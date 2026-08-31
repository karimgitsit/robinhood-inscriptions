// Verify the Inscribe contract source on Blockscout (legacy form-encoded API).
// Usage: node script/verify_blockscout.js <contract> [feeEth]
const { ethers } = require("ethers");
const fs = require("fs");
const path = require("path");

const EXPLORER_API = process.env.EXPLORER_API || "https://robinhoodchain.blockscout.com/api";
const contractAddr = process.argv[2];
if (!contractAddr) {
  console.error("usage: node script/verify_blockscout.js <contract> [feeEth]");
  process.exit(1);
}
const feeWei = ethers.parseEther(process.argv[3] || "0.0002");
const source = fs.readFileSync(path.join(__dirname, "../src/Inscribe.sol"), "utf8");

async function main() {
  const body = new URLSearchParams({
    module: "contract",
    action: "verify",
    addressHash: ethers.getAddress(contractAddr),
    compilerVersion: "v0.8.26+commit.8a97fa7a",
    contractSourceCode: source,
    name: "Inscribe",
    evmVersion: "cancun",
    optimizationUsed: "1",
    runs: "200",
    constructorArguments: ethers.AbiCoder.defaultAbiCoder().encode(["uint256"], [feeWei]),
  }).toString();
  const res = await fetch(EXPLORER_API, {
    method: "POST",
    headers: { "Content-Type": "application/x-www-form-urlencoded" },
    body,
  });
  console.log("status:", res.status);
  console.log("body:", (await res.text()).slice(0, 400));
}
main().catch(e => { console.error("ERR:", e.message); process.exit(1); });
