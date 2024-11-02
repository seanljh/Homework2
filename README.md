# House NFT DApp
## Introduction
This is a basic housing NFT marketplace DApp built on the ethereum blockchain. 

### Functionality
The application allows users to:
1. View house NFTs they own
2. List NFTs of their choosing to the market
3. Buy NFTs from other users on the market

### Key Components
For this project, these components were used to build up the DApp:
1. Ganache - local ethereum blockchain
2. Hardhat - ethereum development environment
3. Web3 - ethereum SDK
4. Vue - javascript framework

## How to run the project:
### Set Up
1. Download files and head into both frontend and backend folders and do `npm install`
2. Set up local Ganache server

**Backend**
1. In backend/hardhat.config.js, input Ganache server RPC URL and a private key for the deployer account
2. Run `npx hardhat compile`
3. Run `npx hardhat ignition deploy ignition/modules/HouseNFT.js --network ganache`
4. Take note of deployed address in the terminal

**Frontend**
1. Head to frontend/src/App.vue and replace the value of `const contractAddress` in the `getAccount()` function with the depolyed address
2. Run `npm run dev`


## Screenshots

**Menu Bar**

This menu bar serves to show users their accounts they have connected, how many house NFTs they own and the menu for navigation.

<img width="406" alt="image" src="https://github.com/user-attachments/assets/419c15c9-4673-4673-a809-2c0ee3a46255">

**My Houses View**

This view is where users can view their owned houses and do certain actions with the NFTs.
1. Users can click on "View Details" to see more details about their token
2. Users can click on "List on market" to list their tokens onto the market to allow other users to purchase them
3. If the tokens are listed, users can choose to unlist their tokens and also choose to edit their listed prices

<img width="935" alt="image" src="https://github.com/user-attachments/assets/d3e87537-bc42-4ab5-ae60-ff68179de19d">

**Market View**

This view is where users can view other users' listed houses and purchase them.
1. Users can click on "View Details" to see more details about the token being sold
2. Users can click on "Buy House" to purchase the token

<img width="934" alt="image" src="https://github.com/user-attachments/assets/03cf505f-e38f-4fff-a0d6-dd0e43756dbf">



