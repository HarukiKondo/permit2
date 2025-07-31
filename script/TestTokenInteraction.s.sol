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
contract TestTokenInteraction is Script {
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
        console2.log("=== トークン相互作用テスト ===");
        
        // 利用可能なテストアカウントを取得
        address testAccount = vm.addr(1); // 秘密鍵1から生成されるアドレス
        console2.log("テストアカウント:", testAccount);
        
        // 各種トークンの基本情報を確認
        analyzeTokenInfo(WETH_SEPOLIA, "WETH");
        analyzeTokenInfo(LINK_SEPOLIA, "LINK");
        
        // Permit2との相互作用を確認
        testPermit2Integration(testAccount, WETH_SEPOLIA);
        
        console2.log("=== トークン相互作用テスト完了 ===");
    }

    /**
     * @notice 特定のトークンの基本情報を分析
     * @param tokenAddress トークンのアドレス
     * @param tokenName トークンの名前（表示用）
     */
    function analyzeTokenInfo(address tokenAddress, string memory tokenName) public view {
        console2.log("=== ", tokenName, " トークン情報 ===");
        console2.log("アドレス:", tokenAddress);
        
        // コントラクトが存在するかチェック
        uint256 codeSize;
        assembly {
            codeSize := extcodesize(tokenAddress)
        }
        
        if (codeSize > 0) {
            console2.log("コントラクト存在: Yes");
            console2.log("バイトコードサイズ:", codeSize, "bytes");
            
            // ERC20の基本情報を取得（可能な場合）
            try IERC20(tokenAddress).totalSupply() returns (uint256 totalSupply) {
                console2.log("総供給量:", totalSupply);
            } catch {
                console2.log("総供給量: 取得失敗");
            }
            
            try IERC20(tokenAddress).decimals() returns (uint8 decimals) {
                console2.log("小数点桁数:", decimals);
            } catch {
                console2.log("小数点桁数: 取得失敗");
            }
        } else {
            console2.log("コントラクト存在: No");
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
        console2.log("=== ", tokenName, " 残高確認 ===");
        console2.log("アカウント:", account);
        
        try IERC20(tokenAddress).balanceOf(account) returns (uint256 balance) {
            console2.log("残高:", balance);
            
            if (balance > 0) {
                // Permit2への許可状況も確認
                try IERC20(tokenAddress).allowance(account, PERMIT2_ADDRESS) returns (uint256 allowance) {
                    console2.log("Permit2への許可量:", allowance);
                    
                    if (allowance >= balance) {
                        console2.log("許可状況: 十分");
                    } else if (allowance > 0) {
                        console2.log("許可状況: 部分的");
                    } else {
                        console2.log("許可状況: なし");
                    }
                } catch {
                    console2.log("許可量確認: 失敗");
                }
            }
        } catch {
            console2.log("残高確認: 失敗");
        }
        
        console2.log("");
    }

    /**
     * @notice Permit2との統合テスト
     * @param testAccount テスト用アカウント
     * @param tokenAddress テスト対象のトークン
     */
    function testPermit2Integration(address testAccount, address tokenAddress) public view {
        console2.log("=== Permit2統合テスト ===");
        console2.log("テストアカウント:", testAccount);
        console2.log("テストトークン:", tokenAddress);
        
        // Permit2での許可状況を確認
        address spender = address(0x1234567890123456789012345678901234567890); // ダミーのスペンダー
        
        (uint160 amount, uint48 expiration, uint48 nonce) = permit2.allowance(
            testAccount,
            tokenAddress,
            spender
        );
        
        console2.log("Permit2許可情報:");
        console2.log("  許可量:", amount);
        console2.log("  有効期限:", expiration);
        console2.log("  ナンス:", nonce);
        
        // 有効期限の状態を判定
        if (expiration == 0) {
            console2.log("  状態: 許可設定なし");
        } else if (expiration < block.timestamp) {
            console2.log("  状態: 期限切れ");
        } else {
            console2.log("  状態: 有効");
            console2.log("  残り時間:", expiration - block.timestamp, "秒");
        }
        
        // ナンスビットマップの状況
        uint256 bitmap = permit2.nonceBitmap(testAccount, 0);
        console2.log("ナンスビットマップ（ワード0）:", bitmap);
        
        console2.log("");
    }

    /**
     * @notice 複数のアカウントでの一括テスト
     * @param tokenAddress テスト対象のトークン
     */
    function batchTestAccounts(address tokenAddress) public view {
        console2.log("=== 複数アカウント一括テスト ===");
        
        // 複数のテストアカウントを生成
        address[] memory testAccounts = new address[](3);
        testAccounts[0] = vm.addr(1);
        testAccounts[1] = vm.addr(2);
        testAccounts[2] = vm.addr(3);
        
        for (uint256 i = 0; i < testAccounts.length; i++) {
            console2.log("--- アカウント", i + 1, "---");
            checkTokenBalance(testAccounts[i], tokenAddress, "TEST");
            
            // 簡単なPermit2許可確認
            (uint160 amount,,) = permit2.allowance(
                testAccounts[i],
                tokenAddress,
                address(this)
            );
            console2.log("Permit2許可量:", amount);
        }
    }

    /**
     * @notice ガス効率の分析
     */
    function analyzeGasEfficiency() public view {
        console2.log("=== ガス効率分析 ===");
        
        // 各種関数呼び出しのガス使用量を推定
        console2.log("想定ガス使用量:");
        console2.log("  allowance()関数: ~2,000 gas");
        console2.log("  permit()関数: ~45,000-55,000 gas");
        console2.log("  transferFrom()関数: ~35,000-45,000 gas");
        console2.log("  permitTransferFrom()関数: ~65,000-75,000 gas");
        
        console2.log("最適化のポイント:");
        console2.log("  - バッチ処理の使用");
        console2.log("  - 適切な有効期限の設定");
        console2.log("  - ナンスの効率的な管理");
    }

    /**
     * @notice セキュリティ考慮事項の表示
     */
    function displaySecurityConsiderations() public pure {
        console2.log("=== セキュリティ考慮事項 ===");
        console2.log("重要なポイント:");
        console2.log("  1. 署名の有効期限を適切に設定する");
        console2.log("  2. ナンスを正しく管理してリプレイ攻撃を防ぐ");
        console2.log("  3. 許可量を必要最小限に設定する");
        console2.log("  4. 信頼できないスペンダーに注意する");
        console2.log("  5. 期限切れの許可を定期的にクリアする");
        
        console2.log("ベストプラクティス:");
        console2.log("  - 短期間の有効期限を使用");
        console2.log("  - バッチ処理でガス効率を向上");
        console2.log("  - 適切なエラーハンドリング");
        console2.log("  - 定期的なセキュリティ監査");
    }
}
