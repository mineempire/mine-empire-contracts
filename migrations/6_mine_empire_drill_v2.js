var MineEmpireDrillv2 = artifacts.require("./MineEmpireDrillv2.sol");
var CosmicCash = artifacts.require("./CosmicCash.sol");

module.exports = function(deployer) {
    deployer.deploy(MineEmpireDrillv2, CosmicCash.address);
};