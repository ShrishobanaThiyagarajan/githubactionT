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
      proj_path    = "./source/KarnovN.kDashboardBff.Func/KarnovN.kDashboardBff.Func.csproj",
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
      proj_path    = "./source/KarnovN.UserEventKafkaWriter.Func/KarnovN.UserEventKafkaWriter.Func.csproj"
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
      proj_path    = "./source/KarnovN.DocumentPublishedKafkaWriter.Func/KarnovN.DocumentPublishedKafkaWriter.Func.csproj"
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
      proj_path    = "./source/Order.Func/KarnovN.Order.Func.csproj"
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
      proj_path    = "./source/KarnovN.HubSpotIntegration.Func/KarnovN.HubSpotIntegration.Func.csproj"
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
      proj_path    = "./source/KarnovN.Alerter.Func/KarnovN.Alerter.Func.csproj"
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
      proj_path    = "./source/KarnovN.DocumentLog.Func/KarnovN.DocumentLog.Func.csproj"
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
      proj_path    = "./source/KarnovN.SalesInfo.Func/KarnovN.SalesInfo.Func.csproj"
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
      proj_path    = "./source/KarnovN.MondayIntegration.Func/KarnovN.MondayIntegration.Func.csproj"
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
      proj_path    = "./source/KarnovN.UserEvents.Func/KarnovN.UserEvents.Func.csproj"
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
}

module "microservice_Statistics" {
  source                   = "../../modules/az-func-microservice-v2"
  service_name             = "Statistics"
  func_resource_group_name = "functions-${lower(var.environment_name)}-k"
  environment_name         = var.environment_name
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
}

module "microservice_LovdataImport" {
  source                   = "../../modules/az-func-microservice-v2"
  service_name             = "LovdataImport"
  func_resource_group_name = "functions-${lower(var.environment_name)}-k"
  environment_name         = var.environment_name
  funcs = [
    {
      service_name = "LovdataImport",
      proj_path    = "./source/KarnovN.LovdataImport.Func/KarnovN.LovdataImport.Func.csproj"
    }
  ]
}

module "microservice_KPortal" {
  source                         = "../../modules/az-appservice"
  service_name                   = "KPortal"
  appservice_resource_group_name = "functions-${lower(var.environment_name)}-k"
  service_plan_sku               = "P1v2"
  environment_name               = var.environment_name
  apps = [
    {
      service_name = "KPortal"
      proj_path    = "./source/KPortal.Web/KPortal.Web.csproj",
    }
  ]
}

module "microservice_ContentReports" {
  source                   = "../../modules/az-func-microservice-v2"
  service_name             = "ContentReports"
  func_resource_group_name = "functions-${lower(var.environment_name)}-k"
  environment_name         = var.environment_name
  service_plan_sku                 = "EP1"
  funcs = [
    {
      service_name = "ContentReports",
      proj_path    = "./source/KarnovN.ContentReportsProducer.Func/KarnovN.ContentReports.func.csproj"
    }
  ]
}
module "az_func_microservice_ContentReports" {
  source              = "../../modules/az-func-microservice"
  service_name        = "ContentReports"
  github_token        = var.github_token
  environment_name    = var.environment_name
  resource_group_name = azurerm_resource_group.resourcegroup.name
}

module "microservice_AuthorContract" {
  source                   = "../../modules/az-func-microservice-v2"
  service_name             = "AuthorContract"
  func_resource_group_name = "functions-${lower(var.environment_name)}-k"
  environment_name         = var.environment_name
  funcs = [
    {
      service_name = "AuthorContract",
      proj_path    = "./source/KarnovN.AuthorContract.Func/KarnovN.AuthorContract.func.csproj"
    }
  ]
}
module "az_func_microservice_AuthorContract" {
  source              = "../../modules/az-func-microservice"
  service_name        = "AuthorContract"
  github_token        = var.github_token
  environment_name    = var.environment_name
  resource_group_name = azurerm_resource_group.resourcegroup.name
}

