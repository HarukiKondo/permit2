# Permit2 に関するメモ

## Permit2 について

Uniswap が開発したトークン承認（Approval）を効率化・安全化するためのスマートコントラクトです。従来の ERC20 トークンの`approve`方式が抱える UX やセキュリティ上の課題を解決することを目的としています。

### Permit2 の概要・仕組み

- **一括承認**:
  - ユーザーは、利用したいトークンに対して、一度だけ Permit2 コントラクトへの`approve`を実行します。
  - これにより、個別の DApp ごとに`approve`を行う手間が不要になります。
- **署名ベースの許可**:
  - DApp でトークンを利用する際、ユーザーは`approve`トランザクションの代わりに、オフチェーンで「パーミットメッセージ」と呼ばれるデータに署名します。
  - この署名は、特定の DApp が、特定の量のトークンを、特定の期間だけ利用することを許可する一時的な許可証の役割を果たします。
- **トランザクションの統合**:
  - DApp は、ユーザーの署名と本来の操作（例: スワップ）を 1 つのトランザクションにまとめてブロックチェーンに送信します。
  - これにより、ユーザーは 1 回の操作で承認と実行を完了でき、ガス代の節約にも繋がります。

### Permit2 のメリット

- **UX の向上**:
  - DApp を利用するたびに必要だった`approve`トランザクションが不要になり、ユーザー体験がスムーズになります。
- **セキュリティの強化**:
  - **有効期限付き承認**: 署名には有効期限を設定できるため、無期限の承認（Infinite Approval）に伴うリスクを低減できます。
  - **明確な権限委譲**: 承認するトークンの量や期間を細かく指定できるため、意図しないトークンの引き出しを防ぎます。
  - **承認の管理**: Permit2 コントラクトを通じて、承認状況を一元的に確認・取り消し（revoke）できます。
- **ガス代の節約**:
  - `approve`トランザクションが不要になるため、その分のガス代を節約できます。

### Permit2 のユースケース

- **DEX (分散型取引所)**: スワップのたびに`approve`することなく、スムーズな取引を実現します。
- **レンディングプロトコル**: 資産の貸し借りにおける承認プロセスを簡略化します。
- **NFT マーケットプレイス**: NFT のオファーや購入時の承認を効率化します。
- その他、トークン承認を必要とするあらゆる DApp で利用が可能です。

## このコードで提供されているテストシナリオの内容

### Permit2 のテストシナリオ概要

Permit2 プロジェクトには、以下の主要なテストカテゴリが含まれています：

#### 1. Allowance Transfer（許可転送）のテスト

基本機能テスト：

- testApprove() - 基本的な承認機能のテスト
- testSetAllowance() - 許可設定の基本テスト
- testTransferFromWithGasSnapshot() - 転送機能とガス使用量の測定

Nonce 管理テスト：

- testInvalidateNonces() - Nonce の無効化機能
- testReuseOrderedNonceInvalid() - 使用済み Nonce の再利用防止

バッチ処理テスト：

- testBatchTransferFrom() - 複数トークンの一括転送 .gas-snapshot:5
- testSetAllowanceBatch() - 複数許可の一括設定 .gas-snapshot:20

#### 2. Signature Transfer（署名転送）のテスト

基本転送テスト：

- testPermitTransferFrom() - 署名による転送の基本機能
- testPermitTransferFromCompactSig() - コンパクト署名での転送

Nonce 管理テスト：

- testPermitTransferFromInvalidNonce() - 無効な Nonce での転送防止
- testInvalidateUnorderedNonces() - 順序なし Nonce の無効化

バッチ転送テスト：

- testPermitBatchTransferFrom() - 複数トークンの署名による一括転送

#### 3. Nonce Bitmap（Nonce ビットマップ）のテスト

基本機能テスト：

- testLowNonces() - 低位 Nonce の処理
- testHighNonces() - 高位 Nonce の処理
- testNonceWordBoundary() - Nonce ワード境界の処理

無効化テスト：

- testInvalidateFullWord() - 完全なワードの無効化 NonceBitmap.t.sol:50-62
- testInvalidateNonzeroWord() - 非ゼロワードの無効化 NonceBitmap.t.sol:64-75

### 4. Token Compatibility（トークン互換性）のテスト

EIP-2612 対応テスト：

- testPermit2Full() - EIP-2612 対応トークンでの完全な Permit2 機能
- testPermit2NonPermitToken() - 非 EIP-2612 トークンでのフォールバック

特殊トークンテスト：

- testPermit2WETH9Mainnet() - WETH9 メインネットでの特別処理
- testPermit2NonPermitFallback() - フォールバック機能のテスト

### 5. 不変条件（Invariant）テスト

システム整合性テスト：

- invariant_spendNeverExceedsPermit() - 支出が許可を超えないことの検証
- invariant_balanceEqualsSpent() - 残高と支出の整合性検証
- invariant_permit2NeverHoldsBalance() - Permit2 コントラクトが残高を保持しないことの検証

### 6. 統合テスト

メインネットトークンテスト：

- 実際のメインネットトークンでの動作確認
- 署名付き Witness データでの転送テスト

## 参考文献

- [DeepWiki - Permit2](https://deepwiki.com/Uniswap/permit2)
