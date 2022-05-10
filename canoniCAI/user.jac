import {
    edge::{user_link}
} with "./edges.jac";

import {
    *
} with "./cai.jac";

import {*} with "./globals.jac";

# User node
node user {
    has id;
    has profile = {};
    has dialogue_context = {};
    has last_conv_state = null;
    has load_from_api = "";

    can start_conv with talker entry {
        if (here.profile == {}) {
            ::init_user;
        }
        visitor.user_context = here.profile;
        if (here.last_conv_state == null) {
            here.last_conv_state = *(global.conv_root_state);
        }
        if(visitor.start_new_dialogue){
            here.dialogue_context = {};
            here.last_conv_state = *(global.conv_root_state);
        }

        visitor.starting_state = here.last_conv_state;
        visitor.dialogue_context = here.dialogue_context;
    }

    can update_with_conv with maintainer entry {
        here.profile.d::update(visitor.user_context);
        here.dialogue_context.d::update(visitor.dialogue_context);
        here.last_conv_state = visitor.last_conv_state;
    }

    can init_user with init entry {
        default_fields = {
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
                "credit_score": 420
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
            
        # Implement logic to fetch actual user data
        # For now, we will have a special case for installing the example user
        if (here.id == "example") {
            here.profile = default_fields;
        }
        elif(here.load_from_api != ""){

            payload = file.load_json(here.load_from_api);

            here.profile = default_fields;
            here.profile["loan_profile"] = payload.borrower;

            # a few name and data type conversions
            # The poa prediction model uses 1 and 0 instead of true and false
            # TODO: casting types work here perhaps?
            here.profile["loan_profile"]["piti"] = here.profile["loan_profile"]["affordableMortgagePayment"];
            here.profile["loan_profile"]["cred_score_num"] = here.profile["loan_profile"]["credit_score"];
            if (here.profile["loan_profile"]["bankruptcy"]){
                here.profile["loan_profile"]["bankruptcy"] = 1; 
            } else {
                here.profile["loan_profile"]["bankruptcy"] = 0; 
            }

            if (here.profile["loan_profile"]["foreclosure_flag"]){
                here.profile["loan_profile"]["foreclosure_flag"] = 1; 
            } else {
                here.profile["loan_profile"]["foreclosure_flag"] = 0; 
            }

            if (here.profile["loan_profile"]["late_chrg_delinq_12_mth_num"]){
                here.profile["loan_profile"]["late_chrg_delinq_12_mth_num"] = 1; 
            } else {
                here.profile["loan_profile"]["late_chrg_delinq_12_mth_num"] = 0; 
            }
        }
    }
}

# User directory node
node user_dir {
    can init_users with init entry {
        # Install an example user
        if(-[user_link(user_id=="example")]->.length == 0) {
            spawn here -[user_link(user_id="example")]-> node::user(id="example");
        }

        # Install all users from json
        users = file.load_json('/json_data/users/user_dir.json');

        for u in users {
            spawn here -[user_link(user_id=u["user_id"])]-> node::user(id=u["user_id"], load_from_api=u["user_json"]);
        }

    }
}

walker update_user {
    root: take --> node::cai_root;
    cai_root: take --> node::user_dir;
    user_dir: take --> node::user;
}