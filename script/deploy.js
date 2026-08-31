// Deploy the Inscribe contract to Robinhood Chain.
// Usage: node script/deploy.js <deployer-key-file> [feeEth]
const { ethers } = require("ethers");
const fs = require("fs");
const path = require("path");

const RPC = process.env.RPC_URL || "https://rpc.mainnet.chain.robinhood.com";
const keyFile = process.argv[2];
if (!keyFile) {
  console.error("usage: node script/deploy.js <deployer-key-file> [feeEth]");
  process.exit(1);
}
const KEY = fs.readFileSync(keyFile, "utf8").trim();
const FEE_WEI = ethers.parseEther(process.argv[3] || "0.0002");

async function main() {
  const provider = new ethers.JsonRpcProvider(RPC);
  const wallet = new ethers.Wallet(KEY, provider);
  const addr = await wallet.getAddress();
  console.log("deployer:", addr);
  console.log("ETH balance:", ethers.formatEther(await provider.getBalance(addr)));

  const artifact = JSON.parse(
    fs.readFileSync(path.join(__dirname, "../out/Inscribe.sol/Inscribe.json"), "utf8"));
  const factory = new ethers.ContractFactory(artifact.abi, artifact.bytecode.object, wallet);
  console.log("deploying with fee:", ethers.formatEther(FEE_WEI), "ETH");
  const contract = await factory.deploy(FEE_WEI, { gasLimit: 2_500_000 });
  const rcpt = await contract.deploymentTransaction().wait();
  console.log("DEPLOYED at:", await contract.getAddress());
  console.log("tx:", contract.deploymentTransaction().hash);
  console.log("gas used:", rcpt.gasUsed.toString());
}
main().catch(e => { console.error("DEPLOY ERROR:", e.shortMessage || e.message); process.exit(1); });
