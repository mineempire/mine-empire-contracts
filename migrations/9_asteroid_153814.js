var Asteroid153814Old = artifacts.require("./Asteroid153814Old.sol");
var Iron = artifacts.require("./Iron.sol");
var MineEmpire = artifacts.require("./MineEmpire.sol");
var MineEmpireDrill = artifacts.require("./MineEmpireDrill.sol");

module.exports = function(deployer) {
    deployer.deploy(Asteroid153814Old, Iron.address, MineEmpire.address, MineEmpireDrill.address);
};