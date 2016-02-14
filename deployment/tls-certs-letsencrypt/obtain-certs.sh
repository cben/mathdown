#!/bin/bash
# Based on http://blog.thesparktree.com/post/138999997429/generating-intranet-and-private-network-ssl

# Passing HTTP challenge is a bit tricky under PaaS (problem and solution explained well in
# https://blog.semicolonsoftware.de/securing-dokku-with-lets-encrypt-tls-certificates/);
# DNS challenge is nicer, doesn't interfere with the app itself in any way.
# It's especially convenient for obtaining a multi-domain cert, and installing it
# on both RHCloud and Heroku.

set -e -u -o pipefail
set -x

# Create one combined cert for all domains - best for Heroku.
MAIN_DOMAIN='www.mathdown.net'
ALT_DOMAINS='mathdown.net www.mathdown.com mathdown.com'

export PROVIDER=dnsimple
export LEXICON_DNSIMPLE_USERNAME=beni.cherniavsky@gmail.com
# Note: dnsimple supports sub-accounts.  I've created a 'mathdown' sub-account
# but so far kept the domains under beni.cherniavsky, don't remember why.
if [[ -z "$LEXICON_DNSIMPLE_TOKEN" ]]; then
    echo Error: LEXICON_DNSIMPLE_TOKEN env var must be set
    exit 1
fi
# TODO: will token work if I enable DNSimple 2FA?

cd "$(dirname "$0")"

#virtualenv -p python2 ./venv/
#export PATH="$PWD/venv/bin/:$PATH"

#pip install dns-lexicon
#pip install 'requests[security]'
#(cd lexicon; python setup.py install)
#exit

# letsencrypt.sh puts outputs inside its directory, but I prefer it unhere so I
# can commit them (except for privkey*) into my git.
ln -sfn ../../$MAIN_DOMAIN/ letsencrypt.sh/certs/$MAIN_DOMAIN

#chmod +x ./lexicon-hook.sh
#cp ./lexicon/examples/letsencrypt.default.sh ./lexicon-hook.sh
./letsencrypt.sh/letsencrypt.sh --cron --challenge dns-01 --hook ./lexicon-hook.sh --domain "$MAIN_DOMAIN $ALT_DOMAINS"
