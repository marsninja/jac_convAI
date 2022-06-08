node use_encoder {
    can use.text_classify;

    can classify with infer_use_encoder entry {
        dataset = file.load_json("data/clf_labels.json");

        response = use.text_classify(visitor.query, dataset);

        report response;
    }

}

walker infer_use_encoder {
    has query;

    root: take --> node::cai_root;
    cai_root: take --> node::use_encoder;
}