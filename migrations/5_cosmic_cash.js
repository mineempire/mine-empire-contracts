var CosmicCash = artifacts.require("./CosmicCash.sol");

module.exports = function(deployer) {
    deployer.deploy(CosmicCash);
};