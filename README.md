# GuardDog 🐕‍🦺

**AI-Powered Autonomous Wallet Security**

GuardDog is an AI security agent that monitors wallets and executes onchain protection when threats are detected. No manual intervention needed—your guardian dog bites back automatically.

## 🎯 Problem

Arbitrum Chain users lose millions to:
- Unlimited token approvals on compromised dApps
- Honeypot tokens that can't be sold
- Rug pulls draining liquidity overnight
- Malicious contract interactions

Existing tools only **alert**. GuardDog **acts**.

## ✨ Solution

Autonomous AI agent that:
1. **Monitors** - Scans wallets + connected dApps for threats
2. **Detects** - ML model identifies malicious patterns
3. **Executes** - Auto-revokes approvals, exits risky positions onchain
4. **Learns** - Improves from community-reported scams

## 🏗️ Architecture

```
User Wallet → GuardDog Agent → Threat Detection (AI) → Smart Contract Executor → Onchain Actions
```

**Core Components:**
- **AI Detection Engine**: Pattern recognition for scams, honeypots, rug pulls
- **Guardian Contract**: Autonomous execution logic on BSC
- **Agent Wallet**: Handles gas + autonomous transactions
- **Monitoring Service**: 24/7 wallet + dApp scanning

## 🔥 Key Features (v1)

### Auto-Revoke Unlimited Approvals
Automatically revokes dangerous token approvals when:
- dApp gets exploited/hacked
- Approval sits idle for >90 days
- Contract shows malicious patterns

### Honeypot Detection (Planned)
ML model analyzes before you buy:
- Transfer restrictions
- Hidden fees
- Sell lockups

### Rug Pull Predictor (Planned)
Monitors liquidity patterns:
- LP token burns
- Ownership concentration
- Suspicious withdrawals

## 🚀 Quick Start

### Prerequisites
- Node.js 18+
- Hardhat
- BNB Chain wallet with testnet BNB

### Installation

```bash
# Clone repository
git clone https://github.com/Ted1166/GuardDog.git
cd GuardDog

# Install dependencies
npm install

# Configure environment
cp .env.example .env
# Edit .env with your keys

# Compile contracts
npx hardhat compile

# Run tests
npx hardhat test

# Deploy to Arbitrum Testnet
npx hardhat run scripts/deploy.js --network arbitrumTestnet
```

### Usage

```bash
# Start monitoring service
npm run monitor

# Connect wallet for protection
npm run connect-wallet <YOUR_WALLET_ADDRESS>

# Check protection status
npm run status
```

## 📋 Smart Contracts

**GuardianVault.sol** - Main protection contract
- Auto-revoke approvals
- Emergency exits
- Agent execution logic

**ThreatRegistry.sol** - Threat database
- Community-reported scams
- AI-flagged contracts
- Risk scoring

Deployed on BSC Testnet: `[CONTRACT_ADDRESS]`

## 🧪 Testing & Reproduction

### Run Demo
```bash
npm run demo
```

Simulates:
1. User approves malicious token
2. GuardDog detects threat
3. Auto-revokes approval
4. Funds protected

## 🤖 AI Components

**Detection Model:**
- Training data: 10k+ reported Arbitrum Chain scams
- Pattern recognition: Bytecode analysis, liquidity tracking
- Confidence scoring: 0-100 threat level

**Technologies:**
- TensorFlow.js for onchain pattern detection
- Historical exploit database
- Real-time mempool monitoring

**Why GuardDog Wins:**
- ✅ Truly autonomous - executes onchain without human approval
- ✅ Solves real pain - Arbitrum Chain scams happen daily
- ✅ AI + blockchain fusion - ML detection → smart contract execution
- ✅ Immediate value - protection starts on connection

## 📄 License

MIT License - see LICENSE file

## 🤝 Contributing

Issues and PRs welcome! See CONTRIBUTING.md

## 📞 Contact

- Discord: tedadams
- Twitter: coming soon
- Email: ogolated00@gmail.com

---

**Built with 🤖 AI + ⛓️ Onchain Execution for Good Vibes Only: OpenClaw Edition**