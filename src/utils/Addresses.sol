// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

library Mainnet {
    // Stablecoins USD
    address public constant DAI = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
    address public constant USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address public constant USDT = 0xdAC17F958D2ee523a2206206994597C13D831ec7;
    address public constant OUSD = 0x2A8e1E676Ec238d8A992307B495b45B3fEAa5e86;
    address public constant CRVFRAX = 0x3175Df0976dFA876431C2E9eE6Bc45b65d3473CC;

    // Wrapper Tokens
    address public constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address public constant WBTC = 0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599;
    address public constant WSTETH = 0x7f39C581F595B53c5cb19bD0b3f8dA6c935E2Ca0;

    // Governance
    address public constant CVG = 0x97efFB790f2fbB701D88f89DB4521348A2B77be8;
    address public constant PENDLE = 0x808507121B80c02388fAd14726482e061B8da827;

    // Swap
    address public constant LIFI_ROUTER = 0x1231DEB6f5749EF6cE6943a275A1D3E7486F4EaE;
    address public constant PENDLE_ROUTER = 0x888888888889758F76e7103c6CbF23ABbF58F946;
    address public constant UNISWAP_ROUTER = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    address public constant SUSHISWAP_ROUTER = 0xd9e1cE17f2641f24aE83637ab66a2cca9C378B9F;

    // --- Protocols ---

    // Pendle
    address public constant PENDLE_MARKET_FACTORY = 0x27b1dAcd74688aF24a64BD3C9C1B143118740784;
    address public constant PENDLE_MARKET_REGISTER_HELPER = 0xd20c245e1224fC2E8652a283a8f5cAE1D83b353a;
    address public constant PENDLE_GAUGE_CONTROLLER_MAINCHAIN_UPG = 0x47D74516B33eD5D70ddE7119A40839f6Fcc24e57;

    // Penpie
    address public constant PENPIE_MASTER = 0x16296859C15289731521F199F0a5f762dF6347d0;
    address public constant PENPIE_PENDLE_STAKING = 0x6E799758CEE75DAe3d84e09D40dc416eCf713652;
    address public constant PENPIE_PENDLE_MARKET_DEPOSITOR_HELPER = 0x1C1Fb35334290b5ff1bF7B4c09130885b10Fc0f4;
}
