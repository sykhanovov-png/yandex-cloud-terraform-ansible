terraform {
  required_providers {
    yandex = {
      source  = "yandex-cloud/yandex"
      version = ">= 0.88.0"
    }
  }
}

provider "yandex" {
  folder_id = var.folder_id
}

# VPC
resource "yandex_vpc_network" "internal_network" {
  name = "internal-network"
}

# Подсети (без привязки к отдельной таблице маршрутизации)
resource "yandex_vpc_subnet" "subnet_a" {
  name          = "subnet-a"
  network_id    = yandex_vpc_network.internal_network.id
  v4_cidr_blocks = ["10.0.1.0/24"]
  zone          = "ru-central1-a"
}

resource "yandex_vpc_subnet" "subnet_b" {
  name          = "subnet-b"
  network_id    = yandex_vpc_network.internal_network.id
  v4_cidr_blocks = ["10.0.2.0/24"]
  zone          = "ru-central1-a"
}

# Security Groups
resource "yandex_vpc_security_group" "bastion_sg" {
  name        = "bastion-sg"
  network_id  = yandex_vpc_network.internal_network.id

  ingress {
    protocol       = "TCP"
    port           = 22
    v4_cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    protocol       = "ANY"
    v4_cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "yandex_vpc_security_group" "web_sg" {
  name        = "web-sg"
  network_id  = yandex_vpc_network.internal_network.id

  ingress {
    protocol       = "TCP"
    port           = 80
    v4_cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    protocol       = "TCP"
    port           = 443
    v4_cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    protocol        = "TCP"
    port            = 22
    security_group_id = yandex_vpc_security_group.bastion_sg.id
  }

  egress {
    protocol       = "ANY"
    v4_cidr_blocks = ["0.0.0.0/0"]
  }
}

# Bastion
resource "yandex_compute_instance" "bastion" {
  name        = "bastion"
  platform_id = "standard-v1"
  zone        = "ru-central1-a"

  resources {
    core_fraction = 20
    cores         = 2
    memory        = 1
  }

  boot_disk {
    initialize_params {
      image_id = var.image_id
    }
  }

  network_interface {
    subnet_id         = yandex_vpc_subnet.subnet_a.id
    nat               = true
    security_group_ids = [yandex_vpc_security_group.bastion_sg.id]
  }

  metadata = {
    ssh-keys = "ubuntu:${file(pathexpand("~/.ssh/ssh-key-1786386901838.pub"))}"
  }
}

# Web-1
resource "yandex_compute_instance" "web_1" {
  name        = "web-1"
  platform_id = "standard-v1"
  zone        = "ru-central1-a"

  resources {
    core_fraction = 20
    cores         = 2
    memory        = 1
  }

  boot_disk {
    initialize_params {
      image_id = var.image_id
    }
  }

  network_interface {
    subnet_id         = yandex_vpc_subnet.subnet_a.id
    nat               = true
    security_group_ids = [yandex_vpc_security_group.web_sg.id]
  }

  metadata = {
    ssh-keys = "ubuntu:${file(pathexpand("~/.ssh/ssh-key-1786386901838.pub"))}"
  }
}

# Web-2
resource "yandex_compute_instance" "web_2" {
  name        = "web-2"
  platform_id = "standard-v1"
  zone        = "ru-central1-a"

  resources {
    core_fraction = 20
    cores         = 2
    memory        = 1
  }

  boot_disk {
    initialize_params {
      image_id = var.image_id
    }
  }

  network_interface {
    subnet_id         = yandex_vpc_subnet.subnet_b.id
    nat               = true
    security_group_ids = [yandex_vpc_security_group.web_sg.id]
  }

  metadata = {
  ssh-keys = "ubuntu:${file(pathexpand("~/.ssh/ssh-key-1786386901838.pub"))}"
  }
}
