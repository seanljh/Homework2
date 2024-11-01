import { reactive } from 'vue';

export const globalState = reactive({
  account: null,
  ownedTokensIds: [],
  tokensInfo: [],
  listedTokens: [],
  contract: null,
  listingTimings: [],
  buyReload: 0
});