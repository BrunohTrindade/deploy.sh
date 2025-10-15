#!/bin/bash
# ==========================================
# 🚀 DEPLOY AUTOMÁTICO APACHE v4.0 (REFATORADO)
# Autor: Bruno Trindade + GPT-5  
# Sistema: Ubuntu / Debian
# ==========================================
# curl -s https://raw.githubusercontent.com/BrunohTrindade/deploy.sh/refs/heads/main/deploy.sh | bash

set -euo pipefail  # Fail fast and fail hard

# ══════════════════════════════════════════════════════════════════════════════
# 🎨 CONFIGURAÇÕES E CONSTANTES
# ══════════════════════════════════════════════════════════════════════════════

# Carregar configurações do arquivo externo se existir
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)" 2>/dev/null || SCRIPT_DIR="/tmp"
CONFIG_FILE="$SCRIPT_DIR/deploy.config"

# Também verificar em locais padrão
if [[ ! -f "$CONFIG_FILE" ]]; then
    CONFIG_FILE="/etc/deploy-apache/deploy.config"
fi

if [[ -f "$CONFIG_FILE" ]]; then
    source "$CONFIG_FILE"
    echo "🔧 Configurações carregadas de: $CONFIG_FILE"
fi

# Cores e Emojis (configuráveis)
if [[ "${ENABLE_COLORS:-true}" == "true" ]]; then
    readonly GREEN=$(tput setaf 2)
    readonly YELLOW=$(tput setaf 3)
    readonly RED=$(tput setaf 1)
    readonly BLUE=$(tput setaf 4)
    readonly RESET=$(tput sgr0)
else
    readonly GREEN=""
    readonly YELLOW=""
    readonly RED=""
    readonly BLUE=""
    readonly RESET=""
fi

if [[ "${ENABLE_EMOJIS:-true}" == "true" ]]; then
    readonly CHECK="✅"
    readonly WARN="⚠️"
    readonly ERROR="❌"
else
    readonly CHECK="[OK]"
    readonly WARN="[WARN]"
    readonly ERROR="[ERROR]"
fi

# Configurações do sistema (configuráveis via deploy.config)
readonly APACHE_DIR="${APACHE_DIR:-/var/www}"
readonly PORTS_FILE="${PORTS_FILE:-/etc/apache2/ports.conf}"
readonly LOG_DIR="${LOG_DIR:-$HOME/deploy_logs}"
readonly SUPERVISOR_USER="${SUPERVISOR_USER:-www-data}"

# Variáveis globais do deploy
declare -g PROJECT_PATH=""
declare -g PROJECT_NAME=""
declare -g PROJECT_TYPE=""
declare -g DOC_ROOT=""
declare -g USE_PORT=false
declare -g PORT=""
declare -g DOMAIN=""
declare -g LOG_FILE=""

# Arrays para controle de rollback
declare -ag ROLLBACK_ACTIONS=()
declare -ag TEMP_FILES=()
declare -ag CREATED_CONFIGS=()

# ══════════════════════════════════════════════════════════════════════════════
# 🛠️ FUNÇÕES UTILITÁRIAS
# ══════════════════════════════════════════════════════════════════════════════

# Inicializar sistema de logs
setup_logging() {
    mkdir -p "$LOG_DIR"
    LOG_FILE="$LOG_DIR/deploy_$(date +%Y%m%d_%H%M%S).log"
    exec > >(tee -a "$LOG_FILE") 2>&1
    
    echo "📝 Log sendo salvo em: $LOG_FILE"
    echo "═══════════════════════════════════════════════════════════════════════════════"
}

# Exibir mensagens formatadas
log_info() { echo "${BLUE}ℹ️ $1${RESET}"; }
log_success() { echo "${GREEN}${CHECK} $1${RESET}"; }
log_warning() { echo "${YELLOW}${WARN} $1${RESET}"; }
log_error() { echo "${RED}${ERROR} $1${RESET}"; }

# Exibir seção
show_section() {
    local step="$1"
    local title="$2"
    echo ""
    echo "${BLUE}┌─────────────────────────────────────────────┐${RESET}"
    echo "${BLUE}│         $step $title         │${RESET}"
    echo "${BLUE}└─────────────────────────────────────────────┘${RESET}"
}

