const path = require('path');

module.exports = function(config) {
  // Compile Elm; add this as first rule so Elm files don't get handled by any
  // other loader.
  config.module.rules.unshift({
    test: /\.elm$/,
    exclude: [/elm-stuff/, /node_modules/],
    use: {
      loader: 'elm-webpack-loader',
      options: {
        // Show debugger.
        debug: false,

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
