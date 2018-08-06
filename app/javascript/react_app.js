import React from 'react';
import ReactElmComponent from 'react-elm-components';
import yaml from 'js-yaml';

import {Main as ElmApp} from 'Main';

const Header = props => <div>Header</div>;
const Footer = props => <div>Footer</div>;

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

const App = props => {
  return (
    <div>
      <Header />
      <ElmAppComponent />
      <Footer />
    </div>
  );
};

export default App;
