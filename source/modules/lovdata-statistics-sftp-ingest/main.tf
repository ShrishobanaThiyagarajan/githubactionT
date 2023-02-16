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
  resource_group_name              = var.resource_group_name
  account_tier                     = "Standard"
  name                             = "storagesftp${lower(var.environment_name)}k"
  location                         = "West Europe"
  account_kind                     = "StorageV2"
  account_replication_type         = "RAGRS"
  cross_tenant_replication_enabled = false
  is_hns_enabled                   = true
  allow_nested_items_to_be_public  = false
  sftp_enabled                     = true
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
  name                 = "lovdata2"
  storage_account_id   = azurerm_storage_account.sftpstorage.id
  ssh_key_enabled      = false
  ssh_password_enabled = true
  home_directory       = "lovdatastats/upload"

  permission_scope {
    permissions {
      create = true
      write  = true
      list   = true
    }
    service       = "blob"
    resource_name = azurerm_storage_container.lovdatastats.name
  }
}

# This is Karnov's account. Used to ingest data form lovdata
# and product pubsub messages.
resource "azurerm_storage_account_local_user" "lovdataproducer" {
  name                 = "lovdataproducer2"
  storage_account_id   = azurerm_storage_account.sftpstorage.id
  ssh_key_enabled      = false
  ssh_password_enabled = true
  home_directory       = "lovdatastats"

  permission_scope {
    permissions {
      delete = true
      read   = true
      create = true
      list   = true
      write  = true
    }
    service       = "blob"
    resource_name = azurerm_storage_container.lovdatastats.name
  }
}

output "local_user_lovdata_password" {
  sensitive   = true
  description = "The generated password for `localUser/lovdata`"
  value       = azurerm_storage_account_local_user.lovdata.password
}

output "local_user_lovdataproducer_password" {
  sensitive   = true
  description = "The generated password for `localUser/lovdataproducer`"
  value       = azurerm_storage_account_local_user.lovdataproducer.password
}
