const Web3 = require("web3")
const fs = require('fs');
const path = require('path')

const jsonFile = "./build/contracts/Bitcoinv1.json";

//const dotenv = require('dotenv').config();
var parsed = JSON.parse(fs.readFileSync(jsonFile));
var abi = parsed.abi;
var web3 = new Web3(new Web3.providers.HttpProvider(process.env.ETHHOST));
var Bitcoinv1 = new web3.eth.Contract(abi, process.env.TOKEN_CONTRACT);

module.exports.generateAddress = async () => {

    return new Promise(async (resolve, reject) => {

        var account = await web3.eth.accounts.create();
        response = {
            address: account.address,
            private_key: account.privateKey
        };
        resolve(response);
    });
};

module.exports.getBalance = async (account_address) => {

    return await new Promise(async (resolve, reject) => {

        await web3.eth.getBalance(account_address, async (err, balance) => {
            if (err) {
                reject(err)
            }
            var balance = await web3.utils.fromWei(web3.utils.toBN(balance).toString(), 'ether')
            if (balance) {
                response = {
                    balance: balance
                }
                resolve(response)
            } else {
                reject(err)
            }


        })


    });
}

module.exports.getToken = async (account) => {
    return await new Promise(async (resolve, reject) => {
        await web3.eth.call({
            to: process.env.TokenContract,
            data: Bictoinv1.methods.balanceOf(account).encodeABI()
        }).then(balance => {
            console.log(balance)
            var b = web3.utils.hexToNumberString(balance)
            response = {
                token: b
            }
            resolve(response)
        }).catch(e => {
            reject(e)
        });

    });

};

module.exports.transfer = async (sender, recipient, amount, privateKey) => {
    //var privateKey;
    return await new Promise(async (resolve, reject) => {

        encoded = await Bitcoinv1.methods.transfer(recipient, amount).encodeABI();
        const nonce = await web3.eth.getTransactionCount(sender, 'pending');
        nonce = web3.utils.toHex(nonce);
        const gasLimit = await getGas();
        const Ether = await this.getBalance(sender)


        if (Ether.balance < gasLimit) {
            response = {
                "status": 403,
                "message": "sorry. No suffiecent Ethers to perform transaction."
            }
            return resolve(response)
        }
        const token = await this.getToken(sender)
        console.log(token.token, amount, parseInt(amount) > parseInt(token.token))
        if (parseInt(token.token) < parseInt(amount)) {
            response = {
                "status": 403,
                "message": "sorry. No suffiecent Tokens to send"
            }
            return resolve(response)
        }

        var tx = {
            "nonce": nonce,
            "to": process.env.TOKEN_CONTRACT,
            "gas": gasLimit,
            "data": encoded,

        }
        var signed = await web3.eth.accounts.signTransaction(tx, privateKey);
        var receipt = await web3.eth.sendSignedTransaction(signed.rawTransaction);
        if (receipt) {
            resolve(receipt)
        }
    });
}

module.exports.getTransactionDetail = async (tx_hash) => {
    return await new Promise(async (resolve, reject) => {
        await web3.eth.getTransaction(tx_hash)
            .then(transaction => {
                response = {
                    trnsaction_detail: transaction
                }
                resolve(response)
            }).catch(e => {
                reject(e)
            });
    });
};

module.exports.checkAddress = (address) => {
    return new Promise(async (resolve, reject) => {
        response = {
            response: web3.utils.isAddress(address)
        }
        resolve(response)
    });
};

async function getGas() {
    var gasLimit = await web3.eth.getBlock("latest", false)
    console.log("gas:", gasLimit.gasLimit)
    var gasLimit1 = web3.utils.toHex(gasLimit.gasLimit);
    console.log("gas:", gasLimit1)

    return gasLimit1
}