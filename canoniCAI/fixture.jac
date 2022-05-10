import {
    node::{state, cai_root}
} with "./nodes.jac";

import {
    *
} with "./user.jac";

import {
    edge::{transition, user_link, conv_graph, faq_answer}
} with "./edges.jac";

import {
    node::{biencoder}
} with "./biencoder.jac";

import {
    node::{flair_ner}
} with "./flair_ner.jac";

import {*} with "./globals.jac";

# Definition of conversation state graph
graph conv_graph {
    has anchor conv_root;
    spawn {
        conv_root = spawn node::state(name="conv_root_state");
        faq_state = spawn node::faq_state;
        conv_root --> faq_state;

        global.conv_root_state = conv_root.info["jid"];
        global.faq_state = faq_state.info["jid"];

        default_faq_answer_state = spawn node::faq_answer_state(answer="Sorry I can't handle that just yet.");
        faq_state -[faq_answer]-> default_faq_answer_state;

        state_home_price_inquiry = spawn node::state(name="home_price_inquiry");
        state_prob_of_approval = spawn node::state(name="prob_of_approval");
        state_saving_advice = spawn node::state(name="saving_advice");
        state_saving_advice_confirmation = spawn node::state(name="saving_advice_confirmation");
        state_saving_advice_denial = spawn node::state(name="saving_advice_denial");
        state_loan_approval_strategy = spawn node::state(name="loan_approval_strategy");
        state_loan_approval_denial = spawn node::state(name="loan_approval_denial");
        state_loan_approval_strategy_confirmation = spawn node::state(name="loan_approval_strategy_confirmation");
        state_loan_approval_deni_approval_sal = spawn node::state(name="loan_approval_denial");
        state_joke = spawn node::state(name="tell_a_joke");
        state_greeting = spawn node::state(name="greeting");
        state_home_interests = spawn node::state(name="home_interests");
        state_term = spawn node::state(name="term");
        state_study = spawn node::state(name="study");
        state_fin_summary = spawn node::state(name="fin_summary");
        state_taxes_calc = spawn node::state(name="taxes_calc");
        state_home_close_docs = spawn node::state(name="home_close_docs");
        state_home_afdb_calc = spawn node::state(name="home_afdb_calc");
        state_home_afdb_var = spawn node::state(name="home_afdb_var");
        state_home_afdb_inc = spawn node::state(name="home_afdb_inc");
        state_docs_to_upload = spawn node::state(name="docs_to_upload");

        # state_term -[transition(intent_label=global.yes_label)]-> state_study;
        # state_term -[transition(intent_label=global.no_label)]-> conv_root;

        state_study -[transition(intent_label="leaving_label")]-> conv_root;
        state_study -[transition(intent_label="stay_label")]-> state_study;
        
        global_states = [
            [
                state_home_price_inquiry,
                global.home_price_inquiry_label
            ],
            [
                state_prob_of_approval,
                global.prob_of_approval_label
            ],
            [
                state_saving_advice,
                global.purchase_ready_advice_label
            ],
            [
                state_joke,
                global.joke_label
            ],
            [
                state_greeting,
                global.greeting_label
            ],
            [
                state_home_interests,
                global.home_interests_label
            ],
            [
                state_term,
                global.term_label
            ],
            [
                state_study,
                global.study_label
            ],
            [
                state_fin_summary,
                global.fin_summary_label
            ],
            [
                state_taxes_calc,
                global.taxes_calc_label
            ],
            [
                state_home_close_docs,
                global.home_close_docs_label
            ],
            [
                state_home_afdb_calc,
                global.home_afdb_calc_label
            ],
            [
                state_home_afdb_var,
                global.home_afdb_var_label
            ],
            [
                state_docs_to_upload,
                global.docs_to_upload_label
            ],
            [
                state_home_afdb_inc,
                global.home_afdb_inc_label
            ]
        ];

        # Conversation root
        for gstate in global_states {
            conv_root -[transition(intent_label = gstate[1])]-> gstate[0];
        }

        # home price inquiry
        for gstate in global_states {
            state_home_price_inquiry -[transition(intent_label = gstate[1])]-> gstate[0];
        }

        # loan approval probability
        state_prob_of_approval -[transition(intent_label = global.yes_label)]-> state_loan_approval_strategy;
        state_prob_of_approval -[transition(intent_label = global.no_label)]-> state_loan_approval_denial;
        for gstate in global_states {
            state_prob_of_approval -[transition(intent_label = gstate[1])]-> gstate[0];
        }
        state_loan_approval_strategy -[transition(intent_label = global.yes_label)]-> state_loan_approval_strategy_confirmation;
        state_loan_approval_strategy -[transition(intent_label = global.no_label)]-> state_loan_approval_denial;
        for gstate in global_states {
            state_loan_approval_strategy -[transition(intent_label = gstate[1])]-> gstate[0];
        }
        # purchase ready advice
        state_saving_advice -[transition(intent_label = global.yes_label)]-> state_saving_advice_confirmation;
        state_saving_advice -[transition(intent_label = global.no_label)]-> state_saving_advice_denial;
        for gstate in global_states {
            state_saving_advice -[transition(intent_label = gstate[1])]-> gstate[0];
        }

        # term definition
        #state_term -[transition(intent_label = global.need_links_label"))]-> state_followup_links;
        # for gstate in global_states {
        #     state_term -[transition(intent_label = gstate[1])]-> gstate[0];
        # }
    }
}

walker init {
    has prod = false, load_actions = false, load_model = false;
    # TODO: load this from a config file
    # Name of models to load and use for this CAI
    has models_to_load = {
        "biencoder": "hlp_clf_with_study",
        "flair_ner": "finterms"
    };
    root {
        here !--> -->;
        spawn here --> node::cai_root;
        take --> node::cai_root;
    }
    cai_root {
        global.cai_root = here.info["jid"];

        spawn here -[conv_graph]-> graph::conv_graph;
        spawn here --> node::user_dir;

        if (load_actions) {
            if(prod) {
                #std.actload_remote("http://js-biencoder:80/");
                std.actload_remote("http://js-use-enc:80");
                std.actload_remote("http://js-entity-extract:80");
                std.actload_remote("http://js-use-qa:80");
                std.actload_remote("http://hlp-poa:80");
            } else {
                #std.actload_remote("jaseci_kit.encoders.bi");
                std.actload_local("../../jaseci_kit/jaseci_kit/use_enc/use_enc.py");
                std.actload_local("../../jaseci_kit/jaseci_kit/entity_extraction/entity_extraction.py");
                std.actload_local("../../jaseci_kit/jaseci_kit/use_qa/use_qa.py");
                std.actload_local("jskit-hlp/poa/hlp_poa.py");
            }
        }

        spawn here --> node::biencoder;
        spawn here --> node::flair_ner;

        take --> node::state;
        take --> node::user_dir;
        # take --> node::biencoder;
        # take --> node::flair_ner;
    }

    state {
        if (here.name == "conv_root_state") {
            take --> node::faq_state;
            take --> node::state(name=="term");
            # switch this for old study mode
            take --> node::state(name=="study");
            #if (here.name == "term"): take --> node::state(name=="study");
        }
    }
    user_dir {
        take -[user_link]-> node::user;
    }
}