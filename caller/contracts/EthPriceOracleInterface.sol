// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0 <=0.8.14;

interface EthPriceOracleInterface {
  function getLatestEthPrice() external returns (uint256);
}
