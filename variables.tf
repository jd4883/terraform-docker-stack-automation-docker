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
variable "vpn_labels" { default = {} }
variable "vpn_ports" { default = [] }
variable "images" { type = map(map(string)) }
variable "networks" {}
variable "exec" {}
variable "local_domain" {
  type = string
  default = "example.com"
}
