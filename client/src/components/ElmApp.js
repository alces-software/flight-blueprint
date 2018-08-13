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

  // App currently just requires a single Int to be passed via flags, to use as
  // initial random seed.
  const initialRandomSeed = Math.floor(Math.random() * Number.MAX_SAFE_INTEGER);
  return (
    <ReactElmComponent
      flags={initialRandomSeed}
      ports={setupPorts}
      src={ElmApp}
    />
  );
};

export default ElmAppComponent;
