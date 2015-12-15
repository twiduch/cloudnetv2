# The *only* reasons this file exists is to pass '/vendor' to the excludes array.
# And the only reason we need that is to stop coverage reporting failing on Travis.
# So a bit of hack. Surely there is a smaller and simpler solution.

coffeeCoverage = require('coffee-coverage')
coverageVar = coffeeCoverage.findIstanbulVariable()
writeOnExit = if (if coverageVar == null then true else null)
  if (_ref = process.env.COFFEECOV_OUT) != null
    _ref
  else
    'coverage/coverage-coffee.json'
else
  null

initAll = if (_ref = process.env.COFFEECOV_INIT_ALL) != null then _ref == 'true' else true

coffeeCoverage.register({
  instrumentor: 'istanbul',
  basePath: process.cwd(),
  exclude: ['/test', '/node_modules', '/.git', '/vendor'],
  coverageVar: coverageVar,
  writeOnExit: writeOnExit,
  initAll: initAll
})
