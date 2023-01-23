module "az-func-microservice" {
    source = "./modules/az-func-microservice"
    service_name = "hello-world"
    github_token = var.github_token
}
