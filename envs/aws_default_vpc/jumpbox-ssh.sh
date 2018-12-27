#!/bin/bash

set -eu


SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null && pwd )"
source $SCRIPT_DIR/state/elastic-ip
: "${AWS_ELASTIC_IP:? AWS_ELASTIC_IP must be set }"
KEYHOLDER_DIR=$SCRIPT_DIR/ssh
mkdir -p $KEYHOLDER_DIR
chmod 700 $KEYHOLDER_DIR

bosh int $SCRIPT_DIR/state/creds.yml --path /jumpbox_ssh/private_key > $KEYHOLDER_DIR/jumpbox.pem
chmod 600 $KEYHOLDER_DIR/jumpbox.pem

#jumpbox_ip=$(terraform output --state=envs/aws/terraform.tfstate box.jumpbox.public_ip)
jumpbox_ip=$AWS_ELASTIC_IP

ssh -A jumpbox@${jumpbox_ip} \
  -i $KEYHOLDER_DIR/jumpbox.pem \
  "$@"
