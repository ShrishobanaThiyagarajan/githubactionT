terraform {
  required_providers {
    azurerm = {
        source  = "hashicorp/azurerm"
        version = "=3.40.0"
    }
  }
}

provider "azurerm" {
  features {}
}

resource "azurerm_storage_account" "sftpstorage" {
    resource_group_name = var.resource_group_name
    account_tier = "Standard"
    name = "storagesftp${lower(var.environment_name)}k"
    location = "West Europe"
    account_kind = "StorageV2"
    account_replication_type = "RAGRS"
    cross_tenant_replication_enabled = false
    is_hns_enabled = true
    allow_nested_items_to_be_public = false
    sftp_enabled = true
    tags = {
        Environment = var.environment_name
    }
}


