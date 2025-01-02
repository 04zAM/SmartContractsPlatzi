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

    struct Product {
        string id;
        string codebar;
        string name;
        string description;
        uint256 timestamp;
        address author;
        Trace[] traces;
        State state;
    }

    mapping(string => Product[]) productHistory;

    event TraceAdded(string id, string description, uint256 timestamp, address author);
    event ProductAdded(string id, string codebar, string name, string description, uint256 timestamp, address author);

    function addProduct(
        string memory _id,
        string memory _codebar,
        string memory _name,
        string memory _description
    ) public {
        require(bytes(_id).length > 0, "Product ID cannot be empty");
        require(bytes(_codebar).length > 0, "Codebar cannot be empty");
        require(bytes(_name).length > 0, "Name cannot be empty");
        require(bytes(_description).length > 0, "Description cannot be empty");
        require(productHistory[_id] == null, "Product ID already exists");
        
        Product memory _product = Product(_id, _codebar, _name, _description, block.timestamp, msg.sender, [], State.Active);
        productHistory[_id] = [_product];
        emit ProductAdded(_id, _codebar, _name, _description, block.timestamp, msg.sender);
    }

    function addTrace(string memory _productId, string memory _description) public {
        require(bytes(_productId).length > 0, "Product ID cannot be empty");
        require(bytes(_description).length > 0, "Trace description cannot be empty");
        require(products[_productId].state == State.Active, "Product not active");

        string memory _id = "TRC-" + (traces.length + 1).toString();
        traces.push(Trace(_id, _description, block.timestamp, msg.sender, State.Active));
        emit TraceAdded(_id, _description, block.timestamp, msg.sender);
    }

    function getTrace(uint256 _productId, uint256 _index) public view returns (Trace memory) {
        require(products[_productId].state == State.Active, "Product not active");
        require(_index < products[_productId].traces.length, "Trace index out of bounds");
        return products[_productId].traces[_index];
    }

    function getTracesByProduct(uint256 _productId) public view returns (Trace[] memory) {
        require(products[_productId].state == State.Active, "Product not active");
        return products[_productId].traces;
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