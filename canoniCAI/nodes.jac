import {
    edge::{transition, user_link}
} with "./edges.jac";

# TODO: decide the best way to implement this
node label_emebdding_cache {
    has cache = {};
    can read {}
}

# Root for the entire conversational AI root
# TODO: would be great if this can be the actual graph root but it makes testing a bit tricker
node cai_root {
    has name="cai_root";
}

# FAQ entry state
node faq_state {
    can use.question_encode, use.answer_encode;
    can vector.dot_product;

    can seek_answer with talker entry {
        # TODO: performance?
        question_emb = use.question_encode(visitor.question)[0];
        for answer in -[faq_answer]-> {
            score = vector.dot_product(question_emb, answer.embedding);
            if (score > visitor.qa_score) {
                visitor.qa_score = score;
                visitor.destination_state = answer;
            }
        }
    }

    can init_answer_states with init entry {
        answers = file.load_json("./faq_answers.json");
        answers_emb = use.answer_encode(answer=answers);
        idx = 0;
        for i in answers {
            spawn here -[faq_answer]-> node::faq_answer_state(answer=i, embedding=answers_emb[idx]);
            idx += 1;
        }
    }
}

# FAQ answer state
node faq_answer_state {
    has answer = "";
    has embedding;

    can speak with talker entry {
        visitor.hoping = false;
        visitor.state_for_continuing = *(std.get_global("conv_root_state"));
        visitor.answer = here.answer;
        report {
            "name": "faq_answer",
            "state": here,
            "response": visitor.answer
        };
    }

    can cleanup with talker entry {
        if (!visitor.hoping) {
            spawn *(std.get_global("cai_root")) walker::maintainer(
                user_id = visitor.user_id,
                user_context = visitor.user_context,
                dialogue_context = visitor.dialogue_context,
                last_conv_state = visitor.state_for_continuing
            );
        }
    }
}

# Conversation state
node state {
    has anchor name;
    has cand_intents = [];

    # AI abilities
    can use.encode, vector.cosine_sim;
    can ent_ext.entity_detection;
    can hlp.predict_poa;

    # Node abilities triggered by the talker walker for convAI
    # listen -- listen to query question and analyze
    # plan -- plan the next state to move to
    # think -- process state-specific business logic
    # speak -- generate response and speak back to the user
    # cleanup -- any wrap up actions for this question
    can listen with talker entry {
        if (visitor.hoping) {
            ::classify_intent;
            ::extract_entities;
        }
    }

    can plan with talker entry {
        if (visitor.hoping) {
            if (visitor.intent_confidence > std.get_global("intent_confidence_threshold")) {
                # VA path
                # TODO: entity transition needs work
                # visitor.destination_state = 
                #     -[transition(
                #         intent_label == visitor.predicted_intent or 
                #         entity in visitor.extracted_entities)]-> node::state;
                visitor.destination_state = -[transition(intent_label == visitor.predicted_intent)]->[0];
            } else {
               # FAQ path
               # TODO: being able to go to this state from anywhere without having to create edges everywhere
               # TODO needs to fix this;
               visitor.destination_state = *(std.get_global("cai_root")) -[faq_transition]->[0];
            }
        }
    }

    can think with talker entry {
        if (!visitor.hoping) {
            ::business_logic;
            # If this is a leaf node, return the root node as the node to continue from for next query
            ::collect_intents;
            if (here.cand_intents.length == 0)  {
                visitor.state_for_continuing = *(std.get_global("conv_root_state"));
            } else {
                visitor.state_for_continuing = here;
            }
        }
    }

    can speak with talker entry {
        if (!visitor.hoping) {
            ::gen_response;
            report {
                "question": visitor.question,
                "name": here.name,
                "state": here,
                "response": visitor.answer
            };
        }
    }

    can cleanup with talker entry {
        if (!visitor.hoping) {
            spawn *(std.get_global("cai_root")) walker::maintainer(
                user_id = visitor.user_id,
                user_context = visitor.user_context,
                dialogue_context = visitor.dialogue_context,
                last_conv_state = visitor.state_for_continuing
            );
        }
    }

    can collect_intents {
        here.cand_intents = [];
        for i in -[transition]->.edge {
            here.cand_intents += [i.intent_label];
        }
    }

    can classify_intent {
        if (visitor.hoping) {
            ::collect_intents;

            #TODO: cache label embedding in separate node
            question_emb = use.encode(visitor.question)[0];
            for i in here.cand_intents {
                intent_emb = use.encode(i)[0];
                cos_score = vector.cosine_sim(question_emb, intent_emb);
                if (cos_score > visitor.intent_confidence) {
                    visitor.intent_confidence = cos_score;
                    visitor.predicted_intent = i;
                }
            }
        }
    }

    can extract_entities {
        entity_result = ent_ext.entity_detection(
            text=visitor.question, ner_labels=["PREDEFINED"]
        );
        if ("entities" in entity_result) {
            for ent in entity_result["entities"] {
                entity_label = ent["entity_value"];
                entity_text = ent["entity_text"];
                if (entity_label not in visitor.extracted_entities) {
                    visitor.extracted_entities[entity_label] = [];
                }
                visitor.extracted_entities[entity_label] += [entity_text];
            }
        }
    }

    can business_logic {
        if (!visitor.hoping) {
            if (here.name == "hello") {
                visitor.dialogue_context["talking"] = true;
            } elif (here.name == "goodbye") {
                visitor.dialogue_context["talking"] = false;
            }
        }
    }

    can gen_response {
        # TODO: load these response from a file
        if (!visitor.hoping) {
            if (here.name == "hello") {
                visitor.answer = "hello there!";
            } elif (here.name == "goodbye") {
                visitor.answer = "see ya later!";
            }
        }
    }
}