terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=3.52.0"
    }
  }

  backend "remote" {
    organization = "Karnov-Group-Norway"

    workspaces {
      name = "infrastructure-platform"
    }
  }
}

provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "resourcegroup" {
  name     = "${lower(var.environment_name)}-k"
  location = "West Europe"
}
 
resource "azurerm_storage_account" "builds_binary_repo" {
  name = "buildsbinaryrepo"
  resource_group_name = azurerm_resource_group.resourcegroup.name
  location = azurerm_resource_group.resourcegroup.location

  account_tier = "Standard"
  account_replication_type = "LRS"
  account_kind = "BlobStorage"

  blob_properties {
    delete_retention_policy {
      days = 365
    }
    container_delete_retention_policy {
      days = 365
    }
  }

  tags = {
    environment = var.environment_name
  }
}

output "builds_binary_repo" {
  sensitive = true
  value     = azurerm_storage_account.builds_binary_repo
}
