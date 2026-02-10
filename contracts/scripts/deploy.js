import hre from "hardhat";
import fs from "fs";
import path from "path";
import { fileURLToPath } from "url";

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

async function main() {
  console.log("🐕 GuardDog Deployment Starting...\n");
  
  const [deployer] = await hre.ethers.getSigners();
  console.log("Deploying contracts with account:", deployer.address);
  
  const balance = await hre.ethers.provider.getBalance(deployer.address);
  console.log("Account balance:", hre.ethers.formatEther(balance), "ETH\n");

  console.log("📋 Deploying ThreatRegistry...");
  const ThreatRegistry = await hre.ethers.getContractFactory("ThreatRegistry");
  const threatRegistry = await ThreatRegistry.deploy(deployer.address);
  await threatRegistry.waitForDeployment();
  const threatRegistryAddress = await threatRegistry.getAddress();
  console.log("✅ ThreatRegistry deployed to:", threatRegistryAddress);

  const deployTx1 = await threatRegistry.deploymentTransaction();
  const receipt1 = await deployTx1?.wait();

  console.log("\n🛡️  Deploying GuardianVault...");
  const GuardianVault = await hre.ethers.getContractFactory("GuardianVault");
  const guardianVault = await GuardianVault.deploy(deployer.address);
  await guardianVault.waitForDeployment();
  const guardianVaultAddress = await guardianVault.getAddress();
  console.log("✅ GuardianVault deployed to:", guardianVaultAddress);

  const deployTx2 = await guardianVault.deploymentTransaction();
  const receipt2 = await deployTx2?.wait();

  const totalGas = (receipt1?.gasUsed || 0n) + (receipt2?.gasUsed || 0n);

  console.log("\n" + "=".repeat(60));
  console.log("🎉 DEPLOYMENT COMPLETE!");
  console.log("=".repeat(60));
  
  console.log("\n📝 Contract Addresses:");
  console.log("─".repeat(60));
  console.log("ThreatRegistry:   ", threatRegistryAddress);
  console.log("GuardianVault:    ", guardianVaultAddress);
  console.log("─".repeat(60));
  
  console.log("\n🔗 Network Info:");
  const network = await hre.ethers.provider.getNetwork();
  console.log("Network:          ", network.name);
  console.log("Chain ID:         ", network.chainId.toString());
  console.log("Deployer:         ", deployer.address);
  console.log("Gas Used:         ", totalGas.toString());
  
  console.log("\n🔍 Verify on Block Explorer:");
  console.log("─".repeat(60));
  console.log(`npx hardhat verify --network ${network.name} ${threatRegistryAddress} ${deployer.address}`);
  console.log(`npx hardhat verify --network ${network.name} ${guardianVaultAddress} ${deployer.address}`);
  
  console.log("\n📋 Next Steps:");
  console.log("1. ✅ Verify contracts on block explorer (commands above)");
  console.log("2. 📝 Update frontend config/contracts.ts with deployed addresses");
  console.log("3. 📝 Update .env with contract addresses");
  console.log("4. 🤖 Build monitoring service");
  console.log("5. 🧪 Test protection flow");
  console.log("6. 🎨 Update README.md with deployed addresses\n");

  const deploymentInfo = {
    network: network.name,
    chainId: Number(network.chainId),
    deployer: deployer.address,
    timestamp: new Date().toISOString(),
    gasUsed: totalGas.toString(),
    contracts: {
      ThreatRegistry: threatRegistryAddress,
      GuardianVault: guardianVaultAddress,
    },
    verificationCommands: {
      ThreatRegistry: `npx hardhat verify --network ${network.name} ${threatRegistryAddress} ${deployer.address}`,
      GuardianVault: `npx hardhat verify --network ${network.name} ${guardianVaultAddress} ${deployer.address}`,
    },
  };

  const deploymentsDir = path.join(__dirname, "..", "deployments");
  if (!fs.existsSync(deploymentsDir)) {
    fs.mkdirSync(deploymentsDir);
  }

  const fileName = `deployment-${Date.now()}.json`;
  fs.writeFileSync(
    path.join(deploymentsDir, fileName),
    JSON.stringify(deploymentInfo, null, 2)
  );

  console.log(`💾 Deployment info saved to: deployments/${fileName}\n`);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });