<script setup>
import { ref, onMounted, watch } from 'vue';
import { globalState } from '@/stores/stores';
import Card from 'primevue/card';
import Button from 'primevue/button';
import Dialog from 'primevue/dialog';
import InputNumber from 'primevue/inputnumber';

//For token URI
const tokenMetadata = ref({});

//For listing, unlisting & editing token price
//Dialog visibility
const isListDialogVisible = ref(false); 
const isEditDialogVisible = ref(false); 
const isUnlistDialogVisible = ref(false); 
const isDetailsDialogVisible = ref(false);

//Dialog vars
const listPrice = ref(0);
const newPrice = ref(0); 
const selectedTokenId = ref(null);
const selectedHouseDetails = ref({});

//Open dialogs
const openDetailsDialog = (tokenId) => {
  selectedTokenId.value = tokenId;
  selectedHouseDetails.value = tokenMetadata.value[tokenId]; 
  isDetailsDialogVisible.value = true;
};

const openListDialog = (tokenId) => {
  selectedTokenId.value = tokenId;
  isListDialogVisible.value = true;
};

const openEditDialog = (tokenId) => {
  selectedTokenId.value = tokenId;
  newPrice.value = BigInt(globalState.listedTokens[tokenId]) / BigInt(10 ** 18);
  isEditDialogVisible.value = true;
};

const openUnlistDialog = (tokenId) => {
  selectedTokenId.value = tokenId;
  isUnlistDialogVisible.value = true;
};

//Functions
async function submitListing() {
  try {
    const price = listPrice.value * 10 ** 18;
    const listTiming = Date.now();
    await globalState.contract.methods.listToken(selectedTokenId.value, price, listTiming).send({ from: globalState.account });

    globalState.listedTokens[selectedTokenId.value] = price;
    globalState.listingTimings[selectedTokenId.value] = listTiming;

    isListDialogVisible.value = false;
    selectedTokenId.value = null;
    listPrice.value = 0; 
    
  } catch (error) {
    console.error(error);
  }
}

async function submitUpdatedPrice() {
  try {
    const price = newPrice.value * 10 ** 18;

    await globalState.contract.methods.updateTokenPrice(selectedTokenId.value, price).send({ from: globalState.account });

    globalState.listedTokens[selectedTokenId.value] = price;

    isEditDialogVisible.value = false;
    selectedTokenId.value = null;
    newPrice.value = 0;
  } catch (error) {
    console.error(error);
  }
}

async function submitUnlist() {
  try {
    await globalState.contract.methods.unlistToken(selectedTokenId.value).send({ from: globalState.account });

    delete globalState.listedTokens[selectedTokenId.value];
    delete globalState.listingTimings[selectedTokenId.value];

    isUnlistDialogVisible.value = false;
    selectedTokenId.value = null;
  } catch (error) {
    console.error(error);
  }
}

async function getTokenInfo(tokenId) {
  const uri = globalState.tokensInfo[tokenId][1];
  const response = await fetch(uri);
  const metadata = await response.json();
  return metadata;
}

async function fetchAllTokensInfo() {
  for (const tokenId of globalState.ownedTokensIds) {
    const metadata = await getTokenInfo(tokenId);
    tokenMetadata.value[tokenId] = metadata;
  }
}

onMounted(async () => {
  if (globalState.account && globalState.ownedTokensIds.length > 0) {
    await fetchAllTokensInfo();
  }
});

watch(() => globalState.tokensInfo, 
  async (newValue, oldValue) => {
    if (globalState.account && globalState.ownedTokensIds.length > 0) {
      await fetchAllTokensInfo();
    }
  },
  { deep: true }
);
</script>

