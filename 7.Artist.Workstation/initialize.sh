#!/bin/bash -ex

source /tmp/functions.sh

if [ "${remoteAgentKey}" != "" ]; then
  RunProcess "/sbin/pcoip-register-host --registration-code=${remoteAgentKey}" $binDirectory/pcoip-agent-license
fi

SetFileSystem '${jsonencode(fileSystem)}' false

source /etc/profile.d/aaa.sh
