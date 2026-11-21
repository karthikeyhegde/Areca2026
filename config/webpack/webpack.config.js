// See the shakacode/shakapacker README and docs directory for advice on customizing your webpackConfig.
const path = require('path')
const { generateWebpackConfig } = require('shakapacker')
const webpack = require('webpack')
const VueLoaderPlugin = require('vue-loader/lib/plugin')

const jqueryPath = path.resolve(__dirname, '../../node_modules/jquery')

const config = generateWebpackConfig({
  resolve: {
    alias: {
      // Exactly one jQuery for the app, Bootstrap, jQuery UI and select2. Without
      // this, packages that bundle their own jQuery copy get a separate instance
      // and plugins attach to the wrong one.
      jquery$: path.join(jqueryPath, 'dist/jquery.js')
    }
  },
  plugins: [
    new VueLoaderPlugin(),
    // Carried over from the old Webpacker config/webpack/environment.js:
    // expose jQuery and Popper globally for Bootstrap 4, jQuery UI and select2.
    new webpack.ProvidePlugin({
      $: 'jquery',
      jQuery: 'jquery',
      Popper: ['popper.js', 'default']
    })
  ]
})

// Vue Loader 15 must find its rule before Shakapacker's generic oneOf rules.
config.module.rules.unshift({ test: /\.vue$/, loader: 'vue-loader' })

module.exports = config
