
import {node::{state}, edge::{transition}, graph::{main_graph}} with "./graph.jac";
import {*} with "./walkers.jac";

walker init {

    root {
        spawn here --> graph::main_graph;
        spawn --> walker::talker;
    }
    
}