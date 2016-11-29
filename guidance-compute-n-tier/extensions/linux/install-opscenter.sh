#!/usr/bin/env bash

cloud_type="azure"
seed_node_name=$1
location=$2

echo "Input to node.sh is:"
echo cloud_type $cloud_type
echo seed_node_name $seed_node_name
echo location $location

seed_node_dns_name="$seed_node_name.$location.cloudapp.azure.com"

echo "Calling opscenter.sh with the settings:"
echo cloud_type $cloud_type
echo seed_node_dns_name $seed_node_dns_name

apt-get -y install unzip

wget https://github.com/DSPN/install-datastax-ubuntu/archive/master.zip
unzip master.zip
cd install-datastax-ubuntu-master/bin

./opscenter.sh $cloud_type $seed_node_dns_name