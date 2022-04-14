
walker talker {
    has utterance;

    state {
        std.out(here.message, here.prompts);

        if(here.title == "Quit"): disengage;

        utterance = std.input("> ");

        take -[transition(intent == utterance)]-> node::state else {
            take <--;
        }
    }
}