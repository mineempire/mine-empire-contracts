var Silver = artifacts.require("./Silver.sol");

module.exports = function(deployer, resourceMinter) {
    deployer.deploy(Silver);
};