node biencoder {
    can bi_enc.train, bi_enc.load_model, bi_enc.save_model, bi_enc.set_model_config;

    can load_model with init entry {
        bi_enc.load_model(visitor.models_to_load["biencoder"]);
    }

    can train with train_biencoder entry {
        # set model config to reload the base pre-trained model
        bi_enc.set_model_config();
        train_data = file.load_json(visitor.train_file);
        bi_enc.train(train_data);
        bi_enc.save_model(visitor.model_name);
    }
}

node ent_ext {
    can ent_ext.train, ent_ext.load_model, ent_ext.save_model;
    
    can load_model with init entry {
        ent_ext.load_model(visitor.models["ent_ext"]);
    }

    can train with train_ent_ext entry {
        ent_ext.load_model("default");
        train_data = file.load_json(visitor.train_file);
        ent_ext.train(train_data);
        ent_ext.save_model(visitor.model_name);
    }
}

walker train_biencoder {
    has model_name, train_file;
    root: take --> node::cai_root;
    cai_root: take --> node::biencoder;
}

walker train_ent_ext {
    has model_name, train_file;
    root: take --> node::cai_root;
    cai_root: take --> node::ent_ext;
}