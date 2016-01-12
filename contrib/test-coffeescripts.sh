NODE_PATH=./frontend/app/scripts/:./frontend/spec \
  ./node_modules/.bin/istanbul cover \
  ./node_modules/.bin/_mocha -- \
  --opts frontend/spec/mocha.opts \
  $(find frontend/spec -name '*_spec.coffee')
