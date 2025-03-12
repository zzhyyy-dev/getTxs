#!/bin/bash

#API KEY
source .env
RPC_KEY = $RPC_KEY


# Check if required parameters are provided
if [ "$#" -ne 1 ]; then
  echo "Usage: $0 <wallet_address>"
  exit 1
fi

WALLET="$1"

# Create directory for wallet
mkdir -p "$WALLET"

# Function to fetch and process transactions
download_transactions() {
  local ADDRESS_TYPE="$1"
  local FILE_NAME
  
  if [[ "$ADDRESS_TYPE" == "fromAddress" ]]; then
    FILE_NAME="withdraw_${WALLET}.csv"
  else
    FILE_NAME="deposit_${WALLET}.csv"
  fi
  
  # API request
  curl https://polygon-mainnet.g.alchemy.com/v2/$RPC_KEY \
    -X POST \
    -H "Content-Type: application/json" \
    -d @- << EOF > "$WALLET/out_${ADDRESS_TYPE}.json"
  {
    "jsonrpc": "2.0",
    "id": 1,
    "method": "alchemy_getAssetTransfers",
    "params": [
      {
        "fromBlock": "0x0",
        "toBlock": "latest",
        "contractAddresses": ["0xc2132D05D31c914a87C6611C10748AEb04B58e8F"],
        "category": ["erc20", "erc721", "erc1155"],
        "withMetadata": true,
        "excludeZeroValue": false,
        "maxCount": "0x3e8",
        "${ADDRESS_TYPE}": "${WALLET}"
      }
    ]
  }
EOF

  # Extract CSV from JSON result
  jq -r '.result.transfers[] | [.hash, .blockNum, .from, .to, .value, .asset, .metadata.blockTimestamp] | @csv' \
    "$WALLET/out_${ADDRESS_TYPE}.json" > "$WALLET/txout_${ADDRESS_TYPE}.csv"

  # Add headers and filter CSV rows based on value > 5
  echo "hash,blockNum,from,to,value,cur,blockTimestamp" > "$WALLET/${FILE_NAME}"
  awk -F',' 'NF==7 && $5+0 > 5' "$WALLET/txout_${ADDRESS_TYPE}.csv" >> "$WALLET/${FILE_NAME}"

  # Cleanup intermediate files
  rm "$WALLET/out_${ADDRESS_TYPE}.json" "$WALLET/txout_${ADDRESS_TYPE}.csv"
  
  echo "Filtered CSV file created: $WALLET/${FILE_NAME}"
}

# Fetch transactions for both fromAddress and toAddress
download_transactions "fromAddress"
download_transactions "toAddress"
