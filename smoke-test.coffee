require('coffee-script/register')
server = require('./server')
sauceTunnel = require('sauce-tunnel')
http = require('http')
wd = require('wd')
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
  name: 'smoke test'
  build: "#{buildUrl} [#{branch}] commit #{commit}"
  tags: tags
  # Most my tests timeout a lot due crashing without cleanup (see below);
  # this will waste less Sauce resources than default 90s.
  'idle-timeout': 30
}

browser = wd.remote('ondemand.saucelabs.com', 80, sauceUser, sauceKey)

browser.on 'status', (info) ->
  console.log(chalk.cyan(info))
browser.on 'command', (meth, path) ->
  console.log(' > %s: %s', chalk.yellow(meth), path)
#browser.on 'http', (meth, path, data) ->
#  console.log(' > %s %s %s', chalk.magenta(meth), path, chalk.grey(data))

# TODO: Cleanup even if there were errors.  Use promises for sanity?
#  Use a test runner with guaranteed pre/post methods?

test = (url, cb) ->
  # Kludge: set to failed first, change to passed if we get to the end without crashing.
  browser.sauceJobStatus false, ->
    browser.get url + '?doc=_mathdown_test_smoke', (err) ->
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
            cb()

# https://docs.saucelabs.com/reference/sauce-connect/#can-i-access-applications-on-localhost-
# lists ports we can use.
port = 8001
httpServer = server.main(port)

tunnel = new sauceTunnel(sauceUser, sauceKey, tunnelId, true, ['--verbose'])
console.log('Creating tunnel...')
tunnel.start (status) ->
  assert(status, 'tunnel creation failed')
  console.log('tunnel created')
  desired['tunnel-identifier'] = tunnel.identifier
  console.log(desired)
  browser.init desired, (err) ->
    assert.ifError(err)
    test 'http://localhost:' + port, ->
      browser.quit()
      tunnel.stop ->
        console.log(chalk.green('Tunnel stopped, cleaned up.'))
      httpServer.close()

# TODO: inspect browser console log
# https://support.saucelabs.com/entries/60070884-Enable-grabbing-server-logs-from-the-wire-protocol
