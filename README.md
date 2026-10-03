# Terraform: инфраструктура в Yandex Cloud (бастион + два веб‑сервера)

Инфраструктура как код для учебного проекта: Terraform создаёт сеть, подсети, бастион‑хост и два веб‑сервера в Yandex Cloud. После создания инфраструктуры серверы настраиваются через Ansible (см. раздел «Связка с Ansible»).

Автор: Sukhanov Oleg Vladimirovich
Дата: октябрь 2026

## Архитектура

- **Сеть:** одна VPC, две подсети — `10.0.1.0/24` и `10.0.2.0/24`.
- **Bastion:** ВМ с публичным IP `89.169.149.195`, единственная точка входа из интернета.
- **Web-1:** внутренний IP `10.0.1.19` — без публичного адреса.
- **Web-2:** внутренний IP `10.0.2.12` — без публичного адреса.

Прямой доступ к веб‑серверам из интернета закрыт: SSH к ним возможен только через бастион (ProxyJump).


## Что создаёт Terraform

- VPC‑сеть и две подсети.
- Три виртуальные машины: бастион и два веб‑сервера (Ubuntu 24).
- Security groups:
  - бастион: порт 22 — только с твоего IP;
  - web‑серверы: порт 22 — только с IP бастиона, порт 80 — для 0.0.0.0/0 (доступ к сайту).
- Outputs: публичный IP бастиона и внутренние IP веб‑серверов.

## Быстрый старт

### 1. Инициализация

```bash
terraform init
```

### 2. Проверка плана

```bash
terraform plan
```

Должен показать список создаваемых ресурсов: сеть, подсети, 3 ВМ, security groups.


### 3. Применение

```bash
terraform apply
```

После завершения Terraform выведет IP‑адреса (outputs):

```text
bastion_public_ip = 89.169.149.195
web1_private_ip   = 10.0.1.19
web2_private_ip   = 10.0.2.12
```

### 4. Проверка результата

```bash
terraform output
```

---

## Структура проекта

```text
terraform-yandex-cloud/
├── main.tf            # провайдер, ресурсы (ВМ, сеть, security groups)
├── variables.tf       # входные переменные (токен, зона, размеры ВМ)
├── outputs.tf         # выходные значения (IP‑адреса)
├── terraform.tfvars   # значения переменных (не коммитить в Git!)
├── README.md          # этот файл
└── images/            # папка для скриншотов
    ├── architecture.png
    ├── yc-console.png
    ├── plan.png
    ├── apply-outputs.png
    └── security-groups.png
```

---

## Важные настройки и безопасность

### Ключи и переменные

- В `terraform.tfvars` хранится токен Yandex Cloud (`token`) и ID облака/папки — этот файл **не коммитится** (см. `.gitignore`).
- SSH‑ключи для ВМ передаются через метаданные (`ssh-keys` в `metadata` ВМ).
- В `~/.ssh/config` на локальной машине должен быть указан **приватный** ключ (без `.pub`):

```ssh
Host bastion
  HostName 89.169.149.195
  User ubuntu
  IdentityFile ~/.ssh/ssh-key-1786386901838   # без .pub
  ForwardAgent yes
```

Права на ключ:

```bash
chmod 600 ~/.ssh/ssh-key-1786386901838
```

### Security Groups

- Бастион: входящий 22 — только с твоего IP.
- Web‑серверы: входящий 22 — только с IP бастиона; входящий 80 — для всех (или нужных подсетей).

---

## Связка с Ansible (следующий шаг)

После `terraform apply` Terraform выдал IP‑адреса — Ansible использует их для настройки серверов:

1. Terraform создаёт инфраструктуру: `terraform apply`.
2. IP‑адреса из outputs переносятся в `inventory.ini` (в соседнем проекте `ansible-yandex-cloud/`).
3. Ansible ставит Nginx и деплоит страницы:

```bash
cd ~/ansible-yandex-cloud
ansible-playbook -i inventory.ini deploy_nginx.yml
```

Пример `inventory.ini` с ProxyJump через бастион:

```ini
[webservers]
web-1 ansible_host=10.0.1.19 ansible_user=ubuntu ansible_ssh_common_args='-o ProxyJump=ubuntu@89.169.149.195 -o StrictHostKeyChecking=accept-new'
web-2 ansible_host=10.0.2.12 ansible_user=ubuntu ansible_ssh_common_args='-o ProxyJump=ubuntu@89.169.149.195 -o StrictHostKeyChecking=accept-new'
```

Проверка после деплоя:

```bash
ansible webservers -i inventory.ini -m uri -a "url=http://127.0.0.1 return_content=yes"
```

Ожидаемый результат: статус `200`, контент `<h1>Hello from web-1</h1>` / `<h1>Hello from web-2</h1>`.

---

## Идеи для развития

- Автоматически подхватывать IP из Terraform outputs в Ansible inventory (например, скриптом или динамическим инвентарём).
- Вынести установку Nginx в отдельную Ansible‑роль (`roles/nginx-deploy`).
- Развернуть на этих серверах приложение на Django (с проксированием через Nginx) или WordPress.
- Добавить S3‑бэкенд Terraform для хранения состояния в Yandex Object Storage.

---

## Если что‑то не работает

1. **`terraform plan` падает** — проверь токен и ID облака в `terraform.tfvars`.
2. **ВМ не создаются** — проверь квоты и права сервисного аккаунта.
3. **SSH к веб‑серверам не проходит напрямую** — это норма: доступ только через бастион (`ssh web-1`, настроенный в `~/.ssh/config` через `ProxyCommand`).
4. **Сайт недоступен** — проверь Security Groups (порт 80 на web‑серверах) и что Nginx запущен (`sudo systemctl status nginx`).
