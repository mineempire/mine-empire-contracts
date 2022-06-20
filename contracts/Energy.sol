// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract Energy is ERC20 {
    mapping(address => bool) public allowedTransferrers;
    address public owner;

    constructor() ERC20("Energy", "NRG") {
        owner = msg.sender;
    }

    // MODIFIERS
    modifier onlyOwner(address _address) {
        require(_address == owner, "not owner");
        _;
    }

    modifier allowedTransferrer(address _address) {
        require(allowedTransferrers[_address] == true, "address not allowed to transfer");
        _;
    }

    modifier canMint(address _address) {
        require(allowedTransferrers[_address] == true || _address == owner, "address not allowed to mint");
        _;
    }

    // ONLY OWNER
    function setTransferrer(address _address, bool _canTransfer) public onlyOwner(msg.sender) {
        allowedTransferrers[_address] = _canTransfer;
    }

    // USER INTERFACE
    function transfer(address to, uint256 amount) public override allowedTransferrer(msg.sender) returns(bool) {
        _transfer(msg.sender, to, amount);
        return true;
    }

    function transferFrom(address from, address to, uint256 amount) public override allowedTransferrer(msg.sender) returns(bool) {
        _spendAllowance(from, msg.sender, amount);
        _transfer(from, to, amount);
        return true;
    }

    function burn(address account, uint256 amount) public allowedTransferrer(msg.sender) returns (bool) {
        _burn(account, amount);
        return true;
    }

    function mint(address account, uint256 amount) public canMint(msg.sender) {
        _mint(account, amount);
    }
}