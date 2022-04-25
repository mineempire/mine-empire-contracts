const BasicMiner = artifacts.require("./BasicMiner.sol");

contract("BasicMiner", accounts => {

    let contract;
    let owner = accounts[0];
    let nonOwner = accounts[1];
    let tryCatch = require("./exceptions.js").tryCatch;
    let errTypes = require("./exceptions.js").errTypes;
    before(async ()=> {
        contract = await BasicMiner.deployed();
    })

    it("should get deployed", async () => {
        assert.notEqual(contract, "");
    });

    it("should minted a miner", async () => {
        const result = await contract.mintMiner({value: web3.utils.toWei('20', 'ether')});
        let miners = await contract.getAllMiners();
        assert.equal(miners.length, 1);
    });

    it("should revert mint", async () => {
        await tryCatch(contract.mintMiner({value: web3.utils.toWei('19', 'ether')}), errTypes.revert);
    });

    it("should update mint price", async () => {
        await contract.setMintPrice(web3.utils.toWei('30', 'ether'), {from: owner});
        const newMintPrice = await contract.getMintPrice();
        assert.equal(newMintPrice, web3.utils.toWei('30', 'ether'));
    })

    it("should fail to update mint price", async () => {
        await tryCatch(contract.setMintPrice(web3.utils.toWei('40', 'ether'), {from: nonOwner}), errTypes.revert);
        let newMintPrice = await contract.getMintPrice();
        assert.equal(newMintPrice.toString(), web3.utils.toWei('30', 'ether'));
        await contract.setMintPrice(web3.utils.toWei('20', 'ether'), {from: owner});
        newMintPrice = await contract.getMintPrice();
        assert.equal(newMintPrice, web3.utils.toWei('20', 'ether'));

    })

    // it("should upgrade mining power", async () => {
    //     const minerOwner = await contract.getMinerOwner(1);
    //     assert.equal(minerOwner, owner);
    //     let miner = await contract.getMiner(1);
    //     assert.equal(miner.miningLevel, 1);
    //     await contract.upgradeMiningLevel(1, {from: owner});
    //     miner = await contract.getMiner(1);
    //     assert.equal(miner.miningLevel, 2);
    // })

    // now private
    // it("should upgrade mining level", async () => {
    //     let miners = await contract.getAllMiners();
    //     assert.equal(miners.length, 1);
    //     let miner = miners[0];
    //     assert.equal(miner.minerId.toString(), '1');
    //     let minerOwner = await contract.getMinerOwner(miner.minerId);
    //     assert.equal(minerOwner, owner);

    //     await contract.mintMiner({value: web3.utils.toWei('20', 'ether'), from: nonOwner});
    //     miners = await contract.getAllMiners();
    //     assert.equal(miners.length, 2);
    //     miner = miners[1];
    //     assert.equal(miner.minerId.toString(), '2');
    //     assert.equal(miner.miningLevel.toString(), '1');
    //     minerOwner = await contract.getMinerOwner(miner.minerId);
    //     assert.equal(minerOwner, nonOwner);

    //     const newUpgrader = accounts[2];
    //     await contract.setUpgrader(newUpgrader, {from: owner});
    //     await contract.setMiningLevel(2, 2, {from: newUpgrader});
    //     miner = await contract.getMiner(2);
    //     assert.equal(miner.miningLevel.toString(), '2');
    // })

});