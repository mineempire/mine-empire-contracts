// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/presets/ERC20PresetMinterPauser.sol";

contract CSCMinter {
    ERC20PresetMinterPauser public cosmicCash;

    constructor(ERC20PresetMinterPauser _cosmicCash) {
        cosmicCash = _cosmicCash;
    }

    function getCSC() public {
        cosmicCash.mint(msg.sender, 1000000000000000000000);
    }
}