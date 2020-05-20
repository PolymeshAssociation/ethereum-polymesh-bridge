pragma solidity 0.5.8;

contract PolyLockerStorage {

    uint256 public noOfeventsEmitted;
    address public polyToken;
    uint256 constant public TRUNCATE_SCALE = 10 ** 12; // Granularity available on Polymesh blockchain
    uint256 constant public VALID_ADDRESS_LENGTH = 48; // Valid address length of Polymesh blockchain
    mapping(address => mapping(uint256 => bool)) authenticationNonce; // Nonce for authentication
    bool public frozen; //Controls if locking Poly is frozen or not

    // Threshold gas limit i.e 4M 
    uint256 constant public MAX_GAS_LIMIT = 4 * 10 ** 7; 

    // block depth allowed
    uint256 constant public BLOCK_DEPTH = 6;

    // Threshold no. of transaction should process in last `X` blocks (i.e should be BLOCK_DEPTH)
    uint256 constant public MAX_TXN_ALLOWED = 5;

    // Unit of gas increased per transaction i.e 500K
    uint256 constant public GAS_UNIT_PENALTY = 5 * 10 ** 5;
    
    // Unit of gas required to perform operations `lock()` or `limitLock()` 
    // By analyzing the older transaction it is ~ 50,376
    uint256 constant public GAS_UINT_REQUIRED_TO_LOCK = 55000;
    
    // Unit of gas required to perform `lockWithData()` opeartions
    // By analyzing the older transaction it is ~ 83,021
    // https://kovan.etherscan.io/tx/0x09c1a26ea13e3724e11af1c8f0739f4df126f40dfc0cf0693fee09aecfdbe808
    uint256 constant public GAS_UNIT_REQUIRED_FOR_LOCK_WITH_DATA = 85000;

    // Keeping track of no. of transaction execution per block
    mapping(uint256 => uint256) public txnExecutedPerBlock;
}
