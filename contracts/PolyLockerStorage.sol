pragma solidity 0.5.8;

contract PolyLockerStorage {

    // Bool to switch on or off the initialization
    bool public initialized;

    // Tract the total no. of events emitted by the contract
    uint256 public noOfeventsEmitted;

    // Address of the token that used to locked by the contract i.e PolyToken contract address
    address public polyToken;

    // Controls if locking Poly lock is frozen or not
    bool public frozen;

    // Granularity available on Polymesh blockchain
    uint256 constant public TRUNCATE_SCALE = 10 ** 12; 

    // Valid address length of Polymesh blockchain
    uint256 constant public VALID_ADDRESS_LENGTH = 48; 

    // Nonce for authentication
    mapping(address => mapping(uint256 => bool)) authenticationNonce;

    // Keeping track of no. of transaction execution per block
    mapping(uint256 => uint256) public txnExecutedPerBlock;

    // Threshold gas limit i.e 4M 
    uint256 constant public MAX_GAS_LIMIT = 4 * 10 ** 6; 

    // block depth allowed (not-including the current block)
    uint256 constant public BLOCK_DEPTH = 120; // For Aldebaran

    // Threshold no. of transaction should process in last `X` blocks (i.e should be BLOCK_DEPTH)
    uint256 constant public MAX_TXN_ALLOWED = 200; // For Aldebaran

    // Unit of gas increased per transaction i.e 500K
    uint256 constant public GAS_UNIT_PENALTY = 5 * 10 ** 5;
    
    // Unit of gas required to perform operations `_lock()`
    // By analyzing the older transaction it is ~ 50,376
    uint256 constant public GAS_UINT_REQUIRED_TO_LOCK = 75000; // + 20,000 for updating the txnExecutedPerBlock[block.number]  

}
