
## Prerequisites

* Tools installed (bosh-cli v2, terraform)
* Standard env vars for AWS (AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY, AWS_DEFAULT_REGION)
* AWS key pair created, downloaded to a directory registered as env AWS_PRIVATE_KEY_LOCATION with the key pair name declared as AWS_KEYPAIR_NAME

State files created from `terraform` and `bosh` are listed in `.gitignore` as they contain sensitive info as well as state that you should store safely. You are on your own with that aspect.


## Create the Subsonic VM

This is simply a matter of running the provided script. We rely on the [jumpbox-deployment](https://github.com/cloudfoundry/jumpbox-deployment) project as a sub-module, which you should prepare as instructed below

### Bootstrapping

cd into the root directory of this project and run

```plain
git submodule update --init
envs/aws_default_vpc/create-env.sh
envs/aws_default_vpc/jumpbox-ssh.sh
# you should now be in the ~ dir of the jumpbox which is actually /var/vcap/store/home/jumpbox. NOTE: Run `ssh-keygen -R <elastic-ip>` after any VM destroys to clean up the known_hosts file.
./ubuntu_dropbox_up.sh
```

the default VPC will be used (main assumption is that the first subnet has a free IP at .10) and the only changes in AWS will be a new Elastic IP and modifications to the default security group to ensure access over ports 22 and 6868 (the latter is for connectivity to the bosh agent, specifically mbus).

### Teardown

to teardown the environment

```plain
DANGER-ZONE
envs/aws_default_vpc/destroy-env.sh
```
