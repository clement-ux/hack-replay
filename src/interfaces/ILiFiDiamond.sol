// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;

import {IGasZipFacet} from "src/interfaces/IGasZipFacet.sol";

interface ILiFiDiamond is IGasZipFacet {
    error CalldataEmptyButInitNotZero();
    error FacetAddressIsNotZero();
    error FacetAddressIsZero();
    error FacetContainsNoCode();
    error FunctionAlreadyExists();
    error FunctionDoesNotExist();
    error FunctionIsImmutable();
    error IncorrectFacetCutAction();
    error InitReverted();
    error InitZeroButCalldataNotEmpty();
    error NoSelectorsInFace();

    fallback() external payable;

    receive() external payable;
}
