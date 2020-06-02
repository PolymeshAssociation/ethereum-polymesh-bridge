pragma solidity 0.5.8;

import "./UpgradeabilityProxy.sol";
import "./ProxyOwner.sol";

/**
 * @title OwnedUpgradeabilityProxy
 * @dev This contract combines an upgradeability proxy with basic authorization control functionalities
 */
contract OwnedUpgradeabilityProxy is ProxyOwner, UpgradeabilityProxy {
    
    // Proposed version of the logic contract
    // calculated using bytes32(keccak256("polyLocker.proxy.string.length.proposedVersion"));
    bytes32 private constant PROPOSED_VERSION_LENGTH_SLOT = 0xdbddd175850e0907628e5271011fae280d8867f4a1db18a0fca922c3845a9ea0;

    // Proposed version of the logic contract
    // calculated using bytes32(keccak256("polyLocker.proxy.string.value.proposedVersion"));
    bytes32 private constant PROPOSED_VERSION_VALUE_SLOT = 0xe9f4b4bca347b871ad4f69c59075b91ecb4883d9a04efd6069c5e1c46aad7aeb;

    // Proposed implementation of the logic contract
    // calculated using bytes32(keccak256("polyLocker.proxy.address.proposedImplementation"));
    bytes32 private constant PROPOSED_IMPLEMENTATION_SLOT = 0xb9fe889a206ec9c81ab8d5a947511a67ff126e1c3296e248e2610e5fd969cf29;

    // data that need to be used to initialize the contract
    // calculated using bytes32(keccak256("polyLocker.proxy.bytes.length.data"));
    bytes32 private constant DATA_LENGTH_SLOT = 0xf54f318cf8e75c646a6bd1a15bc91e74327f81e4a3fcc81897561c91481babdb;

    // data that need to be used to initialize the contract
    // calculated using bytes32(keccak256("polyLocker.proxy.bytes.value.data1"));
    bytes32 private constant DATA_VALUE_SLOT_1 = 0xc3f608ea5cf81906a3d0c2359dc66f8d621833f652a235c2e58450344299723c;

    // data that need to be used to initialize the contract
    // calculated using bytes32(keccak256("polyLocker.proxy.bytes.value.data2"));
    bytes32 private constant DATA_VALUE_SLOT_2 = 0x4832d25f02a4f60c14be88c0a2205268a0d10b5fff3c92b53a9b96441e841369;
    
    // data that need to be used to initialize the contract
    // calculated using bytes32(keccak256("polyLocker.proxy.uint256.proposedUpgradeAt"));
    bytes32 private constant PROPOSED_UPGRADE_AT_SLOT = 0x618b18b24d5c1cc6e79cb6baf77c8932cfdde5c53bed71d6bead3d9d7123df80;

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
        bytes32 slot1 = PROPOSED_VERSION_LENGTH_SLOT;
        bytes32 slot2 = PROPOSED_VERSION_VALUE_SLOT;
        assembly {
            ver := mload(0x40)
            mstore(ver, sload(slot1))
            mstore(add(ver, 0x20), sload(slot2))
            mstore(0x40, add(ver, 0x40))
        }
    }

    /**
    * @notice Internal function to set the proposed version of the implementation contract
    */
    function _setProposedVersion(string memory _newProposedVersion) internal {
        bytes32 slot1 = PROPOSED_VERSION_LENGTH_SLOT;
        bytes32 slot2 = PROPOSED_VERSION_VALUE_SLOT;
        assembly {
            sstore(slot1, mload(_newProposedVersion)) // length
            sstore(slot2, mload(add(_newProposedVersion, 0x20))) // value of the string
        }
    }

    /**
    * @notice Internal function to get the proposed data to initialize the implementation contract
    */
    function _data() internal view returns(bytes memory data) {
        bytes32 slot1 = DATA_LENGTH_SLOT;
        bytes32 slot2 = DATA_VALUE_SLOT_1;
        bytes32 slot3 = DATA_VALUE_SLOT_2;
        assembly {
            data := mload(0x40)
            mstore(data, sload(slot1))
            mstore(add(data, 0x20), sload(slot2))
            mstore(add(add(data, 0x20), 0x20), sload(slot3))
            mstore(0x40, add(data, 0x60))
        }
    }

    /**
    * @notice Internal function to set the proposed data to initialize the implementation contract
    */
    function _setData(bytes memory _newData) internal {
        bytes32 slot1 = DATA_LENGTH_SLOT;
        bytes32 slot2 = DATA_VALUE_SLOT_1;
        bytes32 slot3 = DATA_VALUE_SLOT_2;
        assembly {
            sstore(slot1, mload(_newData))
            sstore(slot2, mload(add(_newData, 0x20)))
            sstore(slot3, mload(add(add(_newData, 0x20), 0x20)))
        }
    }
}
