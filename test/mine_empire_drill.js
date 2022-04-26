const MineEmpireDrill = artifacts.require("./MineEmpireDrill.sol")
const Iron = artifacts.require("./Iron.sol")

contract("MineEmpireDrill", accounts => {
    let mineEmpiredrill
    let iron;
    let owner = accounts[0]
    let nonOwner = accounts[1]
    let acc2 = accounts[2]
    let treasury = accounts[3]
    let tryCatch = require("./exceptions.js").tryCatch
    let errTypes = require("./exceptions.js").errTypes
    
    before(async () => {
        mineEmpiredrill = await MineEmpireDrill.deployed()
        iron = await Iron.deployed()
    })

    it("should be deployed", async () => {
        assert.notEqual(mineEmpiredrill, "");
    });

    it("should not update maxDrills, not owner", async () => {
        await tryCatch(mineEmpiredrill.updateMaxDrillCount(1, {from: nonOwner}), errTypes.revert)
        await mineEmpiredrill.updateMaxDrillCount(1, {from: owner})
    })

    it("should add a new drill type", async () => {
        /*
        mint price 2e18
        mining power 1x, 1.5x, 2x
        capacity 1000, 2000, 3000
        mining power upgrade req 10000, 20000
        capacity upgrade req     10000, 20000
         */
        await mineEmpiredrill.addNewDrillType(
            0,
            "Basic Drill",
            "2000000000000000000",
            "3",
            ["100", "150", "200"],
            ["1000", "2000", "3000"],
            [["10000"], ["20000"]],
            [["10000"], ["20000"]]
        )
    })

    it("should set treasury address", async () => {
        await mineEmpiredrill.updateTreasuryAddress(treasury)
    })

    it("should mint a drill", async () => {
        let balance = await web3.eth.getBalance(treasury);
        assert.equal(balance, web3.utils.toWei('100', 'ether'))

        await mineEmpiredrill.mintDrill({from: acc2, value: web3.utils.toWei('2', 'ether')})
        const drill = await mineEmpiredrill.getDrill(1)
        assert.equal(drill.name, "Basic Drill")
        assert.equal(drill.drillType, "0")
        assert.equal(drill.miningLevel, "1")
        assert.equal(drill.capacityLevel, "1")

        balance = await web3.eth.getBalance(treasury);
        assert.equal(balance, web3.utils.toWei('102', 'ether'))
    })

    it("should not mint due to max drills", async () => {
        await tryCatch(mineEmpiredrill.mintDrill({from: acc2, value: web3.utils.toWei('2', 'ether')}), errTypes.revert)
    })

    it("should add new tracked resource", async () => {
        await mineEmpiredrill.addNewTrackedResource(iron.address)
    })

    it("should mint resource to acc2", async () => {
        await iron.mint(acc2, "100000")
    })

    it("should not be able to upgrade mining power because drill doesn't exist", async () => {
        await tryCatch(mineEmpiredrill.upgradeMiningLevel(2, {from: acc2}), errTypes.revert)
    })

    it("should not be able to upgrade mining power because not owner of drill", async () => {
        await tryCatch(mineEmpiredrill.upgradeMiningLevel(1, {from: owner}), errTypes.revert)
    })

    it("should not be able to upgrade because resource not approved", async () => {
        await tryCatch(mineEmpiredrill.upgradeMiningLevel(1, {from: acc2}), errTypes.revert)
    })

    it("should upgrade mining power and capacity amount", async() => {
        await iron.approve(mineEmpiredrill.address, web3.utils.toWei('1', 'ether'), {from: acc2})
        let balance = await iron.balanceOf(acc2)
        assert.equal(balance, "100000")
        let drill = await mineEmpiredrill.getDrill(1)
        assert.equal(drill.miningLevel, "1")
        assert.equal(drill.drillType, "0")
        let miningPower = await mineEmpiredrill.getDrillMiningPower(1)
        assert.equal(miningPower, "100")
        await mineEmpiredrill.upgradeMiningLevel(1, {from: acc2})
        balance = await iron.balanceOf(acc2)
        assert.equal(balance, "90000")
        drill = await mineEmpiredrill.getDrill(1)
        assert.equal(drill.miningLevel, "2")
        miningPower = await mineEmpiredrill.getDrillMiningPower(1)
        assert.equal(miningPower, "150")
        await mineEmpiredrill.upgradeMiningLevel(1, {from: acc2})
        balance = await iron.balanceOf(acc2)
        assert.equal(balance, "70000")
        drill = await mineEmpiredrill.getDrill(1)
        assert.equal(drill.miningLevel, "3")
        miningPower = await mineEmpiredrill.getDrillMiningPower(1)
        assert.equal(miningPower, "200")
        await tryCatch(mineEmpiredrill.upgradeMiningLevel(1, {from: acc2}), errTypes.revert) // max level

        await mineEmpiredrill.upgradeCapacityLevel(1, {from: acc2})
        balance = await iron.balanceOf(acc2)
        assert.equal(balance, "60000")
        let capacityAmount = await mineEmpiredrill.getDrillCapacity(1)
        assert.equal(capacityAmount, "2000")
        await mineEmpiredrill.upgradeCapacityLevel(1, {from: acc2})
        balance = await iron.balanceOf(acc2)
        assert.equal(balance, "40000")
        capacityAmount = await mineEmpiredrill.getDrillCapacity(1)
        assert.equal(capacityAmount, "3000")
        await tryCatch(mineEmpiredrill.upgradeCapacityLevel(1, {from: acc2}), errTypes.revert)
    })
})