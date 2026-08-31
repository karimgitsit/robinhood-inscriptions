// Write a text inscription via the Inscribe contract.
// Usage: node script/inscribe.js <key-file> <contract> "text to inscribe"
const { ethers } = require("ethers");
const fs = require("fs");

const RPC = process.env.RPC_URL || "https://rpc.mainnet.chain.robinhood.com";
const [keyFile, contractAddr, text] = process.argv.slice(2);
if (!keyFile || !contractAddr || !text) {
  console.error('usage: node script/inscribe.js <key-file> <contract> "text to inscribe"');
  process.exit(1);
}
const ABI = [
  "function fee() view returns (uint256)",
  "function inscribe(string) payable returns (uint256)",
  "function totalInscriptions() view returns (uint256)",
  "function contentOf(uint256) view returns (string)",
  "function ownerOf(uint256) view returns (address)",
];

async function main() {
  const provider = new ethers.JsonRpcProvider(RPC);
  const wallet = new ethers.Wallet(fs.readFileSync(keyFile, "utf8").trim(), provider);
  const c = new ethers.Contract(ethers.getAddress(contractAddr), ABI, wallet);
  const fee = await c.fee();
  console.log("fee:", ethers.formatEther(fee), "ETH");
  const uri = "data:text/plain;charset=utf-8," + encodeURIComponent(text);
  const tx = await c.inscribe(uri, { value: fee, gasLimit: 1_500_000 });
  console.log("tx:", tx.hash);
  const rcpt = await tx.wait();
  console.log("status:", rcpt.status, "gas:", rcpt.gasUsed.toString());
  const id = await c.totalInscriptions();
  console.log("inscription id:", id.toString());
  console.log("owner:", await c.ownerOf(id));
  console.log("content:", (await c.contentOf(id)).slice(0, 80));
}
main().catch(e => { console.error("ERR:", e.shortMessage || e.message); process.exit(1); });
