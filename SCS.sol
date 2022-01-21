// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "hardhat/console.sol";
import "./SCN.sol";
import "@openzeppelin/contracts@4.4.2/token/ERC1155/utils/ERC1155Holder.sol";

contract SCS is ERC1155Holder{
    
    mapping(string => Company) public companies;
    mapping(string => bool) public registered;

    string[] public companyNames;
    
    modifier isRegistered(string memory _name) {
        require(registered[_name], "Unidentified Company");
        _;
    }

    function addCompoany(string memory _name, string memory _date, uint _amount, address[] memory _directors, uint min_approval) public {
        require(!registered[_name], "Duplicated Company");
        Company c = new Company(_name,  _date, _amount, _directors, min_approval);

        companies[_name] = c;
        registered[_name] = true;
        companyNames.push(_name);
        console.log("Company %s register!", _name);
    }

    function showCompany() public view{
        console.log("SCS address: %s", address(this));
        for(uint i = 0; i < companyNames.length; ++i) {
            console.log("%s: %s", companyNames[i], address(companies[companyNames[i]]));
        }
    }

    function issue(string memory _name, uint _amount) 
    public 
    isRegistered(_name) 
    {
        Company c = companies[_name];
        c.submitAction(msg.sender, "issue", _amount, address(this));
    }

    function burn(string memory _name, uint _amount) 
    public 
    isRegistered(_name) 
    {
        Company c = companies[_name];
        c.submitAction(msg.sender, "burn", _amount, address(this));
    }

    function reissue(string memory _name, uint _amount)
    public
    isRegistered(_name)
    {
        Company c = companies[_name];
        c.submitAction(msg.sender, "reissue", _amount, address(this));
    }

    function transfer(string memory _name, address target, uint _amount) 
    public
    isRegistered(_name)
    {
        Company c = companies[_name];
        c.submitAction(msg.sender, "transfer", _amount, target);
    }
 
    function redeem(string memory _name, address target, uint _amount) 
    public
    
    isRegistered(_name)
    {
        Company c = companies[_name];
        c.submitAction(msg.sender, "redeem", _amount, target);
    }

    function confirmAction(string memory _name, uint _acIndex) 
    public 
    isRegistered(_name)
    {
        Company c = companies[_name];
        c.confirmAction(msg.sender, _acIndex);
    }

}
