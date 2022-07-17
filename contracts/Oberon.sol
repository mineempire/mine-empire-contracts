// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./MineEmpireDrill.sol";
import "./Cobalt.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract Oberon {
    MineEmpireDrill public mineEmpireDrill;
    Cobalt public cobalt;
    ERC20 public cosmicCash;
    ERC20 public energy;
    address public owner;
    address treasury;
    address DEAD = 0x000000000000000000000000000000000000dEaD;
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
    mapping(address => bool) public unlocked;
    uint public CSC_UNLOCK_PRICE = 25e18;
    uint public ENERGY_UNLOCK_PRICE = 250e18;
    uint public SECONDS_IN_PERIOD = 2592000;
    uint public GENESIS_TIME;

    constructor(Cobalt _cobalt, ERC20 _cosmicCash, MineEmpireDrill _drill) {
        owner = msg.sender;
        GENESIS_TIME = block.timestamp;
        cobalt = _cobalt;
        cosmicCash = _cosmicCash;
        mineEmpireDrill = _drill;
        maxLevel = 9;
        capacityAtLevel[0] = 2505e18;
        capacityAtLevel[1] = 3131e18;
        capacityAtLevel[2] = 3914e18;
        capacityAtLevel[3] = 4893e18;
        capacityAtLevel[4] = 6850e18;
        capacityAtLevel[5] = 9589e18;
        capacityAtLevel[6] = 13425e18;
        capacityAtLevel[7] = 18795e18;
        capacityAtLevel[8] = 26313e18;
        capacityAtLevel[9] = 36183e18;
        upgradeRequirementAtLevel[1] = 25e18;
        upgradeRequirementAtLevel[2] = 25e18;
        upgradeRequirementAtLevel[3] = 25e18;
        upgradeRequirementAtLevel[4] = 40e18;
        upgradeRequirementAtLevel[5] = 40e18;
        upgradeRequirementAtLevel[6] = 75e18;
        upgradeRequirementAtLevel[7] = 75e18;
        upgradeRequirementAtLevel[8] = 120e18;
        upgradeRequirementAtLevel[9] = 150e18;
        productionRate[0] = 966e13;
        productionRate[1] = 821e13;
        productionRate[2] = 706e13;
        productionRate[3] = 615e13;
        productionRate[4] = 541e13;
        productionRate[5] = 481e13;
        productionRate[6] = 433e13;
        productionRate[7] = 394e13;
        productionRate[8] = 363e13;
        productionRate[9] = 337e13;
        productionRate[10] = 317e13;
        productionRate[11] = 301e13;
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

    modifier userUnlocked(address _user) {
        require(unlocked[_user] == true, "Oberon not unlocked for user");
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
    function updateUpgradeRequirementAtLevel(uint _level, uint _price) public onlyOwner(msg.sender) levelExists(_level){
        require(_level <= maxLevel, "level not less than max level");
        upgradeRequirementAtLevel[_level] = _price;
    }

    function updateEnergy(ERC20 _energy) public onlyOwner(msg.sender) {
        energy = _energy;
    }

    // GETTERS

    function getCurrentPeriod() public view returns(uint) {
        uint period = (block.timestamp - GENESIS_TIME) / SECONDS_IN_PERIOD;
        if (period > 11) {
            period = 11;
        }
        return period;
    }
    
    function getBaseProduction() public view returns(uint) {
        uint period = getCurrentPeriod();
        return productionRate[period];
    }

    function getAccumulatedCobalt(address _userAddress) public view drillStaked(_userAddress) returns(uint) {
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

    function unlock(bool useCSC) public {
        if (useCSC) {
            cosmicCash.transferFrom(msg.sender, treasury, CSC_UNLOCK_PRICE);
        } else {
            energy.transferFrom(msg.sender, DEAD, ENERGY_UNLOCK_PRICE);
        }
        unlocked[msg.sender] = true;
    }

    function stake(uint _drillId) public drillNotStaked(msg.sender) userUnlocked(msg.sender) {
        MineEmpireDrill.Drill memory drill = mineEmpireDrill.getDrill(_drillId);
        require(drill.drillType == 1, "incorrect drill type");
        mineEmpireDrill.safeTransferFrom(msg.sender, address(this), _drillId);
        stakes[msg.sender] = Stake(
            block.timestamp,
            drill);
    }

    function collectCobalt() public drillStaked(msg.sender) {
        uint amount = getAccumulatedCobalt(msg.sender);
        cobalt.mint(msg.sender, amount);
        stakes[msg.sender].timestamp = block.timestamp;
    }

    function unstake() public drillStaked(msg.sender) {
        uint amount = getAccumulatedCobalt(msg.sender);
        cobalt.mint(msg.sender, amount);
        mineEmpireDrill.safeTransferFrom(address(this), msg.sender, stakes[msg.sender].drill.drillId);
        delete stakes[msg.sender];
    }

    function upgrade() public userUnlocked(msg.sender) {
        uint curLevel = userLevel[msg.sender];
        require(curLevel < maxLevel, "level at max");
        uint upgradeAmt = upgradeRequirementAtLevel[curLevel + 1];
        cosmicCash.transferFrom(msg.sender, treasury, upgradeAmt);
        userLevel[msg.sender] = curLevel + 1;
        emit CapacityUpgraded(msg.sender, userLevel[msg.sender]);
        return;
    }
}