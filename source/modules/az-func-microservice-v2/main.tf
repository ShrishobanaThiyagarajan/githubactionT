terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=3.52.0"
    }

    github = {
      source  = "integrations/github"
      version = "~> 5.0"
    }
  }
}

provider "azurerm" {
  features {}
}

# Configure the GitHub Provider
provider "github" {
  token = var.github_token
  owner = "Karnov-Group-Norway"
}

resource "github_repository" "microservice_repository" {
  count                       = var.provision_repository ? 1 : 0
  name                        = var.service_name
  description                 = "Provisioned with kPlatform"
  visibility                  = "private"
  squash_merge_commit_message = "PR_BODY"
  squash_merge_commit_title   = "PR_TITLE"

  template {
    owner                = "Karnov-Group-Norway"
    repository           = "az-func-csharp-template"
    include_all_branches = false
  }
}

resource "github_repository_environment" "test" {
  count       = var.provision_repository ? 1 : 0
  environment = "test"
  repository  = github_repository.microservice_repository[0].name
}

resource "github_actions_environment_secret" "azure_credentials_test" {
  count           = var.provision_repository ? 1 : 0
  repository      = github_repository.microservice_repository[0].name
  environment     = github_repository_environment.test[0].environment
  secret_name     = "AZURE_CREDENTIALS"
  plaintext_value = var.azure_credentials_test
}

resource "github_repository_environment" "production" {
  count       = var.provision_repository ? 1 : 0
  environment = "production"
  repository  = github_repository.microservice_repository[0].name
}

resource "github_actions_environment_secret" "azure_credentials_production" {
  count           = var.provision_repository ? 1 : 0
  repository      = github_repository.microservice_repository[0].name
  environment     = github_repository_environment.production[0].environment
  secret_name     = "AZURE_CREDENTIALS"
  plaintext_value = var.azure_credentials_prod
}

resource "github_actions_secret" "sonar_token" {
  count           = var.provision_repository ? 1 : 0
  repository      = github_repository.microservice_repository[0].name
  secret_name     = "SONAR_TOKEN"
  plaintext_value = var.sonarcloud_token
}

resource "github_repository_file" "appsettings" {
  count               = var.provision_repository ? 1 : 0
  repository          = github_repository.microservice_repository[count.index].name
  branch              = "main"
  file                = "source/Func/appsettings.json"
  content             = templatefile("../../modules/az-func-microservice-v2/appsettings.tftpl", { service_name = var.service_name })
  commit_message      = "Managed by kPlatform"
  commit_author       = "kPlatform"
  commit_email        = "kplatform@karnovgroup.no"
  overwrite_on_create = true
}

resource "github_repository_file" "workflow_pr" {
  count      = var.provision_repository ? 1 : 0
  repository = github_repository.microservice_repository[count.index].name
  branch     = "main"
  file       = ".github/workflows/pr.yml"
  content = templatefile("../../modules/az-func-microservice-v2/workflow_pr.tftpl", {
    service_name = var.service_name,
    sln_path     = var.sln_path,
    func_path    = var.func_path
  })
  commit_message      = "Managed by kPlatform"
  commit_author       = "kPlatform"
  commit_email        = "terraform@karnovgroup.no"
  overwrite_on_create = true
}

resource "github_repository_file" "workflow_release" {
  count      = var.provision_repository ? 1 : 0
  repository = github_repository.microservice_repository[count.index].name
  branch     = "main"
  file       = ".github/workflows/release.yml"
  content = templatefile("../../modules/az-func-microservice-v2/workflow_release.tftpl", {
    service_name = var.service_name,
    sln_path     = var.sln_path,
    func_path    = var.func_path
  })
  commit_message      = "Managed by kPlatform"
  commit_author       = "kPlatform"
  commit_email        = "terraform@karnovgroup.no"
  overwrite_on_create = true
}

resource "github_repository_file" "workflow_deploy" {
  count               = var.provision_repository ? 1 : 0
  repository          = github_repository.microservice_repository[count.index].name
  branch              = "main"
  file                = ".github/workflows/deploy.yml"
  content             = templatefile("../../modules/az-func-microservice-v2/workflow_deploy.tftpl", { 
    service_name = var.service_name,
    func_path    = var.func_path
  })
  commit_message      = "Managed by kPlatform"
  commit_author       = "kPlatform"
  commit_email        = "terraform@karnovgroup.no"
  overwrite_on_create = true
}

resource "azurerm_service_plan" "service_plan" {
  name                = "${var.service_name}-func-sp-${lower(var.environment_name)}-k"
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

  name                = "${var.service_name}-func-${lower(var.environment_name)}-k"
  resource_group_name = data.azurerm_resource_group.func_resource_group.name
  location            = data.azurerm_resource_group.func_resource_group.location

  storage_account_name       = data.azurerm_storage_account.func_storage_account.name
  storage_account_access_key = data.azurerm_storage_account.func_storage_account.primary_access_key
  service_plan_id            = azurerm_service_plan.service_plan.id

  site_config {}

  tags = {
    environment = var.environment_name
  }
}
