var Asteroid153814 = artifacts.require("./Asteroid153814.sol");
var A153814Rock = artifacts.require("./A153814Rock.sol");
var MineEmpire = artifacts.require("./MineEmpire.sol");
var MineEmpireDrill = artifacts.require("./MineEmpireDrill.sol");

module.exports = function(deployer) {
    deployer.deploy(Asteroid153814, A153814Rock.address, MineEmpire.address, MineEmpireDrill.address);
};