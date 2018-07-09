pragma solidity ^0.4.24;

import '../schemesLibrary/SimpleICOScheme.sol';


/**
 * @title SimpleICO scheme.
 * @dev A universal scheme to allow organizations to open a simple ICO and get donations.
 */
contract SimpleICOSchemeV2Mock is SimpleICOScheme {
    event NewDonator(address indexed donator, uint _amount);

    mapping(address => bool) public donators;

    function donate(address _beneficiary) public payable {

        super.donate(_beneficiary);

        if (!donators[msg.sender]) {
            donators[msg.sender] = true;
            emit NewDonator(msg.sender, msg.value);
        }
    }
}
