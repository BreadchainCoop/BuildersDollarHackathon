// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.22;

import 'forge-std/console.sol';
import 'forge-std/StdJson.sol';
import 'script/Constants.s.sol';
import {Script} from 'forge-std/Script.sol';
import {TransparentUpgradeableProxy} from '@oz/proxy/transparent/TransparentUpgradeableProxy.sol';
import {ProxyAdmin} from '@oz/proxy/transparent/ProxyAdmin.sol';
import {OBDYieldDistributor, IOBDYieldDistributor} from 'contracts/OBDYieldDistributor.sol';
import {MockEAS} from 'mocks/MockEAS.sol';
import {EIP173ProxyWithReceive} from '@bdtoken/vendor/EIP173ProxyWithReceive.sol';
import {BuildersDollar} from '@bdtoken/BuildersDollar.sol';

/// @dev used to deploy the YieldDistributor contract for scripts and tests
contract Common is Script {
  string public _configPath = string(bytes('./script/deploy/config/deployYD.json'));

  string internal _configData;
  address internal _admin;
  address internal _token;
  address internal _eas;

  uint256 internal _seasonDuration;
  uint64 internal _currentSeasonExpiry;

  address[] internal _attestors;

  IOBDYieldDistributor.YieldDistributorParams internal _params;
  OBDYieldDistributor public obdYieldDistributor;

  /// @dev for scripts
  function _readConfigFile() internal {
    _configData = vm.readFile(_configPath);
    _admin = stdJson.readAddress(_configData, '._admin');
    _token = stdJson.readAddress(_configData, '._token');
    _eas = stdJson.readAddress(_configData, '._eas');
    _seasonDuration = stdJson.readUint(_configData, '._seasonDuration');
    _currentSeasonExpiry = uint64(stdJson.readUint(_configData, '._currentSeasonExpiry'));
    _attestors = abi.decode(stdJson.parseRaw(_configData, '._attestors'), (address[]));

    _params = IOBDYieldDistributor.YieldDistributorParams({
      cycleLength: uint64(stdJson.readUint(_configData, '._cycleLength')),
      lastClaimedTimestamp: uint64(stdJson.readUint(_configData, '._lastClaimedTimestamp')),
      minVouches: stdJson.readUint(_configData, '._minVouches'),
      precision: stdJson.readUint(_configData, '._precision')
    });
  }

  /// @dev for tests
  function _readConfigRegistry() internal {
    _admin = ADMIN;
    _token = TOKEN;
    _seasonDuration = SEASON_DURATION;
    _currentSeasonExpiry = SEASON_START_TIMESTAMP + uint64(SEASON_DURATION);
    _attestors = [address(0x420), address(0x421), address(0x423)];

    _params = IOBDYieldDistributor.YieldDistributorParams({
      cycleLength: CYCLE_LENGTH,
      lastClaimedTimestamp: LAST_CLAIMED_TIMESTAMP,
      minVouches: MIN_VOUCHES,
      precision: PRECISION
    });
  }

  /// @dev for tests
  function _generateMockDataForTest() internal {
    _eas = address(new MockEAS());
    _token = address(new BuildersDollar(DAI, A_DAI, AAVE_LP, AAVE_REWARDS));
    EIP173ProxyWithReceive _proxy = new EIP173ProxyWithReceive(
      _token, address(this), abi.encodeWithSelector(BuildersDollar.initialize.selector, BD_NAME, BD_SYM)
    );
  }

  /// @dev for scripts and tests
  function _deployYD() internal {
    bytes memory _implementationData = abi.encodeWithSelector(
      OBDYieldDistributor.initialize.selector, _token, _eas, _seasonDuration, _currentSeasonExpiry, _params, _attestors
    );
    address _implementation = address(new OBDYieldDistributor());
    address _proxy = address(new TransparentUpgradeableProxy(_implementation, _admin, _implementationData));
    console.log('Deployed YieldDistributor at address:', _proxy);

    obdYieldDistributor = OBDYieldDistributor(_proxy);
  }
}
