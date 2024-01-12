# CHAINLINK GUIDELINE

## Message Passing (Send Arbitrary Data)
1. Deploy contract (Sender and Reciever)
  recheck router and link address in address-lists folder ref: https://docs.chain.link/ccip/supported-networks)
  run `npx hardhat run ./scripts/deploy/deployMessagePassing.ts --network [chain]`
2. call `allowlistSourceChain` function with chain selector for whitelist chain caller
3. call `allowlistSender` function with contract for whitelist address from source chain

## ProgrammableTokenTransfer (Transfer Token with Data)
1. Deploy contract (Sender and Reciever)
  recheck router and link address in address-lists folder ref: https://docs.chain.link/ccip/supported-networks)
  run `npx hardhat run ./scripts/deploy/deployProgrammableToken.ts --network [chain]`
2. call `allowlistedDestinationChains` function chain select for whitelist destination chain
3. call `allowlistSourceChain` and `allowlistSender` function for whitelist source chain contract

*** NOTE: if set `setSimRevert` to true for open failure case when processing for the simulations ***