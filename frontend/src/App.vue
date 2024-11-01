<script setup>
  import { RouterLink, RouterView } from 'vue-router';
  import { ref, watch } from "vue";
  import Web3 from "web3";
  import abi from "./contractJson/HouseNFT.json";
  import { useRouter } from 'vue-router';
  import { globalState } from './stores/stores';

  const router = useRouter();
  const walletConnected = ref(false);
  const tokensBalance = ref(null);

  async function getAccount() {
    if (window.ethereum) {
      try {
        const accounts = await window.ethereum.request({
          method: "eth_requestAccounts",
        });

        globalState.account = accounts[0];
        walletConnected.value = true;

        const web3 = new Web3(window.ethereum);
        const contractAddress = "0xB3C075B0221874aFe15E2Ef6D51993014C324938";
        const contractABI = abi.abi;

        globalState.contract = new web3.eth.Contract(contractABI, contractAddress);

        await getTokenBalance();
        await getOwnedTokensForUser();
        await populateTokensInfo();
        await fetchListedTokens();

      } catch (error) {
          console.error(error);
      }
    } else {
      console.log("MetaMask Not Detected");
    }
  }

  async function getTokenBalance() {
    if (globalState.contract && globalState.account) {
      try {
        const balance = await globalState.contract.methods.balanceOf(globalState.account).call();
        tokensBalance.value = balance;

      } catch (error) {
        console.error(error);
      }
    }
  }

  async function getOwnedTokensForUser() {
    try {
      globalState.ownedTokensIds = await globalState.contract.methods.getOwnedTokens(globalState.account).call();
      console.log("Owned Token IDs: ", globalState.ownedTokensIds);
    } catch (error) {
      console.error("Error fetching owned tokens: ", error);
    }
  }

  async function populateTokensInfo() {
    const totalMinted = await globalState.contract.methods.getTotalMinted().call();

    for (let tokenId = 0; tokenId < totalMinted; tokenId++) {
      try {
        const { owner, uri } = await globalState.contract.methods.getTokenDetails(tokenId).call();
        globalState.tokensInfo[tokenId] = [owner, uri];
      } catch (error) {
        console.error(`Error fetching token details for tokenId ${tokenId}: `, error);
      }
    }
    console.log("Tokens info successfully populated:", globalState.tokensInfo);
  }

  async function fetchListedTokens() {
    const totalMinted = await globalState.contract.methods.getTotalMinted().call(); // Assuming this function exists
    globalState.listedTokens = new Array(totalMinted).fill(null);
    globalState.listingTimings = new Array(totalMinted).fill(null);

    for (let tokenId = 0; tokenId < totalMinted; tokenId++) {
      try {
        const price = await globalState.contract.methods.marketListings(tokenId).call();

        if (price > 0) {
          globalState.listedTokens[tokenId] = price;
          const timing = await globalState.contract.methods.listingTimings(tokenId).call();
          globalState.listingTimings[tokenId] = timing;
        }
      } catch (error) {
        console.error(`Error fetching listing for tokenId ${tokenId}:`, error);
      }
    }

    console.log("Listed tokens updated:", globalState.listedTokens);
    console.log("Listed timings updated:", globalState.listingTimings);
  }

  watch(() => globalState.buyReload , async () => {
    await getTokenBalance();
    await getOwnedTokensForUser();
    await populateTokensInfo();
    await fetchListedTokens();
  }, { deep: true });
  </script>

<template>
  <div id="floatingApp">
    <!-- Left Section (Menu) -->
    <div id="leftMenu">
      
      <h1>MetaMask DApp</h1>

      <!-- Wallet connection -->
      <button v-if="!walletConnected" @click="getAccount()">Connect to MetaMask</button>
      <p v-if="walletConnected" style="margin-bottom: 1rem;">Account: {{ globalState.account }}</p>
      <p v-if="walletConnected">Owned Houses: {{ tokensBalance }}</p>

      <!-- Navigation Links -->
      <nav v-if="walletConnected">
        <RouterLink style="padding-right: 10px; border-right: 1px solid #e0e0e0" to="/" v-slot="{ isActive, href }">
          <a :href="href" :style="{ color: isActive ? '#000' : '#28a745', fontWeight: isActive ? 'bold' : 'normal', textDecoration: isActive ? 'none' : 'underline' }">
            Owned Houses
          </a>
        </RouterLink>
        
        <RouterLink to="/market" v-slot="{ isActive, href }">
          <a :href="href" :style="{ color: isActive ? '#000' : '#28a745', fontWeight: isActive ? 'bold' : 'normal', textDecoration: isActive ? 'none' : 'underline' }">
            Market
          </a>
        </RouterLink>
      </nav>
    </div>

    <!-- Right Section (Content / RouterView) -->
    <div id="rightContent">
      <RouterView />
    </div>
  </div>
</template>



<style scoped>
/* Floating container styles */
#floatingApp {
  position: fixed;
  top: 50%;
  left: 50%;
  transform: translate(-50%, -50%);
  display: flex;
  width: 90vw; /* Width of the floating app */
  height: 80vh; /* Height of the floating app */
  background-color: #f8f9fa;
  border-radius: 20px;
  box-shadow: 0 8px 16px rgba(0, 0, 0, 0.1);
  overflow: hidden;
}

/* Left menu styling */
#leftMenu {
  width: 30%; /* Menu takes 30% of the app's width */
  background-color: #fff;
  padding: 20px;
  display: flex;
  flex-direction: column;
  border-right: 1px solid #e0e0e0;
}

#leftMenu h1 {
  font-size: 1.5rem;
  margin-top: 1.5rem;
  margin-bottom: 1.5rem;
  font-weight: 480;
}

#leftMenu button {
  padding: 10px;
  font-size: 1rem;
  color: #fff;
  background-color: #f6851b;
  border: none;
  border-radius: 5px;
  cursor: pointer;
}

#leftMenu button:hover {
  background-color: #e2761b;
}

#leftMenu nav {
  display: flex;
  flex-direction: row;
  gap: 10px;
  margin-top: 100%;
  font-size: large;
}


/* Right content (RouterView) styling */
#rightContent {
  width: 70%; /* Content takes 70% of the app's width */
  padding: 20px;
  overflow-y: auto;
  background-color: #e9e9e9;
}
</style>