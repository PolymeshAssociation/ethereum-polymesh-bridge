pragma solidity ^0.5.8;

interface IPolyLocker {
    function noOfeventsEmitted() external view returns(uint256 _eventsEmittedCount);
}