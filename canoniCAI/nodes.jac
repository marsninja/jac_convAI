import {
    edge::{transition, user_link}
} with "./edges.jac";

import {*} with "./globals.jac";

# Root for the entire conversational AI root
node cai_root {
    has name="cai_root";
}

# FAQ entry state
node faq_state {
    can use.question_encode, use.answer_encode;
    can vector.dot_product;
    can cl_summer.summarize;

    can seek_answer with talker entry {
        question_emb = use.question_encode(visitor.question)[0];
        max_qa_score = 0;
        for answer in -[faq_answer]-> {
            if (answer.embedding) {
                score = vector.dot_product(question_emb, answer.embedding);
                if (score > max_qa_score) {
                    max_qa_score = score;
                    visitor.destination_state = answer;
                }
            }
        }
        if (max_qa_score == 0) {
            # No FAQ is set up
            visitor.destination_state = -[faq_answer]->[0];
        }

        # For FAQ, we want the walker to take another hop
        visitor.hoping = true;
    }

    can init_answer_states with init activity {
        answers = file.load_json("data/faq_answers.json");
        answers_emb = use.answer_encode(answer=answers);
        idx = 0;
        for i in answers {
            spawn here -[faq_answer]-> node::faq_answer_state(answer=i, embedding=answers_emb[idx]);
            idx += 1;
        }
    }

    can read_url with read entry {
        summarys = cl_summer.summarize(text="none", url=visitor.source_url, sent_count=10, summarizer_type="LsaSummarizer");
        summarys_emb = use.answer_encode(answer=summarys);
        idx = 0;
        for i in summarys {
            spawn here -[faq_answer]-> node::faq_answer_state(answer=i, embedding=summarys_emb[idx]);
            idx += 1;
        }
    }

    can clean_answer_db with forget entry {
        here !-[faq_answer]-> -[faq_answer]->;
        spawn here -[faq_answer]-> node::faq_answer_state(answer="Sorry I can't handle that just yet");
    }
}

# FAQ answer state
node faq_answer_state {
    has answer = "";
    has embedding = null;

    can speak with talker entry {
        visitor.hoping = false;
        visitor.state_for_continuing = global.conv_root_state;
        visitor.answer = here.answer;
        report {
            "name": "faq_answer",
            "response": visitor.answer
        };
    }

    can cleanup with talker entry {
        if (!visitor.hoping) {
            spawn *(global.cai_root) walker::maintainer(
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
    has terms_emb = {};
    has terms_ac = {};
    has terms_data;
    has study_prompt = "";

    # AI abilities
    can use.encode, vector.cosine_sim;
    can bi_enc.get_context_emb, bi_enc.get_candidate_emb;
    can vector.dot_product, vector.softmax;
    can ent_ext.entity_detection;
    can extract_entity.extract_entity;
    can use.answer_encode;
    can use.question_encode;

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
            visitor.destination_state = -[transition(intent_label == visitor.predicted_intent)]->[0];
            if (visitor.intent_confidence > global.intent_confidence_threshold) {
                # VA path
                visitor.destination_state = 
                    -[transition(
                        intent_label == visitor.predicted_intent or 
                        entity in visitor.extracted_entities)]-> node::state;
            } else {
                # FAQ path
                visitor.destination_state = *(global.faq_state);
            }
        }
    }

    can think with talker entry {
        if (!visitor.hoping) {
            ::business_logic;
            # If this is a leaf node, return the root node as the node to continue from for next query
            ::collect_intents;
            if (here.cand_intents.length == 0)  {
                visitor.state_for_continuing = *(global.conv_root_state);
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
                "response": visitor.answer
            };
        }
    }

    can cleanup with talker entry {
        if (!visitor.hoping) {
            spawn *(global.cai_root) walker::maintainer(
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
            here.cand_intents.l::append(i.intent_label);
        }
    }

    can classify_intent with get_cand_intents activity {
        if (visitor.hoping) {
            if (visitor.overwrite_intent != "") {
                visitor.predicted_intent = visitor.overwrite_intent;
                visitor.intent_confidence = 1;
            } else {
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
    }

    can extract_entities {
        if (visitor.overwrite_entity != {}) {
            visitor.extracted_entities = visitor.overwrite_entity;
        } else {
            entity_result = extract_entity.extract_entity(
                text=visitor.question
            );
            for ent in entity_result {
                if (ent["score"] > global.entity_confidence_threshold){
                    entity_label = ent["entity"];
                    entity_text = ent["text"];
                    if (entity_label not in visitor.extracted_entities) {
                        visitor.extracted_entities[entity_label] = [];
                    }
                    visitor.extracted_entities[entity_label] += [entity_text];
                }
            }
        }
    }

    can business_logic {
        if (!visitor.hoping) {
            if (here.name == "hello") {
                visitor.dialogue_context["talking"] = true;
            } elif (here.name == "goodbye") {
                visitor.dialogue_context["talking"] = false;
            } elif (here.name == "weather") {
                # Call 3rd APIs to fetch weather info
                visitor.dialogue_context["weather"] = "sunny";
            }
        }
    }

    can gen_response {
        if (!visitor.hoping) {
            if (here.name == "hello") {
                visitor.answer = "hello there!";
            } elif (here.name == "goodbye") {
                visitor.answer = "see ya later!";
            } elif (here.name == "weather") {
                visitor.answer = "The weather is going to be " + visitor.dialogue_context["weather"] + ".";
            }
        }
    }
}