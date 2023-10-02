## Setup the Terraform backend
## Storage account details are passed from the Infrastructure Pipeline
terraform {
  required_version = ">= 1.5"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3.72.0, < 4.0"
    }
  }
  backend "azurerm" {
    resource_group_name  = "rg-infraops-centralus"
    storage_account_name = "stcinfraopsbtscentus"
    container_name       = "devops-containerapp"
    key                  = "terraform.tfstate"
  }
}

## Azurerm
provider "azurerm" {
  features {}
}
