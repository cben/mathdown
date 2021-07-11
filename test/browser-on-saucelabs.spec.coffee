# Usage: By default runs local server, tests it via tunnel;
# if SITE_TO_TEST env var is set to a publicly accessible URL, tests that skipping server & tunnel.

util = require('util')
SauceLabs = require('saucelabs').default
wd = require('wd')  # TODO: compare vs http://webdriver.io/ vs webdriverJS
chalk = require('chalk')
expect = require('expect.js')
lodash = require('lodash')
uuid = require('uuid')

require('coffeescript/register')
server = require('../server')
testMetadata = require('./lib/test-metadata')

# 'mathdown' is a sub-account I created.
sauceUser = process.env.SAUCE_USERNAME || 'mathdown'
# I hope storing this in a public test is OK given that an Open Sauce account
# is free anyway.  Can always revoke if needed...
sauceKey = process.env.SAUCE_ACCESS_KEY || '23056294-abe8-4fe9-8140-df9a59c45c7d'

# Try to keep all logging indented deeper than Mocha test tree.
indentation = '          '
log = (fmt, args...) ->
  text = util.format(fmt, args...)
  console.log(text.replace(/^/mg, indentation))

sec = 1000
min = 60*sec

timeouts = {
  tunnel: 60*sec
  tunnelClose: 20*sec
  # Sauce normally gives a VM in seconds but sometimes it's slow
  # and running too many concurrent jobs causes jobs to queue up waiting for a slot.
  sauceSession: 5*min
  sauceSessionClose: 10*sec
  # Waste less Sauce resources than default 90s if this script crashed.
  sauceIdle: 30*sec
}

# Desired environments
# =====================

sauceLabs = new SauceLabs({user: sauceUser, key: sauceKey})

getDesiredBrowsers = ->
  # https://docs.saucelabs.com/dev/api/platform/index.html
  platforms = await sauceLabs.listPlatforms('webdriver')

  oldestBrowser = (api_name) ->
    matchingPlatforms = lodash.filter(platforms, (p) => p.api_name == api_name)
    oldestPlatform = lodash.minBy(matchingPlatforms, (p) => Number(p.short_version))
    # Convert to format expected by 
    {browserName: api_name, version: oldestPlatform.long_version, platform: oldestPlatform.os}

  [
    # Generated with https://docs.saucelabs.com/reference/platforms-configurator/
    # Desktop:
    oldestBrowser('internet explorer')
    {browserName: 'internet explorer', version: 'latest', platform: 'Windows 10'}
    {browserName: 'MicrosoftEdge'}
    # arbitrary somewhat old - but not ancient - FF and Chrome versions.
    {browserName: 'firefox', version: '30.0', platform: 'Linux'}
    {browserName: 'chrome', version: '35.0', platform: 'Linux'}
    {browserName: 'Safari', version: '8.0', platform: 'OS X 10.10'}
    {browserName: 'Safari', version: 'latest', platform: 'macOS 10.13'}
    # Mobile (doesn't mean it's usable though):
    # {browserName: 'Safari', deviceName: 'iPad Simulator', platformName: 'iOS', platformVersion: '9.3'}
    # {browserName: 'Browser', deviceName: 'Android Emulator', platformName: 'Android', platformVersion: '4.4'}
  ]

commonDesired = {
  build: testMetadata.getBuildInfo()
  tags: testMetadata.getTags()
  'idle-timeout': timeouts.sauceIdle
}
log("commonDesired =", commonDesired)

merge = (objs...) ->
  merged = {}
  for obj in objs
    for k, v of obj
      merged[k] = v
  merged

# Tests
# =====

