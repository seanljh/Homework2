const { buildModule } = require("@nomicfoundation/hardhat-ignition/modules");

module.exports = buildModule("HouseNFT", (m) => {
  const houseNFT = m.contract("HouseNFT");

  return { houseNFT };
});

