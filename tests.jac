import {*} with "./cai.jac";

test "Travesal touches all nodes"
with graph::basic_gph by walker::get_states {
    assert(path.length==7);
}