// SPDX-License-Identifier: MIT

pragma solidity ^0.7.6;

// Requirements

// Any POLY holder can lock POLY (Issuers, Investors, WL, Polymath Founders, etc.)
// The amount of POLY to be locked must be >=1, otherwise, fail with insufficient funds
// There is no max limit on how much POLY can be locked
// POLY will be locked forever, no one can unlock it (ignore the upgradable contract bit)
// Granularity for locked POLY should be restricted to Polymesh granularity (10^6)
// User must provide their Mesh address when locking POLY
// Emit an event for locked POLY including Mesh address & timestamp
// Mesh address must be of valid length

import "openzeppelin-solidity/contracts/token/ERC20/IERC20.sol";
import "openzeppelin-solidity/contracts/math/SafeMath.sol";
import "openzeppelin-solidity/contracts/access/Ownable.sol";

/**
 * @title Contract used to lock POLY corresponds to locked amount user can claim same
 * amount of POLY on Polymesh blockchain
 */
contract PolyLocker is Ownable {
    using SafeMath for uint256;

    // Tracks the total no. of events emitted by the contract.
    uint256 public noOfeventsEmitted;

    // Address of the token that is locked by the contract. i.e. PolyToken contract address.
    IERC20 public immutable polyToken;

    // Controls if locking Poly is frozen.
    bool public frozen;

    // Granularity Polymesh blockchain in 10^6 but it's 10^18 on Ethereum.
    // This is used to truncate 18 decimal places to 6.
    uint256 constant public TRUNCATE_SCALE = 10 ** 12;

    // Valid address length of Polymesh blockchain.
    uint256 constant public VALID_ADDRESS_LENGTH = 48;

    uint256 constant internal E18 = uint256(10) ** 18;

    // Emit an event when the poly gets lock
    event PolyLocked(uint256 indexed _id, address indexed _holder, string _meshAddress, uint256 _polymeshBalance, uint256 _polyTokenBalance);
    // Emitted when locking is frozen
    event Frozen();
    // Emitted when locking is unfrozen
    event Unfrozen();


    constructor(address _polyToken) {
        require(_polyToken != address(0), "Invalid address");
        polyToken = IERC20(_polyToken);
    }

    /**
     * @notice Used for freezing locking of POLY token
     */
    function freezeLocking() external onlyOwner {
        require(!frozen, "Already frozen");
        frozen = true;
        emit Frozen();
    }

    /**
     * @notice Used for unfreezing locking of POLY token
     */
    function unfreezeLocking() external onlyOwner {
        require(frozen, "Already unfrozen");
        frozen = false;
        emit Unfrozen();
    }

    /**
     * @notice used to set the nonce
     * @param _newNonce New nonce to set with the contract
     */
    function setEventsNonce(uint256 _newNonce) external onlyOwner {
        noOfeventsEmitted = _newNonce;
    }

    /**
     * @notice Used for locking the POLY token
     * @param _meshAddress Address that compatible the Polymesh blockchain
     */
    function lock(string calldata _meshAddress) external {
        _lock(_meshAddress, msg.sender, polyToken.balanceOf(msg.sender));
    }

    /**
     * @notice Used for locking the POLY token
     * @param _meshAddress Address that compatible the Polymesh blockchain
     * @param _lockedValue Amount of tokens need to locked
     */
    function limitLock(string calldata _meshAddress, uint256 _lockedValue) external {
        _lock(_meshAddress, msg.sender, _lockedValue);
    }

    function _lock(string memory _meshAddress, address _holder, uint256 _polyAmount) internal {
        // Make sure locking is not frozen
        require(!frozen, "Locking frozen");
        // Validate the MESH address
        require(bytes(_meshAddress).length == VALID_ADDRESS_LENGTH, "Invalid length of mesh address");

        // Make sure balance is divisible by 10e18
        require(_polyAmount >= E18, "Insufficient amount");

        // Polymesh balances have 6 decimal places.
        // 1 POLY on Ethereum has 18 decimal places. 1 POLYX on Polymesh has 6 decimal places.
        // i.e. 1^18 POLY = 1^6 POLYX.
        uint256 polymeshBalance = _polyAmount / TRUNCATE_SCALE;
        _polyAmount = polymeshBalance * TRUNCATE_SCALE;

        // Transfer funds to this contract
        require(polyToken.transferFrom(_holder, address(this), _polyAmount), "Insufficient allowance");
        uint256 cachedNoOfeventsEmitted = noOfeventsEmitted + 1; // Caching number of events in memory, saves 1 SLOAD
        noOfeventsEmitted = cachedNoOfeventsEmitted; // Increment the event counter in storage
        // The event does not need to contain both `polymeshBalance` and `_polyAmount` as one can be derived from other.
        // However, we are still keeping them for easier integrations.
        emit PolyLocked(cachedNoOfeventsEmitted, _holder, _meshAddress, polymeshBalance, _polyAmount);
    }
}
