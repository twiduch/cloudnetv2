var src = './app';
var dest = "./build";
var assets = dest + "/assets";
var historyApiFallback = require('connect-history-api-fallback');

module.exports = {
  browserSync: {
    server: {
      // Serve up our build folder
      baseDir: dest,
      // Serve all requests through index.html. Useful for SPA pushState apps
      middleware: [ historyApiFallback() ]
    }
  },
  sass: {
    src: src + "/styles/*.{sass,scss}",
    dest: assets,
    settings: {
      indentedSyntax: true, // Enable .sass syntax!
      imagePath: 'images', // Used by the image-url helper
      includePaths: [
        '../node_modules/zurb-foundation-5/scss/',
        '../node_modules/zurb-foundation-5/scss/foundation/components',
        '../node_modules/nprogress/'
      ]
    }
  },
  images: {
    src: src + "/images/**",
    dest: assets  + '/images'
  },
  markup: {
    src: src + "/index.html",
    dest: dest
  },
  browserify: {
    // A separate bundle will be generated for each
    // bundle config in the list below
    bundleConfigs: [{
      entries: src + '/scripts/main.coffee',
      dest: assets,
      outputName: 'main.js',
      // Additional file extentions to make optional
      extensions: ['.coffee'],
      // list of modules to make require-able externally
      require: [],
      // list of modules to exclude from bundled output
      external: ['coffee-script/register', 'require-dir'],
      paths: [src + '/scripts']
    }]
  },
  production: {
    cssSrc: assets + '/*.css',
    jsSrc: assets + '/*.js',
    dest: assets
  }
};
