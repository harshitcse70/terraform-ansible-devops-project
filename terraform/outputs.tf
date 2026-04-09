output "dev_ip" {
  value = module.dev.public_ip
}

output "stage_ip" {
  value = module.stage.public_ip
}

output "prod_ip" {
  value = module.prod.public_ip
}
