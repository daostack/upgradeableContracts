pragma solidity ^0.4.24;

import './UpgradeabilityProxy.sol';


/**
 * @title SimpleICOFactory
 * @dev This contract works as a registry of versions, it holds the implementations for the registered versions.
 */
contract Factory {

    event ProxyCreated(address indexed proxy);


    /**
    * @dev Creates an upgradeable proxy
    * @param implementation representing the first implementation to be set for the proxy
    * @return address of the new proxy created
    */
    function createProxy(address proxyOwner, address implementation, bytes data) public payable returns (UpgradeabilityProxy) {
        UpgradeabilityProxy proxy = new UpgradeabilityProxy(proxyOwner, implementation);
        require(address(proxy).call.value(msg.value)(data));
        emit ProxyCreated(proxy);
        return proxy;
    }
}
