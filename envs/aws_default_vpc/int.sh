#!/usr/bin/env bash

: "${AWS_ACCESS_KEY_ID:? AWS_ACCESS_KEY_ID must be set }"
: "${AWS_SECRET_ACCESS_KEY:? AWS_SECRET_ACCESS_KEY must be set }"
: "${AWS_DEFAULT_ELASTIC_IP:? AWS_DEFAULT_ELASTIC_IP must be set }"

REPO_ROOT_DIR="$(dirname $(dirname $( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null && pwd )))"

bosh int $REPO_ROOT_DIR/src/my-jumpbox-deployment/jumpbox.yml \
  -o $REPO_ROOT_DIR/src/my-jumpbox-deployment/aws/cpi.yml \
  -v access_key_id=$AWS_ACCESS_KEY_ID \
  -v secret_access_key=$AWS_SECRET_ACCESS_KEY \
  -v region=us-east-2 \
  -v az=us-east-2b \
  -v default_key_name=jumpbox \
  -v subnet_id=subnet-10725878 \
  -v internal_cidr=172.31.0.0/20 \
  -v internal_gw=172.31.0.1 \
  -v internal_ip=172.31.0.10 \
  -v external_ip=$AWS_DEFAULT_ELASTIC_IP \
  -v default_security_groups=default \
  --var-file private_key=~/workspace/aws/MBPro.pem
