node state {
    has name;
    has response="I'm a silly bot.";
    has utterance;

    can speak with entry {
        std.out(response + " I'm current on "+name+" node");
    }
    can listen with talker exit {
        utterance = visitor.utterance;
        visitor.path.l::append(&here);
        std.out("I heard "+utterance+".");
    }

    can record_path with get_states entry {
        visitor.path.l::append(&here);
    }
}

node hop_state {
    has name;
}