import {*} with "./fixture.jac";
import {*} with "./edges.jac";
import {*} with "./nodes.jac";


walker init {
    spawn here --> graph::basic_gph;
}