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

resource "azurerm_service_plan" "service_plan" {
  name                = "${var.service_name}-func-sp-${lower(var.environment_name)}-k"
  resource_group_name = "functions-${var.environment_name}-k"
  location            = data.azurerm_resource_group.func_resource_group.location
  os_type             = "Windows"
  sku_name            = "Y1"
  tags = {
    environment = var.environment_name
  }
}

data "azurerm_storage_account" "func_storage_account" {
  name                             = "storagefunc${lower(var.environment_name)}k"
  resource_group_name              = "data-${lower(var.environment_name)}-k"
}

data "azurerm_resource_group" "func_resource_group" {
  name = var.func_resource_group_name
}

resource "azurerm_windows_function_app" "windows_func" {
  lifecycle {
     ignore_changes = [
       app_settings,
       #site_config,
     ]
   }

  name                = "${var.service_name}-func-${lower(var.environment_name)}-k"
  resource_group_name = data.azurerm_resource_group.func_resource_group.name
  location            = data.azurerm_resource_group.func_resource_group.location

  storage_account_name = data.azurerm_storage_account.func_storage_account.name
  storage_account_access_key = data.azurerm_storage_account.func_storage_account.primary_access_key
  service_plan_id = azurerm_service_plan.service_plan.id

  site_config {}

  tags = {
    environment = var.environment_name
  }
}
