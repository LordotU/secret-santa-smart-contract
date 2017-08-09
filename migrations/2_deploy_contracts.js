const Destructible  = artifacts.require("./Destructible.sol");
const Random        = artifacts.require("./Random.sol");
const usingOraclize = artifacts.require("./usingOraclize.sol");

const SecretSanta   = artifacts.require("./SecretSanta.sol");

module.exports = function(deployer) {
	
	deployer.deploy([Destructible, Random, usingOraclize]);
	
	deployer.link(Destructible, SecretSanta);
	deployer.link(Random, SecretSanta);
	deployer.link(usingOraclize, SecretSanta);
	
	deployer.deploy(
		SecretSanta,
		1504213200,
		1512075600,
		"100000000000000000",
		"10000000000000000",
		10,
	);
};
