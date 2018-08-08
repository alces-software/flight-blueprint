import React from 'react';
import PropTypes from 'prop-types';

import ContextLink from './ContextLink';

const propTypes = {
  children: PropTypes.node.isRequired,
};

const defaultProps = {
  children: 'Alces Flight Appliance documentation site',
};

const DocsSiteLink = ({ children }) => (
  <ContextLink
    linkSite="Docs"
    location="/"
  >
    {children}
  </ContextLink>
);

DocsSiteLink.propTypes = propTypes;
DocsSiteLink.defaultProps = defaultProps;

export const docsSiteHref = ContextLink.makeLinkProps('Docs', '/',).href;

export default DocsSiteLink;
