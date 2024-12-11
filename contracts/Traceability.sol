// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract Traceability {

    enum State {Active, Inactive}

    struct Trace {
        string id;
        string description;
        uint256 timestamp;
        address author; 
        State state;
    }

    Trace[] public traces;

    event TraceAdded(string id, string description, uint256 timestamp, address author);

    function addTrace(string memory _id, string memory _description) public {
        require(bytes(_id).length > 0, "Trace ID cannot be empty");
        require(bytes(_description).length > 0, "Trace description cannot be empty");

        traces.push(Trace(_id, _description, block.timestamp, msg.sender, State.Active));
        emit TraceAdded(_id, _description, block.timestamp, msg.sender);
    }

    function getTrace(uint256 _index) public view returns (Trace memory) {
        require(_index < traces.length, "Index out of bounds");
        require(traces[_index].state == State.Active, "Not active" );
        return traces[_index];
    }

    function getTraceCount() public view returns (uint256) {
        return traces.length;
    }

    function getTracesByAuthor(address _author) public view returns (Trace[] memory) {
        Trace[] memory filteredTraces = new Trace[](traces.length);
        uint256 count = 0;
        for (uint256 i = 0; i < traces.length; i++) {
            if (traces[i].author == _author) {
                filteredTraces[count] = traces[i];
                count++;
            }
        }

        Trace[] memory result = new Trace[](count);
        for (uint256 i = 0; i < count; i++) {
            result[i] = filteredTraces[i];
        }
        return result;
    }
}