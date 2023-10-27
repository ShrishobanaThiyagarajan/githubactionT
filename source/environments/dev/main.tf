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

data "azurerm_key_vault_secret" "kdashboardbff_sonarcloud_token" {
  name         = "kDashboardBffSonarcloudToken"
  key_vault_id = azurerm_key_vault.keyvault.id
}

module "microservice_kDashboardBff" {
  source       = "../../modules/az-func-microservice-v2"
  service_name = "kDashboardBff"
  funcs = [
    {
      service_name = "kDashboardBff",
      proj_path    = "./source/KarnovN.kDashboardBff.Func/KarnovN.kDashboardBff.Func.csproj",
    }
  ]
  func_resource_group_name         = "functions-${lower(var.environment_name)}-k"
  environment_name                 = var.environment_name
  github_token                     = var.github_token
  provision_repository             = true
  sln_path                         = "./kDashboard.sln"
  sonarcloud_token                 = data.azurerm_key_vault_secret.kdashboardbff_sonarcloud_token.value
  azure_credentials_test           = var.azure_credentials_test
  azure_credentials_prod           = var.azure_credentials_prod
  teams_incoming_webhooks_url_test = var.teams_incoming_webhooks_url_test
  teams_incoming_webhooks_url_prod = var.teams_incoming_webhooks_url_prod
  build_and_release_nuget          = false
}

module "UserEventKafkaWriter" {
  source       = "../../modules/az-func-microservice-v2"
  service_name = "UserEventKafkaWriter"
  funcs = [
    {
      service_name = "UserEventKafkaWriter",
      proj_path    = "./source/KarnovN.UserEventKafkaWriter.Func/KarnovN.UserEventKafkaWriter.Func.csproj"
    }
  ]
  func_resource_group_name = "functions-${lower(var.environment_name)}-k"
  environment_name         = var.environment_name
}

module "DocumentPublishedKafkaWriter" {
  source       = "../../modules/az-func-microservice-v2"
  service_name = "DocumentPublishedKafkaWriter"
  funcs = [
    {
      service_name = "DocumentPublishedKafkaWriter",
      proj_path    = "./source/KarnovN.DocumentPublishedKafkaWriter.Func/KarnovN.DocumentPublishedKafkaWriter.Func.csproj"
    }
  ]
  func_resource_group_name = "functions-${lower(var.environment_name)}-k"
  environment_name         = var.environment_name
}

data "azurerm_key_vault_secret" "order_sonarcloud_token" {
  name         = "OrderSonarcloudToken"
  key_vault_id = azurerm_key_vault.keyvault.id
}


data "azurerm_key_vault_secret" "hubspotintegration_sonarcloud_token" {
  name         = "HubSpotIntegrationSonarcloudToken"
  key_vault_id = azurerm_key_vault.keyvault.id
}

module "microservice_Order" {
  source       = "../../modules/az-func-microservice-v2"
  service_name = "Order"
  funcs = [
    {
      service_name = "Order",
      proj_path    = "./source/Order.Func/KarnovN.Order.Func.csproj"
    }
  ]
  func_resource_group_name = "functions-${lower(var.environment_name)}-k"
  environment_name         = var.environment_name
  # provisiong github repo with environments and secrets
  github_token                     = var.github_token
  provision_repository             = true
  sln_path                         = "./Order.sln"
  sonarcloud_token                 = data.azurerm_key_vault_secret.order_sonarcloud_token.value
  azure_credentials_test           = var.azure_credentials_test
  azure_credentials_prod           = var.azure_credentials_prod
  teams_incoming_webhooks_url_test = var.teams_incoming_webhooks_url_test
  teams_incoming_webhooks_url_prod = var.teams_incoming_webhooks_url_prod
}

module "microservice_HubSpotIntegration" {
  source       = "../../modules/az-func-microservice-v2"
  service_name = "HubSpotIntegration"
  funcs = [
    {
      service_name = "HubSpotIntegration",
      proj_path    = "./source/KarnovN.HubSpotIntegration.Func/KarnovN.HubSpotIntegration.Func.csproj"
    }
  ]
  func_resource_group_name         = "functions-${lower(var.environment_name)}-k"
  environment_name                 = var.environment_name
  github_token                     = var.github_token
  provision_repository             = true
  sln_path                         = "./HubSpotIntegration.sln"
  build_and_release_nuget          = false
  sonarcloud_token                 = data.azurerm_key_vault_secret.hubspotintegration_sonarcloud_token.value
  azure_credentials_test           = var.azure_credentials_test
  azure_credentials_prod           = var.azure_credentials_prod
  teams_incoming_webhooks_url_test = var.teams_incoming_webhooks_url_test
  teams_incoming_webhooks_url_prod = var.teams_incoming_webhooks_url_prod
}

