import {
    edge::{user_link}
} with "./edges.jac";

# User node
node user {
    has id;
    has profile = {};
    has dialogue_context = {};
    has last_conv_state = null;

    can start_conv with talker entry {
        visitor.user_context = here.profile;
        if (here.last_conv_state == null) {
            here.last_conv_state = *(std.get_global("conv_root_state"));
        }
        if(visitor.start_new_dialogue){
            here.dialogue_context = {};
            here.last_conv_state = *(std.get_global("conv_root_state"));
        }

        visitor.starting_state = here.last_conv_state;
        visitor.dialogue_context = here.dialogue_context;
    }

    can update_with_conv with maintainer entry {
        here.profile.d::update(visitor.user_context);
        here.dialogue_context.d::update(visitor.dialogue_context);
        here.last_conv_state = visitor.last_conv_state;
    }

    can init_user with init, update_user entry {
        # Implement logic to fetch actual user data
        # For now, we will have a special case for installing the example user
        if (here.id == "example") {
            here.profile = {
                "loan_profile": {
                    "late_non_mtg_pymts": 0,
                    "length_of_residence_num": 3.5,
                    "bankruptcy": 0,
                    "foreclosure_flag": 0,
                    "late_chrg_delinq_12_mth_num": 0,
                    "ltv": 100,
                    "mdo": 3445.27,
                    "piti": 2322.25,
                    "dti": 62.59085863568,
                    "length_of_employment_num": 15,
                    "cred_score_num": 420
                },
                "db": {
                    "average_spending": {
                        "restaurant": "$850"
                    }
                },
                "history": {
                    "spending_reduction_rec": false,
                    "down_payment_programs": false
                }
            };
        }
    }
}

# User directory node
node user_dir {
    can init_users with init entry {
        # Implement user data pull/push policy here
        # for now, we will just install an example user
        if(-[user_link(user_id=="example")]->.length == 0) {
            spawn here -[user_link(user_id="example")]-> node::user(id="example");
        }
    }
}

walker update_user {
    root: take --> node::cai_root;
    cai_root: take --> node::user_dir;
    user_dir: take --> node::user;
}