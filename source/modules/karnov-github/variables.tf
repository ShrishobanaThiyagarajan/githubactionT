variable "service_name" {
  type = string
}

variable "github_token" {
  type = string
  #sensitive = true
}

variable "provision_repository" {
  type = bool
}

variable "funcs" {
  type = list(object({
    service_name       = string
    func_path          = string
  }))
  default = []
}

variable "build_and_release_nuget" {
  type    = bool
  default = true
}

variable "sln_path" {
  type    = string
  default = ""
}

variable "sonarcloud_token" {
  type      = string
  default   = ""
  sensitive = true
}

variable "azure_credentials_test" {
  type      = string
  default   = ""
  sensitive = true
}

variable "azure_credentials_prod" {
  type      = string
  default   = ""
  sensitive = true
}

variable "teams_incoming_webhooks_url_test" {
  type      = string
  default   = ""
  sensitive = true
}

variable "teams_incoming_webhooks_url_prod" {
  type      = string
  default   = ""
  sensitive = true
}
