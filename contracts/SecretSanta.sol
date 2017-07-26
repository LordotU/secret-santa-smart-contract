pragma solidity ^0.4.13;

import "github.com/oraclize/ethereum-api/oraclizeAPI.sol";

import "./Ownable.sol";
import "./Destructible.sol";

import "./libraries/Random.sol";

contract SecretSanta is Ownable, Destructible, usingOraclize {
	
	uint public playTimeStart;
	uint public playTimeFinish;
	uint public amountMinimumToPlay;
	uint public maximumPlayers;
	uint public fee;
	
	struct Santa {
		address wallet;
		uint amount;
	}
	
	Santa[] santas;
	Santa[] assignedSantas;
	
	mapping(bytes32 => Santa) waitingSantas;
	mapping(address => uint) allSantas;
	mapping(string => uint) oraclizeFees;
	
	event NewSanta(
		uint indexed _now,
		address indexed _wallet,
		uint _amount
	);
	event AssignSantas(
		uint indexed _now,
		uint _overallSantas,
		uint _overallFunds
	);
	event PlayFinish(
		uint indexed _now,
		bool _finish
	);
	
	function SecretSanta(
		uint playTimeStartArg,
		uint playTimeFinishArg,
		uint amountMinimumToPlayArg,
		uint feeArg,
		uint maximumPlayersArg
	) {
		playTimeStart = playTimeStartArg;
		playTimeFinish = playTimeFinishArg;
		
		amountMinimumToPlay = amountMinimumToPlayArg;
		fee = feeArg;
		
		maximumPlayers = maximumPlayersArg;
		
		oraclizeFees['URL'] = 40000000000000;
		oraclizeFees['Blockchain'] = 40000000000000;
		oraclizeFees['IPFS'] = 40000000000000;
		oraclizeFees['WolframAlpha'] = 120000000000000;
		oraclizeFees['random'] = 200000000000000;
		oraclizeFees['computation'] = 2000000000000000;
	}
	
	function() payable {
		require(
			msg.value >= amountMinimumToPlay &&
			allSantas[msg.sender] == uint(0x0) &&
			santas.length <= maximumPlayers
		);
		
		bytes32 oraclizeQueryId = oraclize_query("WolframAlpha", "Unix timestamp");
		
		waitingSantas[oraclizeQueryId] = Santa(
			msg.sender,
			msg.value - (fee + oraclizeFees['WolframAlpha'])
		);
		allSantas[msg.sender] = msg.value;
	}
	
	function getOverallSantas() constant returns (uint) {
		return santas.length;
	}
	
	function getOverallFunds() constant returns (uint overallFunds) {
		overallFunds = 0;
		
		for(uint i = 0; i < santas.length; i++) {
			overallFunds += santas[i].amount;
		}
		
		return overallFunds;
	}
	
	function checkPlayer(address playerAddress) constant returns (bool checkResult, uint checkAmount) {
		checkResult = false;
		checkAmount = 0;
		
		for(uint i = 0; i < santas.length; i++) {
			if(santas[i].wallet == playerAddress) {
				checkResult = true;
				if (msg.sender == owner || msg.sender == santas[i].wallet) {
					checkAmount = santas[i].amount;
				}
				break;
			}
		}
		
		return (checkResult, checkAmount);
		
	}
	
	function checkSender() constant returns (bool checkResult, uint checkAmount) {
		return checkPlayer(msg.sender);
	}
	
	function update(
		uint playTimeStartArg,
		uint playTimeFinishArg,
		uint amountMinimumToPlayArg,
		uint feeArg,
		uint maximumPlayersArg
	) onlyOwner {
		playTimeStart = playTimeStartArg;
		playTimeFinish = playTimeFinishArg;
		
		amountMinimumToPlay = amountMinimumToPlayArg;
		fee = feeArg;
		
		maximumPlayers = maximumPlayersArg;
	}
	
	function assignSantas() onlyOwner  {
		require(santas.length > 2);
		
		Santa[] memory shuffledSantas = shuffleSantas();
		
		for(uint i = 0; i < shuffledSantas.length; i++) {
			Santa memory santa = shuffledSantas[i];
			Santa memory recipient;
			
			if(i != shuffledSantas.length - 1) {
				recipient = shuffledSantas[i + 1];
			} else {
				recipient = shuffledSantas[0];
			}
			
			assignedSantas.push( Santa(recipient.wallet, santa.amount) );
		}
		
		AssignSantas(
			now,
			getOverallSantas(),
			getOverallFunds()
		);
	}
	
	function finishPlay() onlyOwner {
		require(assignedSantas.length > 2);
		
		for(uint i = 0; i < assignedSantas.length; i++) {
			Santa memory recipient = assignedSantas[i];
			recipient.wallet.transfer(recipient.amount);
		}
		
		PlayFinish(
			now,
			true
		);
		
		destruct();
	}
	
	function __callback(
		bytes32 oraclizeQueryId,
		string oraclizeQueryResult
	) {
		
		uint oraclizeQueryResultParsed = parseInt(oraclizeQueryResult);
		
		if(
			msg.sender == oraclize_cbAddress() &&
			oraclizeQueryResultParsed >= playTimeStart &&
			oraclizeQueryResultParsed < playTimeFinish
		) {
		
			santas.push(waitingSantas[oraclizeQueryId]);
			delete waitingSantas[oraclizeQueryId];
			
			NewSanta(
				now,
				waitingSantas[oraclizeQueryId].wallet,
				waitingSantas[oraclizeQueryId].amount
			);
			
		} else {
			
			withdrawWaitingSantaRefund(oraclizeQueryId);
			
		}
	}
	
	function withdrawWaitingSantaRefund(bytes32 oraclizeQueryId) private {
		Santa memory waitingSanta = waitingSantas[oraclizeQueryId];
		uint refund = waitingSanta.amount;
		waitingSanta.amount = 0;
		
		if ( waitingSanta.wallet.send(refund + fee) ) {
			delete waitingSantas[oraclizeQueryId];
			delete allSantas[waitingSanta.wallet];
		} else {
			waitingSantas[oraclizeQueryId].amount = refund;
		}
	}
	
	function shuffleSantas() private returns(Santa[] shuffledSantas) {
		shuffledSantas = santas;
		uint n = shuffledSantas.length;
		
		require(n > 2);
		
		uint i;
		Santa memory tmpSanta;
		
		while(n > 0) {
			i = Random.gen(now, n--);
			tmpSanta = shuffledSantas[n];
			shuffledSantas[n] = shuffledSantas[i];
			shuffledSantas[i] = tmpSanta;
		}
		
		return shuffledSantas;
	}
}