# Verificar se comando existe
command_exists() {
    command -v "$1" &>/dev/null
}

# Verificar se porta está em uso
is_port_in_use() {
    local port="$1"
    ss -tuln | grep -q ":$port "
}

# Encontrar porta livre
find_free_port() {
    local start_port=${1:-${PORT_RANGE_START:-8000}}
    local end_port=${2:-${PORT_RANGE_END:-9000}}
    
    for port in $(seq $start_port $end_port); do
        if ! is_port_in_use "$port"; then
            echo "$port"
            return 0
        fi
    done
    return 1
}

# Mostrar informações de logs e debug
show_log_info() {
    echo ""
    log_info "📋 Localização dos logs:"
    log_info "   • Log do deploy: ${LOG_FILE:-$LOG_DIR/deploy_YYYYMMDD_HHMMSS.log}"
    log_info "   • Logs do Apache: /var/log/apache2/"
    log_info "   • Para debug: tail -f \$LOG_FILE"
    echo ""
}

# Verificar se usuário tem privilégios sudo
check_sudo() {
    if ! sudo -n true 2>/dev/null; then
        log_error "Este script requer privilégios sudo"
        [[ -n "$LOG_FILE" ]] && log_error "Veja o log em: $LOG_FILE"
        exit 1
    fi
}

# ══════════════════════════════════════════════════════════════════════════════
# 🔄 SISTEMA DE ROLLBACK
# ══════════════════════════════════════════════════════════════════════════════

rollback_deploy() {
    echo ""
    echo "${RED}╔═══════════════════════════════════════════════╗${RESET}"
    echo "${RED}║              ⚠️ INICIANDO ROLLBACK ⚠️        ║${RESET}"
    echo "${RED}╚═══════════════════════════════════════════════╝${RESET}"
    
    # Desabilitar sites Apache criados
    for config in "${CREATED_CONFIGS[@]}"; do
        log_warning "Desabilitando site: $config"
        sudo a2dissite "$config" 2>/dev/null || true
        
        local config_path="/etc/apache2/sites-available/$config"
        if [[ -f "$config_path" ]]; then
            log_warning "Removendo configuração: $config_path"
            sudo rm -f "$config_path"
        fi
    done
    
    # Remover arquivos temporários
    for temp_file in "${TEMP_FILES[@]}"; do
        if [[ -f "$temp_file" ]]; then
            log_warning "Removendo arquivo temporário: $temp_file"
            rm -f "$temp_file"
        fi
    done
    
    # Remover Listen das portas adicionadas
    for action in "${ROLLBACK_ACTIONS[@]}"; do
        if [[ "$action" == "port:"* ]]; then
            local port=$(echo "$action" | cut -d: -f2)
            log_warning "Removendo Listen $port do ports.conf"
            sudo sed -i "/^Listen $port$/d" "$PORTS_FILE" 2>/dev/null || true
        fi
    done
    
    # Recarregar Apache
    log_warning "Recarregando Apache..."
    sudo systemctl reload apache2 2>/dev/null || true
    
    log_error "Rollback concluído. Deploy foi revertido."
    echo ""
    log_info "📋 Para debug, consulte os logs:"
    [[ -n "$LOG_FILE" ]] && log_info "   • Log do deploy: $LOG_FILE"
    log_info "   • Log do Apache: /var/log/apache2/error.log"
    exit 1
}

# ══════════════════════════════════════════════════════════════════════════════
# 📂 FUNÇÕES DE CONFIGURAÇÃO DE FONTE
# ══════════════════════════════════════════════════════════════════════════════

get_project_source() {
    show_section "📂 [1/10]" "FONTE DO PROJETO"
    log_info "Escolha de onde vem seu projeto:"
    echo ""
    
    local options=("📁 Diretório local" "🌐 Git Clone")
    select source_type in "${options[@]}"; do
        case $source_type in
            "📁 Diretório local")
                get_local_project
                break
                ;;
            "🌐 Git Clone")
                get_git_project
                break
                ;;
            *)
                log_error "Escolha inválida."
                ;;
        esac
    done < /dev/tty
}

