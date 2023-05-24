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
  type = string
  default = "Y1"
}