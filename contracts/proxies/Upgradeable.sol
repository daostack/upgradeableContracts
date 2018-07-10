pragma solidity ^0.4.24;

import './UpgradeabilityStorage.sol';


/**
 * @title Upgradeable
 * @dev This contract holds all the minimum required functionality for a behavior to be upgradeable.
 * This means, required state variables for owned upgradeability purpose and simple initialization validation.
 */
contract Upgradeable is UpgradeabilityStorage {

    function initialize(address sender) public payable {
        require(!isInitialized);
        isInitialized = true;
    }
}
