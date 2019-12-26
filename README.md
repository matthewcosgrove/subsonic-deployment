## Purpose

A quick way to fire up an instance of Subsonic on AWS backed by Dropbox for easy syncing.

WARNING: You should be familiar with AWS before running this set up, especially the pricing model. It is recommended to set up notifications on your billing account to trigger alerts when your bill runs above a certain threshold. Whilst this set up was tested and run on the AWS Free Tier without cost, a normal account would incur costs. Changing settings within this project will also affect the associated cost. A large music collection, for example, would require you to increase the default persistent disk size and therefore also increase the costs.

IMPORTANT: It is recommended to use the destroy-env.sh script to teardown the environment. To use it requires retaining the state after running the creation script (explained further below). By taking this clean approach via the scripted set up and teardown, you won't leave unassociated Elastic IPs behind to incur costs which might happen if you manually delete the VM that gets created and forget to delete the Elastic IP.

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

Next we will need to get dropbox set up and authenticate your account. From the command line, type `run` and expect similar output to the following

```plain
subsonic/0:~$ run
Unable to find image 'otherguy/dropbox:latest' locally
latest: Pulling from otherguy/dropbox
16ea0e8c8879: Pull complete 
50a842f747d4: Pull complete 
de2417b2ab44: Pull complete 
54e2490986d5: Pull complete 
09a3f2dcc80a: Pull complete 
f8ca7dd60c55: Pull complete 
2f96670660f6: Pull complete 
ecb96f0ba374: Pull complete 
Digest: sha256:57d84d8a4e386d89f06f925b58616f014d30ff80ceb468d1188c48e8f6195e63
Status: Downloaded newer image for otherguy/dropbox:latest
b2e64186e5cce1af42b11c4769cb31d4d85ef77b5f0f418b459deb9a372302ad
```

then type `logs` with similar output to the following

```plain
subsonic/0:~$ logs
Checking for latest Dropbox version...
Latest   : 87.4.138
Installed: 86.4.146
Downloading Dropbox 87.4.138...
######################################################################## 100.0%
Installing new version...
Dropbox updated to v87.4.138

Starting dropboxd (87.4.138)...
dropbox: locating interpreter
!! dropbox: failed to create log file (Permission denied)!
dropbox: initializing
dropbox: initializing python 3.7.5
dropbox: setting program path '/opt/dropbox/bin/dropbox-lnx.x86_64-87.4.138/dropbox'
dropbox: setting python path '/opt/dropbox/bin/dropbox-lnx.x86_64-87.4.138:/opt/dropbox/bin/dropbox-lnx.x86_64-87.4.138/python-packages.zip'
dropbox: python initialized
dropbox: running dropbox
dropbox: setting args
dropbox: applying overrides
dropbox: running main script
dropbox: load fq extension '/opt/dropbox/bin/dropbox-lnx.x86_64-87.4.138/cryptography.hazmat.bindings._constant_time.cpython-37m-x86_64-linux-gnu.so'
dropbox: load fq extension '/opt/dropbox/bin/dropbox-lnx.x86_64-87.4.138/cryptography.hazmat.bindings._openssl.cpython-37m-x86_64-linux-gnu.so'
dropbox: load fq extension '/opt/dropbox/bin/dropbox-lnx.x86_64-87.4.138/cryptography.hazmat.bindings._padding.cpython-37m-x86_64-linux-gnu.so'
dropbox: load fq extension '/opt/dropbox/bin/dropbox-lnx.x86_64-87.4.138/psutil._psutil_linux.cpython-37m-x86_64-linux-gnu.so'
dropbox: load fq extension '/opt/dropbox/bin/dropbox-lnx.x86_64-87.4.138/psutil._psutil_posix.cpython-37m-x86_64-linux-gnu.so'
dropbox: load fq extension '/opt/dropbox/bin/dropbox-lnx.x86_64-87.4.138/linuxffi.pthread._linuxffi_pthread.cpython-37m-x86_64-linux-gnu.so'
dropbox: load fq extension '/opt/dropbox/bin/dropbox-lnx.x86_64-87.4.138/cpuid.compiled._cpuid.cpython-37m-x86_64-linux-gnu.so'
dropbox: load fq extension '/opt/dropbox/bin/dropbox-lnx.x86_64-87.4.138/apex._apex.cpython-37m-x86_64-linux-gnu.so'
dropbox: load fq extension '/opt/dropbox/bin/dropbox-lnx.x86_64-87.4.138/tornado.speedups.cpython-37m-x86_64-linux-gnu.so'
dropbox: load fq extension '/opt/dropbox/bin/dropbox-lnx.x86_64-87.4.138/linuxffi.resolv.compiled._linuxffi_resolv.cpython-37m-x86_64-linux-gnu.so'
dropbox: load fq extension '/opt/dropbox/bin/dropbox-lnx.x86_64-87.4.138/librsyncffi.compiled._librsyncffi.cpython-37m-x86_64-linux-gnu.so'
dropbox: load fq extension '/opt/dropbox/bin/dropbox-lnx.x86_64-87.4.138/linuxffi.sys.compiled._linuxffi_sys.cpython-37m-x86_64-linux-gnu.so'
dropbox: load fq extension '/opt/dropbox/bin/dropbox-lnx.x86_64-87.4.138/posixffi.libc._posixffi_libc.cpython-37m-x86_64-linux-gnu.so'
dropbox: load fq extension '/opt/dropbox/bin/dropbox-lnx.x86_64-87.4.138/linuxffi.gnu.compiled._linuxffi_gnu.cpython-37m-x86_64-linux-gnu.so'
This computer isn't linked to any Dropbox account...
Please visit https://www.dropbox.com/cli_link_nonce?nonce=85bd220cd31497f0d9a1b591e2e9e649 to link this device.
This computer isn't linked to any Dropbox account...
Please visit https://www.dropbox.com/cli_link_nonce?nonce=85bd220cd31497f0d9a1b591e2e9e649 to link this device.
```

