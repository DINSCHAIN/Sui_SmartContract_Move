#!/bin/bash

# Tesla Token Deployment Script for SUI Network

echo "🚀 Deploying Tesla Allo Stock Token (aTSLA) to SUI Network..."

# Check if SUI CLI is installed
if ! command -v sui &> /dev/null; then
    echo "❌ SUI CLI not found. Please install it first."
    exit 1
fi

# Check balance
echo "💰 Checking SUI balance..."
sui client balance

# Build the package
echo "🔨 Building Move package..."
sui move build

if [ $? -ne 0 ]; then
    echo "❌ Build failed!"
    exit 1
fi

# Run tests
echo "🧪 Running tests..."
sui move test

if [ $? -ne 0 ]; then
    echo "❌ Tests failed!"
    exit 1
fi

# Deploy to devnet
echo "📦 Deploying to SUI Devnet..."
DEPLOY_RESULT=$(sui client publish --gas-budget 100000000)

if [ $? -eq 0 ]; then
    echo "✅ Deployment successful!"
    echo "$DEPLOY_RESULT"
    
    # Extract package ID (you might need to adjust this based on output format)
    PACKAGE_ID=$(echo "$DEPLOY_RESULT" | grep -o 'PackageID: [^,]*' | cut -d' ' -f2)
    echo "📦 Package ID: $PACKAGE_ID"
    
    # Save deployment info
    echo "PACKAGE_ID=$PACKAGE_ID" > .env
    echo "NETWORK=devnet" >> .env
    echo "DEPLOYED_AT=$(date)" >> .env
    
    echo "🎉 Tesla Token (aTSLA) deployed successfully to SUI Devnet!"
else
    echo "❌ Deployment failed!"
    exit 1
fi