#!/bin/bash -x

ADMIN_PASSWORD=${adminPassword} /usr/bin/hs-init-admin-pw

hscli login --username admin --password ${adminPassword}
