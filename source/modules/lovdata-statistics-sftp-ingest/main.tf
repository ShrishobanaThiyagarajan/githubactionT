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

resource "azurerm_resource_group" "data-dev-k" {
  name     = "data-dev-k"
  location = "West Europe"
}

resource "azurerm_storage_account" "storagesftpdevk" {
    resource_group_name = "data-dev-k"
    account_tier = "Standard"
    name = "storagesftpdevk"
    location = "West Europe"
    account_kind = "StorageV2"
    account_replication_type = "RAGRS"
    cross_tenant_replication_enabled = false
    is_hns_enabled = true
    allow_nested_items_to_be_public = false
    sftp_enabled = true
    tags = {
        Environment = "Dev"
    }
}


