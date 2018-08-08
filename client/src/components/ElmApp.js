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

  return <ReactElmComponent ports={setupPorts} src={ElmApp} />;
};

export default ElmAppComponent;
