import {createSelector} from 'reselect';
import {loadingStates} from 'flight-reactware';

import {NAME} from './constants';

const servicesState = (state) => state[NAME];
const servicesData = (state) => servicesState(state).data;
const servicesMeta = (state) => servicesState(state).meta;

// Return the site id, if any, that has been specified.
//
// Site users have access only to their site.  The site to use is implicitly
// their site; a site id will not have been specified and this function will
// return null;
//
// Admins can access any site.  To ensure we're showing the correct site for
// them, the site's id must be explicitly stated and this function will return
// that id.
export function siteId(state) {
  return servicesMeta(state).siteId;
}

export function loadError(state) {
  return servicesMeta(state).error;
}

// The data downloaded from Center about the site.
function siteData(state) {
  return servicesData(state).site;
}

export const site = createSelector(
  siteData,
  siteId,

  (site, id) => {
    return {
      ...site,
      id: id,
    };
  },
);

export const retrieval = createSelector(
  servicesState,
  () => 'singleton',

  loadingStates.selectors.retrieval,
);
