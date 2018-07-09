pragma solidity ^0.4.24;

import './Upgradeable.sol';
import './UpgradeabilityProxy.sol';


/**
 * @title Factory
 * @dev This contract works as a registry of versions, it holds the implementations for the registered versions.
 */
contract Factory {

    event ProxyCreated(address indexed proxy);


    /**
    * @dev Creates an upgradeable proxy
    * @param version representing the first version to be set for the proxy
    * @return address of the new proxy created
    */
    function createProxy(address version) public payable returns (UpgradeabilityProxy) {
        UpgradeabilityProxy proxy = new UpgradeabilityProxy(version);
        Upgradeable(proxy).initialize.value(msg.value)(msg.sender);
        emit ProxyCreated(proxy);
        return proxy;
    }
}
