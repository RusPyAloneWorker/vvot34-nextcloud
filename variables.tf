variable "ZONE" {
  type        = string
  description = "Yandex.Cloud Zone"
  default     = "ru-central1-d" # рекомендуемая зона для новых проектов
}

variable "CLOUD_ID" {
  type        = string
  description = "Yandex.Cloud Cloud ID"
}

variable "FOLDER_ID" {
  type        = string
  description = "Yandex.Cloud Folder ID"
}

variable "DNS_ZONE" {
    type = string
}

variable "DOMAIN" {
    type = string
}

variable "USER_ZONE" {
    type = string
}


output "web-server-ip" {
  value = yandex_compute_instance.server.network_interface[0].nat_ip_address
}

output "sadsad" {
  value = yandex_cm_certificate.certificate.challenges[0].dns_name
} 