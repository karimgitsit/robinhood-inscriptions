# Robinhood Inscriptions

Write text or images permanently on-chain on Robinhood Chain (chain id 4663) for a
small ETH fee. You own what you inscribe and can transfer it.

## Live
- **App:** https://robinhood-inscriptions.vercel.app (Vercel, NGMI Labs team)
- **Contract:** [`0xeCf73C5AE1946458cF23ea77bc0667a1fb54C32B`](https://robinhoodchain.blockscout.com/address/0xeCf73C5AE1946458cF23ea77bc0667a1fb54C32B)
  on Robinhood Chain (id 4663)

## Contract
- **File:** `src/Inscribe.sol` (Solidity 0.8.26, cancun, optimizer 200)
- Fee per inscription: **0.0002 ETH**, owner-settable via `setFee`
- Content stored on-chain (`contentOf`), max 64 KB
- Inscription ownership tracked on-chain (`ownerOf`, `balanceOf`), transfers supported
- Contract ownership transferable via `setOwner`; accumulated fees withdraw to the owner
- Emits ESIP-3-compatible `ethscriptions_protocol_CreateEthscription` event
- **Tests:** `test/Inscribe.t.sol` (Foundry)

## Web app
- **File:** `frontend/index.html` (single file, ethers v6 via CDN)
- Connect wallet (auto-adds the Robinhood network), inscribe text or images
  (auto-compressed under 60 KB), fee display, gallery of all inscriptions,
  per-item view, transfers

## Operate

```sh
npm install       # script dependencies (ethers)
forge build       # compile (requires Foundry)
forge test        # run the test suite

node script/deploy.js <deployer-key-file> [feeEth]              # deploy
node script/verify_blockscout.js <contract> [feeEth]            # verify source on Blockscout
node script/inscribe.js <key-file> <contract> "text"            # write an inscription
node script/handoff.js <owner-key-file> <contract> <new-owner>  # transfer contract ownership
```

The deployer key lives in a file outside the repo (never commit it). `RPC_URL`
overrides the default Robinhood Chain RPC. Behind an egress proxy (sandboxed
CI), run the scripts with `NODE_USE_ENV_PROXY=1` (Node 22.21+).
