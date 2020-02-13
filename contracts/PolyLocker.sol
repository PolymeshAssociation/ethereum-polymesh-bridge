pragma solidity 0.5.8;

// Requirements 

// Any POLY holder can lock POLY (Issuers, Investors, WL, Polymath Founders, etc.)
// Attempt to lock coins other than POLY must fail
// The amount of POLY to be locked must be >0, otherwise, fail with insufficient funds
// There is no MAX to how much POLY can be locked
// SC must be upgradable based on a time-lock
// POLY will be locked forever, no one can unlock it
// Granularity for locked POLY should be restricted to Polymesh granularity (10^6)
// User must provide their Mesh address when locking POLY
// Emit an event for locked POLY including Mesh address & timestamp
// Mesh address must be valid [needs research to see if we can verify Polymesh account checksum in Ethereum]
// Ideally allow meta-transactions so that exchanges etc. could action on behalf of users.
// User should sign data with their Polymesh address like “I agree that transferring POLY is a one-way process and can’t be reversed”
// - this ensures that they def. control their Polymesh account. [needs research to see if we can verify Polymesh signed data in Ethereum]

import "openzeppelin-solidity/contracts/token/ERC20/IERC20.sol";
import "openzeppelin-solidity/contracts/math/SafeMath.sol";
import "openzeppelin-solidity/contracts/cryptography/ECDSA.sol";
import "./PolyLockerStorage.sol";

/**
 * @title Contract used to lock POLY corresponds to locked amount user can claim same
 * amount of POLY on Polymesh blockchain
 */

contract PolyLocker is PolyLockerStorage {

    using SafeMath for uint256;
    using ECDSA for bytes32;

    // Emit an event when the poly gets lock
    event PolyLocked(uint256 indexed _id, address indexed _holder, string _meshAddress, uint256 _value);

    constructor () public  {
    }

    /**
     * @notice Used for locking the POLY token
     * @param _meshAddress Address that compatible the Polymesh blockchain
     */
    function lock(string calldata _meshAddress) external {
        _lock(_meshAddress, msg.sender, IERC20(polyToken).balanceOf(msg.sender));
    }

    /**
     * @notice Used for locking the POLY token
     * @param _meshAddress Address that compatible the Polymesh blockchain
     * @param _lockedValue Amount of tokens need to locked
     */
    function limitLock(string calldata _meshAddress, uint256 _lockedValue) external {
        require(IERC20(polyToken).balanceOf(msg.sender) > uint256(0), "Insufficient funds");
        _lock(_meshAddress, msg.sender, _lockedValue);
    }

    /**
     * @notice Used for locking the POLY using the off chain data blob
     * @param _meshAddress Address that compatible the Polymesh blockchain
     * @param _holder Ethereum address of the token holder
     * @param _value Amount of tokens need to locked
     * @param _data Off chain data blob used for signer validation
     */
    function lockWithData(string calldata _meshAddress, address _holder, uint256 _value, bytes calldata _data) external {
        address targetAddress;
        string memory meshAddress;
        uint256 lockedValue;
        uint256 nonce;
        bytes memory signature;
        (targetAddress, meshAddress, lockedValue, nonce, signature) = abi.decode(_data, (address, string, uint256, uint256, bytes));
        require(_holder != address(0), "Invalid address");
        require(targetAddress == address(this), "Invalid target address");
        require(lockedValue == _value, "Invalid amount of tokens");
        require(keccak256(abi.encodePacked(meshAddress)) == keccak256(abi.encodePacked(_meshAddress)), "Invalid mesh address");
        require(authenticationNonce[_holder][nonce] == false, "Already used signature");
        bytes32 hash = keccak256(abi.encodePacked(this, meshAddress, lockedValue, nonce));
        require(hash.toEthSignedMessageHash().recover(signature) == _holder, "Incorrect Signer"); 
        // Invalidate the nonce
        authenticationNonce[_holder][nonce] = true;
        require(IERC20(polyToken).balanceOf(_holder) > uint256(0), "Insufficient funds");
        _lock(_meshAddress, _holder, lockedValue);
    }

    function _lock(string memory _meshAddress, address _holder, uint256 _senderBalance) internal {
        // Validate the MESH address
        require(bytes(_meshAddress).length == VALID_ADDRESS_LENGTH, "Invalid length of mesh address");
        // Check the valid granularity, It should be 10^9 if not then transfer only 10^9 granularity funds
        // rest will reamin as dust in the sender account
        if (_senderBalance % VALID_GRANULARITY != 0) {
            _senderBalance = _senderBalance.div(VALID_GRANULARITY);
            _senderBalance = _senderBalance.mul(VALID_GRANULARITY);
        }
        // Check whether the senderBalance is greater than 0 or not
        require(_senderBalance > uint256(0), "Invalid locked amount");
        // Transfer funds to the contract
        require(IERC20(polyToken).transferFrom(_holder, address(this), _senderBalance), "Insufficient allowance");
        emit PolyLocked(noOfeventsEmitted, _holder, _meshAddress, _senderBalance);
        noOfeventsEmitted = noOfeventsEmitted + 1;  // Increment the event counter
    }
    
}