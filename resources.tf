resource "docker_container" "container" {
  for_each = local.stacks
  dynamic "devices" {
    for_each = lookup(each.value, "devices", [])
    content {
      host_path = devices.value
    }
  }
  dynamic "capabilities" {
    for_each = lookup(each.value, "capabilities", [])
    content {
      add  = try(capabilities.value.add, [])
      drop = try(capabilities.value.drop, [])
    }
  }
  attach            = lookup(each.value, "userns_mode", false)
  command           = lookup(each.value, "Commands", [])
  cpu_set           = tostring(lookup(each.value, "cpu_set", "0-1"))
  cpu_shares        = tonumber(lookup(each.value, "cpu", null))
  dns               = try(each.value.networks.vpn, "default") == "default" ? try(tolist(each.value.dns), local.dns_servers) : []
  dns_opts          = lookup(each.value, "dns_opts", [])
  dns_search        = try(tolist([for i in lookup(each.value, "subdomains", []) : join(".", [i, local.domain])]), [])
  domainname        = local.domain
  entrypoint        = lookup(each.value, "Entrypoint", [])
  env               = distinct(concat(tolist([for k, v in tomap(lookup(each.value, "Environment", {})) : "${k}=${v}"]), local.envars, ["TAG=${lookup(each.value, "tags", "latest")}"]))
  group_add         = lookup(each.value, "group_add", [])
  hostname          = try(each.value.networks.vpn, "default") == "default" ? lookup(each.value, "hostname", lower(each.key)) : null
  image             = lookup(var.images, lower(each.key)).id
  log_driver        = tostring(lookup(each.value, "log_driver", "json-file"))
  log_opts          = tomap(lookup(each.value, "log_opts", {}))
  logs              = tobool(lookup(each.value, "logs", false))
  max_retry_count   = tonumber(lookup(each.value, "max_retry_count", 0))
  memory            = tonumber(lookup(each.value, "memory", null))
  memory_swap       = tonumber(lookup(each.value, "memory_swap", 0))
  must_run          = tobool(lookup(each.value, "must_run", true))
  name              = lower(tostring(each.key))
  network_mode      = lookup(lookup(each.value, "networks", { "vpn" : "default" }), "vpn", "default") != "default" ? "container:${lookup(each.value, "networks").vpn}" : "default"
  pid_mode          = tostring(lookup(each.value, "pid_mode", "host"))
  privileged        = tobool(lookup(each.value, "privileged", false))
  publish_all_ports = tobool(lookup(each.value, "publish_all_ports", false))
  read_only         = tobool(lookup(each.value, "read_only", false))
  remove_volumes    = tobool(lookup(each.value, "remove_volumes", true))
  restart           = tostring(lookup(each.value, "restart", "on-failure"))
  rm                = tobool(lookup(each.value, "rm", false))
  start             = tobool(lookup(each.value, "start", true))
  sysctls           = tomap(lookup(each.value, "systemctl", {}))
  tmpfs             = tomap(lookup(each.value, "tmpfs", {}))
  tty               = tobool(lookup(each.value, "tty", false))
  user              = tostring(lookup(each.value, "user", ""))
  userns_mode       = tostring(lookup(each.value, "userns_mode", ""))
  working_dir       = tostring(lookup(each.value, "working_dir", ""))
  dynamic "ports" {
    for_each = try(each.value.vpn_container, false) ? concat(try(try(each.value.networks.vpn, "default") == "default" ? tolist(each.value.ports) : [], []), var.vpn_ports) : try(try(each.value.networks.vpn, "default") == "default" ? tolist(each.value.ports) : [], [])
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
      {
        "com.centurylinklabs.watchtower.enable" : true,
      },
      tobool(lookup(each.value, "public_dns", true)) ? merge(lookup(each.value, "labels", {}), {
        "traefik.enable" : true,
        "traefik.http.routers.${lower(each.key)}.rule" : "Host(${join(",", formatlist("`%s`", [for i in tolist(try(tolist(each.value.subdomains), [each.key])) : join(".", [i, local.domain])]))})",
        "traefik.http.services.${lower(each.key)}.loadbalancer.server.port" : split(":", replace(try(tolist(each.value.ports), ["80:80"]).0, "/", ":")).1,
        #"traefik.http.routers.${lower(each.key)}.service" : try(each.value.networks.vpn, "") == "" ? lower(each.key) : each.value.networks.vpn,
        #"traefik.http.middlewares.${lower(each.key)}.headers.sslhost" : join(",", formatlist("`%s`", [for i in tolist(try(tolist(each.value.subdomains), [each.key])) : join(".", [i, local.domain])])),
        #"traefik.http.middlewares.${lower(each.key)}-compression.compress" : tobool(try(each.value.compression, false)),
      }, try(each.value.networks.vpn, "") == "" ? {} : { "traefik.http.routers.${lower(each.key)}.service" : lower(each.key) }) : {},
      tobool(lookup(each.value, "vpn_container", false)) ? merge(
        try(each.value.labels, {}),
        { "traefik.enable" : true },
      var.vpn_labels) : {}
    )
    content {
      label = replace(labels.key, "PLACEHOLDER_KEY", lower(each.key))
      value = replace(labels.value, "PLACEHOLDER_KEY", lower(each.key))
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
    for_each = try(each.value.networks.vpn, "default") != "default" ? [] : [data.docker_network.backend.name, data.docker_network.frontend.name]
    content {
      name = networks_advanced.value
    }
  }
  provisioner "local-exec" {
    command = tostring(join(" && ", try(each.value.provisioner, ["docker container logs ${lower(each.key)}"])))
  }
}
