# permit2

Permit2 introduces a low-overhead, next-generation token approval/meta-tx system to make token approvals easier, more secure, and more consistent across applications.

## Features

- **Signature Based Approvals**: Any ERC20 token, even those that do not support [EIP-2612](https://eips.ethereum.org/EIPS/eip-2612), can now use permit style approvals. This allows applications to have a single transaction flow by sending a permit signature along with the transaction data when using `Permit2` integrated contracts.
- **Batched Token Approvals**: Set permissions on different tokens to different spenders with one signature.
- **Signature Based Token Transfers**: Owners can sign messages to transfer tokens directly to signed spenders, bypassing setting any allowance. This means that approvals aren't necessary for applications to receive tokens and that there will never be hanging approvals when using this method. The signature is valid only for the duration of the transaction in which it is spent.
- **Batched Token Transfers**: Transfer different tokens to different recipients with one signature.
- **Safe Arbitrary Data Verification**: Verify any extra data by passing through a witness hash and witness type. The type string must follow the [EIP-712](https://eips.ethereum.org/EIPS/eip-712) standard.
- **Signature Verification for Contracts**: All signature verification supports [EIP-1271](https://eips.ethereum.org/EIPS/eip-1271) so contracts can approve tokens and transfer tokens through signatures.
- **Non-monotonic Replay Protection**: Signature based transfers use unordered, non-monotonic nonces so that signed permits do not need to be transacted in any particular order.
- **Expiring Approvals**: Approvals can be time-bound, removing security concerns around hanging approvals on a wallet’s entire token balance. This also means that revoking approvals do not necessarily have to be a new transaction since an approval that expires will no longer be valid.
- **Batch Revoke Allowances**: Remove allowances on any number of tokens and spenders in one transaction.

## Architecture

Permit2 is the union of two contracts: [`AllowanceTransfer`](https://github.com/Uniswap/permit2/blob/main/src/AllowanceTransfer.sol) and [`SignatureTransfer`](https://github.com/Uniswap/permit2/blob/main/src/SignatureTransfer.sol).

The `SignatureTransfer` contract handles all signature-based transfers, meaning that an allowance on the token is bypassed and permissions to the spender only last for the duration of the transaction that the one-time signature is spent.

The `AllowanceTransfer` contract handles setting allowances on tokens, giving permissions to spenders on a specified amount for a specified duration of time. Any transfers that then happen through the `AllowanceTransfer` contract will only succeed if the proper permissions have been set.

## Integrating with Permit2

Before integrating, contracts can request users’ tokens through `Permit2`, users must approve the `Permit2` contract through the specific token contract. To see a detailed technical reference, visit the Uniswap [documentation site](https://docs.uniswap.org/contracts/permit2/overview).

### Note on viaIR compilation

Permit2 uses viaIR compilation, so importing and deploying it in an integration for tests will require the integrating repository to also use viaIR compilation. This is often quite slow, so can be avoided using the precompiled `DeployPermit2` utility:

```
import {DeployPermit2} from "permit2/test/utils/DeployPermit2.sol";

contract MyTest is DeployPermit2 {
    address permit2;

    function setUp() public {
        permit2 = deployPermit2();
    }
}
```

## Bug Bounty

This repository is subject to the Uniswap Labs Bug Bounty program, per the terms defined [here](https://uniswap.org/bug-bounty).

## Contributing

You will need a copy of [Foundry](https://github.com/foundry-rs/foundry) installed before proceeding. See the [installation guide](https://github.com/foundry-rs/foundry#installation) for details.

### Setup

```sh
git clone https://github.com/Uniswap/permit2.git
cd permit2
forge install
```

```bash
cp .env.example .env
```

### Lint

```sh
forge fmt [--check]
```

### Run Tests

```sh
# unit
forge test

# integration
source .env
FOUNDRY_PROFILE=integration forge test
```

テストの実行結果

```bash
[⠒] Compiling...
[⠢] Compiling 79 files with Solc 0.8.17
[⠑] Solc 0.8.17 finished in 594.29s

Ran 2 tests for test/CompactSignature.t.sol:CompactSignature
[PASS] testCompactSignature27() (gas: 300)
[PASS] testCompactSignature28() (gas: 144)
Suite result: ok. 2 passed; 0 failed; 0 skipped; finished in 24.14ms (3.23ms CPU time)

Ran 2 tests for test/EIP712.t.sol:EIP712Test
[PASS] testDomainSeparator() (gas: 5881)
[PASS] testDomainSeparatorAfterFork() (gas: 10830)
Suite result: ok. 2 passed; 0 failed; 0 skipped; finished in 25.04ms (2.48ms CPU time)

Ran 1 test for test/mocks/MockPermit2Lib.sol:MockPermit2Lib
[PASS] testPermit2Code(address) (runs: 256, μ: 3016, ~: 3016)
Suite result: ok. 1 passed; 0 failed; 0 skipped; finished in 66.16ms (45.65ms CPU time)

Ran 3 tests for test/utils/DeployPermit2.t.sol:DeployPermit2Test
[PASS] testAllowanceTransferSanityCheck() (gas: 101876)
[PASS] testDeployPermit2() (gas: 4337527)
[PASS] testSignatureTransferSanityCheck() (gas: 92792)
Suite result: ok. 3 passed; 0 failed; 0 skipped; finished in 88.70ms (62.76ms CPU time)

Ran 10 tests for test/TypehashGeneration.t.sol:TypehashGeneration
[PASS] testPermitBatch() (gas: 40473)
[PASS] testPermitBatchTransferFrom() (gas: 49837)
[PASS] testPermitBatchTransferFromWithWitness() (gas: 56621)
[PASS] testPermitBatchTransferFromWithWitnessIncorrectPermitData() (gas: 56744)
[PASS] testPermitBatchTransferFromWithWitnessIncorrectTypehashStub() (gas: 57353)
[PASS] testPermitSingle() (gas: 28138)
[PASS] testPermitTransferFrom() (gas: 36511)
[PASS] testPermitTransferFromWithWitness() (gas: 43469)
[PASS] testPermitTransferFromWithWitnessIncorrectPermitData() (gas: 43436)
[PASS] testPermitTransferFromWithWitnessIncorrectTypehashStub() (gas: 43956)
Suite result: ok. 10 passed; 0 failed; 0 skipped; finished in 15.78ms (13.73ms CPU time)

Ran 29 tests for test/Permit2Lib.t.sol:Permit2LibTest
[PASS] testOZSafePermit() (gas: 24682)
[PASS] testOZSafePermitPlusOZSafeTransferFrom() (gas: 129329)
[PASS] testOZSafeTransferFrom() (gas: 39007)
[PASS] testPermit2() (gas: 22941)
[PASS] testPermit2DSLessToken() (gas: 7143)
[PASS] testPermit2DSMore32Token() (gas: 7252)
[PASS] testPermit2DSMoreToken() (gas: 7023)
[PASS] testPermit2Full() (gas: 42356)
[PASS] testPermit2InvalidAmount() (gas: 21011)
[PASS] testPermit2LargerDS() (gas: 51464)
[PASS] testPermit2LargerDSRevert() (gas: 32841)
[PASS] testPermit2NonPermitFallback() (gas: 37245)
[PASS] testPermit2NonPermitToken() (gas: 32164)
[PASS] testPermit2PlusTransferFrom2() (gas: 126995)
[PASS] testPermit2PlusTransferFrom2WithNonPermit() (gas: 148221)
[PASS] testPermit2PlusTransferFrom2WithNonPermitFallback() (gas: 174749)
[PASS] testPermit2PlusTransferFrom2WithWETH9Mainnet() (gas: 147934)
[PASS] testPermit2SmallerDS() (gas: 77688)
[PASS] testPermit2SmallerDSNoRevert() (gas: 59324)
[PASS] testPermit2WETH9Mainnet() (gas: 28774)
[PASS] testSimplePermit2() (gas: 29117)
[PASS] testSimplePermit2InvalidAmount() (gas: 16944)
[PASS] testSimplePermit2PlusTransferFrom2WithNonPermit() (gas: 148463)
[PASS] testStandardPermit() (gas: 22535)
[PASS] testStandardTransferFrom() (gas: 38143)
[PASS] testTransferFrom2() (gas: 38734)
[PASS] testTransferFrom2Full() (gas: 53368)
[PASS] testTransferFrom2InvalidAmount() (gas: 12732)
[PASS] testTransferFrom2NonPermitToken() (gas: 53170)
Suite result: ok. 29 passed; 0 failed; 0 skipped; finished in 433.00ms (57.04ms CPU time)

Ran 28 tests for test/AllowanceTransferTest.t.sol:AllowanceTransferTest
[PASS] testApprove() (gas: 47570)
[PASS] testBatchTransferFrom() (gas: 159197)
[PASS] testBatchTransferFromDifferentOwners() (gas: 235094)
[PASS] testBatchTransferFromMultiToken() (gas: 231841)
[PASS] testBatchTransferFromWithGasSnapshot() (gas: 159857)
[PASS] testExcessiveInvalidation() (gas: 64205)
[PASS] testInvalidateMultipleNonces() (gas: 83150)
[PASS] testInvalidateNonces() (gas: 65347)
[PASS] testInvalidateNoncesInvalid() (gas: 16327)
[PASS] testLockdown() (gas: 145984)
[PASS] testLockdownEvent() (gas: 117749)
[PASS] testMaxAllowance() (gas: 134888)
[PASS] testMaxAllowanceDirtyWrite() (gas: 117455)
[PASS] testPartialAllowance() (gas: 105140)
[PASS] testReuseOrderedNonceInvalid() (gas: 69154)
[PASS] testSetAllowance() (gas: 89627)
[PASS] testSetAllowanceBatch() (gas: 133740)
[PASS] testSetAllowanceBatchDifferentNonces() (gas: 118603)
[PASS] testSetAllowanceBatchDirtyWrite() (gas: 99210)
[PASS] testSetAllowanceBatchEvent() (gas: 116049)
[PASS] testSetAllowanceCompactSig() (gas: 89587)
[PASS] testSetAllowanceDeadlinePassed() (gas: 56512)
[PASS] testSetAllowanceDirtyWrite() (gas: 72175)
[PASS] testSetAllowanceIncorrectSigLength() (gas: 29198)
[PASS] testSetAllowanceInvalidSignature() (gas: 64065)
[PASS] testSetAllowanceTransfer() (gas: 103115)
[PASS] testSetAllowanceTransferDirtyNonceDirtyTransfer() (gas: 97194)
[PASS] testTransferFromWithGasSnapshot() (gas: 132867)
Suite result: ok. 28 passed; 0 failed; 0 skipped; finished in 434.05ms (116.16ms CPU time)

Ran 25 tests for test/SignatureTransfer.t.sol:SignatureTransferTest
[PASS] testCorrectWitnessTypehashes() (gas: 3091)
[PASS] testGasMultiplePermitBatchTransferFrom() (gas: 270972)
[PASS] testGasSinglePermitBatchTransferFrom() (gas: 183860)
[PASS] testGasSinglePermitTransferFrom() (gas: 123854)
[PASS] testInvalidateUnorderedNonces() (gas: 41396)
[PASS] testPermitBatchMultiPermitSingleTransfer() (gas: 133675)
[PASS] testPermitBatchTransferFrom() (gas: 162019)
[PASS] testPermitBatchTransferFromSingleRecipient() (gas: 187957)
[PASS] testPermitBatchTransferFromTypedWitness() (gas: 240010)
[PASS] testPermitBatchTransferFromTypedWitnessInvalidType() (gas: 84503)
[PASS] testPermitBatchTransferFromTypedWitnessInvalidTypeHash() (gas: 86007)
[PASS] testPermitBatchTransferFromTypedWitnessInvalidWitness() (gas: 85835)
[PASS] testPermitBatchTransferInvalidAmountsLengthMismatch() (gas: 41574)
[PASS] testPermitBatchTransferMultiAddr() (gas: 160547)
[PASS] testPermitBatchTransferSingleRecipientManyTokens() (gas: 209422)
[PASS] testPermitTransferFrom() (gas: 92909)
[PASS] testPermitTransferFromCompactSig() (gas: 124059)
[PASS] testPermitTransferFromIncorrectSigLength() (gas: 51346)
[PASS] testPermitTransferFromInvalidNonce() (gas: 72928)
[PASS] testPermitTransferFromRandomNonceAndAmount(uint256,uint128) (runs: 256, μ: 96195, ~: 96728)
[PASS] testPermitTransferFromToSpender() (gas: 93283)
[PASS] testPermitTransferFromTypedWitness() (gas: 125096)
[PASS] testPermitTransferFromTypedWitnessInvalidType() (gas: 55884)
[PASS] testPermitTransferFromTypedWitnessInvalidTypehash() (gas: 56879)
[PASS] testPermitTransferSpendLessThanFull(uint256,uint128) (runs: 256, μ: 99101, ~: 99733)
Suite result: ok. 25 passed; 0 failed; 0 skipped; finished in 838.25ms (1.03s CPU time)

Ran 9 tests for test/NonceBitmap.t.sol:NonceBitmapTest
[PASS] testHighNonces() (gas: 36305)
[PASS] testInvalidateFullWord() (gas: 63061)
[PASS] testInvalidateNoncesRandomly(uint248,uint256) (runs: 256, μ: 31061, ~: 31139)
[PASS] testInvalidateNonzeroWord() (gas: 85642)
[PASS] testInvalidateTwoNoncesRandomly(uint248,uint256,uint256) (runs: 256, μ: 39182, ~: 39182)
[PASS] testLowNonces() (gas: 41041)
[PASS] testNonceWordBoundary() (gas: 42284)
[PASS] testUseTwoRandomNonces(uint256,uint256) (runs: 256, μ: 51368, ~: 51625)
[PASS] testUsingNonceTwiceFails(uint256) (runs: 256, μ: 21938, ~: 21955)
Suite result: ok. 9 passed; 0 failed; 0 skipped; finished in 81.36s (306.96ms CPU time)

Ran 3 tests for test/AllowanceUnitTest.sol:AllowanceUnitTest
[PASS] testPackAndUnpack(uint160,uint48,uint48) (runs: 256, μ: 39103, ~: 39103)
[PASS] testUpdateAllRandomly(uint160,uint48,uint48) (runs: 256, μ: 40243, ~: 40244)
[PASS] testUpdateAmountExpirationRandomly(uint160,uint48) (runs: 256, μ: 39169, ~: 39170)
Suite result: ok. 3 passed; 0 failed; 0 skipped; finished in 81.38s (279.43ms CPU time)

Ran 3 tests for test/AllowanceTransferInvariants.t.sol:AllowanceTransferInvariants
[PASS] invariant_balanceEqualsSpent() (runs: 256, calls: 128000, reverts: 18971)
[PASS] invariant_permit2NeverHoldsBalance() (runs: 256, calls: 128000, reverts: 19081)
[PASS] invariant_spendNeverExceedsPermit() (runs: 256, calls: 128000, reverts: 19012)
Suite result: ok. 3 passed; 0 failed; 0 skipped; finished in 89.50s (246.83s CPU time)

Ran 11 test suites in 89.53s (254.16s CPU time): 115 tests passed, 0 failed, 0 skipped (115 total tests)
```

### Update Gas Snapshots

```sh
forge snapshot
```

### Deploy

Run the command below. Remove `--broadcast`, `---rpc-url`, `--private-key` and `--verify` options to test locally

デプロイが失敗するときは Salt の値を変更して再度実行すること。

```sh
source .env
forge script --broadcast --rpc-url $RPC_URL --private-key $PRIVATE_KEY --verify script/DeployPermit2.s.sol:DeployPermit2
```

[実際にデプロイしたコントラクト - sepolia](https://sepolia.etherscan.io/address/0xF08f41d9f4704be54AbdDA494F7d0FE6098fa9f3)

### Scripts

テストネットにデプロイしたコントラクトの機能を呼び出す

```bash
# 基本情報取得
forge script --rpc-url $RPC_URL script/InteractWithPermit2.s.sol:InteractWithPermit2 --sig "run()"
```

実行結果例

```bash
== Logs ==
  === Permit2 Contract Basic Information ===
  Contract Address: 0xF08f41d9f4704be54AbdDA494F7d0FE6098fa9f3
  DOMAIN_SEPARATOR:
  0x4f1a4196777181df9c428e0f364fa64da55307905d030f9c95ffac7d93bcd582
  Current Chain ID: 11155111
  Current Block Number: 8881412
  Current Timestamp: 1753952604
  === DOMAIN_SEPARATOR Detailed Analysis ===
  Actual Value:
  0x4f1a4196777181df9c428e0f364fa64da55307905d030f9c95ffac7d93bcd582
  Expected Value:
  0x4f1a4196777181df9c428e0f364fa64da55307905d030f9c95ffac7d93bcd582
  Match: true
  === Contract Information ===
  Bytecode Size: 9152 bytes
  Max Size (24KB): 24576 bytes
  Remaining Capacity: 15424 bytes
  Usage Rate: 37 %
  === Basic Information Retrieval Complete ===

```

````bash
```bash
# 高度な機能テスト
forge script --rpc-url $RPC_URL script/TestPermit2Advanced.s.sol:TestPermit2Advanced --sig "run()"
````

署名の設定や検証、型ハッシュの確認などを行います。

```bash
# トークン相互作用テスト
forge script --rpc-url $RPC_URL script/TestTokenInteraction.s.sol:TestTokenInteraction --sig "run()"
```

各トークンの残高や許可状況を確認することが可能

```bash
# Token swap demo with Permit2
forge script --rpc-url $RPC_URL script/SwapWithPermit2.s.sol:SwapWithPermit2 --sig "run()"
```

Permit2 を使用したトークンスワップのデモンストレーション

```bash
# Deploy SimpleDEX contract
forge script script/DeployAndUseSimpleDEX.s.sol:DeployAndUseSimpleDEX --sig 'deployDEX()' --rpc-url $RPC_URL --private-key $PRIVATE_KEY --broadcast

# Add liquidity to DEX (set DEX_ADDRESS environment variable first)
export DEX_ADDRESS=0x... # Address from deployment above
forge script script/DeployAndUseSimpleDEX.s.sol:DeployAndUseSimpleDEX --sig 'addLiquidity()' --rpc-url $RPC_URL --private-key $PRIVATE_KEY --broadcast

# Execute token swap
forge script script/DeployAndUseSimpleDEX.s.sol:DeployAndUseSimpleDEX --sig 'executeSwap()' --rpc-url $RPC_URL --private-key $PRIVATE_KEY --broadcast
```

実際のトークンスワップを実行するための完全なワークフロー

### Uniswap V3 Integration

Sepolia テストネットの Uniswap V3 を使用した実際のトークンスワップ:

```bash
# 1. Check current status and get instructions
forge script --rpc-url $RPC_URL script/UniswapV3SwapWithPermit2.s.sol:UniswapV3SwapWithPermit2 --sig "run()"

# 2. Wrap ETH to WETH (get WETH for swapping)
forge script script/UniswapV3SwapWithPermit2.s.sol:UniswapV3SwapWithPermit2 --sig 'wrapETH()' --rpc-url $RPC_URL --private-key $PRIVATE_KEY --broadcast

# 3. Approve tokens for Uniswap Router
forge script script/UniswapV3SwapWithPermit2.s.sol:UniswapV3SwapWithPermit2 --sig 'approveUniswapRouter()' --rpc-url $RPC_URL --private-key $PRIVATE_KEY --broadcast

# 4. Get swap quote (check expected output)
forge script script/UniswapV3SwapWithPermit2.s.sol:UniswapV3SwapWithPermit2 --sig 'getQuote()' --rpc-url $RPC_URL

# 5. Execute actual swap on Uniswap V3
forge script script/UniswapV3SwapWithPermit2.s.sol:UniswapV3SwapWithPermit2 --sig 'executeDirectSwap()' --rpc-url $RPC_URL --private-key $PRIVATE_KEY --broadcast
```

```bash
== Logs ==
  === Uniswap V3 + Permit2 Swap Demo ===
  Uniswap V3 Router: 0x3bFA4769FB09eefC5a80d6E87c3B9C650f7Ae48E
  Permit2 Address: 0xF08f41d9f4704be54AbdDA494F7d0FE6098fa9f3
  WETH Address: 0xfFf9976782d46CC05630D1f6eBAb18b2324d6B14
  USDC Address: 0x1c7D4B196Cb0C7B01d743Fbc6116a902379C7238
  User Account: 0x034f66d49A175438AD7Ec0111CcA18fce1A39Fa6
  === Current Balances ===
  ETH Balance: 36 ETH
  WETH Balance: 0 WETH
  USDC Balance: 1592 USDC

  === Usage Instructions ===

  Step 1: Get test ETH from Sepolia faucet
    - Visit: https://sepoliafaucet.com/
    - Get some ETH for gas and wrapping

  Step 2: Wrap ETH to WETH
  forge script script/UniswapV3SwapWithPermit2.s.sol:UniswapV3SwapWithPermit2 --sig 'wrapETH()' --rpc-url $RPC_URL --private-key $PRIVATE_KEY --broadcast

  Step 3: Approve tokens for Uniswap Router
  forge script script/UniswapV3SwapWithPermit2.s.sol:UniswapV3SwapWithPermit2 --sig 'approveUniswapRouter()' --rpc-url $RPC_URL --private-key $PRIVATE_KEY --broadcast

  Step 4: Get swap quote
  forge script script/UniswapV3SwapWithPermit2.s.sol:UniswapV3SwapWithPermit2 --sig 'getQuote()' --rpc-url $RPC_URL

  Step 5: Execute swap
  forge script script/UniswapV3SwapWithPermit2.s.sol:UniswapV3SwapWithPermit2 --sig 'executeDirectSwap()' --rpc-url $RPC_URL --private-key $PRIVATE_KEY --broadcast

  Check status anytime:
  forge script script/UniswapV3SwapWithPermit2.s.sol:UniswapV3SwapWithPermit2 --sig 'checkApprovals()' --rpc-url $RPC_URL

  === Important Notes ===
  - Make sure you have Sepolia ETH for gas fees
  - WETH/USDC pool must exist and have liquidity
  - Always check quotes before executing swaps
  - Set appropriate slippage protection in production
  === Demo Completed ===
```

### Advanced Permit2-Uniswap Integration

Permit2 と Uniswap V3 を組み合わせた高度な統合:

```bash
# 1. View advanced integration demo
forge script --rpc-url $RPC_URL script/AdvancedPermit2UniswapScript.s.sol:AdvancedPermit2UniswapScript --sig "run()"

# 2. Deploy Permit2-Uniswap integrator contract
forge script script/AdvancedPermit2UniswapScript.s.sol:AdvancedPermit2UniswapScript --sig 'deployIntegrator()' --rpc-url $RPC_URL --private-key $PRIVATE_KEY --broadcast

# 3. Set deployed integrator address
export INTEGRATOR_ADDRESS=0x... # Address from deployment above

# 4. Execute integrated swap with Permit2
source .env
forge script script/AdvancedPermit2UniswapScript.s.sol:AdvancedPermit2UniswapScript --sig 'executeIntegratedSwap()' --rpc-url $RPC_URL --private-key $PRIVATE_KEY --broadcast
```

```bash
== Logs ==
  === Advanced Permit2-Uniswap Integration Demo ===
  This script demonstrates advanced integration between
  Permit2 and Uniswap V3 for enhanced token swapping.

  === Complete Workflow ===

  Traditional approach (without Permit2):
  1. approve(router, amount) - User sets ERC20 allowance
  2. router.exactInputSingle() - Execute swap
  Total: 2 transactions

  Permit2 AllowanceTransfer approach:
  1. approve(permit2, max) - One-time ERC20 approval
  2. permit(details, signature) - Set Permit2 allowance
  3. integrator.swapWithAllowanceTransfer() - Execute swap
  First time: 3 transactions, After: 2 transactions

  Permit2 SignatureTransfer approach:
  1. approve(permit2, max) - One-time ERC20 approval
  2. integrator.swapWithSignatureTransfer() - Swap with signature
  First time: 2 transactions, After: 1 transaction

  Recommended approach: SignatureTransfer for best UX!
  === Gas Efficiency Analysis ===

  Gas costs comparison (approximate):

  Traditional Uniswap swap:
    - ERC20.approve(): ~46,000 gas
    - SwapRouter.exactInputSingle(): ~120,000 gas
    - Total: ~166,000 gas

  Permit2 + Uniswap (AllowanceTransfer):
    - ERC20.approve(permit2): ~46,000 gas (one-time)
    - Permit2.permit(): ~50,000 gas
    - Integrator swap: ~150,000 gas
    - Total first time: ~246,000 gas
    - Total subsequent: ~200,000 gas

  Permit2 + Uniswap (SignatureTransfer):
    - ERC20.approve(permit2): ~46,000 gas (one-time)
    - Integrator signature swap: ~170,000 gas
    - Total first time: ~216,000 gas
    - Total subsequent: ~170,000 gas

  Additional benefits:
    - Batch operations further reduce costs
    - Expiring permits eliminate stale approvals
    - Meta-transaction support
    - Enhanced security model
  === Signature-based Swap Demonstration ===

  To execute signature-based swap:

  1. Generate EIP-712 signature for PermitTransferFrom:
  PermitTransferFrom {
    permitted: TokenPermissions {
      token: WETH_ADDRESS,
      amount: 10000000000000000 // 0.01 WETH
    },
    spender: INTEGRATOR_ADDRESS,
    nonce: unique_nonce,
    deadline: block.timestamp + 3600
  }

  2. Call integrator.swapWithSignatureTransfer():
     - Pass the permit struct
     - Include the generated signature
     - Specify output token and parameters

  Benefits of signature-based approach:
    - One-time use only (more secure)
    - No pre-approval needed
    - Perfect for meta-transactions
    - Prevents hanging approvals

  To deploy and use the integrator:
  1. forge script script/AdvancedPermit2UniswapScript.s.sol:AdvancedPermit2UniswapScript --sig 'deployIntegrator()' --rpc-url $RPC_URL --private-key $PRIVATE_KEY --broadcast
  2. export INTEGRATOR_ADDRESS=0x... # Set deployed address
  3. forge script script/AdvancedPermit2UniswapScript.s.sol:AdvancedPermit2UniswapScript --sig 'executeIntegratedSwap()' --rpc-url $RPC_URL --private-key $PRIVATE_KEY --broadcast

  === Advanced Demo Completed ===
```

デプロイしたコントラクト

[0x0eF5680fEa0B7f2cdE256dAa6661Fa08A6c86b56](https://sepolia.etherscan.io/address/0x0eF5680fEa0B7f2cdE256dAa6661Fa08A6c86b56)

### Network Information

**Sepolia Testnet Details:**

- Chain ID: 11155111
- RPC URL: https://sepolia.infura.io/v3/YOUR_PROJECT_ID
- Explorer: https://sepolia.etherscan.io/

**Contract Addresses:**

- Permit2: `0xF08f41d9f4704be54AbdDA494F7d0FE6098fa9f3`
- Uniswap V3 Router: `0x3bFA4769FB09eefC5a80d6E87c3B9C650f7Ae48E`
- Uniswap V3 Quoter: `0xEd1f6473345F45b75F8179591dd5bA1888cf2FB3`
- WETH: `0xfFf9976782d46CC05630D1f6eBAb18b2324d6B14`
- USDC: `0x1c7D4B196Cb0C7B01d743Fbc6116a902379C7238`

**Test Token Faucets:**

- ETH: https://sepoliafaucet.com/
- Multiple tokens: https://faucet.paradigm.xyz/

````

署名の設定や検証、型ハッシュの確認などを行います。

```bash
== Logs ==
  === Permit2 Advanced Features Test ===
  === EIP-712 Structure Analysis ===
  DOMAIN_SEPARATOR:
  0x4f1a4196777181df9c428e0f364fa64da55307905d030f9c95ffac7d93bcd582
  Domain TypeHash:
  0x8cad95687ba82c2ce50e74f7b754645e5117c3a5bec8151c0726d5857980a866
  Name Hash:
  0x9ac997416e8ff9d2ff6bebeb7149f65cdae5e32e2b90440b566bb3044041d36a
  Chain ID: 11155111
  Verifying Contract: 0xF08f41d9f4704be54AbdDA494F7d0FE6098fa9f3
  === Type Hash Analysis ===
  PermitTransferFrom TypeHash:
  0x939c21a48a8dbe3a9a2404a1d46691e4d39f6583d6ec6b35714604c986d80106
  PermitBatchTransferFrom TypeHash:
  0xfcf35f5ac6a2c28868dc44c302166470266239195f02b0ee408334829333b766
  PermitSingle TypeHash:
  0xf3841cd1ff0085026a6327b620b67997ce40f282c88a8e905a7a5626e310f3d0
  PermitBatch TypeHash:
  0xaf1b0d30d2cab0380e68f0689007e3254993c596f2fdd0aaa7f4d04f79440863
  === Signature Structure Demonstration ===
  TokenPermissions Structure:
    - token: address
    - amount: uint256
  PermitDetails Structure:
    - token: address
    - amount: uint160
    - expiration: uint48
    - nonce: uint48
  TransferDetails Structure:
    - to: address
    - requestedAmount: uint256
  Key values used in signatures:
    - spender: Address authorized to spend
    - nonce: Value to prevent replay attacks
    - deadline: Signature expiration
  === Time-based Function Analysis ===
  Current timestamp: 1754009928
  Expiration after 1 hour: 1754013528
  Expiration after 1 day: 1754096328
  Expiration after 1 week: 1754614728
  Maximum expiration value: 281474976710655
  Maximum expiration datetime: 281474976710655 (Unix timestamp)
  === Advanced Features Test Completed ===
````

```bash
# トークン相互作用テスト
forge script --rpc-url $RPC_URL script/TokenInteraction.s.sol:TokenInteraction --sig "run()"
```

各トークンの残高や許可状況を確認することが可能

```bash
== Logs ==
  === Token Interaction Test ===
  Test Account: 0x7E5F4552091A69125d5DfCb7b8C2659029395Bdf
  ===  WETH  Token Information ===
  Address: 0x7b79995e5f793A07Bc00c21412e50Ecae098E7f9
  Contract Exists: Yes
  Bytecode Size: 1786 bytes
  Total Supply: 505089374605701462713928

  ===  LINK  Token Information ===
  Address: 0x779877A7B0D9E8603169DdbD7836e478b4624789
  Contract Exists: Yes
  Bytecode Size: 4282 bytes
  Total Supply: 1000000000000000000000000000

  === Permit2 Integration Test ===
  Test Account: 0x7E5F4552091A69125d5DfCb7b8C2659029395Bdf
  Test Token: 0x7b79995e5f793A07Bc00c21412e50Ecae098E7f9
  Permit2 Allowance Information:
    Amount: 0
    Expiration: 0
    Nonce: 0
    Status: No allowance set
  Nonce Bitmap (Word 0): 0

  === Batch Test Multiple Accounts ===
  --- Account 1 ---
  ===  TEST  Balance Check ===
  Account: 0x7E5F4552091A69125d5DfCb7b8C2659029395Bdf
  Balance: 0

  Permit2 Allowance Amount: 0
  --- Account 2 ---
  ===  TEST  Balance Check ===
  Account: 0x2B5AD5c4795c026514f8317c7a215E218DcCD6cF
  Balance: 0

  Permit2 Allowance Amount: 0
  --- Account 3 ---
  ===  TEST  Balance Check ===
  Account: 0x6813Eb9362372EEF6200f3b1dbC3f819671cBA69
  Balance: 0

  Permit2 Allowance Amount: 0
  === Batch Test Multiple Accounts ===
  --- Account 1 ---
  ===  TEST  Balance Check ===
  Account: 0x7E5F4552091A69125d5DfCb7b8C2659029395Bdf
  Balance: 50000000000000000000
  Allowance to Permit2: 0
  Allowance Status: None

  Permit2 Allowance Amount: 0
  --- Account 2 ---
  ===  TEST  Balance Check ===
  Account: 0x2B5AD5c4795c026514f8317c7a215E218DcCD6cF
  Balance: 25000000000000000000
  Allowance to Permit2: 0
  Allowance Status: None

  Permit2 Allowance Amount: 0
  --- Account 3 ---
  ===  TEST  Balance Check ===
  Account: 0x6813Eb9362372EEF6200f3b1dbC3f819671cBA69
  Balance: 0

  Permit2 Allowance Amount: 0
  === Token Interaction Test Completed ===
```

## Acknowledgments

Inspired by [merklejerk](https://github.com/merklejerk)'s [permit-everywhere](https://github.com/merklejerk/permit-everywhere) contracts which introduce permit based approvals for all tokens regardless of EIP2612 support.
