#!/bin/bash
# ==========================================
# 🚀 DEPLOY AUTOMÁTICO APACHE v3
# Autor: Bruno Trindade + GPT-5
# Sistema: Ubuntu / Debian
# ==========================================

# ------------------------------
# Cores e Emojis
GREEN=$(tput setaf 2)
YELLOW=$(tput setaf 3)
RED=$(tput setaf 1)
BLUE=$(tput setaf 4)
RESET=$(tput sgr0)
CHECK="✅"
WARN="⚠️"
ERROR="❌"

APACHE_DIR="/var/www"
PORTS_FILE="/etc/apache2/ports.conf"
LOG_DIR="$HOME/deploy_logs"
mkdir -p "$LOG_DIR"

# Log completo
exec > >(tee -a "$LOG_DIR/deploy_$(date +%Y%m%d_%H%M%S).log") 2>&1

echo "${BLUE}==========================================${RESET}"
echo "${GREEN}        🚀 DEPLOY AUTOMÁTICO APACHE v3${RESET}"
echo "${BLUE}==========================================${RESET}"
echo ""

# ------------------------------
# 1️⃣ Fonte do projeto
echo "[1/10] 🔹 Fonte do projeto"
select source_type in "Diretório local" "Git Clone"; do
    case $source_type in
        "Diretório local")
            read -p "Digite o caminho completo do projeto (ex: /var/www/meusite): " PROJECT_PATH
            PROJECT_NAME=$(basename "$PROJECT_PATH")
            break
            ;;
        "Git Clone")
            read -p "Digite o link do repositório Git: " GIT_LINK
            PROJECT_NAME=$(basename "$GIT_LINK" .git)
            PROJECT_PATH="$APACHE_DIR/$PROJECT_NAME"
            git clone "$GIT_LINK" "$PROJECT_PATH" || { echo "${ERROR} Falha ao clonar repositório"; exit 1; }
            break
            ;;
        *)
            echo "${RED}Escolha inválida.${RESET}"
            ;;
    esac
done

# ------------------------------
# 2️⃣ Usuário supervisor
SUPERVISOR_USER="www-data"
echo "[2/10] 🔹 Usuário supervisor detectado: $SUPERVISOR_USER"

# ------------------------------
# 3️⃣ Ajustar permissões
echo "[3/10] 🔹 Ajustando permissões..."
if [ -d "$PROJECT_PATH" ]; then
    sudo chown -R "$SUPERVISOR_USER":www-data "$PROJECT_PATH"
    sudo chmod -R 775 "$PROJECT_PATH"
    echo "${CHECK} Permissões ajustadas para $SUPERVISOR_USER (owner) e www-data (group)"
else
    echo "${ERROR} Caminho $PROJECT_PATH não encontrado."
    exit 1
fi

# ------------------------------
# 4️⃣ Tipo de projeto
echo "[4/10] 🔹 Tipo de projeto"
select project_type in "Laravel" "Vue" "Node" "Python" "HTML/PHP Simples"; do
    case $project_type in
        "Laravel"|"Vue"|"Node"|"Python"|"HTML/PHP Simples")
            break
            ;;
        *)
            echo "${RED}Escolha inválida.${RESET}"
            ;;
    esac
done

# ------------------------------
# 5️⃣ Tipo de acesso
echo "[5/10] 🔹 Tipo de acesso"
select access_type in "Domínio" "Porta"; do
    case $access_type in
        "Domínio")
            read -p "Digite o domínio (ex: exemplo.com): " DOMAIN
            USE_PORT=false
            break
            ;;
        "Porta")
            USE_PORT=true
            echo "${BLUE}🔍 Verificando portas usadas...${RESET}"
            USED_PORTS=$(ss -tuln | awk '{print $5}' | grep -oE '[0-9]+$' | sort -n | uniq | grep -E '^8[0-9]{3}$')
            echo "Portas em uso: ${USED_PORTS:-nenhuma}"
            for i in {8000..9000}; do
                if ! echo "$USED_PORTS" | grep -q "$i"; then
                    SUGGESTED_PORT=$i
                    break
                fi
            done
            echo "Porta sugerida livre: $SUGGESTED_PORT"
            read -p "Digite a porta desejada (padrão $SUGGESTED_PORT): " CUSTOM_PORT
            PORT=${CUSTOM_PORT:-$SUGGESTED_PORT}
            if ss -tuln | grep -q ":$PORT "; then
                echo "${ERROR} Porta $PORT já está em uso! Abortando."
                exit 1
            fi
            break
            ;;
        *)
            echo "${RED}Escolha inválida.${RESET}"
            ;;
    esac
