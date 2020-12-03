variable "customResponseHeaders" { default = "X-Robots-Tag:noindex, nofollow, nosnippet, noarchive, notranslate, noimageindex, none" }
variable "debug" { default = 1 }
variable "globals" {}
variable "home" { default = "/nobody" }
variable "oauth" { default = false }
variable "organizr_cname" { default = "home" }
variable "certresolver" { default = "le" }
variable "stack" {}
variable "stack_name" { type = string }
variable "STSSeconds" { default = 315360000 }

variable "cookie_secret_length" {
  type    = number
  default = 32
}

variable "cookie_secret_special" {
  type    = bool
  default = true
}

variable "network_backend" {
  type    = string
  default = "backend"
}

variable "network_frontend" {
  type    = string
  default = "frontend"
}
