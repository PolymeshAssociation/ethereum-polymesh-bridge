pragma solidity ^0.5.8;

import "./proxies/OwnedUpgradeabilityProxy.sol";
import "./PolyLockerStorage.sol";

/**
 * @title PolyLockerProxy
 */
contract PolyLockerProxy is PolyLockerStorage, OwnedUpgradeabilityProxy {

    /**
    * @notice Constructor
    * @param _version version
    * @param _implementation Address of the Polylocker contract
    */
    constructor (
        string memory _version,
        address _implementation
    )
        public
    {
        require(
            _implementation != address(0),
            "Implementation address should not be 0x"
        );
        __proposeUpgradeAt = now;
        __proposedVersion = _version;
        __proposedImplementation = _implementation;
        _upgradeTo(_version, _implementation);
    }

}