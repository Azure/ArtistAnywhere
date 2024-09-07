#!/bin/bash -x

source /tmp/functions.sh

SetFileSystem '${jsonencode(fileSystem)}'

# rsync $binDirectory/island /mnt/storage/
