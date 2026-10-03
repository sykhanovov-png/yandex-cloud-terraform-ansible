output "bastion_internal_ip" {
  value       = yandex_compute_instance.bastion.network_interface.0.ip_address
  description = "Внутренний IP bastion"
}

output "bastion_public_ip" {
  value       = yandex_compute_instance.bastion.network_interface.0.nat_ip_address
  description = "Публичный IP bastion для SSH"
}

output "web_1_internal_ip" {
  value       = yandex_compute_instance.web_1.network_interface.0.ip_address
  description = "Внутренний IP web-1"
}

output "web_2_internal_ip" {
  value       = yandex_compute_instance.web_2.network_interface.0.ip_address
  description = "Внутренний IP web-2"
}
