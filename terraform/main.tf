terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }
  required_version = ">= 0.14.9"
}

provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "rg" {
  name     = "myResourceGroup"
  location = "West Europe"
}

resource "azurerm_service_plan" "asp" {
  name                = "myServicePlan"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  os_type             = "Linux"  # Or "Windows"
  sku_name            = "F1"     # Example SKU for Free tier
}

resource "azurerm_linux_web_app" "app" {
  name                = "myHelloApiApp"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  service_plan_id     = azurerm_service_plan.asp.id

  site_config {
    # Ensure this line is removed or commented out:
    # always_on = true
  }

  app_settings = {
    "WEBSITE_RUN_FROM_PACKAGE" = "1"
  }
}

resource "azurerm_app_service_source_control" "sourcecontrol" {
  app_id                = azurerm_linux_web_app.app.id
  repo_url              = "https://github.com/ShrishobanaThiyagarajan/githubactionT.git"
  branch                = "main"
  use_manual_integration = true
}
