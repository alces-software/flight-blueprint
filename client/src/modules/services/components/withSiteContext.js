import {compose, lifecycle, withProps} from 'recompose';
import {connect} from 'react-redux';
import {renderRoutes} from 'react-router-config';

import * as actions from '../actions';

const SiteContext = ({children, route}) => {
  return renderRoutes(route.routes);
};

export default function withSiteContext() {
  const enhance = compose(
    withProps((props) => ({siteId: props.match.params.siteId})),

    connect(),

    lifecycle({
      componentDidMount: function componentDidMount() {
        const {dispatch, siteId} = this.props;
        if (siteId != null) {
          dispatch(actions.explicitSiteRequested(siteId));
        }
        const request = dispatch(actions.fetchTerminalServicesConfig(siteId));
        if (request) {
          request.catch((error) => {
            console.log('error:', error); // eslint-disable-line no-console
            return error;
          });
        }
      },

      componentWillReceiveProps: function componentWillReceiveProps(nextProps) {
        if (this.props.siteId !== nextProps.siteId) {
          if (nextProps.siteId != null) {
            this.props.dispatch(
              actions.explicitSiteRequested(nextProps.siteId),
            );
          }
          const action = actions.fetchTerminalServicesConfig(nextProps.siteId);
          const request = this.props.dispatch(action);
          if (request) {
            request.catch((error) => {
              console.log('error:', error); // eslint-disable-line no-console
              return error;
            });
          }
        }
      },
    }),
  );

  return enhance(SiteContext);
}
