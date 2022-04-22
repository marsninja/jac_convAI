
import {node::{state}, edge::{transition}, graph::{main_graph}} with "./graph.jac";
import {*} with "./walkers.jac";

walker init {

    root {
        spawn here --> graph::main_graph;
        
        //spawn --> walker::get_prompts;
        //all_prompts = spawn here walker::get_prompts;
        //spawn --> walker::talker(all_prompts = all_prompts);

        spawn --> walker::talker();
    }
    
}