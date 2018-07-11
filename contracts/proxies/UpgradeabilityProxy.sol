pragma solidity ^0.4.24;

import './Proxy.sol';
import './UpgradeabilityStorage.sol';


/**
 * @title UpgradeabilityProxy
 * @dev This contract represents a proxy where the implementation address to which it will delegate can be upgraded
 */
contract UpgradeabilityProxy is Proxy, UpgradeabilityStorage {

    /**
    * @dev Constructor function
    */
    constructor(address _proxyOwner, address _version) public {
        _implementation = _version;
        proxyOwner = _proxyOwner;
    }

    /**
    * @dev Upgrades the implementation to the requested version
    * @param _version representing the version name of the new implementation to be set
    */
    function upgradeTo(address _version) public {
        require(msg.sender == proxyOwner);
        _implementation = _version;
    }

    function transferProxyOwnership(address _proxyOwner) public {
        require(msg.sender == proxyOwner);
        proxyOwner = _proxyOwner;
    }
}
