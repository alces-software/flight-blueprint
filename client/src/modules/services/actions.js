import {auth} from 'flight-reactware';

import {
  EXPLICIT_SITE_REQUESTED,
  LOAD_TERMINAL_SERVICES_CONFIG_REQUESTED,
} from './actionTypes';
import {retrieval} from './selectors';

const centerBaseUrl = process.env.REACT_APP_CENTER_BASE_URL;

export function fetchTerminalServicesConfig(siteId) {
  return (dispatch, getState) => {
    const ssoUser = auth.selectors.currentUserSelector(getState());
    if (ssoUser == null) {
      return;
    }

    const {initiated, rejected} = retrieval(getState());
    if (!initiated || rejected) {
      let url;
      if (siteId == null) {
        url = `${centerBaseUrl}/terminal_services`;
      } else {
        url = `${centerBaseUrl}/sites/${siteId}/terminal_services`;
      }
      const action = {
        type: LOAD_TERMINAL_SERVICES_CONFIG_REQUESTED,
        meta: {
          apiRequest: {
            config: {
              url: url,
              withCredentials: true,
            },
          },
          loadingState: {
            key: 'singleton',
          },
          siteId: siteId,
        },
      };
      return dispatch(action);
    }
  };
}

export function explicitSiteRequested(siteId) {
  return {
    type: EXPLICIT_SITE_REQUESTED,
    payload: siteId,
  };
}
