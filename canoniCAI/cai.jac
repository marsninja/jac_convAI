import {
    node::{state}
} with "./nodes.jac";

import {
    edge::{transition, user_link}
} with "./edges.jac";

import {
    node::{user, user_dir}
} with "./user.jac";

import {
    node::{biencoder, ent_ext}
} with "./models.jac";

walker talker {
    has question, user_id="example", start_new_dialogue = false;
    has hoping = true; # If the walker needs to make the transition
    has starting_state;
    has predicted_intent = "";
    has intent_confidence = 0;
    has extracted_entities = {};
    has user_context = {};
    has dialogue_context = {};
    has qa_score = 0;
    has answer;
    has state_for_continuing;
    has destination_state;

    root: take --> node::cai_root;
    cai_root: take --> node::user_dir;
    user_dir: take -[user_link(user_id==user_id)]-> node::user;
    user {
        take starting_state;
    }
    state {
        if (hoping) {
            hoping = false;
            take destination_state else {
                report {
                    "name": "out_of_scope",
                    "response": "Sorry I can't handle that just yet.",
                    "state": {}
                    };
            }
        } 
   }
}

walker maintainer {
    has user_id, user_context, dialogue_context, last_conv_state;
    root: take --> node::cai_root;
    cai_root: take --> node::user_dir;
    user_dir: take -[user_link(user_id==user_id)]-> node::user;
}