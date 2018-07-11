pragma solidity ^0.4.24;

import '../proxies/UpgradeabilityStorage.sol';
import '../controller/Avatar.sol';
import "../controller/ControllerInterface.sol";
import "openzeppelin-solidity/contracts/math/SafeMath.sol";


/**
 * @title SimpleICO scheme.
 * @dev A universal scheme to allow organizations to open a simple ICO and get donations.
 */
contract SimpleICOScheme is UpgradeabilityStorage {
    using SafeMath for uint;

    bool public isHalted; // The admin of the ICO can halt the ICO at any time, and also resume it.



    uint public cap; // Cap in Eth
    uint price; // Price represents Tokens per 1 Eth
    uint startBlock;
    uint endBlock;
    address beneficiary; // all funds received will be transferred to this address.
    address admin; // The admin can halt or resume ICO.

    address avatar;

    bool isInitialized;

    event DonationReceived(address indexed organization, address indexed _beneficiary, uint _incomingEther, uint indexed _tokensAmount);

    function () public payable {
        // Return ether if couldn't donate.
        donate(msg.sender);
    }

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
        if (this.balance >= cap) {
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
     * @param _beneficiary The donator's address - which will receive the ICO's tokens.
     * @return uint number of tokens minted for the donation.
     */
    function donate(address _beneficiary) public payable {
        // Check ICO is active:
        require(isActive(), "ICO must be active in order to donate");

        // Check ICO is not halted:
        require(!isHalted, "ICO is halted");

        require(msg.value != 0, "Please send ether");

        uint incomingEther;
        uint change;

        // Compute how much tokens to buy:
        if ( msg.value > cap.sub(address(this).balance) ) {
            incomingEther = cap.sub(address(this).balance);
            change = (msg.value).sub(incomingEther);
        } else {
            incomingEther = msg.value;
        }

        uint tokens = incomingEther.mul(price);

        // Send ether to the defined address, mint, and send change to beneficiary:
        beneficiary.transfer(incomingEther);

        require(ControllerInterface(Avatar(avatar).owner()).mintTokens(tokens, _beneficiary, address(avatar)));
        if (change != 0) {
            _beneficiary.transfer(change);
        }
        emit DonationReceived(avatar, _beneficiary, incomingEther, tokens);
        require(tokens != 0, "Tokens should not be 0");
    }

    function initialize(
        uint _cap,
        uint _price,
        uint _startBlock,
        uint _endBlock,
        address _beneficiary,
        address _admin,
        address _avatar
        ) public
    {
        require(!isInitialized);

        isInitialized = true;
        cap = _cap;
        price = _price; // Price represents Tokens per 1 Eth
        startBlock = _startBlock;
        endBlock = _endBlock;
        beneficiary = _beneficiary; // all funds received will be transferred to this address.
        admin = _admin;
        avatar = _avatar;
    }
}
