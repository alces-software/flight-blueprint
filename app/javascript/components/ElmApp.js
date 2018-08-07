import React from 'react';
import ReactElmComponent from 'react-elm-components';
import yaml from 'js-yaml';

import {Main as ElmApp} from 'Main';

const ElmAppComponent = props => {
  const setupPorts = ports => {
    const convertToYaml = object => {
      const yamlString = yaml.safeDump(object);
      ports.convertedYaml.send(yamlString);
    };
    ports.convertToYaml.subscribe(convertToYaml);
  };

  return <ReactElmComponent src={ElmApp} ports={setupPorts} />;
};

export default ElmAppComponent;
