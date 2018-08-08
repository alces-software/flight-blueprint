import {
  LOAD_CENTER_USER_REQUESTED,
} from './actionTypes';

const centerBaseUrl = process.env.REACT_APP_CENTER_BASE_URL;

export function loadUser() {
  const url = `${centerBaseUrl}/users`;
  return {
    type: LOAD_CENTER_USER_REQUESTED,
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
    },
  };
}
