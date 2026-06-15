#!/bin/bash
# ============================================================================
# ZaanCRM Installer - Yii2 CRM система
# ============================================================================
# Автоматическая установка ZaanCRM на базе Yii2 Basic
# с расширенными модулями: пользователи + страницы
#
# Использование:
#   curl -fsSL https://zaan.ru/install-zaancrm.sh | bash
#
# Или с опциями:
#   curl -fsSL ... | bash -s -- --db-name=zaancrm --db-user=zaan_user
# ============================================================================

set -e

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'
BOLD='\033[1m'

# Конфигурация ZaanCRM
PROJECT_NAME="ZaanCRM"
PROJECT_DIR=""
PROJECT_URL="zaancrm.local"
COMPANY_NAME="ZaanCRM"
COMPANY_EMAIL="info@zaancrm.com"

# Конфигурация БД
DB_HOST="localhost"
DB_PORT="3306"
DB_NAME="zaancrm"
DB_USER="zaan_user"
DB_PASSWORD=""
DB_DRIVER="mysql"

# Администратор по умолчанию
ADMIN_EMAIL="admin@zaancrm.local"
ADMIN_USERNAME="admin"
ADMIN_PASSWORD=""
ADMIN_FIRST_NAME="Zaan"
ADMIN_LAST_NAME="Admin"

# Настройки установки
ENV="dev"
INTERACTIVE=true
RUN_MIGRATIONS=true
SETUP_DB=true
INSTALL_DEMO_DATA=false
CREATE_DEFAULT_PAGES=true

# Обязательные модули (ZaanCRM core)
CORE_MODULES=(
    "zakharov-andrew/yii2-user"           # Расширенный модуль пользователей
    "zakharov-andrew/yii2-pages"          # Модуль управления страницами
    "yiisoft/yii2-bootstrap5"              # Bootstrap 5 интерфейс
    "yiisoft/yii2-fontawesome"             # Иконки FontAwesome
    "kartik-v/yii2-dialog"                 # Диалоговые окна
    "kartik-v/yii2-grid"                   # Расширенная таблица
    "kartik-v/yii2-widget-select2"         # Улучшенные select
)

# Дополнительные модули (опционально)
OPTIONAL_MODULES=(
    "yiisoft/yii2-debug"                   # Отладка (только dev)
    "yiisoft/yii2-gii"                     # Генератор кода (только dev)
    "yiisoft/yii2-faker"                   # Генерация тестовых данных
    "yiisoft/yii2-httpclient"              # HTTP клиент
    "yiisoft/yii2-authclient"              # OAuth авторизация
    "kartik-v/yii2-export"                 # Экспорт данных
    "kartik-v/yii2-mpdf"                   # PDF генерация
    "yiisoft/yii2-elasticsearch"           # Поиск (опционально)
)

# ============================================================================
# Брендирование ZaanCRM
# ============================================================================

print_banner() {
    echo ""
    echo -e "${MAGENTA}${BOLD}"
    echo "╔═══════════════════════════════════════════════════════════════════╗"
    echo "║                    🦎 ZaanCRM Installer v2.0                       ║"
    echo "╠═══════════════════════════════════════════════════════════════════╣"
    echo "║           Профессиональная CRM система на Yii2                    ║"
    echo "║         Модули: Пользователи + Управление страницами              ║"
    echo "╚═══════════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
}

log_info() {
    echo -e "${CYAN}→${NC} $1"
}

log_success() {
    echo -e "${GREEN}✓${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}⚠${NC} $1"
}

log_error() {
    echo -e "${RED}✗${NC} $1"
}

log_step() {
    echo ""
    echo -e "${BLUE}${BOLD}━━━ $1 ━━━${NC}"
}

prompt_yes_no() {
    local question="$1"
    local default="${2:-yes}"
    
    if [ "$INTERACTIVE" = false ]; then
        return 0
    fi
    
    local answer=""
    read -r -p "$question [Y/n]: " answer || answer=""
    answer="${answer:-$default}"
    
    case "$answer" in
        [yY]|[yY][eE][sS]) return 0 ;;
        *) return 1 ;;
    esac
}

prompt_input() {
    local prompt="$1"
    local default="$2"
    local value=""
    
    if [ "$INTERACTIVE" = false ]; then
        echo "$default"
        return
    fi
    
    read -r -p "$prompt [$default]: " value || value=""
    echo "${value:-$default}"
}

