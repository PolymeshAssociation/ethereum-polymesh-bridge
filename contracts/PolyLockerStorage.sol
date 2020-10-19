pragma solidity 0.5.8;

contract PolyLockerStorage {
    // Tracks the total no. of events emitted by the contract.
    uint256 public noOfeventsEmitted;

    // Address of the token that is locked by the contract. i.e. PolyToken contract address.
    address public polyToken;

    // Controls if locking Poly is frozen.
    bool public frozen;

    // Granularity Polymesh blockchain in 10^6 but it's 10^18 on Ethereum.
    // This is used to truncate 18 decimal places to 6.
    uint256 constant public TRUNCATE_SCALE = 10 ** 12;

    // Valid address length of Polymesh blockchain.
    uint256 constant public VALID_ADDRESS_LENGTH = 48;

    uint256 constant internal E18 = uint256(10) ** 18;

    // Nonce for authentication.
    mapping(address => mapping(uint256 => bool)) authenticationNonce;
}
