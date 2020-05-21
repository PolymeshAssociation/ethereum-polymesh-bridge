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
import "./proxies//ProxyOwner.sol";

/**
 * @title Contract used to lock POLY corresponds to locked amount user can claim same
 * amount of POLY on Polymesh blockchain
 */

contract PolyLocker is PolyLockerStorage, ProxyOwner {

    using SafeMath for uint256;
    using ECDSA for bytes32;

    // Emit an event when the poly gets lock
    event PolyLocked(uint256 indexed _id, address indexed _holder, string _meshAddress, uint256 _polymeshBalance, uint256 _polyTokenBalance);
    // Emitted when locking is frozen
    event Frozen();
    // Emitted when locking is unfrozen
    event Unfrozen();

    constructor () public  {
    }

    /**
     * @notice Used for freezing locking of POLY token
     */
    function freezeLocking() external {
        require(msg.sender == __upgradeabilityOwner, "Unauthorized");
        require(!frozen, "Already frozen");
        frozen = true;
        emit Frozen();
    }

    /**
     * @notice Used for unfreezing locking of POLY token
     */
    function unfreezeLocking() external {
        require(msg.sender == __upgradeabilityOwner, "Unauthorized");
        require(frozen, "Already unfrozen");
        frozen = false;
        emit Unfrozen();
    }

    /**
     * @notice Used for locking the POLY token
     * @param _meshAddress Address that compatible the Polymesh blockchain
     */
    function lock(string calldata _meshAddress) external {
        _applyGasThrottling(GAS_UINT_REQUIRED_TO_LOCK);
        _lock(_meshAddress, msg.sender, IERC20(polyToken).balanceOf(msg.sender));
    }

    /**
     * @notice Used for locking the POLY token
     * @param _meshAddress Address that compatible the Polymesh blockchain
     * @param _lockedValue Amount of tokens need to locked
     */
    function limitLock(string calldata _meshAddress, uint256 _lockedValue) external {
        require(IERC20(polyToken).balanceOf(msg.sender) > uint256(0), "Insufficient funds");
        _applyGasThrottling(GAS_UINT_REQUIRED_TO_LOCK);
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
        _applyGasThrottling(GAS_UNIT_REQUIRED_FOR_LOCK_WITH_DATA);
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
        // Make sure locking is not frozen
        require(!frozen, "Locking frozen");
        // Validate the MESH address
        require(bytes(_meshAddress).length == VALID_ADDRESS_LENGTH, "Invalid length of mesh address");
        // Check the valid granularity, It should be 10^6 if not then transfer only 10^6 granularity funds
        // rest will reamin as dust in the sender account
        if (_senderBalance % TRUNCATE_SCALE != 0) {
            _senderBalance = _senderBalance.div(TRUNCATE_SCALE);
            _senderBalance = _senderBalance.mul(TRUNCATE_SCALE);
        }

        // Make sure balance is divisible by 10e18
        require(_senderBalance.div(10 ** 18) >= uint256(1), "Minimum amount to transfer to Polymesh is 1 POLYX");

        // Polymesh balances have 6 decimal places.
        // 1 POLY on Ethereum has 18 decimal places. 1 POLY on Polymesh has 6 decimal places.
        uint256 polymeshBalance = _senderBalance.div(TRUNCATE_SCALE);

        // Transfer funds to the contract
        require(IERC20(polyToken).transferFrom(_holder, address(this), _senderBalance), "Insufficient allowance");
        noOfeventsEmitted = noOfeventsEmitted + 1;  // Increment the event counter
        emit PolyLocked(noOfeventsEmitted, _holder, _meshAddress, polymeshBalance, _senderBalance);
    }

    function _applyGasThrottling(uint256 _gasConsumptionNeeded) internal {
        uint256 txnAlreadyExecuted;
        uint256 penalisedGasAmount = 0;
        uint256 iterationFrom = block.number - 1;
        uint256 iterationTill = iterationFrom - BLOCK_DEPTH;
        // calculate txns executed in Block depth
        for (uint256 i = iterationFrom; i <= iterationFrom && i > iterationTill; i--) {
            txnAlreadyExecuted += txnExecutedPerBlock[i];
        }
        // check whether current transaction will bear peanlty or not.
        if (txnAlreadyExecuted > MAX_TXN_ALLOWED) {
            penalisedGasAmount = (txnAlreadyExecuted - MAX_TXN_ALLOWED) * GAS_UNIT_PENALTY;
            penalisedGasAmount = penalisedGasAmount > MAX_GAS_LIMIT ?  MAX_GAS_LIMIT : penalisedGasAmount;
        }
        if (gasleft() < penalisedGasAmount + _gasConsumptionNeeded ) {
            revert("Gas to low");
        }
        // consumed Extra gas
        if (penalisedGasAmount > 0) 
            consumeGasPenalty(gasleft() - penalisedGasAmount);
        // Update the txn count
        // consume 20,000 of gas unit if `txnExecutedPerBlock[block.number]` is 0
        // otherwise it consume 5000 gas unit
        // refernce - https://eips.ethereum.org/EIPS/eip-1087
        txnExecutedPerBlock[block.number] += 1;
    }
    
    function consumeGasPenalty(uint256 _till) internal {
        while(gasleft() > _till) {
            // Loop till the gas left will equal to `_till`
        }
    }
}
