variable "service_name" {
  type = string
}

variable "environment_name" {
  type = string
}

variable "appservice_resource_group_name" {
  type = string
}

variable "service_plan_sku" {
  type = string
  # TODO: change
  default = "Y1"
}

variable "provision_repository" {
  type    = bool
  default = false
}

variable "sln_path" {
  type    = string
  default = ""
}

variable "apps" {
  type = list(object({
    service_name    = string
    appservice_path = string
  }))
  default = []
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

variable "github_token" {
  type    = string
  default = ""
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