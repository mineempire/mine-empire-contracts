// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract MineEmpireDrillv2 is ERC721 {
    address public owner;
    address payable public treasury;
    IERC20 public cosmicCash;
    uint public nextDrillId = 1;
    uint public maxDrills = 100;

    struct Drill {
        uint drillId;
        uint drillType;
        uint level;
    }

    struct DrillTypeInfo {
        uint drillType;
        string drillName;
        uint mintPrice;
        bool mintNativeCurrency;
        address mintCurrencyAddress;
        uint maxLevel;
        mapping(uint => uint) miningPowerAtLevel;
        mapping(uint => uint) upgradeRequirements;
    }

    mapping(uint => Drill) public drillIdToDrillMap;
    mapping(uint => DrillTypeInfo) public drillTypeToDrillStatsMap;

    constructor(IERC20 _cosmicCash) ERC721("Mine Empire Drill", "DRILL") {
        owner = msg.sender;
        cosmicCash = _cosmicCash;
    }

    // EVENTS
    event LogDrillTypeAdded(uint _type);
    event LogMint(uint _drillId);
    event LogDrillUpgrade(uint _drillId);

    // MODIFIERS
    modifier onlyOwner(address _address) {
        require(_address == owner, "not owner");
        _;
    }

    modifier mintAvailable() {
        require (nextDrillId <= maxDrills, "mint not available");
        _;
    }

    modifier drillExists(uint _drillId) {
        require(_drillId < nextDrillId, "drill does not exist");
        _;
    }

    modifier drillTypeExists(uint _drillType) {
        require(drillTypeToDrillStatsMap[_drillType].maxLevel > 0, "drill type does not exist");
        _;
    }

    modifier drillTypeNotExists(uint _drillType) {
        require(drillTypeToDrillStatsMap[_drillType].maxLevel == 0, "drill type already exists");
        _;
    }

    modifier drillTypeLevelWithinBounds(uint _type, uint _level) {
        require(_level < drillTypeToDrillStatsMap[_type].maxLevel, "level is greater than max level for given drill type");
        require(_level >= 0, "level is negative");
        _;
    }

    modifier correctMintPrice(uint _drillType, uint _mintPrice) {
        require(drillTypeToDrillStatsMap[_drillType].mintPrice == _mintPrice, "incorrect mint price");
        _;
    }

    // ONLY OWNER
    
    // update treasury address
    function updateTreasuryAddress(address payable _address) public onlyOwner(msg.sender) {
        treasury = _address;
    }

    // add new drill type
    function addNewDrillType(
        uint _type,
        string memory _name,
        uint _mintPrice,
        bool _nativeCurrency,
        address _mintCurrencyAddress,
        uint _maxLevel,
        uint[] memory _miningPowerAtLevel,
        uint[] memory _upgradeRequirements
    ) public onlyOwner(msg.sender) drillTypeNotExists(_type) {
        drillTypeToDrillStatsMap[_type].drillType = _type;
        drillTypeToDrillStatsMap[_type].drillName = _name;
        drillTypeToDrillStatsMap[_type].mintPrice = _mintPrice;
        drillTypeToDrillStatsMap[_type].mintNativeCurrency = _nativeCurrency;
        drillTypeToDrillStatsMap[_type].mintCurrencyAddress = _mintCurrencyAddress;
        drillTypeToDrillStatsMap[_type].maxLevel = _maxLevel;
        for (uint i = 0; i < _maxLevel; i++) {
            drillTypeToDrillStatsMap[_type].miningPowerAtLevel[i] = _miningPowerAtLevel[i];
            drillTypeToDrillStatsMap[_type].upgradeRequirements[i] = _upgradeRequirements[i];

        }
        emit LogDrillTypeAdded(_type);
    }

    // update mint price
    function updateMintPrice(
        uint _type, 
        uint _mintPrice
    ) public onlyOwner(msg.sender) drillTypeExists(_type) {
        drillTypeToDrillStatsMap[_type].mintPrice = _mintPrice;
    }

    // update max drills
    function updateMaxDrillCount(uint _maxDrills) public onlyOwner(msg.sender) {
        maxDrills = _maxDrills;
    }

    // update mining power
    function updateMiningPower(
        uint _type, 
        uint _level, 
        uint _power
    ) public onlyOwner(msg.sender) drillTypeExists(_type) drillTypeLevelWithinBounds(_type, _level) {
        drillTypeToDrillStatsMap[_type].miningPowerAtLevel[_level] = _power;
    }

    // update max level
    function updateMaxLevel(
        uint _type,
        uint _maxLevel
    ) public onlyOwner(msg.sender) drillTypeExists(_type) {
        drillTypeToDrillStatsMap[_type].maxLevel = _maxLevel;
    }

    //update upgrade requirement
    function updateUpgradeRequirement(
        uint _type,
        uint _level,
        uint _upgradeRequirement
    ) public onlyOwner(msg.sender) drillTypeExists(_type) drillTypeLevelWithinBounds(_type, _level) {
        drillTypeToDrillStatsMap[_type].upgradeRequirements[_level] = _upgradeRequirement;
    }

    // GETTERS

    // get drill
    function getDrill(uint _drillId) public view drillExists(_drillId) returns(Drill memory) {
        return drillIdToDrillMap[_drillId];
    }
    
    // get mint price and currency
    function getMintPrice(uint _type) public view drillTypeExists(_type) returns(uint) {
        return drillTypeToDrillStatsMap[_type].mintPrice;
    }

    function getMintCurrency(uint _type) public view drillTypeExists(_type) returns(address) {
        return drillTypeToDrillStatsMap[_type].mintCurrencyAddress;
    }

    // get mining level upgrade requirement
    function getUpgradeRequirement(
        uint _type,
        uint _level
    ) public view drillTypeExists(_type) drillTypeLevelWithinBounds(_type, _level) returns(uint) {
        return drillTypeToDrillStatsMap[_type].upgradeRequirements[_level];
    }
    // get mining power
    function getMiningPower(uint _drillId) public view drillExists(_drillId) returns(uint) {
        Drill memory drill = drillIdToDrillMap[_drillId];
        return drillTypeToDrillStatsMap[drill.drillType].miningPowerAtLevel[drill.level];
    }

    // USER INTERACTIONS

    // mint drill
    function mintDrill(uint _type) public payable mintAvailable() correctMintPrice(_type, msg.value) {
        require(treasury != address(0), "treasury address is not set");
        Drill memory drill = Drill(
            nextDrillId,
            _type,
            0
        );
        drillIdToDrillMap[nextDrillId] = drill;
        treasury.transfer(msg.value);
        _safeMint(msg.sender, nextDrillId);
        emit LogMint(nextDrillId);
        nextDrillId++;
    }

    // upgrade drill
    function upgradeDrill(uint _drillId) public drillExists(_drillId) {
        require(super.ownerOf(_drillId) == msg.sender, "drill not owned");
        Drill memory drill = drillIdToDrillMap[_drillId];
        DrillTypeInfo storage drillInfo = drillTypeToDrillStatsMap[drill.drillType];
        require(drill.level < drillInfo.maxLevel, "drill at max level");

        // get resource
        uint amountForUpgrade = drillInfo.upgradeRequirements[drill.level + 1];
        require(amountForUpgrade > 0, "amount for upgrade not greater than zero");
        cosmicCash.transferFrom(msg.sender, treasury, amountForUpgrade);
        drillIdToDrillMap[_drillId].level = drill.level + 1;
        emit LogDrillUpgrade(_drillId);
    }
}