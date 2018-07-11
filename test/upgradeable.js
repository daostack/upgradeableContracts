const helpers = require('./helpers');
const constants = require('./constants');
const DaoCreator = artifacts.require("./DaoCreator.sol");
const Avatar = artifacts.require("./Avatar.sol");
const StandardTokenMock = artifacts.require('./test/StandardTokenMock.sol');
const ControllerCreator = artifacts.require("./ControllerCreator.sol");

const SimpleICO = artifacts.require('./SimpleICOScheme.sol');
const SimpleICOV2 = artifacts.require('./SimpleICOSchemeV2Mock.sol');

const Factory = artifacts.require('./proxies/Factory.sol');
const Proxy = artifacts.require('./proxies/UpgradeabilityProxy.sol');



var daoCreator;
var testSetup = new helpers.TestSetup();

const setupOrganization = async function(daoCreatorOwner, founderToken, founderReputation) {
  var controllerCreator = await ControllerCreator.new({
    gas: constants.ARC_GAS_LIMIT
  });
  daoCreator = await DaoCreator.new(controllerCreator.address, {
    gas: constants.ARC_GAS_LIMIT
  });
  var org = await helpers.setupOrganization(daoCreator, daoCreatorOwner, founderToken, founderReputation);
  return org;
};

const setup = async function(accounts) {
  testSetup.beneficiary = accounts[0];
  testSetup.fee = 10;
  testSetup.standardTokenMock = await StandardTokenMock.new(accounts[1], 100);
  testSetup.org = await setupOrganization(accounts[0], 1000, 1000);
};

contract('Upgradeable', function(accounts) {

  it('should mint 5 tokens to donator while updating the proxy implementation', async function() {

    await setup(accounts);

    const initData = helpers.encodeCall('initialize', ['uint', 'uint', 'uint', 'uint', 'address', 'address', 'address'], [
      10000,
      1,
      web3.eth.blockNumber,
      web3.eth.blockNumber + 500,
      testSetup.org.avatar.address,
      accounts[0],
      testSetup.org.avatar.address
    ]);

    const impl_v1 = await SimpleICO.new();
    const impl_v2 = await SimpleICOV2.new();

    const factory = await Factory.new();

    const {
      logs
    } = await factory.createProxy(
      accounts[0],
      impl_v1.address,
      initData
    );

    const {
      proxy
    } = logs.find(l => l.event === 'ProxyCreated').args;

    assert.equal(await Proxy.at(proxy).implementation(), impl_v1.address, "Implementation for the proxy should be version 1");

    await daoCreator.setSchemes(testSetup.org.avatar.address, [proxy], [""], ["0x00000000"]);

    await SimpleICO.at(proxy).donate(accounts[0], {
      from: accounts[0],
      value: 3
    });

    var balance = await testSetup.org.token.balanceOf(accounts[0]);

    assert.equal(balance.toNumber(), 1003, "Balance of tokens should be 1003");

    await Proxy.at(proxy).upgradeTo(impl_v2.address);

    assert.equal(await Proxy.at(proxy).implementation(), impl_v2.address, "Implementation for the proxy should be version 2");

    var donateLogs = (await SimpleICOV2.at(proxy).sendTransaction({
      from: accounts[0],
      value: 2
    })).logs;

    const {
      donator,
      _amount
    } = donateLogs.find(l => l.event === 'NewDonator').args;

    assert.equal(donator, accounts[0], "Donator address should be " + accounts[0] + " (the same as accounts[0])");
    assert.equal(_amount.toNumber(), 2, "Amount donated should be 2");

    balance = await testSetup.org.token.balanceOf(accounts[0]);

    assert.equal(balance.toNumber(), 1005, "Balance of tokens should be 1005");
  });

  it('upgrade proxy implementation from non-owner address should revert', async function() {

    await setup(accounts);

    const initData = helpers.encodeCall('initialize', ['uint', 'uint', 'uint', 'uint', 'address', 'address', 'address'], [
      10000,
      1,
      web3.eth.blockNumber,
      web3.eth.blockNumber + 500,
      testSetup.org.avatar.address,
      accounts[0],
      testSetup.org.avatar.address
    ]);

    const impl_v1 = await SimpleICO.new();
    const impl_v2 = await SimpleICOV2.new();

    const factory = await Factory.new();

    const {
      logs
    } = await factory.createProxy(
      accounts[0],
      impl_v1.address,
      initData
    );

    const {
      proxy
    } = logs.find(l => l.event === 'ProxyCreated').args;

    try {
      await Proxy.at(proxy).upgradeTo(impl_v2.address, {
        from: accounts[1]
      });
      assert(false, "upgrade from non-owner address should revert");
    } catch (ex) {
      helpers.assertVMException(ex);
    }
  });

  it('calling initialize after proxy deployment should revert', async function() {

    await setup(accounts);

    const initData = helpers.encodeCall('initialize', ['uint', 'uint', 'uint', 'uint', 'address', 'address', 'address'], [
      10000,
      1,
      web3.eth.blockNumber,
      web3.eth.blockNumber + 500,
      testSetup.org.avatar.address,
      accounts[0],
      testSetup.org.avatar.address
    ]);

    console.log();

    const impl_v1 = await SimpleICO.new();
    const impl_v2 = await SimpleICOV2.new();

    const factory = await Factory.new();

    const {
      logs
    } = await factory.createProxy(
      accounts[0],
      impl_v1.address,
      initData
    );

    const {
      proxy
    } = logs.find(l => l.event === 'ProxyCreated').args;

    try {
      await SimpleICO.at(proxy).sendTransaction({
          from: accounts[0],
          data: initData
        });

      assert(false, "calling initialize after proxy deployment should revert");
    } catch (ex) {
      helpers.assertVMException(ex);
    }
  });
});
