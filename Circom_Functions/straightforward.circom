pragma circom 2.0.2;

template Main() {
    signal input a;
    signal input b;
    signal output out;

    out <== a;
}

component main = Main();