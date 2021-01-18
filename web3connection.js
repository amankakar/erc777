const express = require('express')
var router = express.Router();
const Web3 = require("web3")
const fs = require('fs');
var path = require('path')
const Tx = require('ethereumjs-tx').Transaction;

var jsonFile = "./build/contracts/Bitcoinv1.json";
var keccak256 = require('keccak256')
const dotenv = require('dotenv').config();
var parsed = JSON.parse(fs.readFileSync(jsonFile));
var abi = parsed.abi;
var Bictoinv1;
var web3;
// Add headers
router.use(function (req, res, next) {

    web3 = new Web3(new Web3.providers.HttpProvider("http://localhost:8080"))

    Bictoinv1 = new web3.eth.Contract(abi, process.env.TokenContract);

    // Website you wish to allow to connect
    res.setHeader('Access-Control-Allow-Origin', '*');

    // Request methods you wish to allow
    res.setHeader('Access-Control-Allow-Methods', 'GET, POST, OPTIONS, PUT, PATCH, DELETE');

    // Request headers you wish to allow
    res.setHeader('Access-Control-Allow-Headers', 'X-Requested-With,content-type');

    // Set to true if you need the website to include cookies in the requests sent
    // to the API (e.g. in case you use sessions)
    res.setHeader('Access-Control-Allow-Credentials', true);

    // Pass to next layer of middleware
    next();
});
router.get('/getWeb3', async (req, res) => {

    const accounts = await web3.eth.getAccounts()
    console.log(await web3.eth.net.getId())
    console.log(accounts)
    res.send(accounts)
})

router.get('/generateAccounts', async (req, res) => {
    var account = await web3.eth.accounts.create();
    console.log(account)
    const path = './accounts/'
    const content = account.privateKey

    fs.mkdirSync(process.cwd() + path, { recursive: true }, (error) => {
        if (error) {
            res.status(500).json({ "error": error })
        }
    });
    fs.writeFile(path + '/' + account.address, content, (error) => {
        if (error) {
            res.status(500).json({ "error": error })
        }
    });

    res.status(200).json({ "status": 200, "message": "Accounts generated and data stored" })


});

router.get('/getBalanceOf', (req, res) => {
    // console.log(req.body)
    // var token = await Bictoinv1.methods.balanceOf(req.body.account).call()
    var account = req.body.account;
    Bictoinv1.methods.balanceOf(account).call()
        .then(response => {
            console.log(response)
            res.json({ "status": 200, "tokens": response })
        }).catch(e => {
            console.log(e)
        });
    // console.log(token)
    // var am = await web3.eth.getBalance("0xF7f1f19094e17ddA2D68Dfaf435E31a2018a0872")
    // res.status(200).json({ "status": 200, "tokens": token })

});
router.post('/transfer', async (req, res) => {
    var status, txHash;
    var sender = req.body.sender;
    var amount = req.body.amount;
    var recepient = req.body.recepient;
    var privateKey, gasLimit;
    fs.readFile('./accounts' + '/' + sender, (err, data) => {
        if (err) {
            res.status(500).json({ "error": err })
        }
        privateKey = data.toString();
        console.log(privateKey);
    });

    encoded = await Bictoinv1.methods.transfer(recepient, amount).encodeABI()
    var nonce = await web3.eth.getTransactionCount(sender)
    nonce = web3.utils.toHex(nonce)
    var gasLimit = await getGas()
    var tx = {
        "nonce": nonce,
        "to": process.env.TokenContract,
        "gas": gasLimit,
        "data": encoded,

    }
    var signed = await web3.eth.accounts.signTransaction(tx, privateKey)
    var receipt = await web3.eth.sendSignedTransaction(signed.rawTransaction)
    console.log(receipt)
    console.log("txHash:", receipt.transactionHash)
    console.log("status:", receipt.status)
    res.json({ "status": receipt.status, "recepient": recepient, "txHash": receipt.transactionHash, })

});

router.post("/send", async (req, res) => {
    var sender = req.body.sender;
    var amount = req.body.amount;
    var recepient = req.body.recepient;
    var privateKey;
    fs.readFile('./accounts' + '/' + sender, (err, data) => {
        if (err) {
            res.status(500).json({ "error": err })
        }
        privateKey = data.toString();
    });
    var gasLimit = await getGas()
    var gasPrice = await getGasPrice().toString()

    var encodeData = await web3.utils.asciiToHex(req.body.data)
    encoded = await Bictoinv1.methods.send(recepient, amount, encodeData).encodeABI()
    // var encoded = await Bictoinv1.methods.send(300).encodeABI()
    var nonce = await web3.eth.getTransactionCount(sender)
    nonce = web3.utils.toHex(nonce)
    gasPrice = web3.utils.toHex(gasPrice)

    var tx = {
        "nonce": nonce,
        "to": process.env.TokenContract,
        "gas": gasLimit,
        "data": encoded,
    }
    var signed = await web3.eth.accounts.signTransaction(tx, privateKey)
    var receipt = await web3.eth.sendSignedTransaction(signed.rawTransaction)

    console.log(receipt)
    console.log("txHash:", receipt.transactionHash)
    console.log("status:", receipt.status)
    res.json({ "txhash": receipt.transactionHash, "status": receipt.status, "recepient": recepient })

});

router.post("/test", async (req, res) => {
    var func = keccak256('mSymbol()').toString('hex')

    console.log(func)

    var child_process = require('child_process');
    var command = "curl -H \"Content-Type: application/json\" http://192.168.18.40:8080 -v -X POST --data '{\"jsonrpc\":\"2.0\",\"method\":\"web3_clientVersion\",\"params\":[],\"id\":64}'"

    console.log(command)
    async function runCmd(command) {
        var resp = await child_process.execSync(command);
        // var result = resp.toString('UTF8');
        return resp;
    }


    var result = await runCmd(command);

    var json = JSON.parse(result);
    var vale = json.result
    console.log(vale)
    res.send(vale)
    // console.log(str)
});
async function getGas() {
    var gasLimit = await web3.eth.getBlock("latest", false)
    console.log("gas:", gasLimit.gasLimit)
    var gasLimit1 = web3.utils.toHex(gasLimit.gasLimit);
    console.log("gas:", gasLimit1)

    return gasLimit1

}
async function getGasPrice() {
    return await web3.utils.fromWei(await web3.eth.getGasPrice(), 'gwei');
}



module.exports = router;