get_local_project() {
    log_success "Você escolheu: Diretório local"
    while true; do
        read -p "${BLUE}💭 Digite o caminho completo do projeto: ${RESET}" PROJECT_PATH
        
        if [[ -z "$PROJECT_PATH" ]]; then
            log_error "Caminho não pode estar vazio!"
            continue
        fi
        
        if [[ ! -d "$PROJECT_PATH" ]]; then
            log_error "Diretório não encontrado: $PROJECT_PATH"
            continue
        fi
        
        PROJECT_NAME=$(basename "$PROJECT_PATH")
        break
    done
}

get_git_project() {
    log_success "Você escolheu: Git Clone"
    while true; do
        read -p "${BLUE}💭 Digite o link do repositório Git: ${RESET}" GIT_LINK
        
        if [[ -z "$GIT_LINK" ]]; then
            log_error "Link do repositório não pode estar vazio!"
            continue
        fi
        
        PROJECT_NAME=$(basename "$GIT_LINK" .git)
        PROJECT_PATH="$APACHE_DIR/$PROJECT_NAME"
        
        log_info "Clonando repositório..."
        if git clone "$GIT_LINK" "$PROJECT_PATH"; then
            log_success "Repositório clonado com sucesso!"
            break
        else
            log_error "Falha ao clonar repositório"
            continue
        fi
    done
}

# ══════════════════════════════════════════════════════════════════════════════
# 🔒 FUNÇÕES DE PERMISSÕES
# ══════════════════════════════════════════════════════════════════════════════

setup_permissions() {
    show_section "🔒 [3/10]" "AJUSTAR PERMISSÕES"
    log_info "Configurando permissões de segurança..."
    
    if [[ ! -d "$PROJECT_PATH" ]]; then
        log_error "Caminho $PROJECT_PATH não encontrado."
        return 1
    fi
    
    sudo chown -R "$SUPERVISOR_USER":www-data "$PROJECT_PATH"
    sudo chmod -R 775 "$PROJECT_PATH"
    log_success "Permissões ajustadas para $SUPERVISOR_USER (owner) e www-data (group)"
}

# ══════════════════════════════════════════════════════════════════════════════
# 🚀 FUNÇÕES DE CONFIGURAÇÃO DE PROJETO
# ══════════════════════════════════════════════════════════════════════════════

get_project_type() {
    show_section "🚀 [4/10]" "TIPO DE PROJETO"
    
    # Tentativa de detecção automática
    local detected_type=$(detect_project_type)
    if [[ -n "$detected_type" ]]; then
        log_info "Tipo de projeto detectado automaticamente: $detected_type"
        read -p "${YELLOW}Usar detecção automática? (s/N): ${RESET}" use_detected < /dev/tty
        if [[ "$use_detected" =~ ^[Ss]$ ]]; then
            PROJECT_TYPE="$detected_type"
            return 0
        fi
    fi
    
    log_info "Selecione o tipo do seu projeto:"
    echo ""
    
    local options=("⚡ Laravel" "🌟 Vue" "🟢 Node.js" "🐍 Python" "📄 HTML/PHP Simples")
    select project_type in "${options[@]}"; do
        case $project_type in
            "⚡ Laravel"|"🌟 Vue"|"🟢 Node.js"|"🐍 Python"|"📄 HTML/PHP Simples")
                PROJECT_TYPE="$project_type"
                break
                ;;
            *)
                log_error "Escolha inválida."
                ;;
        esac
    done < /dev/tty
}

detect_project_type() {
    if [[ -f "$PROJECT_PATH/composer.json" ]] && grep -q "laravel" "$PROJECT_PATH/composer.json"; then
        echo "⚡ Laravel"
    elif [[ -f "$PROJECT_PATH/package.json" ]] && grep -q "vue" "$PROJECT_PATH/package.json"; then
        echo "🌟 Vue"
    elif [[ -f "$PROJECT_PATH/package.json" ]]; then
        echo "🟢 Node.js"
    elif [[ -f "$PROJECT_PATH/requirements.txt" ]] || [[ -f "$PROJECT_PATH/setup.py" ]]; then
        echo "🐍 Python"
    elif [[ -f "$PROJECT_PATH/index.php" ]] || [[ -f "$PROJECT_PATH/index.html" ]]; then
        echo "📄 HTML/PHP Simples"
    fi
}

