var Coal = artifacts.require("./Coal.sol");

module.exports = function(deployer, resourceMinter) {
    deployer.deploy(Coal);
};