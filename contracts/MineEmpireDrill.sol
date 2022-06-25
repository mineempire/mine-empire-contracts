// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract MineEmpireDrill is ERC721 {
    address public owner;
    address payable public treasury;
    IERC20 public cosmicCash;
    uint public nextDrillId = 1;
    uint public totalFreeMints = 0;
    uint public maxFreeMints = 0;

    struct Drill {
        uint drillId;
        uint drillType;
        uint level;
    }

    struct DrillTypeInfo {
        uint drillType;
        string drillName;
        uint maxLevel;
        mapping(uint => uint) miningPowerAtLevel;
        mapping(uint => uint) upgradeRequirements;
    }

    struct AlternativeMint {
        uint alternativeMintId;
        uint drillType;
        uint level;
        IERC20 currency;
        uint price;
        uint minted;
        uint maxMintsAllowed;
    }

    mapping(uint => Drill) public drillIdToDrillMap;
    mapping(uint => DrillTypeInfo) public drillTypeToDrillStatsMap;
    // type -> level -> available
    mapping(uint => mapping(uint => uint)) public drillsAvailableAtLevel;
    mapping(uint => mapping(uint => uint)) public drillsMintedAtLevel;
    mapping(uint => mapping(uint => uint)) public drillPriceAtLevel;
    mapping(address => mapping(uint => mapping(uint => uint))) public freeMints;
    mapping(uint => AlternativeMint) public alternativeMints;
    mapping(uint => string) public URIs;

    constructor(IERC20 _cosmicCash) ERC721("Mine Empire Drill", "DRILL") {
        owner = msg.sender;
        cosmicCash = _cosmicCash;
        drillsAvailableAtLevel[1][0] = 100;
    }

    // EVENTS
    event LogDrillTypeAdded(uint _type);
    event LogMint(uint _drillId);
    event LogFreeMint(uint _drillId);
    event LogAlternativeMint(uint _drillId);
    event LogDrillUpgrade(uint _drillId);

    // MODIFIERS
    modifier onlyOwner(address _address) {
        require(_address == owner, "not owner");
        _;
    }

    modifier mintAvailable(uint _type, uint _level) {
        require (drillsMintedAtLevel[_type][_level] < drillsAvailableAtLevel[_type][_level], "mint not available");
        _;
    }

    modifier freeMintAvailable(uint _type, uint _level, address _user) {
        require (freeMints[_user][_type][_level] > 0, "free mint not available");
        require (totalFreeMints < maxFreeMints, "free mint exceeds max available");
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

    modifier correctMintPrice(uint _type, uint _level, uint _mintPrice) {
        require(drillPriceAtLevel[_type][_level] == _mintPrice, "incorrect mint price");
        _;
    }

    modifier altMintExists(uint _id) {
        require(alternativeMints[_id].alternativeMintId == _id, "alternative mint id doesn't exist");
        _;
    }

    modifier altMintAvailable(uint _id) {
        require(alternativeMints[_id].minted < alternativeMints[_id].maxMintsAllowed, "no mints left");
        _;
    }

    // ONLY OWNER
    
    function updateTreasuryAddress(address payable _address) public onlyOwner(msg.sender) {
        treasury = _address;
    }

    function addNewDrillType(
        uint _type,
        string memory _name,
        uint _mintPrice,
        uint _maxLevel,
        uint[] memory _miningPowerAtLevel,
        uint[] memory _upgradeRequirements
    ) public onlyOwner(msg.sender) drillTypeNotExists(_type) {
        drillTypeToDrillStatsMap[_type].drillType = _type;
        drillTypeToDrillStatsMap[_type].drillName = _name;
        drillPriceAtLevel[_type][0] = _mintPrice;
        drillTypeToDrillStatsMap[_type].maxLevel = _maxLevel;
        for (uint i = 0; i < _maxLevel; i++) {
            drillTypeToDrillStatsMap[_type].miningPowerAtLevel[i] = _miningPowerAtLevel[i];
            drillTypeToDrillStatsMap[_type].upgradeRequirements[i] = _upgradeRequirements[i];

        }
        emit LogDrillTypeAdded(_type);
    }

    function updateMintPrice(
        uint _type,
        uint _level,
        uint _mintPrice
    ) public onlyOwner(msg.sender) drillTypeExists(_type) {
        drillPriceAtLevel[_type][_level] = _mintPrice;
    }

    function updateDrillsAvailable(uint _type, uint _level, uint _count) public onlyOwner(msg.sender) {
        drillsAvailableAtLevel[_type][_level] = _count;
    }

    function updateMaxFreeMints(uint _amount) public onlyOwner(msg.sender) {
        maxFreeMints = _amount;
    }

    function updateFreeMint(address _user, uint _type, uint _level, uint _amount) public onlyOwner(msg.sender) {
        freeMints[_user][_type][_level] = _amount;
    }

    function updateMiningPower(
        uint _type, 
        uint _level, 
        uint _power
    ) public onlyOwner(msg.sender) drillTypeExists(_type) drillTypeLevelWithinBounds(_type, _level) {
        drillTypeToDrillStatsMap[_type].miningPowerAtLevel[_level] = _power;
    }

    function updateMaxLevel(
        uint _type,
        uint _maxLevel
    ) public onlyOwner(msg.sender) drillTypeExists(_type) {
        drillTypeToDrillStatsMap[_type].maxLevel = _maxLevel;
    }

    function updateUpgradeRequirement(
        uint _type,
        uint _level,
        uint _upgradeRequirement
    ) public onlyOwner(msg.sender) drillTypeExists(_type) drillTypeLevelWithinBounds(_type, _level) {
        drillTypeToDrillStatsMap[_type].upgradeRequirements[_level] = _upgradeRequirement;
    }

    function addAlternativeMint(
        uint _id,
        uint _type,
        uint _level,
        IERC20 _currency,
        uint _price,
        uint _maxMintsAllowed
    ) public onlyOwner(msg.sender) drillTypeExists(_type) drillTypeLevelWithinBounds(_type, _level) {
        alternativeMints[_id] = AlternativeMint(_id, _type, _level, _currency, _price, 0, _maxMintsAllowed);
    }

    function setURIForLevel(uint _level, string memory _uri) public onlyOwner(msg.sender) {
        URIs[_level] = _uri;
    }

    // GETTERS

    function getDrill(uint _drillId) public view drillExists(_drillId) returns(Drill memory) {
        return drillIdToDrillMap[_drillId];
    }

    function getTotalFreeMints() public view returns(uint) {
        return totalFreeMints;
    }

    function getMaxFreeMints() public view returns(uint) {
        return maxFreeMints;
    }
    
    function getMintPrice(uint _type, uint _level) public view drillTypeExists(_type) returns(uint) {
        return drillPriceAtLevel[_type][_level];
    }

    function getUpgradeRequirement(
        uint _type,
        uint _level
    ) public view drillTypeExists(_type) drillTypeLevelWithinBounds(_type, _level) returns(uint) {
        return drillTypeToDrillStatsMap[_type].upgradeRequirements[_level];
    }
    
    function getMiningPower(uint _drillId) public view drillExists(_drillId) returns(uint) {
        Drill memory drill = drillIdToDrillMap[_drillId];
        return drillTypeToDrillStatsMap[drill.drillType].miningPowerAtLevel[drill.level];
    }

    function getDrillsAvailableAtLevel(uint _type, uint _level) public view returns(uint) {
        return drillsAvailableAtLevel[_type][_level];
    }

    function tokenURI(uint256 tokenId) public view override returns(string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        uint level = drillIdToDrillMap[tokenId].level;
        return URIs[level];
    }

    // USER INTERACTIONS

    function mintDrill(uint _type, uint _level) public payable 
    mintAvailable(_type, _level) 
    correctMintPrice(_type, _level, msg.value) {
        require(treasury != address(0), "treasury address is not set");
        treasury.transfer(msg.value);
        Drill memory drill = Drill(
            nextDrillId,
            _type,
            _level
        );
        drillIdToDrillMap[nextDrillId] = drill;
        drillsMintedAtLevel[_type][_level]++;
        _safeMint(msg.sender, nextDrillId);
        emit LogMint(nextDrillId);
        nextDrillId++;
    }

    function freeMintDrill(uint _type, uint _level) public freeMintAvailable(_type, _level, msg.sender) {
        freeMints[msg.sender][_type][_level]--;
        totalFreeMints++;
        Drill memory drill = Drill(
            nextDrillId,
            _type,
            _level
        );
        drillIdToDrillMap[nextDrillId] = drill;
        drillsMintedAtLevel[_type][_level]++;
        _safeMint(msg.sender, nextDrillId);
        emit LogFreeMint(nextDrillId);
        nextDrillId++;
    }

    function alternativeMintDrill(uint _id) public altMintExists(_id) altMintAvailable(_id) {
        alternativeMints[_id].minted++;
        alternativeMints[_id].currency.transferFrom(msg.sender, treasury, alternativeMints[_id].price);
        Drill memory drill = Drill(
            nextDrillId,
            alternativeMints[_id].drillType,
            alternativeMints[_id].level
        );
        drillIdToDrillMap[nextDrillId] = drill;
        _safeMint(msg.sender, nextDrillId);
        emit LogAlternativeMint(nextDrillId);
        nextDrillId++;
    }

    function upgradeDrill(uint _drillId) public drillExists(_drillId) {
        require(super.ownerOf(_drillId) == msg.sender, "drill not owned");
        Drill memory drill = drillIdToDrillMap[_drillId];
        DrillTypeInfo storage drillInfo = drillTypeToDrillStatsMap[drill.drillType];
        require(drill.level < drillInfo.maxLevel, "drill at max level");

        uint amountForUpgrade = drillInfo.upgradeRequirements[drill.level + 1];
        require(amountForUpgrade > 0, "amount for upgrade not greater than zero");
        cosmicCash.transferFrom(msg.sender, treasury, amountForUpgrade);
        drillIdToDrillMap[_drillId].level = drill.level + 1;
        emit LogDrillUpgrade(_drillId);
    }
}