// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.25;

interface IMasterPenpie {
    error InvalidStakingToken();
    error LengthMismatch();
    error MustBeContract();
    error MustBeContractOrZero();
    error OnlyActivePool();
    error OnlyCompounder();
    error OnlyMPendleSV();
    error OnlyPoolManager();
    error OnlyReceiptToken();
    error OnlyStakingToken();
    error OnlyVlPenpie();
    error OnlyWhiteListedAllocaUpdator();
    error PenpieOFTSetAlready();
    error PoolExisted();
    error UnlockAmountExceedsLocked();
    error WithdrawAmountExceedsStaked();
    error onlyARBRewarder();

    event ARBRewarderSet(address _oldARBRewarder, address _newARBRewarder);
    event ARBRewarderSetAsQueuer(address rewarder);
    event Add(
        uint256 _allocPoint, address indexed _stakingToken, address indexed _receiptToken, address indexed _rewarder
    );
    event CompounderUpdated(address _newCompounder, address _oldCompounder);
    event Deposit(address indexed _user, address indexed _stakingToken, address indexed _receiptToken, uint256 _amount);
    event DepositNotAvailable(address indexed _user, address indexed _stakingToken, uint256 _amount);
    event HarvestPenpie(address indexed _account, address indexed _receiver, uint256 _amount, bool isLock);
    event Initialized(uint8 version);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event Paused(address account);
    event PenpieOFTSet(address _penpie);
    event PoolManagerStatus(address _account, bool _status);
    event Set(address indexed _stakingToken, uint256 _allocPoint, address indexed _rewarder);
    event Unpaused(address account);
    event UpdateEmissionRate(address indexed _user, uint256 _oldPenpiePerSec, uint256 _newPenpiePerSec);
    event UpdatePool(
        address indexed _stakingToken, uint256 _lastRewardTimestamp, uint256 _lpSupply, uint256 _accPenpiePerShare
    );
    event UpdatePoolAlloc(address _stakingToken, uint256 _oldAllocPoint, uint256 _newAllocPoint);
    event VlPenpieUpdated(address _newvlPenpie, address _oldvlPenpie);
    event Withdraw(
        address indexed _user, address indexed _stakingToken, address indexed _receiptToken, uint256 _amount
    );
    event mPendleSVUpdated(address _newMPendleSV, address _oldMPendleSV);

    function ARBRewarder() external view returns (address);
    function AllocationManagers(address) external view returns (bool);
    function PoolManagers(address) external view returns (bool);
    function __MasterPenpie_init(address _penpieOFT, uint256 _penpiePerSec, uint256 _startTimestamp) external;
    function add(uint256 _allocPoint, address _stakingToken, address _receiptToken, address _rewarder) external;
    function afterReceiptTokenTransfer(address _from, address _to, uint256 _amount) external;
    function allPendingTokens(address _stakingToken, address _user)
        external
        view
        returns (
            uint256 pendingPenpie,
            address[] memory bonusTokenAddresses,
            string[] memory bonusTokenSymbols,
            uint256[] memory pendingBonusRewards
        );
    function beforeReceiptTokenTransfer(address _from, address _to, uint256 _amount) external;
    function compounder() external view returns (address);
    function createNoReceiptPool(uint256 _allocPoint, address _stakingToken, address _rewarder) external;
    function createPool(
        uint256 _allocPoint,
        address _stakingToken,
        string memory _receiptName,
        string memory _receiptSymbol
    ) external;
    function createRewarder(address _receiptToken, address mainRewardToken) external returns (address);
    function deposit(address _stakingToken, uint256 _amount) external;
    function depositFor(address _stakingToken, address _for, uint256 _amount) external;
    function depositMPendleSVFor(uint256 _amount, address _for) external;
    function depositVlPenpieFor(uint256 _amount, address _for) external;
    function getPoolInfo(address _stakingToken)
        external
        view
        returns (uint256 emission, uint256 allocpoint, uint256 sizeOfPool, uint256 totalPoint);
    function getRewarder(address stakingToken) external view returns (address);
    function mPendleSV() external view returns (address);
    function massUpdatePools() external;
    function multiclaim(address[] memory _stakingTokens) external;
    function multiclaimFor(address[] memory _stakingTokens, address[][] memory _rewardTokens, address _account)
        external;
    function multiclaimOnBehalf(
        address[] memory _stakingTokens,
        address[][] memory _rewardTokens,
        address _account,
        bool _isClaimPNP
    ) external;
    function multiclaimSpec(address[] memory _stakingTokens, address[][] memory _rewardTokens) external;
    function multiclaimSpecPNP(address[] memory _stakingTokens, address[][] memory _rewardTokens, bool _withPNP)
        external;
    function owner() external view returns (address);
    function pause() external;
    function paused() external view returns (bool);
    function pendingTokens(address _stakingToken, address _user, address _rewardToken)
        external
        view
        returns (
            uint256 pendingPenpie,
            address bonusTokenAddress,
            string memory bonusTokenSymbol,
            uint256 pendingBonusToken
        );
    function penpieOFT() external view returns (address);
    function penpiePerSec() external view returns (uint256);
    function poolLength() external view returns (uint256);
    function receiptToStakeToken(address) external view returns (address);
    function registeredToken(uint256) external view returns (address);
    function renounceOwnership() external;
    function set(address _stakingToken, uint256 _allocPoint, address _rewarder) external;
    function setARBRewarder(address _ARBRewarder) external;
    function setARBRewarderAsQueuer(address[] memory _pools) external;
    function setCompounder(address _compounder) external;
    function setMPendleSV(address _mPendleSV) external;
    function setPenpie(address _penpieOFT) external;
    function setPoolManagerStatus(address _account, bool _allowedManager) external;
    function setVlPenpie(address _vlPenpie) external;
    function stakingInfo(address _stakingToken, address _user)
        external
        view
        returns (uint256 stakedAmount, uint256 availableAmount);
    function startTimestamp() external view returns (uint256);
    function tokenToPoolInfo(address)
        external
        view
        returns (
            address stakingToken,
            address receiptToken,
            uint256 allocPoint,
            uint256 lastRewardTimestamp,
            uint256 accPenpiePerShare,
            uint256 totalStaked,
            address rewarder,
            bool isActive
        );
    function totalAllocPoint() external view returns (uint256);
    function transferOwnership(address newOwner) external;
    function unpause() external;
    function updateEmissionRate(uint256 _penpiePerSec) external;
    function updatePool(address _stakingToken) external;
    function updatePoolsAlloc(address[] memory _stakingTokens, uint256[] memory _allocPoints) external;
    function updateRewarderQueuer(address _rewarder, address _manager, bool _allowed) external;
    function updateWhitelistedAllocManager(address _account, bool _allowed) external;
    function userInfo(address, address)
        external
        view
        returns (uint256 amount, uint256 rewardDebt, uint256 available, uint256 unClaimedPenpie);
    function vlPenpie() external view returns (address);
    function withdraw(address _stakingToken, uint256 _amount) external;
    function withdrawMPendleSVFor(uint256 _amount, address _for) external;
    function withdrawVlPenpieFor(uint256 _amount, address _for) external;
}
