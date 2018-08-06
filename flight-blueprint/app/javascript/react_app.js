import React from 'react';
import Elm from 'react-elm-components';

import {Main as ElmApp} from 'Main';

const Header = props => <div>Header</div>;
const Footer = props => <div>Footer</div>;

const App = props => {
  return (
    <div>
      <Header />
      <Elm src={ElmApp} />
      <Footer />
    </div>
  );
};

export default App;
