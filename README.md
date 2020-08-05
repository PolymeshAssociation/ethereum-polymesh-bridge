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

### 1.0.0
| Contracts | Address |
|------------|--------|
|PolyLockerAddress (logic): | [0x7528477C82093f11d5066f8A60ac9f9cB62B5A34](https://kovan.etherscan.io/address/0x7528477C82093f11d5066f8A60ac9f9cB62B5A34)|
|PolyLockerProxyAddress: | [0x3684208173b25aacCD38a58a73f66184f5667C11](https://kovan.etherscan.io/address/0x3684208173b25aacCD38a58a73f66184f5667C11) |
|PolyToken: | [0xB347b9f5B56b431B2CF4e1d90a5995f7519ca792](https://kovan.etherscan.io/address/0xB347b9f5B56b431B2CF4e1d90a5995f7519ca792) |

upgraded PolyLocker (Logic address) - [0xa11ded28bfa305e7c877d0310df436e1f841ef7a](https://kovan.etherscan.io/address/0xa11ded28bfa305e7c877d0310df436e1f841ef7a)

### 1.1.0
| Contracts | Address |
|------------|--------|
|PolyLockerAddress (logic): | [0x528999Ae62d515e2F0CeE0cc9E6681e29BC59f36](https://kovan.etherscan.io/address/0x528999Ae62d515e2F0CeE0cc9E6681e29BC59f36)|
|PolyLockerProxyAddress: | [0x9791be69F613D372E09EbA611d25157A5512c5c8](https://kovan.etherscan.io/address/0x9791be69F613D372E09EbA611d25157A5512c5c8) |
|PolyToken: | [0xB347b9f5B56b431B2CF4e1d90a5995f7519ca792](https://kovan.etherscan.io/address/0xB347b9f5B56b431B2CF4e1d90a5995f7519ca792) |

upgraded PolyLocker (Logic address) - [0xbdbbd3f124d4051df31b7f98e981d358a3bc4f5e](https://kovan.etherscan.io/address/0xbdbbd3f124d4051df31b7f98e981d358a3bc4f5e)

## Kovan (Ethereum) <-> Aldebaran (Polymesh testnet)

| Contracts | Address |
|------------|--------|
|PolyLockerAddress (logic): | [0xcA7f6CdB0A9384354E998b44270E8b490C772b78](https://kovan.etherscan.io/address/0xcA7f6CdB0A9384354E998b44270E8b490C772b78)|
|PolyLockerProxyAddress: | [0x5A0689dB080e63EB1C8F091239B9532Db10B0206](https://kovan.etherscan.io/address/0x5A0689dB080e63EB1C8F091239B9532Db10B0206) |
|PolyToken: | [0xB347b9f5B56b431B2CF4e1d90a5995f7519ca792](https://kovan.etherscan.io/address/0xB347b9f5B56b431B2CF4e1d90a5995f7519ca792) |

upgraded PolyLocker (Logic address) - [0x09588b302B3526Aea8E8600ee52373B1b2eE36B6](https://kovan.etherscan.io/address/0x09588b302B3526Aea8E8600ee52373B1b2eE36B6)

### 1.1.0
| Contracts | Address |
|------------|--------|
|PolyLockerAddress (logic): | [0xDb99495e80f2a9dF8b6d296b5507214e668603Ce](https://kovan.etherscan.io/address/0xDb99495e80f2a9dF8b6d296b5507214e668603Ce)|
|PolyLockerProxyAddress: | [0xC0E0845731af3F081d4947aAe5EB4256536D679B](https://kovan.etherscan.io/address/0xC0E0845731af3F081d4947aAe5EB4256536D679B) |
|PolyToken: | [0xB347b9f5B56b431B2CF4e1d90a5995f7519ca792](https://kovan.etherscan.io/address/0xB347b9f5B56b431B2CF4e1d90a5995f7519ca792) |

upgraded PolyLocker (Logic address) - [0xbdbbd3f124d4051df31b7f98e981d358a3bc4f5e](https://kovan.etherscan.io/address/0xbdbbd3f124d4051df31b7f98e981d358a3bc4f5e)

## Kovan (For tooling chain PMF)
| Contracts | Address |
|------------|--------|
|PolyLockerAddress (logic): | [0x75Dc41b0d69d182fc3fFc7716d35a1845121618d](https://kovan.etherscan.io/address/0x75Dc41b0d69d182fc3fFc7716d35a1845121618d)|
|PolyLockerProxyAddress: | [0xd44A07f1bf0d0DFC3A553E6657a87DB93409Eec6](https://kovan.etherscan.io/address/0xd44A07f1bf0d0DFC3A553E6657a87DB93409Eec6) |
|PolyToken: | [0xB347b9f5B56b431B2CF4e1d90a5995f7519ca792](https://kovan.etherscan.io/address/0xB347b9f5B56b431B2CF4e1d90a5995f7519ca792) |
