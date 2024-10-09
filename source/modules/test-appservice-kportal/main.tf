terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=3.52.0"
    }
  }
}

provider "azurerm" {
  features {}
}

module "repository" {
  source                           = "../karnov-github"
  provision_repository             = var.provision_repository
  service_name                     = var.service_name
  github_token                     = var.github_token
  projs                            = var.apps
  build_and_release_nuget          = false
  sln_path                         = var.sln_path
  sonarcloud_token                 = var.sonarcloud_token
  azure_credentials_test           = var.azure_credentials_test
  azure_credentials_prod           = var.azure_credentials_prod
  teams_incoming_webhooks_url_test = var.teams_incoming_webhooks_url_test
  teams_incoming_webhooks_url_prod = var.teams_incoming_webhooks_url_prod
}

data "azurerm_resource_group" "appservice_resource_group" {
  name = var.appservice_resource_group_name
}

resource "azurerm_service_plan" "service_plan" {
  count                  = length(var.apps)
  name                   = var.appservice_serviceplan_name != "" ? var.appservice_serviceplan_name : "${lower(var.service_name)}-sp-${lower(var.environment)}-k"
  resource_group_name    = data.azurerm_resource_group.appservice_resource_group.name
  location               = data.azurerm_resource_group.appservice_resource_group.location
  os_type                = "Windows"
  sku_name               = var.service_plan_sku
  zone_balancing_enabled = false
  worker_count           = 1

  tags = {
    environment = var.environment
  }
}

resource "azurerm_windows_web_app" "windows_appservice" {
  lifecycle {
    ignore_changes = [
      logs,
    ]
  }

  count               = length(var.apps)
  name                = var.appservice_name != "" ? var.appservice_name : "${lower(var.service_name)}-${lower(var.environment)}-k"
  resource_group_name = data.azurerm_resource_group.appservice_resource_group.name
  location            = data.azurerm_resource_group.appservice_resource_group.location
  service_plan_id     = azurerm_service_plan.service_plan[count.index].id

  site_config {
    always_on                 = true
    dotnet_framework_version  = "v6.0" # Adjust based on your .NET version
    scm_type                  = "LocalGit" # If you plan to use Git for deployment
  }

  app_settings = {
    "WEBSITE_RUN_FROM_PACKAGE" = "1"
    "ASPNETCORE_ENVIRONMENT"   = var.environment
    "KPORTAL_BFF_URL"          = var.bff_url # Define this in variables.tf
    # Add other necessary app settings here
  }

  identity {
    type = "SystemAssigned"
  }

  tags = {
    environment = var.environment
  }
}
