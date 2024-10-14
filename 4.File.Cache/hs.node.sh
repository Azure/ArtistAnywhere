#!/bin/bash -ex

ADMIN_PASSWORD=${adminPassword} /usr/bin/hs-init-admin-pw

activeDirectory='${jsonencode(activeDirectory)}'
enable=$(echo $activeDirectory | jq -r .enable)
if [ $enable == true ]; then
  servers="$(echo $activeDirectory | jq -r .servers)"
  orgUnit="$(echo $activeDirectory | jq -r .orgUnit)"
  username="$(echo $activeDirectory | jq -r .username)"
  password="$(echo $activeDirectory | jq -r .password)"
  hscli ad-join --ad-servers "$servers" --computer-ou "$orgUnit" --username "$username" --password "$password"
fi
