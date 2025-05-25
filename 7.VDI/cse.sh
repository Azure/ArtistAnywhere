#!/bin/bash -ex

source /tmp/functions.sh

if [ "${remoteAgentKey}" != "" ]; then
  run_process "/sbin/pcoip-register-host --registration-code=${remoteAgentKey}" pcoip-agent-license
fi

set_file_system '${jsonencode(fileSystem)}'

source /etc/profile.d/aaa.sh
