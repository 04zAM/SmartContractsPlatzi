// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Traceability {
    enum State { Active, Inactive }

    struct Trace {
        bytes32 id;
        string description;
        uint256 timestamp;
        address author;
        State state;
    }

    struct Product {
        bytes32 id;
        string codebar;
        string name;
        string description;
        uint256 timestamp;
        address author;
        State state;
        bool exists;
    }

    // Changed storage structure to separate products and traces
    mapping(bytes32 => Product) private products;
    mapping(bytes32 => Trace[]) private productTraces;
    mapping(bytes32 => bytes32) private traceToProduct;
    mapping(string => bytes32[]) private codebarToProducts;
    bytes32[] private productIds;

    // Events
    event TraceAdded(bytes32 indexed productId, bytes32 indexed traceId, string description, uint256 timestamp, address author);
    event ProductAdded(bytes32 indexed id, string codebar, string name, string description, uint256 timestamp, address author);
    event ProductStateChanged(bytes32 indexed id, State state);

    // Modifiers
    modifier productExists(bytes32 _productId) {
        require(products[_productId].exists, "Product does not exist");
        _;
    }

    modifier productActive(bytes32 _productId) {
        require(products[_productId].state == State.Active, "Product not active");
        _;
    }

    // Helper function to convert string to bytes32
    function stringToBytes32(string memory source) private pure returns (bytes32 result) {
        bytes memory tempEmptyStringTest = bytes(source);
        if (tempEmptyStringTest.length == 0) {
            return 0x0;
        }
        assembly {
            result := mload(add(source, 32))
        }
    }

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
        
        bytes32 productId = stringToBytes32(_id);
        require(!products[productId].exists, "Product already exists");

        // Create product without traces array
        Product memory newProduct = Product(
            productId,
            _codebar,
            _name,
            _description,
            block.timestamp,
            msg.sender,
            State.Active,
            true
        );

        // Store the product
        products[productId] = newProduct;
        productIds.push(productId);
        codebarToProducts[_codebar].push(productId);

        // Create and store initial trace
        bytes32 traceId = keccak256(abi.encodePacked(productId, block.timestamp, "INIT"));
        Trace memory initTrace = Trace(
            traceId,
            "Product initialization",
            block.timestamp,
            msg.sender,
            State.Active
        );
        
        productTraces[productId].push(initTrace);
        traceToProduct[traceId] = productId;

        emit ProductAdded(productId, _codebar, _name, _description, block.timestamp, msg.sender);
        emit TraceAdded(productId, traceId, "Product initialization", block.timestamp, msg.sender);
    }

    function addTrace(bytes32 _productId, string memory _description) 
        public 
        productExists(_productId)
        productActive(_productId)
    {
        require(bytes(_description).length > 0, "Trace description cannot be empty");

        bytes32 traceId = keccak256(abi.encodePacked(_productId, block.timestamp, msg.sender, _description));
        Trace memory newTrace = Trace(
            traceId,
            _description,
            block.timestamp,
            msg.sender,
            State.Active
        );

        productTraces[_productId].push(newTrace);
        traceToProduct[traceId] = _productId;
        emit TraceAdded(_productId, traceId, _description, block.timestamp, msg.sender);
    }

    function getProductTraces(bytes32 _productId) 
        public 
        view 
        productExists(_productId)
        returns (Trace[] memory) 
    {
        return productTraces[_productId];
    }

    function getProductTracesByAuthor(bytes32 _productId, address _author) 
        public 
        view 
        productExists(_productId)
        returns (Trace[] memory) 
    {
        Trace[] storage allTraces = productTraces[_productId];
        uint256 count = 0;

        // First count matching traces
        for (uint256 i = 0; i < allTraces.length; i++) {
            if (allTraces[i].author == _author) {
                count++;
            }
        }

        // Create result array with exact size
        Trace[] memory result = new Trace[](count);
        uint256 resultIndex = 0;

        // Fill result array
        for (uint256 i = 0; i < allTraces.length; i++) {
            if (allTraces[i].author == _author) {
                result[resultIndex] = allTraces[i];
                resultIndex++;
            }
        }

        return result;
    }

    function setProductState(bytes32 _productId, State _state) 
        public 
        productExists(_productId)
    {
        products[_productId].state = _state;
        emit ProductStateChanged(_productId, _state);
    }

    function getProduct(bytes32 _productId) 
        public 
        view 
        productExists(_productId)
        returns (
            string memory codebar,
            string memory name,
            string memory description,
            uint256 timestamp,
            address author,
            State state
        ) 
    {
        Product memory product = products[_productId];
        return (
            product.codebar,
            product.name,
            product.description,
            product.timestamp,
            product.author,
            product.state
        );
    }

    function getTraceById(bytes32 _traceId) 
        public 
        view 
        returns (
            bytes32 productId,
            string memory description,
            uint256 timestamp,
            address author,
            State state
        ) 
    {
        bytes32 productIdFound = traceToProduct[_traceId];
        require(productIdFound != bytes32(0), "Trace not found");

        Trace[] storage traces = productTraces[productIdFound];
        for (uint256 i = 0; i < traces.length; i++) {
            if (traces[i].id == _traceId) {
                return (
                    productIdFound,
                    traces[i].description,
                    traces[i].timestamp,
                    traces[i].author,
                    traces[i].state
                );
            }
        }
        revert("Trace not found");
    }

     function getProductsByCodebar(string memory _codebar) 
        public 
        view 
        returns (
            bytes32[] memory productIdsByCodebar,
            string[] memory names,
            string[] memory descriptions,
            uint256[] memory timestamps,
            address[] memory authors,
            State[] memory states
        ) 
    {
        require(bytes(_codebar).length > 0, "Codebar cannot be empty");
        
        bytes32[] memory matchingIds = codebarToProducts[_codebar];
        require(matchingIds.length > 0, "No products found with this codebar");

        // Initialize arrays with the correct size
        names = new string[](matchingIds.length);
        descriptions = new string[](matchingIds.length);
        timestamps = new uint256[](matchingIds.length);
        authors = new address[](matchingIds.length);
        states = new State[](matchingIds.length);

        // Fill arrays with product data
        for (uint256 i = 0; i < matchingIds.length; i++) {
            Product memory product = products[matchingIds[i]];
            names[i] = product.name;
            descriptions[i] = product.description;
            timestamps[i] = product.timestamp;
            authors[i] = product.author;
            states[i] = product.state;
        }

        return (matchingIds, names, descriptions, timestamps, authors, states);
    }

    function hasProductsWithCodebar(string memory _codebar) 
        public 
        view 
        returns (bool) 
    {
        return codebarToProducts[_codebar].length > 0;
    }

    function getProductCountByCodebar(string memory _codebar) 
        public 
        view 
        returns (uint256) 
    {
        return codebarToProducts[_codebar].length;
    }

    function getAllProductIds() public view returns (bytes32[] memory) {
        return productIds;
    }
}