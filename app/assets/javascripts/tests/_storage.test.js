import test from 'blue-tape';
import deepEqual from 'fast-deep-equal';
import { storage } from '../code/services/_storage';

test('resetAddress calls params.update with emptied address', t => {
  const params = mock('update');
  const storageService = _storage(params);
  storageService.set('location', { address: 'new york', distance: 10 });

  storageService.resetAddress();

  t.true(params.wasCalledWith({ data: { location: { address: '', distance: 10 } } }));

  t.end();
});

const _storage = (params) => {
  const $rootScope = { $new: () => ({ $watch: () => {} }) };
  return storage(params, $rootScope);
};

const mock = (name) => {
  let calls = [];

  return {
    [name]: arg => calls.push(arg),
    wasCalled: () => calls.length === 1,
    wasCalledWith: (arg) => deepEqual(arg, calls[calls.length - 1])
  };
};
