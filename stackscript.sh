#!/bin/bash


# <UDF name="API_TOKEN" Label="Linode API Token" example="This token is used to add additional IP's and configure the next instance. " />

# upgrades \ updates
apt-get update && apt-get upgrade -y

# install packages
apt-get install -y ansible






