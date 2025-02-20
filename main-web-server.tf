# Настройки Terraform
terraform {
  required_providers {
    yandex = {
      source  = "yandex-cloud/yandex"
    }
    null = {
      source = "hashicorp/null"
      version = "~> 3.2.1"
    }
  }
  required_version = ">= 0.13"
}

provider "yandex" {
  service_account_key_file = pathexpand("~/keys/key1.json")
  cloud_id                 = var.CLOUD_ID
  folder_id                = var.FOLDER_ID
  zone                     = var.ZONE
}

resource "yandex_vpc_network" "network" {
  name = "web-server-network"
}

resource "yandex_vpc_subnet" "subnet" {
  name           = "web-server-subnet"
  zone           = var.ZONE
  v4_cidr_blocks = ["192.168.10.0/24"]
  network_id     = yandex_vpc_network.network.id
}

# Получение  последеней версии публичного образа с Ubuntu 24.04
data "yandex_compute_image" "ubuntu" {
  family = "ubuntu-2404-lts-oslogin"
}

resource "yandex_compute_disk" "boot-disk" {
  name     = "web-server-boot-disk"
  type     = "network-ssd"
  image_id = data.yandex_compute_image.ubuntu.id
  size     = 20 
}

resource "yandex_compute_instance" "server" {
  name        = "web-server"
  platform_id = "standard-v3"
  hostname    = "web"

  resources {
    core_fraction = 20
    cores         = 2
    memory        = 4
  }

  boot_disk {
    disk_id = yandex_compute_disk.boot-disk.id
  }

  network_interface {
    subnet_id = yandex_vpc_subnet.subnet.id
    nat = true
  }

  metadata = {
    ssh-keys = "ubuntu:${file("~/.ssh/id_rsa.pub")}"
  }
}

# Создание DNS-зоны для домена vvot34.itiscl.ru.
resource "yandex_dns_zone" "dns_zone" {
  zone        = var.DNS_ZONE
  description = "DNS зона для проекта"
  public = true
}

# Для основного домена
resource "yandex_dns_recordset" "web" {
  zone_id = yandex_dns_zone.dns_zone.id
  name    = "${var.DNS_ZONE}" # "vvot34.itiscl.ru."
  type    = "A"
  ttl     = 300
  data    = [yandex_compute_instance.server.network_interface.0.nat_ip_address]
}

resource "yandex_dns_recordset" "cname" {
  zone_id = yandex_dns_zone.dns_zone.id
  name    = yandex_cm_certificate.certificate.challenges[0].dns_name
  type    = "CNAME"
  ttl     = 600
  data = ["${yandex_cm_certificate.certificate.id}.cm.yandexcloud.net."]
}

resource "yandex_cm_certificate" "certificate" {
  name    = "certificate"
  domains = [var.DOMAIN]

  managed {
    challenge_type = "DNS_CNAME"
  }
}

# resource "yandex_api_gateway" "api_gateway" {
#   name = "gateaway"
#   custom_domains {
#     fqdn = "${var.DOMAIN}"
#     certificate_id = yandex_cm_certificate.certificate.id
#   }

#   spec = <<-EOT
#     openapi: 3.0.0
#     info:
#       title: Sample API
#       version: 1.0.0
#     paths:
#       /:
#         get:
#           x-yc-apigateway-integration:
#             type: http
#             url: http://${var.DOMAIN}
#       /{path}:
#         get:
#           parameters:
#             - name: path
#               in: path
#               required: true
#               schema:
#                 type: string
#           x-yc-apigateway-integration:
#             type: http
#             url: http://${var.DOMAIN}/{nextfound}
# EOT
# }