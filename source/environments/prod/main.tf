terraform {
  required_providers {
    azurerm = {
        source  = "hashicorp/azurerm"
        version = "=3.40.0"
    }
  }

  backend "remote" {
    organization = "Karnov-Group-Norway"

    workspaces {
      name = "infrastructure-prod"
    }
  }
}

provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "data-prod-k" {
  name     = "data-prod-k"
  location = "West Europe"
}

module "lovdata-statistics-sftp-ingest" {
  source = "../../modules/lovdata-statistics-sftp-ingest"
  resource_group_name = azurerm_resource_group.data-prod-k.name
  environment_name = var.environment_name
}
