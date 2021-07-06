http = require('http')

expect = require('expect.js')

redirects = require('../redirects')
server = require('../server')

describe 'redirects logic', ->
  it 'should not redirect on good address', ->
    r = redirects.computeRedirect('get', 'hTtPs', 'www.mathdown.net', '/?doc=foo')
    expect(r).to.equal(null)

  it 'should redirect to https', ->
    r = redirects.computeRedirect('GET', 'http', 'www.mathdown.net', '/?doc=foo')
    expect(r.status).to.equal(301)
    expect(r.headers.Location).to.equal('https://www.mathdown.net/?doc=foo')

  it 'should redirect to www', ->
    r = redirects.computeRedirect('GET', 'https', 'mathdown.net', '/')
    expect(r.status).to.equal(301)
    expect(r.headers.Location).to.equal('//www.mathdown.net/')

  it 'should redirects POST with 307', ->
    r = redirects.computeRedirect('POST', 'http', 'www.mathdown.net', '/quux')
    expect(r.status).to.equal(307)
    expect(r.headers.Location).to.equal('https://www.mathdown.net/quux')

# Always run server, ignoring env.SITE_TO_TEST - it's hard to test an arbitrary live site
# because passing Host: header would confuse hosting's routing to our app.
describe 'redirects server behavior', ->
  httpServer = null

  before (done) ->
    httpServer = server.main(0, done)  # auto select port

  after () ->
    # Not waiting for server to close - won't happen if the client kept open
    # connections, https://github.com/nodejs/node-v0.x-archive/issues/5052
    httpServer.close()

  it 'should redirect to https and www', (done) ->
    reqOptions = {
      hostname: 'localhost'
      port: httpServer.address().port
      path: '/?doc=about'
      headers: {Host: 'mathdown.net'}
    }
    http.get reqOptions, (res) ->
      expect(res.statusCode).to.equal(301)
      # http.IncomingMessage.headers are lower-cased.
      expect(res.headers.location).to.equal('https://www.mathdown.net/?doc=about')
      done()

  it 'should not have a redirect loop', (done) ->
    reqOptions = {
      hostname: 'localhost'
      port: httpServer.address().port
      path: '/?doc=about'
      headers: {Host: 'Www.mathdown.NET', 'x-forwarded-proto': 'hTTps'}
    }
    http.get reqOptions, (res) ->
      expect(res.statusCode).to.equal(200)
      done()

  it 'should handle missing Host: header', (done) ->
    reqOptions = {
      hostname: 'localhost'
      port: httpServer.address().port
      path: '/?doc=about'
    }
    getWithoutHost = (reqOptions, callback) ->
      # http module adds 'Host: localhost:42' header if omitted, have to actively remove it.
      req = http.request(reqOptions, callback)
      req.removeHeader('host')
      req.end()
    getWithoutHost reqOptions, (res) ->
      expect(res.statusCode).to.equal(200)
      done()

run()