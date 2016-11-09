#!/bin/bash
set -e

# functions
log() {
  echo "* [${2:-INFO}] $1"
}

die() {
  >&2 log "$1" "ERROR"
  exit 1
}

# test env vars
env_vars="
AWS_ACCESS_KEY_ID
AWS_SECRET_ACCESS_KEY
AWS_REGION
"

count=0
for var in $env_vars; do
  if [ -z "${!var:-}" ]; then
    log "Environment variable $var is unset"
    ((count++))
  fi
done

# exit if all not set
if [ "$count" -ne 0 ]; then
  die "One or more environment variables are unset"
fi

rm -rf berks-cookbooks
berks vendor berks-cookbooks -b ../../../Berksfile
packer build resize_and_was_media_ami.json
