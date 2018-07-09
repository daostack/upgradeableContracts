pragma solidity ^0.4.24;

import './Proxy.sol';
import './UpgradeabilityStorage.sol';


/**
 * @title UpgradeabilityProxy
 * @dev This contract represents a proxy where the implementation address to which it will delegate can be upgraded
 */
contract UpgradeabilityProxy is Proxy, UpgradeabilityStorage {

    address public owner;

    /**
    * @dev Constructor function
    */
    constructor(address _owner, address _version) public {
        _implementation = _version;
        owner = _owner;
    }

    /**
    * @dev Upgrades the implementation to the requested version
    * @param _version representing the version name of the new implementation to be set
    */
    function upgradeTo(address _version) public {
        require(msg.sender == owner);
        _implementation = _version;
    }

}
