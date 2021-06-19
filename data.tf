data "docker_network" "backend" { name = var.network_backend }
data "docker_network" "frontend" { name = var.network_frontend }
