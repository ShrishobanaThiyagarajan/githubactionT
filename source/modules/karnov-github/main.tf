terraform {
  required_providers {
    github = {
      source  = "integrations/github"
      version = "~> 5.40.0"
    }
  }
}

# Configure the GitHub Provider
#provider "github" {
#  token = var.github_token
#  owner = "Karnov-Group-Norway"
#}

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

resource "github_issue_label" "skip_code_analysis" {
  count       = var.provision_repository ? 1 : 0
  repository  = github_repository.microservice_repository[0].name
  name        = "skip-code-analysis"
  description = "Delivery pipelines / CI/CD will skip running code analysis"
  color       = "297907"
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

resource "github_actions_environment_secret" "teams_incoming_webhooks_url_test" {
  count           = var.provision_repository ? 1 : 0
  repository      = github_repository.microservice_repository[0].name
  environment     = github_repository_environment.test[0].environment
  secret_name     = "TEAMS_INCOMING_WEBHOOKS_URL"
  plaintext_value = var.teams_incoming_webhooks_url_test
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

resource "github_actions_environment_secret" "teams_incoming_webhooks_url_prod" {
  count           = var.provision_repository ? 1 : 0
  repository      = github_repository.microservice_repository[0].name
  environment     = github_repository_environment.production[0].environment
  secret_name     = "TEAMS_INCOMING_WEBHOOKS_URL"
  plaintext_value = var.teams_incoming_webhooks_url_prod
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
  count      = var.provision_repository ? length(var.projs) : 0
  repository = github_repository.microservice_repository[0].name
  branch     = "main"
  file       = ".github/workflows/pr-${var.projs[count.index].service_name}.yml"
  content = templatefile("../../modules/az-func-microservice-v2/workflow_pr.tftpl", {
    service_name            = var.projs[count.index].service_name,
    sln_path                = var.sln_path,
    func_path               = var.projs[count.index].proj_path,
    build_and_release_nuget = var.build_and_release_nuget,
    # Use first service name as the convention for the project name.
    # Assuming it represents the whole repository.
    sonarcloud_project = "Karnov-Group-Norway_${var.projs[0].service_name}",
    apptype            = var.projs[count.index].apptype
  })
  commit_message      = "Managed by kPlatform"
  commit_author       = "kPlatform"
  commit_email        = "terraform@karnovgroup.no"
  overwrite_on_create = true
}

resource "github_repository_file" "workflow_release" {
  count      = var.provision_repository ? length(var.projs) : 0
  repository = github_repository.microservice_repository[0].name
  branch     = "main"
  file       = ".github/workflows/release-${var.projs[count.index].service_name}.yml"
  content = templatefile("../../modules/az-func-microservice-v2/workflow_release.tftpl", {
    service_name            = var.projs[count.index].service_name,
    sln_path                = var.sln_path,
    func_path               = var.projs[count.index].proj_path,
    build_and_release_nuget = var.build_and_release_nuget,
    # Use first service name as the convention for the project name.
    # Assuming it represents the whole repository.
    sonarcloud_project = "Karnov-Group-Norway_${var.projs[0].service_name}"
  })
  commit_message      = "Managed by kPlatform"
  commit_author       = "kPlatform"
  commit_email        = "terraform@karnovgroup.no"
  overwrite_on_create = true
}

resource "github_repository_file" "workflow_deploy" {
  count      = var.provision_repository ? length(var.projs) : 0
  repository = github_repository.microservice_repository[0].name
  branch     = "main"
  file       = ".github/workflows/deploy-${var.projs[count.index].service_name}.yml"
  content = templatefile("../../modules/az-func-microservice-v2/workflow_deploy.tftpl", {
    service_name   = var.projs[count.index].service_name,
    func_path      = var.projs[count.index].proj_path
  })
  commit_message      = "Managed by kPlatform"
  commit_author       = "kPlatform"
  commit_email        = "terraform@karnovgroup.no"
  overwrite_on_create = true
}
