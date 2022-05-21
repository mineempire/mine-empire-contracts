const MineEmpireDrillv2 = artifacts.require('./MineEmpireDrillv2.sol')
const CosmicCash = artifacts.require('./CosmicCash.sol')

contract('MineEmpireDrillv2', accounts => {
    let mineEmpireDrillv2
    let cosmicCash
    let owner = accounts[0]
    let nonOwner = accounts[1]
    let acc2 = accounts[2]
    let treasury = accounts[3]
    let tryCatch = require('./exceptions.js').tryCatch
    let errTypes = require('./exceptions.js').errTypes
    let nullAddr = '0x0000000000000000000000000000000000000000'

    before(async () => {
        cosmicCash = await CosmicCash.deployed()
        mineEmpireDrillv2 = await MineEmpireDrillv2.deployed()
    })

    it('should be deployed', async () => {
        assert.notEqual(mineEmpireDrillv2, '')
        assert.notEqual(cosmicCash, '')
    })

    it('should not update maxDrills, not owner', async () => {
        await tryCatch(mineEmpireDrillv2.updateMaxDrillCount(1, {from: nonOwner}), errTypes.revert)
        await mineEmpireDrillv2.updateMaxDrillCount(1, {from: owner})
    })

    it('should add a new drill type', async () => {
        /*
        type: 1
        name: Basic Drill
        mintPrice: 20e18
        nativeCurrency: true
        address: 0x0
        maxLevel: 3
        miningPower: [100, 110, 121]
         */
        await mineEmpireDrillv2.addNewDrillType(
            1,
            'Basic Drill',
            '2000000000000000000',
            true,
            nullAddr,
            3,
            ['100', '110', '121'],
            ['0', '1000', '2000']
        )
        // should not add again
        await tryCatch(
            mineEmpireDrillv2.addNewDrillType(
                1,
                'Basic Drill',
                '2000000000000000000',
                true,
                nullAddr,
                3,
                ['100', '110', '121'],
                ['0', '1000', '2000']
            ),
            errTypes.revert
        )
        const mintPrice = await mineEmpireDrillv2.getMintPrice(1)
        assert.equal(mintPrice, '2000000000000000000')
    })

    it('should update mint price', async () => {
        await mineEmpireDrillv2.updateMintPrice(1, '3000000000000000000')
        const mintPrice = await mineEmpireDrillv2.getMintPrice(1)
        assert.equal(mintPrice, '3000000000000000000')
    })

    it('should update upgrade requirements', async () => {
        await mineEmpireDrillv2.updateUpgradeRequirement(1, 2, '1500')
        const upgradeRequirement = await mineEmpireDrillv2.getUpgradeRequirement(1, 2)
        assert.equal(upgradeRequirement, '1500')
        // type deosn't exist
        await tryCatch(mineEmpireDrillv2.updateUpgradeRequirement(2, 2, '1500'), errTypes.revert)
        // level doesn't exist
        await tryCatch(mineEmpireDrillv2.updateUpgradeRequirement(1, 3, '1500'), errTypes.revert)
    })

    it('should set treasury address', async () => {
        await mineEmpireDrillv2.updateTreasuryAddress(treasury)
    })

    it('should mint a drill', async () => {
        let balance = await web3.eth.getBalance(treasury)
        assert.equal(balance, web3.utils.toWei('100', 'ether'))

        await mineEmpireDrillv2.mintDrill(1, {from: acc2, value: web3.utils.toWei('3', 'ether')})
        const drill = await mineEmpireDrillv2.getDrill(1)
        assert.equal(drill.drillId, '1')
        assert.equal(drill.drillType, '1')
        assert.equal(drill.level, '0')

        balance = await web3.eth.getBalance(treasury)
        assert.equal(balance, web3.utils.toWei('103', 'ether'))
    })

    it('should not mint because max drills', async () => {
        await tryCatch(mineEmpireDrillv2.mintDrill(1, {from: acc2, value: web3.utils.toWei('3', 'ether')}), errTypes.revert)
    })

    it('should mint cosmic cash to acc2', async () => {
        await cosmicCash.mint(acc2, '1000000')
    })

    it('should not be able to upgrade drill because drill doesnt exist', async () => {
        await tryCatch(mineEmpireDrillv2.upgradeDrill(2, {from: acc2}), errTypes.revert)
    })

    it('should not be able to upgrade drill because not owner of drill', async () => {
        await tryCatch(mineEmpireDrillv2.upgradeDrill(1, {from: owner}), errTypes.revert)
    })

    it('should not be able to upgrade because resource not approved', async () => {
        await tryCatch(mineEmpireDrillv2.upgradeDrill(1, {from: acc2}), errTypes.revert)
    })

    it('should upgrade drill', async () => {
        let balance = await cosmicCash.balanceOf(acc2)
        assert.equal(balance, '1000000')
        let drill = await mineEmpireDrillv2.getDrill(1)
        assert.equal(drill.level, '0')
        assert.equal(drill.drillType, '1')
        let miningPower = await mineEmpireDrillv2.getMiningPower(1)
        assert.equal(miningPower, '100')

        await cosmicCash.approve(mineEmpireDrillv2.address, web3.utils.toWei('1', 'ether'), {from: acc2})
        await mineEmpireDrillv2.upgradeDrill(1, {from: acc2})
        
        balance = await cosmicCash.balanceOf(acc2)
        assert.equal(balance, '999000')
        drill = await mineEmpireDrillv2.getDrill(1)
        assert.equal(drill.level, '1')
        assert.equal(drill.drillType, '1')
        miningPower = await mineEmpireDrillv2.getMiningPower(1)
        assert.equal(miningPower, '110')

        await mineEmpireDrillv2.upgradeDrill(1, {from: acc2})

        balance = await cosmicCash.balanceOf(acc2)
        assert.equal(balance, '997500')
        drill = await mineEmpireDrillv2.getDrill(1)
        assert.equal(drill.level, '2')
        assert.equal(drill.drillType, '1')
        miningPower = await mineEmpireDrillv2.getMiningPower(1)
        assert.equal(miningPower, '121')
    })

    it('should not be able to upgrade because max level', async () => {
        await tryCatch(mineEmpireDrillv2.upgradeDrill(1, {from: acc2}), errTypes.revert)
    })



})