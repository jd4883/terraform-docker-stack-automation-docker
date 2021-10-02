terraform {
  required_providers {
    dns = {
      source = "hashicorp/dns"
    }
    digitalocean = {
      source = "digitalocean/digitalocean"
    }
    docker = {
      source = "kreuzwerker/docker"
    }
    okta = {
      source = "okta/okta"
    }
  }
}
