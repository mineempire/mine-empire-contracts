// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract MineEmpireDrillOld is ERC721 {
    address public owner;
    address payable public treasury;
    uint public currentMintDrill = 0;
    uint public drillId = 1;
    uint public maxDrills = 100;

    uint private nextNewDrillType = 0;
    IERC20[] private resources;
    uint private numberOfTrackedResources;
    uint[][] private miningMultiplier;
    uint[][] private capacity;
    uint[][][] private miningLevelUpgradeRequirement;
    uint[][][] private capacityLevelUpgradeRequirement;
    string[] private drillName;
    uint[] private mintPrice;
    uint[] private maxLevel;


    struct Drill {
        uint drillId;
        string name;
        uint drillType;
        uint miningLevel;
        uint capacityLevel;
    }

    mapping(uint => Drill) public drillMap;

    struct Promotion {
        uint promoId;
        uint drillType;
        uint maxUnits;
        uint unitsSold;
        uint miningLevel;
        uint capacityLevel;
        uint mintPrice;
    }

    mapping(uint => Promotion) public promotions;

    constructor() ERC721("Mine Empire Drill", "DRILL") {
        owner = msg.sender;
    }

    // events

    event LogNewDrillTypeAdded(uint _drillId);
    event LogNewResourceTracked(address _address);
    event LogMiningLevelUpgraded(uint _drillId);
    event LogCapacityLevelUpgraded(uint _drillId);
    event LogMint(uint _drillId);
    event LogPromotionAdded(Promotion _promo);
    event LogPromoMint(uint _drillId);


    // modifiers

    modifier onlyOwner(address _address) {
        require(_address == owner, "not owner");
        _;
    }

    modifier mintAvailable() {
        require (drillId <= maxDrills, "mint not available");
        _;
    }

    modifier drillExists(uint _drillId) {
        require(_drillId < drillId, "drill does not exist");
        _;
    }

    modifier correctMintPrice(uint256 _amount) {
        require(_amount == mintPrice[currentMintDrill], "mint price is not correct");
        _;
    }

    function getResourceAtIndex(uint idx) public view returns (IERC20) {
        return resources[idx];
    }

    // owner only
    function updateTreasuryAddress(address payable _address) public onlyOwner(msg.sender) {
        treasury = _address;
    }

    function addNewDrillType(
        uint _drillType,
        string memory name,
        uint _mintPrice,
        uint _maxLevel,
        uint[] memory miningPower,
        uint[] memory capacityAmount,
        uint[][] memory _miningLevelUpgradeRequirement,
        uint[][] memory _capacityLevelUpgradeRequirement
    ) public onlyOwner(msg.sender) {
        require(_drillType <= nextNewDrillType, "drillType must be <= nextNewDrillType");
        if (_drillType != nextNewDrillType) {
            require(mintPrice[_drillType] == 0, "drillType already created, delete before replacing");
        }
        drillName.push(name);
        mintPrice.push(_mintPrice);
        maxLevel.push(_maxLevel);
        miningMultiplier.push(miningPower);
        capacity.push(capacityAmount);
        miningLevelUpgradeRequirement.push(_miningLevelUpgradeRequirement);
        capacityLevelUpgradeRequirement.push(_capacityLevelUpgradeRequirement);
        emit LogNewDrillTypeAdded(nextNewDrillType);
        nextNewDrillType++;
    }

    function addNewTrackedResource(
        IERC20 resource
    ) public onlyOwner(msg.sender) {
        resources.push(resource);
        emit LogNewResourceTracked(address(resource));
        numberOfTrackedResources++;
    }

    function updateMintPrice(uint drillType, uint _price) public onlyOwner(msg.sender) {
        require(drillType < nextNewDrillType, "drill type doesn't exist");
        mintPrice[drillType] = _price;
    }

    function updateMaxDrillCount(uint _maxDrills) public onlyOwner(msg.sender) {
        maxDrills = _maxDrills;
    }

    function createPromotion(
        uint promoId, 
        uint _drillType, 
        uint _miningLeve, 
        uint _capacityLevel, 
        uint _maxUnits, 
        uint _price
        ) public onlyOwner(msg.sender) {
        Promotion memory promo = Promotion(
            promoId,
            _drillType,
            _maxUnits,
            0,
            _miningLeve,
            _capacityLevel,
            _price
        );
        promotions[promoId] = promo;
        emit LogPromotionAdded(promo);
    }

    // getters
    function getDrill(uint256 _drillId) public view returns (Drill memory) {
        return drillMap[_drillId];
    }

    function getMintPrice(uint drillType) public view returns(uint) {
        require(drillType < nextNewDrillType, "drill type doesn't exist");
        return mintPrice[drillType];
    }

    function getMiningLevelUpgradeRequirements(uint _drillId) public view drillExists(_drillId) returns(uint[] memory) {
        uint drillType = drillMap[_drillId].drillType;
        uint curLevel = drillMap[_drillId].miningLevel;
        return miningLevelUpgradeRequirement[drillType][curLevel];
    }

    function getCapacityLevelUpgradeRequirements(uint _drillId) public view drillExists(_drillId) returns(uint[] memory) {
        uint drillType = drillMap[_drillId].drillType;
        uint curLevel = drillMap[_drillId].capacityLevel;
        return capacityLevelUpgradeRequirement[drillType][curLevel];
    }

    function getDrillMiningPower(uint _drillId) public view drillExists(_drillId) returns (uint) {
        uint drillType = drillMap[_drillId].drillType;
        uint curLevel = drillMap[_drillId].miningLevel;
        return miningMultiplier[drillType][curLevel-1];
    }

    function getDrillCapacity(uint _drillId) public view drillExists(_drillId) returns (uint) {
        uint drillType = drillMap[_drillId].drillType;
        uint curLevel = drillMap[_drillId].capacityLevel;
        return capacity[drillType][curLevel-1];
    }

    // user interactions
    function mintDrill() public payable mintAvailable() {
        require(currentMintDrill < nextNewDrillType, "drill you are trying to mint is not created");
        require(msg.value == mintPrice[currentMintDrill], "pay amount doesn't match mint price");
        require(treasury != address(0), "treasury address is not set");
        Drill memory drill = Drill(
            drillId,
            drillName[currentMintDrill],
            currentMintDrill,
            1,
            1
        );
        drillMap[drillId] = drill;
        treasury.transfer(msg.value);
        _safeMint(msg.sender, drillId);
        emit LogMint(drillId);
        drillId++;
    }

    function mintPromoDrill(uint _promoId) public payable {
        Promotion memory promo = promotions[_promoId];
        require(promo.maxUnits > 0, "promotion does not exist");
        require(promo.unitsSold < promo.maxUnits, "no units available for this promotion");
        require(msg.value == promo.mintPrice, "payment doesn't match promo mint price");
        require(promo.drillType < nextNewDrillType, "drill type hasn't been configured");

        Drill memory drill = Drill(
            drillId,
            drillName[promo.drillType],
            promo.drillType,
            promo.miningLevel,
            promo.capacityLevel
        );
        drillMap[drillId] = drill;
        treasury.transfer(msg.value);
        _safeMint(msg.sender, drillId);
        emit LogPromoMint(drillId);
        drillId++;
    }

    function upgradeMiningLevel(uint _drillId) public drillExists(_drillId) {
        require(super.ownerOf(_drillId) == msg.sender, "drill not owned");
        uint drillType = drillMap[_drillId].drillType;
        uint curLevel = drillMap[_drillId].miningLevel;
        require(curLevel < maxLevel[drillType], "mining level at max");

        // get relevant resources
        for (uint i = 0; i < numberOfTrackedResources; i++) {
            uint resourceAmount = miningLevelUpgradeRequirement[drillType][curLevel-1][i];
            if (resourceAmount > 0) {
                resources[i].transferFrom(msg.sender, address(this), resourceAmount);
            }
        }
        drillMap[_drillId].miningLevel = curLevel + 1;
        emit LogMiningLevelUpgraded(_drillId);
    }

    function upgradeCapacityLevel(uint _drillId) public drillExists(_drillId) {
        require(super.ownerOf(_drillId) == msg.sender, "drill not owned");
        uint drillType = drillMap[_drillId].drillType;
        uint curLevel = drillMap[_drillId].capacityLevel;
        require(curLevel < maxLevel[drillType], "mining level at max");

        // get relevant resources
        for (uint i = 0; i < numberOfTrackedResources; i++) {
            uint resourceAmount = capacityLevelUpgradeRequirement[drillType][curLevel-1][i];
            if (resourceAmount > 0) {
                resources[i].transferFrom(msg.sender, address(this), resourceAmount);
            }
        }
        drillMap[_drillId].capacityLevel = curLevel + 1;
        emit LogCapacityLevelUpgraded(_drillId);
    }
}