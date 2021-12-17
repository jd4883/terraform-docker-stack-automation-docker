module "dns" {
  source                = "jd4883/internal-external-dns-automation-docker/docker"
  providers = {
    pihole.ns1 = pihole.ns1
    pihole.ns2 = pihole.ns2
   }
  STSSeconds            = var.STSSeconds
  local_domain          = var.local_domain
  cnames                = distinct(concat(lookup(each.value, "subdomains", []), [each.key]))
  customResponseHeaders = var.customResponseHeaders
  domain                = local.domain
  emails                = local.emails
  envars                = local.envars
  external_dns          = tobool(lookup(each.value, "external_dns", try(lookup(each.value, "networks", { "frontend" : false }).frontend, false)))
  for_each              = var.stack
  internal_dns          = tobool(lookup(each.value, "internal_dns", true))
  labels                = lookup(each.value, "labels", {})
  logo_url              = tostring(lookup(each.value, "logo_url", ""))
  name                  = lower(tostring(each.key))
  networks              = var.networks.*.id
  okta_oauth            = tobool(lookup(each.value, "okta_oauth", true))
  organizr_cname        = var.organizr_cname
  private_ip            = var.globals.networking.host_ip
  upstream_url          = "http://${try(each.value.networks.vpn, lookup(each.value, "hostname", lower(each.key)))}:${split(":", replace(try(tolist(each.value.ports), ["80:80"]).0, "/", ":")).1}"
}
