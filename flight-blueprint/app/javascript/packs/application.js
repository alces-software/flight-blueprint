/* eslint no-console:0 */
// This file is automatically compiled by Webpack, along with any other files
// present in this directory. You're encouraged to place your actual
// application logic in a relevant structure within app/javascript and only use
// these pack files to reference that code so it'll be compiled.

import React from 'react';
import ReactDOM from 'react-dom';
import PropTypes from 'prop-types';

const Hello = props => <div>Hello {props.name}!</div>;

Hello.defaultProps = {
  name: 'David',
};

Hello.propTypes = {
  name: PropTypes.string,
};

document.addEventListener('DOMContentLoaded', () => {
  ReactDOM.render(<Hello name="React" />, document.getElementById('root'));
});
