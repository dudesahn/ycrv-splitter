// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {IERC20, SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract Receiver1 {
    using SafeERC20 for IERC20;

    address public owner;
    address public pendingOwner;
    address public guardian;
    mapping(address spender => bool approved) public approvedSpenders;

    event SpenderApproved(address indexed spender, bool indexed approved);
    event OwnershipTransferred(address indexed pendingOwner);
    event GuardianSet(address indexed guardian);

    constructor(address _owner, address _guardian) {
        owner = _owner;
        guardian = _guardian;
    }

    modifier _onlyOwner() {
        require(msg.sender == owner, "!Owner");
        _;
    }

    modifier _onlyAdmins() {
        require(
            msg.sender == owner ||
            msg.sender == guardian,
            "!Admin"
        );
        _;
    }

    function transferToken(
        IERC20 token,
        address receiver,
        uint256 amount
    ) external {
        require(approvedSpenders[msg.sender], "!Approved");
        _transfer(token, receiver, amount);
    }

    function transferManyTokens(
        IERC20[] memory tokens,
        address receiver,
        uint256[] memory amounts
    ) external {
        require(approvedSpenders[msg.sender], "!Approved");
        require(tokens.length == amounts.length, "Array lengths dont match");
        for(uint i; i < tokens.length; i++) {
            _transfer(tokens[i], receiver, amounts[i]);
        }
    }

    function _transfer(
        IERC20 token,
        address receiver,
        uint256 amount
    ) internal {
        token.safeTransfer(receiver, amount);
    }

    function setApprovedSpender(address _spender, bool _approved) external _onlyAdmins() {
        if (msg.sender == guardian) {
            require(_approved == false, "Guardian may only disable");
        }
        require(approvedSpenders[_spender] != _approved, "!Update");
        approvedSpenders[_spender] = _approved;
        emit SpenderApproved(_spender, _approved);
    }

    function setOwner(address _pendingOwner) external _onlyOwner {
        pendingOwner = _pendingOwner;
    }

    function acceptOwnership() external {
        require(msg.sender == pendingOwner, "!Pending owner");
        owner = pendingOwner;
        pendingOwner = address(0);
        emit OwnershipTransferred(pendingOwner);
    }

    function setGuardian(address _guardian) external _onlyOwner {
        guardian = _guardian;
        emit GuardianSet(_guardian);
    }
}