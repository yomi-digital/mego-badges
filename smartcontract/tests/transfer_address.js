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
        const web3Instance = new web3(provider)
        const gasPrice = await web3Instance.eth.getGasPrice() * 15
        console.log('USING GAS ' + gasPrice)
        const contract = new web3Instance.eth.Contract(
            NFT_CONTRACT_ABI,
            configs.contract_address
        );

        // CHANGE THIS PARAM TO SEND ANOTHER TYPE OF AIRDROP
        const created = await contract.methods
            .created(configs.owner_address)
            .call();
        if (created.length === 0) {
            console.log('Create an event first')
            process.exit()
        }
        const nft_type = created[created.length - 1]
        const receiver = "0x19ddC76B6ea171e6C89E586907504753f040127b"
        const check = await contract.methods.balanceOf(receiver, nft_type).call()
        console.log('Name received badge?', check === "1")
        if (parseInt(check) === 0) {
            try {
                let nonce = await web3Instance.eth.getTransactionCount(configs.owner_address)
                const transfer = await contract.methods
                    .transferBadge(receiver, "", nft_type)
                    .send({
                        from: configs.owner_address,
                        nonce: nonce,
                        gasPrice: "200000000000",
                        gas: "1000000"
                    })
                console.log('Transfer successful!', transfer.transactionHash)
                const check = await contract.methods.balanceOf(receiver, nft_type).call()
                console.log('Name received badge then?', check === "1")
            } catch (e) {
                console.log('Transfer errored..', e.message)
                process.exit()
            }
        } else {
            console.log('NFT already sent to ' + receiver)
        }
    }
}

if (argv._ !== undefined) {
    main()
} else {
    console.log('Provide a deployed contract first.')
}