module "az-func-microservice" {
    source = "./modules/az-func-microservice"
    service_name = "hello-world"
    github_token = var.github_token
}

module "lovdata-statistics-sftp-ingest" {
  source = "./modules/lovdata-statistics-sftp-ingest"
}