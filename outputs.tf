output "stack" { value = toset(docker_container.container.*) }
