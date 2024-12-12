// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract ProductTraceability {
    struct Event {
        string eventType;
        string details;
        uint256 timestamp;
        address recorder;
    }

    mapping(string => Event[]) private productHistory;
    mapping(address => bool) public authorizedRecorders;

    event ProductEventRecorded(string indexed productId, string eventType, address recorder);

    constructor() {
        authorizedRecorders[msg.sender] = true;
    }

    modifier onlyAuthorized() {
        require(authorizedRecorders[msg.sender], "Not authorized");
        _;
    }

    function addAuthorizedRecorder(address recorder) public onlyAuthorized {
        authorizedRecorders[recorder] = true;
    }

    function removeAuthorizedRecorder(address recorder) public onlyAuthorized {
        authorizedRecorders[recorder] = false;
    }

    function recordProduct(string memory productId, string memory eventType, string memory details) public onlyAuthorized {
        Event memory newEvent = Event(eventType, details, block.timestamp, msg.sender);
        productHistory[productId].push(newEvent);
        emit ProductEventRecorded(productId, eventType, msg.sender);
    }

    function getProductHistory(string memory productId) public view returns (Event[] memory) {
        return productHistory[productId];
    }
}