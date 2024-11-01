require("@nomicfoundation/hardhat-toolbox");

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  solidity: "0.8.27",
  networks: {
    ganache: {
      url: "HTTP://127.0.0.1:7545",  // Ganache RPC URL
      accounts: [ "0x992eb0023bfab52b1186ea550c4d3d63b26a1491dc166a5bcc3ac6b86128c53b"] // Use private keys from your Ganache accounts
    },
  },
};