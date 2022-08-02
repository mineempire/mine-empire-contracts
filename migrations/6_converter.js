var Converter = artifacts.require("./Converter.sol");

module.exports = function (deployer) {
  deployer.deploy(Converter);
};
