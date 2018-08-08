var webpack = require('webpack');
var path = require('path');
var fs = require('fs');

var nodeModules = {};
fs.readdirSync('node_modules')
  .filter(function(x) {
    return ['.bin'].indexOf(x) === -1;
  })
  .forEach(function(mod) {
    nodeModules[mod] = 'commonjs ' + mod;
  });
delete nodeModules['flight-reactware'];

module.exports = {
  entry: './server/index.js',
  target: 'node',
  output: {
    path: path.join(__dirname, '../build/server'),
    filename: 'server.js'
  },
  externals: nodeModules,
  plugins: [
    new webpack.NormalModuleReplacementPlugin(/\.css$/, 'node-noop'),
//    new webpack.IgnorePlugin(/\.(css|less)$/),
    new webpack.BannerPlugin({banner: 'require("source-map-support").install();',
                              raw: true, entryOnly: false })
  ],
  devtool: 'sourcemap',
  module: {
    rules: [
      {
        test: /\.js$/,
        exclude: /(node_modules|bower_components)/,
        use: {
          loader: 'babel-loader',
          options: {
            presets: ['es2015', 'react-app']
          }
        }
      },
      {
        exclude: [
          /\.html$/,
          /\.(js|jsx)$/,
          /\.css$/,
          /\.json$/,
          /\.bmp$/,
          /\.gif$/,
          /\.jpe?g$/,
          /\.png$/,
        ],
        loader: require.resolve('file-loader'),
        options: {
          name: '../static/media/[name].[hash:8].[ext]',
        },
      },
      {
        test: [/\.bmp$/, /\.gif$/, /\.jpe?g$/, /\.png$/],
        loader: require.resolve('url-loader'),
        options: {
          limit: 10000,
          name: '../static/media/[name].[hash:8].[ext]',
        },
      }
    ]
  }
}
