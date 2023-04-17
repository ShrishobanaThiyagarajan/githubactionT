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
  name                = "${var.service_name}-func-sp-${var.environment_name}-k"
  resource_group_name = var.func_resource_group_name
  location            = var.func_resource_group_location
  os_type             = "Windows"
  sku_name            = "Y1"
  tags = {
    environment = var.environment_name
  }
}

resource "azurerm_storage_account" "func_storage_account" {
  name                             = "storagefunc${lower(var.environment_name)}k"
  resource_group_name              = "data-${lower(var.environment_name)}-k"
  location                         = var.func_resource_group_location
  account_tier                     = "Standard"
  min_tls_version                  = "TLS1_0"
  cross_tenant_replication_enabled = false
  account_replication_type         = "LRS"
  timeouts {
  }
}

resource "azurerm_windows_function_app" "windows_func" {
  name                = var.service_name
  resource_group_name = var.func_resource_group_name
  location            = var.func_resource_group_location

  storage_account_name = azurerm_storage_account.func_storage_account.name
  storage_account_access_key = azurerm_storage_account.func_storage_account.primary_access_key
  service_plan_id = azurerm_service_plan.service_plan.id

  site_config {

  }

  tags = {
    environment = var.environment_name
  }
}
