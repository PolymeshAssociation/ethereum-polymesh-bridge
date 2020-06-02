const web3 = require("web3");
const BN = web3.utils.BN;

async function printHash() {
    console.log(`
    Storage hash of the different variables of the PolyLockerProxy

        ****** Sub Contract UpgradeabilityProxy ******

        VERSION_LENGTH_SLOT             : ${slot("polyLocker.proxy.string.length.version")}
        VERSION_VALUE_SLOT              : ${slot("polyLocker.proxy.string.value.version")}
        IMPLEMENTATION_SLOT             : ${slot("polyLocker.proxy.address.implementation")}

        ****** Sub Contract OwnerUpgradeabilityProxy ******

        PROPOSED_VERSION_LENGTH_SLOT    : ${slot("polyLocker.proxy.string.length.proposedVersion")}
        PROPOSED_VERSION_VALUE_SLOT     : ${slot("polyLocker.proxy.string.value.proposedVersion")}
        PROPOSED_IMPLEMENTATION_SLOT    : ${slot("polyLocker.proxy.address.proposedImplementation")}
        DATA_LENGTH_SLOT                : ${slot("polyLocker.proxy.bytes.length.data")}
        DATA_VALUE_SLOT_1               : ${slot("polyLocker.proxy.bytes.value.data_1")}
        DATA_VALUE_SLOT_2               : ${slot("polyLocker.proxy.bytes.value.data_2")}
        PROPOSED_UPGRADE_AT_SLOT        : ${slot("polyLocker.proxy.uint256.proposedUpgradeAt")}
    `)
}


function slot(slotName) {
    return web3.utils.soliditySha3(slotName);
}

printHash();