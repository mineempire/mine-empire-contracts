const MineEmpireDrill = artifacts.require("./MineEmpireDrill.sol")
const A153814 = artifacts.require("./Asteroid153814.sol")
const Iron = artifacts.require("./Iron.sol")
const Gem = artifacts.require("./MineEmpire.sol")

contract("Asteroid153814", accounts => {
    let mineEmpireDrill
    let iron
    let gem
    let a153814
    let owner = accounts[0]
    let nonOwner = accounts[1]
    let acc2 = accounts[2]
    let treasury = accounts[3]
    let tryCatch = require("./exceptions.js").tryCatch
    let errTypes = require("./exceptions.js").errTypes

    before(async () => {
        mineEmpiredrill = await MineEmpireDrill.deployed()
        iron = await Iron.deployed()
        gem = await Gem.deployed()
        a153814 = await A153814.deployed()
    })

    it("should be deployed", async () => {
        assert.notEqual(mineEmpireDrill, "")
        assert.notEqual(iron, "")
        assert.notEqual(gem, "")
        assert.notEqual(a153814, "")
    })
})