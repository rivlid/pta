.PHONY: packer-init packer-validate packer-build terraform-init terraform-plan terraform-apply ansible-run

PACKER_DIR    = packer
PACKER_VARS   = $(PACKER_DIR)/secrets.pkrvars.hcl
TERRAFORM_DIR = terraform
ANSIBLE_INV   = ansible/inventory/hosts.yml
ANSIBLE_PLAY  = ansible/playbook.yml

packer-init:	
	packer init $(PACKER_DIR)/.
packer-validate:
	packer validate -var-file="$(PACKER_VARS)" $(PACKER_DIR)/.
packer-build:
	packer build -var-file="$(PACKER_VARS)" $(PACKER_DIR)/.

terraform-init:
	terraform -chdir=$(TERRAFORM_DIR) init

terraform-plan:
	terraform -chdir=$(TERRAFORM_DIR) plan

terraform-apply:
	terraform -chdir=$(TERRAFORM_DIR) apply

terraform-destroy:
	terraform -chdir=$(TERRAFORM_DIR) destroy

ansible-run:
	ansible-playbook -i $(ANSIBLE_INV) $(ANSIBLE_PLAY)
