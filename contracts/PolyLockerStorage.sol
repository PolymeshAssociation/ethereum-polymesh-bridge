pragma solidity 0.5.8;

contract PolyLockerStorage {

    uint256 public noOfeventsEmitted;
    address public polyToken;
    //address constant public POLYTOKEN = 0x9992eC3cF6A55b00978cdDF2b27BC6882d88D1eC; // Ethereum mainnet PolyToken contract address
    uint256 constant public VALID_GRANULARITY = 10 ** 6; // Granularity available on Polymesh blockchain
    uint256 constant public VALID_ADDRESS_LENGTH = 48; // Valid address length of Polymesh blockchain
    mapping(address => mapping(uint256 => bool)) authenticationNonce; // Nonce for authentication
    bool public frozen;
}
