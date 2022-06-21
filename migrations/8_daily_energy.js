var DailyEnergy = artifacts.require("./DailyEnergy.sol");

module.exports = function (deployer) {
  deployer.deploy(DailyEnergy);
};
