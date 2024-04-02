/*
 * Copyright (c) 2021 Contributors to the Eclipse Foundation
 *
 * This program and the accompanying materials are made
 * available under the terms of the Eclipse Public License 2.0
 * which is available at https://www.eclipse.org/legal/epl-2.0/
 *
 * SPDX-License-Identifier: EPL-2.0
 */
const path = require('path');
const ReactRefreshWebpackPlugin = require('@pmmmwh/react-refresh-webpack-plugin');
const ForkTsCheckerWebpackPlugin = require('fork-ts-checker-webpack-plugin');

module.exports = (env, options) => {
  const isDevelopment = options.mode !== 'production';
  return {
    mode: isDevelopment ? 'development' : 'production',
    target: isDevelopment ? "web" : "browserslist",
    entry: ["./src/index.tsx"],
    module: {
      rules: [
        {
          test: /\.(ts|js)x?$/,
          exclude: /node_modules/,
          use: "babel-loader",
        },
      ],
    },
    resolve: {
      extensions: [".tsx", ".ts", ".js"],
    },
    plugins: [
      isDevelopment && new ReactRefreshWebpackPlugin(),
      new ForkTsCheckerWebpackPlugin({
        async: false,
        eslint: {
          files: "./src/**/*",
        },
      }),
    ].filter(Boolean),
    output: {
      path: path.resolve(__dirname, "public"),
      filename: "bundle.js",
    },
    devServer: {
      contentBase: path.join(__dirname, "public"),
      compress: true,
      port: 3000,
    },
  }
};