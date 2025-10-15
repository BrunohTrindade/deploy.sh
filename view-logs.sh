#!/bin/bash
# ==========================================
# 📋 VISUALIZADOR DE LOGS DO DEPLOY
# ==========================================

# Cores
readonly GREEN=$(tput setaf 2)
readonly YELLOW=$(tput setaf 3)
readonly RED=$(tput setaf 1)
readonly BLUE=$(tput setaf 4)
readonly RESET=$(tput sgr0)

log_info() { echo "${BLUE}ℹ️ $1${RESET}"; }
log_success() { echo "${GREEN}✅ $1${RESET}"; }
log_warning() { echo "${YELLOW}⚠️ $1${RESET}"; }
log_error() { echo "${RED}❌ $1${RESET}"; }

show_header() {
    echo "${BLUE}════════════════════════════════════════${RESET}"
    echo "${GREEN}  📋 LOGS DO DEPLOY AUTOMÁTICO APACHE  ${RESET}"
    echo "${BLUE}════════════════════════════════════════${RESET}"
    echo ""
}

show_deploy_logs() {
    local log_dir="$HOME/deploy_logs"
    
    if [[ ! -d "$log_dir" ]]; then
        log_error "Diretório de logs não encontrado: $log_dir"
        return 1
    fi
    
    local log_files=("$log_dir"/deploy_*.log)
    
    if [[ ! -f "${log_files[0]}" ]]; then
        log_warning "Nenhum log de deploy encontrado em: $log_dir"
        return 1
    fi
    
    log_info "📁 Logs de deploy disponíveis:"
    echo ""
    
    local count=1
    for log_file in "${log_files[@]}"; do
        local basename_file=$(basename "$log_file")
        local file_date=$(echo "$basename_file" | sed 's/deploy_\([0-9]\{8\}\)_\([0-9]\{6\}\).log/\1 \2/' | sed 's/\([0-9]\{4\}\)\([0-9]\{2\}\)\([0-9]\{2\}\) \([0-9]\{2\}\)\([0-9]\{2\}\)\([0-9]\{2\}\)/\3\/\2\/\1 \4:\5:\6/')
        local file_size=$(du -h "$log_file" 2>/dev/null | cut -f1)
        
        echo "${YELLOW}[$count]${RESET} $basename_file"
        echo "    📅 Data: $file_date"
        echo "    📏 Tamanho: $file_size"
        echo "    📂 Caminho: $log_file"
        echo ""
        ((count++))
    done
}

show_apache_logs() {
    log_info "📁 Logs do Apache disponíveis:"
    echo ""
    
    local apache_log_dir="/var/log/apache2"
    
    if [[ -d "$apache_log_dir" ]]; then
        local error_logs=("$apache_log_dir"/*error.log)
        local access_logs=("$apache_log_dir"/*access.log)
        
        echo "${YELLOW}📛 Logs de Erro:${RESET}"
        for log_file in "${error_logs[@]}"; do
            if [[ -f "$log_file" ]]; then
                local file_size=$(du -h "$log_file" 2>/dev/null | cut -f1)
                echo "   • $(basename "$log_file") ($file_size)"
            fi
        done
        
        echo ""
        echo "${YELLOW}📈 Logs de Acesso:${RESET}"
        for log_file in "${access_logs[@]}"; do
            if [[ -f "$log_file" ]]; then
                local file_size=$(du -h "$log_file" 2>/dev/null | cut -f1)
                echo "   • $(basename "$log_file") ($file_size)"
            fi
        done
    else
        log_warning "Diretório de logs do Apache não encontrado: $apache_log_dir"
    fi
    echo ""
}

watch_latest_log() {
    local log_dir="$HOME/deploy_logs"
    local latest_log=$(ls -t "$log_dir"/deploy_*.log 2>/dev/null | head -1)
    
    if [[ -f "$latest_log" ]]; then
        log_info "👀 Monitorando log mais recente: $latest_log"
        log_info "Pressione Ctrl+C para sair"
        echo ""
        tail -f "$latest_log"
    else
        log_error "Nenhum log de deploy encontrado"
    fi
}

view_log() {
    local log_dir="$HOME/deploy_logs"
    local log_files=("$log_dir"/deploy_*.log)
    
    if [[ ! -f "${log_files[0]}" ]]; then
        log_error "Nenhum log encontrado"
        return 1
    fi
    
    echo ""
    echo "${YELLOW}Selecione um log para visualizar:${RESET}"
    
    local count=1
    for log_file in "${log_files[@]}"; do
        echo "[$count] $(basename "$log_file")"
        ((count++))
    done
    echo "[0] Cancelar"
    echo ""
    
    read -p "Escolha uma opção: " choice
    
    if [[ "$choice" == "0" ]]; then
        return 0
    elif [[ "$choice" =~ ^[0-9]+$ ]] && [[ "$choice" -le "${#log_files[@]}" ]] && [[ "$choice" -gt 0 ]]; then
        local selected_log="${log_files[$((choice-1))]}"
        log_info "📖 Visualizando: $(basename "$selected_log")"
        echo ""
        
        if command -v less &>/dev/null; then
            less "$selected_log"
        else
            cat "$selected_log"
        fi
    else
        log_error "Opção inválida"
    fi
}

show_recent_errors() {
    local apache_error_log="/var/log/apache2/error.log"
    
    if [[ -f "$apache_error_log" ]]; then
        log_info "🔍 Últimos erros do Apache (últimas 20 linhas):"
        echo ""
        sudo tail -20 "$apache_error_log" | while read line; do
            echo "${RED}   $line${RESET}"
        done
    else
        log_warning "Log de erro do Apache não encontrado"
    fi
}

main() {
    show_header
    
    case "${1:-}" in
        "--list"|"-l")
            show_deploy_logs
            show_apache_logs
            ;;
        "--watch"|"-w")
            watch_latest_log
            ;;
        "--view"|"-v")
            view_log
            ;;
        "--errors"|"-e")
            show_recent_errors
            ;;
        "--help"|"-h")
            echo "📋 Visualizador de Logs do Deploy Automático Apache"
            echo ""
            echo "Uso: $0 [opção]"
            echo ""
            echo "Opções:"
            echo "  -l, --list      Listar todos os logs disponíveis"
            echo "  -w, --watch     Monitorar log mais recente em tempo real"
            echo "  -v, --view      Visualizar um log específico"
            echo "  -e, --errors    Mostrar últimos erros do Apache"
            echo "  -h, --help      Mostrar esta ajuda"
            echo ""
            echo "Sem opções: Menu interativo"
            ;;
        *)
            # Menu interativo
            echo "${YELLOW}Escolha uma opção:${RESET}"
            echo ""
            select option in "📋 Listar logs" "👀 Monitorar log atual" "📖 Ver log específico" "🔍 Últimos erros Apache" "❌ Sair"; do
                case $option in
                    "📋 Listar logs")
                        echo ""
                        show_deploy_logs
                        show_apache_logs
                        break
                        ;;
                    "👀 Monitorar log atual")
                        echo ""
                        watch_latest_log
                        break
                        ;;
                    "📖 Ver log específico")
                        view_log
                        break
                        ;;
                    "🔍 Últimos erros Apache")
                        echo ""
                        show_recent_errors
                        break
                        ;;
                    "❌ Sair")
                        log_info "Até mais!"
                        break
                        ;;
                    *)
                        log_error "Opção inválida"
                        ;;
                esac
            done
            ;;
    esac
}

main "$@"