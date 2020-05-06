# ethereum-polymesh-bridge
Contracts used to bridge POLY from Ethereum to Polymesh. This bridge will be a one way bridge type that allows users to lock there etheruem POLY forever in the smart contract by providing the corresponding Polymesh based address that will holds the same amount of POLY on Polymesh blockchain.  

## Initial requirements
* Any POLY holder can lock POLY (Issuers, Investors, WL, Polymath Founders, etc.)
* Attempt to lock coins other than POLY must fail
* The amount of POLY to be locked must be >0, otherwise, fail with insufficient funds
* There is no MAX to how much POLY can be locked
* SC must be upgradable based on a time-lock
* POLY will be locked forever, no one can unlock it
* Granularity for locked POLY should be restricted to Polymesh granularity (10^6)
* User must provide their Mesh address when locking POLY
* Emit an event for locked POLY including Mesh address & timestamp
* Mesh address must be valid (validation of address checksum)[**Deprecated**]
* Ideally allow meta-transactions so that exchanges etc. could action on behalf of users.
* User should sign data with their Polymesh address like “I agree that transferring POLY is a one-way process and can’t be reversed”
this ensures that they def. control their Polymesh account. (Verify Polymesh signed data in Ethereum)[**Deprecated**]


### Pre-requisite
* Node ^10.0.0
* Truffle ^5.0.0
* Ganache ^6.0.0

### Setup
```
yarn install
```

### Compile
```
npm run compile
```

### Test
```
npm run test
```
# Contracts Deployment

## Kovan

| Contracts | Address |
|------------|--------|
|PolyLockerAddress (logic): | [0x7528477C82093f11d5066f8A60ac9f9cB62B5A34](https://kovan.etherscan.io/address/0x7528477C82093f11d5066f8A60ac9f9cB62B5A34)|
|PolyLockerProxyAddress: | [0x3684208173b25aacCD38a58a73f66184f5667C11](https://kovan.etherscan.io/address/0x3684208173b25aacCD38a58a73f66184f5667C11) |
|PolyToken: | [0xB347b9f5B56b431B2CF4e1d90a5995f7519ca792](https://kovan.etherscan.io/address/0xB347b9f5B56b431B2CF4e1d90a5995f7519ca792) |