data "azurerm_key_vault_secret" "alerter_sonarcloud_token" {
  name         = "AlerterSonarcloudToken"
  key_vault_id = azurerm_key_vault.keyvault.id
}

module "microservice_Alerter" {
  source       = "../../modules/az-func-microservice-v2"
  service_name = "Alerter"
  funcs = [
    {
      service_name = "Alerter",
      proj_path    = "./source/KarnovN.Alerter.Func/KarnovN.Alerter.Func.csproj"
    }
  ]
  func_resource_group_name         = "functions-${lower(var.environment_name)}-k"
  environment_name                 = var.environment_name
  github_token                     = var.github_token
  provision_repository             = true
  sln_path                         = "./Alerter.sln"
  sonarcloud_token                 = data.azurerm_key_vault_secret.alerter_sonarcloud_token.value
  azure_credentials_test           = var.azure_credentials_test
  azure_credentials_prod           = var.azure_credentials_prod
  teams_incoming_webhooks_url_test = var.teams_incoming_webhooks_url_test
  teams_incoming_webhooks_url_prod = var.teams_incoming_webhooks_url_prod
}

data "azurerm_key_vault_secret" "documentlog_sonarcloud_token" {
  name         = "DocumentLogSonarcloudToken"
  key_vault_id = azurerm_key_vault.keyvault.id
}

module "microservice_DocumentLog" {
  source       = "../../modules/az-func-microservice-v2"
  service_name = "DocumentLog"
  funcs = [
    {
      service_name = "DocumentLog",
      proj_path    = "./source/KarnovN.DocumentLog.Func/KarnovN.DocumentLog.Func.csproj"
    }
  ]
  func_resource_group_name         = "functions-${lower(var.environment_name)}-k"
  environment_name                 = var.environment_name
  github_token                     = var.github_token
  provision_repository             = true
  sln_path                         = "./DocumentLog.sln"
  build_and_release_nuget          = false
  sonarcloud_token                 = data.azurerm_key_vault_secret.documentlog_sonarcloud_token.value
  azure_credentials_test           = var.azure_credentials_test
  azure_credentials_prod           = var.azure_credentials_prod
  teams_incoming_webhooks_url_test = var.teams_incoming_webhooks_url_test
  teams_incoming_webhooks_url_prod = var.teams_incoming_webhooks_url_prod
}

data "azurerm_key_vault_secret" "salesinfo_sonarcloud_token" {
  name         = "SalesInfoSonarcloudToken"
  key_vault_id = azurerm_key_vault.keyvault.id
}

module "microservice_SalesInfo" {
  source       = "../../modules/az-func-microservice-v2"
  service_name = "SalesInfo"
  funcs = [
    {
      service_name = "SalesInfo",
      proj_path    = "./source/KarnovN.SalesInfo.Func/KarnovN.SalesInfo.Func.csproj"
    }
  ]
  func_resource_group_name         = "functions-${lower(var.environment_name)}-k"
  environment_name                 = var.environment_name
  github_token                     = var.github_token
  provision_repository             = true
  sln_path                         = "./SalesInfo.sln"
  sonarcloud_token                 = data.azurerm_key_vault_secret.salesinfo_sonarcloud_token.value
  azure_credentials_test           = var.azure_credentials_test
  azure_credentials_prod           = var.azure_credentials_prod
  teams_incoming_webhooks_url_test = var.teams_incoming_webhooks_url_test
  teams_incoming_webhooks_url_prod = var.teams_incoming_webhooks_url_prod
}

data "azurerm_key_vault_secret" "mondayintegration_sonarcloud_token" {
  name         = "MondayIntegrationSonarcloudToken"
  key_vault_id = azurerm_key_vault.keyvault.id
}