prompt_password() {
    local prompt="$1"
    local password=""
    local confirm=""
    
    if [ "$INTERACTIVE" = false ]; then
        echo $(openssl rand -base64 16 | tr -d "=+/" | cut -c1-12)
        return
    fi
    
    while true; do
        read -s -p "$prompt: " password
        echo ""
        read -s -p "Подтвердите пароль: " confirm
        echo ""
        
        if [ "$password" = "$confirm" ] && [ -n "$password" ]; then
            echo "$password"
            break
        else
            log_error "Пароли не совпадают или пустые. Попробуйте снова."
        fi
    done
}

# ============================================================================
# Проверка системы
# ============================================================================

check_php() {
    log_info "Проверка PHP..."
    
    if ! command -v php &> /dev/null; then
        log_error "PHP не установлен"
        echo ""
        log_info "Установите PHP 7.4+:"
        echo "  Ubuntu/Debian: sudo apt install php8.1 php8.1-cli php8.1-mbstring php8.1-xml php8.1-curl php8.1-zip php8.1-pdo php8.1-mysql php8.1-intl php8.1-gd php8.1-json"
        echo "  CentOS/RHEL:   sudo yum install php php-cli php-mbstring php-xml php-curl php-zip php-pdo php-mysql php-json"
        echo "  macOS:         brew install php@8.1"
        exit 1
    fi
    
    PHP_VERSION=$(php -v | head -n1 | cut -d' ' -f2)
    log_success "PHP версия: $PHP_VERSION"
    
    if [[ "$PHP_VERSION" < "7.4" ]]; then
        log_error "Требуется PHP 7.4 или выше"
        exit 1
    fi
}

check_composer_local() {
    log_info "Проверка Composer..."
    
    if ! command -v composer &> /dev/null; then
        log_info "Установка Composer локально..."
        
        EXPECTED_CHECKSUM="$(php -r 'copy("https://composer.github.io/installer.sig", "php://stdout");')"
        php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');"
        ACTUAL_CHECKSUM="$(php -r "echo hash_file('sha384', 'composer-setup.php');")"
        
        if [ "$EXPECTED_CHECKSUM" != "$ACTUAL_CHECKSUM" ]; then
            >&2 echo 'ERROR: Invalid installer checksum'
            rm composer-setup.php
            exit 1
        fi
        
        php composer-setup.php --quiet --install-dir=/usr/local/bin --filename=composer
        rm composer-setup.php
        log_success "Composer установлен"
    else
        COMPOSER_VERSION=$(composer --version | cut -d' ' -f3)
        log_success "Composer версия: $COMPOSER_VERSION"
    fi
}

