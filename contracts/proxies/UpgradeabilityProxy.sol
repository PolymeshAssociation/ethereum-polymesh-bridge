pragma solidity 0.5.8;

import "./Proxy.sol";
import "openzeppelin-solidity/contracts/utils/Address.sol";

/**
 * @title UpgradeabilityProxy
 * @dev This contract represents a proxy where the implementation address to which it will delegate can be upgraded
 */
contract UpgradeabilityProxy is Proxy {

    // Version name of the current implementation
    // calculated using bytes32(keccak256("polyLocker.proxy.string.length.version")); 
    bytes32 internal constant VERSION_LENGTH_SLOT = 0xd268213b7338f494342c01a33edbcbb2b796880811df0340ad2cf2d79a4b963d;

    // Version name of the current implementation
    // calculated using bytes32(keccak256("polyLocker.proxy.string.value.version")); 
    bytes32 internal constant VERSION_VALUE_SLOT = 0x22ae9ed2863b3492c451b2d8d14f66ac380ec1428f903287771eccdf19abc20f;

    // Address of the current implementation
    // Calculated using bytes32(keccak256("polyLocker.proxy.address.implementation"));
    bytes32 internal constant IMPLEMENTATION_SLOT = 0x657494d3592e0bec12778a01bf605e19066c34a5202885e305a1de8e32fd1992;

    /**
    * @dev This event will be emitted every time the implementation gets upgraded
    * @param _newVersion representing the version name of the upgraded implementation
    * @param _newImplementation representing the address of the upgraded implementation
    */
    event Upgraded(string _newVersion, address indexed _newImplementation);

    /**
    * @dev Upgrades the implementation address
    * @param _newVersion representing the version name of the new implementation to be set
    * @param _newImplementation representing the address of the new implementation to be set
    */
    function _upgradeTo(string memory _newVersion, address _newImplementation) internal {
        require(
            _implementation() != _newImplementation && _newImplementation != address(0),
            "Old address is not allowed and implementation address should not be 0x"
        );
        require(Address.isContract(_newImplementation), "Cannot set a proxy implementation to a non-contract address");
        require(bytes(_newVersion).length > 0, "Version should not be empty string");
        require(keccak256(abi.encodePacked(_version())) != keccak256(abi.encodePacked(_newVersion)), "New version equals to current");
        _setVersion(_newVersion);
        _setImplementation(_newImplementation);
        emit Upgraded(_newVersion, _newImplementation);
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
    * @notice Internal function to provide the version of the implementation contract
    */
    function _version() internal view returns(string memory ver) {
        bytes32 slot1 = VERSION_LENGTH_SLOT;
        bytes32 slot2 = VERSION_VALUE_SLOT;
        assembly {
            ver := mload(0x40)
            mstore(ver, sload(slot1))
            mstore(add(ver, 0x20), sload(slot2))
            mstore(0x40, add(ver, 0x40))
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

    /**
    * @notice Internal function to set the version of the implementation contract
    */
    function _setVersion(string memory _newVersion) internal {
        bytes32 slot1 = VERSION_LENGTH_SLOT;
        bytes32 slot2 = VERSION_VALUE_SLOT;
        assembly {
            sstore(slot1, mload(_newVersion)) // length
            sstore(slot2, mload(add(_newVersion, 0x20))) // value of the string
        }
    }

}
