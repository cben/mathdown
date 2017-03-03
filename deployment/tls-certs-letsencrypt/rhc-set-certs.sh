#!/bin/bash
set -e -u -o pipefail  # also set -x below

# One cert for all 4 domains.
main_domain='mathdown.net'
alt_domains=('www.mathdown.net' 'www.mathdown.com' 'mathdown.com')
domains=("$main_domain" "${alt_domains[@]}")

if [ $# -lt 2 -o $# -gt 3 ]; then
    echo "Usage: $0 APP NAMESPACE KEYFILE [PASSPHRASE]"
    echo "  (\"NAMESPACE\" is what openshift also calls \"domain\")"
    echo "Examples:"
    echo "  $0 prod mathdown certs/$main_domain/privkey.pem"
    echo "use encrypted keyfile (unsecure on multi-user systems):"
    echo "  read -s -p 'Passphrase: ' passphrase"
    echo "  $0 prod mathdown path/to/encrypted-privkey.pem \"\$passphrase\""
    echo
    echo "I believe this script is idempotent (up to \"Certificate Added\" date)."
    echo "Not sure if it's zero downtime but it's pretty fast."
    exit 2
fi
set -x

cd "$(dirname "$0")"

appopts=(--app="$1" --namespace="$2")
if [ -z "${4:-}" ]; then
  keyopts=(--certificate="certs/$main_domain"/fullchain.pem --private-key="$3")
else
  keyopts=(--certificate="certs/$main_domain"/fullchain.pem --private-key="$3" --passphrase="$4")
fi

# <rant>In fish $X does the right thing, in bash I need "${X[@]}" and it only comes close.</rant>

echo '== before: =='
rhc alias list "${appopts[@]}"

for domain in "${domains[@]}"; do
    rhc alias add "${appopts[@]}" "$domain" || true
done

for domain in "${domains[@]}"; do
    rhc alias update-cert "${appopts[@]}" "$domain" "${keyopts[@]}"
done

echo '== after: =='
rhc alias list "${appopts[@]}"

curl --head "https://$main_domain/"

echo 'To analyze certs & security:'
printf '  https://www.ssllabs.com/ssltest/analyze.html?d=%s&latest\n' "${domains[@]}"
