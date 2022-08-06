var FantomBridge = artifacts.require(
  "./bridges/MineEmpireFantomToPolygonBridge.sol"
);

module.exports = function (deployer) {
  deployer.deploy(FantomBridge);
};
