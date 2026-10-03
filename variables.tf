variable "folder_id" {
  description = "ID каталога (folder) в Yandex Cloud"
  type        = string
}

variable "image_id" {
  description = "ID образа ОС для ВМ (например, ubuntu2204-lts)"
  type        = string
}

variable "ssh_key" {
  description = "Публичный SSH-ключ (содержимое id_rsa.pub)"
  type        = string
}
