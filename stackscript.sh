#!/bin/bash

# <UDF name="SUBNODE_PASSWORD" Label="Sub-Node password" example="This will be the password for the secondary node. " />

# <UDF name="API_TOKEN_PASSWORD" Label="Linode API Password" example="This token is used to add additional IP's and configure the next instance. " />

# install packages
apt-get update 
apt-get install -y ansible git python3 python3-pip

# installs ansible dependencies 
sudo -H pip3 install -Iv 'resolvelib<0.6.0'

# installs the Linode Ansible collection 
ansible-galaxy collection install linode.cloud

# Installs more stuff 
sudo pip3 install -r .ansible/collections/ansible_collections/linode/cloud/requirements.txt

# requests metadatatoken
export MTOKEN=$(curl -s -X PUT -H "Metadata-Token-Expiry-Seconds: 3600" http://169.254.169.254/v1/token)

# metatdata info from the DC for this Linode 
# curl -H "Metadata-Token: $MTOKEN" http://169.254.169.254/v1/instance

Exports the region to the env so we can use it to create another Linode later. 
export REGION=$(curl -s -H "Metadata-Token: $MTOKEN" http://169.254.169.254/v1/instance | grep "region" | awk -F": " '{print $2}' | xargs)

# Grabs our IP address just to have for now 
export CONTROL_IP=$(curl -s -H "Metadata-Token: $MTOKEN" http://169.254.169.254/v1/network | grep "ipv4.public" | awk -F": " '{print $2}' | xargs)

# Makes a dir for our stuff
mkdir -p /installation

# export our variables to a file 
echo "$REGION" > /tmp/installation/REGION
echo "$CONTROL_IP" > /tmp/installation/CONTROL_IP
echo "$MTOKEN" > /tmp/installation/MTOKEN
echo "$API_TOKEN_PASSWORD" > /tmp/installation/API_TOKEN_PASSWORD
echo "$SUBNODE_PASSWORD" > /tmp/installation/SUBNODE_PASSWORD
# echos the DCIC to a file 
echo "$LINODE_DATACENTERID" > /tmp/installation/DCID

#Clones the playbooks down to the system 
git clone https://github.com/WoodardDigital/ansible-failover.git

cd ansible-failover/Ansible


# These were formerly used, keeping here till I know I don't need them any longer.
# Generates a random password. This will need some modiciation, but it should work for now. 
# tr -dc 'A-Za-z0-9!"#$%&'\''()*+,-./:;<=>?@[\]^_`{|}~' </dev/urandom | head -c 28 > /installation/subnode.password
# Exports the password to the $SUB_PASS variable 
# export SUB_PASS=$(cat /installation/subnode.password)

