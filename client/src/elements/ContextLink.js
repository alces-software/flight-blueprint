import React from 'react';
import PropTypes from 'prop-types';

import { ContextLink as ReactwareContextLink } from 'flight-reactware';

const ContextLink = ({ linkSite, location, children, ...passThroughProps }) => (
  <ReactwareContextLink
    link={ReactwareContextLink.makeLink(linkSite, location)}
    site={process.env.REACT_APP_SITE}
    {...passThroughProps}
  >
    {children}
  </ReactwareContextLink>
);

ContextLink.propTypes = {
  children: PropTypes.node.isRequired,
  linkSite: PropTypes.string.isRequired,
  location: PropTypes.string.isRequired,
};

ContextLink.makeLinkProps = (...props) => ReactwareContextLink.makeLinkProps(
  process.env.REACT_APP_SITE,
  ...props,
);

export default ContextLink;
