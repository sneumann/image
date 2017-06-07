#!/bin/bash
# shellcheck disable=SC1091

# This Script will be executed as post-processor of the Openstack packer builder within a OS VM instances, not in Travis.
# Travis environment has not enough resources for the below steps, hence it takes a longer time causing timeouts.
# The script takes two parameters: current_version and image_id of the newly created KubewNow image.

# Fix OS potential issue/bug: "sudo: unable to resolve host..."
sudo sed -i /etc/hosts -e "s/^127.0.0.1 localhost$/127.0.0.1 localhost $(hostname)/"

# Install Tools
sudo apt-get update && sudo apt-get install qemu-utils awscli python-dev python-pip -y
pip install --upgrade pip
sudo pip install python-glanceclient

# Donwloading newly created KubeNow from OS
echo "Downloading KubeNow image from Openstack..."
echo "Sourcing Openstack environment"
source /tmp/citycloud.sh
glance image-download --file "$1" "$2"

# Converting image from raw to qcow format.
echo "Converting RAW image into QCOW2 format..."
qemu-img convert -f qcow2 -O qcow2 -c -q "$1" "$1".qcow2

# Uploading the new image format to the AWS S3 bucket. Previous copy will be overwritten.
echo "Uploading new image format into AWS S3 bucket: kubenow-us-east-1 ..."
echo "Sourcing AWS environment"
source /tmp/aws.sh
aws s3 cp "$1".qcow2 s3://kubenow-us-east-1 --region us-east-1 --acl public-read --quiet
