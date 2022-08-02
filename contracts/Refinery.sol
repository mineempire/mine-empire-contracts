// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract Refinery {
    address public owner;
    address public DEAD = 0x000000000000000000000000000000000000dEaD;
    uint public MAX_REFINERY_COUNT;
    uint public MAX_REFINERY_LEVEL;

    ERC20 public energy;

    // user, their unlocked refineires and the refinery levels
    mapping(address => uint) public userUnlockedRefineries;
    mapping(address => mapping(uint => uint)) public refineryLevel;
    
    // refinery unlock costs (0 - 4)
    struct UnlockCost {
        ERC20 resource;
        uint quantity;
    }
    mapping(uint => UnlockCost) public unlockCost;

    // refinery upgrade costs (1 - 10)
    struct UpgradeCost {
        ERC20 resource;
        uint quantity;
    }
    mapping(uint => UpgradeCost) public upgradeCost;

    constructor() {
        owner = msg.sender;
        MAX_REFINERY_COUNT = 5;
        MAX_REFINERY_LEVEL = 10;
    }

    // EVENTS
    event RefineryUnlocked(uint refinerNum);

    // MODIFIERS
    modifier onlyOwner(address _address) {
        require(_address == owner, "not authorized");
        _;
    }

    // ONLY OWNER
    function updateEnergy(ERC20 _energy) public onlyOwner(msg.sender) {
        energy = _energy;
    }

    function updateRefineryUpgradeCost(uint _level, ERC20 _resource, uint _quantity) public onlyOwner(msg.sender) {
        unlockCost[_level] = UnlockCost(_resource, _quantity);
    }

    // USER INTERFACE
    function unlockRefinery() public {
        uint curLocked = userUnlockedRefineries[msg.sender];
        require(curLocked <= MAX_REFINERY_COUNT, "all refineries unlocked");
        UnlockCost memory cost = unlockCost[curLocked];
        cost.resource.transferFrom(msg.sender, DEAD, cost.quantity);
        userUnlockedRefineries[msg.sender] = curLocked + 1;
        refineryLevel[msg.sender][curLocked] = 1;
        emit RefineryUnlocked(curLocked);
    }

    function upgradeRefinery(uint _idx) public {
        require(_idx < userUnlockedRefineries[msg.sender], "refinery not unlocked");
    }

}