const MineEmpireDrill = artifacts.require("./MineEmpireDrill.sol");
const Gades = artifacts.require("./Gades.sol");
const Iron = artifacts.require("./Iron.sol");
const CosmicCash = artifacts.require("./CosmicCash.sol");

contract("Gades", (accounts) => {
  let mineEmpireDrill;
  let iron;
  let cosmicCash;
  let gades;
  let owner = accounts[0];
  let nonOwner = accounts[1];
  let acc2 = accounts[2];
  let treasury = accounts[3];
  let tryCatch = require("./exceptions.js").tryCatch;
  let errTypes = require("./exceptions.js").errTypes;
  let nullAddr = "0x0000000000000000000000000000000000000000";
  const helper = require("./helpers/truffleTestHelper.js");

  before(async () => {
    cosmicCash = await CosmicCash.deployed();
    mineEmpireDrill = await MineEmpireDrill.deployed();
    iron = await Iron.deployed();
    gades = await Gades.deployed();
  });

  it("should be deployed", async () => {
    assert.notEqual(mineEmpireDrill, "");
    assert.notEqual(iron, "");
    assert.notEqual(cosmicCash, "");
    assert.notEqual(gades, "");
  });

  it("should add a new drill type", async () => {
    /*
        type: 1
        name: Basic Drill
        mintPrice: 20e18
        nativeCurrency: true
        address: 0x0
        maxLevel: 3
        miningPower: [100, 110, 121]
         */
    await mineEmpireDrill.addNewDrillType(
      1,
      "Basic Drill",
      "2000000000000000000",
      3,
      ["100", "110", "121"],
      ["0", "1000", "2000"]
    );
    // should not add again
    await tryCatch(
      mineEmpireDrill.addNewDrillType(
        1,
        "Basic Drill",
        "2000000000000000000",
        3,
        ["100", "110", "121"],
        ["0", "1000", "2000"]
      ),
      errTypes.revert
    );
    const mintPrice = await mineEmpireDrill.getMintPrice(1, 0);
    assert.equal(mintPrice, "2000000000000000000");
  });

  it("should set mine empire treasury address", async () => {
    await mineEmpireDrill.updateTreasuryAddress(treasury);
  });

  it("should mint two drills", async () => {
    let balance = await web3.eth.getBalance(treasury);
    assert.equal(balance, web3.utils.toWei("100", "ether"));

    await mineEmpireDrill.mintDrill(1, 0, {
      from: acc2,
      value: web3.utils.toWei("2", "ether"),
    });
    let drill = await mineEmpireDrill.getDrill(1);
    assert.equal(drill.drillId, "1");
    assert.equal(drill.drillType, "1");
    assert.equal(drill.level, "0");

    balance = await web3.eth.getBalance(treasury);
    assert.equal(balance, web3.utils.toWei("102", "ether"));

    await mineEmpireDrill.mintDrill(1, 0, {
      from: acc2,
      value: web3.utils.toWei("2", "ether"),
    });
    drill = await mineEmpireDrill.getDrill(2);
    assert.equal(drill.drillId, "2");
    assert.equal(drill.drillType, "1");
    assert.equal(drill.level, "0");
  });

  it("should not stake because not approved", async () => {
    await tryCatch(gades.stake(1, { from: acc2 }), errTypes.revert);
  });

  it("should approve for spend", async () => {
    await mineEmpireDrill.approve(gades.address, 1, { from: acc2 });
    const approved = await mineEmpireDrill.getApproved(1);
    assert.equal(approved, gades.address);
  });

  it("should not be able to stake someone elses drill", async () => {
    await tryCatch(gades.stake(1, { from: owner }), errTypes.revert);
  });

  it("should stake drill", async () => {
    await gades.stake(1, { from: acc2 });
    const owner = await mineEmpireDrill.ownerOf(1);
    assert.equal(owner, gades.address);

    const stake = await gades.getStake(acc2);
    assert.equal(stake.drill.drillId, 1);
  });

  it("should not stake because already staked", async () => {
    await tryCatch(gades.stake(2, { from: acc2 }), errTypes.revert);
    const owner = await mineEmpireDrill.ownerOf(2);
    assert.equal(owner, acc2);
  });

  it("should not be able to unstake if not staked", async () => {
    await tryCatch(gades.unstake({ from: owner }), errTypes.revert);
  });

  // buggy
  // it('should have 0 accumulated iron because timestamp diff is 0', async () => {
  //     const ironAmt = await gades.getAccumulatedIron(acc2)
  //     assert.equal(ironAmt, '0')
  // })

  it("should go forward in blocks an accumulate resources", async () => {
    let stake = await gades.getStake(acc2);
    assert.equal(stake.drill.drillId, 1);

    // 500 seconds at 3941e13 base production = 1.9705E19
    // randomly can be 501 seconds
    await helper.advanceTimeAndBlock(500);

    let rewards = await gades.getAccumulatedIron(acc2);
    if (
      !(rewards == "19705000000000000000" || rewards == "19744410000000000000")
    ) {
      assert.fail("wrong amount of rewards: " + rewards);
    }

    let curIronBalance = await iron.balanceOf(acc2);
    assert.equal(curIronBalance, 0);

    await iron.mint(
      gades.address,
      web3.utils.toBN("100000000000000000000000"),
      {
        from: owner,
      }
    );
    let gadesIronBal = await iron.balanceOf(gades.address);
    assert.equal(gadesIronBal, "100000000000000000000000");

    await gades.unstake({ from: acc2 });
    curIronBalance = await iron.balanceOf(acc2);
    if (
      !(
        curIronBalance == "19705000000000000000" ||
        curIronBalance == "19744410000000000000"
      )
    ) {
      assert.fail("wrong iron balance: " + curIronBalance);
    }
  });

  it("should accumulate max amount", async () => {
    await mineEmpireDrill.approve(gades.address, 1, { from: acc2 });
    await gades.stake(1, { from: acc2 });
    stake = await gades.getStake(acc2);
    assert.equal(stake.drill.drillId, 1);

    // max lv0 capacity 10215e18, 260,000 seconds required
    await helper.advanceTimeAndBlock(260000);
    let rewards = await gades.getAccumulatedIron(acc2);
    assert.equal(rewards.toString(), "10215000000000000000000");

    await helper.advanceTimeAndBlock(260000);
    rewards = await gades.getAccumulatedIron(acc2);
    assert.equal(rewards.toString(), "10215000000000000000000");
    const balBefore = await iron.balanceOf(acc2);

    await gades.unstake({ from: acc2 });
    let balAfter = await iron.balanceOf(acc2);
    assert.equal(
      balAfter.toString(),
      Number(balBefore) + 10215000000000000000000
    );
  });

  it("should approve CSC spend", async () => {
    await cosmicCash.mint(
      acc2,
      web3.utils.toBN("100000000000000000000", { from: owner })
    );
    await cosmicCash.approve(gades.address, "100000000000000000000", {
      from: acc2,
    });
    await gades.updateTreasury(treasury);
  });

  it("should upgrade gades capacity", async () => {
    let cscBal = await cosmicCash.balanceOf(acc2);
    assert.equal(cscBal.toString(), "100000000000000000000");
    let userLevel = await gades.getUserLevel(acc2);
    assert.equal(userLevel, 0);
    await gades.upgrade({ from: acc2 });
    cscBal = await cosmicCash.balanceOf(acc2);
    assert.equal(cscBal.toString(), "75000000000000000000");
    userLevel = await gades.getUserLevel(acc2);
    assert.equal(userLevel, 1);

    await mineEmpireDrill.approve(gades.address, 1, { from: acc2 });
    await gades.stake(1, { from: acc2 });

    // max capacity should be 11747e18, 298,071 sec
    await helper.advanceTimeAndBlock(299000);
    let rewards = await gades.getAccumulatedIron(acc2);
    assert.equal(rewards.toString(), "11747000000000000000000");

    await gades.upgrade({ from: acc2 });
    cscBal = await cosmicCash.balanceOf(acc2);
    assert.equal(cscBal.toString(), "50000000000000000000");

    // only need 1.762E21 more iron to fill up new capacity, 44,709 sec
    await helper.advanceTimeAndBlock(45000);
    rewards = await gades.getAccumulatedIron(acc2);
    assert.equal(rewards.toString(), "13509000000000000000000");
  });

  it("should max out capacity", async () => {
    await cosmicCash.mint(
      acc2,
      web3.utils.toBN("1000000000000000000000", { from: owner })
    );
    await cosmicCash.approve(gades.address, "1000000000000000000000", {
      from: acc2,
    });
    let curLevel = await gades.getUserLevel(acc2);
    assert.equal(curLevel, 2);
    await gades.upgrade({ from: acc2 });
    curLevel = await gades.getUserLevel(acc2);
    assert.equal(curLevel, 3);
    await gades.upgrade({ from: acc2 });
    curLevel = await gades.getUserLevel(acc2);
    assert.equal(curLevel, 4);
    await gades.upgrade({ from: acc2 });
    curLevel = await gades.getUserLevel(acc2);
    assert.equal(curLevel, 5);
    await gades.upgrade({ from: acc2 });
    curLevel = await gades.getUserLevel(acc2);
    assert.equal(curLevel, 6);
    await gades.upgrade({ from: acc2 });
    curLevel = await gades.getUserLevel(acc2);
    assert.equal(curLevel, 7);
    await gades.upgrade({ from: acc2 });
    curLevel = await gades.getUserLevel(acc2);
    assert.equal(curLevel, 8);
    await gades.upgrade({ from: acc2 });
    curLevel = await gades.getUserLevel(acc2);
    assert.equal(curLevel, 9);

    // max level
    await tryCatch(gades.upgrade({ from: acc2 }), errTypes.revert);

    await helper.advanceTimeAndBlock(4000000);
    const rewards = await gades.getAccumulatedIron(acc2);
    assert.equal(rewards.toString(), "125985000000000000000000");
  });

  // it("should have base production reduced", async () => {
  //   let curPeriod = await gades.getCurrentPeriod();
  //   assert.equal(curPeriod.toString(), "0");
  //   let curProduction = await gades.getBaseProduction();
  //   assert.equal(curProduction.toString(), "39410000000000000");

  //   await helper.advanceTimeAndBlock(2592000);
  //   curProduction = await gades.getBaseProduction();
  //   curPeriod = await gades.getCurrentPeriod();
  //   assert.equal(curPeriod.toString(), "1");
  //   assert.equal(curProduction.toString(), "33500000000000000");
  // });
});
