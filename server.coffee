# For starters, runs from manually compiled server.js.
# TODO: run as CoffeeScript.  https://github.com/floriankrueger/heroku-on-coffee
st = require('st')
http = require('http')
assert = require('assert')

port = process.env.PORT || 80;
server = http.createServer(st({
  path: process.cwd()
  index: 'index.html'
}))
server.on 'request', (req, res) ->
  console.log('[%s] < %s %s', new Date().toISOString(), req.method, req.url)
server.listen(port)
server.on 'listening', ->
  console.log('Server up, e.g. http://localhost:' + port + '/?doc=demo');
