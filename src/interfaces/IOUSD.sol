// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

// OpenZeppelin
import {IERC20} from "@openzeppelin/token/ERC20/IERC20.sol";

interface IOUSD is IERC20 {
    function rebaseOptIn() external;
}
