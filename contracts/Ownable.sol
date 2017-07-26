pragma solidity ^0.4.13;

contract Ownable {
	address public owner;
	
	function Ownable() {
		owner = msg.sender;
	}
	
	modifier onlyOwner() {
		require(msg.sender == owner);
		_;
	}
	
	function changeOwnership(
		address newOwner
	) onlyOwner {
		require(newOwner != address(0));
		
		owner = newOwner;
	}
}