module "microservice_InvoiceBasis" {
  source                   = "../../modules/az-func-microservice-v2"
  service_name             = "InvoiceBasis"
  func_resource_group_name = "functions-${lower(var.environment_name)}-k"
  environment_name         = var.environment_name
  funcs = [
    {
      service_name = "InvoiceBasis",
      proj_path    = "./source/KarnovN.InvoiceBasis.Func/KarnovN.InvoiceBasis.Func.csproj"
    }
  ]
}

module "microservice_KHealth" {
  source                   = "../../modules/az-func-microservice-v2"
  service_name             = "KHealth"
  func_resource_group_name = "functions-${lower(var.environment_name)}-k"
  environment_name         = var.environment_name
  funcs = [
    {
      service_name = "KHealth",
      proj_path    = "./source/KarnovN.KHealth.Func/KarnovN.KHealth.Func.csproj"
    }
  ]
}

module "microservice_LegalField" {
  source                   = "../../modules/az-func-microservice-v2"
  service_name             = "LegalField"
  func_resource_group_name = "functions-${lower(var.environment_name)}-k"
  environment_name         = var.environment_name
  funcs = [
    {
      service_name = "LegalField",
      proj_path    = "./source/KarnovN.LegalField.Func/KarnovN.LegalField.Func.csproj"
    }
  ]
}

module "microservice_LovdataPublisher" {
  source                   = "../../modules/az-func-microservice-v2"
  service_name             = "LovdataPublisher"
  func_resource_group_name = "functions-${lower(var.environment_name)}-k"
  environment_name         = var.environment_name
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
}

module "microservice_MasterDocument" {
  source                   = "../../modules/az-func-microservice-v2"
  service_name             = "MasterDocument"
  func_resource_group_name = "functions-${lower(var.environment_name)}-k"
  environment_name         = var.environment_name
  service_plan_sku                 = "EP1"
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
}

module "microservice_Metadata" {
  source                   = "../../modules/az-func-microservice-v2"
  service_name             = "Metadata"
  func_resource_group_name = "functions-${lower(var.environment_name)}-k"
  environment_name         = var.environment_name
  funcs = [
    {
      service_name = "Metadata",
      proj_path    = "./source/KarnovN.Metadata.Func/KarnovN.Metadata.Func.csproj"
    },
      {
      service_name = "MetadataWriter",
      proj_path    = "./source/KarnovN.MetadataWriter.Func/KarnovN.MetadataWriter.Func.csproj"
    }
  ]
}

module "microservice_MetadataSync" {
  source                   = "../../modules/az-func-microservice-v2"
  service_name             = "MetadataSync"
  func_resource_group_name = "functions-${lower(var.environment_name)}-k"
  environment_name         = var.environment_name
  funcs = [
    {
      service_name = "MetadataSync",
      proj_path    = "./source/KarnovN.MetadataSync.Func/KarnovN.MetadataSync.Func.csproj"
    }
  ]
}

module "microservice_WorkItem" {
  source                   = "../../modules/az-func-microservice-v2"
  service_name             = "WorkItem"
  func_resource_group_name = "functions-${lower(var.environment_name)}-k"
  environment_name         = var.environment_name
  funcs = [
    {
      service_name = "WorkItem",
      proj_path    = "./source/KarnovN.WorkItem.Func/KarnovN.WorkItem.Func.csproj"
    },
    {
      service_name = "WorkItemPublish",
      proj_path    = "./source/KarnovN.WorkItemPublish.Func/KarnovN.WorkItemPublish.Func.csproj"
    },
    {
      service_name = "WorkItemTools",
      proj_path    = "./source/KarnovN.WorkItemTools.Func/KarnovN.WorkItemTools.Func.csproj"
    }
  ]
}

module "microservice_WorkItemNotification" {
  source                   = "../../modules/az-func-microservice-v2"
  service_name             = "WorkItemNotification"
  func_resource_group_name = "functions-${lower(var.environment_name)}-k"
  environment_name         = var.environment_name
  funcs = [
    {
      service_name = "WorkItemNotification",
      proj_path    = "./source/KarnovN.WorkItemNotification.Func/KarnovN.WorkItemNotification.Func.csproj"
    }
  ]
}

