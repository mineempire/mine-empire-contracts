var BasicMiner = artifacts.require("./BasicMiner.sol");

module.exports = function(deployer) {
    deployer.deploy(BasicMiner);
};