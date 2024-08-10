// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

// OpenZeppelin
import {IERC20} from "@openzeppelin/token/ERC20/IERC20.sol";

// Local Interfaces
import {ICVG} from "src/interfaces/ICVG.sol";
import {IWETH} from "src/interfaces/IWETH.sol";
import {IUSDT} from "src/interfaces/IUSDT.sol";
import {IOUSD} from "src/interfaces/IOUSD.sol";
import {ILiFiDiamond} from "src/interfaces/ILiFiDiamond.sol";
import {IUniswapV2Router} from "src/interfaces/IUniswapV2Router.sol";

// Local Libraries
import {Mainnet} from "src/utils/Addresses.sol";

abstract contract Contracts {
    //////////////////////////////////////////////////////
    /// --- TOKENS
    //////////////////////////////////////////////////////
    ICVG public constant CVG = ICVG(Mainnet.CVG);
    IWETH public constant WETH = IWETH(payable(Mainnet.WETH));
    IOUSD public constant OUSD = IOUSD(Mainnet.OUSD);
    IUSDT public constant USDT = IUSDT(Mainnet.USDT);
    IERC20 public constant DAI = IERC20(Mainnet.DAI);
    IERC20 public constant USDC = IERC20(Mainnet.USDC);
    IERC20 public constant CRVFRAX = IERC20(Mainnet.CRVFRAX);

    //////////////////////////////////////////////////////
    /// --- ROUTERS
    //////////////////////////////////////////////////////
    ILiFiDiamond public constant LIFI_ROUTER = ILiFiDiamond(payable(Mainnet.LIFI_ROUTER));
    IUniswapV2Router public constant UNISWAP_ROUTER = IUniswapV2Router(payable(Mainnet.UNISWAP_ROUTER));
    IUniswapV2Router public constant SUSHISWAP_ROUTER = IUniswapV2Router(payable(Mainnet.SUSHISWAP_ROUTER));
}
