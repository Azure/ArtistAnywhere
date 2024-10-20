#!/bin/bash -x

while true; do
  if hscli cluster-view | grep -q "Metadata servers:"; then
    break
  fi
  sleep 1m
done
