// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/presets/ERC20PresetMinterPauser.sol";

contract Converter {
    address public owner;
    ERC20PresetMinterPauser public cosmicCash;
    address payable treasury;
    struct Resource {
        ERC20PresetMinterPauser resource;
        uint conversionRate;
    }
    mapping(address => Resource) public rates;

    constructor(ERC20PresetMinterPauser _cosmicCash) {
        owner = msg.sender;
        cosmicCash = _cosmicCash;
    }

    // EVENTS
    event conversionComplete(address _resource, address _csc, uint amount);

    // MODIFIERS
    modifier onlyOwner(address _address) {
        require(_address == owner, "not authorized");
        _;
    }

    // ONLY OWNER
    function setResource(ERC20PresetMinterPauser _resource, uint _conversionRate) public onlyOwner(msg.sender) {
        rates[address(_resource)] = Resource(_resource, _conversionRate);
    }

    function setTreasury(address payable _address) public onlyOwner(msg.sender) {
        treasury = _address;
    }

    // USER INTERFACE
    function convert(ERC20PresetMinterPauser _resource, uint _amount) public {
        uint conversionRate = rates[address(_resource)].conversionRate;
        uint amount = _amount/conversionRate;
        _resource.transferFrom(msg.sender, treasury, _amount);
        cosmicCash.transfer(msg.sender, amount);
        emit conversionComplete(address(_resource), address(cosmicCash), amount);
        return;
    }
}