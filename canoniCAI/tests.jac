import {*} with "./nodes.jac";
import {*} with "./edges.jac";
import {*} with "./fixture.jac";
import {*} with "./cai.jac";

graph empty {
    has anchor root;
    spawn {
        root = spawn node::cai_root;
    }
}

test "test flows in cai_tests.json"
with graph::empty by walker::init {
    flows = file.load_json("./cai_tests.json");
    cai_root = *(std.get_global("cai_root"));
    for flow in flows {
        # Reset user
        spawn cai_root walker::update_user;
        std.out("\n====Testing flow: " + flow["test_name"] + "====");
        new_dialogue = true;
        for step in flow["flow"] {
            std.out("\tquery: " + step["query"]);
            spawn cai_root walker::talker(
                question=step["query"],
                start_new_dialogue=new_dialogue
            );
            new_dialogue = false;
            res = std.get_report();
            assert (res[-1]["name"] == step["state"]);
            assert (step["response_contains"] in res[-1]["response"]);
        }
    }
}