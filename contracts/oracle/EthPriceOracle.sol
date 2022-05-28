// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0 <=0.8.14;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./EthPriceOracleInterface.sol";
import "../caller/CallerContractInterface.sol";

contract EthPriceOracle is AccessControl, EthPriceOracleInterface {

  using SafeMath for uint256;
  uint private randNonce = 0;
  uint private modulus = 1000;
  uint private numOracles = 0;
  uint private THRESHOLD = 0;

  mapping(uint256=>bool) pendingRequests;
  mapping (uint256=>Response[]) public requestIdToResponse;

  struct Response {
    address oracleAddress;
    address callerAddress;
    uint256 ethPrice;
  }

  bytes32 public constant OWNER_ROLE = keccak256("OWNER_ROLE");
  bytes32 public constant ORACLE_ROLE = keccak256("ORACLE_ROLE");

  event GetLatestEthPriceEvent(address callerAddress, uint id);
  event SetLatestEthPriceEvent(uint256 ethPrice, address callerAddress);
  event AddOracleEvent(address oracleAddress);
  event RemoveOracleEvent(address oracleAddress);
  event SetThresholdEvent(uint threshold);

  constructor (address _owner) {
    _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    _setupRole(OWNER_ROLE, _owner);
  }

  function addOracle (address _oracle) public onlyRole(OWNER_ROLE) {
    require(!hasRole(ORACLE_ROLE, _oracle), "Already an oracle!");
    grantRole(ORACLE_ROLE, _oracle);
    numOracles++;
    emit AddOracleEvent(_oracle);
  }

  function removeOracle (address _oracle) public onlyRole(OWNER_ROLE) {
    require(hasRole(ORACLE_ROLE, _oracle), "Not an oracle!");
    require (numOracles > 1, "Do not remove the last oracle!");
    revokeRole(ORACLE_ROLE, _oracle);
    numOracles--;
    emit RemoveOracleEvent(_oracle);
  }

  function setThreshold (uint _threshold) public onlyRole(OWNER_ROLE) {
    THRESHOLD = _threshold;
    emit SetThresholdEvent(THRESHOLD);
  }

  function getLatestEthPrice() public returns (uint256) {
    randNonce++;
    uint id = uint(keccak256(abi.encodePacked(block.timestamp, msg.sender, randNonce))) % modulus;
    pendingRequests[id] = true;
    emit GetLatestEthPriceEvent(msg.sender, id);
    return id;
  }

  function setLatestEthPrice(uint256 _ethPrice, address _callerAddress, uint256 _id) public onlyRole(ORACLE_ROLE) {
    require(pendingRequests[_id], "This request is not in my pending list.");
    Response memory resp;
    resp = Response(msg.sender, _callerAddress, _ethPrice);
    requestIdToResponse[_id].push(resp);
    uint numResponses = requestIdToResponse[_id].length;
    if (numResponses == THRESHOLD) {
      uint computedEthPrice = 0;
      for (uint f=0; f < requestIdToResponse[_id].length; f++) {
        computedEthPrice = computedEthPrice.add(requestIdToResponse[_id][f].ethPrice);
      }
      computedEthPrice = computedEthPrice.div(numResponses);
      delete pendingRequests[_id];
      delete requestIdToResponse[_id];
      CallerContractInterface callerContractInstance;
      callerContractInstance = CallerContractInterface(_callerAddress);
      callerContractInstance.callback(computedEthPrice, _id);
      emit SetLatestEthPriceEvent(computedEthPrice, _callerAddress);
    }
  }
}
