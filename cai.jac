import {graph::{basic_gph}} with "./fixture.jac";
import {edge::{trans_ner, trans_intent, trans_qa}} with "./edges.jac";
import {node::{state, hop_state}} with "./nodes.jac";


walker init {
    root {
        spawn here --> graph::basic_gph;
    }
    take -->;
}