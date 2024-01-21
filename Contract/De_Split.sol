// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0; 

contract De_Split {
    struct User {
        string name;
        address Add;
        string username;
        uint256 net;
    }

    struct Group {
        address owner;
        mapping(string => bool) usernames;
        address[] members;
    }

    mapping(string => address) groupowners;

    struct Expense {
        uint256 totalAmount;
        uint256 share;
        bool settled;
        mapping(address => bool) hasPaid;
    }

    mapping(address => User) public users;
    mapping(address => Group) public groups;
    mapping(string => address) public usernameToAddress;
    mapping(address => Expense) public groupExpenses;

    event UserRegistered(address indexed Add, string name, string username, uint256 net);
    event GroupCreated(address indexed groupOwner);
    event MemberAdded(address indexed groupOwner, address indexed addedMember);
    event MemberRemoved(address indexed groupOwner, address indexed removedMember);
    event ExpenseAdded(address indexed groupOwner, uint256 totalAmount);
    event PaymentReceived(address indexed groupOwner, address indexed payer, uint256 amount);
    event PaymentCompleted(address indexed groupOwner, bool flag);

    modifier onlyGroupOwner() {
        require(msg.sender == groups[msg.sender].owner, "Only the group owner can access this function");
        _;
    }

    function registerUser(string memory name, string memory username) public {
        require(bytes(name).length > 0, "Name cannot be empty");
        require(bytes(username).length > 0, "Username cannot be empty");
        require(users[msg.sender].Add == address(0), "User is already registered");

        users[msg.sender] = User(name, msg.sender, username, 0);
        usernameToAddress[username]= msg.sender;

        emit UserRegistered(msg.sender, name, username, 0);
    }

    function createGroup() public {
        require(users[msg.sender].Add != address(0), "User must be registered to create a group");

        address[] memory initialMembers;
        groups[msg.sender].owner = msg.sender;
        groups[msg.sender].members = initialMembers;

        emit GroupCreated(msg.sender);
    }

    function addMember(string memory username) public onlyGroupOwner {
        require(usernameToAddress[username] != address(0), "User with this username does not exist");
        require(!groups[msg.sender].usernames[username], "User is already a member");

        address newMember = usernameToAddress[username];
        groups[msg.sender].members.push(newMember);
        groups[msg.sender].usernames[username] = true;
        groupowners[username] = msg.sender;

        emit MemberAdded(msg.sender, newMember);
    }

    function removeMember(string memory username) public onlyGroupOwner {
        require(usernameToAddress[username] != address(0), "User with this username does not exist");
        require(groups[msg.sender].usernames[username], "User is not a member");

        address memberToRemove = usernameToAddress[username];

        for (uint256 i = 0; i < groups[msg.sender].members.length; i++) {
            if (groups[msg.sender].members[i] == memberToRemove) {
                groups[msg.sender].members[i] = groups[msg.sender].members[groups[msg.sender].members.length - 1];
                groups[msg.sender].members.pop();
                break;
            }
        }

        groups[msg.sender].usernames[username] = false;

        emit MemberRemoved(msg.sender, memberToRemove);
    }

    function addExpense(uint256 totalAmount) public onlyGroupOwner {
        require(groups[msg.sender].members.length > 0, "Group must have members to add an expense");

        uint256 numMembers = groups[msg.sender].members.length;
        uint256 share = totalAmount / (numMembers+1);

        Expense storage expense = groupExpenses[msg.sender];
        expense.totalAmount = totalAmount;
        expense.share = share;
        expense.settled = false;

        for(uint256 i=0; i<groups[msg.sender].members.length; i++)
        {
            users[groups[msg.sender].members[i]].net+=share;
        }

        emit ExpenseAdded(msg.sender, totalAmount);
    }

    function getShare() public view returns(uint256){
        return groupExpenses[msg.sender].share;
    }

    function getAdd() public view returns(address)
    {
        return groups[msg.sender].owner;
    }

    function makePayment(string memory username, address payable receiver) public payable {
        require(usernameToAddress[username] == msg.sender, "Invalid Credentials.");
        require(groups[groupowners[username]].usernames[username] == true, "You must be in the group to make a payment");
        require(groupExpenses[groupowners[username]].totalAmount > 0, "No expense was recorded for this receiver");

        Expense storage expense = groupExpenses[groupowners[username]];

        require(expense.share == msg.value, "Incorrect payment amount");
        require(!expense.hasPaid[msg.sender], "Paid Already !");



        receiver.transfer(msg.value);

        expense.hasPaid[msg.sender] = true;

        emit PaymentReceived(msg.sender, groups[msg.sender].owner, msg.value);
    }

    function PaymentSettled() public onlyGroupOwner{
        bool flag = true;
        for(uint i=0; i < groups[msg.sender].members.length; i++)
        {
            if(groupExpenses[msg.sender].hasPaid[groups[msg.sender].members[i]] == false)
            {
                flag = false;
                break;
            }
        }
        if(flag)
        {
            groupExpenses[msg.sender].settled = true;
        }
        emit PaymentCompleted(msg.sender, flag);
    }
}