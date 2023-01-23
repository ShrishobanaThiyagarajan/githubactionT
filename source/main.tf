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

/*resource "github_repository" "hello-world" {
    name = "hello-world"
    description = "goeran tester"
    visibility = "private"

    template {
        owner = "Karnov-Group-Norway"
        repository = "az-func-csharp-template"
        include_all_branches = false
  }
}*/
