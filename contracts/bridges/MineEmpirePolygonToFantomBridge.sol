// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract MineEmpirePolygonToFantomBridge {
    address public owner;
    ERC20 public gem;

    constructor() {
        owner = msg.sender;
    }

    // EVENT
    event ReleasedToPolygon(address user, uint amount);

    // MODIFIER
    modifier onlyOwner(address _address) {
        require(_address == owner, "not authorized");
        _;
    }

    // ADMIN ONLY
    function setGem(ERC20 _gem) public onlyOwner(msg.sender) {
        gem = _gem;
    }

    function release(address _address, uint _amount) public onlyOwner(msg.sender) {
        gem.transfer(_address, _amount);
        emit ReleasedToPolygon(_address, _amount);
    }
}