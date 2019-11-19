pragma solidity ^0.5.8;

contract PolyLockerStorage {
    
    address constant public polyToken = 0x9992eC3cF6A55b00978cdDF2b27BC6882d88D1eC;
    uint256 constant public VALID_GRANULARITY = 10 ** 9;
    mapping(address => mapping(uint256 => bool)) authenticationNonce;
}