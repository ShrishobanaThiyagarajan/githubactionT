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
  projs                            = var.funcs
  build_and_release_nuget          = var.build_and_release_nuget
  sln_path                         = var.sln_path
  sonarcloud_token                 = var.sonarcloud_token
  azure_credentials_test           = var.azure_credentials_test
  azure_credentials_prod           = var.azure_credentials_prod
  teams_incoming_webhooks_url_test = var.teams_incoming_webhooks_url_test
  teams_incoming_webhooks_url_prod = var.teams_incoming_webhooks_url_prod
}

resource "azurerm_service_plan" "service_plan" {
  count               = length(var.funcs)
  name                = "${var.funcs[count.index].service_name}-func-sp-${lower(var.environment_name)}-k"
  resource_group_name = "functions-${var.environment_name}-k"
  location            = data.azurerm_resource_group.func_resource_group.location
  os_type             = "Windows"
  sku_name            = var.service_plan_sku
  tags = {
    environment = var.environment_name
  }
}

data "azurerm_storage_account" "func_storage_account" {
  name                = "storagefunc${lower(var.environment_name)}k"
  resource_group_name = "data-${lower(var.environment_name)}-k"
}

data "azurerm_resource_group" "func_resource_group" {
  name = var.func_resource_group_name
}

resource "azurerm_windows_function_app" "windows_func" {
  lifecycle {
    ignore_changes = [
      app_settings,
      site_config,
      tags,
      sticky_settings,
      builtin_logging_enabled
    ]
  }

  count               = length(var.funcs)
  name                = "${var.funcs[count.index].service_name}-func-${lower(var.environment_name)}-k"
  resource_group_name = data.azurerm_resource_group.func_resource_group.name
  location            = data.azurerm_resource_group.func_resource_group.location

  storage_account_name       = data.azurerm_storage_account.func_storage_account.name
  storage_account_access_key = data.azurerm_storage_account.func_storage_account.primary_access_key
  service_plan_id            = azurerm_service_plan.service_plan[count.index].id

  site_config {}

  tags = {
    environment = var.environment_name
  }
}
