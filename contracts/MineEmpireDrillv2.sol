// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract MineEmpireDrill is ERC721 {
    address public owner;
    address payable public treasury;
    address public cosmicCash;
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
    }

    mapping(uint => Drill) public drillIdToDrillMap;
    mapping(uint => DrillTypeInfo) public drillTypeToDrillStatsMap;

    constructor(address _cosmicCash) ERC721("Mine Empire Drill", "DRILL") {
        owner = msg.sender;
        cosmicCash = _cosmicCash;
    }

    // EVENTS
    event LogDrillTypeAdded(uint _type);

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

    modifier correctMintPriceAndCurrency(uint _drillType, bool _mintNativeCurrency, address _mintCurrencyAddress, uint _mintPrice) {
        require(drillTypeToDrillStatsMap[_drillType].mintNativeCurrency == _mintNativeCurrency, "mintNativeCurrency does not match");
        require(drillTypeToDrillStatsMap[_drillType].mintCurrencyAddress == _mintCurrencyAddress, "incorrect mint currency address");
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
        uint[] memory _miningPowerAtLevel
    ) public onlyOwner(msg.sender) drillTypeNotExists(_type) {
        drillTypeToDrillStatsMap[_type].drillType = _type;
        drillTypeToDrillStatsMap[_type].drillName = _name;
        drillTypeToDrillStatsMap[_type].mintPrice = _mintPrice;
        drillTypeToDrillStatsMap[_type].mintNativeCurrency = _nativeCurrency;
        drillTypeToDrillStatsMap[_type].mintCurrencyAddress = _mintCurrencyAddress;
        drillTypeToDrillStatsMap[_type].maxLevel = _maxLevel;
        for (uint i = 0; i < _maxLevel; i++) {
            drillTypeToDrillStatsMap[_type].miningPowerAtLevel[i] = _miningPowerAtLevel[i];
        }
        emit LogDrillTypeAdded(_type);
    }
    // update mint price
    // update max drills
    // update mining power
    // update max level

    // GETTERS
    // get drill
    // get mint price and currency
    // get mining level upgrade requirements
    // get mining power

    // USER INTERACTIONS
    // mint drill
    // upgrade drill
}