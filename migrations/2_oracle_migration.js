const Oracle = artifacts.require("oracle/EthPriceOracle");
const fs = require('fs');
const oracleContractAddress = fs.readFileSync(".secret_oracle_address").toString().trim();

module.exports = function (deployer) {
  deployer.deploy(Oracle, oracleContractAddress);
};
