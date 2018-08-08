/*=============================================================================
 * Copyright (C) 2017 Stephen F. Norledge and Alces Flight Ltd.
 *
 * This file is part of Flight Launch.
 *
 * All rights reserved, see LICENSE.txt.
 *===========================================================================*/

import * as modules from '../modules';

const logics = Object.keys(modules).reduce(
  (accum, name) => accum.concat(modules[name].logic || []),
  [],
);

export default (store) => {
  store.subscribe(() => {
    logics.forEach(logic => {
      logic(store.dispatch, store.getState);
    });
  });
};
