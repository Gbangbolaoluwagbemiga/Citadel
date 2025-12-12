require('dotenv').config();
require('@nomicfoundation/hardhat-ethers');
require('@nomiclabs/hardhat-etherscan');

module.exports = {
  solidity: '0.8.20',
  networks: {
    alfajores: {
      url: process.env.ALFAJORES_RPC_URL || 'https://alfajores-forno.celo-testnet.org',
      accounts: process.env.PRIVATE_KEY ? [process.env.PRIVATE_KEY] : []
    },
    celo: {
      url: process.env.CELO_MAINNET_RPC_URL || 'https://forno.celo.org',
      accounts: process.env.PRIVATE_KEY ? [process.env.PRIVATE_KEY] : [],
      chainId: 42220
    }
  }
  ,etherscan: {
    apiKey: {
      celo: process.env.CELOSCAN_API_KEY || '',
      alfajores: process.env.CELOSCAN_API_KEY || ''
    },
    customChains: [
      {
        network: 'celo',
        chainId: 42220,
        urls: {
          apiURL: 'https://celoscan.io/api',
          browserURL: 'https://celoscan.io'
        }
      },
      {
        network: 'alfajores',
        chainId: 44787,
        urls: {
          apiURL: 'https://alfajores.celoscan.io/api',
          browserURL: 'https://alfajores.celoscan.io'
        }
      }
    ]
  }
};