<template>
  <div>
    <div v-if="!globalState.account">
      Please connect your wallet to load your NFTs.
    </div>
    
    <div id="nft-container" v-if="globalState.ownedTokensIds.length > 0">
      <div
        v-for="tokenId in globalState.ownedTokensIds"
        :key="tokenId"
        class="nft-card"
        style="margin-bottom: 20px;"
      >
        <Card style="width: 100%; overflow: hidden">
          <template #header>
            <img
              :src="tokenMetadata[tokenId]?.image || 'http://localhost:5173/Images/BlackBackground.jpeg'"
              alt="House Image"
              style="width: 100%; height: 200px; object-fit:cover;"
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
            <p v-if="globalState.listedTokens[tokenId] > 0" style="margin-top: 1rem; font-weight: bold; color: blue ;">
              Price: {{ Number(globalState.listedTokens[tokenId]) / (10**18)}} ETH
            </p>
          </template>
          <template #footer>
            <div style="display: flex; gap: 1rem; justify-content: space-between; margin-top: 1rem;">
              <div style="display: flex; gap: 0.5rem;">
                <Button 
                  label="View Details" 
                  @click="openDetailsDialog(tokenId)"
                />
                <Button 
                  v-if="globalState.listedTokens[tokenId] > 0" 
                  label="Edit Price" 
                  severity="warn"
                  @click="openEditDialog(tokenId)"
                />
              </div>
              <div style="display: flex; gap: 0.5rem;">
                <Button 
                  v-if="globalState.listedTokens[tokenId] > 0" 
                  label="Unlist" 
                  severity="danger"
                  @click="openUnlistDialog(tokenId)"
                />
                <Button 
                  v-if="globalState.listedTokens[tokenId] > 0" 
                  label="Listed" 
                  severity="secondary" 
                  :disabled="true"
                />
                <Button 
                  v-else 
                  label="List on market" 
                  @click="openListDialog(tokenId)"
                />
              </div>
            </div>
          </template>
        </Card>
      </div>
    </div>

    <!-- Dialog for listing price -->
    <Dialog header="Set Listing Price" v-model:visible="isListDialogVisible">
      <div>
        <p>Enter the listing price for the token.</p>
        <InputNumber v-model="listPrice" mode="currency" currency="ETH" />
      </div>
      <template #footer>
        <Button label="Cancel" class="p-button-secondary" @click="isListDialogVisible = false" />
        <Button label="Submit" @click="submitListing" />
      </template>
    </Dialog>

    <!-- Dialog for editing price -->
    <Dialog header="Edit Listing Price" v-model:visible="isEditDialogVisible">
      <div>
        <p>Enter the new listing price for the token.</p>
        <InputNumber v-model="newPrice" mode="currency" currency="ETH" />
      </div>
      <template #footer>
        <Button label="Cancel" class="p-button-secondary" @click="isEditDialogVisible = false" />
        <Button label="Submit" @click="submitUpdatedPrice" />
      </template>
    </Dialog>

    <!-- Dialog for unlisting confirmation -->
    <Dialog header="Confirm Unlist" v-model:visible="isUnlistDialogVisible">
      <div>
        <p>Are you sure you want to unlist this house from the market?</p>
      </div>
      <template #footer>
        <Button label="Cancel" class="p-button-secondary" @click="isUnlistDialogVisible = false" />
        <Button label="Unlist" class="p-button-danger" @click="submitUnlist" />
      </template>
    </Dialog>

        <!-- Dialog for viewing house details -->
    <Dialog header="House Details" v-model:visible="isDetailsDialogVisible" style="min-width: 400px">
      <div v-if="selectedHouseDetails">
        <img :src="selectedHouseDetails.image || 'https://via.placeholder.com/150'" alt="House Image" style="width: 100%; height: 400px; object-fit: cover;" />
        <p>Name: {{ selectedHouseDetails.name || 'No name available' }}</p>
        <p>Size: {{ selectedHouseDetails.size || 'No size available' }}</p>
        <p>Description: {{ selectedHouseDetails.description || 'No description available' }}</p>
        <p>Address: {{ selectedHouseDetails.address || 'No address available' }}</p>
        <p v-if="globalState.listedTokens[selectedTokenId] > 0" style="font-weight: bold;">
          Price: {{ Number(globalState.listedTokens[selectedTokenId]) / (10**18) }} ETH
        </p>
      </div>
      <template #footer>
        <Button label="Close" class="p-button-secondary" @click="isDetailsDialogVisible = false; selectedTokenId = null" />
      </template>
    </Dialog>
  </div>
</template>