module "microservice_MondayIntegration" {
  source       = "../../modules/az-func-microservice-v2"
  service_name = "MondayIntegration"
  funcs = [
    {
      service_name = "MondayIntegration",
      proj_path    = "./source/KarnovN.MondayIntegration.Func/KarnovN.MondayIntegration.Func.csproj"
    }
  ]
  func_resource_group_name         = "functions-${lower(var.environment_name)}-k"
  environment_name                 = var.environment_name
  github_token                     = var.github_token
  provision_repository             = true
  sln_path                         = "./MondayIntegration.sln"
  sonarcloud_token                 = data.azurerm_key_vault_secret.mondayintegration_sonarcloud_token.value
  azure_credentials_test           = var.azure_credentials_test
  azure_credentials_prod           = var.azure_credentials_prod
  teams_incoming_webhooks_url_test = var.teams_incoming_webhooks_url_test
  teams_incoming_webhooks_url_prod = var.teams_incoming_webhooks_url_prod
}

data "azurerm_key_vault_secret" "userevents_sonarcloud_token" {
  name         = "UserEventsSonarcloudToken"
  key_vault_id = azurerm_key_vault.keyvault.id
}

module "microservice_UserEvents" {
  source       = "../../modules/az-func-microservice-v2"
  service_name = "UserEvents"
  funcs = [
    {
      service_name = "UserEvents",
      proj_path    = "./source/KarnovN.UserEvents.Func/KarnovN.UserEvents.Func.csproj"
    }
  ]
  func_resource_group_name         = "functions-${lower(var.environment_name)}-k"
  environment_name                 = var.environment_name
  github_token                     = var.github_token
  provision_repository             = true
  sln_path                         = "./UserEvents.sln"
  sonarcloud_token                 = data.azurerm_key_vault_secret.userevents_sonarcloud_token.value
  azure_credentials_test           = var.azure_credentials_test
  azure_credentials_prod           = var.azure_credentials_prod
  teams_incoming_webhooks_url_test = var.teams_incoming_webhooks_url_test
  teams_incoming_webhooks_url_prod = var.teams_incoming_webhooks_url_prod
}

data "azurerm_key_vault_secret" "user_sonarcloud_token" {
  name         = "UserSonarcloudToken"
  key_vault_id = azurerm_key_vault.keyvault.id
}

module "microservice_User" {
  source       = "../../modules/az-func-microservice-v2"
  service_name = "User"
  funcs = [
    {
      service_name = "User",
      proj_path    = "./source/KarnovN.User.Func/KarnovN.User.Func.csproj"
    },
    {
      service_name = "UserAdmin",
      proj_path    = "./source/KarnovN.UserAdmin.Func/KarnovN.UserAdmin.Func.csproj"
    },
    {
      service_name = "UserProperties",
      proj_path    = "./source/KarnovN.UserProperties.Func/KarnovN.UserProperties.Func.csproj"
    }
  ]
  func_resource_group_name         = "functions-${lower(var.environment_name)}-k"
  environment_name                 = var.environment_name
  github_token                     = var.github_token
  provision_repository             = true
  sln_path                         = "./User.sln"
  sonarcloud_token                 = data.azurerm_key_vault_secret.userevents_sonarcloud_token.value
  azure_credentials_test           = var.azure_credentials_test
  azure_credentials_prod           = var.azure_credentials_prod
  teams_incoming_webhooks_url_test = var.teams_incoming_webhooks_url_test
  teams_incoming_webhooks_url_prod = var.teams_incoming_webhooks_url_prod
}

data "azurerm_key_vault_secret" "statistics_sonarcloud_token" {
  name         = "StatisticsSonarcloudToken"
  key_vault_id = azurerm_key_vault.keyvault.id
}

module "microservice_Statistics" {
  source       = "../../modules/az-func-microservice-v2"
  service_name = "Statistics"
  funcs = [
    {
      service_name = "Statistics",
      proj_path    = "./source/KarnovN.Statistics.Func/KarnovN.Statistics.Func.csproj"
    },
    {
      service_name = "StatisticsAggregate",
      proj_path    = "./source/KarnovN.Statistics.Aggregate.Func/KarnovN.Statistics.Aggregate.Func.csproj"
    },
    {
      service_name = "StatisticsLovdataProducer",
      proj_path    = "./source/KarnovN.StatisticsLovdataProducer.Func/KarnovN.StatisticsLovdataProducer.Func.csproj"
    }
  ]
  func_resource_group_name         = "functions-${lower(var.environment_name)}-k"
  environment_name                 = var.environment_name
  github_token                     = var.github_token
  provision_repository             = true
  sln_path                         = "./Statistics.sln"
  sonarcloud_token                 = data.azurerm_key_vault_secret.statistics_sonarcloud_token.value
  azure_credentials_test           = var.azure_credentials_test
  azure_credentials_prod           = var.azure_credentials_prod
  teams_incoming_webhooks_url_test = var.teams_incoming_webhooks_url_test
  teams_incoming_webhooks_url_prod = var.teams_incoming_webhooks_url_prod
}

