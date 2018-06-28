# pavelvizir_infra
pavelvizir Infra repository

## Homework-3
**Task \#1: Connect to 'someinternalhost' with one-liner.**
*\# pseudo-terminal way, '-t'*
ssh -i ~/.ssh/cloud_google_appuser_key -A -t appuser@104.199.32.91 ssh -A 10.132.0.3

**Task \#2: Same as 'Task \#1', but with command 'ssh someinternalhost' or alias 'someinternalhost'.**
*\# ProxyCommand way, '-W', ssh 5.3-7.2. For very old ssh use nc, for ssh 7.3+ use ProxyJump.
\# ssh someinternalhost*
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
*\# alias someinternalhost, with bash*
echo "alias someinternalhost='ssh someinternalhost'" >> ~/.bashrc
source ~/.bashrc
someinternalhost

**Task \#3: Final vars.**
bastion_IP = 104.199.32.91
someinternalhost_IP = 10.132.0.3

## Homework-4
**Task \#1: Create separate deploy scripts.**
*Created:
	install_ruby.sh
	install_mongodb.sh
	deploy.sh*
chmod +x \*.sh
**Task \#2: Create startup script and write glcoud command. Try 'startup-script-url' as well.**
*Created:
	startup_script.sh*
\#chmod +x startup_script.sh
*Gcloud command used:*
gcloud compute instances create reddit-app\
  --boot-disk-size=10GB \
  --image-family ubuntu-1604-lts \
  --image-project=ubuntu-os-cloud \
  --machine-type=g1-small \
  --tags puma-server \
  --restart-on-failure \
  --metadata-from-file startup-script=startup_script.sh
*\# startup-script-url requires cloud storage, so:
\# created bucket, placed script there.
Gcloud command used:*
gcloud compute instances create reddit-app\
  --boot-disk-size=10GB \
  --image-family ubuntu-1604-lts \
  --image-project=ubuntu-os-cloud \
  --machine-type=g1-small \
  --tags puma-server \
  --restart-on-failure \
  --scopes storage-ro \
  --metadata startup-script-url=gs://test_storage_infra/startup_script.sh
**Task \#3: Create FW rule with gcloud.**
\# gcloud compute firewall-rules delete default-puma-server 
gcloud compute --project=infra-207711 firewall-rules create default-puma-server --direction=INGRESS --priority=1000 --network=default --action=ALLOW --rules=tcp:9292 --source-ranges=0.0.0.0/0 --target-tags=puma-server

**Travis strings:**
testapp_IP = 35.233.11.193
testapp_port = 9292
