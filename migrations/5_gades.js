var Gades = artifacts.require("./Gades.sol");
var Iron = artifacts.require("./Iron.sol");
var CosmicCash = artifacts.require("./CosmicCash.sol");
var MineEmpireDrill = artifacts.require("./MineEmpireDrill.sol");

module.exports = function(deployer) {
    deployer.deploy(Gades, Iron.address, CosmicCash.address, MineEmpireDrill.address);
};