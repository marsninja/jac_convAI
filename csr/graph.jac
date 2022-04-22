node state {
    has title;
    has message;
    has prompts;
}

edge transition {
    has intent;
}

graph main_graph {
    has anchor main_root;

    spawn {

        main_root = spawn node::state(
                        title = "Greeting",
                        message = "Hi there, welcome. What can we build for you today?",
                        prompts = ["website", "mobile app", "information system", "quit"] 
                    );

        website = spawn main_root -[transition(intent="website")]-> node::state(
                                            title = "Website",
                                            message = "What type of website would you like?",
                                            prompts = ["one pager website", "five pager website", "custom website", "back"]
                            ); 

        website -[transition(intent="back")]-> main_root;

        one_pager = spawn website -[transition(intent="one pager website")]-> node::state(
                                            title = "One Pager",
                                            message = "Tell us about the one pager that you'd like us to build",
                                            prompts = ["back"]
                            );

        five_pager = spawn website -[transition(intent="five pager website")]-> node::state(
                                            title = "Five Pager",
                                            message = "Tell us about the five pager that you'd like us to build",
                                            prompts = ["back"]
                            );

        custom_website = spawn website -[transition(intent="custom website")]-> node::state(
                                            title = "One Pager",
                                            message = "Tell us about the custom website that you'd like us to build",
                                            prompts = ["back"]
                            );

        mobile_app = spawn main_root -[transition(intent="mobile app")]-> node::state(
                                            title = "Mobile App",
                                            message = "What type of mobile app would you like?",
                                            prompts = ["game", "social", "custom", "back"]
                            );

        info_system = spawn main_root -[transition(intent="information system")]-> node::state(
                                            title = "Information System",
                                            message = "Tell me about the information system you'd like",
                                            prompts = ["back"]
                            ); 
    }
}