pragma solidity 0.5.8;

contract PolyLockerStorage {

    uint256 public noOfeventsEmitted;
    address public polyToken;
    uint256 constant public TRUNCATE_SCALE = 10 ** 12; // Granularity available on Polymesh blockchain
    uint256 constant public VALID_ADDRESS_LENGTH = 48; // Valid address length of Polymesh blockchain
    mapping(address => mapping(uint256 => bool)) authenticationNonce; // Nonce for authentication
    bool public frozen; //Controls if locking Poly is frozen or not

    // Threshold gas limit i.e 4M 
    uint256 constant public MAX_GAS_LIMIT = 4 * 10 ** 6; 

    // block depth allowed (not-including the current block)
    uint256 constant public BLOCK_DEPTH = 6;

    // Threshold no. of transaction should process in last `X` blocks (i.e should be BLOCK_DEPTH)
    uint256 constant public MAX_TXN_ALLOWED = 5;

    // Unit of gas increased per transaction i.e 500K
    uint256 constant public GAS_UNIT_PENALTY = 5 * 10 ** 5;
    
    // Unit of gas required to perform operations `_lock()`
    // By analyzing the older transaction it is ~ 50,376
    uint256 constant public GAS_UINT_REQUIRED_TO_LOCK = 75000; // + 20,000 for updating the txnExecutedPerBlock[block.number]  

    // Keeping track of no. of transaction execution per block
    mapping(uint256 => uint256) public txnExecutedPerBlock;
}
