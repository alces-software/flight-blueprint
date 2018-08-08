// Import and export the public facing API for the terminal module.

import * as components from './components';
import * as constants from './constants';
import * as pages from './pages';

export default {
  ...components,
  constants,
  pages,
};
