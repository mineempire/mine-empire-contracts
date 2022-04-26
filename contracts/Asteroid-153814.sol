// SPDX-License-Identifier: MIT
// Asteroid info: https://theskylive.com/153814-info

pragma solidity ^0.8.0;

import "./MineEmpireDrill.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/presets/ERC20PresetMinterPauser.sol";

contract Asteroid153814 {
    MineEmpireDrill public drill;
    ERC20PresetMinterPauser public iron;
    ERC20PresetMinterPauser public gold;
    address public owner;
    uint public baseProduction;
    uint public capacityPerUnit;
    uint public refinerCapacity;
    uint[] private refinerEfficiency;
    uint[] private refinerUpgradeRequirement;
    uint private maxRefinerLevel;

    struct Stake {
        MineEmpireDrill.Drill drill;
        uint timestamp;
    }

    mapping(address => Stake) public stakes;
    mapping(address => uint) public refinerLevel;
    mapping(address => uint) public lastRefined;

    constructor(ERC20PresetMinterPauser inputResource, ERC20PresetMinterPauser outputResource, MineEmpireDrill _drill) {
        owner = msg.sender;
        baseProduction = 1e16;
        capacityPerUnit = 100;
        refinerCapacity = 1e22;
        iron = inputResource;
        gold = outputResource;
        drill = _drill;
        refinerEfficiency = [50, 55, 61, 67, 73, 80, 88, 100];
        refinerUpgradeRequirement = [40e20, 50e20, 60e20, 70e20, 80e20, 100e20];
        maxRefinerLevel = 7;
    }

    function onERC721Received(
        address operator,
        address from,
        uint256 id,
        bytes calldata data
    ) external pure returns (bytes4) {
        return bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"));
    }

    // events
    event LogRefinement(uint _amountMinted);
    event LogRefinerUpgraded(uint _newLevel);
    // modifiers
    modifier onlyOwner(address _address) {
        require(_address == owner);
        _;
    }

    modifier drillStaked(address _address) {
        require(stakes[_address].timestamp > 0, "drill not staked for this user");
        _;
    }

    // owner only
    function setRefinerCapacity(uint _cap) public onlyOwner(msg.sender) {
        refinerCapacity = _cap;
    }

    function updateRefinerEfficiency(
        uint[] memory newEfficiencyList
        ) public onlyOwner(msg.sender) {
        for (uint i = 0; i < maxRefinerLevel; i++) {
            require(newEfficiencyList[i] != 0, "invalid input for available level");
        }
        refinerEfficiency = newEfficiencyList;
    }

    function updateRefinerUpgradeRequirements(
        uint[] memory newRefinerUpgradeRequirements
    ) public onlyOwner(msg.sender) {
        for (uint i = 0; i < maxRefinerLevel; i++) {
            require(newRefinerUpgradeRequirements[i] != 0, "invalid input for available level");
        }
        refinerUpgradeRequirement = newRefinerUpgradeRequirements;
    }

    function updateMaxRefinerLevel(uint newLevel) public onlyOwner(msg.sender) {
        maxRefinerLevel = newLevel;
    }

    // user interface
    function stake(uint256 _drillId) public {
        require(stakes[msg.sender].timestamp == 0, "user already staked");
        drill.safeTransferFrom(msg.sender, address(this), _drillId);
        stakes[msg.sender] = Stake(drill.getDrill(_drillId), block.timestamp);
    }

    function unstake() public {
        require(stakes[msg.sender].timestamp > 0, "drill not staked");
        drill.safeTransferFrom(address(this), msg.sender, stakes[msg.sender].drill.drillId);
        delete stakes[msg.sender];
    }

    function collectResources() public {
        Stake memory curStake = stakes[msg.sender];
        uint miningMultiplier = drill.getDrillMiningPower(curStake.drill.drillId);
        uint capacity = drill.getDrillCapacity(curStake.drill.drillId);
        uint time = block.timestamp - curStake.timestamp;
        uint amount = time * baseProduction / 100 * miningMultiplier / 100 * capacityPerUnit;
        if (capacity < amount) {
            amount = capacity;
        }
        iron.mint(msg.sender, amount);
        stakes[msg.sender].timestamp = block.timestamp;
    }

    function refine(uint _amount) public {
        uint timeSinceLastRefine = block.timestamp - lastRefined[msg.sender];
        if (timeSinceLastRefine > 86400) {
            timeSinceLastRefine = 86400;
        }
        require(_amount <= refinerCapacity * timeSinceLastRefine / 864000, 
                "amount to refine exceeds daily capacity");

        iron.transferFrom(msg.sender, address(this), _amount);
        uint userRefinerLevel = refinerLevel[msg.sender];
        if (userRefinerLevel == 0) {
            refinerLevel[msg.sender] = 1;
            userRefinerLevel = 1;
        }
        uint amountToMint = _amount * refinerEfficiency[userRefinerLevel-1] / 100;
        gold.mint(msg.sender, amountToMint);
        lastRefined[msg.sender] = block.timestamp;
        emit LogRefinement(amountToMint);
    }

    function upgradeRefiner() public {
        if (refinerLevel[msg.sender] == 0) {
            refinerLevel[msg.sender] = 1;
        }
        uint curLevel = refinerLevel[msg.sender];
        require(curLevel < maxRefinerLevel, "refiner at max level");
        uint requiredAmount = refinerUpgradeRequirement[curLevel - 1];
        iron.transferFrom(msg.sender, address(this), requiredAmount);
        refinerLevel[msg.sender] = curLevel + 1;
        emit LogRefinerUpgraded(curLevel + 1);
    }

    // getters
    function getStake(address _address) public view returns(Stake memory) {
        return stakes[_address];
    }

    function getAccumulatedRocks() public view returns (uint) {
        require(stakes[msg.sender].timestamp > 0, "no drill staked");
        Stake memory curStake = stakes[msg.sender];
        uint time = block.timestamp - curStake.timestamp;
        uint miningMultiplier = drill.getDrillMiningPower(curStake.drill.drillId);
        uint capacity = drill.getDrillCapacity(curStake.drill.drillId);
        uint amount = time * baseProduction / 100 * miningMultiplier / 100 * capacityPerUnit;
        if (capacity < amount) {
            amount = capacity;
        }
        return amount;
    }

    function getBaseProduction() public view returns (uint) {
        return baseProduction;
    }

    function getCapacityPerUnit() public view returns (uint) {
        return capacityPerUnit;
    }

    function getRefinerCapacity() public view returns (uint) {
        return refinerCapacity;
    }

    function getRefinerUpgradeRequirement() public view returns (uint) {
        uint userRefinerLevel = refinerLevel[msg.sender];
        if (userRefinerLevel == 0) {
            userRefinerLevel = 1;
        }
        return refinerUpgradeRequirement[userRefinerLevel-1];
    }

}