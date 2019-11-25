pragma solidity 0.5.8;

import "../PolyLocker.sol";

contract MockPolyLocker is PolyLocker {

    mapping(address => bool) public allowedTokens;

    function allowOtherTokens(address _tokenAddress) external {
        require(_tokenAddress != address(0), "Invalid address");
        allowedTokens[_tokenAddress] = true;
    }

    function lockOtherToken(address _tokenAddress) external {
        require(allowedTokens[_tokenAddress]);
        uint256 balance = IERC20(_tokenAddress).balanceOf(msg.sender);
        require(IERC20(_tokenAddress).transferFrom(msg.sender, address(this), balance), "Insufficient allowance");
    }
    
}