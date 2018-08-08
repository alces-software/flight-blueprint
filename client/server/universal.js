const path = require('path');
const fs = require('fs');

const React = require('react');
const { Provider } = require('react-redux');
const { applyMiddleware, createStore } = require('redux');
const { default: thunk } = require('redux-thunk');
const { default: promiseMiddleware } = require('redux-simple-promise');

const { renderToString } = require('react-dom/server');
const { StaticRouter } = require('react-router-dom');

const { ServerStyleSheet, StyleSheetManager } = require('styled-components');
const Cookies = require('universal-cookie');
const { default: Helmet } = require('react-helmet');

const { middleware: flightMiddleware } = require('flight-reactware');
const { default: createReducer } = require('../src/reducers');

const { default: routes } = require('../src/routes');
const { renderRoutes } = require('react-router-config');

module.exports = function universalLoader(req, res) {
  const sheet = new ServerStyleSheet();
  const filePath = path.resolve(process.env.APPROOT, 'build', 'index.html');

  fs.readFile(filePath, 'utf8', (err, htmlData) => {
    if (err) {
      console.error('read err', err);
      return res.status(404).end();
    }
    const context = {};
    const cookies = new Cookies(req.headers.cookie);

    const store = createStore(
      createReducer(cookies),
      {},
      applyMiddleware(
        flightMiddleware,
        thunk,
        promiseMiddleware()
      )
    );

    const markup = renderToString(
      <StyleSheetManager sheet={sheet.instance}>
        <Provider store={store}>
          <StaticRouter
            context={context}
            location={req.url}
          >
            {renderRoutes(routes)}
          </StaticRouter>
        </Provider>
      </StyleSheetManager>
    );

    const helmet = Helmet.renderStatic();

    if (context.url) {
      // Somewhere a `<Redirect>` was rendered
      res.writeHead(301, {
        Location: context.url
      });
      res.end();
    } else {
      // we're good, send the response
      const RenderedApp = htmlData
        .replace('<title></title>', helmet.title.toString())
        .replace('<div id="root">', '<div id="root">' + markup)
        .replace('<script id="preload">', '<script id="preload">window.__PRELOADED_STATE__ = ' + JSON.stringify(store.getState()).replace(/</g, '\\u003c') + ';')
        .replace('</head>', sheet.getStyleTags() + '</head>');
      res.send(RenderedApp);
    }
  });
};
