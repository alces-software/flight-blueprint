import { combineReducers } from 'redux';
import { apiRequest, loadingStates } from 'flight-reactware';

import {
  EXPLICIT_SITE_REQUESTED,
  LOAD_TERMINAL_SERVICES_CONFIG_REQUESTED,
} from './actionTypes';

const initialState = {
  flightDirectoryConfig: null,
  site: null,
};

// A reducer to maintain the siteId.
function siteIdReducer(state = null, { meta, payload, type }) {
  switch (type) {
    case EXPLICIT_SITE_REQUESTED:
      return payload;

    case LOAD_TERMINAL_SERVICES_CONFIG_REQUESTED:
      return meta.siteId == null ? null : meta.siteId;

    default:
      return state;
  }
}

function errorReducer(state = null, action) {
  switch (action.type) {
    case LOAD_TERMINAL_SERVICES_CONFIG_REQUESTED:
    case apiRequest.resolved(LOAD_TERMINAL_SERVICES_CONFIG_REQUESTED):
      return null;

    case apiRequest.rejected(LOAD_TERMINAL_SERVICES_CONFIG_REQUESTED):
      if (action.error.response.status === 404) {
        return 'NO_TERMINAL_SERVICES';
      }
      return state;

    default:
      return state;
  }
}

const metaReducers = combineReducers({
  siteId: siteIdReducer,
  [loadingStates.constants.NAME]: loadingStates.reducer({
    pending: LOAD_TERMINAL_SERVICES_CONFIG_REQUESTED,
    resolved: apiRequest.resolved(LOAD_TERMINAL_SERVICES_CONFIG_REQUESTED),
    rejected: apiRequest.rejected(LOAD_TERMINAL_SERVICES_CONFIG_REQUESTED),
  }),
  error: errorReducer,
});

function dataReducer(state=initialState, action) {
  switch (action.type) {
    case apiRequest.resolved(LOAD_TERMINAL_SERVICES_CONFIG_REQUESTED):
      const data = action.payload.data;
      return {
        flightDirectoryConfig: data.flight_directory_config,
        site: data.site,
      };

    case apiRequest.rejected(LOAD_TERMINAL_SERVICES_CONFIG_REQUESTED):
      return initialState;

    default:
      return state;
  }
}

export default combineReducers({
  data: dataReducer,
  meta: metaReducers,
});
