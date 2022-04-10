include "../Circom_Functions/circomlib/circuits/mimcsponge.circom";

// Computes MiMC([left, right])
template HashLeftRight() {
    signal input left;
    signal input right;
    signal output hash;

    component hasher = MiMCSponge(2, 2, 1);
    hasher.ins[0] <== left;
    hasher.ins[1] <== right;
    hasher.k <== 0;
    hash <== hasher.outs[0];
}

// if s == 0 returns [inp[0], inp[1]]
// if s == 1 returns [inp[1], inp[0]]
template DualMux() {
    signal input inp[2];
    signal input s;
    signal output outp[2];

    s * (1 - s) === 0;
    outp[0] <== (inp[1] - inp[0])*s + inp[0];
    outp[1] <== (inp[0] - inp[1])*s + inp[1];
}

// Verifies that merkle proof is correct for given merkle root and a leaf
// pathIndices input is an array of 0/1 selectors telling whether given pathElement is on the left or right side of merkle path
template MerkleTreeChecker(levels) {
    signal input leaf;
    signal input root;
    signal input pathElements[levels];
    signal input pathIndices[levels];

    component selectors[levels];
    component hashers[levels];

    for (var i = 0; i < levels; i++) {
        selectors[i] = DualMux();
        selectors[i].inp[0] <== i == 0 ? leaf : hashers[i - 1].hash;
        selectors[i].inp[1] <== pathElements[i];
        selectors[i].s <== pathIndices[i];

        hashers[i] = HashLeftRight();
        hashers[i].left <== selectors[i].outp[0];
        hashers[i].right <== selectors[i].outp[1];
    }

    root === hashers[levels - 1].hash;
}

component main = MerkleTreeChecker(20);