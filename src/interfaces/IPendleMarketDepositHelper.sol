// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.25;

interface IPendleMarketDepositHelper {
    error DeactivatePool();
    error NullAddress();
    error OnlyOperator();

    event Initialized(uint8 version);
    event NewDeposit(address indexed _user, address indexed _market, uint256 _amount);
    event NewWithdraw(address indexed _user, address indexed _market, uint256 _amount);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event Paused(address account);
    event Unpaused(address account);

    function __PendleMarketDepositHelper_init(address _pendleStaking) external;
    function balance(address _market, address _address) external view returns (uint256);
    function depositMarket(address _market, uint256 _amount) external;
    function depositMarketFor(address _market, address _for, uint256 _amount) external;
    function harvest(address _market, uint256 _minEthToRecieve) external;
    function masterpenpie() external view returns (address);
    function owner() external view returns (address);
    function paused() external view returns (bool);
    function pendleStaking() external view returns (address);
    function poolInfo(address) external view returns (address rewarder, bool isActive);
    function renounceOwnership() external;
    function setOperator(address _address, bool _value) external;
    function setPoolInfo(address market, address rewarder, bool isActive) external;
    function setmasterPenpie(address _masterPenpie) external;
    function totalStaked(address _market) external view returns (uint256);
    function transferOwnership(address newOwner) external;
    function withdrawMarket(address _market, uint256 _amount) external;
    function withdrawMarketWithClaim(address _market, uint256 _amount, bool _doClaim) external;
}
