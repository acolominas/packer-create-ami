.PHONY: help
help: ## Display this help screen
	@grep -E '^[a-z.A-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'
install-prerequisites: ## Deploy the AWS Resouces needed to import the AMI.
	terraform -chdir=terraform init
	terraform -chdir=terraform fmt -recursive
	terraform -chdir=terraform validate
	terraform -chdir=terraform plan -out=terraform.tfplan
	terraform -chdir=terraform apply terraform.tfplan

destroy-prerequisites: ## Destroy the AWS Resouces needed to import the AMI.
	terraform -chdir=terraform destroy --auto-approve
	rm -rf terraform/.terraform* terraform/terraform.tfplan

build-opnsense:	## Build the OPNsense AMI
	packer init packer-opnsense.pkr.hcl
	packer fmt -check packer-opnsense.pkr.hcl
	packer validate packer-opnsense.pkr.hcl
	packer build packer-opnsense.pkr.hcl

build-pfsense: ## Build the PFsense AMI
	packer init packer-pfsense.pkr.hcl
	packer fmt -check packer-pfsense.pkr.hcl
	packer validate packer-pfsense.pkr.hcl
	packer build packer-pfsense.pkr.hcl

clean-builds:	## Remove all the Virtual Machines in output directory
	rm -rf output

clean-all: clean-builds destroy-prerequisites	## Remove all the Virtual Machines in output directory and the AWS Resources
