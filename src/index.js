import yaml from 'js-yaml';

import {Main} from './Main.elm';
import registerServiceWorker from './registerServiceWorker';

const app = Main.embed(document.getElementById('root'));

const convertToYaml = object => {
  const yamlString = yaml.safeDump(object);
  app.ports.convertedYaml.send(yamlString);
};
app.ports.convertToYaml.subscribe(convertToYaml);

registerServiceWorker();
