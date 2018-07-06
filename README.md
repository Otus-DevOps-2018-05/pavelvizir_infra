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

## Homework-6 aka 'terraform-1'
#### Task \#1:
##### Create more input variables, 'terraform.tfvars.example', format with 'fmt'.  
variables.tf:
```json
variable private_key_path {
 description = "Path to the private key used for ssh access"
}
variable app_zone {
 description = "Zone for app"
 default = "europe-west1-b"
}
```
main.tf:
```json
...
private_key = "${file(var.private_key_path)}"
...
zone    = "${var.app_zone}"
...
```
```sh
terraform fmt
```
terraform.tfvars.example:
```json
project = "infra-999999"
public_key_path = "~/.ssh/appuser.pub"
disk_image = "reddit-base"
private_key_path = "~/.ssh/appuser"
```
#### Task \#2\*:  
##### Add ssh-keys to project metadata with terraform.  
> Made it without variables, lazy way :-)  
main.tf:
```json
resource "google_compute_project_metadata_item" "project-ssh-keys" {
    key = "ssh-keys"
    value = "[USERNAME_1]:ssh-rsa [KEY_VALUE_1] [USERNAME_1]\n[USERNAME_2]:ssh-rsa [KEY_VALUE_2] [USERNAME_2]"
}
```
*terraform apply* deletes other ssh keys not defined in template. Hence 'appuser-web' keyi got deleted.   
#### Task \#3\*:
##### Create load-balancer, make second node.  
> First sub-task with manual *'reddit-app2'* creation lacks flexibility. What if we want 3 or more nodes?  

> Final result with *'count'* described here. Had to create *'target pool'* and *'forwarding rule'* for load balancer to work.  

lb.tf:
```
resource "google_compute_target_pool" "default" {
  name = "instance-pool"

  instances = [
    "europe-west1-b/reddit-app0",
    "europe-west1-b/reddit-app1"
]

  health_checks = [
    "${google_compute_http_health_check.default.name}",
  ]
}

resource "google_compute_http_health_check" "default" {
  name               = "default"
  request_path       = "/"
  port	             = 9292
  check_interval_sec = 1
  timeout_sec        = 1
}

resource "google_compute_forwarding_rule" "default" {
  name       = "website-forwarding-rule"
  target     = "${google_compute_target_pool.default.self_link}"
  port_range = "9292"
}
```
outputs.tf:
```
output "app_external_ip" {
  value = "${google_compute_instance.app.*.network_interface.0.access_config.0.assigned_nat_ip}"
}
output "lb_external_ip" {
  value = "${google_compute_forwarding_rule.default.ip_address}"
}
```
variables.tf:
```
variable "node_count" {
  default = "1"
}
```
main.tf:
```
...
resource "google_compute_instance" "app" {
  count        = "${var.node_count}"
  name         = "reddit-app${count.index}"
...
```

## Homework-7 aka 'terraform-2'
#### Task \#1:  
##### First 60 pages of homework pdf :-)

**What's done:**  
 * Created 2 new packer images:
   * *db, app*  
 * Created 3 new local moudles:
   * *db, app, vpc*  
 * Played with input variables:
   * *vpc* module  
 * Played with module reuse:
   * *stage* and *prod* environments  
 * Played with module registry:
   * module *"storage-bucket"*  

```sh
gsutil ls
```

**Learned to:**  
 * define additional resources  
 * terraform import  
 * terraform implicit dependencies  
 * terraform config files decompositon  
 * terraform modules  
 * terraform get  
 * terraform output from module  
 * terraform input variables  
 * module reuse  
 * module registry  

#### Task \#2\*:
##### Configure and test remote backend (Google Cloud Storgage).

```sh
echo 'terraform {
  backend "gcs" {
    bucket  = "test_storage_infra"
    prefix  = "prod"
  }
}'\
> backend.tf
terraform init
```
Now state lock works when trying to run terraform apply from two different dirs simultaneously:  
> Acquiring state lock. This may take a few moments...  
>  
> Error: Error locking state: Error acquiring the state lock:  

#### Task \#3\*:
##### Add provisioner to modules. Make it switchable.
> App should get db address from env variable 'DATABASE_URL'  

###### First subtask: add provisioners to modules.

{prod,stage}/main.tf:
```
module "app" {
...
  private_key_path = "${var.private_key_path}"
  db_internal_ip   = "${module.db.db_internal_ip}" 
...
module "db" {
...
  private_key_path = "${var.private_key_path}"
...
```
modules/app/files/puma.service:
```
...
[Service]
Environment="DATABASE_URL=127.0.0.1"  
...
```
modules/app/main.tf:
```
...
  provisioner "file" {
    source      = "${path.module}/files/puma.service"
    destination = "/tmp/puma.service"
  }

  provisioner "remote-exec" {
    inline = [
      "sed -i 's/DATABASE_URL=127.0.0.1/DATABASE_URL=${var.db_internal_ip}/' /tmp/puma.service"
    ]
  }
...
```
modules/db/outputs.tf
```
output "db_internal_ip" {
  value = "${google_compute_instance.db.network_interface.0.address}"
}
```
modules/db/main.tf:
```
  provisioner "remote-exec" {
    script = "${path.module}/files/publish_mongo.sh"  
  }
```
modules/db/files/publish_mongo.sh:
```sh
#!/bin/bash
set -e

sudo sed -i -e 's/^\(\s*bindIp: 127.0.0.1\)/#\1/' /etc/mongod.conf
sudo systemctl restart mongod
```

