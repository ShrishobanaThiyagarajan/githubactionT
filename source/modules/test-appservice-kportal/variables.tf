variable "environment" {
  description = "Deployment environment (dev, platform, prod)"
  type        = string
}

variable "location" {
  description = "Azure region for resource deployment"
  type        = string
  default     = "East US"
}

variable "appservice_resource_group_name" {
  description = "Name of the resource group for App Service"
  type        = string
}

variable "service_plan_sku" {
  description = "SKU for the App Service Plan"
  type        = string
  default     = "S1"
}

variable "appservice_serviceplan_name" {
  description = "Name of the App Service Plan"
  type        = string
  default     = ""
}

variable "appservice_name" {
  description = "Name of the App Service"
  type        = string
  default     = ""
}

variable "apps" {
  description = "List of applications to deploy"
  type        = list(string)
  default     = ["kportal"]
}
variable "app_port" {
  description = "Port used by the web app"
  type        = string
  default     = "8080"
}

variable "environment" {
  description = "Deployment environment (e.g., dev, platform, prod)"
  type        = string
}