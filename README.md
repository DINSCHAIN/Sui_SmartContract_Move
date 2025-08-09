Step 1: Install Prerequisites
# 1. Install Rust (if not already installed)
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
source ~/.cargo/env

# 2. Verify Rust installation
rustc --version
cargo --version

# 3. Install SUI CLI
cargo install --locked --git https://github.com/MystenLabs/sui.git --branch devnet sui

# 4. Verify SUI installation
sui --version

# 5. Install Node.js (if not already installed)
//Download from https://nodejs.org/ or use package manager:
//Ubuntu/Debian: sudo apt install nodejs npm
//macOS: brew install node
//Windows: Download from nodejs.org

# 6. Verify Node.js installation
node --version
npm --version# Sui_SmartContract_Move


FOR SUI Faucet USe this :

https://faucet.sui.io/?address=0xb4370b8f76c5b25f6383716429350aa3cb44853bf6b1c9991016e2c649ae5fb4


 sui move new tesla_token --path .


Deployment Steps
sui move build
sui move test

# Deploy when ready
sui client publish --gas-budget 100000000
 