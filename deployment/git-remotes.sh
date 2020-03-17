#!/bin/bash

# Define git remotes.  You probably want to run `heroku login` first.

git remote get-url heroku || heroku git:remote --remote heroku --app mathdown
git remote get-url heroku-staging || heroku git:remote --remote heroku-staging --app mathdown-staging
