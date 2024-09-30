pragma circom 2.1.9;

template Multiplier() {
    signal input a;
    signal input b;
    signal output c;
    signal intermediary;

    // Constraint: a * b should equal c
    intermediary <== a * b;
    c <== intermediary;

    // Assert correctness of intermediary calculation
    assert(c == a * b);
}

template UnderconstrainedMultiplier1() {
    signal input a;
    signal input b;
    signal output c;
    signal intermediary;

    intermediary <-- a * b;
    c <== intermediary;
    assert(c == a * b);
}

template UnderconstrainedMultiplier2() {
    signal input a;
    signal input b;
    signal output c;
    signal intermediary;

    intermediary <== a * b;
    c <-- intermediary;
    assert(c == a * b);
}

template UnderconstrainedMultiplier3() {
    signal input a;
    signal input b;
    signal output c;
    signal intermediary;

    intermediary <== a * b;
    c <== intermediary;
    // assert(c == a * b);
}

