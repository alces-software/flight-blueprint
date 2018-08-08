import { compose } from 'redux';
import {
  auth,
  createReducers as createFlightReducers,
  jsonApi,
  loadingStates,
  reducerUtils,
} from 'flight-reactware';
import { reducer as formReducer } from 'redux-form';
import { routerReducer } from 'react-router-redux';
import { combineReducers } from 'redux';

import * as modules from '../modules';

const entityIndexes = Object.keys(modules).reduce(
  (accum, name) => accum.concat(modules[name].indexes || []),
  [],
);

const loadingStatesConfig = Object.keys(modules).reduce(
  (accum, name) => {
    const c = modules[name].loadingStatesConfig;
    if (c) {
      accum.push(c);
    }
    return accum;
  },
  [],
);

const moduleReducers = Object.keys(modules).reduce(
  (accum, name) => {
    const m = modules[name];
    if (m.reducer) {
      accum[m.constants.NAME] = m.reducer;
    }
    return accum;
  },
  {},
);

const createAppReducers = (cookies) => ({
  ...createFlightReducers(cookies),
  ...moduleReducers,
  entities: compose(
    jsonApi.withIndexes(entityIndexes),
    loadingStates.withLoadingStates(loadingStatesConfig),
  )(jsonApi.reducer),
  form: formReducer,
  router: routerReducer,
});

export default (cookies) => {
  const appReducers = combineReducers(createAppReducers(cookies));
  return reducerUtils.withStateResetting({
    keepStateSlices: [ 'router' ],
    resetOn: [ auth.actionTypes.LOGOUT ]
  })(appReducers);
};