##### Second subtask: make provisioners in modules switchable.

> Only doing it in *app* module.  
> To achieve the goal I have to use *null_resource* and *count*.  

> First move provisioners to *null_resource*.  

modules/app/main.tf:
```
...
resource "null_resource" "app" {
 
  count = "${var.provision_trigger}"

  connection {
    host        = "${google_compute_instance.app.network_interface.0.access_config.0.assigned_nat_ip}"
...
```
> Then set default value of *provision_trigger*.  

modules/app/variables.tf:
```
...
variable provision_trigger {
  description = "To provision or not"
  default = true
}
```
> Now switch with *'provision_trigger = false'* or *'#  provision_trigger = false'* when calling module.   

{prod,stage}/main.tf:
```
...
module "app" {
...
  provision_trigger = false
}
...
```
> Before *terraform apply* should *terraform init* for new provider *null_resource*.  

```sh
terraform init
terraform apply
```

## Homework-8 aka 'ansible-1'
#### Task \#1:  
##### Install ansible, play with it.  

```sh
ansible-playbook clone.yml
ansible app -m command -a 'rm -rf ~/reddit'
ansible-playbook clone.yml
```

**Результат выполнения команд выше одинаков, т.к. configuration management инструменту должен обеспечивать повторяемость при сохранении условий**

#### Task \#2\*:  
##### Make *ansible all -m ping* with json inventory.  

inventory.json:
```json
{
  "app": {
	"hosts": ["35.233.107.24"]
	},
  "db": {
	"hosts": ["35.233.15.19"]
  },
  "_meta": {
	"hostvars": {
	  "35.233.107.24": {
		"host_specific_var": "appserver"
	  },
	  "35.233.15.19": {
		"host_specific_var": "dbserver"
	  }
	}
  }
} 
```
inventory.sh:
```sh
#!/usr/bin/env bash
if [ "$1" == "--list" ] ; then
  cat inventory.json
elif [ "$1" == "--host" ]; then
  echo '{"_meta": {"hostvars": {}}}'
else
  echo "{ }"
fi
```
ansible.cfg:
```
# inventory = ./inventory
inventory = ./inventory.sh
```
> Now run it:  
```
chmod +x inventory.sh
ansible all -m ping
```

## Homework-9 aka 'ansible-2'
#### Task \#1:  
##### First 65 pages of homework pdf :-)

> Had to add switch to provisioning of db server in terraform.  
> Also added needed outputs to terraform:  
>   {app,db}_external_ip, db_internal_db  

Created multiple playbooks with the same tasks:  
 * *reddit_app_one_play.yml*: one play per playbook  
 * *reddit_app_multiple_plays.yml*: multiple plays per playbook  
 * *site.yml*: includes multiple playbooks:  
   * *db.yml*: db play  
   * *app.yml*: app play  
   * *deploy.yml*: deploy app play  

#### Task \#2\*:
##### Select dynamic inventory script and start using it.

> **gce.py** is the most used, tested etc  

Let's install and configure it.

```sh
wget https://raw.githubusercontent.com/ansible/ansible/devel/contrib/inventory/gce.{ini,py}
trizen -S python-apache-libcloud
chmod +x gce.py
# download json credentials file
echo "GCE_PARAMS = ('<service_mail>', '/path/to/json_credentials')
GCE_KEYWORD_PARAMS = {'project': '<project>', 'datacenter': '<zone>'}"\
> secrets.py
echo -e '__pycache__\nsecrets.py' >> ../.gitignore
sed -i 's/inventory = .\/inventory/inventory = .\/gce.py/' ansible.cfg
./gce.py --list
```
> Now there is a problem, as my hosts are **'app'** and **'db'**, but *gce.py* returns **'reddit-app'** and **'reddit-db'**.  
> Let's fix it by passing variable *'site_prefix'* to playbooks and using that variable in hostnames.  

site.yml:
```
...
- import_playbook: db.yml
    site_prefix="reddit-"
...
```
{db,app,deploy}.yml:
```
...
hosts: "{{ prefix }}db"
...
vars:
  ...
  prefix: '{{ vars["site_prefix"] | default("") }}'
...
```
Now test it:
```sh
ansible-playbook site.yml --check
...
PLAY RECAP ****************************************************************
reddit-app                 : ok=7    changed=0    unreachable=0    failed=0   
reddit-db                  : ok=2    changed=0    unreachable=0    failed=0
```
Works! :-)  

#### Task \#3:
##### Change packer's bash scripts to ansible playbooks.  

> Working with *packer_app.yml* as an example here. Working with *packer_db.yml* is the same, only contents differs.

packer_app.yml:
```
...
      apt:
        name: "{{ item }}"
        state: present
      loop:
        - ruby-full
        - ruby-bundler
        - build-essential
```
packer/app.json:
```
"provisioners": [
    {
        "type": "ansible",
	"playbook_file": "ansible/packer_app.yml"
    }
  ]
```
Now test it!
```sh
packer build --var-file=packer/variables.json packer/app.json
```

TBC

