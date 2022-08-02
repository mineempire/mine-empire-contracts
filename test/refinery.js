const Refinery = artifacts.require("./Refinery.sol");

contract("Refinery", (accounts) => {
  let refinery;
  let owner = accounts[0];

  before(async () => {
    refinery = await Refinery.deployed();
  });

  it("should be deployed", async () => {
    assert.notEqual(refinery, "");
  });
});
