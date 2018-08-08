import React from 'react';
import PropTypes from 'prop-types';
import {compose} from 'recompose';
import {connect} from 'react-redux';
import {createStructuredSelector} from 'reselect';

import ContextLink from '../../../elements/ContextLink';
import services from '../../../modules/services';

const SiteDashboardLink = ({children, siteId}) => {
  const location = siteId == null ? '/' : `/sites/${siteId}`;
  return (
    <ContextLink linkSite="Center" location={location}>
      {children}
    </ContextLink>
  );
};

SiteDashboardLink.propTypes = {
  children: PropTypes.node.isRequired,
  siteId: PropTypes.string,
};

const enhance = compose(
  connect(
    createStructuredSelector({
      siteId: services.selectors.siteId,
    }),
  ),
);

export default enhance(SiteDashboardLink);
