#!/bin/bash
API_RESPONSE_CODE=$(curl --write-out %{http_code} --silent --output /dev/null http://127.0.0.1:9000/api/v1/avail/peer)
until [[ $API_RESPONSE_CODE == "200" ]]
do
  echo "$API_RESPONSE is not 200."
  echo "Sleeping for 15 seconds, before checking again..."
  sleep 15
done
echo "$API_RESPONSE_CODE is 200..."
echo "Restarting HAProxy..."
service haproxy restart
