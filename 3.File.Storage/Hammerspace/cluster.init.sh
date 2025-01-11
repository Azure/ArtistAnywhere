#!/bin/bash -x

while true; do
  if hscli cluster-view | grep -q "Metadata servers:"; then
    break
  fi
  sleep 1m
done

if [ ${activeDirectory.enable} == true ]; then
  hscli ad-join --ad-servers ${activeDirectory.servers} --realm ${activeDirectory.domainName} --username ${activeDirectory.userName} --password ${activeDirectory.userPassword}
fi
