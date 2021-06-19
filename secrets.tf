//resource "random_string" "cookie_secret" {
//  for_each = var.stack
//  length   = var.cookie_secret_length
//  special  = var.cookie_secret_special
//}
//
//# TODO: this part probably only should happen for the fw_auth container and nowhere else