module "microservice_WorkItemSharing" {
  source                   = "../../modules/az-func-microservice-v2"
  service_name             = "WorkItemSharing"
  func_resource_group_name = "functions-${lower(var.environment_name)}-k"
  environment_name         = var.environment_name
  funcs = [
    {
      service_name = "WorkItemSharing",
      proj_path    = "./source/KarnovN.WorkItemSharing.Func/KarnovN.WorkItemSharing.Func.csproj"
    }
  ]
}

module "microservice_Linker" {
  source                   = "../../modules/az-func-microservice-v2"
  service_name             = "Linker"
  func_resource_group_name = "functions-${lower(var.environment_name)}-k"
  environment_name         = var.environment_name
  funcs = [
    {
      service_name = "Linker",
      proj_path    = "./source/KarnovN.Linker.Func/KarnovN.Linker.Func.csproj"
    },
    {
      service_name = "LinkerFeed",
      proj_path    = "./source/KarnovN.Linker.Feed.Func/KarnovN.Linker.Feed.Func.csproj"
    }
  ]
}

module "microservice_Notification" {
  source                   = "../../modules/az-func-microservice-v2"
  service_name             = "Notification"
  func_resource_group_name = "functions-${lower(var.environment_name)}-k"
  environment_name         = var.environment_name
  funcs = [
    {
      service_name = "Notification",
      proj_path    = "./source/KarnovN.Notification.Func/KarnovN.Notification.Func.csproj"
    }
  ]
}

module "microservice_Templates" {
  source                   = "../../modules/az-func-microservice-v2"
  service_name             = "Templates"
  func_resource_group_name = "functions-${lower(var.environment_name)}-k"
  environment_name         = var.environment_name
  funcs = [
    {
      service_name = "Templates",
      proj_path    = "./source/KarnovN.Templates.Func/KarnovN.Templates.Func.csproj"
    }
  ]
}

module "microservice_Publisher" {
  source                   = "../../modules/az-func-microservice-v2"
  service_name             = "Publisher"
  func_resource_group_name = "functions-${lower(var.environment_name)}-k"
  environment_name         = var.environment_name
  funcs = [
    {
      service_name = "Publisher",
      proj_path    = "./source/KarnovN.Publisher.Func/KarnovN.Publisher.Func.csproj"
    }
  ]
}

module "microservice_PublishingInfo" {
  source                   = "../../modules/az-func-microservice-v2"
  service_name             = "PublishingInfo"
  func_resource_group_name = "functions-${lower(var.environment_name)}-k"
  environment_name         = var.environment_name
  funcs = [
    {
      service_name = "PublishingInfo",
      proj_path    = "./source/KarnovN.PublishingInfo.Func/KarnovN.PublishingInfo.Func.csproj"
    }
  ]
}

module "microservice_NoteId" {
  source                   = "../../modules/az-func-microservice-v2"
  service_name             = "NoteId"
  func_resource_group_name = "functions-${lower(var.environment_name)}-k"
  environment_name         = var.environment_name
  funcs = [
    {
      service_name = "NoteId",
      proj_path    = "./source/KarnovN.NoteId.Func/KarnovN.NoteId.Func.csproj"
    }
  ]
}
module "microservice_LLMIntegration" {
  source       = "../../modules/az-func-microservice-v2"
  service_name = "LLMIntegration"
  funcs = [
    {
      service_name = "LLMIntegration",
      proj_path    = "./source/LLMIntegration.Func/LLMIntegration.Func.csproj"
    }
  ]
  func_resource_group_name         = "functions-${lower(var.environment_name)}-k"
  environment_name                 = var.environment_name

}
module "microservice_WorkItemContentTools" {
  source       = "../../modules/az-func-microservice-v2"
  service_name = "WorkItemContentTools"
  funcs = [
    {
      service_name = "WorkItemContentTools",
      proj_path    = "./source/WorkItemContentTools.Func/WorkItemContentTools.Func.csproj"
    }
  ]
  func_resource_group_name         = "functions-${lower(var.environment_name)}-k"
  environment_name                 = var.environment_name
}