set_document_root() {
    local project_key
    case $PROJECT_TYPE in
        "⚡ Laravel") project_key="Laravel" ;;
        "🌟 Vue") project_key="Vue" ;;
        "🟢 Node.js") project_key="Node.js" ;;
        "🐍 Python") project_key="Python" ;;
        *) project_key="HTML" ;;
    esac
    
    # Usar configuração do arquivo deploy.config se disponível
    # Verificar se o array PROJECT_DOC_ROOTS está declarado e tem a chave
    if declare -p PROJECT_DOC_ROOTS &>/dev/null && [[ -n "${PROJECT_DOC_ROOTS[$project_key]:-}" ]]; then
        DOC_ROOT="${PROJECT_PATH}/${PROJECT_DOC_ROOTS[$project_key]}"
    else
        # Fallback para configuração padrão
        case $PROJECT_TYPE in
            "⚡ Laravel") DOC_ROOT="${PROJECT_PATH}/public" ;;
            "🌟 Vue") DOC_ROOT="${PROJECT_PATH}/dist" ;;
            *) DOC_ROOT="${PROJECT_PATH}" ;;
        esac
    fi
}

# ══════════════════════════════════════════════════════════════════════════════
# 🌐 FUNÇÕES DE CONFIGURAÇÃO DE ACESSO
# ══════════════════════════════════════════════════════════════════════════════

get_access_type() {
    show_section "🌐 [5/10]" "TIPO DE ACESSO"
    log_info "Como você quer acessar seu projeto?"
    echo ""
    
    local options=("🌍 Domínio" "🔌 Porta")
    select access_type in "${options[@]}"; do
        case $access_type in
            "🌍 Domínio")
                setup_domain_access
                break
                ;;
            "🔌 Porta")
                setup_port_access
                break
                ;;
            *)
                log_error "Escolha inválida."
                ;;
        esac
    done < /dev/tty
}

setup_domain_access() {
    log_success "Você escolheu: Acesso por domínio"
    while true; do
        read -p "${BLUE}💭 Digite o domínio (ex: exemplo.com): ${RESET}" DOMAIN
        
        if [[ -z "$DOMAIN" ]]; then
            log_error "Domínio não pode estar vazio!"
            continue
        fi
        
        # Validação básica de domínio
        if [[ ! "$DOMAIN" =~ ^[a-zA-Z0-9][a-zA-Z0-9.-]*[a-zA-Z0-9]$ ]]; then
            log_error "Formato de domínio inválido!"
            continue
        fi
        
        USE_PORT=false
        break
    done
}

setup_port_access() {
    log_success "Você escolheu: Acesso por porta"
    USE_PORT=true
    
    log_info "Verificando portas disponíveis..."
    local suggested_port=$(find_free_port 8000 9000)
    
    if [[ -z "$suggested_port" ]]; then
        log_error "Não foi possível encontrar uma porta livre entre 8000-9000"
        exit 1
    fi
    
    log_success "Porta sugerida livre: $suggested_port"
    
    while true; do
        read -p "${BLUE}💭 Digite a porta desejada (padrão $suggested_port): ${RESET}" CUSTOM_PORT
        PORT=${CUSTOM_PORT:-$suggested_port}
        
        if ! [[ "$PORT" =~ ^[0-9]+$ ]] || [[ "$PORT" -lt 1024 ]] || [[ "$PORT" -gt 65535 ]]; then
            log_error "Porta deve ser um número entre 1024 e 65535!"
            continue
        fi
        
        if is_port_in_use "$PORT"; then
            log_error "Porta $PORT já está em uso!"
            continue
        fi
        
        break
    done
}

# ══════════════════════════════════════════════════════════════════════════════
# 📋 FUNÇÕES DE VERIFICAÇÃO
# ══════════════════════════════════════════════════════════════════════════════

