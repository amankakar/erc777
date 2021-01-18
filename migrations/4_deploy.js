const erc777 = artifacts.require("Bitcoinv1");
module.exports = function (deployer) {
    deployer.deploy(erc777, ["0xC6Fa46e016ff160166BcF7FB783649c282B268d7"]);
};
