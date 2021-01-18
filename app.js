const express = require('express')
var bodyParser = require("body-parser");
var ETHRoutes = require("./web3/web3connection.js");
var BTCRoutes = require("./BTC/btcConnection.js");
const service = require('./service');
const app = express()

app.use(bodyParser.json());
app.use(bodyParser.urlencoded({ extended: true }));
const port = 3000
// app.use(express.json())
app.get('/generateAddress', async (req, res) => {
    await service.generateAddress().then((resolve, reject) => {
        if (resolve) {
            res.send(resolve)
        } else {
            res.send(reject)
        }
    })
        .catch(e => {
            console.log(e)
        });
});

app.get('/getToken', async (req, res) => {
    // console.log(req.body.account)
    var acc = req.body.account
    console.log(acc)
    await service.getToken(acc).then((resolve, reject) => {
        if (resolve) {
            res.send(resolve)
        } else {
            res.send(reject)
        }
    })
})

app.get("/getBalance", async (req, res) => {
    var acc = req.body.account
    console.log(acc)
    await service.getBalance(acc).then((resolve, reject) => {
        if (resolve) {
            res.send(resolve)
        } else {
            res.send(reject)
        }
    })
})
app.post("/transfer", async (req, res) => {
    await service.transfer(req.body.sender, req.body.recipient, req.body.amount)
        .then((resolve, reject) => {
            if (resolve) {
                res.send(resolve)
            } else if (reject) {
                res.send(reject)
            }

        });
})

app.get("/transactionDetail", async (req, res) => {
    console.log(req.body.tx_hash)
    await service.getTransactionDetail(req.body.tx_hash)
        .then((resolve, reject) => {
            if (resolve) {
                res.send(resolve)
            } else {
                res.send(reject)
            }
        })
})

app.get("/checkAddress", async (req, res) => {
    await service.checkAddress(req.body.account)
        .then(response => {
            res.send(response)
        })
})
app.listen(port, () => console.log(`Example app listening on port ${port}!`))