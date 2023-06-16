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

module "lovdata-statistics-sftp-ingest" {
  source              = "../../modules/lovdata-statistics-sftp-ingest"
  resource_group_name = azurerm_resource_group.resourcegroup.name
  environment_name    = var.environment_name
}

resource "azurerm_key_vault_secret" "keyvault_SftpLovdataStatsHostname_secret" {
  key_vault_id = azurerm_key_vault.keyvault.id
  name         = "SftpLovdataStatsHostname"
  value        = module.lovdata-statistics-sftp-ingest.primary_blob_host
}

resource "azurerm_key_vault_secret" "keyvault_SftpLovdataStatsUsername_secret" {
  key_vault_id = azurerm_key_vault.keyvault.id
  name         = "SftpLovdataStatsUsername"
  value        = module.lovdata-statistics-sftp-ingest.local_user_lovdataproducer_name
}

resource "azurerm_key_vault_secret" "keyvault_SftpLovdataStatsPassword_secret" {
  key_vault_id = azurerm_key_vault.keyvault.id
  name         = "SftpLovdataStatsPassword"
  value        = module.lovdata-statistics-sftp-ingest.local_user_lovdataproducer_password
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

module "microservice_kDashboardBff" {
  source                   = "../../modules/az-func-microservice-v2"
  service_name             = "kDashboardBff"
  func_resource_group_name = "functions-${lower(var.environment_name)}-k"
  environment_name         = var.environment_name
}
module "UserEventKafkaWriter" {
  source                   = "../../modules/az-func-microservice-v2"
  service_name             = "UserEventKafkaWriter"
  func_resource_group_name = "functions-${lower(var.environment_name)}-k"
  environment_name         = var.environment_name
}
module "DocumentPublishedKafkaWriter" {
  source                   = "../../modules/az-func-microservice-v2"
  service_name             = "DocumentPublishedKafkaWriter"
  func_resource_group_name = "functions-${lower(var.environment_name)}-k"
  environment_name         = var.environment_name
}

data "azurerm_key_vault_secret" "order_sonarcloud_token" {
  name         = "OrderSonarcloudToken"
  key_vault_id = azurerm_key_vault.keyvault.id
}

data "azurerm_key_vault_secret" "order_func_publish_profile_test" {
  name         = "OrderPublishProfileTest"
  key_vault_id = azurerm_key_vault.keyvault.id
}

data "azurerm_key_vault_secret" "order_func_publish_profile_prod" {
  name         = "OrderPublishProfileProd"
  key_vault_id = azurerm_key_vault.keyvault.id
}

module "microservice_Order" {
  source                   = "../../modules/az-func-microservice-v2"
  service_name             = "Order"
  func_resource_group_name = "functions-${lower(var.environment_name)}-k"
  environment_name         = var.environment_name
  # provisiong github repo with environments and secrets
  github_token              = var.github_token
  provision_repository      = true
  sln_path                  = "./source/Order.sln"
  func_path                 = "./source/Order.Func/KarnovN.Order.Func.csproj.csproj"
  sonarcloud_token          = data.azurerm_key_vault_secret.order_sonarcloud_token.value
  func_publish_profile_test = data.azurerm_key_vault_secret.order_func_publish_profile_test.value
  func_publish_profile_prod = data.azurerm_key_vault_secret.order_func_publish_profile_prod.value
}

output "lovdata_statistics_sftp" {
  sensitive = true
  value     = module.lovdata-statistics-sftp-ingest
}
