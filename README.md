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

### Deployment to Testnet
To deploy to testnet, set 3 ENV variables when running migration:

- PRIVATE_KEY
- KOVAN_ENDPOINT
- POLY_TOKEN_ADDRESS 

Deployed contract addresses are written to `contracts.json` file in project root folder.
```
PRIVATE_KEY= KOVAN_ENDPOINT=https://kovan.infura.io/v3/ POLY_TOKEN_ADDRESS=0x0 truffle migrate --network kovan
```