done

# ------------------------------
# 6️⃣ Ajustar DocumentRoot
case $project_type in
    "Laravel") DOC_ROOT="${PROJECT_PATH}/public" ;;
    "Vue") DOC_ROOT="${PROJECT_PATH}/dist" ;;
    *) DOC_ROOT="${PROJECT_PATH}" ;;
esac

# Check arquivo inicial
echo "[6/10] 🔹 Verificando arquivo inicial..."
if [ -f "$DOC_ROOT/index.php" ] || [ -f "$DOC_ROOT/index.html" ]; then
    echo "${CHECK} Arquivo inicial encontrado em $DOC_ROOT"
else
    echo "${WARN} Nenhum arquivo inicial encontrado em $DOC_ROOT"
    read -p "Deseja continuar mesmo assim? (s/n): " CONTINUE
    [[ ! "$CONTINUE" =~ ^[Ss]$ ]] && { echo "🚫 Deploy cancelado"; exit 1; }
fi

# ------------------------------
# 7️⃣ Listen e VirtualHost
echo "[7/10] 🔹 Criando VirtualHost Apache..."
if [ "$USE_PORT" = true ]; then
    if ! sudo grep -qE "^\s*Listen\s+$PORT\b" "$PORTS_FILE"; then
        echo "Listen $PORT" | sudo tee -a "$PORTS_FILE" >/dev/null
    fi
    PORT_LINE=":$PORT"
    SERVER_NAME="localhost"
else
    if ! sudo grep -qE "^\s*Listen\s+80\b" "$PORTS_FILE"; then
        echo "Listen 80" | sudo tee -a "$PORTS_FILE" >/dev/null
    fi
    PORT_LINE=":80"
    SERVER_NAME="$DOMAIN"
fi

CONF_PATH="/etc/apache2/sites-available/${PROJECT_NAME}.conf"
sudo bash -c "cat > $CONF_PATH" <<EOF
<VirtualHost *${PORT_LINE}>
    ServerAdmin webmaster@${SERVER_NAME}
    ServerName ${SERVER_NAME}
    DocumentRoot ${DOC_ROOT}

    <Directory ${DOC_ROOT}>
        AllowOverride All
        Require all granted
    </Directory>

    ErrorLog \${APACHE_LOG_DIR}/${PROJECT_NAME}_error.log
    CustomLog \${APACHE_LOG_DIR}/${PROJECT_NAME}_access.log combined
</VirtualHost>
EOF

sudo a2enmod rewrite proxy proxy_http headers ssl > /dev/null 2>&1
sudo a2ensite "${PROJECT_NAME}.conf" > /dev/null 2>&1

# ------------------------------
# 8️⃣ Instalação de dependências
echo "[8/10] 📦 Instalando dependências..."
cd "$PROJECT_PATH" || exit

case $project_type in
    "Laravel")
        command -v composer &>/dev/null && { composer install; [ ! -f .env ] && cp .env.example .env; php artisan key:generate; } || echo "${WARN} Composer não encontrado"
        ;;
    "Vue"|"Node")
        command -v npm &>/dev/null && { npm install; [ "$project_type" = "Vue" ] && npm run build; } || echo "${WARN} npm não encontrado"
        ;;
    "Python")
        command -v pip &>/dev/null && pip install -r requirements.txt || echo "${WARN} pip não encontrado"
        ;;
    *)
        echo "${YELLOW}Nenhuma dependência a instalar${RESET}"
        ;;
esac

# ------------------------------
# 9️⃣ SSL
if [ "$USE_PORT" = false ]; then
    echo "[9/10] 🔹 Configurando SSL (Certbot)"
    select enable_ssl in "Sim" "Não"; do
        case $enable_ssl in
            "Sim")
                sudo apt install -y certbot python3-certbot-apache
                sudo certbot --apache -d "$DOMAIN"
                break
                ;;
            "Não") break ;;
        esac
    done
fi

# ------------------------------
# 🔁 10️⃣ Recarregar Apache
echo "[10/10] 🔁 Recarregando Apache..."
sudo systemctl reload apache2

# ------------------------------
# ✅ Finalização
echo ""
echo "${BLUE}==========================================${RESET}"
echo "${GREEN}✅ DEPLOY CONCLUÍDO!${RESET}"
echo "Projeto: $PROJECT_NAME"
echo "Acesso: ${USE_PORT:+http://localhost:$PORT}${DOMAIN:+https://$DOMAIN}"
echo "${BLUE}==========================================${RESET}"
