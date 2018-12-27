#!/usr/bin/env bash

set -eu
: "${AWS_ACCESS_KEY_ID:? AWS_ACCESS_KEY_ID must be set }"
: "${AWS_SECRET_ACCESS_KEY:? AWS_SECRET_ACCESS_KEY must be set }"
: "${AWS_DEFAULT_REGION:? AWS_DEFAULT_REGION must be set }"
: "${AWS_PRIVATE_KEY_LOCATION:? AWS_PRIVATE_KEY_LOCATION must be set }"
: "${AWS_KEYPAIR_NAME:? AWS_KEYPAIR_NAME must be set }"

REPO_ROOT_DIR="$(dirname $(dirname $( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null && pwd )))"
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null && pwd )"
SCRIPT_DIR_STATE=$SCRIPT_DIR/state
mkdir -p $SCRIPT_DIR_STATE

pushd $SCRIPT_DIR/terraform > /dev/null
terraform init
terraform apply -input=false -auto-approve

elastic_ip=$(terraform output elastic_ip)
az=$(terraform output default_subnet_az)
default_security_group=$(terraform output default_security_group)
subnet_id=$(terraform output default_subnet_id)
subnet_cidr=$(terraform output default_subnet_cidr)
subnet_gw=$(awk -F"." '{print $1"."$2"."$3".1"}'<<<$subnet_cidr)
subnet_new_ip=$(awk -F"." '{print $1"."$2"."$3".10"}'<<<$subnet_cidr)
bosh create-env $REPO_ROOT_DIR/src/jumpbox-deployment/jumpbox.yml \
  --state $SCRIPT_DIR_STATE/state.json \
  -o $REPO_ROOT_DIR/src/jumpbox-deployment/aws/cpi.yml \
  -o $REPO_ROOT_DIR/operators/pre-start-script.yml \
  -o $REPO_ROOT_DIR/operators/persistent-homes.yml \
  -o $REPO_ROOT_DIR/operators/override-aws-cpi-disk-for-data.yml \
  --vars-store $SCRIPT_DIR_STATE/creds.yml \
  -v access_key_id=$AWS_ACCESS_KEY_ID \
  -v secret_access_key=$AWS_SECRET_ACCESS_KEY \
  -v region=$AWS_DEFAULT_REGION \
  -v az=$az \
  -v default_key_name=$AWS_KEYPAIR_NAME \
  -v subnet_id=$subnet_id \
  -v internal_cidr=$subnet_cidr \
  -v internal_gw=$subnet_gw \
  -v internal_ip=$subnet_new_ip \
  -v external_ip=$elastic_ip \
  -v default_security_groups=[$default_security_group] \
  --var-file private_key=$AWS_PRIVATE_KEY_LOCATION
echo "AWS_ELASTIC_IP=$elastic_ip" > $SCRIPT_DIR/state/elastic-ip
popd > /dev/null
