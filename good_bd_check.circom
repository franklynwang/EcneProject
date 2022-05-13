pragma circom 2.0.0;

template Num2Bits(){
    signal input x;
    signal output b0;
    signal output b1;
    b0 <-- x & 1;
    b1 <-- (x >> 1) & 1;
    2 * b0 + b1 === x;
    b0 * (b0 - 1) === 0;
    b1 * (b1 - 1) === 0;
}

component main = Num2Bits();