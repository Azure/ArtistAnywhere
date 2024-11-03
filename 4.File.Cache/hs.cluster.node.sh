#!/bin/bash -ex

activeDirectory='${jsonencode(activeDirectory)}'
enable=$(echo $activeDirectory | jq -r .enable)
if [ $enable == true ]; then
  realm="$(echo $activeDirectory | jq -r .realm)"
  orgUnit="$(echo $activeDirectory | jq -r .orgUnit)"
  username="$(echo $activeDirectory | jq -r .username)"
  password="$(echo $activeDirectory | jq -r .password)"
  if [ "$orgUnit" != "" ]; then
    hscli ad-join --realm "$realm" --username "$username" --password "$password" --computer-ou "$orgUnit"
  else
    hscli ad-join --realm "$realm" --username "$username" --password "$password"
  fi
fi
