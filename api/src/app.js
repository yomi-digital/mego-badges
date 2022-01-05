const express = require("express");
const web3 = require("web3");
const HDWalletProvider = require("@truffle/hdwallet-provider");
const cors = require('cors')
const axios = require('axios')
require('dotenv').config()
const NFT_CONTRACT_ABI = require('../abi.json')
const port = 3000;
const app = express()
app.use(cors())
app.use(express.json())


app.get("/:nftId", async function(req, res) {
    try {
        // Get IPFS metadata by ID
        // Download and serve IPFS metadata
    } catch (e) {
        console.log(e);
        res.status(500).json({
            error: "Something goes wrong, please retry"
        });
    }
});

app.listen(port, () => {
    console.log(`badgeme-api listen at http://localhost:${port}`)
})