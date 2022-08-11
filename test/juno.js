const Juno = artifacts.require("./Juno.sol");

contract("Juno", (accounts) => {
  let juno;
  let owner = accounts[0];

  before(async () => {
    juno = await Juno.deployed();
  });

  it("should be deployed", async () => {
    assert.notEqual(juno, "");
  });
});
