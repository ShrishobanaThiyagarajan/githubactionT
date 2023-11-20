variable "service_name" {
  type = string
}

variable "provision_repository" {
  type    = bool
  default = false
}

variable "sln_path" {
  type    = string
  default = ""
}

variable "projs" {
  type = list(object({
    service_name   = string
    proj_path      = string
  }))
  default = []
}

variable "github_token" {
  type    = string
  default = ""
}

variable "sonarcloud_token" {
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

