var Iron = artifacts.require("./Iron.sol");

module.exports = function(deployer, resourceMinter) {
    deployer.deploy(Iron);
};