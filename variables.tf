variable deployment_name {
  type = string
  default = "uts-qbot"
}

variable deployment_location {
  type = string
  default = "Australia East"
}

variable database_administrator_username {
  type = string
  default = "go_administrator"
}
variable database_administrator_password {
  type = string
  default = "HashiCorp123!"
}

variable dns_zone_name {
  type = string
  default = "go.hashidemos.io"
}