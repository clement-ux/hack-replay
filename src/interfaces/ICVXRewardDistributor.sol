// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;

interface ICvxRewardDistributor {
    struct TokenAmount {
        address token;
        uint256 amount;
    }

    event Initialized(uint8 version);
    event OwnershipTransferStarted(address indexed previousOwner, address indexed newOwner);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    function CVG() external view returns (address);
    function CVX() external view returns (address);
    function acceptOwnership() external;
    function claimCvgCvxSimple(
        address receiver,
        uint256 totalCvgClaimable,
        TokenAmount[] memory totalCvxRewardsClaimable,
        uint256 minCvgCvxAmountOut,
        bool isConvert
    ) external;
    function claimMultipleStaking(
        address[] memory claimContracts,
        address _account,
        uint256 _minCvgCvxAmountOut,
        bool _isConvert,
        uint256 cvxRewardCount
    ) external;
    function cvgCVX() external view returns (address);
    function cvgControlTower() external view returns (address);
    function cvx1() external view returns (address);
    function initialize(address _cvx1, address _cvgCVX) external;
    function owner() external view returns (address);
    function pendingOwner() external view returns (address);
    function poolCvgCvxCvx1() external view returns (address);
    function renounceOwnership() external;
    function setPoolCvgCvxCvx1AndApprove(address _poolCvgCvxCvx1) external;
    function transferOwnership(address newOwner) external;
}
