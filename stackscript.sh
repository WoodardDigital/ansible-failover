#!/bin/bash

# <UDF name="SUBNODE_PASSWORD" Label="Sub-Node password" example="This will be the password for the secondary node. " />

# <UDF name="API_TOKEN_PASSWORD" Label="Linode API Password" example="This token is used to add additional IP's and configure the next instance. " />

## WHEN TESTING LOCALLY##
# It's easiest to declare your API token. So let's just do that here..

export API_TOKEN_PASSWORD=$

# install packages
apt-get update 
apt-get install -y ansible git python3 python3-pip jq

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

# Grabs our current plan size to duplicate for the new instance. 
export TYPE=$(curl -s -H "Metadata-Token: $MTOKEN" http://169.254.169.254/v1/instance | grep "type" | awk -F": " '{print $2}' | xargs)


# Makes a dir for our stuff
mkdir -p /tmp/installation

# export our variables to a file 
echo "$REGION" > /tmp/installation/REGION
echo "$CONTROL_IP" > /tmp/installation/CONTROL_IP
echo "$MTOKEN" > /tmp/installation/MTOKEN
echo "$API_TOKEN_PASSWORD" > /tmp/installation/API_TOKEN_PASSWORD
echo "$SUBNODE_PASSWORD" > /tmp/installation/SUBNODE_PASSWORD
echo "$TYPE" > /tmp/installation/TYPE

# Define a mapping between regions (DCs) and IDs 

################THIS NEEDS ADDED TO###################

declare -A DCID_MAPPING
DCID_MAPPING["us-ord"]=18
DCID_MAPPING["us-lax"]=30

# Check if the REGION exists in the mapping
if [ -n "${DCID_MAPPING[$REGION]}" ]; then
  DCID="${DCID_MAPPING[$REGION]}"
  echo "DCID: $DCID"
else
  echo "Region $REGION not found in the mapping"
fi

# echos the DCIC to a file 
echo "$DCID" > /tmp/installation/DCID

# Generates a random password. This will need some modiciation, but it should work for now. 
export SUBPASS=$(LC_ALL=C tr -dc '[:graph:]' </dev/urandom | head -c 32; echo)
echo $SUBPASS > /tmp/installation/SUBPASS

# Creates a new Linode in the same DC
curl -H "Content-Type: application/json" \
-H "Authorization: Bearer $API_TOKEN_PASSWORD" \
-X POST -d '{
    "authorized_users": [
        "levi_woodard"
    ],
    "backups_enabled": false,
    "booted": true,
    "image": "linode/ubuntu22.04",
    "label": "autofailover-test-01",
    "private_ip": false,
    "region": "'"$REGION"'",
    "root_pass": "'"$SUBPASS"'",
    "tags": [
        "Failover"
    ],
    "type": "'"$TYPE"'"
}' https://api.linode.com/v4/linode/instances > /tmp/installation/SUBINSTANCE

# Use jq to extract the IP address from the response
SUBIP=$(cat /tmp/installation/SUBINSTANCE | jq -r '.ipv4[0]')

# Print the extracted IP address
echo $SUBIP > /tmp/installation/SUBIP


#Clones the playbooks down to the system 
# git clone https://github.com/WoodardDigital/ansible-failover.git
# cd ansible-failover/Ansible 