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
  funcs                            = var.apps
  build_and_release_nuget          = false
  sln_path                         = var.sln_path
  sonarcloud_token                 = var.sonarcloud_token
  azure_credentials_test           = var.azure_credentials_test
  azure_credentials_prod           = var.azure_credentials_prod
  teams_incoming_webhooks_url_test = var.teams_incoming_webhooks_url_test
  teams_incoming_webhooks_url_prod = var.teams_incoming_webhooks_url_prod
}

#data "azurerm_resource_group" "appservice_resource_group" {
#  name = var.appservice_resource_group_name
#}

#resource "azurerm_service_plan" "service_plan" {
#  count               = length(var.apps)
#  name                = "${var.apps[count.index].service_name}-func-sp-${lower(var.environment_name)}-k"
#  resource_group_name = "functions-${var.environment_name}-k"
#  location            = data.azurerm_resource_group.appservice_resource_group.location
#  os_type             = "Windows"
#  sku_name            = var.service_plan_sku
#  tags = {
#    environment = var.environment_name
#  }
#}
