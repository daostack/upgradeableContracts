pragma solidity ^0.4.24;

import '../schemesLibrary/SimpleICOScheme.sol';
import './UpgradeabilityProxy.sol';


/**
 * @title SimpleICOFactory
 * @dev This contract works as a registry of versions, it holds the implementations for the registered versions.
 */
contract SimpleICOFactory {

    event ProxyCreated(address indexed proxy);


    /**
    * @dev Creates an upgradeable proxy
    * @param version representing the first version to be set for the proxy
    * @return address of the new proxy created
    */
    function createProxy(
        address version,
        uint _cap,
        uint _price,
        uint _startBlock,
        uint _endBlock,
        address _beneficiary,
        address _admin,
        address  _avatar
        ) public payable returns (UpgradeabilityProxy)
    {
        UpgradeabilityProxy proxy = new UpgradeabilityProxy(msg.sender, version);
        SimpleICOScheme(proxy).initialize(
            msg.sender, _cap, _price, _startBlock, _endBlock, _beneficiary, _admin, _avatar);
        emit ProxyCreated(proxy);
        return proxy;
    }
}
