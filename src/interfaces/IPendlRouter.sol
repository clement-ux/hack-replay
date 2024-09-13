// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.25;

library IPLimitOrderType {
    type OrderType is uint8;
}

interface ActionAddRemoveLiqV3 {
    type SwapType is uint8;

    struct ApproxParams {
        uint256 guessMin;
        uint256 guessMax;
        uint256 guessOffchain;
        uint256 maxIteration;
        uint256 eps;
    }

    struct FillOrderParams {
        Order order;
        bytes signature;
        uint256 makingAmount;
    }

    struct LimitOrderData {
        address limitRouter;
        uint256 epsSkipMarket;
        FillOrderParams[] normalFills;
        FillOrderParams[] flashFills;
        bytes optData;
    }

    struct Order {
        uint256 salt;
        uint256 expiry;
        uint256 nonce;
        IPLimitOrderType.OrderType orderType;
        address token;
        address YT;
        address maker;
        address receiver;
        uint256 makingAmount;
        uint256 lnImpliedRate;
        uint256 failSafeRate;
        bytes permit;
    }

    struct SwapData {
        SwapType swapType;
        address extRouter;
        bytes extCalldata;
        bool needScale;
    }

    struct TokenInput {
        address tokenIn;
        uint256 netTokenIn;
        address tokenMintSy;
        address pendleSwap;
        SwapData swapData;
    }

    struct TokenOutput {
        address tokenOut;
        uint256 minTokenOut;
        address tokenRedeemSy;
        address pendleSwap;
        SwapData swapData;
    }

    error MarketExchangeRateBelowOne(int256 exchangeRate);
    error MarketExpired();
    error MarketProportionMustNotEqualOne();
    error MarketProportionTooHigh(int256 proportion, int256 maxProportion);
    error MarketRateScalarBelowZero(int256 rateScalar);
    error MarketZeroAmountsInput();
    error MarketZeroAmountsOutput();
    error MarketZeroTotalPtOrTotalAsset(int256 totalPt, int256 totalAsset);

    event AddLiquidityDualSyAndPt(
        address indexed caller,
        address indexed market,
        address indexed receiver,
        uint256 netSyUsed,
        uint256 netPtUsed,
        uint256 netLpOut
    );
    event AddLiquidityDualTokenAndPt(
        address indexed caller,
        address indexed market,
        address indexed tokenIn,
        address receiver,
        uint256 netTokenUsed,
        uint256 netPtUsed,
        uint256 netLpOut,
        uint256 netSyInterm
    );
    event AddLiquiditySinglePt(
        address indexed caller, address indexed market, address indexed receiver, uint256 netPtIn, uint256 netLpOut
    );
    event AddLiquiditySingleSy(
        address indexed caller, address indexed market, address indexed receiver, uint256 netSyIn, uint256 netLpOut
    );
    event AddLiquiditySingleSyKeepYt(
        address indexed caller,
        address indexed market,
        address indexed receiver,
        uint256 netSyIn,
        uint256 netSyMintPy,
        uint256 netLpOut,
        uint256 netYtOut
    );
    event AddLiquiditySingleToken(
        address indexed caller,
        address indexed market,
        address indexed token,
        address receiver,
        uint256 netTokenIn,
        uint256 netLpOut,
        uint256 netSyInterm
    );
    event AddLiquiditySingleTokenKeepYt(
        address indexed caller,
        address indexed market,
        address indexed token,
        address receiver,
        uint256 netTokenIn,
        uint256 netLpOut,
        uint256 netYtOut,
        uint256 netSyMintPy,
        uint256 netSyInterm
    );
    event RemoveLiquidityDualSyAndPt(
        address indexed caller,
        address indexed market,
        address indexed receiver,
        uint256 netLpToRemove,
        uint256 netPtOut,
        uint256 netSyOut
    );
    event RemoveLiquidityDualTokenAndPt(
        address indexed caller,
        address indexed market,
        address indexed tokenOut,
        address receiver,
        uint256 netLpToRemove,
        uint256 netPtOut,
        uint256 netTokenOut,
        uint256 netSyInterm
    );
    event RemoveLiquiditySinglePt(
        address indexed caller,
        address indexed market,
        address indexed receiver,
        uint256 netLpToRemove,
        uint256 netPtOut
    );
    event RemoveLiquiditySingleSy(
        address indexed caller,
        address indexed market,
        address indexed receiver,
        uint256 netLpToRemove,
        uint256 netSyOut
    );
    event RemoveLiquiditySingleToken(
        address indexed caller,
        address indexed market,
        address indexed token,
        address receiver,
        uint256 netLpToRemove,
        uint256 netTokenOut,
        uint256 netSyInterm
    );

