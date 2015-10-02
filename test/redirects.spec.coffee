redirects = require('../redirects')

expect = require('expect.js')

describe 'redirects logic', ->
  it 'should not redirect on good address', ->
    r = redirects.computeRedirect('get', 'hTtPs', 'www.mathdown.net', '/?doc=foo')
    expect(r).to.equal(null)

  it 'should redirect to https', ->
    r = redirects.computeRedirect('GET', 'http', 'www.mathdown.net', '/')
    expect(r.status).to.equal(301)
    expect(r.headers.Location).to.equal('https://www.mathdown.net/')

  it 'should redirect to www', ->
    r = redirects.computeRedirect('GET', 'https', 'mathdown.net', '/')
    expect(r.status).to.equal(301)
    expect(r.headers.Location).to.equal('//www.mathdown.net/')

  it 'should redirects POST with 307', ->
    r = redirects.computeRedirect('POST', 'http', 'www.mathdown.net', '/')
    expect(r.status).to.equal(307)
    expect(r.headers.Location).to.equal('https://www.mathdown.net/')
