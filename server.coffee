st = require('st')
http = require('http')
assert = require('assert')

exports.main = (port) ->
  port = port || process.env.PORT || process.env.OPENSHIFT_NODEJS_PORT || 8080
  listen_on_address = process.env.OPENSHIFT_NODEJS_IP || '0.0.0.0'  # INADDR_ANY
  httpServer = http.createServer(st({
    path: process.cwd()
    index: 'index.html'
  }))
  httpServer.on 'request', (req, res) ->
    # Note: full URLs might still appear in other platform logs, e.g. heroku[router]
    anonimizedUrl = req.url.replace(/([?&])doc=[^&]*/, '$1doc=...')
    # TODO: also log our responses, especially errors.
    console.log('[%s] %s %s %s < %s %s', new Date().toISOString(), req.method, req.headers.host, anonimizedUrl, req.socket.remoteAddress, req.headers['user-agent'])
  httpServer.on 'listening', ->
    console.log('HttpServer up, e.g. http://localhost:' + port + '/?doc=demo');
  httpServer.listen(port, listen_on_address)
  return httpServer

if module is require.main
  exports.main()
