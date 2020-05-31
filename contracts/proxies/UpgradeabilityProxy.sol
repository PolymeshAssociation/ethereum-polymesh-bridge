pragma solidity 0.5.8;

import "./Proxy.sol";
import "openzeppelin-solidity/contracts/utils/Address.sol";

/**
 * @title UpgradeabilityProxy
 * @dev This contract represents a proxy where the implementation address to which it will delegate can be upgraded
 */
contract UpgradeabilityProxy is Proxy {

    // Version name of the current implementation
    // calculated using bytes32(uint256(keccak256("polylocker.proxy.string.version")) -1 ); 
    bytes32 internal constant VERSION_SLOT = 0xc96dcfaf3cfab66f529e0055b68eca022c308e96a75a0888eb307f3838892fee;

    // Address of the current implementation
    // Calculated using bytes32(uint256(keccak256("polylocker.proxy.address.implementation")) - 1);
    bytes32 internal constant IMPLEMENTATION_SLOT = 0xf9481edbe92e5eb2036f423fb2a8203d4463e12b8deaa58c265b5fe46300fb4b;

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
        bytes32 slot = VERSION_SLOT;
        assembly {
            ver := sload(slot)
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
        bytes32 slot = VERSION_SLOT;
        assembly {
            sstore(slot, _newVersion)
        }
    }

}