data "azurerm_key_vault_secret" "lovdataimport_sonarcloud_token" {
  name         = "LovdataImportSonarcloudToken"
  key_vault_id = azurerm_key_vault.keyvault.id
}

module "microservice_LovdataImport" {
  source       = "../../modules/az-func-microservice-v2"
  service_name = "LovdataImport"
  funcs = [
    {
      service_name = "LovdataImport",
      proj_path    = "./source/KarnovN.LovdataImport.Func/KarnovN.LovdataImport.Func.csproj"
    }
  ]
  func_resource_group_name         = "functions-${lower(var.environment_name)}-k"
  environment_name                 = var.environment_name
  github_token                     = var.github_token
  provision_repository             = true
  sln_path                         = "./LovdataImport.sln"
  sonarcloud_token                 = data.azurerm_key_vault_secret.lovdataimport_sonarcloud_token.value
  azure_credentials_test           = var.azure_credentials_test
  azure_credentials_prod           = var.azure_credentials_prod
  teams_incoming_webhooks_url_test = var.teams_incoming_webhooks_url_test
  teams_incoming_webhooks_url_prod = var.teams_incoming_webhooks_url_prod
}

# TODO: using this as playground for appservice to learn how to automate this setup
module "microservice_AppServicePlayground" {
  source                         = "../../modules/az-appservice"
  service_name                   = "AppServicePlayground"
  appservice_resource_group_name = "functions-${lower(var.environment_name)}-k"
  service_plan_sku               = "B1"
  # TODO: add SKU for service_plan
  environment_name = var.environment_name
  apps = [
    {
      service_name   = "AppServicePlayground"
      proj_path      = "./source/AppServicePlayground.Web/AppServicePlayground.Web.csproj",
    }
  ]
  github_token                     = var.github_token
  provision_repository             = true
  sln_path                         = "./AppServicePlayground.sln"
  sonarcloud_token                 = data.azurerm_key_vault_secret.lovdataimport_sonarcloud_token.value
  azure_credentials_test           = var.azure_credentials_test
  azure_credentials_prod           = var.azure_credentials_prod
  teams_incoming_webhooks_url_test = var.teams_incoming_webhooks_url_test
  teams_incoming_webhooks_url_prod = var.teams_incoming_webhooks_url_prod
}

data "azurerm_key_vault_secret" "kportal_sonarcloud_token" {
  name         = "KPortalSonarcloudToken"
  key_vault_id = azurerm_key_vault.keyvault.id
}

module "microservice_KPortal" {
  source                         = "../../modules/az-appservice"
  service_name                   = "KPortal"
  appservice_resource_group_name = "functions-${lower(var.environment_name)}-k"
  service_plan_sku               = "B1"
  # TODO: add SKU for service_plan
  environment_name = var.environment_name
  apps = [
    {
      service_name   = "KPortal"
      proj_path      = "./source/KPortal.Web/KPortal.Web.csproj",
    }
  ]
  github_token                     = var.github_token
  provision_repository             = true
  sln_path                         = "./KPortal.sln"
  sonarcloud_token                 = data.azurerm_key_vault_secret.kportal_sonarcloud_token.value
  azure_credentials_test           = var.azure_credentials_test
  azure_credentials_prod           = var.azure_credentials_prod
  teams_incoming_webhooks_url_test = var.teams_incoming_webhooks_url_test
  teams_incoming_webhooks_url_prod = var.teams_incoming_webhooks_url_prod
}

data "azurerm_key_vault_secret" "contentreports_sonarcloud_token" {
  name         = "ContentReportsSonarcloudToken"
  key_vault_id = azurerm_key_vault.keyvault.id
}

module "microservice_ContentReports" {
  source       = "../../modules/az-func-microservice-v2"
  service_name = "ContentReports"
  funcs = [
    {
      service_name = "ContentReports",
      proj_path    = "./source/KarnovN.ContentReportsProducer.Func/KarnovN.ContentReports.func.csproj"
    }
  ]
  func_resource_group_name         = "functions-${lower(var.environment_name)}-k"
  environment_name                 = var.environment_name
  github_token                     = var.github_token
  provision_repository             = true
  sln_path                         = "./ContentReports.sln"
  sonarcloud_token                 = data.azurerm_key_vault_secret.contentreports_sonarcloud_token.value
  azure_credentials_test           = var.azure_credentials_test
  azure_credentials_prod           = var.azure_credentials_prod
  teams_incoming_webhooks_url_test = var.teams_incoming_webhooks_url_test
  teams_incoming_webhooks_url_prod = var.teams_incoming_webhooks_url_prod
}

