include .secrets.env
export

.PHONY: packer-init packer-validate packer-build terraform-init terraform-plan terraform-apply terraform-destroy ansible-run

PKR_VARS = PKR_VAR_proxmox_password='$(PROXMOX_PASSWORD)' \
           PKR_VAR_proxmox_username='$(PROXMOX_USERNAME)' \
           PKR_VAR_proxmox_node='$(PROXMOX_NODE)' \
           PKR_VAR_proxmox_url='$(PROXMOX_HOST)'/api2/json \
		   PKR_VAR_storage_pool='$(STORAGE_POOL)'

TF_VARS  = TF_VAR_proxmox_password='$(PROXMOX_PASSWORD)' \
           TF_VAR_proxmox_username='$(PROXMOX_USERNAME)' \
           TF_VAR_proxmox_node='$(PROXMOX_NODE)' \
           TF_VAR_proxmox_endpoint='$(PROXMOX_HOST)'/ \
		   TF_VAR_vm_id='$(VM_ID)' \
		   TF_VAR_vm_name='$(VM_NAME)' \
		   TF_VAR_storage_pool='$(STORAGE_POOL)' \
		   TF_VAR_vlan_id='$(VLAN_ID)' \
		   TF_VAR_dns_domain='$(DNS_DOMAIN)' \
		   TF_VAR_dhcp='$(DHCP)' \
		   TF_VAR_ip_address='$(IP_ADDRESS)' \
		   TF_VAR_ip_gateway='$(IP_GATEWAY)'

PACKER_DIR    = packer
#PACKER_VARS   = $(PACKER_DIR)/secrets.pkrvars.hcl
TERRAFORM_DIR = terraform
ANSIBLE_INV   = ansible/inventory/hosts.yml
ANSIBLE_PLAY  = ansible/playbook.yml

packer-init:	
	packer init $(PACKER_DIR)/. || true
packer-validate:
	$(PKR_VARS) packer validate $(PACKER_DIR)/.
packer-build:
	$(PKR_VARS) packer build $(PACKER_DIR)/.

terraform-init:
	terraform -chdir=$(TERRAFORM_DIR) init

terraform-plan:
	$(TF_VARS) terraform -chdir=$(TERRAFORM_DIR) plan

terraform-apply:
	$(TF_VARS) terraform -chdir=$(TERRAFORM_DIR) apply

terraform-destroy:
	$(TF_VARS) terraform -chdir=$(TERRAFORM_DIR) destroy

ansible-run:
	ansible-playbook -i $(ANSIBLE_INV) $(ANSIBLE_PLAY)
