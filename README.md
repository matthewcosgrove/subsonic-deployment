## Purpose

A quick way to fire up an instance of Subsonic on AWS backed by Dropbox for easy syncing.

## Prerequisites

You should know how to set up env vars, and ensure all the env vars mentioned in capitals below have been exported. See the main list at the top of [create-env.sh](envs/aws_default_vpc/create-env.sh)

### Subsonic Domain

* You should have a domain (env var will be SUBSONIC_DOMAIN) and know how to configure the DNS A record. You can configure it with your preferred DNS entry pointing to the elastic IP which will get output during the scripted set up below.

### Dropbox

* Dropbox account with your music collection available in a top level folder (for the sync we will be excluding all other Dropbox folders) and the default subsonic directory as a subfolder of that. Subsonic uses /var/music as a default, so an example might be SUBSONIC_SOLO_DROPBOX_FOLDER=var with SUBSONIC_MUSIC_SUBFOLDER=music. This would mean you need to have `~/Dropbox/var/music` as the location of synced folders within Dropbox with your mp3s already uploaded there.
* If you have other subfolders with music, they will be synced to the VM we will provision further below, but you will need to add them to Subsonic from the GUI in the usual way manually. e.g. Using the settings above, if you have a ~/Dropbox/var/elevator folder with all your favourite elevator tunes then that folder would be synced to the VM by dropbox but not added to Subsonic out of the box.

### Infrastructure Tooling

* Ability to run bash scripts on your workstation.
* Tools installed ([bosh-cli v2](https://bosh.io/docs/cli-v2-install/), [terraform](https://learn.hashicorp.com/terraform/getting-started/install.html))
* Standard env vars for AWS (AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY, AWS_DEFAULT_REGION)
* AWS key pair created, downloaded to a directory registered as env AWS_PRIVATE_KEY_LOCATION with the key pair name declared as AWS_KEYPAIR_NAME

State files created from `terraform` and `bosh` are kept in a state directory which is listed in `.gitignore` as they contain sensitive info as well as state that you should store safely. You are on your own with that aspect.

## Create the Subsonic VM

Scripts are provided. By default, at the time of writing (you should check the config files in this repo for the source of truth on this), the create-env.sh script will set up among other more minor things

* An Ubuntu VM t2.micro
* A persistent disk with 10GB
* An Elastic IP

Note that the default VPC for your account on your chosen region will be used (the main assumption of the scripts is that the first subnet of your default VPC has a free IP at .10 fourth octet) and the only changes made in AWS with terraform will be a new Elastic IP and modifications to the default security group to ensure access over ports 22 and 6868 (the latter is for connectivity to the bosh agent, specifically mbus).

If you are on the free trial of AWS, they should be covered, but if not you should anticipate some costs.

To provision a VM, we rely on the [jumpbox-deployment](https://github.com/cloudfoundry/jumpbox-deployment) project as a sub-module, which you should prepare as instructed below

### Bootstrapping

cd into the root directory of this project and run

```plain
git submodule update --init
envs/aws_default_vpc/create-env.sh
```

The VM should now be available, with Subsonic running. We will now need to ssh onto the VM to set up dropbox with the login process etc

Login should happen automatically by running

```plain
envs/aws_default_vpc/jumpbox-ssh.sh
```

You should now be in the ~ dir of the jumpbox which is actually /var/vcap/store/home/jumpbox. NOTE: Run `ssh-keygen -R <elastic-ip>` after any VM destroys to clean up the known_hosts file.

Next we will need to get dropbox set up and authenticate. Follow the output carefully from the following script in the jumpbox home directory

IMPORTANT: The dropbox-cli is a bit naff and there is no simple way to avoid Dropbox trying to sync everything on start up. Double check the exclusions are set up as expected to avoid any nonsense.

```plain
./ubuntu_dropbox_up.sh
```

Again, read the output carefully, to ensure all the exclusions are in place.

### Teardown

to teardown the environment

```plain
DANGER-ZONE
envs/aws_default_vpc/destroy-env.sh
```