data "azurerm_key_vault_secret" "invoicebasis_sonarcloud_token" {
  name         = "InvoiceBasisSonarcloudToken"
  key_vault_id = azurerm_key_vault.keyvault.id
}

module "microservice_InvoiceBasis" {
  source       = "../../modules/az-func-microservice-v2"
  service_name = "InvoiceBasis"
  funcs = [
    {
      service_name = "InvoiceBasis",
      proj_path    = "./source/KarnovN.InvoiceBasis.Func/KarnovN.InvoiceBasis.Func.csproj"
    }
  ]
  func_resource_group_name         = "functions-${lower(var.environment_name)}-k"
  environment_name                 = var.environment_name
  github_token                     = var.github_token
  provision_repository             = true
  sln_path                         = "./InvoiceBasis.sln"
  sonarcloud_token                 = data.azurerm_key_vault_secret.invoicebasis_sonarcloud_token.value
  azure_credentials_test           = var.azure_credentials_test
  azure_credentials_prod           = var.azure_credentials_prod
  teams_incoming_webhooks_url_test = var.teams_incoming_webhooks_url_test
  teams_incoming_webhooks_url_prod = var.teams_incoming_webhooks_url_prod
}

data "azurerm_key_vault_secret" "khealth_sonarcloud_token" {
  name         = "KHealthSonarcloudToken"
  key_vault_id = azurerm_key_vault.keyvault.id
}

module "microservice_KHealth" {
  source       = "../../modules/az-func-microservice-v2"
  service_name = "KHealth"
  funcs = [
    {
      service_name = "KHealth",
      proj_path    = "./source/KarnovN.KHealth.Func/KarnovN.KHealth.Func.csproj"
    }
  ]
  func_resource_group_name         = "functions-${lower(var.environment_name)}-k"
  environment_name                 = var.environment_name
  github_token                     = var.github_token
  provision_repository             = true
  sln_path                         = "./KHealth.sln"
  sonarcloud_token                 = data.azurerm_key_vault_secret.khealth_sonarcloud_token.value
  azure_credentials_test           = var.azure_credentials_test
  azure_credentials_prod           = var.azure_credentials_prod
  teams_incoming_webhooks_url_test = var.teams_incoming_webhooks_url_test
  teams_incoming_webhooks_url_prod = var.teams_incoming_webhooks_url_prod
  build_and_release_nuget          = false
}

data "azurerm_key_vault_secret" "legalfield_sonarcloud_token" {
  name         = "LegalFieldSonarcloudToken"
  key_vault_id = azurerm_key_vault.keyvault.id
}

module "microservice_LegalField" {
  source       = "../../modules/az-func-microservice-v2"
  service_name = "LegalField"
  funcs = [
    {
      service_name = "LegalField",
      proj_path    = "./source/KarnovN.LegalField.Func/KarnovN.LegalField.Func.csproj"
    }
  ]
  func_resource_group_name         = "functions-${lower(var.environment_name)}-k"
  environment_name                 = var.environment_name
  github_token                     = var.github_token
  provision_repository             = true
  sln_path                         = "./LegalField.sln"
  sonarcloud_token                 = data.azurerm_key_vault_secret.legalfield_sonarcloud_token.value
  azure_credentials_test           = var.azure_credentials_test
  azure_credentials_prod           = var.azure_credentials_prod
  teams_incoming_webhooks_url_test = var.teams_incoming_webhooks_url_test
  teams_incoming_webhooks_url_prod = var.teams_incoming_webhooks_url_prod
}

data "azurerm_key_vault_secret" "lovdatapublisher_sonarcloud_token" {
  name         = "LovdataPublisherSonarcloudToken"
  key_vault_id = azurerm_key_vault.keyvault.id
}

