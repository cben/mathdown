#!/bin/bash

# Define git remotes.  You probably want to run `rhc setup`, `heroku login` first.

rhcloud_remote() {
    remote="$1"; shift
    if rhc app show "$@" > /dev/null; then
        git remote remove "$remote"
        git remote add -f "$remote" "$(rhc app show "$@" | sed -n 's/^\s*git url:\s*\(\S*\)/\1/ip')"
    fi
}

rhcloud_remote rhcloud-staging -a staging -n mathdown
rhcloud_remote rhcloud -a prod -n mathdown

heroku git:remote --remote heroku --app mathdown
heroku git:remote --remote heroku-staging --app mathdown-staging
