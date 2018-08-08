// Import and export the public facing API for this module.

import * as actions from './actions';
import * as constants from './constants';
import * as selectors from './selectors';
import reducer from './reducer';

export default {
  actions,
  constants,
  reducer,
  selectors,
};
