#!/bin/bash -x

binDirectory="/usr/local/bin"
cd $binDirectory

source /etc/profile.d/aaa.sh

source /tmp/functions.sh

if [ "${pcoipLicenseKey}" != "" ]; then
  RunProcess "/sbin/pcoip-register-host --registration-code=${pcoipLicenseKey}" $binDirectory/pcoip-agent-license
fi

SetFileSystems '${jsonencode(fileSystems)}'

InitializeClient ${databaseUsername} ${databasePassword} null false
