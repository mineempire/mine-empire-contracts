var Converter = artifacts.require('./Converter.sol')
var CosmicCash = artifacts.require('./CosmicCash.sol')

module.exports = function(deployer) {
    deployer.deploy(Converter, CosmicCash.address)
}