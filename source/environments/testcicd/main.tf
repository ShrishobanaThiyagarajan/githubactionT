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
      name = "infrastructure-testcicd"
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

resource "azurerm_key_vault_secret" "keyvault_BackofficeEndpoint" {
  key_vault_id = azurerm_key_vault.keyvault.id
  name         = "BackofficeEndpoint"
  value        = "https://backofficetest.karnovgroup.no"
}

resource "azurerm_key_vault_secret" "keyvault_MondayOutdatedNotesBoardId" {
  key_vault_id = azurerm_key_vault.keyvault.id
  name         = "MondayOutdatedNotesBoardId"
  value        = "3875956428"
}

data "azurerm_key_vault_secret" "kportalapp_sonarcloud_token" {
  name         = "KPortalSonarcloudToken"
  key_vault_id = azurerm_key_vault.keyvault.id
}

module "microservice_KPortalapp" {
  source                         = "../../modules/az-appservice"
  service_name                   = "KPortalapp"
  appservice_resource_group_name = "functions-${lower(var.environment_name)}-k"
  service_plan_sku               = "B1"
  # TODO: add SKU for service_plan
  environment_name = var.environment_name
  apps = [
    {
      service_name = "KPortalapp"
      proj_path    = "./source/KPortalapp.Web/KPortal.Web.csproj",
    }
  ]
  github_token                     = var.github_token
  provision_repository             = true
  sln_path                         = "./KPortalapp.sln"
  sonarcloud_token                 = data.azurerm_key_vault_secret.kportalapp_sonarcloud_token.value
  azure_credentials_test           = var.azure_credentials_test
  
}
