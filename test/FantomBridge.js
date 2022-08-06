const FantomBridge = artifacts.require(
  "./bridges/MineEmpireFantomToPolygonBridge.sol"
);

contract("FantomBridge", (accounts) => {
  let bridge;
  let owner = accounts[0];

  before(async () => {
    bridge = await FantomBridge.deployed();
  });

  it("should be deployed", async () => {
    assert.notEqual(bridge, "");
  });
});
