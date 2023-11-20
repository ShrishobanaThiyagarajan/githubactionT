
module "repository" {
  source               = "../karnov-github"
  provision_repository = var.provision_repository
  service_name         = var.service_name
  github_token         = var.github_token
  projs = [{
    service_name = var.service_name,
    proj_path    = "",
    apptype      = "none"
  }]
  build_and_release_nuget = true
  sln_path                = var.sln_path
  sonarcloud_token        = var.sonarcloud_token
  #azure_credentials_test           = var.azure_credentials_test
  #azure_credentials_prod           = var.azure_credentials_prod
  teams_incoming_webhooks_url_test = var.teams_incoming_webhooks_url_test
  teams_incoming_webhooks_url_prod = var.teams_incoming_webhooks_url_prod
}
