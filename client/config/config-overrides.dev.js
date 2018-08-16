const path = require('path');
const rewireStyledComponents = require('react-app-rewire-styled-components');

// Ensure output always coloured; needed as overriding `process.stdout.isTTY`
// in `client/scripts/customized-config.js`.
const chalk = require('chalk');
chalk.enabled = true;

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
      options: {
        // Show debugger.
        debug: true,

        // Report all warnings and info about unused imports.
        warn: true,
        verbose: true,

        // Recompile when any Elm file changed (rather than just when Main
        // changed, which is default with standard CRA settings).
        forceWatch: true,

        cwd: path.resolve('./src/elm'),
      },
    },
  });

  return config;
};
