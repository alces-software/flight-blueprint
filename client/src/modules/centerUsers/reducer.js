import { combineReducers } from 'redux';
import { apiRequest, loadingStates } from 'flight-reactware';

import {
  LOAD_CENTER_USER_REQUESTED,
} from './actionTypes';

const metaReducers = combineReducers({
  [loadingStates.constants.NAME]: loadingStates.reducer({
    pending: LOAD_CENTER_USER_REQUESTED,
    resolved: apiRequest.resolved(LOAD_CENTER_USER_REQUESTED),
    rejected: apiRequest.rejected(LOAD_CENTER_USER_REQUESTED),
  }),
});

function dataReducer(state=null, action) {
  switch (action.type) {
    case apiRequest.resolved(LOAD_CENTER_USER_REQUESTED):
      return action.payload.data;

    case apiRequest.rejected(LOAD_CENTER_USER_REQUESTED):
      return null;

    default:
      return state;
  }
}

export default combineReducers({
  data: dataReducer,
  meta: metaReducers,
});
