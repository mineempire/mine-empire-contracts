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
    uint public baseProduction;
    struct Stake {
        uint timestamp;
        MineEmpireDrill.Drill drill;
    }

    uint maxLevel;
    mapping(uint => uint) public capacityAtLevel;
    mapping(uint => uint) public upgradeRequirementAtLevel;
    mapping(address => uint) public userLevel;
    mapping(address => Stake) public stakes;

    constructor(ERC20PresetMinterPauser _iron, ERC20PresetMinterPauser _cosmicCash, MineEmpireDrill _drill) {
        owner = msg.sender;
        baseProduction = 289351851900000;
        iron = _iron;
        cosmicCash = _cosmicCash;
        mineEmpireDrill = _drill;
        maxLevel = 9;
        capacityAtLevel[0] = 175e18;
        capacityAtLevel[1] = 185e18;
        capacityAtLevel[2] = 200e18;
        capacityAtLevel[3] = 225e18;
        capacityAtLevel[4] = 255e18;
        capacityAtLevel[5] = 295e18;
        capacityAtLevel[6] = 350e18;
        capacityAtLevel[7] = 410e18;
        capacityAtLevel[8] = 485e18;
        capacityAtLevel[9] = 575e18;
        upgradeRequirementAtLevel[1] = 100e16;
        upgradeRequirementAtLevel[2] = 120e16;
        upgradeRequirementAtLevel[3] = 156e16;
        upgradeRequirementAtLevel[4] = 2184e15;
        upgradeRequirementAtLevel[5] = 3276e15;
        upgradeRequirementAtLevel[6] = 5242e15;
        upgradeRequirementAtLevel[7] = 8911e15;
        upgradeRequirementAtLevel[8] = 16039e15;
        upgradeRequirementAtLevel[9] = 30475e15;
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

    // get capacity at level
    function getCapacityAtLevel(uint _level) public view levelExists(_level) returns(uint) {
        return capacityAtLevel[_level];
    }

    // get user level
    function getUserLevel(address _userAddress) public view returns(uint) {
        return userLevel[_userAddress];
    }

    // get stake
    function getStake(address _address) public view returns(Stake memory) {
        return stakes[_address];
    }
    
    // get base production
    function getBaseProduction() public view returns(uint) {
        return baseProduction;
    }

    // get max level
    function getMaxLevel() public view returns(uint) {
        return maxLevel;
    }

    // get accumulated iron
    function getAccumulatedIron(address _userAddress) public view drillStaked(_userAddress) returns(uint) {
        Stake memory curStake = stakes[_userAddress];
        uint time = block.timestamp - curStake.timestamp;
        uint miningPower = mineEmpireDrill.getMiningPower(curStake.drill.drillId);
        uint capacity = capacityAtLevel[userLevel[_userAddress]];
        uint amount = time * baseProduction / 100 * miningPower;
        if (capacity < amount) {
            amount = capacity;
        }
        return amount;
    }

    // USER INTERACTIONS

    // stake
    function stake(uint _drillId) public drillNotStaked(msg.sender) {
        mineEmpireDrill.safeTransferFrom(msg.sender, address(this), _drillId);
        MineEmpireDrill.Drill memory drill = mineEmpireDrill.getDrill(_drillId);
        stakes[msg.sender] = Stake(
            block.timestamp,
            drill);
    }

    // collect
    function collectIron() public drillStaked(msg.sender) {
        uint amount = getAccumulatedIron(msg.sender);
        iron.mint(msg.sender, amount);
        stakes[msg.sender].timestamp = block.timestamp;
    }

    // unstake and collect
    function unstake() public drillStaked(msg.sender) {
        uint amount = getAccumulatedIron(msg.sender);
        iron.transfer(msg.sender, amount);
        mineEmpireDrill.safeTransferFrom(address(this), msg.sender, stakes[msg.sender].drill.drillId);
        delete stakes[msg.sender];
    }

    // upgrade
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