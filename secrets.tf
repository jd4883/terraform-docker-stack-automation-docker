resource "random_string" "cookie_secret" {
  for_each = var.stack
  length   = var.cookie_secret_length
  special  = var.cookie_secret_special
}
