# pavelvizir_infra
pavelvizir Infra repository

## Homework-3
#### Task \#1:  
##### Connect to *'someinternalhost'* with one-liner.  
> pseudo-terminal way, '-t'  
```sh
ssh -i ~/.ssh/cloud_google_appuser_key -A -t appuser@104.199.32.91 ssh -A 10.132.0.3
```
#### Task \#2:  
##### Same as 'Task \#1', but with command *'ssh someinternalhost'* or alias *'someinternalhost'.*  
> ProxyCommand way, '-W', ssh 5.3-7.2.  
> For very old ssh use nc, for ssh 7.3+ use ProxyJump.  

*'ssh someinternalhost'*  
```sh
echo '
host bastion
        Hostname 104.199.32.91
        IdentityFile ~/.ssh/cloud_google_appuser_key
        User appuser
        AddKeysToAgent yes 

host someinternalhost
        ProxyCommand ssh bastion -W %h:%p
        Hostname 10.132.0.3
        IdentityFile ~/.ssh/cloud_google_appuser_key
        User appuser'\
>> ~/.ssh/config
ssh someinternalhost
```
*'someinternalhost*' - bash alias  
```sh
echo "alias someinternalhost='ssh someinternalhost'" >> ~/.bashrc
source ~/.bashrc
someinternalhost
```
#### Task \#3:  
##### Travis variables.  
bastion_IP = 104.199.32.91  
someinternalhost_IP = 10.132.0.3

## Homework-4
#### Task \#1:  
##### Create separate deploy scripts.  
```sh
vim install_ruby.sh
vim install_mongodb.sh
vim deploy.sh
chmod +x *.sh
```
#### Task \#2:  
##### Create startup script and write glcoud command. Try 'startup-script-url' as well.  
Create *'startup_script.sh'*:
```sh
vim startup_script.sh
chmod +x startup_script.sh
```
**gcloud** command with *'startup-script'*:  
```sh
gcloud compute instances create reddit-app\
  --boot-disk-size=10GB \
  --image-family ubuntu-1604-lts \
  --image-project=ubuntu-os-cloud \
  --machine-type=g1-small \
  --tags puma-server \
  --restart-on-failure \
  --metadata-from-file startup-script=startup_script.sh
```
> *'Startup-script-url'* requires cloud storage so had to create bucket. Placed script there.   

**gcloud** command with *'startup-script-url'*:
```sh
gcloud compute instances create reddit-app\
  --boot-disk-size=10GB \
  --image-family=ubuntu-1604-lts \
  --image-project=ubuntu-os-cloud \
  --machine-type=g1-small \
  --tags=puma-server \
  --restart-on-failure \
  --scopes storage-ro \
  --metadata startup-script-url=gs://test_storage_infra/startup_script.sh
```
#### Task \#3:  
##### Create FW rule with gcloud.  
> To delete rule:
```sh
gcloud compute firewall-rules delete default-puma-server
```
**gcloud** command to create FW rule:
```sh
gcloud compute --project=infra-207711 firewall-rules create default-puma-server --direction=INGRESS --priority=1000 --network=default --action=ALLOW --rules=tcp:9292 --source-ranges=0.0.0.0/0 --target-tags=puma-server
```
#### Travis strings:  
testapp_IP = 35.233.11.193  
testapp_port = 9292

## Homework-5
#### Task \#1:  
##### Create image with packer using template user variables.  
Make *'variables'* section in a template, place user variables in other sections:
```sh
vim ubuntu16.json
```
```json
{
    "variables": {
        "project_id": null
        ...
    },
    "builders": [
        {
            "project_id": "{{user `project_id`}}"
            ...
	}
    ]
}
```
Make *'-var-file'* to define some variables:
```sh
vim variables.json  
```
```json
{
  "project_id": "infra-999999"
  ...
}
```
Validate template and run **packer**:
```sh
packer validate -var-file=variables.json ubuntu16-variables.json
packer build -var-file=variables.json ubuntu16-variables.json
```
#### Task \#2\*:
##### 'Bake' app into *'reddit-full'* image.
```sh
mkdir files
echo '[Unit]
Description=puma_service

[Service]
WorkingDirectory=/home/appuser/reddit
ExecStart=/usr/local/bin/puma
Restart=always
RestartSec=10
SyslogIdentifier=puma_service

[Install]
WantedBy=default.target' \
> files/puma.service
```
```sh
echo '#!/bin/bash
set -e
set -x
git clone -b monolith https://github.com/express42/reddit.git
cd reddit && bundle install' \
> scripts/deploy_puma.sh
```
```sh
vim immutable.json
```
```json
...
    "provisioners": [
	{
            "type": "shell",
	    "remote_folder": "/home/appuser",
            "script": "scripts/deploy_puma.sh"
	},
	{
            "type": "file",
	    "source": "files/puma.service",
	    "destination": "/tmp/puma.service"
	},
	{
	    "type": "shell",
	    "inline_shebang": "/bin/bash",
            "inline": [
		    "set -e",
		    "set -x",
		    "sudo loginctl enable-linger appuser",
		    "mkdir -pv /home/appuser/.config/systemd/user",
		    "mv -v /tmp/puma.service /home/appuser/.config/systemd/user/",
		    "systemctl --user daemon-reload",
		    "systemctl --user enable puma.service"
...
```
Commands to run:
```sh
packer validate -var 'project_id=omg' immutable.json
packer build -var 'project_id=infra-999999' immutable.json
```
#### Task \#3\*:
##### Create *'create-reddit-vm.sh'*.
```sh
vim ../config-scripts/create-reddit-vm.sh
```
```sh
gcloud compute instances create reddit-app \
--boot-disk-size=11GB \
--image-family=reddit-full \
--image-project=infra-999999 \
--machine-type=f1-micro \
--tags=puma-server \
--restart-on-failure
```
```sh
chmod +x ../config-scripts/create-reddit-vm.sh
```
