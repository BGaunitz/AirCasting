import test from 'blue-tape';
import { mock } from './helpers';
import { MobileSessionsMapCtrl } from '../code/controllers/_mobile_sessions_map_ctrl';

test('registers a callback to map.goToAddress', t => {
  const callbacks = [];
  const $scope = {
    $watch: (str, callback) => str.includes('address') ? callbacks.push(callback) : null
  };
  // diff from fixed_sessions_map_ctrl removeAllMarkers
  const map = mock('goToAddress');
  const controller = _MobileSessionsMapCtrl({ $scope, map, callbacks });

  callbacks.forEach(callback => callback({ location: 'new york' }));

  t.true(map.wasCalledWith('new york'));

  t.end();
});

const _MobileSessionsMapCtrl = ({ $scope, map, callback, storage }) => {
  const expandables = { show: () => {} };
  const sensors = { setSensors: () => {} };
  const functionBlocker = { block: () => {} };
  const params = { get: () => {} };
  const rectangles = { clear: () => {} };
  const infoWindow = { hide: () => {} };
  const _storage = {
    updateDefaults: () => {},
    updateFromDefaults: () => {},
    ...storage
  };
  // diff from fixed_sessions_map_ctrl
  const markersClusterer = {
    clear: () => {}
  };
  const _map = {
    goToAddress: () => {},
    unregisterAll: () => {},
    removeAllMarkers: () => {},
    ...map
  };

  return MobileSessionsMapCtrl($scope, params, _map, sensors, expandables, _storage, null, null, null, null, functionBlocker, null, rectangles, infoWindow, markersClusterer);
};
