const fs             = require('fs');
const merge          = require('lodash.merge');
const configDefaults = require('./truffle.js.default');


/**
 * [readConfigDir description]
 * @param  {[type]} configDir [description]
 * @return {[type]}           [description]
 */
const readConfigDir = configDir => (
	fs.readdirSync(`./config/${configDir}`)
		.filter ( file => /\.js/.test(file) )
		.map    ( file => file.replace(/\.js$/i, '') )
);


/**
 * [buildConfigPart description]
 * @param  {[type]} configType         [description]
 * @param  {[type]} configTypeDefaults [description]
 * @return {[type]}                    [description]
 */
const buildConfigPart = (configType, configTypeDefaults) => (
	readConfigDir(configType).reduce(
		(configPart, key) => {
			configPart[configType][key] = merge(
				{},
				configTypeDefaults,
				require(`./config/${configType}/${key}`)
			);
			return configPart;
		},
		{
			[configType] : {}
		}
	)
);


const configAssigned = merge(
	{},
	configDefaults,
	buildConfigPart('networks', configDefaults.rpc),
);

module.exports = configAssigned;
