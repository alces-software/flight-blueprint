import React from 'react';
import PropTypes from 'prop-types';
import {MissingNotice} from 'flight-reactware';
import {compose} from 'recompose';
import {connect} from 'react-redux';
import {createStructuredSelector} from 'reselect';

// import CommunitySiteLink from '../../../elements/CommunitySiteLink';
import services from '../../../modules/services';

import SignInLink from './SignInLink';

const NotLoggedInError = () => {
  return (
    <MissingNotice title="Unable to access the Alces Flight Directory service.">
      You must be signed in to your Alces Flight account in order to access the
      Alces Flight Directory service for your organisation. Please{' '}
      <SignInLink>sign in</SignInLink> and try again.
    </MissingNotice>
  );
};

NotLoggedInError.propTypes = {
  error: PropTypes.string,
};

const enhance = compose(
  connect(
    createStructuredSelector({
      ssoUser: services.selectors.loadError,
    }),
  ),
);

export default enhance(NotLoggedInError);
