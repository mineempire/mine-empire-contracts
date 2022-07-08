// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract GEMVest {
    address public treasury;
    ERC20 public GEM;
    uint GENESIS;
    uint PERIOD = 7 days;
    uint UNLOCK_PER_PERIOD = 100e18;
    uint claimedPeriods = 0;

    constructor(uint _genesis, ERC20 _GEM, address _treasury) {
        GEM = _GEM;
        GENESIS = _genesis;
        treasury = _treasury;
    }

    modifier onlyTreasury(address _address) {
        require(_address == treasury, "only treasury can take action");
        _;
    }

    function claim() public onlyTreasury(msg.sender) {
        uint unclaimedTime = block.timestamp - (GENESIS + claimedPeriods * PERIOD);
        uint unclaimedPeriods = unclaimedTime / PERIOD;
        if (unclaimedPeriods == 0) return;
        uint amount = unclaimedPeriods * UNLOCK_PER_PERIOD;
        claimedPeriods = claimedPeriods + unclaimedPeriods;
        GEM.transfer(treasury, amount);
    }

    function updateTreasury(address _address) public onlyTreasury(msg.sender) {
        treasury = _address;
    }
}