#!/usr/bin/env bash

set -eu
: "${AWS_ACCESS_KEY_ID:? AWS_ACCESS_KEY_ID must be set }"
: "${AWS_SECRET_ACCESS_KEY:? AWS_SECRET_ACCESS_KEY must be set }"
: "${AWS_DEFAULT_REGION:? AWS_DEFAULT_REGION must be set }"
: "${AWS_PRIVATE_KEY_LOCATION:? AWS_PRIVATE_KEY_LOCATION must be set }"
: "${AWS_KEYPAIR_NAME:? AWS_KEYPAIR_NAME must be set }"
: "${SUBSONIC_SOLO_DROPBOX_FOLDER:? SUBSONIC_SOLO_DROPBOX_FOLDER must be set and defines the main top folder relative to ~/Dropbox which the headless dropbox cli exclusions algorithm will ignore i.e it will be left as the solo folder to be synced with dropbox on the ubuntu VM e.g. SubsonicLibrary }"
: "${SUBSONIC_MUSIC_SUBFOLDER:? SUBSONIC_MUSIC_SUBFOLDER must be set and is the folder under ~/Dropbox/SUBSONIC_SOLO_DROPBOX_FOLDER which contains the music files which will appear by default in subsonic e.g. MyMusic i.e. in your path this would end up as ~/Dropbox/SubsonicLibrary/MyMusic }"
: "${SUBSONIC_DOMAIN:? SUBSONIC_DOMAIN must be set to the DNS being used to refer to this instance which should be configured in nginx e.g. music.mydomain.com }"

set +u
[ ! -z "$1" ] && STATE_DIR=state-$1
set -u
REPO_ROOT_DIR="$(dirname $(dirname $( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null && pwd )))"
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null && pwd )"
SCRIPT_DIR_STATE="$SCRIPT_DIR/${STATE_DIR:=state}"

export TERRAFORM_STATE="$SCRIPT_DIR_STATE/terraform.tfstate"
pushd $SCRIPT_DIR/terraform > /dev/null
source $SCRIPT_DIR/output-terraform
SCRIPT_DIR_STATE_DERIVED_CONFIG="$SCRIPT_DIR_STATE/derived-config"
source $SCRIPT_DIR_STATE_DERIVED_CONFIG
subnet_gw=$AWS_SUBNET_GW
subnet_new_ip=$AWS_SUBNET_VM_INTERNAL_IP
bosh delete-env $REPO_ROOT_DIR/src/jumpbox-deployment/jumpbox.yml \
  --state $SCRIPT_DIR_STATE/state.json \
  -o $REPO_ROOT_DIR/src/jumpbox-deployment/aws/cpi.yml \
  -o $REPO_ROOT_DIR/operators/pre-start-script.yml \
  -o $REPO_ROOT_DIR/operators/persistent-homes.yml \
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
  -v subsonic_solo_dropbox_folder=$SUBSONIC_SOLO_DROPBOX_FOLDER \
  -v subsonic_music_subfolder=$SUBSONIC_MUSIC_SUBFOLDER \
  -v subsonic_domain=$SUBSONIC_DOMAIN \
  --var-file private_key=$AWS_PRIVATE_KEY_LOCATION
terraform destroy -input=false -auto-approve -state=$TERRAFORM_STATE
rm $SCRIPT_DIR_STATE_DERIVED_CONFIG
rm $SCRIPT_DIR_STATE/creds.yml
popd > /dev/null