verify_project_structure() {
    show_section "📋 [6/10]" "VERIFICAR ESTRUTURA"
    log_info "Verificando arquivo inicial do projeto..."
    
    # Usar configuração dos arquivos índice se disponível
    local index_files
    if declare -p INDEX_FILES &>/dev/null; then
        index_files=("${INDEX_FILES[@]}")
    else
        index_files=("index.php" "index.html" "app.js" "main.py")
    fi
    local found=false
    
    for file in "${index_files[@]}"; do
        if [[ -f "$DOC_ROOT/$file" ]]; then
            log_success "Arquivo inicial encontrado: $DOC_ROOT/$file"
            found=true
            break
        fi
    done
    
    if [[ "$found" == false ]]; then
        log_warning "Nenhum arquivo inicial encontrado em $DOC_ROOT"
        read -p "${YELLOW}❓ Deseja continuar mesmo assim? (s/N): ${RESET}" CONTINUE < /dev/tty
        if [[ ! "$CONTINUE" =~ ^[Ss]$ ]]; then
            log_error "Deploy cancelado pelo usuário"
            exit 1
        fi
    fi
}

# ══════════════════════════════════════════════════════════════════════════════
# ⚙️ FUNÇÕES DE CONFIGURAÇÃO DO APACHE
# ══════════════════════════════════════════════════════════════════════════════

configure_apache() {
    show_section "⚙️ [7/10]" "CONFIGURAR APACHE"
    log_info "Criando VirtualHost Apache..."
    
    setup_apache_ports
    create_virtual_host
    enable_apache_modules
    enable_site
}

setup_apache_ports() {
    local target_port
    if [[ "$USE_PORT" == true ]]; then
        target_port="$PORT"
        ROLLBACK_ACTIONS+=("port:$PORT")
    else
        target_port="80"
    fi
    
    if ! sudo grep -qE "^\s*Listen\s+$target_port\b" "$PORTS_FILE"; then
        echo "Listen $target_port" | sudo tee -a "$PORTS_FILE" >/dev/null
        log_success "Porta $target_port adicionada ao Apache"
    fi
}

