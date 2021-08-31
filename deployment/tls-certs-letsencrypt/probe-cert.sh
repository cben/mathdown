#!/bin/bash
# Show live certificate chain served for a domain.

if [ $# != 1 ]; then
    echo "Usage: $0 DOMAIN"
    set www.mathdown.net
    echo "Defaulting to $1"
    echo
fi

# -showcerts dumps summarized chain info to stderr too.  Does SOME but not full validation.
openssl s_client -showcerts -servername "$1" -connect "$1:443" < /dev/null |
# Summarize all certs in chain: http://serverfault.com/a/755815
  openssl crl2pkcs7 -nocrl -certfile /dev/stdin |
  openssl pkcs7 -print_certs -noout -text |
  grep --extended-regexp --color 'Certificate:|Issuer|Validity|Before|After|Subject|DNS'
