#!/bin/bash -x

source /tmp/functions.sh

SetFileSystem '${jsonencode(fileSystem)}' true

# rsync $binDirectory/island /mnt/storage/
