#!/bin/bash
# TODO: learn to write this kind of theng in Node.js.

firebase=mathdown.firebaseio.com

fails=0
# Can't read list of pads
curl --silent --head -X GET https://$firebase/firepads.json | grep 403 || let fails++
# Can read pad with known name
curl --silent --head -X GET https://$firebase/firepads/help/history.json | grep 200 || let fails++
curl --silent --head -X GET https://$firebase/firepads/help/checkpoint.json | grep 200 || let fails++
curl --silent --head -X GET https://$firebase/firepads/help/users.json | grep 200 || let fails++

echo
if [ $fails != 0 ]; then
  echo "$fails FAILURES"
else
  echo "PASS"
fi
exit $fails
