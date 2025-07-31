// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "forge-std/console2.sol";
import "forge-std/Script.sol";
import {Permit2} from "../src/Permit2.sol";
import {IAllowanceTransfer} from "../src/interfaces/IAllowanceTransfer.sol";
import {ISignatureTransfer} from "../src/interfaces/ISignatureTransfer.sol";

/**
 * @title Permit2の高度な機能をテストするスクリプト
 * @notice Permit2コントラクトの署名検証や型ハッシュなどの高度な機能をテストします
 * @dev EIP-712署名の検証や各種ハッシュ値の確認を行います
 */
contract TestPermit2Advanced is Script {
    // SepoliaテストネットのPermit2コントラクトアドレス
    address constant PERMIT2_ADDRESS = 0xF08f41d9f4704be54AbdDA494F7d0FE6098fa9f3;
    
    Permit2 permit2;

    function setUp() public {
        permit2 = Permit2(PERMIT2_ADDRESS);
    }

    /**
     * @notice 高度な機能のテストを実行
     */
    function run() public view {
        console2.log(unicode"=== Permit2高度機能テスト ===");
        
        // EIP-712関連の情報を取得
        analyzeEIP712Structure();
        
        // 各種型ハッシュを確認
        analyzeTypeHashes();
        
        // テスト用のサンプルデータで署名構造を確認
        demonstrateSignatureStructures();
        
        console2.log(unicode"=== 高度機能テスト完了 ===");
    }

    /**
     * @notice EIP-712構造の詳細分析
     */
    function analyzeEIP712Structure() internal view {
        console2.log(unicode"=== EIP-712構造分析 ===");
        
        bytes32 domainSeparator = permit2.DOMAIN_SEPARATOR();
        console2.log("DOMAIN_SEPARATOR:");
        console2.logBytes32(domainSeparator);
        
        // ドメインタイプハッシュ
        bytes32 domainTypeHash = keccak256("EIP712Domain(string name,uint256 chainId,address verifyingContract)");
        console2.log("Domain TypeHash:");
        console2.logBytes32(domainTypeHash);
        
        // 名前ハッシュ
        bytes32 nameHash = keccak256("Permit2");
        console2.log("Name Hash:");
        console2.logBytes32(nameHash);
        
        console2.log("Chain ID:", block.chainid);
        console2.log("Verifying Contract:", PERMIT2_ADDRESS);
    }

    /**
     * @notice 各種型ハッシュの分析
     */
    function analyzeTypeHashes() internal pure {
        console2.log("=== 型ハッシュ分析 ===");
        
        // AllowanceTransfer関連の型ハッシュ
        bytes32 permitTransferFromTypeHash = keccak256(
            "PermitTransferFrom(TokenPermissions permitted,address spender,uint256 nonce,uint256 deadline)TokenPermissions(address token,uint256 amount)"
        );
        console2.log("PermitTransferFrom TypeHash:");
        console2.logBytes32(permitTransferFromTypeHash);
        
        bytes32 permitBatchTransferFromTypeHash = keccak256(
            "PermitBatchTransferFrom(TokenPermissions[] permitted,address spender,uint256 nonce,uint256 deadline)TokenPermissions(address token,uint256 amount)"
        );
        console2.log("PermitBatchTransferFrom TypeHash:");
        console2.logBytes32(permitBatchTransferFromTypeHash);
        
        // AllowanceTransfer関連の型ハッシュ
        bytes32 permitSingleTypeHash = keccak256(
            "PermitSingle(PermitDetails details,address spender,uint256 sigDeadline)PermitDetails(address token,uint160 amount,uint48 expiration,uint48 nonce)"
        );
        console2.log("PermitSingle TypeHash:");
        console2.logBytes32(permitSingleTypeHash);
        
        bytes32 permitBatchTypeHash = keccak256(
            "PermitBatch(PermitDetails[] details,address spender,uint256 sigDeadline)PermitDetails(address token,uint160 amount,uint48 expiration,uint48 nonce)"
        );
        console2.log("PermitBatch TypeHash:");
        console2.logBytes32(permitBatchTypeHash);
    }

    /**
     * @notice 署名構造のデモンストレーション
     */
    function demonstrateSignatureStructures() internal pure {
        console2.log("=== 署名構造デモンストレーション ===");
        
        // サンプルのTokenPermissions構造
        console2.log("TokenPermissions構造:");
        console2.log("  - token: address");
        console2.log("  - amount: uint256");
        
        // サンプルのPermitDetails構造
        console2.log("PermitDetails構造:");
        console2.log("  - token: address");
        console2.log("  - amount: uint160");
        console2.log("  - expiration: uint48");
        console2.log("  - nonce: uint48");
        
        // サンプルのTransferDetails構造
        console2.log("TransferDetails構造:");
        console2.log("  - to: address");
        console2.log("  - requestedAmount: uint256");
        
        console2.log("署名で使用される主要な値:");
        console2.log("  - spender: 使用許可されるアドレス");
        console2.log("  - nonce: リプレイ攻撃防止用の値");
        console2.log("  - deadline: 署名の有効期限");
    }

    /**
     * @notice ナンス管理システムの詳細分析
     * @param testAddress テスト対象のアドレス
     */
    function analyzeNonceSystem(address testAddress) public view {
        console2.log("=== ナンス管理システム分析 ===");
        console2.log("対象アドレス:", testAddress);
        
        // 複数のワード位置でナンスビットマップを確認
        for (uint256 word = 0; word < 3; word++) {
            uint256 bitmap = permit2.nonceBitmap(testAddress, word);
            console2.log("ワード", word, "のビットマップ:", bitmap);
            
            if (bitmap > 0) {
                // 使用済みナンスの詳細分析
                console2.log("  使用済みナンス:");
                for (uint256 bit = 0; bit < 256; bit++) {
                    if ((bitmap >> bit) & 1 == 1) {
                        uint256 nonce = word * 256 + bit;
                        console2.log("    ナンス", nonce, "は使用済み");
                    }
                }
            }
        }
    }

    /**
     * @notice 時間ベースの機能分析
     */
    function analyzeTimeFunctions() public view {
        console2.log("=== 時間ベース機能分析 ===");
        
        uint256 currentTimestamp = block.timestamp;
        console2.log("現在のタイムスタンプ:", currentTimestamp);
        
        // 一般的な有効期限の例
        uint48 oneHour = uint48(currentTimestamp + 3600);
        uint48 oneDay = uint48(currentTimestamp + 86400);
        uint48 oneWeek = uint48(currentTimestamp + 604800);
        
        console2.log("1時間後の有効期限:", oneHour);
        console2.log("1日後の有効期限:", oneDay);
        console2.log("1週間後の有効期限:", oneWeek);
        
        // uint48の最大値確認
        uint48 maxExpiration = type(uint48).max;
        console2.log("最大有効期限値:", maxExpiration);
        console2.log("最大有効期限日時:", maxExpiration, "(Unix timestamp)");
    }

    /**
     * @notice コントラクトの継承構造を分析
     */
    function analyzeInheritanceStructure() public pure {
        console2.log("=== 継承構造分析 ===");
        console2.log("Permit2コントラクトの継承:");
        console2.log("  Permit2");
        console2.log("  ├── SignatureTransfer");
        console2.log("  │   ├── EIP712");
        console2.log("  │   └── ISignatureTransfer");
        console2.log("  └── AllowanceTransfer");
        console2.log("      ├── EIP712");
        console2.log("      └── IAllowanceTransfer");
        
        console2.log("主要な機能:");
        console2.log("  - SignatureTransfer: 署名ベースの転送");
        console2.log("  - AllowanceTransfer: 許可ベースの転送");
        console2.log("  - EIP712: 構造化データの署名");
    }
}
