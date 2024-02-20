#!/bin/bash -x

binDirectory="/usr/local/bin"
cd $binDirectory

source /tmp/functions.sh

if [ "${pcoipLicenseKey}" != "" ]; then
  RunProcess "/sbin/pcoip-register-host --registration-code=${pcoipLicenseKey}" $binDirectory/pcoip-agent-license
fi

SetFileSystems '${jsonencode(fileSystems)}'

source /etc/profile.d/aaa.sh
