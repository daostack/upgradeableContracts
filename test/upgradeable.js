const helpers = require('./helpers');
const constants = require('./constants');
const DaoCreator = artifacts.require("./DaoCreator.sol");
const Avatar = artifacts.require("./Avatar.sol");
const StandardTokenMock = artifacts.require('./test/StandardTokenMock.sol');
const ControllerCreator = artifacts.require("./ControllerCreator.sol");

const SimpleICO = artifacts.require('./SimpleICOScheme.sol');
const SimpleICOV2 = artifacts.require('./SimpleICOSchemeV2Mock.sol');

const Factory = artifacts.require('./proxies/SimpleICOFactory.sol');
const Proxy = artifacts.require('./proxies/UpgradeabilityProxy.sol');



var daoCreator;
var testSetup = new helpers.TestSetup();

const setupOrganization = async function (daoCreatorOwner,founderToken,founderReputation) {
  var controllerCreator = await ControllerCreator.new({gas: constants.ARC_GAS_LIMIT});
  daoCreator = await DaoCreator.new(controllerCreator.address,{gas:constants.ARC_GAS_LIMIT});
  var org = await helpers.setupOrganization(daoCreator,daoCreatorOwner,founderToken,founderReputation);
  return org;
};

const setup = async function (accounts) {
  testSetup.beneficiary = accounts[0];
  testSetup.fee = 10;
  testSetup.standardTokenMock = await StandardTokenMock.new(accounts[1],100);
  testSetup.org = await setupOrganization(accounts[0], 1000, 1000);
};

contract('Upgradeable', function (accounts) {

  it('should work', async function () {
    await setup(accounts);
    const impl_v1 = await SimpleICO.new();
    const impl_v2 = await SimpleICOV2.new();

    const registry = await Factory.new();
    //await registry.addVersion("1.0", impl_v1_0.address)
    //await registry.addVersion("1.1", impl_v1_1.address)
    //


     const {logs} = await registry.createProxy(
       impl_v1.address,
       10000,
       1,
       web3.eth.blockNumber,
       web3.eth.blockNumber + 500,
       testSetup.org.avatar.address,
       accounts[0]
     );

    const {proxy} = logs.find(l => l.event === 'ProxyCreated').args;

    await daoCreator.setSchemes(testSetup.org.avatar.address,[proxy],[""],["0x00000000"]);

    await SimpleICO.at(proxy).donate(testSetup.org.avatar.address, accounts[0], {value: 2});

    await Proxy.at(proxy).upgradeTo(impl_v2.address)

    await SimpleICOV2.at(proxy).donate(testSetup.org.avatar.address, accounts[0], {value: 3});

    const balance = await testSetup.org.token.balanceOf(accounts[0]);

    assert.equal(balance.toNumber(), 1005, "Balance of tokens should be 5");
  })

})
