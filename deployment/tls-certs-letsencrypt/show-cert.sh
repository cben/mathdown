#!/bin/bash

if [ $# != 1 ]; then
    echo "Usage: $0 FULL_CHAIN_FILE.pem"
    set "$(dirname "$0")"/certs/mathdown.net/fullchain.pem
    echo "Defaulting to prod cert: $1"
    echo
fi

namei -l "$1"
echo

# Summarize all certs in chain: http://serverfault.com/a/755815
openssl crl2pkcs7 -nocrl -certfile "$1" |
  openssl pkcs7 -print_certs -noout -text |
  egrep --color 'Certificate:|Issuer|Validity|Before|After|Subject|DNS'
