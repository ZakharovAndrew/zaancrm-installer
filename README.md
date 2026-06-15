# 🦎 ZaanCRM Installer

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Bash](https://img.shields.io/badge/bash-4.0+-green.svg)](https://www.gnu.org/software/bash/)
[![Yii2](https://img.shields.io/badge/Yii2-2.0-blue)](https://www.yiiframework.com/)

**ZaanCRM Installer** – автоматический bash‑скрипт для развёртывания профессиональной CRM‑системы на базе Yii2 Basic.

Скрипт создаёт новый проект Yii2, устанавливает обязательные модули:
- `zakharov-andrew/yii2-user` – расширенное управление пользователями, RBAC, профили
- `zakharov-andrew/yii2-pages` – управление статическими страницами (CRUD + публичная часть)
- а также популярные расширения `bootstrap5`, `kartik/grid`, `kartik/select2`, `fontawesome` и другие (список ниже)

Затем настраивает подключение к базе данных (MySQL), выполняет миграции, создаёт учётную запись администратора и генерирует стандартные страницы.

## Требования

- **PHP** >= 7.4 (рекомендуется 8.1) с расширениями: `mbstring`, `xml`, `curl`, `zip`, `json`, `openssl`, `pdo`, `intl`, `gd`
- **Composer** (будет установлен автоматически, если отсутствует)
- **MySQL** >= 5.7 или MariaDB >= 10.2 (если не указывать `--skip-db`)
- **Git** (будет установлен автоматически, если отсутствует)
- **Bash** (Linux, macOS, WSL или Termux)

## Быстрая установка (одной строкой)

```bash
curl -fsSL https://raw.githubusercontent.com/ваш-логин/zaancrm-installer/main/install.sh | bash
