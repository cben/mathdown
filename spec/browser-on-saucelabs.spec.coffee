# Usage: By default runs local server, tests it via tunnel;
# if SITE_TO_TEST env var is set to a publicly accessible URL, tests that skipping server & tunnel.

require('coffee-script/register')
server = require('../server')

sauceTunnel = require('sauce-tunnel')
http = require('http')
wd = require('wd')  # TODO: compare vs http://webdriver.io/
chalk = require('chalk')

# 'mathdown' is a sub-account I created.
sauceUser = process.env.SAUCE_USERNAME || 'mathdown'
# I hope storing this in a public test is OK given that an Open Sauce account
# is free anyway.  Can always revoke if needed...
sauceKey = process.env.SAUCE_ACCESS_KEY || '23056294-abe8-4fe9-8140-df9a59c45c7d'

sauceConnectOptions = {
  username: sauceUser
  accessKey: sauceKey
  verbose: true
  logger: console.log
}

# Build metadata
# ==============
# http://docs.travis-ci.com/user/ci-environment/#Environment-variables
# http://docs.drone.io/env.html  (Jenkins compatible)
# http://docs.shippable.com/en/latest/config.html#common-environment-variables
# https://codeship.com/documentation/continuous-integration/set-environment-variables/#default-environment-variables
# http://devcenter.wercker.com/articles/steps/variables.html
env = process.env
build = env.CI_BUILD_NUMBER || env.BUILD_ID || env.TRAVIS_BUILD_ID || (env.WERCKER_BUILD_URL || '').replace(/.*\//, '') || env.JOB_ID
travisBuildUrl = (env.TRAVIS_REPO_SLUG && env.TRAVIS_BUILD_ID && "https://travis-ci.org/#{env.TRAVIS_REPO_SLUG}/builds/#{env.TRAVIS_BUILD_ID}")
buildUrl = env.CI_BUILD_URL || env.BUILD_URL || env.WERCKER_BUILD_URL || travisBuildUrl || build
commit = env.CI_COMMIT_ID || env.COMMIT || env.GIT_COMMIT || env.TRAVIS_COMMIT || env.WERCKER_GIT_COMMIT
branch = env.CI_BRANCH || env.BRANCH || env.GIT_BRANCH || env.TRAVIS_BRANCH || env.WERCKER_GIT_BRANCH

siteToTest = env.SITE_TO_TEST

tags = []
tags.push('shippable') if env.SHIPPABLE
# Shippable tries too hard to be Travis-compatible, sets TRAVIS.
tags.push('travis') if env.TRAVIS && ! env.SHIPPABLE
tags.push('drone') if env.DRONE
tags.push('wercker') if env.WERCKER_BUILD_URL
tags.push(env.CI_NAME) if env.CI_NAME  # Covers Codeship (could also use env.CODESHIP).

commonDesired = {
  build: "#{buildUrl} [#{branch}] commit #{commit}"
  tags: tags
  # Waste less Sauce resources than default 90s if this script crashed.
  'idle-timeout': 30
}

desiredBrowsers = [
  {browserName: 'internet explorer', version: '8.0', platform: 'Windows XP'}
  {browserName: 'internet explorer', version: '9.0', platform: 'Windows 7'}
  {browserName: 'microsoftedge', version: '20.10240', platform: 'Windows 10'}
  # Arbitrary somewhat old - but not ancient - FF and Chrome versions.
  {browserName: 'firefox', version: '30.0', platform: 'Linux'}
  {browserName: 'chrome', version: '30.0', platform: 'Linux'}
  {browserName: 'safari', version: '8.1', platform: 'OS X 10.11'}
  # TODO: mobile
]

itSlowly = (text, func) -> it(text, func, 30000)
# YIKES: this affects other files, and having a big timeout everywhere
# hides forgotten done() calls :-(
jasmine.DEFAULT_TIMEOUT_INTERVAL = 30000

merge = (objs...) ->
  merged = {}
  for obj in objs
    for k, v of obj
      merged[k] = v
  merged

# I've factored parts of the test suite into "desribeFoo" functions.
# When I want to pass them values computed in beforeAll/Each blocks,
# I have to pass "getValue" callables rather than the values themselves
# (see https://gist.github.com/cben/43fcbbae95019aa73ecd).
describeBrowserTest = (browserName, getDesired, site) ->
  describe browserName, ->
    browser = null

    # Theoretically should use a custom reporter to set pass/fail status on Sauce Labs.
    # Practically this kludge works, as long as test cases set eachPassed to true when done.
    eachPassed = false
    allPassed = true

    beforeEach ->
      eachPassed = false

    afterEach ->
      if not eachPassed
        allPassed = false

    # TODO: should I reuse one browser instance for many tests?
    # From the wd docs reusing one should work but is it isolated enough?
    # I suppose `browser.get()` does reset browser state...
    # Also, seeing individual tests on SauceLabs would be cool: https://youtu.be/Dzplh1tAwIg?t=370
    beforeAll (done) ->
      browser = wd.remote('ondemand.saucelabs.com', 80, sauceUser, sauceKey)
      browser.on 'status', (info) ->
        console.log(chalk.cyan(info))
      browser.on 'command', (meth, path) ->
        console.log(' > %s: %s', chalk.yellow(meth), path)
      #browser.on 'http', (meth, path, data) ->
      #  console.log(' > %s %s %s', chalk.magenta(meth), path, chalk.grey(data))

      browser.init getDesired(), (err) ->
        expect(err).toBeFalsy()
        done()

    # TODO: inspect browser console log
    # https://support.saucelabs.com/entries/60070884-Enable-grabbing-server-logs-from-the-wire-protocol
    # https://code.google.com/p/selenium/wiki/JsonWireProtocol#/session/:sessionId/log
    # Sounds like these should work but on SauceLabs they return:
    #   Selenium error: Command not found: GET /session/XXXXXXXX-XXXX-XXXX-XXXX-XXXXe3fcc97e/log/types
    #   Selenium error: Command not found: POST /session/XXXXXXXX-XXXX-XXXX-XXXX-XXXX26210a31/log
    # respectively...
    #
    # afterEach (done) ->
    #   browser.logTypes (err, arrayOfLogTypes) ->
    #     expect(err).toBeFalsy()
    #     console.log(chalk.yellow('LOG TYPES:'), arrayOfLogTypes)
    #     browser.log 'browser', (err, arrayOfLogs) ->
    #       expect(err).toBeFalsy()
    #       console.log(chalk.yellow('LOGS:'), arrayOfLogs)
    #       done()

    afterAll (done) ->
      browser.sauceJobStatus allPassed, ->
        browser.quit()
        done()

    itSlowly 'should load and render math', (done) ->
      browser.get site + '?doc=_mathdown_test_smoke', (err) ->

        expect(err).toBeFalsy()
        browser.waitFor wd.asserters.jsCondition('document.title.match(/smoke test/)'), 10000, (err, value) ->
          expect(err).toBeFalsy()
          browser.waitForElementByCss '.MathJax_Display', 15000, (err, el) ->
            expect(err).toBeFalsy()
            el.text (err, text) ->
              expect(err).toBeFalsy()
              console.log('el.text:', text, 'match:', text.match(/^\s*α\s*$/))
              expect(text).toMatch(/^\s*α\s*$/)
              eachPassed = true
              done()

describeAllBrowsers = (getDesired, site) ->
  for b in desiredBrowsers
    do (b) ->
      name = "#{b.browserName} #{b.version} on #{b.platform}"
      describeBrowserTest(name, (-> merge(b, getDesired())), site)

if siteToTest  # Testing existing instance
  describe "#{siteToTest}", ->
    describeAllBrowsers(
      (-> merge(commonDesired, {name: 'smoke test of ' + siteToTest})),
      siteToTest)
else  # Run local server, test it via tunnel
  describe 'Served site via Sauce Connect', ->
    tunnel = null
    actualTunnelId = null
    # https://docs.saucelabs.com/reference/sauce-connect/#can-i-access-applications-on-localhost-
    # lists ports we can use.
    httpServer = null
    port = 8001
    site = 'http://localhost:' + port

    beforeAll (done) ->
      httpServer = server.main(port)
      # TODO: wait until server is actually up

      # undefined => unique tunnel id will be automatically chosen
      tunnel = new sauceTunnel(sauceUser, sauceKey, undefined, true, ['--verbose'])
      console.log(chalk.green('Creating tunnel...'))
      tunnel.start (tunnel_status) ->
        expect(tunnel_status).toBeTruthy()
        console.log('tunnel created')
        # HORRIBLE KLUDGE
        actualTunnelId = tunnel.identifier
        done()

    afterAll (done) ->
      tunnel.stop ->
        console.log(chalk.green('Tunnel stopped, cleaned up.'))
        httpServer.close()
        done()

    describeAllBrowsers(
      (-> merge(commonDesired, {
        name: 'smoke test'
        'tunnel-identifier': actualTunnelId
      })),
      site)

# TODO: parallelize (at least between different browsers).
# I probably want Vows instead of Jasmine, see https://github.com/jlipps/sauce-node-demo example?
# Or Nightwatch.js?
