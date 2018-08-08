import React from 'react';
import PropTypes from 'prop-types';
import { MissingNotice } from 'flight-reactware';
import { compose } from 'recompose';
import { connect } from 'react-redux';
import { createStructuredSelector } from 'reselect';

import CommunitySiteLink from '../../../elements/CommunitySiteLink';
import ContextLink from '../../../elements/ContextLink';
import services from '../../../modules/services';

const NoCenterAccountError = () => {
  return (
    <MissingNotice title="Unable to access the Alces Flight Directory service.">
      The Alces Flight Directory service is available to organisation managers
      only. Please{' '}
      <ContextLink
        linkSite="Home"
        location="/contact"
      >
        contact us
      </ContextLink>
      {' '}for more details or visit our{' '}
      <CommunitySiteLink>Community Support Portal</CommunitySiteLink>
      {' '}for further help.
    </MissingNotice>
  );
};

NoCenterAccountError.propTypes = {
  error: PropTypes.string,
};

const enhance = compose(
  connect(createStructuredSelector({
    ssoUser: services.selectors.loadError,
  })),
);

export default enhance(NoCenterAccountError);
