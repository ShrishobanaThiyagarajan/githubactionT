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
      name = "infrastructure-dev"
    }
  }
}

provider "azurerm" {
  features {}
}

data "azurerm_client_config" "current" {}

resource "azurerm_resource_group" "resourcegroup" {
  name     = "data-${lower(var.environment_name)}-k"
  location = "West Europe"
}

resource "azurerm_key_vault" "keyvault" {
  name                        = "kv-${lower(var.environment_name)}-k"
  location                    = azurerm_resource_group.resourcegroup.location
  resource_group_name         = azurerm_resource_group.resourcegroup.name
  enabled_for_disk_encryption = false
  tenant_id                   = data.azurerm_client_config.current.tenant_id
  soft_delete_retention_days  = 90
  purge_protection_enabled    = false

  sku_name = "standard"
}

#module "az-func-microservice" {
#    source = "../../modules/az-func-microservice"
#    service_name = "hello-world"
#    github_token = var.github_token
#}

module "lovdata-statistics-sftp-ingest" {
  source              = "../../modules/lovdata-statistics-sftp-ingest"
  resource_group_name = azurerm_resource_group.resourcegroup.name
  environment_name    = var.environment_name
}

output "lovdata_statistics" {
    sensitive = true
    value = module.lovdata-statistics-sftp-ingest
}

output "lovdata_statistics_primary_connection_string" {
  sensitive = true
  value = module.lovdata-statistics-sftp-ingest.primary_connection_string
}

output "lovdata_statistics_local_user_lovdata_name" {
  value = module.lovdata-statistics-sftp-ingest.local_user_lovdata_name
}

output "lovdata_statistics_local_user_lovdata_password" {
  sensitive = true
  value = module.lovdata-statistics-sftp-ingest.local_user_lovdata_password
}

output "lovdata_statistics_local_user_lovdataproducer_name" {
  value = module.lovdata-statistics-sftp-ingest.local_user_lovdataproducer_name
}

output "lovdata_statistics_local_user_lovdataproducer_password" {
  sensitive = true
  value = module.lovdata-statistics-sftp-ingest.local_user_lovdataproducer_password
}
