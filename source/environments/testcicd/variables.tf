variable "github_token" {
  default = "ADD-YOUR-OWN"
}

variable "environment_name" {
  default = "testcicd"
}

variable "azure_credentials_test" {
  type = string
}

variable "teams_incoming_webhooks_url_test" {
  type      = string
  sensitive = true
}




