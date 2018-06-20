# pavelvizir_infra
pavelvizir Infra repository

Task #1: Connect to 'someinternalhost' with one-liner.
# pseudo-terminal way, '-t'
ssh -i ~/.ssh/cloud_google_appuser_key -A -t appuser@104.199.32.91 ssh -A 10.132.0.3

Task #2: Same as 'Task #1', but with command 'ssh someinternalhost' or alias 'someinternalhost'.
# ProxyCommand way, '-W', ssh 5.3-7.2. For very old ssh use nc, for ssh 7.3+ use ProxyJump.
# ssh someinternalhost
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
# alias someinternalhost, with bash
echo "alias someinternalhost='ssh someinternalhost'" >> ~/.bashrc
source ~/.bashrc
someinternalhost

Task #3 (final)
bastion_IP = 104.199.32.91
someinternalhost_IP = 10.132.0.3
