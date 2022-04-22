import {
    node::{state, cai_root}
} with "./nodes.jac";

# TODO: super weird import bug here. check with jason
import {
    *
    #node::{user, user_dir},
} with "./user.jac";

import {
    edge::{transition, user_link, conv_graph}
} with "./edges.jac";

import {
    node::{biencoder, ent_ext}
} with "./models.jac";

global hello_label = "hello";
global goodbye_label = "goodbye";

global intent_confidence_threshold  = 0.3;

# Definition of conversation state graph
graph conv_graph {
    has anchor conv_root;
    spawn {
        conv_root = spawn node::state(name="conv_root_state");
        # TODO: this feels hacky. need to find an alternative
        std.set_global("conv_root_state", conv_root.info["jid"]);

        faq_state = spawn node::faq_state;
        conv_root --> faq_state;

        state_hello = spawn node:;state(name="hello");
        state_goodbye = spawn node:;state(name="goodbye");

        conv_root -[transition(intent_label = global.hello_label)]-> state_hello;
        conv_root -[transition(intent_label = global.goodbye_label)]-> state_goodbye;
    }
}

walker init {
    has prod = false, load_actions = false;
    # TODO: load this from a config file
    # Name of models to load and use for this CAI
    has models_to_load = {
        "biencoder": "modeloutput",
        "ent_ext": "modeloutput"
    };
    root {
        spawn here --> node::cai_root;
    }
    cai_root {
        # TODO: this feels like a hack. need to find alternative
        std.set_global("cai_root", here.info["jid"]);

        spawn here -[conv_graph]-> graph::conv_graph;
        spawn here --> node::user_dir;

        if (load_actions) {
            if(prod) {
                # TODO: do we want to load here at init?
                std.actload_remote("http://js-biencoder:80/");
                std.actload_remote("http://js-use-enc:80");
                std.actload_remote("http://js-entity-extract:80");
                std.actload_remote("http://js-use-qa:80");
                std.actload_remote("http://hlp-poa:80");
            } else {
                std.actload_remote("jaseci_kit.encoders.bi");
                std.actload_local("../../jaseci_kit/jaseci_kit/use_enc/use_enc.py");
                std.actload_local("../../jaseci_kit/jaseci_kit/entity_extraction/entity_extraction.py");
                std.actload_local("../../jaseci_kit/jaseci_kit/use_qa/use_qa.py");
                std.actload_local("jskit-hlp/poa/hlp_poa.py");
            }
        }

        spawn here --> node::biencoder;
        spawn here --> node::ent_ext;

        take --> node::state;
        take --> node::user_dir;
        take --> node::biencoder;
        take --> node::entity_extract;
    }

    state {
        take --> node::faq_state;
    }
    user_dir {
        take --> node::user;
    }
}