terraform {
  required_providers {
    azurerm = {
        source  = "hashicorp/azurerm"
        version = "=3.40.0"
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

resource "azurerm_resource_group" "data-dev-k" {
  name     = "data-dev-k"
  location = "West Europe"
}

module "az-func-microservice" {
    source = "../../modules/az-func-microservice"
    service_name = "hello-world"
    github_token = var.github_token
}

module "lovdata-statistics-sftp-ingest" {
  source = "../../modules/lovdata-statistics-sftp-ingest"
  resource_group_name = azurerm_resource_group.data-dev-k.name
  environment_name = var.environment_name
}