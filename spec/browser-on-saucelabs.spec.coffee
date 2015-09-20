# Usage: By default runs local server, tests it via tunnel;
# if SITE_TO_TEST env var is set to a publicly accessible URL, tests that skipping server & tunnel.

require('coffee-script/register')
server = require('../server')

sauceTunnel = require('sauce-tunnel')
http = require('http')
wd = require('wd')  # TODO: compare vs http://webdriver.io/
assert = require('assert')
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
buildUrl = env.CI_BUILD_URL || env.BUILD_URL || env.WERCKER_BUILD_URL || build
commit = env.CI_COMMIT_ID || env.COMMIT || env.GIT_COMMIT || env.TRAVIS_COMMIT || env.WERCKER_GIT_COMMIT
branch = env.CI_BRANCH || env.BRANCH || env.GIT_BRANCH || env.TRAVIS_BRANCH || env.WERCKER_GIT_BRANCH

siteToTest = env.SITE_TO_TEST

tunnelId = build
tags = []
tags.push('shippable') if env.SHIPPABLE
# Shippable tries too hard to be Travis-compatible, sets TRAVIS.
tags.push('travis') if env.TRAVIS && ! env.SHIPPABLE
tags.push('drone') if env.DRONE
tags.push('wercker') if env.WERCKER_BUILD_URL
tags.push(env.CI_NAME) if env.CI_NAME  # Covers Codeship (could also use env.CODESHIP).

desired = {
  browserName: 'internet explorer'
  version: '8'
  platform: 'Windows XP'
  name: if siteToTest then 'smoke test ' + siteToTest else 'smoke test'
  build: "#{buildUrl} [#{branch}] commit #{commit}"
  tags: tags
  # Most my tests timeout a lot due crashing without cleanup (see below);
  # this will waste less Sauce resources than default 90s.
  'idle-timeout': 30
}

# TODO refactor me more

createBrowserAndTest = (site) ->
  browser = null

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

    browser.init desired, (err) ->
      assert.ifError(err)
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
  #     assert.ifError(err)
  #     console.log(chalk.yellow('LOG TYPES:'), arrayOfLogTypes)
  #     browser.log 'browser', (err, arrayOfLogs) ->
  #       assert.ifError(err)
  #       console.log(chalk.yellow('LOGS:'), arrayOfLogs)
  #       done()

  afterAll (done) ->
    browser.quit()
    done()

  it 'should load and render math', (done) ->
    # Kludge: set to failed first, change to passed if we get to the end without crashing.
    browser.sauceJobStatus false, ->
      browser.get site + '?doc=_mathdown_test_smoke', (err) ->
        assert.ifError(err)
        browser.waitFor wd.asserters.jsCondition('document.title.match(/smoke test/)'), 10000, (err, value) ->
          assert.ifError(err)
          browser.waitForElementByCss '.MathJax_Display', 15000, (err, el) ->
            assert.ifError(err)
            el.text (err, text) ->
              assert.ifError(err)
              if not text.match(/^\s*α\s*$/)
                assert.fail(text, '/^\s*α\s*$/', 'math text is wrong', ' match ')
              console.log(chalk.green('\nALL PASSED\n'))
              browser.sauceJobStatus(true)
              done()


jasmine.DEFAULT_TIMEOUT_INTERVAL = 30000;

if siteToTest  # Testing existing instance
  describe "#{siteToTest} on IE8", ->
    createBrowserAndTest(siteToTest)
else  # Run local server, test it via tunnel
  describe 'Served site on IE8', ->
    tunnel = null
    # https://docs.saucelabs.com/reference/sauce-connect/#can-i-access-applications-on-localhost-
    # lists ports we can use.
    httpServer = null
    port = 8001
    site = 'http://localhost:' + port

    beforeAll (done) ->
      httpServer = server.main(port)
      # TODO: wait until server is actually up

      tunnel = new sauceTunnel(sauceUser, sauceKey, tunnelId, true, ['--verbose'])
      console.log('Creating tunnel...')
      tunnel.start (status) ->
        assert(status, 'tunnel creation failed')
        console.log('tunnel created')
        desired['tunnel-identifier'] = tunnel.identifier
        console.log(desired)
        done()

    afterAll (done) ->
      tunnel.stop ->
        console.log(chalk.green('Tunnel stopped, cleaned up.'))
        httpServer.close()
        done()

    describe 'nested', ->
      createBrowserAndTest(site)

# TODO: Cleanup doesn't happen if there were errors.
# Replace assert with Jasmine's expect()?

# TODO: parallelize (at least between different browsers).
# I probably want Vows instead of Jasmine, see https://github.com/jlipps/sauce-node-demo example.
