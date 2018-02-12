#!/bin/bash -x

set -e  # exit on first error.

cd "$(dirname "$0")"/..  # project root

#npm test  # is this needed?  it probably got tested on Travis, and staging test will catch problems.

# TODO: make it easy to use this after forking (different apps, git remotes, "origin")
# TODO: create git remotes as needed
# TODO: log to files (and upload somewhere? gist?)
# TODO: parallelize

# if local gh-pages != origin/gh-pages, only deploy what's on github.
git fetch
time git push heroku-staging origin/gh-pages:master
env SITE_TO_TEST=https://mathdown-staging.herokuapp.com npm test
time git push heroku origin/gh-pages:master
date -Isec --utc
