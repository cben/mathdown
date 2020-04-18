#!/bin/bash

# Deploy certs files per https://devcenter.heroku.com/articles/ssl
# Requires `heroku` CLI, and being logged in.

# (Alternative: paid dynos (including Hobby) can simply enable https://devcenter.heroku.com/articles/automated-certificate-management)

set -e -u -o pipefail
set -x

cd "$(dirname "$0")"

# TODO: command-line parameters like rhc-set-certs.sh ?

# One cert for all 4 domains.
main_domain='mathdown.net'
alt_domains=('www.mathdown.net' 'www.mathdown.com' 'mathdown.com')
domains=("$main_domain" "${alt_domains[@]}")

app=mathdown
cert=certs/mathdown.net/cert.pem
privkey=certs/mathdown.net/privkey.pem
if heroku certs:info --app "$app"; then
   heroku certs:update --app "$app" "$cert" "$privkey"
else
   heroku certs:add --app "$app" "$cert" "$privkey"
fi

sleep 5
curl --head "https://$main_domain/"

echo 'To analyze certs & security:'
printf '  https://www.ssllabs.com/ssltest/analyze.html?d=%s&latest\n' "${domains[@]}"
