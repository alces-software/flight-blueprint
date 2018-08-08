import React from 'react';
import ReactDOM from 'react-dom';
import Cookies from 'universal-cookie';
import createHistory from 'history/createBrowserHistory';
import { ConnectedRouter, routerMiddleware } from 'react-router-redux';
import { Provider } from 'react-redux';
import { createCookieMiddleware } from 'redux-cookie';
import { createStore, applyMiddleware, compose } from 'redux';
import { renderRoutes } from 'react-router-config';

import { Analytics } from 'flight-reactware';

import middleware from './middleware';
import createReducers from './reducers';
import createLogics from './logics';
import { unregister as unregisterServiceWorker } from './registerServiceWorker';
import routes from './routes';

import './index.css';

const cookies = new Cookies();

// Grab the state from a global variable injected into the server-generated HTML
const preloadedState = window.__PRELOADED_STATE__;

// Allow the passed state to be garbage-collected
delete window.__PRELOADED_STATE__;

const history = createHistory();
const composeEnhancers = window.__REDUX_DEVTOOLS_EXTENSION_COMPOSE__ || compose;
const store = createStore(
  createReducers(cookies),
  preloadedState,
  composeEnhancers(
    applyMiddleware(
      ...middleware,
      createCookieMiddleware(cookies),
      routerMiddleware(history)
    )
  )
);

createLogics(store);

Analytics.initialize(process.env.REACT_APP_ANALYTICS_TRACKER_ID, history);

ReactDOM.render(
  <Provider store={store}>
    { /* ConnectedRouter will use the store from Provider automatically */ }
    <ConnectedRouter history={history}>
      {renderRoutes(routes)}
    </ConnectedRouter>
  </Provider>,
  document.getElementById('root')
);

unregisterServiceWorker();
