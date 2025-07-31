# Permit2 Contract Interaction Guide

Sepolia テストネットにデプロイされた Permit2 コントラクトと相互作用するためのスクリプト集です。

## 📁 作成されたファイル

### スクリプトファイル

- `script/InteractWithPermit2.s.sol` - 基本的な情報取得と許可確認
- `script/TestPermit2Advanced.s.sol` - 高度な機能テスト（EIP-712、型ハッシュ等）
- `script/TestTokenInteraction.s.sol` - 実際のトークンとの相互作用テスト

### 実行ヘルパー

- `run_permit2_tests.bat` - Windows バッチファイル
- `run_permit2_tests.ps1` - PowerShell スクリプト
- `env.example` - 環境設定のサンプル

## 🚀 使用方法

### 1. 環境設定

1. `env.example`を`.env`にコピー

```bash
copy env.example .env
```

2. `.env`ファイルを編集して RPC URL を設定

```
RPC_URL=https://sepolia.infura.io/v3/YOUR_PROJECT_ID
```

### 2. スクリプトの実行

#### PowerShell を使用する場合

```powershell
.\run_permit2_tests.ps1
```

#### コマンドプロンプトを使用する場合

```cmd
run_permit2_tests.bat
```

#### 個別のスクリプトを直接実行する場合

```bash
# 基本情報取得
forge script --rpc-url $RPC_URL script/InteractWithPermit2.s.sol:InteractWithPermit2 --sig "run()"

# 高度な機能テスト
forge script --rpc-url $RPC_URL script/TestPermit2Advanced.s.sol:TestPermit2Advanced --sig "run()"

# トークン相互作用テスト
forge script --rpc-url $RPC_URL script/TestTokenInteraction.s.sol:TestTokenInteraction --sig "run()"
```

## 📋 スクリプト機能一覧

### InteractWithPermit2.s.sol

- ✅ コントラクト基本情報の取得
- ✅ DOMAIN_SEPARATOR の確認
- ✅ 特定アドレスの許可情報確認
- ✅ ナンスビットマップの確認
- ✅ 複数トークンの一括許可確認

### TestPermit2Advanced.s.sol

- ✅ EIP-712 構造の詳細分析
- ✅ 各種型ハッシュの確認
- ✅ 署名構造のデモンストレーション
- ✅ ナンス管理システムの分析
- ✅ コントラクト継承構造の表示

### TestTokenInteraction.s.sol

- ✅ Sepolia テストネット上のトークン情報取得
- ✅ トークン残高と Permit2 許可の確認
- ✅ 複数アカウントでの一括テスト
- ✅ ガス効率の分析
- ✅ セキュリティ考慮事項の表示

## 🔧 主要な関数

### 基本情報取得

```solidity
// コントラクト基本情報
function run() public view

// 許可情報確認
function checkAllowance(address owner, address token, address spender) public view

// ナンスビットマップ確認
function checkNonceBitmap(address owner, uint256 word) public view
```

### 高度な分析

```solidity
// EIP-712構造分析
function analyzeEIP712Structure() internal view

// 型ハッシュ分析
function analyzeTypeHashes() internal pure

// ナンスシステム分析
function analyzeNonceSystem(address testAddress) public view
```

### トークン相互作用

```solidity
// トークン情報分析
function analyzeTokenInfo(address tokenAddress, string memory tokenName) public view

// 残高確認
function checkTokenBalance(address account, address tokenAddress, string memory tokenName) public view

// Permit2統合テスト
function testPermit2Integration(address testAccount, address tokenAddress) public view
```

## 📊 テスト対象のコントラクト情報

- **Permit2 コントラクト**: `0x000000000022D473030F116dDEE9F6B43aC78BA3`
- **ネットワーク**: Sepolia Testnet (Chain ID: 11155111)
- **テストトークン**:
  - WETH: `0x7b79995e5f793A07Bc00c21412e50Ecae098E7f9`
  - LINK: `0x779877A7B0D9E8603169DdbD7836e478b4624789`

## 🔍 確認できる情報

1. **基本情報**

   - DOMAIN_SEPARATOR
   - チェーン ID
   - ブロック情報
   - コントラクトサイズ

2. **許可情報**

   - 許可量
   - 有効期限
   - ナンス
   - 許可状態

3. **EIP-712 情報**

   - 型ハッシュ
   - ドメインセパレーター構造
   - 署名構造

4. **トークン情報**
   - 残高
   - 許可状況
   - 基本的な ERC20 情報

## ⚠️ 注意事項

- テスト用の RPC URL とプライベートキーのみを使用してください
- 実際の資金が入ったアカウントは使用しないでください
- `.env`ファイルを`.gitignore`に追加して秘密情報を保護してください
- Sepolia テストネット上でのみ動作します

## 🆘 トラブルシューティング

### RPC URL が設定されていない

```
エラー: RPC_URL環境変数が設定されていません
```

→ `.env`ファイルに RPC URL を設定してください

### コントラクトが見つからない

```
Contract not found
```

→ RPC URL が正しいか確認してください（Sepolia テストネット用）

### ガス不足

```
insufficient funds for gas
```

→ テストアカウントに Sepolia の ETH が必要です（フォーセットから取得）

## 📚 参考資料

- [Permit2 Documentation](https://docs.uniswap.org/contracts/permit2/overview)
- [EIP-712 Standard](https://eips.ethereum.org/EIPS/eip-712)
- [Foundry Documentation](https://book.getfoundry.sh/)
- [Sepolia Testnet Faucet](https://sepoliafaucet.com/)

---

このスクリプト集を使用して、Permit2 コントラクトの機能を安全にテストし、理解を深めてください！
