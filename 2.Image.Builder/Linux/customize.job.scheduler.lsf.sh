#!/bin/bash -ex

source /tmp/functions.sh

echo "Customize (Start): Job Scheduler"

if [ "$binPaths" != "" ]; then
  echo "Customize (PATH): ${binPaths:1}"
  echo 'PATH=$PATH'$binPaths >> $aaaProfile
fi

echo "Customize (End): Job Scheduler"
