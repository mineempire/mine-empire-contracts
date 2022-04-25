const Coal = artifacts.require("./Coal.sol");

contract("Coal", accounts => {

    // let coal;
    // let owner = accounts[0];
    // let acc2 = accounts[1];
    // let tryCatch = require("./exceptions.js").tryCatch;
    // let errTypes = require("./exceptions.js").errTypes;
    // before(async () => {
    //     coal = await Coal.deployed();
    // });

    // it("should get deployed", async () => {
    //     assert.notEqual(coal, "");
    // })

    // it("should mint to acc2", async () => {
    //     await coal.mint(acc2, 10000);
    //     const amt = await coal.balanceOf(acc2);
    //     assert.equal(amt.toString(), '10000');
    // })

    // it("should not mint because not owner", async () => {
    //     await tryCatch(coal.mint(acc2, 50000, {from: acc2}), errTypes.revert);
    //     const amt = await coal.balanceOf(acc2);
    //     assert.equal(amt.toString(), '10000');
    // })

    // it("should grant minter role to acc2", async () => {
    //     const rolehash = web3.utils.keccak256('MINTER_ROLE')
    //     let role = await coal.hasRole(rolehash, acc2);
    //     assert.equal(role, false);
    //     await coal.grantRole(rolehash, acc2);
    //     role = await coal.hasRole(rolehash, acc2);
    //     assert.equal(role, true);
    // })

    // it("should mint from acc2", async () => {
    //     await coal.mint(acc2, 50000, {from: acc2});
    //     const amt = await coal.balanceOf(acc2);
    //     assert.equal(amt.toString(), '60000');
    // })
})