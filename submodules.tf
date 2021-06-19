module "dns" {
  for_each   = var.stack
  cnames     = distinct(concat(lookup(each.value, "subdomains", []), [each.key]))
  domain     = local.domain
  private_ip = var.globals.networking.host_ip
  external_dns = tobool(try(each.value.external_dns, try(try(tomap(each.value.networks), { "frontend" : false }).frontend, false)))
  internal_dns = tobool(try(each.value.internal_dns, true))

  logo_url              = tostring(lookup(each.value, "logo_url", ""))
  name                  = lower(tostring(each.key))
  okta_oauth            = tobool(lookup(each.value, "okta_oauth", true))
  source                = "jd4883/internal-external-dns-automation-docker/docker"
  labels                = lookup(each.value, "labels", {})
  emails                = local.emails
  envars                = local.envars
  upstream_url          = "http://${try(each.value.networks.vpn, try(each.value.hostname, lower(each.key)))}:${split(":", replace(try(tolist(each.value.ports), ["80:80"]).0, "/", ":")).1}"
  customResponseHeaders = var.customResponseHeaders
  organizr_cname        = var.organizr_cname
  STSSeconds            = var.STSSeconds
  networks              = [data.docker_network.backend.id, data.docker_network.frontend.id]
}