// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "forge-std/console2.sol";
import "forge-std/Script.sol";
import {IERC20} from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {Permit2} from "../src/Permit2.sol";
import {IAllowanceTransfer} from "../src/interfaces/IAllowanceTransfer.sol";
import {ISignatureTransfer} from "../src/interfaces/ISignatureTransfer.sol";

// Uniswap V3 interfaces
interface ISwapRouter {
    struct ExactInputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
        uint160 sqrtPriceLimitX96;
    }

    function exactInputSingle(ExactInputSingleParams calldata params) external payable returns (uint256 amountOut);
}

/**
 * @title Permit2を使ったUniswap統合スワップコントラクト
 * @notice Permit2の機能を活用してUniswapでスワップを実行する中間コントラクト
 */
contract Permit2UniswapIntegrator {
    Permit2 public immutable permit2;
    ISwapRouter public immutable swapRouter;

    // イベント
    event SwapExecuted(
        address indexed user, address indexed tokenIn, address indexed tokenOut, uint256 amountIn, uint256 amountOut
    );

    constructor(address _permit2, address _swapRouter) {
        permit2 = Permit2(_permit2);
        swapRouter = ISwapRouter(_swapRouter);
    }

    /**
     * @notice AllowanceTransferを使用したスワップ
     */
    function swapWithAllowanceTransfer(
        address tokenIn,
        address tokenOut,
        uint24 fee,
        uint160 amountIn,
        uint256 amountOutMinimum,
        address recipient
    ) external returns (uint256 amountOut) {
        // 1. Permit2経由でトークンを受け取る
        IAllowanceTransfer.AllowanceTransferDetails[] memory transferDetails =
            new IAllowanceTransfer.AllowanceTransferDetails[](1);

        transferDetails[0] = IAllowanceTransfer.AllowanceTransferDetails({
            from: msg.sender,
            to: address(this),
            amount: amountIn,
            token: tokenIn
        });

        permit2.transferFrom(transferDetails);

        // 2. トークンをUniswap Routerに許可
        IERC20(tokenIn).approve(address(swapRouter), amountIn);

        // 3. Uniswapでスワップ実行
        ISwapRouter.ExactInputSingleParams memory params = ISwapRouter.ExactInputSingleParams({
            tokenIn: tokenIn,
            tokenOut: tokenOut,
            fee: fee,
            recipient: recipient,
            deadline: block.timestamp + 300,
            amountIn: amountIn,
            amountOutMinimum: amountOutMinimum,
            sqrtPriceLimitX96: 0
        });

        amountOut = swapRouter.exactInputSingle(params);

        emit SwapExecuted(msg.sender, tokenIn, tokenOut, amountIn, amountOut);
    }

    /**
     * @notice SignatureTransferを使用したスワップ
     */
    function swapWithSignatureTransfer(
        ISignatureTransfer.PermitTransferFrom memory permit,
        bytes calldata signature,
        address tokenOut,
        uint24 fee,
        uint256 amountOutMinimum,
        address recipient
    ) external returns (uint256 amountOut) {
        // 1. 署名検証と転送実行
        ISignatureTransfer.SignatureTransferDetails memory transferDetails =
            ISignatureTransfer.SignatureTransferDetails({to: address(this), requestedAmount: permit.permitted.amount});

        permit2.permitTransferFrom(permit, transferDetails, msg.sender, signature);

        // 2. トークンをUniswap Routerに許可
        IERC20(permit.permitted.token).approve(address(swapRouter), permit.permitted.amount);

        // 3. Uniswapでスワップ実行
        ISwapRouter.ExactInputSingleParams memory params = ISwapRouter.ExactInputSingleParams({
            tokenIn: permit.permitted.token,
            tokenOut: tokenOut,
            fee: fee,
            recipient: recipient,
            deadline: block.timestamp + 300,
            amountIn: permit.permitted.amount,
            amountOutMinimum: amountOutMinimum,
            sqrtPriceLimitX96: 0
        });

        amountOut = swapRouter.exactInputSingle(params);

        emit SwapExecuted(msg.sender, permit.permitted.token, tokenOut, permit.permitted.amount, amountOut);
    }
}

/**
 * @title Permit2-Uniswap統合スクリプト
 * @notice Permit2とUniswap V3を組み合わせた高度なスワップ機能のデモ
 */
