import React from 'react';
import PropTypes from 'prop-types';
import { withRouter } from 'react-router';

import { Scrolling } from 'flight-reactware';

class ScrollToTopRoute extends React.Component {
  static propTypes = {
    children: PropTypes.element.isRequired,
    location: PropTypes.any,
  };

  componentDidMount() {
    var hash = window.location.hash;
    if (hash) {
      Scrolling.scrollTo(hash.substring(1));
    }
  }

  componentDidUpdate(prevProps) {
    if ( this.props.location.action === 'POP' ) {
      return;
    }
    if (this.props.location.pathname !== prevProps.location.pathname) {
      window.scrollTo(0, 0);
    }
    var hash = window.location.hash;
    if (hash) {
      Scrolling.scrollTo(hash.substring(1));
    }
  }

  render() {
    return this.props.children;
  }
}

export default withRouter(ScrollToTopRoute);
