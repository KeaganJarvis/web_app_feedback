# both `write_files` and `chef` cloudinit stanzas were misbehaving so ran commands direct
runcmd:
- wget https://packages.chef.io/files/stable/chef-workstation/21.9.613/ubuntu/18.04/chef-workstation_21.9.613-1_amd64.deb
- dpkg -i chef-workstation_21.9.613-1_amd64.deb
- sudo chef-client --chef-license accept
- git clone https://github.com/KeaganJarvis/web_app_feedback.git /web_app_feedback
- echo ${asana_key} >> /web_app_feedback/web_app/asana.key
- cd /web_app_feedback/chef/cookbooks/
- sudo chef-client --local-mode

output: {all: '| tee -a /var/log/cloud-init-output.log'}