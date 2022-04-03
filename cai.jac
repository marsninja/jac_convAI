import {graph::{basic_gph}} with "./fixture.jac";
import {edge::{trans_ner, trans_intent, trans_qa}} with "./edges.jac";
import {node::{state, hop_state}} with "./nodes.jac";


walker init {
    root {
        spawn here --> graph::basic_gph;
    }
    spawn -->[0] walker::talker;
}

walker talker {
    has utterance;
    has use_cmd = true, path = [];
    if(use_cmd and here.details['name'] != 'hop_state'):
        utterance = std.input("> ");
    take -->;
}

walker get_states {
    has anchor path = [];
    take -->;
    with exit {
        report path;
    }
}