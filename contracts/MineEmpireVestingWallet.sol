// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/finance/VestingWallet.sol";

contract MineEmpireVestingWallet is VestingWallet {
    uint64 DURATION = 106 weeks;
    constructor(address beneficiaryAddress) VestingWallet(beneficiaryAddress, uint64(block.timestamp), DURATION) {}
}