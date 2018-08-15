import React from 'react';
import ReactElmComponent from 'react-elm-components';
import yaml from 'js-yaml';

import {Main as ElmApp} from '../elm/Main.elm';

const ElmAppComponent = (props) => {
  const setupPorts = (ports) => {
    const convertToYaml = (object) => {
      const yamlString = yaml.safeDump(object);
      ports.convertedYaml.send(yamlString);
    };
    ports.convertToYaml.subscribe(convertToYaml);
  };

  // App currently just requires a single 32-bit Int to be passed via flags, to
  // use as initial random seed (see
  // http://package.elm-lang.org/packages/mgold/elm-random-pcg/5.0.2/Random-Pcg#initialSeed).
  const initialRandomSeed = Math.floor(Math.random() * 0xFFFFFFFF);
  return (
    <ReactElmComponent
      flags={initialRandomSeed}
      ports={setupPorts}
      src={ElmApp}
    />
  );
};

export default ElmAppComponent;
