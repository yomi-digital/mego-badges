const HDWalletProvider = require("@truffle/hdwallet-provider");
const web3 = require("web3");
require('dotenv').config()
const MNEMONIC = process.env.GANACHE_MNEMONIC;
const NFT_CONTRACT_ADDRESS = process.env.GANACHE_CONTRACT_ADDRESS;
const OWNER_ADDRESS = process.env.GANACHE_OWNER_ADDRESS;
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
                gasLimit: "5000000"
            }
        );
        // CUSTOMIZE THE AMOUNT MINTED AND TOKEN ID
        const nft_type = 1
        const eventDate = "04-01-2022".split("-");
        const eventTime = "17:06".split(":");
        const start_timestamp = parseInt(new Date(eventDate[2], eventDate[1] - 1, eventDate[0], eventTime[0], eventTime[1]).getTime() / 1000)
        const claimDeadline = "30-01-2022".split("-");
        const claimTime = "10:00".split(":");
        const end_timestamp = parseInt(new Date(claimDeadline[2], claimDeadline[1] - 1, claimDeadline[0], claimTime[0], claimTime[1]).getTime() / 1000)
        console.log('Setting timestamp to ' + start_timestamp)
        try {
            let nonce = await web3Instance.eth.getTransactionCount(configs.owner_address)
            console.log('Trying preparing event type ' + nft_type + ' with ' + configs.owner_address + ' with nonce ' + nonce + '...')
            const result = await nftContract.methods
                .prepare(nft_type, start_timestamp, end_timestamp)
                .send({
                    from: configs.owner_address,
                    nonce: nonce,
                    gasPrice: "100000000000"
                }).on('transactionHash', pending => {
                    console.log('Pending TX is: ' + pending)
                })
            console.log("Event prepared! Transaction: " + result.transactionHash);
        } catch (e) {
            console.log(e)
        }
        console.log('Finished!')
        process.exit()
    } else {
        console.log('Please provide `owner_mnemonic` first.')
    }

}

if (argv._ !== undefined) {
    main();
} else {
    console.log('Provide a deployed contract first.')
}