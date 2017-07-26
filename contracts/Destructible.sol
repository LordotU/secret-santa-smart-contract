pragma solidity ^0.4.13;

import "./Ownable.sol";

contract Destructible is Ownable {
	
	function Destructible() payable { } 
	
	function destruct() onlyOwner internal {
		selfdestruct(owner);
	}
}
