#!/bin/bash

cd "$1"
if [ -f "terraform.tfstate" ]
then
  terraform destroy -auto-approve || exit 1
fi
rm -rf *.tf *.tfvars az vpc peering


