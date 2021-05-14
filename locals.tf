locals {
  domain      = tostring(try(var.globals.dns.domain, "example.com"))
  dns_servers = var.globals.dns.servers.local.addresses
  emails      = tolist(var.globals.authentication.emails)
  envars = [
    "DEBUG=${var.debug}",
    "DOMAIN=${local.domain}",
    "DOMAIN_EMAIL=${local.emails[length(local.emails) - 1]}",
    "EMAIL=${local.emails.0}",
    "HOME=${var.home}",
    "HOST_IP=${var.globals.networking.host_ip}",
    "PGID=${var.globals.authentication.pgid}",
    "PUID=${var.globals.authentication.puid}",
    "TZ=${var.globals.tz}",
  ]
  labels = {
    v2 = {}
  }
}