# I've factored parts of the test suite into "desribeFoo" functions.
# When I want to pass them values computed in before[Each] blocks, I have to
# pass "getValue" callables (e.g. `getDesired` here) rather than the values
# themselves (see https://gist.github.com/cben/43fcbbae95019aa73ecd).
describeBrowserTest = (browserName, getDesired, getSite) ->
  describe browserName, ->
    browser = null

    # KLUDGE: to set pass/fail status on Sauce Labs, I want to know whether tests passed.
    # Theoretically should use a custom reporter; practically this works, as
    # long as test cases set eachPassed to true when done.
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
    before (done) ->
      this.timeout(timeouts.sauceSession)
      browser = wd.remote('ondemand.saucelabs.com', 80, sauceUser, sauceKey)
      browser.on 'status', (info) ->
        log(chalk.cyan(info))
      browser.on 'command', (meth, path) ->
        log('> %s: %s', chalk.yellow(meth), path)
      #browser.on 'http', (meth, path, data) ->
      #  log('> %s %s %s', chalk.magenta(meth), path, chalk.grey(data))

      log('')  # blank line before lots of noise
      browser.init getDesired(), (err) ->
        expect(err).to.be(null)
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
    #     expect(err).to.be(null)
    #     log(chalk.yellow('LOG TYPES:'), arrayOfLogTypes)
    #     browser.log 'browser', (err, arrayOfLogs) ->
    #       expect(err).to.be(null)
    #       log(chalk.yellow('LOGS:'), arrayOfLogs)
    #       done()

    after (done) ->
      this.timeout(timeouts.sauceSessionClose)
      browser.sauceJobStatus allPassed, ->
        browser.quit ->
          log('')  # blank line after lots of noise
          done()

    it 'should load and render math', (done) ->
      this.timeout(60*sec)  # 30s would be enough if not for mobile?
      browser.get getSite() + '?doc=_mathdown_test_smoke', (err) ->
        expect(err).to.be(null)
        browser.waitFor wd.asserters.jsCondition('document.title.match(/smoke test/)'), 30*sec, (err, value) ->
          expect(err).to.be(null)
          browser.waitForElementByCss '.MathJax_Display', 30*sec, (err, el) ->
            expect(err).to.be(null)
            el.text (err, text) ->
              expect(err).to.be(null)
              expect(text).to.match(/^\s*(α|𝛼)\s*$/)
              eachPassed = true
              done()

# Defines test cases and executes them with explicit run(), for mocha --delay mode.
# This lets us do async preparations before defining the cases, see main().
runTests = (desiredBrowsers) ->
  describeAllBrowsers = (getDesired, getSite) ->
    for b in desiredBrowsers
      do (b) ->
        name = "#{b.browserName} #{b.deviceName} #{b.version} on #{b.platform}"
        describeBrowserTest(name, (-> merge(b, getDesired())), getSite)

  siteToTest = process.env.SITE_TO_TEST

  if siteToTest  # Testing existing instance
    describe "#{siteToTest}", ->
      describeAllBrowsers(
        (-> merge(commonDesired, {name: 'smoke test of ' + siteToTest})),
        (-> siteToTest))
  else  # Run local server, test it via tunnel
    describe 'Served site via Sauce Connect', ->
      tunnel = null
      actualTunnelId = null
      httpServer = null

      before (done) ->
        this.timeout(timeouts.tunnel)

        # https://docs.saucelabs.com/reference/sauce-connect/#can-i-access-applications-on-localhost-
        # lists ports we can use.  TODO: try other ports if in use.
        port = 8001
        httpServer = server.main port, ->
          log(chalk.magenta('Creating tunnel...'))
          actualTunnelId = uuid.v4()
          tunnel = await sauceLabs.startSauceConnect({
            logger: (stdout) => log(chalk.magenta(stdout.trimEnd())),
            tunnelIdentifier: actualTunnelId,
          })
          done()

      after ->
        this.timeout(timeouts.tunnelClose)
        # TODO (in mocha?): run this on SIGINT
        await tunnel.close()
        log(chalk.magenta('Tunnel stopped, cleaned up.'))
        # Not waiting for server to close - won't happen if the client kept open
        # connections, https://github.com/nodejs/node-v0.x-archive/issues/5052
        httpServer.close()

      describeAllBrowsers(
        (-> merge(commonDesired, {name: 'smoke test', 'tunnel-identifier': actualTunnelId})),
        (-> "http://localhost:#{httpServer.address().port}"))
  
  run()

main = ->
  desiredBrowsers = await getDesiredBrowsers()
  log('desiredBrowsers =', desiredBrowsers)
  runTests(desiredBrowsers)

main()

# TODO: parallelize (at least between different browsers).
# I probably want Vows instead of Jasmine, see https://github.com/jlipps/sauce-node-demo example?
# Or Nightwatch.js?
