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

// component main = Multiplier();
