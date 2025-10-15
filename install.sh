#!/bin/bash
# ==========================================
# 🚀 INSTALADOR DO DEPLOY AUTOMÁTICO v4.0 
# ==========================================

set -euo pipefail

# Cores
readonly GREEN=$(tput setaf 2)
readonly YELLOW=$(tput setaf 3)
readonly RED=$(tput setaf 1)
readonly BLUE=$(tput setaf 4)
readonly RESET=$(tput sgr0)

# URLs dos arquivos
readonly SCRIPT_URL="https://raw.githubusercontent.com/BrunohTrindade/deploy.sh/refs/heads/main/deploy-refatorado.sh"
readonly CONFIG_URL="https://raw.githubusercontent.com/BrunohTrindade/deploy.sh/refs/heads/main/deploy.config"

# Diretório de instalação
readonly INSTALL_DIR="/usr/local/bin"
readonly CONFIG_DIR="/etc/deploy-apache"

show_header() {
    echo ""
    echo "${BLUE}╔══════════════════════════════════════════════════════════╗${RESET}"
    echo "${BLUE}║       🚀 INSTALADOR DEPLOY AUTOMÁTICO APACHE v4.0       ║${RESET}"
    echo "${BLUE}╚══════════════════════════════════════════════════════════╝${RESET}"
    echo ""
}

log_info() { echo "${BLUE}ℹ️ $1${RESET}"; }
log_success() { echo "${GREEN}✅ $1${RESET}"; }
log_warning() { echo "${YELLOW}⚠️ $1${RESET}"; }
log_error() { echo "${RED}❌ $1${RESET}"; }

check_requirements() {
    log_info "Verificando requisitos do sistema..."
    
    # Verificar se tem privilégios sudo
    if ! sudo -n true 2>/dev/null; then
        log_error "Este instalador requer privilégios sudo"
        exit 1
    fi
    
    # Verificar curl
    if ! command -v curl &>/dev/null; then
        log_error "curl não encontrado. Instale com: sudo apt install curl"
        exit 1
    fi
    
    log_success "Requisitos verificados"
}

install_script() {
    log_info "Baixando script principal..."
    
    if sudo curl -sL "$SCRIPT_URL" -o "$INSTALL_DIR/deploy-apache"; then
        sudo chmod +x "$INSTALL_DIR/deploy-apache"
        log_success "Script instalado em: $INSTALL_DIR/deploy-apache"
    else
        log_error "Falha ao baixar o script principal"
        exit 1
    fi
}

install_config() {
    log_info "Configurando arquivo de configuração..."
    
    # Criar diretório de configuração
    sudo mkdir -p "$CONFIG_DIR"
    
    if sudo curl -sL "$CONFIG_URL" -o "$CONFIG_DIR/deploy.config"; then
        sudo chmod 644 "$CONFIG_DIR/deploy.config"
        log_success "Configuração instalada em: $CONFIG_DIR/deploy.config"
    else
        log_warning "Falha ao baixar arquivo de configuração (opcional)"
    fi
}

update_script() {
    log_info "Criando script de atualização do deploy.config..."
    
    sudo tee "$INSTALL_DIR/deploy-apache-config" > /dev/null << 'EOF'
#!/bin/bash
# Script para editar configurações do deploy

CONFIG_FILE="/etc/deploy-apache/deploy.config"

if [[ ! -f "$CONFIG_FILE" ]]; then
    echo "❌ Arquivo de configuração não encontrado: $CONFIG_FILE"
    exit 1
fi

if command -v nano &>/dev/null; then
    sudo nano "$CONFIG_FILE"
elif command -v vim &>/dev/null; then
    sudo vim "$CONFIG_file"
else
    echo "❌ Editor de texto não encontrado (nano/vim)"
    exit 1
fi

echo "✅ Configurações atualizadas!"
EOF
    
    sudo chmod +x "$INSTALL_DIR/deploy-apache-config"
    log_success "Script de configuração criado: deploy-apache-config"
}

create_wrapper() {
    log_info "Criando wrapper script..."
    
    sudo tee "$INSTALL_DIR/deploy-apache-wrapper" > /dev/null << EOF
#!/bin/bash
# Wrapper para o deploy automático Apache

SCRIPT_DIR="\$(dirname "\$0")"
CONFIG_FILE="/etc/deploy-apache/deploy.config"

# Exportar caminho do arquivo de configuração
export DEPLOY_CONFIG_FILE="\$CONFIG_FILE"

# Executar script principal
exec "\$SCRIPT_DIR/deploy-apache" "\$@"
EOF
    
    sudo chmod +x "$INSTALL_DIR/deploy-apache-wrapper"
    log_success "Wrapper criado: deploy-apache-wrapper"
}

show_completion() {
    echo ""
    echo "${GREEN}╔══════════════════════════════════════════════════════════╗${RESET}"
    echo "${GREEN}║              🎉 INSTALAÇÃO CONCLUÍDA! 🎉                ║${RESET}"
    echo "${GREEN}╚══════════════════════════════════════════════════════════╝${RESET}"
    echo ""
    echo "${BLUE}📋 Comandos disponíveis:${RESET}"
    echo "${YELLOW}   deploy-apache${RESET}         - Executar deploy automático"
    echo "${YELLOW}   deploy-apache-config${RESET}  - Editar configurações"
    echo ""
    echo "${BLUE}📁 Arquivos instalados:${RESET}"
    echo "${YELLOW}   $INSTALL_DIR/deploy-apache${RESET}"
    echo "${YELLOW}   $CONFIG_DIR/deploy.config${RESET}"
    echo ""
    echo "${BLUE}🚀 Para começar, execute:${RESET}"
    echo "${YELLOW}   sudo deploy-apache${RESET}"
    echo ""
}

uninstall() {
    log_info "Removendo deploy automático..."
    
    sudo rm -f "$INSTALL_DIR/deploy-apache"
    sudo rm -f "$INSTALL_DIR/deploy-apache-config"
    sudo rm -f "$INSTALL_DIR/deploy-apache-wrapper"
    sudo rm -rf "$CONFIG_DIR"
    
    log_success "Deploy automático removido!"
}

main() {
    show_header
    
    # Verificar se é desinstalação
    if [[ "${1:-}" == "--uninstall" ]]; then
        uninstall
        exit 0
    fi
    
    # Verificar se já está instalado
    if [[ -f "$INSTALL_DIR/deploy-apache" ]]; then
        log_warning "Deploy automático já está instalado!"
        read -p "Deseja atualizar? (s/N): " update
        if [[ ! "$update" =~ ^[Ss]$ ]]; then
            log_info "Instalação cancelada"
            exit 0
        fi
    fi
    
    check_requirements
    install_script
    install_config
    update_script
    create_wrapper
    show_completion
}

# Mostrar ajuda
if [[ "${1:-}" == "--help" ]] || [[ "${1:-}" == "-h" ]]; then
    echo "🚀 Instalador do Deploy Automático Apache v4.0"
    echo ""
    echo "Uso:"
    echo "  $0              - Instalar/atualizar"
    echo "  $0 --uninstall  - Desinstalar"
    echo "  $0 --help       - Mostrar esta ajuda"
    echo ""
    exit 0
fi

main "$@"