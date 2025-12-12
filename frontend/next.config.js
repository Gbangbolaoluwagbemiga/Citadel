/** @type {import('next').NextConfig} */
const nextConfig = {
  transpilePackages: [
    '@reown/appkit',
    '@reown/appkit-wagmi',
    '@reown/appkit-adapter-wagmi'
  ],
  turbopack: {
    root: __dirname
  },
  webpack: (config) => {
    config.resolve.alias = {
      ...(config.resolve.alias || {}),
      'why-is-node-running': false,
      '@solana/kit': false,
      '@base-org/account': false,
      '@coinbase/cdp-sdk': false,
      'axios': false,
      '@gemini-wallet/core': false,
      '@metamask/sdk': false,
      'porto': false,
      '@walletconnect/ethereum-provider': false
    };
    return config;
  }
};

module.exports = nextConfig;
