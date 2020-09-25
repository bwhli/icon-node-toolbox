#!/bin/bash

REGION_ID=$(cat /home/haproxy/.gcp_vars/REGION_ID)

# Set HAProxy config file directory.
HAPROXY_CONFIG_DIR="/Users/brianli/Desktop"

# Make request to GCP API to get instance names and internal IPs for VMs tagged with ctz-node in specified region ($REGION_ID).
GCP_API_REQUEST=$(gcloud compute instances list --filter="zone ~ $REGION_ID AND tags.items=ctz-node" --format="json(name,networkInterfaces.[].networkIP)")

# Get length of JSON array.
GCP_API_REQUEST_ARRAY_LENGTH=$(echo $GCP_API_REQUEST | jq 'length')

# Initialize array to hold GCP internal IPs.
GCP_INTERNAL_IP_ARRAY=()
# Loop through API request JSON and add internal IPs to array.
for i in $( seq 0 $(($GCP_API_REQUEST_ARRAY_LENGTH - 1)) ); do
  GCP_INSTANCE_INTERNAL_IP=$(echo $GCP_API_REQUEST | jq --arg index "$i" '.[$index|tonumber].networkInterfaces[].networkIP' | sed -e 's/^"//' -e 's/"$//')
  GCP_INTERNAL_IP_ARRAY+=( $GCP_INSTANCE_INTERNAL_IP )
done

# Print GCP internal IP array to string, sort, and replace newlines with spaces.
GCP_INTERNAL_IPS=$(printf '%s\n' "${GCP_INTERNAL_IP_ARRAY[@]}" | sort -n | tr '\n' ' ')

# Get current HAProxy IPs from config file, sort, and replace newlines with spaces.
CURRENT_HAPROXY_IPS=$(cat ~/Desktop/haproxy.cfg | egrep -o '10\.[[:digit:]]{1,3}\.[[:digit:]]{1,3}\.[[:digit:]]{1,3}' | sort -n | tr '\n' ' ')

# Compare current HAProxy IPs with GCP internal IPs.
if [[ $CURRENT_HAPROXY_IPS != $GCP_INTERNAL_IPS ]]; then
  echo "IPs are not the same."
  cp $HAPROXY_CONFIG_DIR/haproxy-default.cfg $HAPROXY_CONFIG_DIR/haproxy-new.cfg
  for i in $( seq 0 $(($GCP_API_REQUEST_ARRAY_LENGTH - 1)) ); do
    GCP_INSTANCE_NAME=$(echo $GCP_API_REQUEST | jq --arg index "$i" '.[$index|tonumber].name' | sed -e 's/^"//' -e 's/"$//')
    echo $GCP_INSTANCE_NAME
    GCP_INSTANCE_INTERNAL_IP=$(echo $GCP_API_REQUEST | jq --arg index "$i" '.[$index|tonumber].networkInterfaces[].networkIP' | sed -e 's/^"//' -e 's/"$//')
    echo $GCP_INSTANCE_INTERNAL_IP
    # Run health check on node and get response code of HTTP request. Timeout is set to 2 seconds.
    HEALTH_CHECK_REQUEST=$(curl -i --connect-timeout 2 -s -o /dev/null -w "%{http_code}" http://$GCP_INSTANCE_INTERNAL_IP:9000/api/v1/avail/peer)
    # If the response code returns 200, add it to the HAProxy config.
    if [[ $HEALTH_CHECK_REQUEST == "200"]]; then
      echo "  server $GCP_INSTANCE_NAME $GCP_INSTANCE_INTERNAL_IP:9000 check maxconn 500" >> $HAPROXY_CONFIG_DIR/haproxy-new.cfg
    fi
  done
  mv $HAPROXY_CONFIG_DIR/haproxy.cfg $HAPROXY_CONFIG_DIR/haproxy.cfg.bkp
  mv $HAPROXY_CONFIG_DIR/haproxy-new.cfg $HAPROXY_CONFIG_DIR/haproxy.cfg
  service haproxy reload
fi
