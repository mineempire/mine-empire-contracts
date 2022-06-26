// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./MineEmpireDrill.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/presets/ERC20PresetMinterPauser.sol";

contract Gades {
    MineEmpireDrill public mineEmpireDrill;
    ERC20PresetMinterPauser public iron;
    ERC20PresetMinterPauser public cosmicCash;
    address public owner;
    address payable treasury;
    struct Stake {
        uint timestamp;
        MineEmpireDrill.Drill drill;
    }

    uint maxLevel;
    mapping(uint => uint) public capacityAtLevel;
    mapping(uint => uint) public upgradeRequirementAtLevel;
    mapping(address => uint) public userLevel;
    mapping(address => Stake) public stakes;
    mapping(uint => uint) public productionRate;
    uint public SECONDS_IN_PERIOD = 2592000;
    uint public GENESIS_TIME;

    constructor(ERC20PresetMinterPauser _iron, ERC20PresetMinterPauser _cosmicCash, MineEmpireDrill _drill) {
        owner = msg.sender;
        GENESIS_TIME = block.timestamp;
        iron = _iron;
        cosmicCash = _cosmicCash;
        mineEmpireDrill = _drill;
        maxLevel = 9;
        capacityAtLevel[0] = 10215e18;
        capacityAtLevel[1] = 11747e18;
        capacityAtLevel[2] = 13509e18;
        capacityAtLevel[3] = 15536e18;
        capacityAtLevel[4] = 19420e18;
        capacityAtLevel[5] = 24275e18;
        capacityAtLevel[6] = 33984e18;
        capacityAtLevel[7] = 50977e18;
        capacityAtLevel[8] = 76465e18;
        capacityAtLevel[9] = 125985e18;
        upgradeRequirementAtLevel[1] = 25e18;
        upgradeRequirementAtLevel[2] = 25e18;
        upgradeRequirementAtLevel[3] = 25e18;
        upgradeRequirementAtLevel[4] = 40e18;
        upgradeRequirementAtLevel[5] = 40e18;
        upgradeRequirementAtLevel[6] = 75e18;
        upgradeRequirementAtLevel[7] = 75e18;
        upgradeRequirementAtLevel[8] = 120e18;
        upgradeRequirementAtLevel[9] = 150e18;
        productionRate[0] = 3941e13;
        productionRate[1] = 3350e13;
        productionRate[2] = 2881e13;
        productionRate[3] = 2506e13;
        productionRate[4] = 2206e13;
        productionRate[5] = 1963e13;
        productionRate[6] = 1767e13;
        productionRate[7] = 1608e13;
        productionRate[8] = 1479e13;
        productionRate[9] = 1376e13;
        productionRate[10] = 1293e13;
        productionRate[11] = 1228e13;
    }

    function onERC721Received(
        address operator,
        address from,
        uint256 id,
        bytes calldata data
    ) external pure returns (bytes4) {
        return bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"));
    }

    // EVENTS
    event CapacityUpgraded(address userAddress, uint userLevel);

    // MODIFIERS
    modifier onlyOwner(address _address) {
        require(_address == owner, "not authorized");
        _;
    }

    modifier drillStaked(address _address) {
        require(stakes[_address].timestamp > 0, "drill not staked for this user");
        _;
    }

    modifier drillNotStaked(address _address) {
        require(stakes[_address].timestamp == 0, "drill already staked");
        _;
    }

    modifier levelExists(uint _level) {
        require(_level <= maxLevel, "level greater than max level");
        _;
    }

    // ONLY OWNER
    
    // update treasury
    function updateTreasury(address payable _address) public onlyOwner(msg.sender) {
        treasury = _address;
    }

    // update max level
    function updateMaxLevel(uint _level) public onlyOwner(msg.sender) {
        maxLevel = _level;
    }

    // update capacity at level
    function updateCapacityAtLevel(uint _level, uint _capacity) public onlyOwner(msg.sender) levelExists(_level) {
        capacityAtLevel[_level] = _capacity;
    }

    // update upgrade requirement
    function updateUpgradeRequirementAtLevel(uint _level, uint _capacity) public onlyOwner(msg.sender) levelExists(_level){
        require(_level <= maxLevel, "level not less than max level");
        upgradeRequirementAtLevel[_level] = _capacity;
    }

    // GETTERS

    function getCapacityAtLevel(uint _level) public view levelExists(_level) returns(uint) {
        return capacityAtLevel[_level];
    }

    function getUserLevel(address _userAddress) public view returns(uint) {
        return userLevel[_userAddress];
    }

    function getStake(address _address) public view returns(Stake memory) {
        return stakes[_address];
    }

    // TODO : test this
    function getCurrentPeriod() public view returns(uint) {
        return (block.timestamp - GENESIS_TIME) / SECONDS_IN_PERIOD;
    }
    
    function getBaseProduction() public view returns(uint) {
        uint period = getCurrentPeriod();
        if (period > 11) {
            period = 11;
        }
        return productionRate[period];
    }

    function getMaxLevel() public view returns(uint) {
        return maxLevel;
    }

    function getAccumulatedIron(address _userAddress) public view drillStaked(_userAddress) returns(uint) {
        Stake memory curStake = stakes[_userAddress];
        uint time = block.timestamp - curStake.timestamp;
        uint miningPower = mineEmpireDrill.getMiningPower(curStake.drill.drillId);
        uint capacity = capacityAtLevel[userLevel[_userAddress]];
        uint baseProduction = getBaseProduction();
        uint amount = time * baseProduction / 100 * miningPower;
        if (capacity < amount) {
            amount = capacity;
        }
        return amount;
    }

    // USER INTERACTIONS

    function stake(uint _drillId) public drillNotStaked(msg.sender) {
        mineEmpireDrill.safeTransferFrom(msg.sender, address(this), _drillId);
        MineEmpireDrill.Drill memory drill = mineEmpireDrill.getDrill(_drillId);
        stakes[msg.sender] = Stake(
            block.timestamp,
            drill);
    }

    function collectIron() public drillStaked(msg.sender) {
        uint amount = getAccumulatedIron(msg.sender);
        iron.mint(msg.sender, amount);
        stakes[msg.sender].timestamp = block.timestamp;
    }

    function unstake() public drillStaked(msg.sender) {
        uint amount = getAccumulatedIron(msg.sender);
        iron.mint(msg.sender, amount);
        mineEmpireDrill.safeTransferFrom(address(this), msg.sender, stakes[msg.sender].drill.drillId);
        delete stakes[msg.sender];
    }

    function upgrade() public {
        uint curLevel = userLevel[msg.sender];
        require(curLevel < 9, "level at max");
        uint upgradeAmt = upgradeRequirementAtLevel[curLevel + 1];
        cosmicCash.transferFrom(msg.sender, treasury, upgradeAmt);
        userLevel[msg.sender] = curLevel + 1;
        emit CapacityUpgraded(msg.sender, userLevel[msg.sender]);
        return;
    }
    

}