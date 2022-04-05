node state {
    has name;
    has response="I'm a silly bot.";
    has user_utter;

    can speak with entry {
        std.out(response + " I'm current on "+name+" node");
    }
    
    can listen with talker exit {
        user_utter = visitor.utterance;
        visitor.path.l::append(&here);
        std.out("I heard "+user_utter+".");
    }

    can test_path with get_states entry {
        visitor.path.l::append(&here);
    }
}

node hop_state {
    has name;
    can log with exit {
        std.log("A walker is walking right over me.");
    }
}

edge trans_ner { has entities; }
edge trans_intent { has intent; }
edge trans_qa { has embed; }

graph basic_gph {
    has anchor conv_root;
    spawn {
        conv_root = spawn node::state(name="root_state");

        appt = spawn conv_root -[trans_intent(intent="appointment")]->
            node::hop_state(name="Appointments");

        spawn appt -[trans_intent(intent="create")]->
            node::state(name="Create an appoitnment");
        spawn appt -[trans_intent(intent="cancel")]->
            node::state(name="Cancel an appoitnment");
        spawn appt -[trans_intent(intent="reschedule")]->
            node::state(name="Reschedule an appoitnment");

        service = spawn conv_root -[trans_intent(intent="service info")]->
            node::hop_state(name="Services");

        spawn service -[trans_intent(intent="manicures")]->
            node::state(name="About manicures");
        spawn service -[trans_intent(intent="haircuts")]->
            node::state(name="About haircuts");
        spawn service -[trans_intent(intent="makeup")]->
            node::state(name="About makeup");
    }

}

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
}

test "Travesal touches all nodes"
with graph::basic_gph by walker::get_states {
    std.out(path.length);
    assert(path.length==7);
}