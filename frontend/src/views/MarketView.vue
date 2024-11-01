<script setup>
import { ref, onMounted, watch } from 'vue';
import { globalState } from '@/stores/stores';
import Card from 'primevue/card';
import Button from 'primevue/button';
import Dialog from 'primevue/dialog';
import { useRouter, useRoute } from 'vue-router';

const router = useRouter();

const tokenMetadata = ref({});
const tokenOwner = ref({});
const listedHouseTokens = ref([]);
const comissionPercentage = 10;
const timeNow = ref(0);

const isDetailsDialogVisible = ref(false);
const selectedTokenId = ref(null);
const selectedHouseDetails = ref({});
const selectedHouseOwner = ref(null);
const isBuyDialogVisible = ref(false);

const openDetailsDialog = (tokenId) => {
  selectedTokenId.value = tokenId;
  selectedHouseDetails.value = tokenMetadata.value[tokenId];
  selectedHouseOwner.value = tokenOwner.value[tokenId]; // Initialize while fetching
  isDetailsDialogVisible.value = true;
  timeNow.value = Date.now();
};

const openBuyDialog = (tokenId) => {
  selectedTokenId.value = tokenId;
  isBuyDialogVisible.value = true;
  timeNow.value = Date.now();
};

async function getTokenInfo(tokenId) {
  const uri = globalState.tokensInfo[tokenId][1];
  const response = await fetch(uri);
  const metadata = await response.json();
  return metadata;
}

function getTokenOwner(tokenId) {
  const owner = globalState.tokensInfo[tokenId][0];
  return owner;
}


function loadMarketListings() {
  for (let index = 0; index < globalState.listedTokens.length; index++) {
    if (globalState.listedTokens[index] > 0 && !globalState.ownedTokensIds.includes(BigInt(index))) {
      listedHouseTokens.value.push(index);
    }
  }

  console.log("owned: ", globalState.ownedTokensIds);
  console.log("Houses on market: ", listedHouseTokens.value);
}

// Function to fetch metadata only for listed houses in the market
async function fetchAllTokensInfo() {
  for (const tokenId of listedHouseTokens.value) {
    const metadata = await getTokenInfo(tokenId);
    tokenMetadata.value[tokenId] = metadata;
    const owner = getTokenOwner(tokenId);
    tokenOwner.value[tokenId] = owner;
  }
  console.log("Owner:", tokenOwner.value);
}

async function buyToken() {
  try {
    const comission = ((Number(timeNow.value) - Number(globalState.listingTimings[selectedTokenId.value])) / (60 * 60 * 1000)) * 
      Number(comissionPercentage) * 
        (Number(globalState.listedTokens[selectedTokenId.value]));

    const total = Number(globalState.listedTokens[selectedTokenId.value]) + comission;

    await globalState.contract.methods.buyToken(selectedTokenId.value, comission).send({ from: globalState.account, value: total});
    isBuyDialogVisible.value = false;

    delete globalState.listedTokens[selectedTokenId.value];
    delete globalState.listingTimings[selectedTokenId.value];

    globalState.buyReload += 1;
    router.push('/');
  } catch (error) {
    console.log(error);
  }
}

// Initialize data on component mount
onMounted(async () => {
  if (globalState) {
    loadMarketListings(); // Load listed houses
    await fetchAllTokensInfo(); // Fetch metadata for those houses
  }

  console.log("Info", globalState.tokensInfo[0])
});


// Watch for changes in `globalState.tokensInfo` to reload listings and metadata if necessary
watch(() => globalState.listedTokens , async () => {
  if (globalState) {
    loadMarketListings();
    await fetchAllTokensInfo();
  }

  console.log("Info", globalState.tokensInfo[0]);
}, { deep: true });
</script>

