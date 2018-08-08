import React from 'react';
import PropTypes from 'prop-types';
import Helmet from 'react-helmet';
import { connect } from 'react-redux';
import { createStructuredSelector } from 'reselect';

import { ProductBar } from 'flight-reactware';

import getItems from '../modules/items';
import { services, users } from '../modules';

const Page = ({
  children,
  currentUser,
  pageKey,
  site,
  siteRetrieval,
  title,
}) => {
  const items = getItems(currentUser, site, siteRetrieval);
  return (
    <div>
      <Helmet>
        <title>{title}</title>
      </Helmet>
      <ProductBar
        items={items}
        noaccount
        nosearch
        page={pageKey || title || ''}
        site={process.env.REACT_APP_SITE}
      />
      {children}
    </div>
  );
};

Page.propTypes = {
  children: PropTypes.node.isRequired,
  currentUser: PropTypes.object,
  pageKey: PropTypes.string,
  site: PropTypes.object,
  siteRetrieval: PropTypes.object.isRequired,
  title: PropTypes.string.isRequired,
};

export default connect(createStructuredSelector({
  site: services.selectors.site,
  siteRetrieval: services.selectors.retrieval,
  currentUser: users.selectors.currentUser,
}))(Page);
