// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

// Foundry
import {Test} from "forge-std/Test.sol";

import {Contracts} from "src/utils/Contracts.sol";

// Local Libraries
import {Constants} from "src/utils/Constants.sol";

abstract contract Base_Test_ is Test, Contracts {
    //////////////////////////////////////////////////////
    /// --- CONSTANTS
    //////////////////////////////////////////////////////
    uint256 public constant MAX_UINT256 = Constants.MAX_UINT256;

    //////////////////////////////////////////////////////
    /// --- SETUP
    //////////////////////////////////////////////////////
    function setUp() public virtual {
        _label();
    }

    function _label() internal {
        // Tokens
        vm.label(address(DAI), "DAI");
        vm.label(address(CVG), "CVG");
        vm.label(address(OUSD), "OUSD");
        vm.label(address(USDT), "USDT");
        vm.label(address(USDC), "USDC");
        vm.label(address(WETH), "WETH");
        vm.label(address(CRVFRAX), "CRVFRAX");

        // Routers
        vm.label(address(UNISWAP_ROUTER), "UNISWAP_ROUTER");
        vm.label(address(SUSHISWAP_ROUTER), "SUSHISWAP_ROUTER");
    }
}
