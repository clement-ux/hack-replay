// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.25;

interface IPendleStaking {
    error InvalidAddress();
    error InvalidFee();
    error InvalidFeeDestination();
    error LengthMismatch();
    error NoVePendleReward();
    error OnlyActivePool();
    error OnlyPoolHelper();
    error OnlyPoolRegisterHelper();
    error OnlyVoteManager();
    error PoolOccupied();
    error TimeGapTooMuch();
    error ZeroNotAllowed();

    event AddPendleFee(address _to, uint256 _value, bool _isMPENDLE, bool _isAddress);
    event BribeManagerEOAUpdated(address _oldBribeManagerEOA, address _bribeManagerEOA);
    event BribeManagerUpdated(address _oldBribeManager, address _bribeManager);
    event Initialized(uint8 version);
    event MPendleBurn(address indexed _mgpBlackHole, uint256 _burnAmount);
    event MgpBlackHoleSet(address indexed _mgpBlackHole, uint256 _mPendleBurnRatio);
    event NewMarketDeposit(
        address indexed _user,
        address indexed _market,
        uint256 _lpAmount,
        address indexed _receptToken,
        uint256 _receptAmount
    );
    event NewMarketWithdraw(
        address indexed _user,
        address indexed _market,
        uint256 _lpAmount,
        address indexed _receptToken,
        uint256 _receptAmount
    );
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event Paused(address account);
    event PendleLocked(uint256 _amount, uint256 _lockDays, uint256 _vePendleAccumulated);
    event PendleMarketRegisterHelperSet(address _pendleMarketRegisterHelper);
    event PoolAdded(address _market, address _rewarder, address _receiptToken);
    event PoolHelperUpdated(address _market);
    event PoolRemoved(uint256 _pid, address _lpToken);
    event RemovePendleFee(uint256 value, address to, bool _isMPENDLE, bool _isAddress);
    event RewardPaidTo(address _market, address _to, address _rewardToken, uint256 _feeAmount);
    event SetLockDays(uint256 _oldLockDays, uint256 _newLockDays);
    event SetMPendleConvertor(address _oldmPendleConvertor, address _newmPendleConvertor);
    event SetPendleFee(address _to, uint256 _value);
    event SmartPendleConvertUpdated(address _OldSmartPendleConvert, address _smartPendleConvert);
    event Unpaused(address account);
    event VePendleHarvested(
        uint256 _total,
        address[] _pool,
        uint256[] _totalAmounts,
        uint256 _protocolFee,
        uint256 _callerFee,
        uint256 _rest
    );
    event VoteManagerUpdated(address _oldVoteManager, address _voteManager);
    event VoteSet(
        address _voter,
        uint256 _vePendleHarvestCallerFee,
        uint256 _harvestCallerPendleFee,
        uint256 _voteProtocolFee,
        address _voteFeeCollector
    );

    receive() external payable;

    function ETHZapper() external view returns (address);
    function PENDLE() external view returns (address);
    function WETH() external view returns (address);
    function __PendleStakingBaseUpg_init(
        address _pendle,
        address _WETH,
        address _vePendle,
        address _distributorETH,
        address _pendleRouter,
        address _masterPenpie
    ) external;
    function __PendleStaking_init(
        address _pendle,
        address _WETH,
        address _vePendle,
        address _distributorETH,
        address _pendleRouter,
        address _masterPenpie
    ) external;
    function accumulatedVePendle() external view returns (uint256);
    function addPendleFee(uint256 _value, address _to, bool _isMPENDLE, bool _isAddress) external;
    function autoBribeFee() external view returns (uint256);
    function batchHarvestMarketRewards(address[] memory _markets, uint256 minEthToRecieve) external;
    function bootstrapVePendle(uint256[] memory chainId) external payable returns (uint256);
    function bribeManager() external view returns (address);
    function bribeManagerEOA() external view returns (address);
    function convertPendle(uint256 _amount, uint256[] memory chainId) external payable returns (uint256);
    function depositMarket(address _market, address _for, address _from, uint256 _amount) external;
    function distributorETH() external view returns (address);
    function feeCollector() external view returns (address);
    function getPoolLength() external view returns (uint256);
    function harvestCallerPendleFee() external view returns (uint256);
    function harvestMarketReward(address _market, address _caller, uint256 _minEthRecive) external;
    function harvestTimeGap() external view returns (uint256);
    function harvestVePendleReward(address[] memory _pools) external;
    function increaseLockTime(uint256 _unlockTime) external;
    function lockPeriod() external view returns (uint256);
    function mPendleBurnRatio() external view returns (uint256);
    function mPendleConvertor() external view returns (address);
    function mPendleOFT() external view returns (address);
    function marketDepositHelper() external view returns (address);
    function masterPenpie() external view returns (address);
    function mgpBlackHole() external view returns (address);
    function owner() external view returns (address);
    function pause() external;
    function paused() external view returns (bool);
    function pendleFeeInfos(uint256)
        external
        view
        returns (uint256 value, address to, bool isMPENDLE, bool isAddress, bool isActive);
    function pendleMarketRegisterHelper() external view returns (address);
    function pendleRouter() external view returns (address);
    function pendleVote() external view returns (address);
    function poolTokenList(uint256) external view returns (address);
    function pools(address)
        external
        view
        returns (
            address market,
            address rewarder,
            address helper,
            address receiptToken,
            uint256 lastHarvestTime,
            bool isActive
        );
    function protocolFee() external view returns (uint256);
    function registerPool(address _market, uint256 _allocPoints, string memory name, string memory symbol) external;
    function removePendleFee(uint256 _index) external;
    function renounceOwnership() external;
    function setAutoBribeFee(uint256 _autoBribeFee) external;
    function setBribeManager(address _bribeManager, address _bribeManagerEOA) external;
    function setETHZapper(address _ETHZapper) external;
    function setHarvestTimeGap(uint256 _period) external;
    function setLockDays(uint256 _newLockPeriod) external;
    function setMGPBlackHole(address _mgpBlackHole, uint256 _mPendleBurnRatio) external;
    function setMPendleConvertor(address _mPendleConvertor) external;
    function setMPendleOFT(address _setMPendleOFT) external;
    function setMarketDepositHelper(address _helper) external;
    function setPendleFee(uint256 _index, uint256 _value, address _to, bool _isMPENDLE, bool _isAddress, bool _isActive)
        external;
    function setPendleMarketRegisterHelper(address _pendleMarketRegisterHelper) external;
    function setSmartConvert(address _smartPendleConvert) external;
    function setVote(
        address _pendleVote,
        uint256 _vePendleHarvestCallerFee,
        uint256 _harvestCallerPendleFee,
        uint256 _protocolFee,
        address _feeCollector
    ) external;
    function setVoteManager(address _voteManager) external;
    function setmasterPenpie(address _masterPenpie) external;
    function smartPendleConvert() external view returns (address);
    function totalPendleFee() external view returns (uint256);
    function totalUnclaimedETH() external view returns (uint256);
    function transferOwnership(address newOwner) external;
    function unpause() external;
    function updateMarketRewards(address _market, uint256[] memory amounts) external;
    function updatePoolHelper(address _market, address _helper) external;
    function vePendle() external view returns (address);
    function vePendleHarvestCallerFee() external view returns (uint256);
    function vote(address[] memory _pools, uint64[] memory _weights) external;
    function voteManager() external view returns (address);
    function withdrawMarket(address _market, address _for, uint256 _amount) external;
}
