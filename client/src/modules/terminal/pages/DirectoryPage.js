import React from 'react';
import PropTypes from 'prop-types';
import { Container } from 'reactstrap';
import { Redirect } from 'react-router';
import { compose, branch, nest, renderComponent } from 'recompose';
import { connect } from 'react-redux';
import { createStructuredSelector } from 'reselect';
import { auth, showSpinnerUntil } from 'flight-reactware';

import centerUsers from '../../../modules/centerUsers';
import services from '../../../modules/services';

import CenterAccountIsViewerError from '../components/CenterAccountIsViewerError';
import LoadError from '../components/LoadError';
import NoCenterAccountError from '../components/NoCenterAccountError';
import NotLoggedInError from '../components/NotLoggedInError';
import TerminalPage from './TerminalPage';

const NestedLoadError = nest(Container, LoadError);
const NestedNotLoggedInError = nest(Container, NotLoggedInError);
const NestedNoCenterAccount = nest(Container, NoCenterAccountError);
const NestedCenterAccountIsViewerError = nest(Container, CenterAccountIsViewerError);

const propTypes = {
  jwt: PropTypes.string.isRequired,
  site: PropTypes.shape({
    name: PropTypes.string.isRequired,
    id: PropTypes.string,
  }).isRequired,
};

const env = {
  LANG: 'en_GB.UTF-8',
};

const DirectoryPage = ({ jwt, site }) => {
  const title = (
    <span>
      Flight Directory: {site.name}
    </span>
  );
  const overview = (
    <span>
      Alces Flight Directory provides user, group and host management across your compute estate.
    </span>
  );

  return (
    <TerminalPage
      auth={{
        jwt: jwt,
        siteId: site.id,
      }}
      columns={120}
      overview={overview}
      socketIOPath={process.env.REACT_APP_TERMINAL_SERVICE_SOCKET_IO_PATH}
      socketIOUrl={process.env.REACT_APP_TERMINAL_SERVICE_URL}
      termProps={{
        env: env,
      }}
      title={title}
    />
  );
};

DirectoryPage.propTypes = propTypes;

const enhance = compose(
  connect(createStructuredSelector({
    centerUser: centerUsers.selectors.currentUser,
    centerUserRetrieval: centerUsers.selectors.retrieval,
    jwt: auth.selectors.ssoToken,
    servicesRetrieval: services.selectors.retrieval,
    site: services.selectors.site,
    ssoUser: auth.selectors.currentUserSelector,
  })),

  branch(
    ({ ssoUser }) => ssoUser == null,
    renderComponent(() => <NestedNotLoggedInError />),
  ),

  showSpinnerUntil(
    ({ centerUser, centerUserRetrieval, servicesRetrieval }) => {
      const waitingOnCenterUser = !centerUserRetrieval.initiated
        || centerUserRetrieval.pending;
      const centerUserPresent = centerUser != null;
      const waitingOnServices = !servicesRetrieval.initiated
        || servicesRetrieval.pending;

      return !waitingOnCenterUser && (!centerUserPresent || !waitingOnServices);
    }
  ),

  branch(
    ({ centerUser }) => centerUser == null,
    renderComponent(() => <NestedNoCenterAccount />),
  ),

  branch(
    ({ centerUser }) => centerUser.role === 'viewer',
    renderComponent(() => <NestedCenterAccountIsViewerError />),
  ),

  branch(
    ({ servicesRetrieval }) => servicesRetrieval.rejected,
    renderComponent(() => <NestedLoadError />),
  ),

  branch(
    ({ site }) => !site,
    renderComponent(() => <Redirect to="/" />),
  )
);

export default enhance(DirectoryPage);
