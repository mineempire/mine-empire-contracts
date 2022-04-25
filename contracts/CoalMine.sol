// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./BasicMiner.sol";
import "./Coal.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";

contract CoalMine {
    BasicMiner public basicMiner;
    Coal public coal;
    address public owner;
    uint256 public baseProduction;

    struct Stake {
        BasicMiner.Miner miner;
        uint256 timestamp;
    }

    mapping(address => Stake) public stakes;

    constructor() {
        owner = msg.sender;
        baseProduction = 1e16;
    }

    modifier isOwner(address _addr) {
        require(_addr == owner);
        _;
    }

    modifier minerStaked(address _addr) {
        require(stakes[_addr].timestamp > 0, "miner not staked");
        _;
    }

    // game pre-requisites
    function setMinerContract(address _addr) public isOwner(msg.sender) {
        basicMiner = BasicMiner(_addr);
    }

    function getMinerContract() public view returns (address) {
        return address(basicMiner);
    }

    function setResourceContract(address _addr) public isOwner(msg.sender) {
        coal = Coal(_addr);
    }

    function getResourceContract() public view returns (address) {
        return address(coal);
    }


    // contract functions
    function stake(uint256 _minerId) public {
        require(stakes[msg.sender].timestamp == 0, "already staked");
        basicMiner.safeTransferFrom(msg.sender, address(this), _minerId);
        stakes[msg.sender] = Stake(basicMiner.getMiner(_minerId), block.timestamp);
    }

    function unstake() public minerStaked(msg.sender) {
        basicMiner.safeTransferFrom(address(this), msg.sender, stakes[msg.sender].miner.minerId);
        delete stakes[msg.sender];
    }

    function getStake(address _addr) public view returns(Stake memory) {
        return stakes[_addr];
    }

    function onERC721Received(
        address operator,
        address from,
        uint256 id,
        bytes calldata data
    ) external pure returns (bytes4) {
        return bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"));
    }

    function getAccumulatedResources() public view returns (uint256) {
        require(stakes[msg.sender].timestamp > 0, "no miner staked");
        Stake memory cur = stakes[msg.sender];
        uint256 time = block.timestamp - cur.timestamp;
        uint256 amount = time * baseProduction / 100 * cur.miner.miningPower;
        uint256 coalCap = cur.miner.coalCapacity;
        if (coalCap < amount) {
            amount = coalCap;
        }
        return amount;
    }

    function collectResources() public minerStaked(msg.sender) {
        Stake memory cur = stakes[msg.sender];
        uint256 time = block.timestamp - cur.timestamp;
        uint256 amount = time * baseProduction / 100 * cur.miner.miningPower;
        uint256 coalCap = cur.miner.coalCapacity;
        if (coalCap < amount) {
            amount = coalCap;
        }
        coal.transfer(msg.sender, amount);
        stakes[msg.sender].timestamp = block.timestamp;
    }
}