# Default: local state (terraform.tfstate in this folder, gitignored).
#
# For anything shared or long-lived, use remote state:
#   1. cd ../../bootstrap && terraform apply   (creates the S3 bucket)
#   2. uncomment the block below, fill in the bucket name
#   3. terraform init -migrate-state
#
# terraform {
#   backend "s3" {
#     bucket       = "<state bucket from terraform/bootstrap>"
#     key          = "k8s-demo/dev/terraform.tfstate"
#     region       = "ap-south-1"
#     encrypt      = true
#     use_lockfile = true # S3-native locking, no DynamoDB table needed
#   }
# }
