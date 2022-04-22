import {*} with "./graph.jac";
import {*} with "./walkers.jac";

walker init {

    root {
        spawn here --> graph::main_graph;
        spawn --> walker::talker;
    }
}