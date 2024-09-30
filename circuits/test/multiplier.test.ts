// A reference to using circomkit
// circomkit: https://github.com/erhant/circomkit
// more examples: https://github.com/erhant/circomkit-examples

import { assert } from "chai";
import { Circomkit, WitnessTester } from "circomkit";
import "mocha";

// 1. circomkit may be setup once at a root file, e.g. index.test.ts
export const circomkit = new Circomkit({
  verbose: false,
});

// 2. test. 
// Use WitnessTester to declare circuit inputs and outputs. 
// Use a `before` block to set up the circuit once, and use `it` blocks to test different cases.
describe("ToBlocks", () => {
  let circuit: WitnessTester<["a", "b"], ["c"]>;

  before(async () => {
    circuit = await circomkit.WitnessTester(`ToBlocks`, {
      file: "multiplier",
      template: "Multiplier",
      // params: [],
    });
    console.log("#constraints:", await circuit.getConstraintCount());
  });

  it("test multiplier", async () => {
    const a = 2;
    const b = 3;
    const c = 6;
    await circuit.expectPass({ a, b }, { c });
  });
});

// 3. run test with `npx mocha test [-g testname]`
// or if you have just installed, `just test[g testname]`
