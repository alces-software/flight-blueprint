/*=============================================================================
 * Copyright (C) 2017 Stephen F. Norledge and Alces Flight Ltd.
 *
 * This file is part of Flight Launch.
 *
 * All rights reserved, see LICENSE.txt.
 *===========================================================================*/

import version from './data/version.json';

export const major = version.major;
export const minor = version.minor;
export default `${version.major}.${version.minor}`;
