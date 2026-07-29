# backend.tf
terraform {
  backend "s3" {
    bucket         = "aurix-terraform-state-dev"
    key            = "aurix-platform/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "aurix-terraform-locks"
  }
}

# Override for other environments via:
#   terraform init -backend-config="bucket=aurix-terraform-state-<env>"
#
# Or use a partial config file:
#   terraform init -backend-config=backend-<env>.hcl

# Note: Azure backend uses "azurerm" with storage_account_name and container_name
# Note: GCP backend uses "gcs" with bucket name
#
# For Azure:
# terraform {
#   backend "azurerm" {
#     storage_account_name = "aurixtfstatedev"
#     container_name       = "terraform-state"
#     key                  = "aurix-platform.tfstate"
#   }
# }
#
# For GCP:
# terraform {
#   backend "gcs" {
#     bucket = "aurix-terraform-state-dev"
#     prefix = "terraform/state"
#   }
# }
