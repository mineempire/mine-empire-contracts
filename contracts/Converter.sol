// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract Converter {
    address public owner;
    ERC20 public cosmicCash;
    address DEAD = 0x000000000000000000000000000000000000dEaD;
    struct Resource {
        ERC20 resource;
        uint conversionRate;
    }
    mapping(address => Resource) public rates;

    constructor() {
        owner = msg.sender;
    }

    // EVENTS
    event conversionComplete(address _resource, address _csc, uint amount);

    // MODIFIERS
    modifier onlyOwner(address _address) {
        require(_address == owner, "not authorized");
        _;
    }

    // ONLY OWNER
    function setResource(ERC20 _resource, uint _conversionRate) public onlyOwner(msg.sender) {
        rates[address(_resource)] = Resource(_resource, _conversionRate);
    }

    function setCosmicCash(ERC20 _cosmicCash) public onlyOwner(msg.sender) {
        cosmicCash = _cosmicCash;
    }

    // USER INTERFACE
    function convert(ERC20 _resource, uint _amount) public {
        uint conversionRate = rates[address(_resource)].conversionRate;
        uint amount = _amount/conversionRate;
        _resource.transferFrom(msg.sender, DEAD, _amount);
        cosmicCash.transfer(msg.sender, amount);
        emit conversionComplete(address(_resource), address(cosmicCash), amount);
    }
}