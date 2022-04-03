node state {
    has name;
    has response="I'm a silly bot.";
    has utterance;

    can speak with entry {
        std.out(response + " I'm current on "+name+" node");
    }
    can listen with entry {
        utterance = std.input("> ");
    }
}

node hop_state {
    has name;
}