// SPDX-License-Identifier: MIT

pragma solidity >=0.8.2 <0.9.0;

contract CrowdFunding {

    struct Contribution {
        address contributor;
        uint amount;
    }

    enum State {Active, Inactive}

    struct Project {
        string id;
        string name;
        string description;
        State state;
        address payable wallet;
        address owner;
        uint funds;
        uint256 goal;
    }

    Project[] private projects;
    mapping(string => Contribution[]) public contributions; 

    event ProjectCreated(
        string id
    );

    function createProject (string calldata _id, string calldata _name, string calldata _description, uint256 _goal) public {
        require(_goal > 0, "The goal must be greater than 0");
        Project memory newProject = Project(_id, _name, _description, State.Active, payable(msg.sender), msg.sender, 0, _goal);
        projects.push(newProject);
        emit ProjectCreated(newProject.id);
    }

    event FundingProject(
        address funder, uint value, uint currentFunds
    );

    error GoalReached(string description, uint256 goal);

    function fundProject(uint index) public payable notOwner(index) {
        require(getStatus(index) == State.Active, "Crowd is not active");
        require(msg.value > 0, "Can't fund less than 0 ETH");
        if(projects[index].funds < projects[index].goal) {
            projects[index].wallet.transfer(msg.value);
            projects[index].funds += msg.value;
            contributions[projects[index].id].push(Contribution(msg.sender, msg.value)); 
            emit FundingProject(msg.sender, msg.value, projects[index].funds);
        } else {
            revert GoalReached("The goal is reached", projects[index].goal);
        }
    }

    modifier notOwner(uint index) {
        require(projects[index].owner != msg.sender, "The project owner can't do this transaction");
        _;
    }

    modifier onlyOwner(uint index) {
        require(projects[index].owner == msg.sender, "You must be the project owner");
        _;
    }

    event ChangeStatus(address editor, State currentStatus);

    function changeState(State newState, uint index) public onlyOwner(index) {
        require(newState != projects[index].state, "Cant change to the same state");
        projects[index].state = newState; 
        emit ChangeStatus(msg.sender, projects[index].state);
    }
    
    function getGoal(uint index) public view returns(uint) {
        return projects[index].goal;
    }
    
    function getStatus(uint index) public view returns(State) {
        return projects[index].state;
    }
    
    function getFunds(uint index) public view returns (uint) {
        return projects[index].funds;
    }
}