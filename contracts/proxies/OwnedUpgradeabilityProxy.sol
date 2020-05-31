pragma solidity 0.5.8;

import "./UpgradeabilityProxy.sol";
import "./ProxyOwner.sol";

/**
 * @title OwnedUpgradeabilityProxy
 * @dev This contract combines an upgradeability proxy with basic authorization control functionalities
 */
contract OwnedUpgradeabilityProxy is ProxyOwner, UpgradeabilityProxy {
    
    // Proposed version of the logic contract
    // calculated using bytes32(uint256(keccak256("polylock.proxy.string.proposedVersion")) - 1);
    bytes32 private constant PROPOSED_VERSION_SLOT = 0xddfeeef0ac1411aa24c4760ad59fc4359c04ec93e9b3bd869a2e89c595117eea;

    // Proposed implementation of the logic contract
    // calculated using bytes32(uint256(keccak256("polylock.proxy.address.proposedImplementation")) -1);
    bytes32 private constant PROPOSED_IMPLEMENTATION_SLOT = 0x1301f853d87ec41d98f23d4fb7155ed282bd563b311592b078fdad70306616fd;

    // data that need to be used to initialize the contract
    // calculated using bytes32(uint256(keccak256("polylock.proxy.bytes.data")) -1);
    bytes32 private constant DATA_SLOT = 0xc72c573ea8c2c7729d04d3b26305d9523460c28995af7ecad3356ef46bc25828;
    
    // data that need to be used to initialize the contract
    // calculated using bytes32(uint256(keccak256("polylock.proxy.uint256.proposedUpgradeAt")) -1);
    bytes32 private constant PROPOSED_UPGRADE_AT_SLOT = 0x29c02dae7ff91d9c44ab7aac770c54f5103021450df4af0842c2bc2a7bef92d2;

    uint256 constant internal COLDPERIOD = 30 minutes;

    /**
    * @dev Event to show ownership has been transferred
    * @param _previousOwner representing the address of the previous owner
    * @param _newOwner representing the address of the new owner
    */
    event ProxyOwnershipTransferred(address _previousOwner, address _newOwner);

    /**
    * @dev Throws if called by any account other than the owner.
    */
    modifier ifOwner() {
        if (msg.sender == _upgradeabilityOwner()) {
            _;
        } else {
            _fallback();
        }
    }

    /**
    * @dev the constructor sets the original owner of the contract to the sender account.
    */
    constructor() public {
        _setUpgradeabilityOwner(msg.sender);
    }

    /**
    * @dev Tells the address of the proxy owner
    * @return the address of the proxy owner
    */
    function proxyOwner() external ifOwner returns(address) {
        return _upgradeabilityOwner();
    }

    /**
    * @dev Tells the version name of the current implementation
    * @return string representing the name of the current version
    */
    function version() external ifOwner returns(string memory) {
        return _version();
    }

    /**
    * @dev Tells the address of the current implementation
    * @return address of the current implementation
    */
    function implementation() external ifOwner returns(address) {
        return _implementation();
    }

    /**
    * @dev Allows the current owner to transfer control of the contract to a newOwner.
    * @param _newOwner The address to transfer ownership to.
    */
    function transferProxyOwnership(address _newOwner) external ifOwner {
        require(_newOwner != address(0), "Address should not be 0x");
        emit ProxyOwnershipTransferred(_upgradeabilityOwner(), _newOwner);
        _setUpgradeabilityOwner(_newOwner);
    }

    /**
    * @dev Allows the upgradeability owner to upgrade the current version of the proxy and call the new implementation
    * to initialize whatever is needed through a low level call.
    * @param _newVersion representing the version name of the new implementation to be set.
    * @param _newImplementation representing the address of the new implementation to be set.
    * @param _data represents the msg.data to bet sent in the low level call. This parameter may include the function
    * signature of the implementation to be called with the needed payload
    */
    function proposeUpgrade(string calldata _newVersion, address _newImplementation, bytes calldata _data) external ifOwner {
        _setProposeUpgradeAt(now);
        _setProposedVersion(_newVersion);
        _setProposedImplementation(_newImplementation);
        _setData(_data);
    }

    /**
    * @dev Allows the upgradeability owner to upgrade the current version of the proxy.
    */
    function upgradeTo() external ifOwner {
        require(now > (_proposeUpgradeAt() + COLDPERIOD), "Proposal is in unmatured state");
        _upgradeTo(_proposedVersion(), _proposedImplementation());
    }

    /**
    * @dev Allows the upgradeability owner to upgrade the current version of the proxy and call the new implementation
    * to initialize whatever is needed through a low level call.
    */
    function upgradeToAndCall() external payable ifOwner {
        require(now > (_proposeUpgradeAt() + COLDPERIOD), "Proposal is in unmatured state");
        _upgradeToAndCall(_proposedVersion(), _proposedImplementation(), _data());
    }

    function _upgradeToAndCall(string memory _newVersion, address _newImplementation, bytes memory _data) internal {
        _upgradeTo(_newVersion, _newImplementation);
        bool success;
        /*solium-disable-next-line security/no-call-value*/
        (success, ) = address(this).call.value(msg.value)(_data);
        require(success, "Fail in executing the function of implementation contract");
    }


    /**
    * @notice Internal function to get the proposed upgrade timestamp
    */
    function _proposeUpgradeAt() internal view returns(uint256 upgradeAt) {
        bytes32 slot = PROPOSED_UPGRADE_AT_SLOT;
        assembly {
            upgradeAt := sload(slot)
        }
    }

    /**
    * @notice Internal function to set the proposed upgrade timestamp
    */
    function _setProposeUpgradeAt(uint256 _newProposeUpgradeAt) internal {
        bytes32 slot = PROPOSED_UPGRADE_AT_SLOT;
        assembly {
            sstore(slot, _newProposeUpgradeAt)
        }
    }

    /**
    * @notice Internal function to provide the proposed address of the implementation contract
    */
    function _proposedImplementation() internal view returns(address impl) {
        bytes32 slot = PROPOSED_IMPLEMENTATION_SLOT;
        assembly {
            impl := sload(slot)
        }
    }

    /**
    * @notice Internal function to set the proposed address of the implementation contract
    */
    function _setProposedImplementation(address _newProposedImplementation) internal {
        bytes32 slot = PROPOSED_IMPLEMENTATION_SLOT;
        assembly {
            sstore(slot, _newProposedImplementation)
        }
    }

    /**
    * @notice Internal function to get the proposed version of the implementation contract
    */
    function _proposedVersion() internal view returns(string memory ver) {
        bytes32 slot = PROPOSED_VERSION_SLOT;
        assembly {
            ver := sload(slot)
        }
    }

    /**
    * @notice Internal function to set the proposed version of the implementation contract
    */
    function _setProposedVersion(string memory _newProposedVersion) internal {
        bytes32 slot = PROPOSED_VERSION_SLOT;
        assembly {
            sstore(slot, _newProposedVersion)
        }
    }

    /**
    * @notice Internal function to get the proposed data to initialize the implementation contract
    */
    function _data() internal view returns(bytes memory data) {
        bytes32 slot = DATA_SLOT;
        assembly {
            data := sload(slot)
        }
    }

    /**
    * @notice Internal function to set the proposed data to initialize the implementation contract
    */
    function _setData(bytes memory _newData) internal {
        bytes32 slot = DATA_SLOT;
        assembly {
            sstore(slot, _newData)
        }
    }
}
