// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./Beryllium.sol";

contract Valetta {
    ERC20 public energy;
    ERC20 public ticket;
    Beryllium public beryllium;
    address public owner;
    address public DEAD = 0x000000000000000000000000000000000000dEaD;
    uint public energyUnlockCost;
    uint public ticketUnlockCost;
    uint public maxCapacityLevel;
    uint public maxProductionLevel;
    mapping(uint => uint) capacityAtLevel;
    mapping(uint => uint) productionAtLevel;
    mapping(uint => uint) capacityUpgradeCost;
    mapping(uint => uint) productionUpgradeCost;
    mapping(address => uint) userCapacityLevel;
    mapping(address => uint) userProductionLevel;
    mapping(address => uint) lastCollected;
    mapping(address => bool) blacklist;
    

    uint maxUnlocks;
    uint unlockedQuantity = 0;

    mapping(address => bool) unlocked;


    constructor() {
        owner = msg.sender;
        energyUnlockCost = 120e18;
        ticketUnlockCost = 1e18;
        maxUnlocks = 500;
        capacityAtLevel[0] = 60e18;
        capacityAtLevel[1] = 90e18;
        capacityAtLevel[2] = 120e18;
        productionAtLevel[0] = 359e12;
        productionAtLevel[1] = 486e12;
        productionAtLevel[2] = 637e12;
        capacityUpgradeCost[0] = 1e18;
        capacityUpgradeCost[1] = 2e18;
        productionUpgradeCost[0] = 3e18;
        productionUpgradeCost[1] = 5e18;
        maxCapacityLevel = 2;
        maxProductionLevel = 2;
    }

    // EVENTS

    event Unlocked(address user);
    event CapacityUpgraded(address user, uint level);
    event BerylliumCollected(address user, uint amount);

    // MODIFIERS
    modifier onlyOwner(address _address) {
        require(_address == owner, "not authorized");
        _;
    }

    modifier unlockAvailable() {
        require(unlockedQuantity < maxUnlocks, "max unlocks reached");
        _;
    }

    modifier asteroidLocked(address _user) {
        require(!unlocked[_user], "asteroid already unlocked");
        _;
    }

    modifier asteroidUnlocked(address _user) {
        require(unlocked[_user], "asteroid locked");
        _;
    }

    modifier notBlacklisted(address _user) {
        require(!blacklist[_user], "user blacklisted");
        _;
    }

    // OWNER ONLY
    function setEnergy(ERC20 _energy) public onlyOwner(msg.sender) {
        energy = _energy;
    }

    function setTicket(ERC20 _ticket) public onlyOwner(msg.sender) {
        ticket = _ticket;
    }

    function setBeryllium(Beryllium _beryllium) public onlyOwner(msg.sender) {
        beryllium = _beryllium;
    }

    function setMaxUnlocks(uint _maxUnlocks) public onlyOwner(msg.sender) {
        maxUnlocks = _maxUnlocks;
    }

    function setEnergyUnlockCost(uint _energyUnlockCost) public onlyOwner(msg.sender) {
        energyUnlockCost = _energyUnlockCost;
    }

    function setTicketUnlockCost(uint _ticketUnlockCost) public onlyOwner(msg.sender) {
        ticketUnlockCost = _ticketUnlockCost;
    }

    function setCapacityAtLevel(uint _level, uint _capacity) public onlyOwner(msg.sender) {
        capacityAtLevel[_level] = _capacity;
    }

    function setProductionAtLevel(uint _level, uint _production) public onlyOwner(msg.sender) {
        productionAtLevel[_level] = _production;
    }

    function setCapacityUpgradeCost(uint _level, uint _cost) public onlyOwner(msg.sender) {
        capacityUpgradeCost[_level] = _cost;
    }

    function setProductionUpgradeCost(uint _level, uint _cost) public onlyOwner(msg.sender) {
        productionUpgradeCost[_level] = _cost;
    }

    function setMaxCapacityLevel(uint _level) public onlyOwner(msg.sender) {
        maxCapacityLevel = _level;
    }
    
    function setMaxProductionLevel(uint _level) public onlyOwner(msg.sender) {
        maxProductionLevel = _level;
    }

    function blacklistUser(address _user, bool add) public onlyOwner(msg.sender) {
        blacklist[_user] = add;
    }


    // USER INTERFACE

    // unlock -> with energy or with ticket
    function unlockWithEnergy() public asteroidLocked(msg.sender) {
        require(unlockedQuantity < maxUnlocks, "max unlocks reached");
        energy.transferFrom(msg.sender, DEAD, energyUnlockCost);
        unlockedQuantity++;
        unlocked[msg.sender] = true;
        lastCollected[msg.sender] = block.timestamp;
        emit Unlocked(msg.sender);
        return;
    }

    function unlockWithTicket() public asteroidLocked(msg.sender) {
        ticket.transferFrom(msg.sender, DEAD, ticketUnlockCost);
        unlocked[msg.sender] = true;
        lastCollected[msg.sender] = block.timestamp;
        emit Unlocked(msg.sender);
        return;
    }

    function upgradeCapacity() public asteroidUnlocked(msg.sender) {
        uint curLevel = userCapacityLevel[msg.sender];
        require(curLevel < maxCapacityLevel, "capacity at max level");
        uint amount = capacityUpgradeCost[curLevel];
        ticket.transferFrom(msg.sender, DEAD, amount);
        userCapacityLevel[msg.sender] = curLevel + 1;
        emit CapacityUpgraded(msg.sender, curLevel + 1);
    }

    function upgradeProduction() public asteroidUnlocked(msg.sender) {
        uint curLevel = userProductionLevel[msg.sender];
        require(curLevel < maxProductionLevel, "production at max level");
        uint amount = productionUpgradeCost[curLevel];
        ticket.transferFrom(msg.sender, DEAD, amount);
        userProductionLevel[msg.sender] = curLevel + 1;
        emit CapacityUpgraded(msg.sender, curLevel + 1);
    }

    function getAccumulatedBeryllium() public view returns(uint) {
        if (!unlocked[msg.sender]) {
            return 0;
        }
        uint productionLevel = userProductionLevel[msg.sender];
        uint capacityLevel = userCapacityLevel[msg.sender];
        uint production = productionAtLevel[productionLevel];
        uint capacity = capacityAtLevel[capacityLevel];
        uint amt = production * (block.timestamp - lastCollected[msg.sender]);
        if (amt > capacity) {
            amt = capacity;
        }
        return amt;
    }

    function collectBeryllium() public notBlacklisted(msg.sender) {
        uint amount = getAccumulatedBeryllium();
        lastCollected[msg.sender] = block.timestamp;
        beryllium.mint(msg.sender, amount);
        emit BerylliumCollected(msg.sender, amount);
        return;
    }
}