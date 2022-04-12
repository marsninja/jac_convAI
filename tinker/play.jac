
walker simple {
    has anchor apple;
    apple=5;
}

walker init {
    std.out(spawn here walker::simple);
}