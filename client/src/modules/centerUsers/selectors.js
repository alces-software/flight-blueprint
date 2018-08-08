import { createSelector } from 'reselect';
import { loadingStates } from 'flight-reactware';

import { NAME } from './constants';

const usersState = state => state[NAME];
const usersData = state => usersState(state).data;
// const usersMeta = state => usersState(state).meta;

export const retrieval = createSelector(
  usersState,
  () => 'singleton',

  loadingStates.selectors.retrieval,
);

export const currentUser = createSelector(
  usersData,

  (user) => {
    if (user == null) {
      return user;
    }
    return {
      ...user,
      isAdmin: user.role === 'admin',
    };
  },
);
