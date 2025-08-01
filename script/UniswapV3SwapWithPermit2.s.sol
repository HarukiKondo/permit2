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

    struct ExactInputParams {
        bytes path;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
    }

    function exactInput(ExactInputParams calldata params) external payable returns (uint256 amountOut);
}

interface IQuoter {
    function quoteExactInputSingle(
        address tokenIn,
        address tokenOut,
        uint24 fee,
        uint256 amountIn,
        uint160 sqrtPriceLimitX96
    ) external returns (uint256 amountOut);
}

interface IWETH9 {
    function deposit() external payable;
    function withdraw(uint256 amount) external;
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
}

/**
 * @title Uniswap V3 + Permit2 スワップスクリプト
 * @notice SepoliaテストネットのUniswap V3を使用してPermit2経由でトークンスワップを実行
 */
contract UniswapV3SwapWithPermit2 is Script {
    // Sepolia テストネットのコントラクトアドレス
    address constant PERMIT2_ADDRESS = 0xF08f41d9f4704be54AbdDA494F7d0FE6098fa9f3;
    // Uniswapのルーターとクォーターのアドレスは公式ドキュメントを参照すること
    address constant UNISWAP_V3_ROUTER = 0x3bFA4769FB09eefC5a80d6E87c3B9C650f7Ae48E;
    address constant UNISWAP_V3_QUOTER = 0xEd1f6473345F45b75F8179591dd5bA1888cf2FB3;

    // Sepolia テストトークン
    address constant WETH_SEPOLIA = 0xfFf9976782d46CC05630D1f6eBAb18b2324d6B14;
    address constant USDC_SEPOLIA = 0x1c7D4B196Cb0C7B01d743Fbc6116a902379C7238;
    address constant UNI_SEPOLIA = 0x1f9840a85d5aF5bf1D1762F925BDADdC4201F984;

    // Pool fees (0.05%, 0.3%, 1.0%)
    uint24 constant POOL_FEE_LOW = 500;
    uint24 constant POOL_FEE_MEDIUM = 3000;
    uint24 constant POOL_FEE_HIGH = 10000;

    Permit2 permit2;
    ISwapRouter swapRouter;
    IQuoter quoter;
    IWETH9 weth;

    /**
     * セットアップ
     * 各コントラクトのインスタンス化
     */
    function setUp() public {
        permit2 = Permit2(PERMIT2_ADDRESS);
        swapRouter = ISwapRouter(UNISWAP_V3_ROUTER);
        quoter = IQuoter(UNISWAP_V3_QUOTER);
        weth = IWETH9(WETH_SEPOLIA);
    }

    /**
     * @notice メイン実行関数
     */
    function run() public {
        console2.log("=== Uniswap V3 + Permit2 Swap Demo ===");
        console2.log("Uniswap V3 Router:", UNISWAP_V3_ROUTER);
        console2.log("Permit2 Address:", PERMIT2_ADDRESS);
        console2.log("WETH Address:", WETH_SEPOLIA);
        console2.log("USDC Address:", USDC_SEPOLIA);

        uint256 privateKey = vm.envUint("PRIVATE_KEY");
        address userAccount = vm.addr(privateKey);
        console2.log("User Account:", userAccount);

        // 現在の残高確認
        checkBalances(userAccount);

        // 使用方法の説明
        displayUsageInstructions();

        console2.log("=== Demo Completed ===");
    }

    /**
     * @notice ETHをWETHに変換
     */
    function wrapETH() public {
        console2.log("=== Wrapping ETH to WETH ===");

        uint256 privateKey = vm.envUint("PRIVATE_KEY");
        address userAccount = vm.addr(privateKey);

        uint256 ethAmount = 0.1 ether; // 0.1 ETH をラップ

        console2.log("Wrapping", ethAmount / 1e18, "ETH to WETH");
        console2.log("User ETH balance:", userAccount.balance / 1e18, "ETH");

        require(userAccount.balance >= ethAmount, "Insufficient ETH balance");

        vm.startBroadcast(privateKey);

        // ETHをWETHに変換
        weth.deposit{value: ethAmount}();

        vm.stopBroadcast();

        // 変換後の残高確認
        uint256 wethBalance = weth.balanceOf(userAccount);
        console2.log("WETH balance after wrapping:", wethBalance / 1e18, "WETH");

        console2.log("=== ETH Wrapping Completed ===");
    }

    /**
     * @notice Permit2へのERC20許可設定
     */
    function approvePermit2() public {
        console2.log("=== Approving Permit2 for ERC20 Tokens ===");

        uint256 privateKey = vm.envUint("PRIVATE_KEY");

        vm.startBroadcast(privateKey);

        // WETH への許可
        try IERC20(WETH_SEPOLIA).approve(PERMIT2_ADDRESS, type(uint256).max) {
            console2.log("WETH approval to Permit2: SUCCESS");
        } catch {
            console2.log("WETH approval to Permit2: FAILED");
        }

        // USDC への許可
        try IERC20(USDC_SEPOLIA).approve(PERMIT2_ADDRESS, type(uint256).max) {
            console2.log("USDC approval to Permit2: SUCCESS");
        } catch {
            console2.log("USDC approval to Permit2: FAILED");
        }

        vm.stopBroadcast();

        console2.log("=== ERC20 Approvals Completed ===");
    }

    /**
     * @notice Uniswap RouterへのERC20許可設定
     */
    function approveUniswapRouter() public {
        console2.log("=== Approving Uniswap Router for ERC20 Tokens ===");

        uint256 privateKey = vm.envUint("PRIVATE_KEY");

        vm.startBroadcast(privateKey);

        // WETH への許可
        try IERC20(WETH_SEPOLIA).approve(UNISWAP_V3_ROUTER, type(uint256).max) {
            console2.log("WETH approval to Uniswap Router: SUCCESS");
        } catch {
            console2.log("WETH approval to Uniswap Router: FAILED");
        }

        // USDC への許可
        try IERC20(USDC_SEPOLIA).approve(UNISWAP_V3_ROUTER, type(uint256).max) {
            console2.log("USDC approval to Uniswap Router: SUCCESS");
        } catch {
            console2.log("USDC approval to Uniswap Router: FAILED");
        }

        vm.stopBroadcast();

        console2.log("=== Uniswap Router Approvals Completed ===");
    }

    /**
     * @notice スワップの見積もりを取得
     */
    function getQuote() public {
        console2.log("=== Getting Swap Quote ===");

        uint256 amountIn = 0.01 ether; // 0.01 WETH

        console2.log("Quote for", amountIn / 1e18, "WETH -> USDC");

        try quoter.quoteExactInputSingle(WETH_SEPOLIA, USDC_SEPOLIA, POOL_FEE_MEDIUM, amountIn, 0) returns (
            uint256 amountOut
        ) {
            console2.log("Expected USDC output:", amountOut / 1e6, "USDC");
            console2.log("Exchange rate: 1 WETH =", amountOut / 1e6, "USDC");
        } catch {
            console2.log("Failed to get quote - pool may not exist or have liquidity");
        }

        console2.log("=== Quote Retrieved ===");
    }

    /**
     * @notice 直接的なUniswapスワップ実行
     */
    function executeDirectSwap() public {
        console2.log("=== Executing Direct Uniswap Swap ===");

        uint256 privateKey = vm.envUint("PRIVATE_KEY");
        address userAccount = vm.addr(privateKey);

        uint256 amountIn = 0.01 ether; // 0.01 WETH
        uint256 amountOutMinimum = 0; // 実際の本番環境では適切なスリッページ保護を設定

        console2.log("Swapping", amountIn, "WETH for USDC");

        // 事前残高確認
        uint256 wethBalanceBefore = IERC20(WETH_SEPOLIA).balanceOf(userAccount);
        uint256 usdcBalanceBefore = IERC20(USDC_SEPOLIA).balanceOf(userAccount);

        console2.log("WETH balance before:", wethBalanceBefore, "WETH");
        console2.log("USDC balance before:", usdcBalanceBefore, "USDC");

        require(wethBalanceBefore >= amountIn, "Insufficient WETH balance");

        vm.startBroadcast(privateKey);

        // Uniswap V3でスワップ実行
        ISwapRouter.ExactInputSingleParams memory params = ISwapRouter.ExactInputSingleParams({
            tokenIn: WETH_SEPOLIA,
            tokenOut: USDC_SEPOLIA,
            fee: POOL_FEE_MEDIUM,
            recipient: userAccount,
            deadline: block.timestamp + 300, // 5分後
            amountIn: amountIn,
            amountOutMinimum: amountOutMinimum,
            sqrtPriceLimitX96: 0
        });

        try swapRouter.exactInputSingle(params) returns (uint256 amountOut) {
            console2.log("Swap executed successfully!");
            console2.log("Amount out:", amountOut / 1e6, "USDC");
        } catch Error(string memory reason) {
            console2.log("Swap failed:", reason);
        } catch {
            console2.log("Swap failed: Unknown error");
        }

        vm.stopBroadcast();

        // 事後残高確認
        uint256 wethBalanceAfter = IERC20(WETH_SEPOLIA).balanceOf(userAccount);
        uint256 usdcBalanceAfter = IERC20(USDC_SEPOLIA).balanceOf(userAccount);

        console2.log("WETH balance after:", wethBalanceAfter, "WETH");
        console2.log("USDC balance after:", usdcBalanceAfter / 1e6, "USDC");

        console2.log("Actual swap result:");
        console2.log("WETH used:", (wethBalanceBefore - wethBalanceAfter), "WETH");
        console2.log("USDC received:", (usdcBalanceAfter - usdcBalanceBefore) / 1e6, "USDC");

        console2.log("=== Direct Swap Completed ===");
    }

    /**
     * @notice 現在の残高確認
     */
    function checkBalances(address account) public view {
        console2.log("=== Current Balances ===");

        // ETH残高
        uint256 ethBalance = account.balance;
        console2.log("ETH Balance:", ethBalance / 1e18, "ETH");

        // WETH残高
        try IERC20(WETH_SEPOLIA).balanceOf(account) returns (uint256 wethBalance) {
            console2.log("WETH Balance:", wethBalance / 1e18, "WETH");
        } catch {
            console2.log("WETH Balance: Failed to retrieve");
        }

        // USDC残高
        try IERC20(USDC_SEPOLIA).balanceOf(account) returns (uint256 usdcBalance) {
            console2.log("USDC Balance:", usdcBalance / 1e6, "USDC");
        } catch {
            console2.log("USDC Balance: Failed to retrieve");
        }

        console2.log("");
    }

    /**
     * @notice 許可状況の確認
     */
    function checkApprovals() public view {
        console2.log("=== Checking Approvals ===");

        uint256 privateKey = vm.envUint("PRIVATE_KEY");
        address userAccount = vm.addr(privateKey);

        // Permit2への許可
        console2.log("Approvals to Permit2:");
        try IERC20(WETH_SEPOLIA).allowance(userAccount, PERMIT2_ADDRESS) returns (uint256 allowance) {
            console2.log("WETH -> Permit2:", allowance == type(uint256).max ? "Unlimited" : "Limited/None");
        } catch {
            console2.log("WETH -> Permit2: Failed to check");
        }

        try IERC20(USDC_SEPOLIA).allowance(userAccount, PERMIT2_ADDRESS) returns (uint256 allowance) {
            console2.log("USDC -> Permit2:", allowance == type(uint256).max ? "Unlimited" : "Limited/None");
        } catch {
            console2.log("USDC -> Permit2: Failed to check");
        }

        // Uniswap Routerへの許可
        console2.log("Approvals to Uniswap Router:");
        try IERC20(WETH_SEPOLIA).allowance(userAccount, UNISWAP_V3_ROUTER) returns (uint256 allowance) {
            console2.log("WETH -> Router:", allowance == type(uint256).max ? "Unlimited" : "Limited/None");
        } catch {
            console2.log("WETH -> Router: Failed to check");
        }

        try IERC20(USDC_SEPOLIA).allowance(userAccount, UNISWAP_V3_ROUTER) returns (uint256 allowance) {
            console2.log("USDC -> Router:", allowance == type(uint256).max ? "Unlimited" : "Limited/None");
        } catch {
            console2.log("USDC -> Router: Failed to check");
        }

        console2.log("");
    }

    /**
     * @notice 使用方法の説明
     */
    function displayUsageInstructions() public view {
        console2.log("=== Usage Instructions ===");
        console2.log("");
        console2.log("Step 1: Get test ETH from Sepolia faucet");
        console2.log("  - Visit: https://sepoliafaucet.com/");
        console2.log("  - Get some ETH for gas and wrapping");
        console2.log("");

        console2.log("Step 2: Wrap ETH to WETH");
        console2.log(
            "forge script script/UniswapV3SwapWithPermit2.s.sol:UniswapV3SwapWithPermit2 --sig 'wrapETH()' --rpc-url $RPC_URL --private-key $PRIVATE_KEY --broadcast"
        );
        console2.log("");

        console2.log("Step 3: Approve tokens for Uniswap Router");
        console2.log(
            "forge script script/UniswapV3SwapWithPermit2.s.sol:UniswapV3SwapWithPermit2 --sig 'approveUniswapRouter()' --rpc-url $RPC_URL --private-key $PRIVATE_KEY --broadcast"
        );
        console2.log("");

        console2.log("Step 4: Get swap quote");
        console2.log(
            "forge script script/UniswapV3SwapWithPermit2.s.sol:UniswapV3SwapWithPermit2 --sig 'getQuote()' --rpc-url $RPC_URL"
        );
        console2.log("");

        console2.log("Step 5: Execute swap");
        console2.log(
            "forge script script/UniswapV3SwapWithPermit2.s.sol:UniswapV3SwapWithPermit2 --sig 'executeDirectSwap()' --rpc-url $RPC_URL --private-key $PRIVATE_KEY --broadcast"
        );
        console2.log("");

        console2.log("Check status anytime:");
        console2.log(
            "forge script script/UniswapV3SwapWithPermit2.s.sol:UniswapV3SwapWithPermit2 --sig 'checkApprovals()' --rpc-url $RPC_URL"
        );
        console2.log("");

        console2.log("=== Important Notes ===");
        console2.log("- Make sure you have Sepolia ETH for gas fees");
        console2.log("- WETH/USDC pool must exist and have liquidity");
        console2.log("- Always check quotes before executing swaps");
        console2.log("- Set appropriate slippage protection in production");
    }

    /**
     * @notice テストネット情報の表示
     */
    function displayNetworkInfo() public pure {
        console2.log("=== Sepolia Testnet Information ===");
        console2.log("");
        console2.log("Network Details:");
        console2.log("- Chain ID: 11155111");
        console2.log("- RPC URL: https://sepolia.infura.io/v3/YOUR_PROJECT_ID");
        console2.log("- Explorer: https://sepolia.etherscan.io/");
        console2.log("");

        console2.log("Contract Addresses:");
        console2.log("- Permit2:", PERMIT2_ADDRESS);
        console2.log("- Uniswap V3 Router:", UNISWAP_V3_ROUTER);
        console2.log("- Uniswap V3 Quoter:", UNISWAP_V3_QUOTER);
        console2.log("- WETH:", WETH_SEPOLIA);
        console2.log("- USDC:", USDC_SEPOLIA);
        console2.log("");

        console2.log("Faucets:");
        console2.log("- ETH: https://sepoliafaucet.com/");
        console2.log("- Multiple tokens: https://faucet.paradigm.xyz/");
        console2.log("");
    }
}
