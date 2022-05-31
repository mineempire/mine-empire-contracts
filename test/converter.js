const Converter = artifacts.require('./Converter.sol')
const CosmicCash = artifacts.require('./CosmicCash.sol')
const Iron = artifacts.require('./Iron.sol')

contract('Converter', accounts => {
    let converter
    let cosmicCash
    let iron
    let owner = accounts[0]
    let nonOwner = accounts[1]
    let acc2 = accounts[2]
    let treasury = accounts[3]
    let tryCatch = require('./exceptions.js').tryCatch
    let errTypes = require('./exceptions.js').errTypes

    before(async () => {
        cosmicCash = await CosmicCash.deployed()
        iron = await Iron.deployed()
        converter = await Converter.deployed()
    })

    it('should be deployed', async () => {
        assert.notEqual(cosmicCash, '')
        assert.notEqual(iron, '')
        assert.notEqual(converter, '')
    })
})