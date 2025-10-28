# Makefile for building and deploying the web app with terraform
.PHONY: init plan apply destroy clean

init:
	terraform init

plan: init
	terraform plan

apply: plan
	terraform apply

destroy:
	terraform destroy

clean:
	find . -name "*.tfstate" -type f -delete
	find . -name "*.tfstate.backup" -type f -delete
	find . -name ".terraform" -type d -exec rm -rf {} +