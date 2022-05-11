import {
    node::{state, cai_root}
} with "./nodes.jac";

import {*} with "./user.jac";

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

        state_hello = spawn node::state(name="hello");
        state_goodbye = spawn node::state(name="goodbye");
        state_weather = spawn node::state(name="weather");

        conv_root -[transition(intent_label = global.hello_label)]-> state_hello;
        conv_root -[transition(intent_label = global.goodbye_label)]-> state_goodbye;
        conv_root -[transition(intent_label = global.weather_label)]-> state_weather;
    }
}

walker init {
    has prod = false, load_model = false;

    # Name of models to load and use for this CAI
    has models_to_load = {
        "biencoder": "clf_model",
        "flair_ner": "ner_model"
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

        spawn here --> node::biencoder;
        spawn here --> node::flair_ner;
        take --> node::biencoder;
        take --> node::flair_ner;
 
        take --> node::state;
        take --> node::user_dir;
   }

    state {
        if (here.name == "conv_root_state") {
            take --> node::faq_state;
        }
    }
    user_dir {
        take -[user_link]-> node::user;
    }
}