import React from 'react';
import PropTypes from 'prop-types';
import Helmet from 'react-helmet';
import Route from 'react-router/Route';
import Switch from 'react-router/Switch';
import { CSSTransitionGroup } from 'react-transition-group';
import { compose } from 'recompose';
import { matchRoutes } from 'react-router-config';
import { withRouter } from 'react-router';

import { Page } from 'flight-reactware';

import ScrollToTop from './ScrollToTop';
import SitePage from './Page';
import routes from '../routes';
import appVersion from '../version';


// Use our own version of `renderRoutes` which incorporates currently
// unreleased fixes from `react-router-config`'s `renderRoutes`.  The
// important fix being the ability to pass props to the `Switch` used
// internally by `renderRoutes`.
//
// This fix is important due to the nesting of `Switch` under
// `CSSTransitionGroup`.  When a `Switch` is nested under
// `CSSTransitionGroup`, we must make sure that it uses the same `location`
// when transitioning out as it did when transitioning in.  If it doesn't, the
// `Switch` which is transitioning out, will perform unnecessary mounting and
// unmounting of its children due to different components matching the updated
// location.
//
// At best, this results in unnecessary processing and a less smooth
// animation.  If the components have a side-effect when mounted or unmounted,
// something may be broken.
//
// We're currently using `react-router-config@1.0.0-beta.4`.  When a new
// release is made, we can revert to using `react-router-config`'s
// `renderRoutes`.
//
/* eslint-disable react/jsx-sort-props */
/* eslint-disable react/jsx-max-props-per-line */
/* eslint-disable react/jsx-tag-spacing */
/* eslint-disable semi */
const renderRoutes = (routes, extraProps = {}, switchProps = {}) => routes ? (
  <Switch {...switchProps}>
    {routes.map((route, i) => (
      <Route
        key={route.key || i}
        path={route.path}
        exact={route.exact}
        strict={route.strict}
        render={(props) => (
          <route.component {...props} {...extraProps} route={route}/>
        )}
      />
    ))}
  </Switch>
) : null
/* eslint-enable react/jsx-sort-props */
/* eslint-enable react/jsx-max-props-per-line */
/* eslint-enable react/jsx-tag-spacing */
/* eslint-enable semi */

const productName = process.env.REACT_APP_PRODUCT_NAME;

const propTypes = {
  location: PropTypes.object,
  route: PropTypes.object,
};

const App = ({ location, route }) => {
  const branch = matchRoutes(routes, location.pathname);
  const lastRouteComponent = branch[branch.length - 1].route;

  return (
    <ScrollToTop>
      <Page
        serviceText={process.env.REACT_APP_SERVICE_TEXT}
        site={process.env.REACT_APP_SITE}
      >
        <Helmet
          defaultTitle={productName}
          titleTemplate={`${productName} - %s`}
        >
          <meta
            content={appVersion}
            name="client-version"
          />
        </Helmet>
        <SitePage
          pageKey={lastRouteComponent.pageKey}
          title={lastRouteComponent.title}
        >
          <CSSTransitionGroup
            transitionEnterTimeout={250}
            transitionLeave={false}
            transitionName="fade"
          >
            <div key={lastRouteComponent.key || location.pathname}>
              {renderRoutes(route.routes, {}, { location: location })}
            </div>
          </CSSTransitionGroup>
        </SitePage>
      </Page>
    </ScrollToTop>
  );
};

App.propTypes = propTypes;

const enhance = compose(
  withRouter,
);

export default enhance(App);
