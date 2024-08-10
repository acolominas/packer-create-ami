all: init test build deploy

init:
	terraform -chdir=terraform init

test:
	terraform -chdir=terraform fmt -recursive
	terraform -chdir=terraform validate

build:
	terraform -chdir=terraform plan -out=terraform.tfplan

build-pfsense:
	./scripts/build.sh -o pfsense -s3 vmimport-input-acolominas -region eu-west-1

deploy:
	terraform -chdir=terraform apply terraform.tfplan

clean:
	terraform -chdir=terraform destroy
	rm -rf .terraform* terraform.tfplan dist/*