create_virtual_host() {
    local port_line server_name
    
    if [[ "$USE_PORT" == true ]]; then
        port_line=":$PORT"
        server_name="localhost"
    else
        port_line=":80"
        server_name="$DOMAIN"
    fi
    
    local conf_path="/etc/apache2/sites-available/${PROJECT_NAME}.conf"
    
    # Gerar configuração do VirtualHost
    local vhost_config="<VirtualHost *${port_line}>
    ServerAdmin webmaster@${server_name}
    ServerName ${server_name}
    DocumentRoot ${DOC_ROOT}

    <Directory ${DOC_ROOT}>
        AllowOverride All
        Require all granted
        Options Indexes FollowSymLinks
    </Directory>"

    # Adicionar headers de segurança se configurados
    if declare -p SECURITY_HEADERS &>/dev/null && [[ ${#SECURITY_HEADERS[@]} -gt 0 ]]; then
        vhost_config+="\n\n    # Security headers"
        for header in "${SECURITY_HEADERS[@]}"; do
            vhost_config+="\n    $header"
        done
    else
        # Headers padrão
        vhost_config+="\n\n    # Security headers
    Header always set X-Content-Type-Options nosniff
    Header always set X-Frame-Options DENY
    Header always set X-XSS-Protection \"1; mode=block\""
    fi

    # Logs
    vhost_config+="\n\n    # Logs
    ErrorLog \${APACHE_LOG_DIR}/${PROJECT_NAME}_error.log
    CustomLog \${APACHE_LOG_DIR}/${PROJECT_NAME}_access.log combined
    LogLevel ${APACHE_LOG_LEVEL:-warn}"

    # Compressão se habilitada
    if [[ "${ENABLE_COMPRESSION:-true}" == "true" ]]; then
        vhost_config+="\n\n    # Compression
    <IfModule mod_deflate.c>"
        
        if declare -p COMPRESSION_TYPES &>/dev/null && [[ ${#COMPRESSION_TYPES[@]} -gt 0 ]]; then
            for mime_type in "${COMPRESSION_TYPES[@]}"; do
                vhost_config+="\n        AddOutputFilterByType DEFLATE $mime_type"
            done
        else
            # Tipos padrão
            vhost_config+="\n        AddOutputFilterByType DEFLATE text/plain
        AddOutputFilterByType DEFLATE text/html
        AddOutputFilterByType DEFLATE text/css
        AddOutputFilterByType DEFLATE application/javascript"
        fi
        
        vhost_config+="\n    </IfModule>"
    fi

    # Cache de arquivos estáticos se habilitado
    if [[ "${ENABLE_STATIC_CACHE:-true}" == "true" ]]; then
        local cache_time="${STATIC_CACHE_TIME:-2592000}"
        vhost_config+="\n\n    # Static file caching
    <IfModule mod_expires.c>
        ExpiresActive On
        ExpiresByType image/jpg \"access plus $cache_time seconds\"
        ExpiresByType image/jpeg \"access plus $cache_time seconds\"
        ExpiresByType image/gif \"access plus $cache_time seconds\"
        ExpiresByType image/png \"access plus $cache_time seconds\"
        ExpiresByType text/css \"access plus $cache_time seconds\"
        ExpiresByType application/pdf \"access plus $cache_time seconds\"
        ExpiresByType application/javascript \"access plus $cache_time seconds\"
        ExpiresByType application/x-javascript \"access plus $cache_time seconds\"
    </IfModule>"
    fi

    vhost_config+="\n</VirtualHost>"

    # Escrever configuração no arquivo
    echo -e "$vhost_config" | sudo tee "$conf_path" > /dev/null

    CREATED_CONFIGS+=("${PROJECT_NAME}.conf")
    log_success "VirtualHost criado: $conf_path"
}

enable_apache_modules() {
    # Usar configuração dos módulos se disponível
    local modules
    if declare -p APACHE_MODULES &>/dev/null; then
        modules=("${APACHE_MODULES[@]}")
    else
        modules=("rewrite" "proxy" "proxy_http" "headers" "ssl" "deflate")
    fi
    for module in "${modules[@]}"; do
        if sudo a2enmod "$module" >/dev/null 2>&1; then
            [[ "${VERBOSITY:-normal}" == "verbose" ]] && log_info "Módulo $module habilitado"
        fi
    done
    log_success "Módulos Apache habilitados"
}

enable_site() {
    sudo a2ensite "${PROJECT_NAME}.conf" >/dev/null 2>&1
    log_success "Site ${PROJECT_NAME}.conf habilitado"
}

# ══════════════════════════════════════════════════════════════════════════════
# 📦 FUNÇÕES DE INSTALAÇÃO DE DEPENDÊNCIAS
# ══════════════════════════════════════════════════════════════════════════════

install_dependencies() {
    show_section "📦 [8/10]" "INSTALAR DEPENDÊNCIAS"
    log_info "Instalando dependências do projeto..."
    
    cd "$PROJECT_PATH" || exit 1
    
    case $PROJECT_TYPE in
        "⚡ Laravel")
            install_laravel_dependencies
            ;;
        "🌟 Vue"|"🟢 Node.js")
            install_node_dependencies
            ;;
        "🐍 Python")
            install_python_dependencies
            ;;
        *)
            log_info "Projeto HTML/PHP - Nenhuma dependência a instalar"
            ;;
    esac
}

install_laravel_dependencies() {
    log_info "Processando projeto Laravel..."
    
    verify_php_requirements
    install_composer
    install_composer_packages
    configure_laravel_env
    optimize_laravel
}

verify_php_requirements() {
    if ! command_exists php; then
        log_error "PHP não encontrado no sistema!"
        log_info "Instale PHP manualmente: sudo apt install php php-cli php-mysql php-mbstring php-xml php-zip"
        exit 1
    fi
    
    local php_version=$(php -r "echo PHP_VERSION;")
    log_success "PHP $php_version detectado"
    
    # Verificar extensões essenciais usando configuração
    local required_extensions
    if declare -p PHP_EXTENSIONS &>/dev/null; then
        required_extensions=("${PHP_EXTENSIONS[@]}")
    else
        required_extensions=("mbstring" "xml" "ctype" "json" "bcmath" "openssl" "pdo" "tokenizer")
    fi
    local missing_extensions=()
    
    for ext in "${required_extensions[@]}"; do
        if ! php -m | grep -q "$ext"; then
            missing_extensions+=("$ext")
            log_warning "Extensão PHP '$ext' não encontrada"
        else
            [[ "${VERBOSITY:-normal}" == "verbose" ]] && log_success "Extensão PHP '$ext' encontrada"
        fi
    done
    
    if [[ ${#missing_extensions[@]} -gt 0 ]]; then
        log_warning "Extensões faltando: ${missing_extensions[*]}"
        log_info "Instale com: sudo apt install $(printf 'php-%s ' "${missing_extensions[@]}")"
    fi
}

install_composer() {
    if ! command_exists composer; then
        log_info "Instalando Composer..."
        
        local temp_dir=$(mktemp -d)
        cd "$temp_dir" || exit 1
        
        local installer_url="${COMPOSER_INSTALLER_URL:-https://getcomposer.org/installer}"
        local timeout="${NETWORK_TIMEOUT:-30}"
        
        if curl -sS --connect-timeout "$timeout" "$installer_url" -o composer-setup.php; then
            sudo php composer-setup.php --install-dir=/usr/local/bin --filename=composer
            rm composer-setup.php
            
            cd "$PROJECT_PATH" || exit 1
            
            if command_exists composer; then
                log_success "Composer instalado com sucesso!"
            else
                log_error "Falha ao instalar Composer"
                exit 1
            fi
        else
            log_error "Falha ao baixar o instalador do Composer"
            exit 1
        fi
    else
        log_success "Composer já está instalado"
    fi
}

install_composer_packages() {
    if [[ ! -f "composer.json" ]]; then
        log_error "Arquivo composer.json não encontrado!"
        return 1
    fi
    
    # Configurar Git safety
    git config --global --add safe.directory "$PROJECT_PATH" 2>/dev/null || true
    
    # Ajustar permissões
    sudo chown -R "$SUPERVISOR_USER":www-data "$PROJECT_PATH"
    
    # Instalar dependências
    log_info "Instalando dependências do Composer..."
    if sudo -u "$SUPERVISOR_USER" COMPOSER_ALLOW_SUPERUSER=1 composer install --no-interaction --prefer-dist --optimize-autoloader --no-dev; then
        log_success "Dependências do Composer instaladas!"
    else
        log_warning "Tentando com composer update..."
        sudo -u "$SUPERVISOR_USER" COMPOSER_ALLOW_SUPERUSER=1 composer update --no-interaction --prefer-dist --optimize-autoloader --no-dev
    fi
}

configure_laravel_env() {
    if [[ ! -f .env ]]; then
        if [[ -f .env.example ]]; then
            cp .env.example .env
            log_success "Arquivo .env criado a partir do .env.example"
        else
            create_basic_env_file
        fi
    else
        log_success "Arquivo .env já existe"
    fi
    
    # Ajustar permissões
    sudo chown "$SUPERVISOR_USER":www-data .env
    sudo chmod 640 .env
    
    # Gerar chave da aplicação
    log_info "Gerando chave da aplicação..."
    sudo -u "$SUPERVISOR_USER" php artisan key:generate --force
    log_success "Chave da aplicação gerada!"
}

create_basic_env_file() {
    cat > .env << 'EOF'
APP_NAME=Laravel
APP_ENV=production
APP_KEY=
APP_DEBUG=false
APP_URL=http://localhost

LOG_CHANNEL=stack
LOG_LEVEL=error

DB_CONNECTION=sqlite
DB_DATABASE=database/database.sqlite

CACHE_DRIVER=file
QUEUE_CONNECTION=sync
SESSION_DRIVER=file
SESSION_LIFETIME=120
EOF
    log_success "Arquivo .env básico criado"
}

optimize_laravel() {
    log_info "Otimizando cache para produção..."
    sudo -u "$SUPERVISOR_USER" php artisan config:cache 2>/dev/null || true
    sudo -u "$SUPERVISOR_USER" php artisan route:cache 2>/dev/null || true
    sudo -u "$SUPERVISOR_USER" php artisan view:cache 2>/dev/null || true
    log_success "Cache otimizado!"
}

install_node_dependencies() {
    log_info "Processando projeto ${PROJECT_TYPE}..."
    
    if ! command_exists npm; then
        log_info "Instalando Node.js..."
        curl -fsSL https://deb.nodesource.com/setup_lts.x | sudo -E bash -
        sudo apt-get install -y nodejs
        
        if command_exists npm; then
            log_success "Node.js e NPM instalados!"
        else
            log_error "Falha ao instalar Node.js/NPM"
            return 1
        fi
    else
        log_success "NPM já está instalado"
    fi
    
    if [[ -f "package.json" ]]; then
        log_info "Instalando dependências do NPM..."
        sudo -u "$SUPERVISOR_USER" npm install
        
        if [[ "$PROJECT_TYPE" == *"Vue"* ]]; then
            log_info "Fazendo build do projeto Vue..."
            sudo -u "$SUPERVISOR_USER" npm run build
        fi
        log_success "Dependências do NPM instaladas!"
    else
        log_warning "package.json não encontrado"
    fi
}

install_python_dependencies() {
    log_info "Processando projeto Python..."
    
    if [[ -f "requirements.txt" ]]; then
        local pip_cmd=""
        if command_exists pip3; then
            pip_cmd="pip3"
        elif command_exists pip; then
            pip_cmd="pip"
        else
            log_info "Instalando pip..."
            sudo apt update
            sudo apt install -y python3-pip
            pip_cmd="pip3"
        fi
        
        log_info "Instalando dependências do Python..."
        sudo -u "$SUPERVISOR_USER" $pip_cmd install -r requirements.txt
        log_success "Dependências do Python instaladas!"
    else
        log_warning "Arquivo requirements.txt não encontrado"
    fi
}

# ══════════════════════════════════════════════════════════════════════════════
# 🔄 FUNÇÃO PRINCIPAL E FINALIZAÇÃO
# ══════════════════════════════════════════════════════════════════════════════

finalize_deploy() {
    show_section "🔄 [10/10]" "FINALIZAR DEPLOY"
    log_info "Recarregando Apache..."
    sudo systemctl reload apache2
    
    # Desabilitar trap de erro - deploy concluído
    trap - ERR
    
    show_success_message
}

show_success_message() {
    local access_url
    if [[ "$USE_PORT" == true ]]; then
        access_url="http://localhost:$PORT"
    else
        access_url="https://$DOMAIN"
    fi
    
    echo ""
    echo "${GREEN}╔═══════════════════════════════════════════════╗${RESET}"
    echo "${GREEN}║              🎉 DEPLOY CONCLUÍDO! 🎉          ║${RESET}"
    echo "${GREEN}╠═══════════════════════════════════════════════╣${RESET}"
    echo "${GREEN}║ ${BLUE}📦 Projeto: ${YELLOW}$PROJECT_NAME${GREEN}                    ║${RESET}"
    echo "${GREEN}║ ${BLUE}🌐 Acesso: ${YELLOW}$access_url${GREEN}              ║${RESET}"
    echo "${GREEN}║ ${BLUE}📅 Deploy: ${YELLOW}$(date '+%d/%m/%Y %H:%M:%S')${GREEN}         ║${RESET}"
    echo "${GREEN}║ ${BLUE}📝 Log: ${YELLOW}$LOG_FILE${GREEN}     ║${RESET}"
    echo "${GREEN}╚═══════════════════════════════════════════════╝${RESET}"
    echo ""
    log_success "Seu projeto está online e funcionando!"
    echo ""
    log_info "📋 Informações importantes:"
    log_info "   • Log completo: $LOG_FILE"
    log_info "   • Log do Apache: /var/log/apache2/${PROJECT_NAME}_error.log"
    log_info "   • Para ver logs em tempo real: tail -f $LOG_FILE"
}

show_header() {
    echo "${BLUE}==========================================${RESET}"
    echo "${GREEN}      🚀 DEPLOY AUTOMÁTICO APACHE v4.0${RESET}"
    echo "${BLUE}==========================================${RESET}"
    echo ""
}

# ══════════════════════════════════════════════════════════════════════════════
# 🚀 FUNÇÃO PRINCIPAL
# ══════════════════════════════════════════════════════════════════════════════

main() {
    # Configuração inicial
    setup_logging
    check_sudo
    
    # Configurar trap para rollback em caso de erro
    trap 'rollback_deploy' ERR
    
    # Exibir cabeçalho
    show_header
    
    # Fluxo principal do deploy
    get_project_source
    show_section "👤 [2/10]" "USUÁRIO SUPERVISOR"
    log_success "Usuário supervisor detectado: $SUPERVISOR_USER"
    
    setup_permissions
    get_project_type
    set_document_root
    get_access_type
    verify_project_structure
    configure_apache
    install_dependencies
    finalize_deploy
}

# Executar função principal
main "$@"