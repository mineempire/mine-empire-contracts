const { tryCatch, errTypes } = require("./exceptions");

const Energy = artifacts.require("./Energy.sol");

contract("Energy", (accounts) => {
  let energy;
  let owner = accounts[0];
  let nonOwner = accounts[4];
  let acc1 = accounts[1];
  let acc2 = accounts[2];
  let transferrer = accounts[3];

  before(async () => {
    energy = await Energy.deployed();
  });

  it("should be deployed", async () => {
    assert.notEqual(energy, "");
  });

  it("should mint to acc1", async () => {
    await energy.mint(acc1, 100);
    let bal = await energy.balanceOf(acc1);
    assert.equal(bal, 100);

    await tryCatch(energy.mint(acc1, 100, { from: nonOwner }), errTypes.revert);
    bal = await energy.balanceOf(acc1);
    assert.equal(bal, 100);

    await energy.setTransferrer(nonOwner, true);
    await energy.mint(acc1, 100, { from: nonOwner });
    bal = await energy.balanceOf(acc1);
    assert.equal(bal, 200);

    await energy.setTransferrer(nonOwner, false);
    await tryCatch(energy.mint(acc1, 100, { from: nonOwner }), errTypes.revert);
    bal = await energy.balanceOf(acc1);
    assert.equal(bal, 200);
  });

  it("should not let user transfer", async () => {
    await tryCatch(energy.transfer(acc2, 100, { from: acc1 }), errTypes.revert);
    await tryCatch(energy.transferFrom(acc1, acc2, 100), errTypes.revert);
    await tryCatch(
      energy.transferFrom(acc1, acc2, 100, { from: nonOwner }),
      errTypes.revert
    );
    await tryCatch(energy.burn(acc1, 100, { from: acc1 }), errTypes.revert);
  });
});
