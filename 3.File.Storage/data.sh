#!/bin/bash -ex

az login --identity

source /tmp/functions.sh

SetFileSystem '${jsonencode(fileSystem)}' true

az storage copy --source-account-name ${dataLoadSource.accountName} --source-container ${dataLoadSource.containerName} --destination "/mnt" --recursive
