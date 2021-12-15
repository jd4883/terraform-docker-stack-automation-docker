terraform {
  required_providers {
    digitalocean = {
      source = "digitalocean/digitalocean"
    }
    docker = {
      source = "kreuzwerker/docker"
    }
    okta = {
      source = "okta/okta"
    }
    pihole = {
      source = "ryanwholey/pihole"
      configuration_aliases = [
        pihole.ns1,
        pihole.ns2,
      ]
    }
  }
}