<template>
  <div>
    <div v-if="!globalState.account">
      Please connect your wallet to load the market NFTs.
    </div>

    <div v-if="globalState.account && listedHouseTokens.length == 0" style="font-weight: bold;">
      No houses listed on the market currently.
    </div>
    
    <div id="nft-container" v-if="listedHouseTokens.length > 0">
      <div
        v-for="tokenId in listedHouseTokens"
        :key="tokenId"
        class="nft-card"
        style="margin-bottom: 20px;"
      >
        <Card style="width: 100%; overflow: hidden">
          <template #header>
            <img
              :src="tokenMetadata[tokenId]?.image || 'http://localhost:5173/Images/BlackBackground.jpeg'"
              alt="House Image"
              style="width: 100%; height: 200px; object-fit: cover;"
            />
          </template>
          <template #title>
            {{ tokenMetadata[tokenId]?.name || 'No title available' }}
          </template>
          
          <template #subtitle>
            {{ tokenMetadata[tokenId]?.address || 'No address available' }}
          </template>
          
          <template #content>
            <p class="m-0">
              {{ tokenMetadata[tokenId]?.description || 'No description available' }}
            </p>
            <p style="margin-top: 1rem; font-weight: bold; color: blue;">
              Price: {{ Number(globalState.listedTokens[tokenId]) / (10 ** 18) }} ETH
            </p>
          </template>
          <template #footer>
            <div style="display: flex; justify-content: space-between;">
              <Button 
                label="View Details" 
                @click="openDetailsDialog(tokenId)" 
              />
              <Button
                label="Buy House" 
                @click="openBuyDialog(tokenId)"
                severity="danger"
              />
            </div>
            
          </template>
        </Card>
      </div>
    </div>
    
    <Dialog header="House Details" v-model:visible="isDetailsDialogVisible" style="min-width: 400px">
      <div v-if="selectedHouseDetails">
        <img :src="selectedHouseDetails.image || 'http://localhost:5173/Images/BlackBackground.jpeg'" alt="House Image" style="width: 100%; height: 400px; object-fit: cover;" />
        <p>Owner: {{ selectedHouseOwner }}</p>
        <p>Name: {{ selectedHouseDetails.name || 'No name available' }}</p>
        <p>Size: {{ selectedHouseDetails.size || 'No size available' }}</p>
        <p>Description: {{ selectedHouseDetails.description || 'No description available' }}</p>
        <p>Address: {{ selectedHouseDetails.address || 'No address available' }}</p>
        <p v-if="globalState.listedTokens[selectedTokenId] > 0" style="font-weight: bold;">
          Price: {{ Number(globalState.listedTokens[selectedTokenId]) / (10 ** 18) }} ETH
        </p>
        <p style="color: blue;">
          Comission = (Hours Listed) * (Comission) * (House Price)
        </p>
        <p style="margin-left: 5rem; color: blue;">
          =
          {{ (Number(timeNow) - Number(globalState.listingTimings[selectedTokenId])) / (60 * 60 * 1000)}} *
          {{ Number(comissionPercentage) }} *
          {{ Number(globalState.listedTokens[selectedTokenId]) / (10 ** 18) }} ETH
        </p>
        <p style="margin-left: 5rem; color: blue; font-weight: bold;">
          =
          {{ (Number(timeNow) - Number(globalState.listingTimings[selectedTokenId])) / (60 * 60 * 1000) * Number(comissionPercentage) *  Number(globalState.listedTokens[selectedTokenId]) / (10 ** 18)}} ETH
        </p>
      </div>
      <template #footer>
        <Button label="Close" class="p-button-secondary" @click="isDetailsDialogVisible = false; selectedTokenId = null" />
      </template>
    </Dialog>
    
    <!-- Buy Dialog -->
    <Dialog header="Edit Listing Price" v-model:visible="isBuyDialogVisible">
      <div>
        <p>
          Confirm purchase of house NFT 
        </p>
        <p style="font-weight: bold; color: blue; text-decoration: underline;">
          @ {{ Number(globalState.listedTokens[selectedTokenId]) / (10 ** 18) }} ETH
        </p>
        <p style="font-weight: bold; color: blue; text-decoration: underline;">
          + {{ (Number(timeNow) - Number(globalState.listingTimings[selectedTokenId])) / (60 * 60 * 1000) * Number(comissionPercentage) *  Number(globalState.listedTokens[selectedTokenId]) / (10 ** 18) }} ETH
        </p>
      </div>
      <template #footer>
        <Button label="Cancel" class="p-button-secondary" @click="isBuyDialogVisible = false" />
        <Button label="Submit" @click="buyToken()" />
      </template>
    </Dialog>

  </div>
</template>



<style scoped>
.nft-card {
  padding: 10px;
  border: 1px solid #ddd;
  margin-bottom: 10px;
}
</style>