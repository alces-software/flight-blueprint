import React from 'react';
import PropTypes from 'prop-types';
import { MissingNotice } from 'flight-reactware';
import { compose } from 'recompose';
import { connect } from 'react-redux';
import { createStructuredSelector } from 'reselect';

import services from '../../../modules/services';

import SiteDashboardLink from './SiteDashboardLink';

const CenterAccountIsViewerError = () => {
  return (
    <MissingNotice
      title="The Alces Flight Directory service is unavailable to your account."
    >
      The Alces Flight Directory service is not available to site viewer
      accounts. Please contact one of your{' '}
      <SiteDashboardLink>account managers</SiteDashboardLink>
      {' '}for further information.
    </MissingNotice>
  );
};

CenterAccountIsViewerError.propTypes = {
  error: PropTypes.string,
};

const enhance = compose(
  connect(createStructuredSelector({
    ssoUser: services.selectors.loadError,
  })),
);

export default enhance(CenterAccountIsViewerError);
