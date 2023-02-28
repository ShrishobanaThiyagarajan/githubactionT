terraform {
  required_providers {
    github = {
        source  = "integrations/github"
        version = "~> 5.0"
    }

    azurerm = {
        source  = "hashicorp/azurerm"
        version = "=3.40.0"
    }
  }
}

# Configure the GitHub Provider
provider "github" {
    token = var.github_token
    owner = "Karnov-Group-Norway"

}

resource "github_repository" "microservice_repository" {
    count = lower(var.environment_name) == "dev" ? 1 : 0
    name = var.service_name
    description = "goeran tester"
    visibility = "private"

    template {
        owner = "Karnov-Group-Norway"
        repository = "az-func-csharp-template"
        include_all_branches = false
  }
}

resource "github_repository_file" "appsettings" {
  count = lower(var.environment_name) == "dev" ? 1 : 0
  repository          = github_repository.microservice_repository[count.index].name
  branch              = "main"
  file                = "source/Func/appsettings.json"
  content             = templatefile("../../modules/az-func-microservice/appsettings.tftpl", { service_name = var.service_name })
  commit_message      = "Managed by Terraform"
  commit_author       = "Terraform User"
  commit_email        = "terraform@example.com"
  overwrite_on_create = true
}

provider "azurerm" {
  features {}
}

/*resource "azurerm_resource_group" "example" {
  name     = "goeran-test"
  location = "Norway East"
}

resource "azurerm_storage_account" "example" {
  name                     = "storagegoerantestfunc"
  resource_group_name      = azurerm_resource_group.example.name
  location                 = azurerm_resource_group.example.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

resource "azurerm_service_plan" "example" {
  name                = "goeran-test-func-service-plan"
  resource_group_name = azurerm_resource_group.example.name
  location            = azurerm_resource_group.example.location
  os_type             = "Linux"
  sku_name            = "Y1"
}

resource "azurerm_linux_function_app" "example" {
  name                = "goeran-test-func"
  resource_group_name = azurerm_resource_group.example.name
  location            = azurerm_resource_group.example.location

  storage_account_name       = azurerm_storage_account.example.name
  storage_account_access_key = azurerm_storage_account.example.primary_access_key
  #service_plan_id            = azurerm_service_plan.example.id
  service_plan_id = azurerm_service_plan.example.id

  site_config {}
}*/
