sauceTunnel = require('sauce-tunnel')
st = require('st')
http = require('http')
wd = require('wd')
assert = require('assert')
chalk = require('chalk')

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

# http://docs.travis-ci.com/user/ci-environment/#Environment-variables
# http://docs.drone.io/env.html  (Jenkins compatible)
# https://www.codeship.io/documentation/continuous-integration/set-environment-variables/
env = process.env
build = env.BUILD_ID || env.TRAVIS_BUILD_ID || env.CI_BUILD_NUMBER || env.JOB_ID
buildUrl = env.BUILD_URL || env.CI_BUILD_URL || build
commit = env.GIT_COMMIT || env.TRAVIS_COMMIT || env.CI_COMMIT_ID || env.COMMIT
tunnelId = build
tags = []
tags.push('travis') if env.TRAVIS
tags.push('drone') if env.DRONE
tags.push(env.CI_NAME) if env.CI_NAME

browser = wd.remote('ondemand.saucelabs.com', 80, sauceUser, sauceKey)

browser.on 'status', (info) ->
  console.log(chalk.cyan(info))
browser.on 'command', (meth, path) ->
  console.log(' > %s: %s', chalk.yellow(meth), path)
#browser.on 'http', (meth, path, data) ->
#  console.log(' > %s %s %s', chalk.magenta(meth), path, chalk.grey(data))

desired = {
  browserName: 'internet explorer'
  version: '8'
  platform: 'Windows XP'
  name: 'smoke test'
  build: "#{buildUrl} commit #{commit}"
  tags: tags
  # Most my tests timeout a lot due crashing without cleanup (see below);
  # this will waste less Sauce resources than default 90s.
  'idle-timeout': 30
}

# TODO: Cleanup even if there were errors.  Use promises for sanity?
#  Use a test runner with guaranteed pre/post methods?

test = (cb) ->
  # TODO: use current source (via Sauce Connect?)
  browser.get 'http://localhost:8000/?doc=_mathdown_test_smoke', (err) ->
    assert.ifError(err)
    browser.waitFor wd.asserters.jsCondition('document.title.match(/smoke test/)'), 10000, (err, value) ->
      assert.ifError(err)
      browser.waitForElementByCss '.MathJax_Display', 15000, (err, el) ->
        assert.ifError(err)
        el.text (err, text) ->
          assert.ifError(err)
          if not text.match(/^\s*α\s*$/)
            assert.fail(text, '/^\s*α\s*$/', 'math text is wrong', ' match ')
          console.log(chalk.green('ALL PASSED'))
          cb()

server = http.createServer(st({
  path: process.cwd()
  index: 'index.html'
}))
server.on 'request', (req, res) ->
  console.log(' < %s %s', chalk.green(req.method), req.url)
server.listen(8000)
console.log('Server up, e.g. http://localhost:8000/?doc=_mathdown_test_smoke')

tunnel = new sauceTunnel(sauceUser, sauceKey, tunnelId, true, ['--verbose'])
console.log('Creating tunnel...')
tunnel.start (status) ->
  assert(status, 'tunnel creation failed')
  console.log('tunnel created')
  desired['tunnel-identifier'] = tunnel.identifier
  console.log(desired)
  browser.init desired, (err) ->
    assert.ifError(err)
    test ->
      browser.quit()
      server.close()
      tunnel.stop ->
        console.log(chalk.green('Cleaned up.'))
