// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

interface IOUSDVault {
    function mint(address asset, uint256 amount) external;
    function redeem(uint256 amount) external;
    function mintMultiple(address[] calldata assets, uint256[] calldata amounts) external;
    function totalValue() external view returns (uint256);
}
