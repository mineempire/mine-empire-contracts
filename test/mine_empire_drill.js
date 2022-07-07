const MineEmpireDrill = artifacts.require("./MineEmpireDrill.sol");
const CosmicCash = artifacts.require("./CosmicCash.sol");

contract("MineEmpireDrill", (accounts) => {
  let mineEmpireDrill;
  let cosmicCash;
  let owner = accounts[0];
  let nonOwner = accounts[1];
  let acc2 = accounts[2];
  let treasury = accounts[3];
  let acc3 = accounts[4];
  let acc4 = accounts[5];
  let tryCatch = require("./exceptions.js").tryCatch;
  let errTypes = require("./exceptions.js").errTypes;
  let nullAddr = "0x0000000000000000000000000000000000000000";

  before(async () => {
    cosmicCash = await CosmicCash.deployed();
    mineEmpireDrill = await MineEmpireDrill.deployed();
  });

  it("should be deployed", async () => {
    assert.notEqual(mineEmpireDrill, "");
    assert.notEqual(cosmicCash, "");
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
      3,
      ["100", "110", "121"],
      ["0", "1000", "2000"]
    );
    // should not add again
    await tryCatch(
      mineEmpireDrill.addNewDrillType(
        1,
        "Basic Drill",
        3,
        ["100", "110", "121"],
        ["0", "1000", "2000"]
      ),
      errTypes.revert
    );
  });

  it("should update upgrade requirements", async () => {
    await mineEmpireDrill.updateUpgradeRequirement(1, 2, "1500");
    const upgradeRequirement = await mineEmpireDrill.getUpgradeRequirement(
      1,
      2
    );
    assert.equal(upgradeRequirement, "1500");
    // type deosn't exist
    await tryCatch(
      mineEmpireDrill.updateUpgradeRequirement(2, 2, "1500"),
      errTypes.revert
    );
    // level doesn't exist
    await tryCatch(
      mineEmpireDrill.updateUpgradeRequirement(1, 3, "1500"),
      errTypes.revert
    );
  });

  it("should set treasury address", async () => {
    await mineEmpireDrill.updateTreasuryAddress(treasury);
  });

  it("should add alt mint type", async () => {
    await mineEmpireDrill.addAlternativeMint(
      1,
      1,
      0,
      cosmicCash.address,
      "100",
      "3",
      "0"
    );

    await mineEmpireDrill.addAlternativeMint(
      1,
      1,
      0,
      cosmicCash.address,
      "90",
      "3",
      "0"
    );
  });

  it("should alt mint a drill", async () => {
    let cscBal = await cosmicCash.balanceOf(treasury);
    assert.equal(cscBal, "0");
    await cosmicCash.mint(acc2, "420", { from: owner });
    await cosmicCash.approve(mineEmpireDrill.address, "1000", { from: acc2 });
    let acc2Bal = await cosmicCash.balanceOf(acc2);
    assert.equal(acc2Bal, "420");

    await mineEmpireDrill.alternativeMintDrill(1, {
      from: acc2,
    });

    const drill = await mineEmpireDrill.getDrill(1);
    assert.equal(drill.drillId, "1");
    assert.equal(drill.drillType, "1");
    assert.equal(drill.level, "0");

    cscBal = await cosmicCash.balanceOf(treasury);
    assert.equal(cscBal, "90");
    acc2Bal = await cosmicCash.balanceOf(acc2);
    assert.equal(acc2Bal, "330");

    await mineEmpireDrill.alternativeMintDrill(1, { from: acc2 });
    await mineEmpireDrill.alternativeMintDrill(1, { from: acc2 });
    await tryCatch(
      mineEmpireDrill.alternativeMintDrill(1, { from: acc2 }),
      errTypes.revert
    );
  });

  it("should mint a lv2 drill", async () => {
    await mineEmpireDrill.addAlternativeMint(
      2,
      1,
      2,
      cosmicCash.address,
      "150",
      "1",
      "0"
    );

    let cscBal = await cosmicCash.balanceOf(treasury);
    assert.equal(cscBal, "270");

    await mineEmpireDrill.alternativeMintDrill(2, { from: acc2 });
    const drill = await mineEmpireDrill.getDrill(4);
    assert.equal(drill.level, "2");

    cscBal = await cosmicCash.balanceOf(treasury);
    assert.equal(cscBal, "420");
  });

  it("should mint cosmic cash to acc2", async () => {
    await cosmicCash.mint(acc2, "1000000");
  });

  it("should set cosmic cash", async () => {
    await mineEmpireDrill.updateCosmicCash(cosmicCash.address);
  });

  it("should not be able to upgrade drill because drill doesnt exist", async () => {
    await tryCatch(
      mineEmpireDrill.upgradeDrill(2, { from: acc2 }),
      errTypes.revert
    );
  });

  it("should not be able to upgrade drill because not owner of drill", async () => {
    await tryCatch(
      mineEmpireDrill.upgradeDrill(1, { from: owner }),
      errTypes.revert
    );
  });

  it("should not be able to upgrade because resource not approved", async () => {
    await tryCatch(
      mineEmpireDrill.upgradeDrill(1, { from: acc2 }),
      errTypes.revert
    );
  });

  it("should upgrade drill", async () => {
    let balance = await cosmicCash.balanceOf(acc2);
    assert.equal(balance, "1000000");
    let drill = await mineEmpireDrill.getDrill(1);
    assert.equal(drill.level, "0");
    assert.equal(drill.drillType, "1");
    let miningPower = await mineEmpireDrill.getMiningPower(1);
    assert.equal(miningPower, "100");

    await cosmicCash.approve(mineEmpireDrill.address, "1000000", {
      from: acc2,
    });
    await mineEmpireDrill.upgradeDrill(1, { from: acc2 });

    balance = await cosmicCash.balanceOf(acc2);
    assert.equal(balance, "999000");
    drill = await mineEmpireDrill.getDrill(1);
    assert.equal(drill.level, "1");
    assert.equal(drill.drillType, "1");
    miningPower = await mineEmpireDrill.getMiningPower(1);
    assert.equal(miningPower, "110");

    await mineEmpireDrill.upgradeDrill(1, { from: acc2 });

    balance = await cosmicCash.balanceOf(acc2);
    assert.equal(balance, "997500");
    drill = await mineEmpireDrill.getDrill(1);
    assert.equal(drill.level, "2");
    assert.equal(drill.drillType, "1");
    miningPower = await mineEmpireDrill.getMiningPower(1);
    assert.equal(miningPower, "121");
  });

  it("should not be able to upgrade because max level", async () => {
    await tryCatch(
      mineEmpireDrill.upgradeDrill(1, { from: acc2 }),
      errTypes.revert
    );
  });
});
