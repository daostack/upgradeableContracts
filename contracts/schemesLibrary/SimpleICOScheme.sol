pragma solidity ^0.4.24;

import '../proxies/Upgradeable.sol';
import '../controller/Avatar.sol';
import "../controller/ControllerInterface.sol";
import "openzeppelin-solidity/contracts/ownership/Ownable.sol";
import "openzeppelin-solidity/contracts/math/SafeMath.sol";
import "openzeppelin-solidity/contracts/lifecycle/Destructible.sol";


/**
 * @title SimpleICO scheme.
 * @dev A universal scheme to allow organizations to open a simple ICO and get donations.
 */
contract SimpleICOScheme is Upgradeable {
    using SafeMath for uint;


    address avatarContractICO; // Avatar is a contract for users that want to send ether without calling a function.
    uint totalEthRaised;
    bool public isHalted; // The admin of the ICO can halt the ICO at any time, and also resume it.



    uint public cap; // Cap in Eth
    uint price; // Price represents Tokens per 1 Eth
    uint startBlock;
    uint endBlock;
    address beneficiary; // all funds received will be transferred to this address.
    address admin; // The admin can halt or resume ICO.


    // A mapping from the organization (Avatar) address to the saved data of the organization:
    //mapping(address=>Organization) public organizationsICOInfo;


    event DonationReceived(address indexed organization, address indexed _beneficiary, uint _incomingEther, uint indexed _tokensAmount);

    /**
     * @dev Allowing admin to halt an ICO.
     */
    function haltICO() public {
        require(msg.sender == admin);
        isHalted = true;
    }

    /**
     * @dev Allowing admin to reopen an ICO.
     */
    function resumeICO() public {
        require(msg.sender == admin);
        isHalted = false;
    }

    /**
     * @dev Check is an ICO is active (halted is still considered active). Active ICO:
     * 1. The organization is registered.
     * 2. The ICO didn't reach it's cap yet.
     * 3. The current block isn't bigger than the "endBlock" & Smaller then the "startBlock"
     * @return bool which represents a successful of the function
     */
    function isActive() public view returns(bool) {
        if (totalEthRaised >= cap) {
            return false;
        }
        if (block.number >= endBlock) {
            return false;
        }
        if (block.number <= startBlock) {
            return false;
        }
        return true;
    }

    /**
     * @dev Donating ethers to get tokens.
     * If the donation is higher than the remaining ethers in the "cap",
     * The donator will get the change in ethers.
     * @param _avatar The Avatar's of the organization.
     * @param _beneficiary The donator's address - which will receive the ICO's tokens.
     * @return uint number of tokens minted for the donation.
     */
    function donate(Avatar _avatar, address _beneficiary) public payable {

        // Check ICO is active:
        require(isActive(), "ICO must be active in order to donate");

        // Check ICO is not halted:
        require(!isHalted, "ICO is halted");

        require(msg.value != 0, "Please send ether");

        uint incomingEther;
        uint change;

        // Compute how much tokens to buy:
        if ( msg.value > cap.sub(totalEthRaised) ) {
            incomingEther = cap.sub(totalEthRaised);
            change = (msg.value).sub(incomingEther);
        } else {
            incomingEther = msg.value;
        }

        uint tokens = incomingEther.mul(price);
        // Update total raised, call event and return amount of tokens bought:
        totalEthRaised += incomingEther;
        // Send ether to the defined address, mint, and send change to beneficiary:
        beneficiary.transfer(incomingEther);

        require(ControllerInterface(_avatar.owner()).mintTokens(tokens, _beneficiary, address(_avatar)));
        if (change != 0) {
            _beneficiary.transfer(change);
        }
        emit DonationReceived(_avatar, _beneficiary, incomingEther, tokens);
        require(tokens != 0, "Tokens should not be 0");
    }

    function initialize(
        address sender,
        uint _cap,
        uint _price,
        uint _startBlock,
        uint _endBlock,
        address _beneficiary,
        address _admin
        ) public payable
    {
        super.initialize(sender);
        _initialize(
            _cap, _price, _startBlock, _endBlock, _beneficiary, _admin);
    }

    function _initialize(
        uint _cap,
        uint _price,
        uint _startBlock,
        uint _endBlock,
        address _beneficiary,
        address _admin)
        internal
    {
        cap = _cap;
        price = _price; // Price represents Tokens per 1 Eth
        startBlock = _startBlock;
        endBlock = _endBlock;
        beneficiary = _beneficiary; // all funds received will be transferred to this address.
        admin = _admin;
    }
}
