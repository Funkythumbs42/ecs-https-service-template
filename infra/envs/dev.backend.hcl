# Partial S3 backend config for dev. Replace the placeholders.
bucket       = "REPLACE-ME-terraform-state-bucket"
key          = "services/my-service/dev/terraform.tfstate"
region       = "eu-west-1"
encrypt      = true
use_lockfile = true # S3-native locking (Terraform >= 1.10); use dynamodb_table on older versions
