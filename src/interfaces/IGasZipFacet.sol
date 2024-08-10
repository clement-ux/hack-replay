// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;

interface IGasZipFacet {
    struct BridgeData {
        bytes32 transactionId;
        string bridge;
        string integrator;
        address referrer;
        address sendingAssetId;
        address receiver;
        uint256 minAmount;
        uint256 destinationChainId;
        bool hasSourceSwaps;
        bool hasDestinationCall;
    }

    struct GasZipData {
        uint256 gasZipChainId;
    }

    struct SwapData {
        address callTo;
        address approveTo;
        address sendingAssetId;
        address receivingAssetId;
        uint256 fromAmount;
        bytes callData;
        bool requiresDeposit;
    }

    error CannotBridgeToSameNetwork();
    error ContractCallNotAllowed();
    error CumulativeSlippageTooHigh(uint256 minAmount, uint256 receivedAmount);
    error InformationMismatch();
    error InsufficientBalance(uint256 required, uint256 balance);
    error InvalidAmount();
    error InvalidCallData();
    error InvalidContract();
    error InvalidReceiver();
    error NativeAssetTransferFailed();
    error NoSwapDataProvided();
    error NoSwapFromZeroBalance();
    error NoTransferToNullAddress();
    error NullAddrIsNotAValidSpender();
    error NullAddrIsNotAnERC20Token();
    error ReentrancyError();

    event LiFiGenericSwapCompleted(
        bytes32 indexed transactionId,
        string integrator,
        string referrer,
        address receiver,
        address fromAssetId,
        address toAssetId,
        uint256 fromAmount,
        uint256 toAmount
    );
    event LiFiSwappedGeneric(
        bytes32 indexed transactionId,
        string integrator,
        string referrer,
        address fromAssetId,
        address toAssetId,
        uint256 fromAmount,
        uint256 toAmount
    );
    event LiFiTransferCompleted(
        bytes32 indexed transactionId, address receivingAssetId, address receiver, uint256 amount, uint256 timestamp
    );
    event LiFiTransferRecovered(
        bytes32 indexed transactionId, address receivingAssetId, address receiver, uint256 amount, uint256 timestamp
    );
    event LiFiTransferStarted(BridgeData bridgeData);

    function depositToGasZipERC20(SwapData memory _swapData, uint256 _destinationChains, address _recipient) external;
    function depositToGasZipNative(uint256 _amountToZip, uint256 _destinationChains, address _recipient)
        external
        payable;
    function gasZipRouter() external view returns (address);
    function startBridgeTokensViaGasZip(BridgeData memory _bridgeData, GasZipData memory _gasZipData)
        external
        payable;
    function swapAndStartBridgeTokensViaGasZip(
        BridgeData memory _bridgeData,
        SwapData[] memory _swapData,
        GasZipData memory _gasZipData
    ) external payable;
}
