// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "forge-std/console2.sol";
import "forge-std/Script.sol";
import {IERC20} from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {Permit2} from "../src/Permit2.sol";
import {IAllowanceTransfer} from "../src/interfaces/IAllowanceTransfer.sol";

/**
 * @title トークンとの相互作用テストスクリプト
 * @notice 実際のERC20トークンとPermit2コントラクトの相互作用をテストします
 * @dev Sepoliaテストネット上のトークンを使用してPermit2の機能をテストします
 */
contract TokenInteraction is Script {
    // SepoliaテストネットのPermit2コントラクトアドレス
    address constant PERMIT2_ADDRESS = 0xF08f41d9f4704be54AbdDA494F7d0FE6098fa9f3;

    // Sepoliaテストネット上の一般的なテストトークン
    address constant WETH_SEPOLIA = 0x7b79995e5f793A07Bc00c21412e50Ecae098E7f9;
    address constant LINK_SEPOLIA = 0x779877A7B0D9E8603169DdbD7836e478b4624789;

    Permit2 permit2;

    function setUp() public {
        permit2 = Permit2(PERMIT2_ADDRESS);
    }

    /**
     * @notice トークン相互作用テストのメイン実行関数
     */
    function run() public {
        console2.log("=== Token Interaction Test ===");

        // 利用可能なテストアカウントを取得
        address testAccount = vm.addr(1); // 秘密鍵1から生成されるアドレス
        console2.log("Test Account:", testAccount);

        // 各種トークンの基本情報を確認
        analyzeTokenInfo(WETH_SEPOLIA, "WETH");
        analyzeTokenInfo(LINK_SEPOLIA, "LINK");

        // Permit2との相互作用を確認
        Permit2Integration(testAccount, WETH_SEPOLIA);

        batchTestAccounts(WETH_SEPOLIA);
        batchTestAccounts(LINK_SEPOLIA);

        console2.log("=== Token Interaction Test Completed ===");
    }

    /**
     * @notice 特定のトークンの基本情報を分析
     * @param tokenAddress トークンのアドレス
     * @param tokenName トークンの名前（表示用）
     */
    function analyzeTokenInfo(address tokenAddress, string memory tokenName) public view {
        console2.log("=== ", tokenName, " Token Information ===");
        console2.log("Address:", tokenAddress);

        // コントラクトが存在するかチェック
        uint256 codeSize;
        assembly {
            codeSize := extcodesize(tokenAddress)
        }

        if (codeSize > 0) {
            console2.log("Contract Exists: Yes");
            console2.log("Bytecode Size:", codeSize, "bytes");

            // ERC20の基本情報を取得（可能な場合）
            try IERC20(tokenAddress).totalSupply() returns (uint256 totalSupply) {
                console2.log("Total Supply:", totalSupply);
            } catch {
                console2.log("Total Supply: Failed to retrieve");
            }
        } else {
            console2.log("Contract Exists: No");
        }

        console2.log("");
    }

    /**
     * @notice 指定されたアカウントのトークン残高を確認
     * @param account アカウントアドレス
     * @param tokenAddress トークンアドレス
     * @param tokenName トークン名（表示用）
     */
    function checkTokenBalance(address account, address tokenAddress, string memory tokenName) public view {
        console2.log("=== ", tokenName, " Balance Check ===");
        console2.log("Account:", account);

        try IERC20(tokenAddress).balanceOf(account) returns (uint256 balance) {
            console2.log("Balance:", balance);

            if (balance > 0) {
                // Permit2への許可状況も確認
                try IERC20(tokenAddress).allowance(account, PERMIT2_ADDRESS) returns (uint256 allowance) {
                    console2.log("Allowance to Permit2:", allowance);

                    if (allowance >= balance) {
                        console2.log("Allowance Status: Sufficient");
                    } else if (allowance > 0) {
                        console2.log("Allowance Status: Partial");
                    } else {
                        console2.log("Allowance Status: None");
                    }
                } catch {
                    console2.log("Allowance Check: Failed");
                }
            }
        } catch {
            console2.log("Balance Check: Failed");
        }

        console2.log("");
    }

    /**
     * @notice Permit2との統合テスト
     * @param testAccount テスト用アカウント
     * @param tokenAddress テスト対象のトークン
     */
    function Permit2Integration(address testAccount, address tokenAddress) public view {
        console2.log("=== Permit2 Integration Test ===");
        console2.log("Test Account:", testAccount);
        console2.log("Test Token:", tokenAddress);

        // Permit2での許可状況を確認(ここは自分のウォレットアドレスを指定する)
        address spender = address(0x034f66d49A175438AD7Ec0111CcA18fce1A39Fa6);

        (uint160 amount, uint48 expiration, uint48 nonce) = permit2.allowance(testAccount, tokenAddress, spender);

        console2.log("Permit2 Allowance Information:");
        console2.log("  Amount:", amount);
        console2.log("  Expiration:", expiration);
        console2.log("  Nonce:", nonce);

        // 有効期限の状態を判定
        if (expiration == 0) {
            console2.log("  Status: No allowance set");
        } else if (expiration < block.timestamp) {
            console2.log("  Status: Expired");
        } else {
            console2.log("  Status: Valid");
            console2.log("  Time Remaining:", expiration - block.timestamp, "seconds");
        }

        // ナンスビットマップの状況
        uint256 bitmap = permit2.nonceBitmap(testAccount, 0);
        console2.log("Nonce Bitmap (Word 0):", bitmap);

        console2.log("");
    }

    /**
     * @notice 複数のアカウントでの一括テスト
     * @param tokenAddress テスト対象のトークン
     */
    function batchTestAccounts(address tokenAddress) public view {
        console2.log("=== Batch Test Multiple Accounts ===");

        // 複数のテストアカウントを生成
        address[] memory testAccounts = new address[](3);
        testAccounts[0] = vm.addr(1);
        testAccounts[1] = vm.addr(2);
        testAccounts[2] = vm.addr(3);

        for (uint256 i = 0; i < testAccounts.length; i++) {
            console2.log("--- Account", i + 1, "---");
            checkTokenBalance(testAccounts[i], tokenAddress, "TEST");

            // 簡単なPermit2許可確認
            (uint160 amount,,) = permit2.allowance(testAccounts[i], tokenAddress, PERMIT2_ADDRESS);
            console2.log("Permit2 Allowance Amount:", amount);
        }
    }

    /**
     * @notice ガス効率の分析
     */
    function analyzeGasEfficiency() public view {
        console2.log("=== Gas Efficiency Analysis ===");

        // 各種関数呼び出しのガス使用量を推定
        console2.log("Estimated Gas Usage:");
        console2.log("  allowance() function: ~2,000 gas");
        console2.log("  permit() function: ~45,000-55,000 gas");
        console2.log("  transferFrom() function: ~35,000-45,000 gas");
        console2.log("  permitTransferFrom() function: ~65,000-75,000 gas");

        console2.log("Optimization Points:");
        console2.log("  - Use batch processing");
        console2.log("  - Set appropriate expiration times");
        console2.log("  - Efficient nonce management");
    }

    /**
     * @notice セキュリティ考慮事項の表示
     */
    function displaySecurityConsiderations() public pure {
        console2.log("=== Security Considerations ===");
        console2.log("Important Points:");
        console2.log("  1. Set appropriate signature expiration times");
        console2.log("  2. Properly manage nonces to prevent replay attacks");
        console2.log("  3. Set allowance amounts to minimum necessary");
        console2.log("  4. Be careful with untrusted spenders");
        console2.log("  5. Regularly clear expired allowances");

        console2.log("Best Practices:");
        console2.log("  - Use short-term expiration times");
        console2.log("  - Improve gas efficiency with batch processing");
        console2.log("  - Implement proper error handling");
        console2.log("  - Conduct regular security audits");
    }
}
