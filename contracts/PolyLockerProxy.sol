pragma solidity 0.5.8;

import "./proxies/OwnedUpgradeabilityProxy.sol";
import "./PolyLockerStorage.sol";

/**
 * @title PolyLockerProxy
 */
contract PolyLockerProxy is OwnedUpgradeabilityProxy, PolyLockerStorage {

    /**
    * @notice Constructor
    * @param _implementation Address of the Polylocker contract
    * @param _polyToken Address of the Poly token
    */
    constructor (
        address _implementation,
        address _polyToken
    )
        public
    {
        require(
            _implementation != address(0),
            "Implementation address should not be 0x"
        );
        // For deployment on Ethereum mainnet we will prefer hardcoded PolyToken
        require(_polyToken != address(0), "Invalid address");
        polyToken = _polyToken;
        _upgradeTo(_implementation);
    }

}