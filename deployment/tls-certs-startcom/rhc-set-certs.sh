#!/bin/bash
if [ $# -lt 2 -o $# -gt 3 ]; then
    echo "Usage: $0 APP KEYFILE [PASSPHRASE]"
    echo "Examples:"
    echo "  $0 mathdown ~/StartSSL/my-private-decrypted.key"
    echo "kludge: disambiguate multiple openshift \"domains\":"
    echo "  $0 'mathdown -n cben' ~/StartSSL/my-private-decrypted.key"
    echo "use encrypted keyfile (unsecure on multi-user systems):"
    echo "  read -s -p 'Passphrase: ' passphrase"
    echo "  $0 mathdown ~/StartSSL/my-private-encrypted.key \"\$passphrase\""
    echo
    echo "I believe this script is idempotent (up to \"Certificate Added\" date)."
    echo "Not sure if it's zero downtime but it's pretty fast."
    exit 2
fi
set -x

cd "$(dirname "$0")"

appopts=($1)  # this splits $1 into words
if [ -z "$3" ]; then
  keyopts=(--private-key="$2")
else
  keyopts=(--private-key="$2" --passphrase="$3")
fi

cat mathdown.com-until-2016-02-12.pem StartCom-chain-sub.class1.server.ca.pem > GENERATED-CHAINED-mathdown.com.pem
cat mathdown.net-until-2016-02-15.pem StartCom-chain-sub.class1.server.ca.pem > GENERATED-CHAINED-mathdown.net.pem

# <rant>In fish $X does the right thing, in bash I need "${X[@]}" and it only comes close.</rant>

echo '== before: =='
rhc alias list "${appopts[@]}"

rhc alias add "${appopts[@]}" mathdown.net
rhc alias add "${appopts[@]}" www.mathdown.net
rhc alias add "${appopts[@]}" mathdown.com
rhc alias add "${appopts[@]}" www.mathdown.com

rhc alias update-cert "${appopts[@]}" mathdown.net --certificate GENERATED-CHAINED-mathdown.net.pem "${keyopts[@]}"
rhc alias update-cert "${appopts[@]}" www.mathdown.net --certificate GENERATED-CHAINED-mathdown.net.pem "${keyopts[@]}"
rhc alias update-cert "${appopts[@]}" mathdown.com --certificate GENERATED-CHAINED-mathdown.com.pem "${keyopts[@]}"
rhc alias update-cert "${appopts[@]}" www.mathdown.com --certificate GENERATED-CHAINED-mathdown.com.pem "${keyopts[@]}"

echo '== after: =='
rhc alias list "${appopts[@]}"

