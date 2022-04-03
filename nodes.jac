node state {
    has name;
    has reponse;
    has utterance;

    can speak with entry {
        std.out(response);
    }
    can listen with entry {
        utterance = std.input("> ");
    }
}

node hop_state {
    has name;
}