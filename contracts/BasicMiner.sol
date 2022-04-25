// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "./Coal.sol";

contract BasicMiner is ERC721 {

    address public owner;
    uint256 minerId = 1;
    uint256 maxMiners = 500;
    uint256 mintPrice = 20e18;

    // stats
    uint256 baseMiningLevel = 1;
    uint256 baseCapacityLevel = 1;
    uint256 baseMiningPower = 100;
    uint256 baseCoalCapacity = 6e18;
    uint256 baseIronCapacity = 16e17;
    uint256 baseSilverCapacity = 2e17;

    // resources
    Coal public coal;

    address public rewardsTreasury;

    // requirements of Coal, Iron, Silver, Gemstone for levels 2 - 10
    uint256[4][9] miningLevelUpgradeReqs;

    struct Miner {
        uint256 minerId;
        uint256 miningLevel;
        uint256 capacityLevel;
        uint256 miningPower;
        uint256 coalCapacity;
        uint256 ironCapacity;
        uint256 silverCapacity;
    }

    Miner[] public allMiners;

    mapping(uint256 => Miner) public minerMap;

    // deploy requirements -------------------------------
    constructor() ERC721("Miner", "MINER") {
        owner = msg.sender;

        miningLevelUpgradeReqs[0] = [100, 0, 0, 0];
        miningLevelUpgradeReqs[1] = [100, 0, 0, 0];
        miningLevelUpgradeReqs[2] = [100, 0, 0, 0];
        miningLevelUpgradeReqs[3] = [100, 0, 0, 0];
        miningLevelUpgradeReqs[4] = [100, 0, 0, 0];
        miningLevelUpgradeReqs[5] = [100, 0, 0, 0];
        miningLevelUpgradeReqs[6] = [100, 0, 0, 0];
        miningLevelUpgradeReqs[7] = [100, 0, 0, 0];
        miningLevelUpgradeReqs[8] = [100, 0, 0, 0];
    }

    // set resources upon deploy
    function setCoal(address _addr) public isOwner(msg.sender) {
        coal = Coal(_addr);
    }

    function getCoal() public view returns (address) {
        return address(coal);
    }

    function setRewardsTreasury(address _addr) public isOwner(msg.sender) {
        rewardsTreasury = _addr;
    }
    // ----------------------------------------------------

    /// Events
    event LogMint(uint256 id);
    event LogUpdateMintPrice(uint256 amount);
    event LogSetUpgrader(address _address);
    event LogUpgradeMiningLevel(uint256 minerId, uint256 newLevel);
    event LogUpgradeCapacityLevel(uint256 minerId, uint256 newLevel);

    /// Modifiers
    modifier correctMintPrice(uint256 _amount) {
        require(_amount == mintPrice);
        _;
    }
    
    modifier isOwner(address _address) {
        require (owner == _address);
        _;
    }

    modifier mintAvailable() {
        require (minerId < maxMiners);
        _;
    }

    modifier minerExists(uint256 _minerId) {
        require (minerMap[_minerId].minerId > 0);
        _;
    }

    function getMiner(uint256 _minerId) public view returns (Miner memory) {
        return minerMap[_minerId];
    }

    function getAllMiners() public view returns (Miner[] memory) {
        return allMiners;
    }

    function getMinerOwner(uint256 _minerId) public view returns (address) {
        return super.ownerOf(_minerId);
    }

    function mintMiner() public payable correctMintPrice(msg.value) mintAvailable() {
        Miner memory miner = Miner(
            minerId, 
            baseMiningLevel, 
            baseCapacityLevel, 
            baseMiningPower, 
            baseCoalCapacity, 
            baseIronCapacity, 
            baseSilverCapacity);
        allMiners.push(miner);
        minerMap[minerId] = miner;
        _safeMint(msg.sender, minerId);
        emit LogMint(minerId);
        minerId++;
    }

    function setMintPrice(uint256 newPrice) public isOwner(msg.sender) {
        mintPrice = newPrice;
        emit LogUpdateMintPrice(newPrice);
    }

    function getMintPrice() public view returns (uint256) {
        return mintPrice;
    }

    // upgrading
    function getMiningLevelUpgradeRequirements(
        uint256 _minerId
        ) public view minerExists(_minerId) returns (uint256[4] memory) {
        uint256 curLevel = minerMap[_minerId].miningLevel;
        uint256[4] memory req;
        if (curLevel == 10) {
            return req;
        }
        return miningLevelUpgradeReqs[curLevel - 1];
    }


    function upgradeMiningLevel(uint256 _minerId) public minerExists(_minerId) {
        require(super.ownerOf(_minerId) == msg.sender, "miner not owned");

        Miner memory miner = minerMap[_minerId];
        uint256 curLevel = miner.miningLevel;
        require(curLevel <= 10, "mining level at max");

        // ensure you have required resources
        uint256 coalReq = miningLevelUpgradeReqs[curLevel - 1][0];
        if (coalReq > 0) {
            coal.transferFrom(msg.sender, rewardsTreasury, coalReq);
        }

        setMiningLevel(_minerId, curLevel + 1);
        setMiningPower(_minerId, miner.miningPower + 1); // update
    }

    function upgradeMiningCapacity(uint256 _minerId) public minerExists(_minerId) {
        require(super.ownerOf(_minerId) == msg.sender, "miner not owned");

        Miner memory miner = minerMap[_minerId];
        uint256 curLevel = miner.capacityLevel;
        require(curLevel <= 10, "mining level at max");
        setCapacityLevel(_minerId, curLevel + 1);
        setCoalCapacity(_minerId, miner.coalCapacity + 1);
        setIronCapacity(_minerId, miner.ironCapacity + 1);
        setSilverCapacity(_minerId, miner.silverCapacity + 1);
    }


    function setMiningLevel(uint256 _minerId, uint256 level) private {
        minerMap[_minerId].miningLevel = level;
        emit LogUpgradeMiningLevel(_minerId, level);
    }

    function setCapacityLevel(uint256 _minerId, uint256 level) private {
        minerMap[_minerId].capacityLevel = level;
        emit LogUpgradeCapacityLevel(_minerId, level);
    }

    function setMiningPower(uint256 _minerId, uint256 power) private {
        minerMap[_minerId].miningPower = power;
    }

    function setCoalCapacity(uint256 _minerId, uint256 capacity) private {
        minerMap[_minerId].coalCapacity = capacity;
    }

    function setIronCapacity(uint256 _minerId, uint256 capacity) private {
        minerMap[_minerId].ironCapacity = capacity;
    }

    function setSilverCapacity(uint256 _minerId, uint256 capacity) public {
        minerMap[_minerId].silverCapacity = capacity;
    }
}