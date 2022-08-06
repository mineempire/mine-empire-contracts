var FantomBridge = artifacts.require(
  "./bridges/MineEmpirePolygonToFantomBridge.sol"
);

module.exports = function (deployer) {
  deployer.deploy(FantomBridge);
};