follow the link to authenticate and then `ctrl-c` to continue. Dropbox files should now be syncing in the background.


IMPORTANT: The dropbox-cli is a bit naff and there is no simple way to avoid Dropbox trying to sync everything on start up. The VM is configured with a systemd timer that ensures exclusions are put in place so that only the music folder is synced.

The dropbox-cli is tucked away in a docker container for it's own safety, and the `dropbox` command is exposed for normal usage. Double check the exclusions are set up as expected to avoid any nonsense.

```plain
sudo systemctl status subsonic-dropbox-exclusions
dropbox status
```
But that's it, everything should just work now! Logon to your subsonic server and configure it how you want.

### Updates

Any changes to the underlying config will generally cause the VM to get re-built when you re-run

```plain
envs/aws_default_vpc/create-env.sh
```

### Teardown

to teardown the environment

```plain
DANGER-ZONE
envs/aws_default_vpc/destroy-env.sh
```

### RDS Postgres (Optional)

If you don't want the default in-memory DB then Postgres can be configured as follows

* Login to the AWS console for RDS and create a new DB named "subsonic" (use Dev/Test option to keep it in the free tier and then also select any checkboxes that say "Only enable options eligible for RDS Free Usage Tier")), take note of the host from the Connectivity tab Endpoint field (it should end in rds.amazonaws.com).
* You should use the Default subnet. Hopefully, this should correspond to the Default VPC the scripts have used.
* You wont need to set "Public accessibility" to Yes unless you want to manage the DB directly from your machine which would need external access.
* Grab the VPC default security group id and add it to the newly created DB security group on the inbound rules for port 5432
* Populate the env vars SUBSONIC_POSTGRES_DB_HOST, SUBSONIC_POSTGRES_DB_USERNAME and SUBSONIC_POSTGRES_DB_PASSWORD before running ./create-env.sh (these will be used to derive the JDBC driver url `jdbc:postgresql://$SUBSONIC_POSTGRES_DB_HOST:5432/subsonic?user=$SUBSONIC_POSTGRES_DB_USERNAME&password=$SUBSONIC_POSTGRES_DB_PASSWORD`)

### Appendix - Install Tools

#### Debian/Ubuntu

```plain
wget -q -O - https://raw.githubusercontent.com/starkandwayne/homebrew-cf/master/public.key | apt-key add -
echo "deb http://apt.starkandwayne.com stable main" | tee /etc/apt/sources.list.d/starkandwayne.list
apt-get update
apt-get install bosh-cli terraform
```
