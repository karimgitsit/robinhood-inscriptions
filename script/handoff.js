// Hand Inscribe contract ownership to a new owner address.
// Usage: node script/handoff.js <current-owner-key-file> <contract> <new-owner>
const { ethers } = require("ethers");
const fs = require("fs");

const RPC = process.env.RPC_URL || "https://rpc.mainnet.chain.robinhood.com";
const [keyFile, contractAddr, newOwner] = process.argv.slice(2);
if (!keyFile || !contractAddr || !newOwner) {
  console.error("usage: node script/handoff.js <current-owner-key-file> <contract> <new-owner>");
  process.exit(1);
}
const ABI = [
  "function owner() view returns (address)",
  "function setOwner(address)",
];

async function main() {
  const provider = new ethers.JsonRpcProvider(RPC);
  const wallet = new ethers.Wallet(fs.readFileSync(keyFile, "utf8").trim(), provider);
  const c = new ethers.Contract(ethers.getAddress(contractAddr), ABI, wallet);
  console.log("current owner:", await c.owner());
  const tx = await c.setOwner(ethers.getAddress(newOwner), { gasLimit: 200_000 });
  console.log("tx:", tx.hash);
  const rcpt = await tx.wait();
  console.log("status:", rcpt.status);
  console.log("new owner:", await c.owner());
}
main().catch(e => { console.error("ERR:", e.shortMessage || e.message); process.exit(1); });
