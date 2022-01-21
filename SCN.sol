// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "hardhat/console.sol";
import "@openzeppelin/contracts@4.4.2/token/ERC1155/ERC1155.sol";

contract Company is ERC1155 {

    uint TOKENID = 0;
    struct Action {
        address promotor;
        bool executed;
        uint numConfirmations;
        string actionName;
        uint amount;
        address target;
    }

    string name;
    string fundingDate;
    uint shares;
    address[] public directors;
    uint public numConfirmationsRequired;

    Action[] public actions;

    mapping(address => bool) public Director;
    mapping(string => bool) public ValidAction;
    mapping(uint => mapping(address => bool)) public isConfirmed;

    event SubmitAction(
        address indexed director,
        uint indexed acIndex
    );

    event ConfirmAction(
        address indexed director,
        uint indexed acIndex
    );

    modifier isDirector(address _director) {
        require(Director[_director], "Not Director");
        _;
    }

    modifier isValidAction(string memory _action) {
        require(ValidAction[_action], "Invalid Action");
        _;
    }

    modifier notExecuted(uint _acIndex) {
        require(!actions[_acIndex].executed, "Executed Action");
        _;
    }
    
    modifier notConfirmed(address _director, uint _acIndex) {
        require(!isConfirmed[_acIndex][_director], "The director already confirmed");
        _;
    }

    constructor(string memory _name, string memory _fundingDate, uint _shares, address[] memory _directors, uint _numConfirmationsRequired) ERC1155("https://hgliu1998.github.io/SampleERC1155/api/token/{id}.json") {
        require(_directors.length > 0, "owners required");
        require(_numConfirmationsRequired > 0 && _numConfirmationsRequired <= _directors.length, "invalid number of required confirmations");
        require(_shares > 0, "shares should be at least 1");

        for (uint i = 0; i < _directors.length; i++) {
            address director = _directors[i];

            require(director != address(0), "invalid owner");
            require(!Director[director], "Director not unique");

            Director[director] = true;
            directors.push(director);
        }

        numConfirmationsRequired = _numConfirmationsRequired;
        name = _name;
        fundingDate = _fundingDate;
        shares = _shares;

        issue(_shares);

        ValidAction["issue"] = true;
        ValidAction["burn"] = true;
        ValidAction["reissue"] = true;
        ValidAction["transfer"] = true;
        ValidAction["redeem"] = true;
    }

    function compareString(string memory a, string memory b) public pure returns (bool) {
        return (keccak256(abi.encodePacked((a))) == keccak256(abi.encodePacked((b))));
    }

    function submitAction(address _director, string memory _actionName, uint _amount, address _target) 
    public 
    isDirector(_director)
    isValidAction(_actionName)
    {
        require(_amount > 0);
        if (compareString(_actionName, "transfer") || compareString(_actionName, "redeem")) {
            require(_target != address(0));
        }

        uint acIndex = actions.length;
        actions.push(
            Action({
                promotor: _director,
                executed: false,
                numConfirmations: 0,
                actionName: _actionName,
                amount: _amount,
                target: _target
            })
        );
        //isConfirmed[acIndex][_director] = true;
        console.log("Public new action: (%s, %s)", acIndex, _actionName);
        emit SubmitAction(_director, acIndex);
    }
    
    function confirmAction(address _director, uint _acIndex)
    public
    isDirector(_director)
    notExecuted(_acIndex)
    notConfirmed(_director, _acIndex)
    {
        Action storage action = actions[_acIndex];
        action.numConfirmations += 1;
        isConfirmed[_acIndex][_director] = true;
        console.log("Action %s - %s, number of confirm: %s", _acIndex, action.actionName, action.numConfirmations);
        if (action.numConfirmations >= numConfirmationsRequired) {
            executeAction(_acIndex);
            console.log("Action %s exectue", _acIndex);
        }
        
        emit ConfirmAction(_director, _acIndex);
    }

    function executeAction(uint _acIndex) private{
        Action storage action = actions[_acIndex];

        action.executed = true;

        if (compareString(action.actionName, "issue")) {
            issue(action.amount);
        }
        else if (compareString(action.actionName, "burn")) {
            burn(action.amount);
        }
        else if (compareString(action.actionName, "reissue")) {
            reissue(action.amount);
        }
        else if (compareString(action.actionName, "transfer")) {
            transfer(action.target, action.amount);
        }
        else if (compareString(action.actionName,"redeem")) {
            redeem(action.target, action.amount);
        }
        
    }

    function issue(uint _amount) private {
        _mint(msg.sender, TOKENID, _amount, "");
        console.log("Issue Success!!");
    }
    
    function burn(uint _amount) private {
        _burn(msg.sender, TOKENID, _amount);
        console.log("Burn Success!!");

    }

    function reissue(uint _amount) private {
        _burn(msg.sender, TOKENID, _amount);
        _mint(msg.sender, TOKENID, 2 * _amount, "");
        console.log("Reissue Success!!");

    }

    function transfer(address target, uint _amount) private {
        safeTransferFrom(msg.sender, target, TOKENID, _amount, "");
        console.log("Transfer Success!!");

    }

    function redeem(address target, uint _amount) private {
        safeTransferFrom(target, msg.sender, TOKENID, _amount, "");
        _burn(msg.sender, TOKENID, _amount);
        console.log("Redemption Success!!");

    }
}
