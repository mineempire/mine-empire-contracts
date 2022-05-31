var MineEmpireDrill = artifacts.require("./MineEmpireDrill.sol");
var CosmicCash = artifacts.require("./CosmicCash.sol");

module.exports = function(deployer) {
    deployer.deploy(MineEmpireDrill, CosmicCash.address);
};