check_extensions() {
    log_info "Проверка PHP расширений..."
    
    local required_extensions=("mbstring" "xml" "curl" "zip" "json" "openssl" "pdo" "intl" "gd")
    local missing=()
    
    for ext in "${required_extensions[@]}"; do
        if ! php -m | grep -qi "$ext"; then
            missing+=("$ext")
        fi
    done
    
    if [ ${#missing[@]} -eq 0 ]; then
        log_success "Все необходимые расширения установлены"
    else
        log_warn "Отсутствуют расширения: ${missing[*]}"
        log_info "Установите их и запустите установку заново"
        exit 1
    fi
}

check_git() {
    log_info "Проверка Git..."
    
    if ! command -v git &> /dev/null; then
        log_warn "Git не установлен. Установка через менеджер пакетов..."
        if command -v apt &> /dev/null; then
            sudo apt install -y git
        elif command -v yum &> /dev/null; then
            sudo yum install -y git
        elif command -v brew &> /dev/null; then
            brew install git
        else
            log_error "Установите Git вручную"
            exit 1
        fi
    fi
    
    log_success "Git установлен"
}

create_project() {
    log_step "Создание проекта ZaanCRM"
    
    if [ -z "$PROJECT_DIR" ]; then
        PROJECT_DIR="$PWD/$PROJECT_NAME"
    fi
    
    if [ -d "$PROJECT_DIR" ]; then
        log_warn "Директория $PROJECT_DIR уже существует"
        if ! prompt_yes_no "Перезаписать проект?" "no"; then
            log_error "Установка отменена"
            exit 1
        fi
        rm -rf "$PROJECT_DIR"
    fi
    
    log_info "Создание проекта на основе Yii2 Basic..."
    composer create-project --prefer-dist --no-interaction yiisoft/yii2-app-basic "$PROJECT_NAME"
    
    cd "$PROJECT_DIR"
    log_success "Проект создан в $PROJECT_DIR"
}

setup_directories() {
    log_step "Настройка структуры директорий ZaanCRM"
    
    # Создание только специфичных для ZaanCRM директорий
    mkdir -p web/uploads/pages    # для изображений страниц
    mkdir -p web/uploads/users   # для аватаров пользователей
    mkdir -p web/uploads/files   # для общих файлов
    
    # Установка прав на запись для uploads
    chmod 755 web/uploads
    chmod 755 web/uploads/pages
    chmod 755 web/uploads/users
    chmod 755 web/uploads/files
    
    # Создание базовой конфигурации (если не существует)
    if [ ! -f "config/params.php" ]; then
        cat > "config/params.php" <<'EOF'
<?php
return [
    'bsVersion' => '5.x',
    'adminEmail' => 'admin@zaancrm.local',
    'supportEmail' => 'support@zaancrm.local',
    'senderEmail' => 'noreply@zaancrm.local',
    'senderName' => 'ZaanCRM',
    'companyName' => 'ZaanCRM',
    'companyPhone' => '+7 (999) 123-45-67',
    'companyAddress' => 'change',
];
EOF
        log_success "Создан config/params.php"
    fi
    
    log_success "Структура директорий ZaanCRM создана"
}

install_core_modules() {
    log_step "Установка обязательных модулей ZaanCRM"

    # Установка модуля пользователей
    log_info "Установка модуля пользователей (zakharov-andrew/yii2-user)..."
    composer require --prefer-dist --no-interaction "zakharov-andrew/yii2-user"
    
    # Установка модуля страниц
    log_info "Установка модуля страниц (zakharov-andrew/yii2-pages)..."
    composer require --prefer-dist --no-interaction "zakharov-andrew/yii2-pages"
    
    # Установка остальных обязательных модулей
    for module in "${CORE_MODULES[@]}"; do
        if [[ "$module" != "zakharov-andrew/yii2-user" ]] && [[ "$module" != "zakharov-andrew/yii2-pages" ]]; then
            log_info "Установка $module..."
            composer require --prefer-dist --no-interaction "$module"
        fi
    done
    
    # Обновление config/web.php
    log_info "Настройка конфигурации приложения..."
    update_web_config
    
    log_success "Обязательные модули установлены и настроены"
}

update_web_config_php() {
    log_info "Обновление config/web.php через PHP..."
    
    # Создание резервной копии
    if [ -f "config/web.php" ]; then
        BACKUP_FILE="config/web.php.backup.$(date +%Y%m%d_%H%M%S)"
        cp config/web.php "$BACKUP_FILE"
    fi
    
    # Использование PHP для безопасного добавления конфигурации
    php -r "
        \$configFile = 'config/web.php';
        \$config = require \$configFile;
        
        // Добавление модуля user
        if (!isset(\$config['modules']['user'])) {
            \$config['modules']['user'] = [
                'class' => 'ZakharovAndrew\\user\\Module',
                'bootstrapVersion' => 5,
                'showTitle' => true,
                'enableUserSignup' => true,
                'telegramToken' => env('TELEGRAM_BOT_TOKEN', ''),
                'telegramBotLink' => 'https://t.me/zaancrm_bot',
                'controllersAccessList' => [
                    1001 => [
                        'Users' => [
                            '/user/user/index' => 'users',
                            '/user/user/create' => 'create user',
                            '/user/user/update' => 'update user',
                            '/user/user/delete' => 'delete user',
                        ],
                    ],
                    1002 => ['/user/roles/index' => 'Roles'],
                ],
            ];
        }
        
        // Добавление модуля pages
        if (!isset(\$config['modules']['pages'])) {
            \$config['modules']['pages'] = [
                'class' => 'ZakharovAndrew\\pages\\Module',
                'imageUploadPath' => '@webroot/uploads/pages',
                'imageUploadUrl' => '@web/uploads/pages',
            ];
        }
        
        // Добавление компонента telegram
        if (!isset(\$config['components']['telegram'])) {
            \$config['components']['telegram'] = [
                'class' => 'ZakharovAndrew\\user\\components\\Telegram',
                'token' => env('TELEGRAM_BOT_TOKEN', ''),
            ];
        }
        
        // Сохранение конфигурации
        file_put_contents(\$configFile, '<?php\n\nreturn ' . var_export(\$config, true) . ';\n');
    "
    
    if [ $? -eq 0 ]; then
        log_success "config/web.php успешно обновлен через PHP"
    else
        log_error "Ошибка при обновлении config/web.php"
        cp "$BACKUP_FILE" config/web.php
        exit 1
    fi
}

configure_database() {
    if [ "$SETUP_DB" = false ]; then
        log_info "Настройка БД пропущена"
        return 0
    fi
    
    log_step "Настройка базы данных"
    
    if [ "$INTERACTIVE" = true ]; then
        DB_HOST=$(prompt_input "Хост БД" "$DB_HOST")
        DB_PORT=$(prompt_input "Порт БД" "$DB_PORT")
        DB_NAME=$(prompt_input "Имя БД" "$DB_NAME")
        DB_USER=$(prompt_input "Пользователь БД" "$DB_USER")
        DB_PASSWORD=$(prompt_password "Пароль пользователя БД")
        ADMIN_PASSWORD=$(prompt_password "Пароль администратора ZaanCRM")
    elif [ -z "$DB_PASSWORD" ]; then
        DB_PASSWORD=$(openssl rand -base64 16 | tr -d "=+/" | cut -c1-12)
        ADMIN_PASSWORD=$(openssl rand -base64 16 | tr -d "=+/" | cut -c1-12)
        log_warn "Сгенерирован пароль БД: $DB_PASSWORD"
        log_warn "Сгенерирован пароль администратора: $ADMIN_PASSWORD"
        log_warn "Сохраните эти пароли!"
    fi
    
    cat > "config/db.php" <<EOF
<?php
return [
    'class' => 'yii\\db\\Connection',
    'dsn' => 'mysql:host=$DB_HOST;port=$DB_PORT;dbname=$DB_NAME',
    'username' => '$DB_USER',
    'password' => '$DB_PASSWORD',
    'charset' => 'utf8mb4',
    
    'enableSchemaCache' => '$ENV' === 'prod',
    'schemaCacheDuration' => 3600,
    'schemaCache' => 'cache',
    'enableQueryLog' => '$ENV' !== 'prod',
    'commandTimeout' => 30,
];
EOF
    
    log_success "Конфигурация БД сохранена"
}

setup_database() {
    log_step "Инициализация базы данных"
    
    if ! command -v mysql &> /dev/null; then
        log_warn "MySQL клиент не найден. Пропуск создания БД"
        return 0
    fi
    
    if prompt_yes_no "Создать базу данных '$DB_NAME'?" "yes"; then
        log_info "Создание базы данных и пользователя..."
        
        read -s -p "Введите пароль root MySQL: " MYSQL_ROOT_PASSWORD
        echo ""
        
        mysql -u root -p"$MYSQL_ROOT_PASSWORD" <<EOF
CREATE DATABASE IF NOT EXISTS \`$DB_NAME\` 
    CHARACTER SET utf8mb4 
    COLLATE utf8mb4_unicode_ci;

CREATE USER IF NOT EXISTS '$DB_USER'@'%' 
    IDENTIFIED BY '$DB_PASSWORD';

GRANT ALL PRIVILEGES ON \`$DB_NAME\`.* 
    TO '$DB_USER'@'%';

FLUSH PRIVILEGES;
EOF
        
        if [ $? -eq 0 ]; then
            log_success "База данных и пользователь созданы"
        else
            log_error "Ошибка создания БД"
        fi
    fi
}

run_migrations() {
    if [ "$RUN_MIGRATIONS" = false ]; then
        log_info "Миграции пропущены"
        return 0
    fi
    
    log_step "Выполнение миграций"
    
    # Миграции модуля пользователей
    log_info "Миграции модуля пользователей..."
    php yii migrate/up --migrationPath=@vendor/zakharov-andrew/yii2-user/migrations --interactive=0
    
    # Миграции модуля страниц
    log_info "Миграции модуля страниц..."
    php yii migrate/up --migrationPath=@vendor/zakharov-andrew/yii2-pages/migrations --interactive=0
    
    log_success "Миграции выполнены"
}

