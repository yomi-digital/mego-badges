const BadgeME = artifacts.require("./BadgeME.sol");
const fs = require('fs')

module.exports = async (deployer, network) => {
    let PolygonMEAddress = process.env.ME_ADDRESS
    await deployer.deploy(BadgeME, PolygonMEAddress);
    const contract = await BadgeME.deployed();

    let configs = JSON.parse(fs.readFileSync(process.env.CONFIG).toString())
    console.log('Saving address in config file..')
    configs.contract_address = contract.address
    fs.writeFileSync(process.env.CONFIG, JSON.stringify(configs, null, 4))
    console.log('--')
};