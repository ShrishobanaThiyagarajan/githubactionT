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
      name = "infrastructure-prod"
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
  name                            = "kv-${lower(var.environment_name)}-k"
  location                        = azurerm_resource_group.resourcegroup.location
  resource_group_name             = azurerm_resource_group.resourcegroup.name
  enabled_for_template_deployment = true
  enabled_for_disk_encryption     = false
  tenant_id                       = data.azurerm_client_config.current.tenant_id
  soft_delete_retention_days      = 90
  purge_protection_enabled        = false

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
  value        = "https://backoffice.karnovgroup.no"
}

resource "azurerm_key_vault_secret" "keyvault_MondayOutdatedNotesBoardId" {
  key_vault_id = azurerm_key_vault.keyvault.id
  name         = "MondayOutdatedNotesBoardId"
  value        = "4080674685"
}

output "lovdata_statistics_sftp" {
  sensitive = true
  value     = module.lovdata-statistics-sftp-ingest
}

module "az_func_microservice_ContentReports" {
  source              = "../../modules/az-func-microservice"
  service_name        = "ContentReports"
  github_token        = var.github_token
  environment_name    = var.environment_name
  resource_group_name = azurerm_resource_group.resourcegroup.name
}

resource "azurerm_dashboard_grafana" "grafana" {
  name                              = "grafana-prod-k"
  resource_group_name               = azurerm_resource_group.resourcegroup.name
  location                          = "West Europe"
  api_key_enabled                   = false
  deterministic_outbound_ip_enabled = false
  public_network_access_enabled     = true

  identity {
    type = "SystemAssigned"
  }

  tags = {
    environment = var.environment_name
  }
}

module "microservice_kDashboardBff" {
  source                   = "../../modules/az-func-microservice-v2"
  service_name             = "kDashboardBff"
  func_resource_group_name = "functions-${lower(var.environment_name)}-k"
  environment_name         = var.environment_name
  funcs = [
    {
      service_name = "kDashboardBff",
      func_path    = "./source/KarnovN.kDashboardBff.Func/KarnovN.kDashboardBff.Func.csproj",
    }
  ]
}

module "UserEventKafkaWriter" {
  source                   = "../../modules/az-func-microservice-v2"
  service_name             = "UserEventKafkaWriter"
  func_resource_group_name = "functions-${lower(var.environment_name)}-k"
  environment_name         = var.environment_name
  funcs = [
    {
      service_name = "UserEventKafkaWriter",
      func_path    = "./source/KarnovN.UserEventKafkaWriter.Func/KarnovN.UserEventKafkaWriter.Func.csproj"
    }
  ]
}

module "DocumentPublishedKafkaWriter" {
  source                   = "../../modules/az-func-microservice-v2"
  service_name             = "DocumentPublishedKafkaWriter"
  func_resource_group_name = "functions-${lower(var.environment_name)}-k"
  environment_name         = var.environment_name
  funcs = [
    {
      service_name = "DocumentPublishedKafkaWriter",
      func_path    = "./source/KarnovN.DocumentPublishedKafkaWriter.Func/KarnovN.DocumentPublishedKafkaWriter.Func.csproj"
    }
  ]
}

module "microservice_Order" {
  source                   = "../../modules/az-func-microservice-v2"
  service_name             = "Order"
  func_resource_group_name = "functions-${lower(var.environment_name)}-k"
  environment_name         = var.environment_name
  funcs = [
    {
      service_name = "Order",
      func_path    = "./source/Order.Func/KarnovN.Order.Func.csproj"
    }
  ]
}

module "microservice_HubSpotIntegration" {
  source                   = "../../modules/az-func-microservice-v2"
  service_name             = "HubSpotIntegration"
  func_resource_group_name = "functions-${lower(var.environment_name)}-k"
  environment_name         = var.environment_name
  funcs = [
    {
      service_name = "HubSpotIntegration",
      func_path    = "./source/KarnovN.HubSpotIntegration.Func/KarnovN.HubSpotIntegration.Func.csproj"
    }
  ]
}

module "microservice_Alerter" {
  source                   = "../../modules/az-func-microservice-v2"
  service_name             = "Alerter"
  func_resource_group_name = "functions-${lower(var.environment_name)}-k"
  environment_name         = var.environment_name
  funcs = [
    {
      service_name = "Alerter",
      func_path    = "./source/KarnovN.Alerter.Func/KarnovN.Alerter.Func.csproj"
    }
  ]
}

module "microservice_DocumentLog" {
  source                   = "../../modules/az-func-microservice-v2"
  service_name             = "DocumentLog"
  func_resource_group_name = "functions-${lower(var.environment_name)}-k"
  environment_name         = var.environment_name
  funcs = [
    {
      service_name = "DocumentLog",
      func_path    = "./source/KarnovN.DocumentLog.Func/KarnovN.DocumentLog.Func.csproj"
    }
  ]
}

module "microservice_SalesInfo" {
  source                   = "../../modules/az-func-microservice-v2"
  service_name             = "SalesInfo"
  func_resource_group_name = "functions-${lower(var.environment_name)}-k"
  environment_name         = var.environment_name
  funcs = [
    {
      service_name = "SalesInfo",
      func_path    = "./source/KarnovN.SalesInfo.Func/KarnovN.SalesInfo.Func.csproj"
    }
  ]
}

module "microservice_MondayIntegration" {
  source                   = "../../modules/az-func-microservice-v2"
  service_name             = "MondayIntegration"
  func_resource_group_name = "functions-${lower(var.environment_name)}-k"
  environment_name         = var.environment_name
  funcs = [
    {
      service_name = "MondayIntegration",
      func_path    = "./source/KarnovN.MondayIntegration.Func/KarnovN.MondayIntegration.Func.csproj"
    }
  ]
}

module "microservice_UserEvents" {
  source                   = "../../modules/az-func-microservice-v2"
  service_name             = "UserEvents"
  func_resource_group_name = "functions-${lower(var.environment_name)}-k"
  environment_name         = var.environment_name
  funcs = [
    {
      service_name = "UserEvents",
      func_path    = "./source/KarnovN.UserEvents.Func/KarnovN.UserEvents.Func.csproj"
    }
  ]
}

module "microservice_User" {
  source                   = "../../modules/az-func-microservice-v2"
  service_name             = "User"
  func_resource_group_name = "functions-${lower(var.environment_name)}-k"
  environment_name         = var.environment_name
  funcs = [
    {
      service_name = "User",
      func_path    = "./source/KarnovN.User.Func/KarnovN.User.Func.csproj"
    },
    {
      service_name = "UserAdmin",
      func_path    = "./source/KarnovN.UserAdmin.Func/KarnovN.UserAdmin.Func.csproj"
    },
    {
      service_name = "UserProperties",
      func_path    = "./source/KarnovN.UserProperties.Func/KarnovN.UserProperties.Func.csproj"
    }
  ]
}
