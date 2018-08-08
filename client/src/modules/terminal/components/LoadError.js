import React from 'react';
import PropTypes from 'prop-types';
import { MissingNotice } from 'flight-reactware';
import { compose } from 'recompose';
import { connect } from 'react-redux';
import { createStructuredSelector } from 'reselect';

import CommunitySiteLink from '../../../elements/CommunitySiteLink';
import services from '../../../modules/services';

import SiteDashboardLink from './SiteDashboardLink';

const NoTerminalServicesError = () => (
  <MissingNotice
    title="The Alces Flight Directory service is not configured for your organisation."
  >
    Your organisation has not requested access to the Alces Flight Directory
    service. Please contact your{' '}
    <SiteDashboardLink>account manager</SiteDashboardLink>
    {' '}if you would like to request this facility.
  </MissingNotice>
);

const GenericLoadError = () => (
  <MissingNotice
    title="Unable to load directory details"
  >
    Unfortunately, the details for the directory service cannot be loaded.
    Please try again, or visit our{' '}
    <CommunitySiteLink>Community Support Portal</CommunitySiteLink>
    {' '}for further help.
  </MissingNotice>
);

const LoadError = ({ error }) => {
  if (error === 'NO_TERMINAL_SERVICES') {
    return <NoTerminalServicesError />;
  } else {
    return <GenericLoadError />;
  }
};

LoadError.propTypes = {
  error: PropTypes.string,
};

const enhance = compose(
  connect(createStructuredSelector({
    error: services.selectors.loadError,
  })),
);

export default enhance(LoadError);
