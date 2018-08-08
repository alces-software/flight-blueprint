import React from 'react';
import PropTypes from 'prop-types';
import Helmet from 'react-helmet';

import {ProductBar} from 'flight-reactware';

const Page = ({children, pageKey, title}) => {
  // XXX Items to appear in product bar go here.
  const items = [];
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
  pageKey: PropTypes.string,
  title: PropTypes.string.isRequired,
};

export default Page;
