
walker talker {
    //has all_prompts = [];
    has utterance;
    has root_state;
    can use.enc_question, use.enc_answer;

    state {

        if(here.title == "Greeting"): root_state = here;

        std.out(here.message);
    
        utterance = std.input("> ");

        if(utterance == "quit"): disengage; #disengage if user types quit

        q_enc = use.enc_question(utterance);
        a_enc = use.enc_answer(here.prompts); # can take lists or single strings

        a_scores={}; #stores a dictionary of prompts and their related scores based on utterance similarity
        threshold = 0.15; #cutoff threshold value; scores below this will be ignored
        max_cf = 0; #max confidence factor score of the question among the encoded answers
        qa_intent = ""; #the likely intent based on max_cf to use in transition

        for i=0 to i<(here.prompts).length by i += 1 {

            cf = vector.cosine_sim(q_enc, a_enc[i]);
            a_scores[here.prompts[i]] = cf;

            if(cf >= threshold && cf > max_cf) {
                max_cf = cf;
                qa_intent = here.prompts[i];
            }
        } 

        report {"utterance": utterance, "qa_intent": qa_intent, "scores": a_scores}; #report all this 
        
        take -[transition(intent == qa_intent)]-> node::state else {
            #say I dont know..prompt again..
            //std.out("Hmm.. not sure. Here are some options to help: ", here.prompts);
            take root_state;
        }

        //spawn -[transition(intent == qa_intent)]-> walker::talker;
        //disengage;    
        
    }
}

walker get_prompts {
    
    has anchor prompts = [];

  
    root, state {
        states = --> node::state;

        for n in states {
           if( n.context.prompts ):
                prompts += n.context.prompts;
        }

        root: take --> node::state;
        state: disengage;
    }

}