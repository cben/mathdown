wd = require('wd')
chalk = require('chalk')

browser = wd.remote(
  'ondemand.saucelabs.com', 80,
  # I hope storing this in a public test is OK given that an Open Sauce account
  # is free anyway.  Can always revoke if needed...
  'mathdown', '23056294-abe8-4fe9-8140-df9a59c45c7d'
)

browser.on 'status', (info) ->
  console.log(chalk.cyan(info))

browser.on 'command', (meth, path) ->
  console.log(' > %s: %s', chalk.yellow(meth), path)

browser.on 'http', (meth, path, data) ->
  console.log(' > %s %s %s', chalk.magenta(meth), path, chalk.grey(data))

desired = {
  browserName: 'internet explorer'
  version: '8'
  platform: 'Windows XP'
  name: 'smoke test'
}

browser.init desired, ->
  # TODO: use current source (via Sauce Connect?)
  browser.get 'http://mathdown.net/?doc=_mathdown_test_smoke', (err) ->
    browser.waitFor wd.asserters.jsCondition('document.title.match(/smoke test/)', 2000), (err, value) ->
      # TODO: err should not be ignored.  Use promises for sanity?
      browser.waitForElementByCss '.MathJax_Display', 15000, (err, el) ->
        el.text (err, text) ->
          if not text.match(/^\s*α\s*$/)
            console.error('math', text, 'isn\'t alpha.')
          console.log(chalk.green('ALL PASSED'))
          browser.quit()
