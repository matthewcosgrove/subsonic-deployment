#!/bin/bash

set -eu

TMPDIR=""¬
TMPDIR=$(mktemp -d -t jumpbox_ssh.XXXXXX)
trap "rm -rf ${TMPDIR}" INT TERM QUIT EXIT

set +u
[ ! -z "$1" ] && STATE_DIR=state-$1
set -u
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null && pwd )"
SCRIPT_DIR_STATE="$SCRIPT_DIR/${STATE_DIR:=state}"
echo "Using state stored in $SCRIPT_DIR_STATE"
export TERRAFORM_STATE="$SCRIPT_DIR_STATE/terraform.tfstate"
source $SCRIPT_DIR/output-terraform
ssh-keygen -R ${elastic_ip} # cover cases where VM needed rebuilding since last login
bosh int $SCRIPT_DIR_STATE/creds.yml --path /jumpbox_ssh/private_key > $TMPDIR/jumpbox.pem && chmod 600 $TMPDIR/jumpbox.pem
ssh -A jumpbox@${elastic_ip} \
  -i $TMPDIR/jumpbox.pem
