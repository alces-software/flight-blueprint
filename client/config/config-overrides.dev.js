const path = require('path');
const rewireStyledComponents = require('react-app-rewire-styled-components');

module.exports = function(config) {
  // Use your own ESLint file
  config.module.rules[0].use[0].options.useEslintrc = true;

  // Make CRA's "catchall" loader ignore .md files
  config.module.rules[1].exclude.push(/\.md$/);

  // Avoids loading multiple copies of React
  config.resolve.alias.react = path.resolve('./node_modules/react');
  // Avoids loading multiple copies of styled-components
  config.resolve.alias['styled-components'] = path.resolve(
    './node_modules/styled-components',
  );

  config = rewireStyledComponents(config);

  // Compile Elm; add this as first rule so Elm files don't get handled by any
  // other loader.
  config.module.rules.unshift({
    test: /\.elm$/,
    exclude: [/elm-stuff/, /node_modules/],
    use: {
      loader: 'elm-webpack-loader',
      options: {cwd: path.resolve('./src/elm')},
    },
  });

  return config;
};
