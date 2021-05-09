resource "docker_image" "image" {
  for_each = try(var.stack, {})
  name     = join(":", [try(each.value.Image, each.key), try(each.value.tags, "latest")])
}

resource "docker_container" "container" {
  for_each = try(var.stack, {})
  dynamic "devices" {
    for_each = try(tolist(each.value.devices), [])
    content {
      host_path = devices.value
    }
  }
  dynamic "capabilities" {
    for_each = try(tomap(try(tolist(each.value.capabilities), [])), {})
    content {
      add  = try(capabilities.value.add, [])
      drop = try(capabilities.value.drop, [])
    }
  }
  attach            = try(tobool(each.value.userns_mode), false)
  command           = try(tolist(each.value.Commands), [])
  cpu_set           = try(tostring(each.value.cpu_set), "0-1")
  cpu_shares        = try(tonumber(each.value.cpu), null)
  depends_on        = [data.docker_network.backend, random_string.cookie_secret]
  dns               = try(each.value.networks.vpn, "default") == "default" ? try(tolist(each.value.dns), local.dns_servers) : []
  dns_opts          = try(tolist(each.value.dns_opts), [])
  dns_search        = try(tolist([for i in lookup(each.value, "subdomains", []) : join(".", [i, local.domain])]), [])
  domainname        = local.domain
  entrypoint        = try(tolist(each.value.Entrypoint), [])
  env               = distinct(concat(tolist([for k, v in try(each.value.Environment, {}) : "${k}=${v}"]), local.envars, ["TAG=${lookup(each.value, "tags", "latest")}", "OAUTH2_PROXY_COOKIE_SECRET=${random_string.cookie_secret[each.key].result}"]))
  group_add         = try(tolist(each.value.group_add), [])
  hostname          = try(each.value.networks.vpn, "default") == "default" ? try(each.value.hostname, lower(each.key)) : null
  image             = lower(try(docker_image.image[each.key].latest, each.key))
  log_driver        = tostring(try(each.value.log_driver, "json-file"))
  log_opts          = try(tomap(each.value.log_opts), {})
  logs              = try(tobool(each.value.logs), false)
  max_retry_count   = tonumber(try(each.value.max_retry_count, 0))
  memory            = try(tonumber(each.value.memory), null)
  memory_swap       = tonumber(try(each.value.memory_swap, 0))
  must_run          = try(tobool(each.value.must_run), true)
  name              = lower(tostring(each.key))
  network_mode      = try("container:${each.value.networks.vpn}", "default")
  pid_mode          = try(tostring(each.value.pid_mode), "host")
  privileged        = tobool(try(each.value.privileged, false))
  publish_all_ports = tobool(try(each.value.publish_all_ports, false))
  read_only         = try(tobool(each.value.read_only), false)
  remove_volumes    = try(tobool(each.value.remove_volumes), true)
  restart           = tostring(try(each.value.restart, "on-failure"))
  rm                = try(tobool(each.value.rm), false)
  start             = try(tobool(each.value.start), true)
  sysctls           = try(tomap(each.value.systemctl), {})
  tmpfs             = try(tomap(each.value.tmpfs), {})
  tty               = try(tobool(each.value.tty), false)
  user              = try(each.value.user, "")
  userns_mode       = try(tostring(each.value.userns_mode), "")
  working_dir       = try(each.value.working_dir, "")
  dynamic "ports" {
    for_each = try(try(each.value.networks.vpn, "default") == "default" ? tolist(each.value.ports) : [], [])
    content {
      internal = tonumber(split(":", replace(ports.value, "/", ":")).1)
      external = tonumber(split(":", replace(ports.value, "/", ":")).0)
      protocol = contains(regex("^(?:.*(/udp))?.*$", tostring(ports.value)), "/udp") ? "udp" : "tcp"
    }
  }
  dynamic "mounts" {
    for_each = tolist(lookup(each.value, "Volumes", []))
    content {
      source    = abspath(tostring(split(":", mounts.value).0))
      target    = abspath(tostring(split(":", mounts.value).1))
      type      = "bind"
      read_only = contains(regex("^(?:.*(:ro))?.*$", tostring(mounts.value)), ":ro") ? true : false
    }
  }
  dynamic "labels" {
    for_each = merge(
      tobool(try(each.value.public_dns, true)) ? merge(tobool(try(each.value.okta_oauth, true)) ? {} : local.labels.v2, try(each.value.labels, {})) : {},
      tobool(try(each.value.okta_oauth, true)) ? {} : {
        "traefik.http.routers.${lower(each.key)}.rule" : "Host(${join(",", formatlist("`%s`", [for i in tolist(try(tolist(each.value.subdomains), [each.key])) : join(".", [i, local.domain])]))})",
        "traefik.http.routers.${lower(each.key)}.service" : lower(each.key),
        "traefik.http.services.${lower(each.key)}.loadbalancer.server.port" : split(":", replace(try(tolist(each.value.ports), ["80:80"]).0, "/", ":")).1,
        "traefik.http.middlewares.${lower(each.key)}.headers.sslhost" : join(",", formatlist("`%s`", [for i in tolist(try(tolist(each.value.subdomains), [each.key])) : join(".", [i, local.domain])])),
        "traefik.http.middlewares.${lower(each.key)}-compression.compress" : tobool(try(each.value.compression, false)),
        "com.centurylinklabs.watchtower.enable": true,
      }
    )
    content {
      label = replace(labels.key, "PLACEHOLDER_KEY", lower(each.key))
      value = labels.value == "traefik.enable" ? try(each.value.public_dns, true) : replace(labels.value, "PLACEHOLDER_KEY", lower(each.key))
    }
  }

  lifecycle {
    create_before_destroy = false
    ignore_changes = [
      container_logs,
      exit_code,
      links,
      network_data,
      command,
      healthcheck,
      network_mode,
    ]
  }
  dynamic "networks_advanced" {
    for_each = try(
      tobool(
      each.value.networks.vpn),
      false
      ) == true ? [] : tobool(
      try(
        each.value.networks.frontend,
        false
        ) && !try(
        each.value.okta_oauth,
        true
        ) && try(
        each.value.networks.vpn,
      "default") == "default"
      ) ? [data.docker_network.backend.name,
    data.docker_network.frontend.name] : [data.docker_network.backend.name]
    content {
      name = networks_advanced.value
    }
  }
  provisioner "local-exec" {
    command = tostring(join(" && ", try(each.value.provisioner, ["docker container logs ${lower(each.key)}"])))
  }
}