module "microservice_LovdataPublisher" {
  source       = "../../modules/az-func-microservice-v2"
  service_name = "LovdataPublisher"
  funcs = [
    {
      service_name = "LovdataPublisher",
      proj_path    = "./source/KarnovN.LovdataPublisher.Func/KarnovN.LovdataPublisher.Func.csproj"
    },
    {
      service_name = "LovdataPublisherSync",
      proj_path    = "./source/KarnovN.LovdataPublisherSync.Func/KarnovN.LovdataPublisherSync.Func.csproj"
    }
  ]
  func_resource_group_name         = "functions-${lower(var.environment_name)}-k"
  environment_name                 = var.environment_name
  github_token                     = var.github_token
  provision_repository             = true
  sln_path                         = "./LovdataPublisher.sln"
  sonarcloud_token                 = data.azurerm_key_vault_secret.lovdatapublisher_sonarcloud_token.value
  azure_credentials_test           = var.azure_credentials_test
  azure_credentials_prod           = var.azure_credentials_prod
  teams_incoming_webhooks_url_test = var.teams_incoming_webhooks_url_test
  teams_incoming_webhooks_url_prod = var.teams_incoming_webhooks_url_prod
}

data "azurerm_key_vault_secret" "masterdocument_sonarcloud_token" {
  name         = "MasterDocumentSonarcloudToken"
  key_vault_id = azurerm_key_vault.keyvault.id
}

module "microservice_MasterDocument" {
  source       = "../../modules/az-func-microservice-v2"
  service_name = "MasterDocument"
  funcs = [
    {
      service_name = "MasterDocument",
      proj_path    = "./source/KarnovN.MasterDocument.Func/KarnovN.MasterDocument.Func.csproj"
    },
    {
      service_name = "MasterDocumentInfo",
      proj_path    = "./source/KarnovN.MasterDocumentInfo.Func/KarnovN.MasterDocumentInfo.Func.csproj"
    }
  ]
  func_resource_group_name         = "functions-${lower(var.environment_name)}-k"
  environment_name                 = var.environment_name
  github_token                     = var.github_token
  provision_repository             = true
  sln_path                         = "./MasterDocument.sln"
  sonarcloud_token                 = data.azurerm_key_vault_secret.masterdocument_sonarcloud_token.value
  azure_credentials_test           = var.azure_credentials_test
  azure_credentials_prod           = var.azure_credentials_prod
  teams_incoming_webhooks_url_test = var.teams_incoming_webhooks_url_test
  teams_incoming_webhooks_url_prod = var.teams_incoming_webhooks_url_prod
}

data "azurerm_key_vault_secret" "metadata_sonarcloud_token" {
  name         = "MetadataSonarcloudToken"
  key_vault_id = azurerm_key_vault.keyvault.id
}

module "microservice_Metadata" {
  source       = "../../modules/az-func-microservice-v2"
  service_name = "Metadata"
  funcs = [
    {
      service_name = "Metadata",
      proj_path    = "./source/KarnovN.Metadata.Func/KarnovN.Metadata.Func.csproj"
    }
  ]
  func_resource_group_name         = "functions-${lower(var.environment_name)}-k"
  environment_name                 = var.environment_name
  github_token                     = var.github_token
  provision_repository             = true
  sln_path                         = "./Metadata.sln"
  sonarcloud_token                 = data.azurerm_key_vault_secret.metadata_sonarcloud_token.value
  azure_credentials_test           = var.azure_credentials_test
  azure_credentials_prod           = var.azure_credentials_prod
  teams_incoming_webhooks_url_test = var.teams_incoming_webhooks_url_test
  teams_incoming_webhooks_url_prod = var.teams_incoming_webhooks_url_prod
}

data "azurerm_key_vault_secret" "metadatasync_sonarcloud_token" {
  name         = "MetadataSyncSonarcloudToken"
  key_vault_id = azurerm_key_vault.keyvault.id
}

module "microservice_MetadataSync" {
  source       = "../../modules/az-func-microservice-v2"
  service_name = "MetadataSync"
  funcs = [
    {
      service_name = "MetadataSync",
      proj_path    = "./source/KarnovN.MetadataSync.Func/KarnovN.MetadataSync.Func.csproj"
    }
  ]
  func_resource_group_name         = "functions-${lower(var.environment_name)}-k"
  environment_name                 = var.environment_name
  github_token                     = var.github_token
  provision_repository             = true
  sln_path                         = "./MetadataSync.sln"
  sonarcloud_token                 = data.azurerm_key_vault_secret.metadata_sonarcloud_token.value
  azure_credentials_test           = var.azure_credentials_test
  azure_credentials_prod           = var.azure_credentials_prod
  teams_incoming_webhooks_url_test = var.teams_incoming_webhooks_url_test
  teams_incoming_webhooks_url_prod = var.teams_incoming_webhooks_url_prod
}

output "lovdata_statistics_sftp" {
  sensitive = true
  value     = module.lovdata-statistics-sftp-ingest
} 
