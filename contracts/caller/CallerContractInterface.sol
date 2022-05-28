// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0 <=0.8.14;

interface CallerContractInterface {
  function callback(uint256 _ethPrice, uint256 id) external;
}
