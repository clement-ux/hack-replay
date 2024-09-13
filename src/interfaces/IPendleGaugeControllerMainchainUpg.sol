// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.25;

interface IPendleGaugeControllerMainchainUpg {
    error ArrayLengthMismatch();
    error GCNotPendleMarket(address caller);
    error GCNotVotingController(address caller);

    event AdminChanged(address previousAdmin, address newAdmin);
    event BeaconUpgraded(address indexed beacon);
    event Initialized(uint8 version);
    event MarketClaimReward(address indexed market, uint256 amount);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event ReceiveVotingResults(uint128 indexed wTime, address[] markets, uint256[] pendleAmounts);
    event UpdateMarketReward(address indexed market, uint256 pendlePerSec, uint256 incentiveEndsAt);
    event Upgraded(address indexed implementation);

    function claimOwnership() external;
    function epochRewardReceived(uint128) external view returns (bool);
    function fundPendle(uint256 amount) external;
    function initialize() external;
    function isValidMarket(address) external view returns (bool);
    function marketFactory() external view returns (address);
    function marketFactory2() external view returns (address);
    function marketFactory3() external view returns (address);
    function marketFactory4() external view returns (address);
    function owner() external view returns (address);
    function pendingOwner() external view returns (address);
    function pendle() external view returns (address);
    function proxiableUUID() external view returns (bytes32);
    function redeemMarketReward() external;
    function rewardData(address)
        external
        view
        returns (uint128 pendlePerSec, uint128 accumulatedPendle, uint128 lastUpdated, uint128 incentiveEndsAt);
    function transferOwnership(address newOwner, bool direct, bool renounce) external;
    function updateVotingResults(uint128 wTime, address[] memory markets, uint256[] memory pendleSpeeds) external;
    function upgradeTo(address newImplementation) external;
    function upgradeToAndCall(address newImplementation, bytes memory data) external payable;
    function votingController() external view returns (address);
    function withdrawPendle(uint256 amount) external;
}
