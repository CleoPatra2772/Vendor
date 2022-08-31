// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;
import './ERC20.sol';

/*Purpose: smart contract for a vendor with following functions:
buyToken()
sellToken()
withdrawal balance()

*/

contract VendorCLC is Ownership {
    MyERC20 _myERC20;
    address private VOwner;
    uint TokensPerEther = 100;
    event BuyToken(address indexed buyer, uint256 _value, uint256 _qty );
    event SellToken(address indexed seller, uint256 _howmany, uint256 _amount);
    event WithdrawalBalance(address indexed vendor, uint256 _balance);

    constructor( address myERC20_ ){
        VOwner = msg.sender;
       _myERC20 = MyERC20(myERC20_);
    }

    function buyToken () payable public returns (bool success){
        require (msg.value >= 1 ether, 'Min purchase is 1 eth');
        uint tokenQty = (msg.value/1 ether) * TokensPerEther;
        uint vendorTokenBal = _myERC20.balanceOf(address(this));

        require(vendorTokenBal >= tokenQty, "Insufficent" );
        (bool sent) = _myERC20.transfer(msg.sender, tokenQty);
        require(sent, 'Token transfer failed');

        emit BuyToken(msg.sender, msg.value, tokenQty);

        return true;

    }

    function sellToken(uint256 howMany) payable public returns (bool transfered){
        uint256 _token = howMany % TokensPerEther;
        require( _token == 0, 'Must sell in multiple of 100');

        uint256 limitQty = _myERC20.allowance(msg.sender, address(this));
        require(limitQty >= howMany, "Exceeded allowed qty");

        uint256 qtyInEther = howMany / TokensPerEther;
        uint256 vendorBal = (address(this).balance / 1 ether);
        require(vendorBal >= qtyInEther, 'Insufficent Fund');

        (bool success) = _myERC20.transferFrom(msg.sender, address(this), howMany);
        require(success, 'Failed in transfer from sender to vendor');

        (bool sent,)= msg.sender.call{value: qtyInEther * 1e18 }('');
        require(sent, 'fail in ether transfer');
        emit SellToken(msg.sender, howMany, qtyInEther);
        return true;
    }

    function withdrawal() public payable returns (bool) {
        require(msg.sender == VOwner, 'Only owner can withdraw');
        uint256 contractBal = address(this).balance;
        require(contractBal > 0, 'Balance is zero');

        (bool sent,) = msg.sender.call{value: contractBal}('');
        require(sent, 'Failed in withdrawal');

        emit WithdrawalBalance(msg.sender, contractBal);

        return true;


    }
}