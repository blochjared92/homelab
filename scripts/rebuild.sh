#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/../terraform/proxmox"
terraform apply -auto-approve

echo "Waiting for VMs to finish booting..."
sleep 45

cd ../../ansible
IPS=$(cd ../terraform/proxmox && terraform output -json test_vm_ip_list | jq -r '.[]')

for ip in $IPS; do
  ssh-keygen -f ~/.ssh/known_hosts -R "$ip" 2>/dev/null || true
done

ssh-keyscan -H $IPS >> ~/.ssh/known_hosts 2>/dev/null

ansible-playbook -i inventory.yml playbooks/base.yml
