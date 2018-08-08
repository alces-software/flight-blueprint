import { createMiddleware } from 'flight-reactware';

import thunk from 'redux-thunk';
import logger from 'redux-logger';

export default [
  thunk,
  logger,
  createMiddleware({
    api: {
      axiosClientConfig: {
        baseURL: process.env.REACT_APP_API_BASE_URL,
      },
    },
  }),
];
