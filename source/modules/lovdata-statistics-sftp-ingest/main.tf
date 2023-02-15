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

resource "azurerm_storage_container" "lovdatastats" {
  name                  = "lovdatastats"
  storage_account_name  = azurerm_storage_account.sftpstorage.name
  container_access_type = "private"
}

resource "azurerm_storage_account_local_user" "lovdata" {
  name                 = "ghtest"
  storage_account_id   = azurerm_storage_account.sftpstorage.id
  ssh_key_enabled      = true
  ssh_password_enabled = true
  home_directory       = "lovdatastats"
  
  #ssh_authorized_key {
  #  description = "key1"
  #  key         = local.first_public_key
  #}
  #ssh_authorized_key {
  #  description = "key2"
  #  key         = local.second_public_key
  #}
  permission_scope {
    permissions {
      read   = true
      create = true
    }
    service       = "blob"
    resource_name = azurerm_storage_container.lovdatastats.name
  }
}
