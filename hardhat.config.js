require('dotenv').config();
require('@nomicfoundation/hardhat-ethers');

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
};
