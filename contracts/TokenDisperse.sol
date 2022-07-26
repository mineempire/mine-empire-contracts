// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract TokenDisperse {
    constructor() {}

    function disperse(IERC20 token, address[] memory users, uint numUsers, uint amount) public {
        for (uint i = 0; i < numUsers; i++) {
            token.transfer(users[i], amount);
        }
    }
}