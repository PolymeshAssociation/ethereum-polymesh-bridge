pragma solidity 0.5.8;

/**
 * @title ProxyOwner
 * @dev This contract holds the owner of the proxy
 */
contract ProxyOwner {

    // Owner of the contract
    // calculated using bytes32(uint256(keccak256("polylock.proxy.address.upgradeabilityOwner")) - 1);
    bytes32 private constant UPGREADABILITY_OWNER_SLOT = 0x9c88aa543146ae4f3dcb6144632ee1296f5ba93321d1dd5ee6a35b84b41b955b;

    /**
    * @dev Tells the address of the owner
    * @return the address of the owner
    */
    function _upgradeabilityOwner() internal view returns(address uOwner) {
        bytes32 slot = UPGREADABILITY_OWNER_SLOT;
        assembly {
            uOwner := sload(slot)
        }
    }

    /**
    * @dev Sets the address of the owner
    */
    function _setUpgradeabilityOwner(address _newUpgradeabilityOwner) internal {
        require(_newUpgradeabilityOwner != address(0), "Address should not be 0x");
        bytes32 slot = UPGREADABILITY_OWNER_SLOT;
        assembly {
            sstore(slot, _newUpgradeabilityOwner)
        }
    }
}
