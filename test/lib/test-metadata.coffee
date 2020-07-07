execSync = require('sync-exec')

# Continuous integration metadata
# ===============================
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

tags = []
tags.push('shippable') if env.SHIPPABLE
# Shippable tries too hard to be Travis-compatible, sets TRAVIS.
tags.push('travis') if env.TRAVIS && ! env.SHIPPABLE
tags.push('drone') if env.DRONE
tags.push('wercker') if env.WERCKER_BUILD_URL
tags.push(env.CI_NAME) if env.CI_NAME  # Covers Codeship (could also use env.CODESHIP).

exports.getTags = -> tags

buildInfo = null
exports.getBuildInfo = ->
  if not buildInfo?
    buildInfo = if buildUrl
      "#{buildUrl} [#{branch}] commit #{commit}"
    else
      # Synthesize unique build string for local `npm test` runs.
      console.log('Running `git describe` to get build info...')
      versionInfo = execSync('git describe --always --all --long --dirty').stdout.trim()
      timestamp = new Date().toISOString()
      "Local at #{versionInfo} on #{timestamp}"
  buildInfo
