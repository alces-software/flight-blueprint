import React from 'react';
import PropTypes from 'prop-types';

import ContextLink from './ContextLink';

const propTypes = {
  children: PropTypes.node.isRequired,
};

const defaultProps = {
  children: 'Alces Flight Community',
};

const CommunityLink = ({ children }) => (
  <ContextLink
    linkSite="Community"
    location="/"
  >
    {children}
  </ContextLink>
);

CommunityLink.propTypes = propTypes;
CommunityLink.defaultProps = defaultProps;

export default CommunityLink;
