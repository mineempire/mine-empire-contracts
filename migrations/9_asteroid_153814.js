var Asteroid153814 = artifacts.require("./Asteroid153814.sol");
var Iron = artifacts.require("./Iron.sol");
var MineEmpire = artifacts.require("./MineEmpire.sol");
var MineEmpireDrill = artifacts.require("./MineEmpireDrill.sol");

module.exports = function(deployer) {
    deployer.deploy(Asteroid153814, Iron.address, MineEmpire.address, MineEmpireDrill.address);
};