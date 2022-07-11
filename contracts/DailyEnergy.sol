// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Energy.sol";

contract DailyEnergy {
    Energy public energy;
    address public owner;
    uint MAX_ENERGY;
    uint AMOUNT_PER_SECOND;
    mapping(address => uint) lastClaimed;
    mapping(address => uint) userMultiplier;


    constructor() {
        owner = msg.sender;
        MAX_ENERGY = 30e18;
        AMOUNT_PER_SECOND = 1157e11;
    }

    // MODIFIERS
    modifier onlyOwner(address _address) {
        require(_address == owner, "not authorized");
        _;
    }

    function setEnergy(Energy _energy) public onlyOwner(msg.sender) {
        energy = _energy;
    }

    function getAccumulatedEnergy(address _address) public view returns (uint) {
        uint amount = 0;
        if (lastClaimed[_address] == 0) {
            amount = MAX_ENERGY;
        } else {
            uint time = block.timestamp - lastClaimed[_address];
            amount = time * AMOUNT_PER_SECOND;
            if (userMultiplier[_address] > 0) {
                amount = amount * 100 / userMultiplier[_address];
            }
        }
        if (amount > MAX_ENERGY) {
            amount = MAX_ENERGY;
        }
        return amount;
    }

    function claimEnergy() public {
        uint amount = getAccumulatedEnergy(msg.sender);
        lastClaimed[msg.sender] = block.timestamp;
        energy.mint(msg.sender, amount);
    }
}