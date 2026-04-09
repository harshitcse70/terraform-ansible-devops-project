#!/bin/bash

cd bootstrap

BUCKET=$(terraform output -raw bucket_name)
TABLE=$(terraform output -raw dynamodb_table)

cd ..

terraform init \
  -backend-config="bucket=$BUCKET" \
  -backend-config="key=global/terraform.tfstate" \
  -backend-config="region=eu-north-1" \
  -backend-config="dynamodb_table=$TABLE" \
  -backend-config="encrypt=true"
