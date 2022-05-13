pragma circom 2.0.0;

template Num2Bits(){
    signal input x;
    signal output b0;
    signal output b1;
    signal output b2;
    b0 <-- x & 1;
    b1 <-- (x >> 1) & 1;
    b2 <-- (x >> 2) & 1;
    2 * b0 + b1 === x;
    b1 * (b1 - 1) === 0;
    b2 * (b2 - 1) === 0;
}

component main = Num2Bits();