    function addLiquidityDualSyAndPt(
        address receiver,
        address market,
        uint256 netSyDesired,
        uint256 netPtDesired,
        uint256 minLpOut
    ) external returns (uint256 netLpOut, uint256 netSyUsed, uint256 netPtUsed);
    function addLiquidityDualTokenAndPt(
        address receiver,
        address market,
        TokenInput memory input,
        uint256 netPtDesired,
        uint256 minLpOut
    ) external payable returns (uint256 netLpOut, uint256 netPtUsed, uint256 netSyInterm);
    function addLiquiditySinglePt(
        address receiver,
        address market,
        uint256 netPtIn,
        uint256 minLpOut,
        ApproxParams memory guessPtSwapToSy,
        LimitOrderData memory limit
    ) external returns (uint256 netLpOut, uint256 netSyFee);
    function addLiquiditySingleSy(
        address receiver,
        address market,
        uint256 netSyIn,
        uint256 minLpOut,
        ApproxParams memory guessPtReceivedFromSy,
        LimitOrderData memory limit
    ) external returns (uint256 netLpOut, uint256 netSyFee);
    function addLiquiditySingleSyKeepYt(
        address receiver,
        address market,
        uint256 netSyIn,
        uint256 minLpOut,
        uint256 minYtOut
    ) external returns (uint256 netLpOut, uint256 netYtOut, uint256 netSyMintPy);
    function addLiquiditySingleToken(
        address receiver,
        address market,
        uint256 minLpOut,
        ApproxParams memory guessPtReceivedFromSy,
        TokenInput memory input,
        LimitOrderData memory limit
    ) external payable returns (uint256 netLpOut, uint256 netSyFee, uint256 netSyInterm);
    function addLiquiditySingleTokenKeepYt(
        address receiver,
        address market,
        uint256 minLpOut,
        uint256 minYtOut,
        TokenInput memory input
    ) external payable returns (uint256 netLpOut, uint256 netYtOut, uint256 netSyMintPy, uint256 netSyInterm);
    function removeLiquidityDualSyAndPt(
        address receiver,
        address market,
        uint256 netLpToRemove,
        uint256 minSyOut,
        uint256 minPtOut
    ) external returns (uint256 netSyOut, uint256 netPtOut);
    function removeLiquidityDualTokenAndPt(
        address receiver,
        address market,
        uint256 netLpToRemove,
        TokenOutput memory output,
        uint256 minPtOut
    ) external returns (uint256 netTokenOut, uint256 netPtOut, uint256 netSyInterm);
    function removeLiquiditySinglePt(
        address receiver,
        address market,
        uint256 netLpToRemove,
        uint256 minPtOut,
        ApproxParams memory guessPtReceivedFromSy,
        LimitOrderData memory limit
    ) external returns (uint256 netPtOut, uint256 netSyFee);
    function removeLiquiditySingleSy(
        address receiver,
        address market,
        uint256 netLpToRemove,
        uint256 minSyOut,
        LimitOrderData memory limit
    ) external returns (uint256 netSyOut, uint256 netSyFee);
    function removeLiquiditySingleToken(
        address receiver,
        address market,
        uint256 netLpToRemove,
        TokenOutput memory output,
        LimitOrderData memory limit
    ) external returns (uint256 netTokenOut, uint256 netSyFee, uint256 netSyInterm);
}
