variable "service_name" {
  type = string
}

variable "environment_name" {
  type = string
}

variable "func_resource_group_name" {
  type = string
}

variable "service_plan_sku" {
  type    = string
  default = "Y1"
}

variable "provision_repository" {
  type    = bool
  default = false
}

variable "sonarcloud_token" {
  type      = string
  default   = ""
  sensitive = true
}

variable "func_publish_profile_test" {
  type      = string
  default   = ""
  sensitive = true
}

variable "func_publish_profile_prod" {
  type      = string
  default   = ""
  sensitive = true
}

variable "github_token" {
  type    = string
  default = ""
}
