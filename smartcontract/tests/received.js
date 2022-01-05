const HDWalletProvider = require("@truffle/hdwallet-provider");
const web3 = require("web3");
require('dotenv').config()
const NFT_CONTRACT_ABI = require('../abi.json')
const argv = require('minimist')(process.argv.slice(2));
const fs = require('fs')

async function main() {
    const configs = JSON.parse(fs.readFileSync('./configs/' + argv._ + '.json').toString())
    if (configs.owner_mnemonic !== undefined) {
        const provider = new HDWalletProvider(
            configs.owner_mnemonic,
            configs.provider
        );
        const web3Instance = new web3(provider);

        const nftContract = new web3Instance.eth.Contract(
            NFT_CONTRACT_ABI,
            configs.contract_address, {
                gasLimit: "500000",
                gasPrice: "100000000000"
            }
        );

        try {
            console.log('Trying fetching created events...')
            const result = await nftContract.methods
                .received("0x19ddC76B6ea171e6C89E586907504753f040127b")
                .call();
            console.log(result)
            for (let k in result) {
                const tokenCID = await nftContract.methods.tokenCID(result[k]).call()
                console.log('IPFS CID:', tokenCID)
            }
            process.exit();
        } catch (e) {
            console.log(e)
            process.exit();
        }
    } else {
        console.log('Please provide `owner_mnemonic` first.')
    }

}

if (argv._ !== undefined) {
    main();
} else {
    console.log('Provide a deployed contract first.')
}