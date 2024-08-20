all: install-prerequisites build-opnsense

install-prerequisites:
	terraform -chdir=terraform init
	terraform -chdir=terraform fmt -recursive
	terraform -chdir=terraform validate
	terraform -chdir=terraform plan -out=terraform.tfplan
	terraform -chdir=terraform apply terraform.tfplan

build-opnsense:
	packer init packer-opnsense.pkr.hcl
	packer fmt -check packer-opnsense.pkr.hcl
	packer validate packer-opnsense.pkr.hcl
	packer build packer-opnsense.pkr.hcl

build-pfsense:
	packer init packer-pfsense.pkr.hcl
	packer fmt -check packer-pfsense.pkr.hcl
	packer validate packer-pfsense.pkr.hcl
	packer build packer-pfsense.pkr.hcl

clean-builds:
	rm -tf output

clean-all:
	rm -rf output
	terraform -chdir=terraform destroy --auto-approve
	rm -rf terraform/.terraform* terraform/terraform.tfplan
