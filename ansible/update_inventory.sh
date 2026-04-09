#!/bin/bash

cd ../terraform

DEV_IP=$(terraform output -raw dev_ip)
STG_IP=$(terraform output -raw stage_ip)
PROD_IP=$(terraform output -raw prod_ip)

cd ../ansible

# DEV
cat > inventories/dev/hosts <<EOF
[servers]
dev ansible_host=$DEV_IP

[servers:vars]
ansible_user=ubuntu
ansible_ssh_private_key_file=../devops-key
EOF

# STG
cat > inventories/stg/hosts <<EOF
[servers]
stg ansible_host=$STG_IP

[servers:vars]
ansible_user=ubuntu
ansible_ssh_private_key_file=../devops-key
EOF

# PROD
cat > inventories/prod/hosts <<EOF
[servers]
prod ansible_host=$PROD_IP

[servers:vars]
ansible_user=ubuntu
ansible_ssh_private_key_file=../devops-key
EOF
