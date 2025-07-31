// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "forge-std/console2.sol";
import "forge-std/Script.sol";
import {Permit2} from "../src/Permit2.sol";
import {IAllowanceTransfer} from "../src/interfaces/IAllowanceTransfer.sol";
import {ISignatureTransfer} from "../src/interfaces/ISignatureTransfer.sol";

/**
 * @title Script for interacting with Permit2 contract
 * @notice Tests the functionality of Permit2 contract deployed on Sepolia testnet
 * @dev Performs basic read operations and contract information verification
 */
contract InteractWithPermit2 is Script {
    // SepoliaテストネットのPermit2コントラクトアドレス
    address constant PERMIT2_ADDRESS = 0xF08f41d9f4704be54AbdDA494F7d0FE6098fa9f3;
    
    Permit2 permit2;

    function setUp() public {
        permit2 = Permit2(PERMIT2_ADDRESS);
    }

    /**
     * @notice Retrieves and displays basic information about Permit2 contract
     * @dev Gets DOMAIN_SEPARATOR, chain info, and block info
     */
    function run() public view {
        console2.log("=== Permit2 Contract Basic Information ===");
        console2.log("Contract Address:", address(permit2));
        
        // Get DOMAIN_SEPARATOR
        bytes32 domainSeparator = permit2.DOMAIN_SEPARATOR();
        console2.log("DOMAIN_SEPARATOR:");
        console2.logBytes32(domainSeparator);
        
        // Check network information
        console2.log("Current Chain ID:", block.chainid);
        console2.log("Current Block Number:", block.number);
        console2.log("Current Timestamp:", block.timestamp);
        
        // EIP-712ドメインセパレーターの詳細分析
        analyzeDomainSeparator();
        
        // Contract size information
        checkContractSize();
        
        console2.log("=== Basic Information Retrieval Complete ===");
    }

    /**
     * @notice Check allowance information for a specific account
     * @param owner Token owner address
     * @param token ERC20 token address
     * @param spender Address with spending permission
     */
    function checkAllowance(address owner, address token, address spender) public view {
        console2.log("=== Allowance Information Check ===");
        console2.log("Owner:", owner);
        console2.log("Token:", token);
        console2.log("Spender:", spender);
        
        // Get allowance information
        (uint160 amount, uint48 expiration, uint48 nonce) = permit2.allowance(owner, token, spender);
        
        console2.log("Allowance Amount:", amount);
        console2.log("Expiration:", expiration);
        console2.log("Nonce:", nonce);
        
        // Expiration details
        if (expiration == 0) {
            console2.log("Status: No allowance");
        } else if (expiration < block.timestamp) {
            console2.log("Status: Expired");
        } else {
            console2.log("Status: Valid");
            console2.log("Time remaining (seconds):", expiration - block.timestamp);
        }
    }

    /**
     * @notice Check unordered nonce usage status
     * @param owner Address
     * @param word Bitmap word position
     */
    function checkNonceBitmap(address owner, uint256 word) public view {
        console2.log("=== Nonce Bitmap Check ===");
        console2.log("Address:", owner);
        console2.log("Word Position:", word);
        
        uint256 bitmap = permit2.nonceBitmap(owner, word);
        console2.log("Bitmap Value:", bitmap);
        console2.logBytes32(bytes32(bitmap));
        
        // Count bits (used nonces)
        uint256 usedNonces = countSetBits(bitmap);
        console2.log("Used Nonces Count:", usedNonces);
    }

    /**
     * @notice Detailed analysis of EIP-712 format domain separator
     */
    function analyzeDomainSeparator() internal view {
        bytes32 domainSeparator = permit2.DOMAIN_SEPARATOR();
        
        console2.log("=== DOMAIN_SEPARATOR Detailed Analysis ===");
        
        // 期待されるドメインセパレーターを計算
        bytes32 typeHash = keccak256("EIP712Domain(string name,uint256 chainId,address verifyingContract)");
        bytes32 nameHash = keccak256("Permit2");
        bytes32 expectedDomainSeparator = keccak256(
            abi.encode(typeHash, nameHash, block.chainid, PERMIT2_ADDRESS)
        );
        
        console2.log("Actual Value:");
        console2.logBytes32(domainSeparator);
        console2.log("Expected Value:");
        console2.logBytes32(expectedDomainSeparator);
        console2.log("Match:", domainSeparator == expectedDomainSeparator);
    }

    /**
     * @notice Check contract bytecode size
     */
    function checkContractSize() internal view {
        uint256 size;
        assembly {
            size := extcodesize(PERMIT2_ADDRESS)
        }
        console2.log("=== Contract Information ===");
        console2.log("Bytecode Size:", size, "bytes");
        console2.log("Max Size (24KB):", 24576, "bytes");
        
        if (size > 0) {
            console2.log("Remaining Capacity:", 24576 - size, "bytes");
            console2.log("Usage Rate:", (size * 100) / 24576, "%");
        }
    }

    /**
     * @notice Count set bits in bitmap
     * @param bitmap Target bitmap
     * @return Number of set bits
     */
    function countSetBits(uint256 bitmap) internal pure returns (uint256) {
        uint256 count = 0;
        while (bitmap != 0) {
            count += bitmap & 1;
            bitmap >>= 1;
        }
        return count;
    }

    /**
     * @notice Get common test token addresses on Sepolia testnet
     * @return Array of test token addresses
     */
    function getTestTokenAddresses() public pure returns (address[] memory) {
        address[] memory tokens = new address[](3);
        tokens[0] = 0x7b79995e5f793A07Bc00c21412e50Ecae098E7f9; // WETH on Sepolia
        tokens[1] = 0x779877A7B0D9E8603169DdbD7836e478b4624789; // LINK on Sepolia
        tokens[2] = 0x1f9840a85d5aF5bf1D1762F925BDADdC4201F984; // UNI on Sepolia (例)
        return tokens;
    }

    /**
     * @notice Batch check allowance information for multiple test tokens
     * @param owner Owner address
     * @param spender Spender address
     */
    function checkMultipleTokenAllowances(address owner, address spender) public view {
        console2.log("=== Multiple Token Allowance Batch Check ===");
        
        address[] memory tokens = getTestTokenAddresses();
        
        for (uint256 i = 0; i < tokens.length; i++) {
            console2.log("");
            console2.log("--- Token", i + 1, "---");
            checkAllowance(owner, tokens[i], spender);
        }
    }
}
