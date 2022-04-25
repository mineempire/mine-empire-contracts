const BasicMiner = artifacts.require("./BasicMiner.sol");
const CoalMine = artifacts.require("./CoalMine.sol");
const Coal = artifacts.require("./Coal.sol");

contract("CoalMine", accounts => {

    let basicMiner;
    let coalMine;
    let coal;
    let owner = accounts[0];
    let acc2 = accounts[1];
    let acc3 = accounts[2];
    let acc4 = accounts[3];
    let tryCatch = require("./exceptions.js").tryCatch;
    let errTypes = require("./exceptions.js").errTypes;
    const helper = require("./helpers/truffleTestHelper.js");
    before(async () => {
        basicMiner = await BasicMiner.new();
        coalMine = await CoalMine.new();
        coal = await Coal.new();
    });

    it("should get deployed", async () => {
        assert.notEqual(basicMiner, "");
        assert.notEqual(coalMine, "");
        assert.notEqual(coal, "");
    });

    it("miner minter contract address should be 0x0", async () => {
        const addr = await coalMine.getMinerContract();
        assert.equal(addr, '0x0000000000000000000000000000000000000000')
    });

    it("should not set miner contract", async () => {
        await tryCatch(coalMine.setMinerContract(basicMiner.address, {from: acc2}), errTypes.revert);
    });

    it("should set miner contract", async () => {
        await coalMine.setMinerContract(basicMiner.address, {from: owner});
        const addr = await coalMine.getMinerContract();
        assert.equal(addr, basicMiner.address);
    });

    it("should mint a miner", async () => {
        await basicMiner.mintMiner({value: web3.utils.toWei('20', 'ether'), from: acc3});
        const owner = await basicMiner.getMinerOwner(1);
        assert.equal(owner, acc3);
    });

    it("should not be able to stake because not approved", async () => {
        await tryCatch(coalMine.stake(1, {from: acc3}), errTypes.revert);
    })

    it("should set approval", async () => {
        await basicMiner.approve(coalMine.address, 1, {from: acc3});
        const approved = await basicMiner.getApproved(1);
        assert.equal(approved, coalMine.address);
    })

    it("should not be able to stake because not owner of token", async () => {
        await tryCatch(coalMine.stake(1, {from: owner}), errTypes.revert);
    })

    it("should stake", async () => {
        await coalMine.stake(1, {from: acc3});
        const owner = await basicMiner.getMinerOwner(1);
        assert.equal(owner, coalMine.address);

        const stake = await coalMine.getStake(acc3);
        assert.equal(stake.miner.minerId, 1);
    })

    it("should not be able to stake another miner", async () => {
        await basicMiner.mintMiner({value: web3.utils.toWei('20', 'ether'), from: acc3});
        const owner = await basicMiner.getMinerOwner(2);
        assert.equal(owner, acc3);

        await basicMiner.approve(coalMine.address, 2, {from: acc3});

        await tryCatch(coalMine.stake(2, {from: acc3}), errTypes.revert);

        const stake = await coalMine.getStake(acc3);
        assert.equal(stake.miner.minerId, 1);
    })

    it("should not be able to stake someone else's miner", async () => {
        await basicMiner.mintMiner({value: web3.utils.toWei('20', 'ether'), from: acc2});
        const owner = await basicMiner.getMinerOwner(3);
        assert.equal(owner, acc2);

        await basicMiner.approve(coalMine.address, 3, {from: acc2});

        await tryCatch(coalMine.stake(3, {from: acc4}), errTypes.revert);

        let stake = await coalMine.getStake(acc3);
        assert.equal(stake.miner.minerId, 1);
        stake = await coalMine.getStake(acc2);
        assert.equal(stake.miner.minerId, 0);
        stake = await coalMine.getStake(acc4);
        assert.equal(stake.miner.minerId, 0);
    })

    it("should not be able to unstake if not staked", async () => {
        await tryCatch(coalMine.unstake({from: acc2}), errTypes.revert);
    })

    it("should unstake a staked miner", async () => {
        let stake = await coalMine.getStake(acc3);
        assert.equal(stake.miner.minerId, 1);
        let owner = await basicMiner.getMinerOwner(1);
        assert.equal(owner, coalMine.address);

        await coalMine.unstake({from: acc3});
        stake = await coalMine.getStake(acc3);
        assert.equal(stake.miner.minerId, 0);
        owner = await basicMiner.getMinerOwner(1);
        assert.equal(owner, acc3);
    })

    // coal erc20

    it("should mint to coal and set resource", async () => {
        let balance = await coal.balanceOf(coalMine.address);
        assert.equal(balance, 0);

        await coal.mint(coalMine.address, 100, {from: owner});
        balance = await coal.balanceOf(coalMine.address);
        assert.equal(balance, 100);
        
        await coalMine.setResourceContract(coal.address, {from: owner});
        const addr = await coalMine.getResourceContract();
        assert.equal(addr, coal.address);
    })

    it("should stake and accumulate rewards", async () => {
        let stake = await coalMine.getStake(acc3);
        assert.equal(stake.timestamp, 0);

        await basicMiner.approve(coalMine.address, 1, {from: acc3});
        const approved = await basicMiner.getApproved(1);
        assert.equal(approved, coalMine.address);

        await coalMine.stake(1, {from: acc3});
        stake = await coalMine.getStake(acc3);
        assert.notEqual(stake.timestamp, 0);

        // mint rewards to coalMine
        await coal.mint(coalMine.address, web3.utils.toBN('1000000000000000000000'), {from: owner});
        let mineBal = await coal.balanceOf(coalMine.address);
        assert.equal(mineBal.toString(), '1000000000000000000100');

        let acc3bal = await coal.balanceOf(acc3);
        assert.equal(acc3bal.toString(), '0');
        
        // 500 seconds at 1e16 production per second and 1.00 mining power = 500e16 rewards
        await helper.advanceTimeAndBlock(500);

        let rewards = await coalMine.getAccumulatedResources({from: acc3});
        assert.equal(rewards.toString(), '5000000000000000000');

        // 500e16 coal should move to acc3 (sometimes 501)
        await coalMine.collectResources({from: acc3});
        acc3bal = await coal.balanceOf(acc3);
        if (!(acc3bal.toString() == '5000000000000000000' || 
            acc3bal.toString() == '5010000000000000000')) {
            assert.fail('not expected amount');
        }

        rewards = await coalMine.getAccumulatedResources({from: acc3});
        assert.equal(rewards.toString(), '0');

        // 1000 yields 1000e16 = 1e19 which is greater than capacity of 6e18. should get 6e18 rewards
        await helper.advanceTimeAndBlock(10000);

        rewards = await coalMine.getAccumulatedResources({from: acc3});
        assert.equal(rewards.toString(), '6000000000000000000');

        // 6e18 coal should move to acc3
        await coalMine.collectResources({from: acc3});
        acc3bal = await coal.balanceOf(acc3);
        assert.equal(acc3bal.toString(), '11000000000000000000');

        rewards = await coalMine.getAccumulatedResources({from: acc3});
        assert.equal(rewards.toString(), '0');
    })
})