contract AdvancedPermit2UniswapScript is Script {
    // Sepolia テストネットのコントラクトアドレス
    address constant PERMIT2_ADDRESS = 0xF08f41d9f4704be54AbdDA494F7d0FE6098fa9f3;
    address constant UNISWAP_V3_ROUTER = 0x3bFA4769FB09eefC5a80d6E87c3B9C650f7Ae48E;

    // Sepolia テストトークン
    address constant WETH_SEPOLIA = 0xfFf9976782d46CC05630D1f6eBAb18b2324d6B14;
    address constant USDC_SEPOLIA = 0x1c7D4B196Cb0C7B01d743Fbc6116a902379C7238;

    uint24 constant POOL_FEE_MEDIUM = 3000;

    Permit2 permit2;
    Permit2UniswapIntegrator integrator;

    /**
     * 事前セットアップ
     */
    function setUp() public {
        permit2 = Permit2(PERMIT2_ADDRESS);
    }

    /**
     * @notice 統合コントラクトをデプロイ
     */
    function deployIntegrator() public {
        console2.log("=== Deploying Permit2-Uniswap Integrator ===");

        uint256 privateKey = vm.envUint("PRIVATE_KEY");

        vm.startBroadcast(privateKey);

        // 統合コントラクトをデプロイ
        integrator = new Permit2UniswapIntegrator(PERMIT2_ADDRESS, UNISWAP_V3_ROUTER);

        console2.log("Integrator deployed at:", address(integrator));
        console2.log("Permit2 address:", PERMIT2_ADDRESS);
        console2.log("Uniswap Router:", UNISWAP_V3_ROUTER);

        vm.stopBroadcast();

        console2.log("=== Deployment Completed ===");
    }

    /**
     * @notice 統合コントラクトを使用したスワップ実行
     */
    function executeIntegratedSwap() public {
        console2.log("=== Executing Integrated Swap ===");

        uint256 privateKey = vm.envUint("PRIVATE_KEY");
        address userAccount = vm.addr(privateKey);

        // デプロイされた統合コントラクトのアドレスを取得
        address integratorAddress = vm.envOr("INTEGRATOR_ADDRESS", address(0));
        require(integratorAddress != address(0), "INTEGRATOR_ADDRESS not set");

        integrator = Permit2UniswapIntegrator(integratorAddress);

        uint256 amountIn = 0.01 ether; // 0.01 WETH
        uint256 amountOutMinimum = 0; // 本番環境では適切なスリッページ保護を設定

        console2.log("Swapping via integrator:", amountIn / 1e18, "WETH for USDC");

        // 事前残高確認
        uint256 wethBalanceBefore = IERC20(WETH_SEPOLIA).balanceOf(userAccount);
        uint256 usdcBalanceBefore = IERC20(USDC_SEPOLIA).balanceOf(userAccount);

        console2.log("WETH balance before:", wethBalanceBefore / 1e18, "WETH");
        console2.log("USDC balance before:", usdcBalanceBefore / 1e6, "USDC");

        require(wethBalanceBefore >= amountIn, "Insufficient WETH balance");

        vm.startBroadcast(privateKey);

        // 1. 統合コントラクトへのPermit2許可設定（簡易版）
        // 本番環境では適切な署名生成が必要

        // 2. 統合コントラクトを使用したスワップ実行
        try integrator.swapWithAllowanceTransfer(
            WETH_SEPOLIA, USDC_SEPOLIA, POOL_FEE_MEDIUM, uint160(amountIn), amountOutMinimum, userAccount
        ) returns (uint256 amountOut) {
            console2.log("Integrated swap executed successfully!");
            console2.log("Amount out:", amountOut / 1e6, "USDC");
        } catch Error(string memory reason) {
            console2.log("Integrated swap failed:", reason);
        } catch {
            console2.log("Integrated swap failed: Unknown error");
        }

        vm.stopBroadcast();

        // 事後残高確認
        uint256 wethBalanceAfter = IERC20(WETH_SEPOLIA).balanceOf(userAccount);
        uint256 usdcBalanceAfter = IERC20(USDC_SEPOLIA).balanceOf(userAccount);

        console2.log("WETH balance after:", wethBalanceAfter / 1e18, "WETH");
        console2.log("USDC balance after:", usdcBalanceAfter / 1e6, "USDC");

        console2.log("=== Integrated Swap Completed ===");
    }

    /**
     * @notice 署名ベースのスワップのデモンストレーション
     */
    function demonstrateSignatureSwap() public pure {
        console2.log("=== Signature-based Swap Demonstration ===");
        console2.log("");
        console2.log("To execute signature-based swap:");
        console2.log("");

        console2.log("1. Generate EIP-712 signature for PermitTransferFrom:");
        console2.log("PermitTransferFrom {");
        console2.log("  permitted: TokenPermissions {");
        console2.log("    token: WETH_ADDRESS,");
        console2.log("    amount: 10000000000000000 // 0.01 WETH");
        console2.log("  },");
        console2.log("  spender: INTEGRATOR_ADDRESS,");
        console2.log("  nonce: unique_nonce,");
        console2.log("  deadline: block.timestamp + 3600");
        console2.log("}");
        console2.log("");

        console2.log("2. Call integrator.swapWithSignatureTransfer():");
        console2.log("   - Pass the permit struct");
        console2.log("   - Include the generated signature");
        console2.log("   - Specify output token and parameters");
        console2.log("");

        console2.log("Benefits of signature-based approach:");
        console2.log("  - One-time use only (more secure)");
        console2.log("  - No pre-approval needed");
        console2.log("  - Perfect for meta-transactions");
        console2.log("  - Prevents hanging approvals");
    }

    /**
     * @notice マルチステップワークフローの説明
     */
    function displayWorkflow() public pure {
        console2.log("=== Complete Workflow ===");
        console2.log("");

        console2.log("Traditional approach (without Permit2):");
        console2.log("1. approve(router, amount) - User sets ERC20 allowance");
        console2.log("2. router.exactInputSingle() - Execute swap");
        console2.log("Total: 2 transactions");
        console2.log("");

        console2.log("Permit2 AllowanceTransfer approach:");
        console2.log("1. approve(permit2, max) - One-time ERC20 approval");
        console2.log("2. permit(details, signature) - Set Permit2 allowance");
        console2.log("3. integrator.swapWithAllowanceTransfer() - Execute swap");
        console2.log("First time: 3 transactions, After: 2 transactions");
        console2.log("");

        console2.log("Permit2 SignatureTransfer approach:");
        console2.log("1. approve(permit2, max) - One-time ERC20 approval");
        console2.log("2. integrator.swapWithSignatureTransfer() - Swap with signature");
        console2.log("First time: 2 transactions, After: 1 transaction");
        console2.log("");

        console2.log("Recommended approach: SignatureTransfer for best UX!");
    }

    /**
     * @notice ガス効率の比較
     */
    function analyzeGasEfficiency() public pure {
        console2.log("=== Gas Efficiency Analysis ===");
        console2.log("");

        console2.log("Gas costs comparison (approximate):");
        console2.log("");

        console2.log("Traditional Uniswap swap:");
        console2.log("  - ERC20.approve(): ~46,000 gas");
        console2.log("  - SwapRouter.exactInputSingle(): ~120,000 gas");
        console2.log("  - Total: ~166,000 gas");
        console2.log("");

        console2.log("Permit2 + Uniswap (AllowanceTransfer):");
        console2.log("  - ERC20.approve(permit2): ~46,000 gas (one-time)");
        console2.log("  - Permit2.permit(): ~50,000 gas");
        console2.log("  - Integrator swap: ~150,000 gas");
        console2.log("  - Total first time: ~246,000 gas");
        console2.log("  - Total subsequent: ~200,000 gas");
        console2.log("");

        console2.log("Permit2 + Uniswap (SignatureTransfer):");
        console2.log("  - ERC20.approve(permit2): ~46,000 gas (one-time)");
        console2.log("  - Integrator signature swap: ~170,000 gas");
        console2.log("  - Total first time: ~216,000 gas");
        console2.log("  - Total subsequent: ~170,000 gas");
        console2.log("");

        console2.log("Additional benefits:");
        console2.log("  - Batch operations further reduce costs");
        console2.log("  - Expiring permits eliminate stale approvals");
        console2.log("  - Meta-transaction support");
        console2.log("  - Enhanced security model");
    }

    /**
     * @notice メイン実行関数
     */
    function run() public {
        console2.log("=== Advanced Permit2-Uniswap Integration Demo ===");

        console2.log("This script demonstrates advanced integration between");
        console2.log("Permit2 and Uniswap V3 for enhanced token swapping.");
        console2.log("");

        // ワークフローの説明
        displayWorkflow();

        // ガス効率分析
        analyzeGasEfficiency();

        // 署名ベーススワップのデモ
        demonstrateSignatureSwap();

        console2.log("");
        console2.log("To deploy and use the integrator:");
        console2.log(
            "1. forge script script/AdvancedPermit2UniswapScript.s.sol:AdvancedPermit2UniswapScript --sig 'deployIntegrator()' --rpc-url $RPC_URL --private-key $PRIVATE_KEY --broadcast"
        );
        console2.log("2. export INTEGRATOR_ADDRESS=0x... # Set deployed address");
        console2.log(
            "3. forge script script/AdvancedPermit2UniswapScript.s.sol:AdvancedPermit2UniswapScript --sig 'executeIntegratedSwap()' --rpc-url $RPC_URL --private-key $PRIVATE_KEY --broadcast"
        );
        console2.log("");

        console2.log("=== Advanced Demo Completed ===");
    }
}
