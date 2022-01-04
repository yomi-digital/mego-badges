const HDWalletProvider = require("@truffle/hdwallet-provider");
const web3 = require("web3");
require('dotenv').config()
const argv = require('minimist')(process.argv.slice(2));
const fs = require('fs')
const contract_name = argv._[0]
const NFT_CONTRACT_ABI = require('../abi.json')

async function main() {
    try {
        const configs = JSON.parse(fs.readFileSync('./configs/' + argv._ + '.json').toString())
        const provider = new HDWalletProvider(
            configs.owner_mnemonic,
            configs.provider
        );
        const web3Instance = new web3(provider);
        const nftContract = new web3Instance.eth.Contract(
            NFT_CONTRACT_ABI,
            configs.contract_address, { gasLimit: "10000000" }
        );
        console.log('Testing contract: ' + argv._)
        console.log('--')
        console.log('CONTRACT ADDRESS IS:', configs.contract_address)
        const owner = await nftContract.methods.owner().call();
        console.log('OWNER IS:', owner)
        const contractURI = await nftContract.methods.contractURI().call();
        console.log('Contract URI:', contractURI)
        console.log('--')
        let exists = true
        let i = 1;
        console.log('Checking NFTs..')
        console.log('--')
        try {
            while (exists) {
                exists = false
                let owned = []
                for (let k in configs.minters) {
                    const balance = await nftContract.methods.balanceOf(configs.minters[k], i).call();
                    owned.push('OWNED BY ' + configs.minters[k] + ': ' + balance)
                    if (balance > 0) {
                        exists = true
                    }
                }
                if (exists) {
                    console.log('NFT TYPE: ' + i)
                    let uri = await nftContract.methods.uri(i).call();
                    let longId = String(i).padStart(64, "0")
                    uri = uri.replace('{id}', longId)
                    console.log('URI IS ' + uri)
                    console.log('MINTERS OWNS', owned)
                    console.log('--')
                }
                i++;
            }
        } catch (e) {
            console.log(e.message)
        }
        process.exit();
    } catch (e) {
        console.log(e.message)
        process.exit();
    }
}

if (argv._ !== undefined) {
    main();
} else {
    console.log('Provide a deployed contract first.')
}