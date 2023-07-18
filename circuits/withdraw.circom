include "../node_modules/circomlib/circuits/bitify.circom";
include "./merkleTree.circom";

template CommitmentHasher() {
    signal input secret;
    signal input nullifier;
    signal output nullifierHash;
    signal output commitment;
    component hasher = HashLeftRight();
    hasher.left <== secret;
    hasher.right <== nullifier;

    component hasherNullifier = HashLeftRight();
    hasherNullifier.left <== nullifier;
    hasherNullifier.right <== nullifier;



    commitment <== hasher.hash;
    nullifierHash <== hasherNullifier.hash;

}
template Withdraw(levels) {
    signal input root;
    signal input nullifierHash;
    signal input amount;
    signal private input nullifier;
    signal private input secret;
    signal private input pathElements[levels];
    signal private input pathIndices[levels];

    component hasher = CommitmentHasher();
    hasher.nullifier <== nullifier;
    hasher.secret <== secret;
    hasher.nullifierHash === nullifierHash;

    component tree = MerkleTreeCheck(levels);
    tree.leaf <== hasher.commitment;
    tree.root <== root;

    for (var i = 0; i < levels; i++) {
      tree.pathElements[i] <== pathElements[i];
      tree.pathIndices[i] <== pathIndices[i];
    }

    // Add hidden signals to make sure that tampering with recipient or fee will invalidate the snark proof
    // Most likely it is not required, but it's better to stay on the safe side and it only takes 2 constraints
    // Squares are used to prevent optimizer from removing those constraints
    signal amountSquare;
    amountSquare <== amount * amount;
}

component main = Withdraw(20);