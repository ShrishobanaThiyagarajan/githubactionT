terraform {
  required_providers {
    github = {
        source  = "integrations/github"
        version = "~> 5.0"
    }
  }
}

# Configure the GitHub Provider
provider "github" {
    token = var.github_token
    owner = "Karnov-Group-Norway"
}

# Going to move over from Azure DevOps
resource "github_repository" "microservice_repository_ContentReports" {
    name = "ContentReports"
    description = "ContentReports microservice"
    visibility = "private"
}
