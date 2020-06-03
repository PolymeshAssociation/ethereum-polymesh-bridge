pragma solidity 0.5.8;

import "./Proxy.sol";
import "openzeppelin-solidity/contracts/utils/Address.sol";

/**
 * @title UpgradeabilityProxy
 * @dev This contract represents a proxy where the implementation address to which it will delegate can be upgraded
 */
contract UpgradeabilityProxy is Proxy {

    // Address of the current implementation
    // Calculated using bytes32(keccak256("polyLocker.proxy.address.implementation"));
    bytes32 internal constant IMPLEMENTATION_SLOT = 0x657494d3592e0bec12778a01bf605e19066c34a5202885e305a1de8e32fd1992;

    /**
    * @dev This event will be emitted every time the implementation gets upgraded
    * @param _newImplementation representing the address of the upgraded implementation
    */
    event Upgraded(address indexed _newImplementation);

    /**
    * @dev Upgrades the implementation address
    * @param _newImplementation representing the address of the new implementation to be set
    */
    function _upgradeTo(address _newImplementation) internal {
        require(
            _implementation() != _newImplementation && _newImplementation != address(0),
            "Old address is not allowed and implementation address should not be 0x"
        );
        require(Address.isContract(_newImplementation), "Cannot set a proxy implementation to a non-contract address");
        _setImplementation(_newImplementation);
        emit Upgraded(_newImplementation);
    }

    
    /**
    * @notice Internal function to provide the address of the implementation contract
    */ 
    function _implementation() internal view returns(address impl) {
        bytes32 slot = IMPLEMENTATION_SLOT;
        assembly {
            impl := sload(slot)
        }
    }
    
    /**
    * @notice Internal function to set the address of the implementation contract
    */
    function _setImplementation(address _newImplementation) internal {
        bytes32 slot = IMPLEMENTATION_SLOT;
        assembly {
            sstore(slot, _newImplementation)
        }
    }

}
