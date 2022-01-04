const HDWalletProvider = require("@truffle/hdwallet-provider");
const web3 = require("web3");
require('dotenv').config()
const ethJS = require('ethereumjs-wallet')
const bip39 = require('bip39')
const ETH_DERIVATION_PATH = 'm/44\'/60\'/0\'/0'
const NFT_CONTRACT_ABI = require('../abi.json')
const argv = require('minimist')(process.argv.slice(2));
const fs = require('fs')

async function derive(mnemonic, shift) {
    const hdwallet = ethJS.hdkey.fromMasterSeed(await bip39.mnemonicToSeed(mnemonic));
    let address
    const derivePath = hdwallet.derivePath(ETH_DERIVATION_PATH).deriveChild(shift);
    const privkey = derivePath.getWallet().getPrivateKeyString();
    const wallet = ethJS.default.fromPrivateKey(Buffer.from(privkey.replace('0x', ''), 'hex'));
    address = wallet.getAddressString()
    console.log('Generated: ' + address)
    return address
}

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
                gasLimit: "6000000"
            }
        );
        // CUSTOMIZE THE AMOUNT MINTED AND TOKEN ID
        const nft_type = 1
        let toWhitelist = []
        console.log('Generating list...')
        for (let i = 1; i <= 350; i++) {
            const newAdress = await derive(configs.owner_mnemonic, i)
            toWhitelist.push(newAdress)
        }
        console.log('Adding to whitelist:', toWhitelist)
        try {
            let nonce = await web3Instance.eth.getTransactionCount(configs.owner_address)
            console.log('Trying adding in whitelist ' + nft_type + ' with ' + configs.owner_address + ' with nonce ' + nonce + '...')
            const result = await nftContract.methods
                .manageAddressWhitelist(nft_type, toWhitelist, true, 1)
                .send({
                    from: configs.owner_address,
                    nonce: nonce,
                    gasPrice: "100000000000"
                }).on('transactionHash', pending => {
                    console.log('Pending TX is: ' + pending)
                })
            console.log("Whitelist changed: " + result.transactionHash);
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