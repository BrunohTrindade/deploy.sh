#!/bin/bash
# ==========================================
# 🚀 DEPLOY AUTOMÁTICO APACHE v2
# Autor: Bruno Trindade + GPT-5
# Sistema: Ubuntu / Debian
# ==========================================

# Cores para logs
GREEN=$(tput setaf 2)
YELLOW=$(tput setaf 3)
RED=$(tput setaf 1)
BLUE=$(tput setaf 4)
RESET=$(tput sgr0)

APACHE_DIR="/var/www"
PORTS_FILE="/etc/apache2/ports.conf"

echo "${BLUE}==========================================${RESET}"
echo "${GREEN}        🚀 DEPLOY AUTOMÁTICO APACHE v2${RESET}"
echo "${BLUE}==========================================${RESET}"
echo ""

# 1️⃣ Fonte do projeto
echo "Como deseja obter o projeto?"
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
            git clone "$GIT_LINK" "$PROJECT_PATH"
            break
            ;;
        *)
            echo "${RED}Escolha inválida.${RESET}"
            ;;
    esac
done

# 2️⃣ Detectar automaticamente o usuário supervisor (Apache)
SUPERVISOR_USER=$(ps aux | grep apache2 | grep -v grep | head -n1 | awk '{print $1}')
SUPERVISOR_USER=${SUPERVISOR_USER:-www-data}
echo ""
echo "${BLUE}🔐 Ajustando permissões...${RESET}"
if [ -d "$PROJECT_PATH" ]; then
    sudo chown -R "$SUPERVISOR_USER":www-data "$PROJECT_PATH"
    sudo chmod -R 775 "$PROJECT_PATH"
    echo "${GREEN}Permissões ajustadas para $SUPERVISOR_USER (owner) e www-data (group)${RESET}"
else
    echo "${RED}❌ Caminho $PROJECT_PATH não encontrado.${RESET}"
    exit 1
fi

# 3️⃣ Tipo de projeto
echo ""
echo "Selecione o tipo de projeto:"
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

# 4️⃣ Tipo de acesso
echo ""
echo "Como será o acesso?"
select access_type in "Domínio" "Porta"; do
    case $access_type in
        "Domínio")
            read -p "Digite o domínio (ex: exemplo.com): " DOMAIN
            USE_PORT=false
            break
            ;;
        "Porta")
            USE_PORT=true
            echo ""
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
            break
            ;;
        *)
            echo "${RED}Escolha inválida.${RESET}"
            ;;
    esac
done

# 5️⃣ Ajustar DocumentRoot
case $project_type in
    "Laravel") DOC_ROOT="${PROJECT_PATH}/public" ;;
    "Vue") DOC_ROOT="${PROJECT_PATH}/dist" ;;
    *) DOC_ROOT="${PROJECT_PATH}" ;;
esac

# 6️⃣ Garantir Listen
if [ "$USE_PORT" = true ]; then
    if ! sudo grep -qE "^\s*Listen\s+${PORT}\b" "$PORTS_FILE"; then
        echo "Listen ${PORT}" | sudo tee -a "$PORTS_FILE" >/dev/null
        echo "${YELLOW}Adicionando Listen ${PORT} em $PORTS_FILE${RESET}"
    fi
    PORT_LINE=":${PORT}"
    SERVER_NAME="localhost"
else
    if ! sudo grep -qE "^\s*Listen\s+80\b" "$PORTS_FILE"; then
        echo "Listen 80" | sudo tee -a "$PORTS_FILE" >/dev/null
    fi
    PORT_LINE=":80"
    SERVER_NAME="${DOMAIN}"
fi

# 7️⃣ Criar VirtualHost
CONF_PATH="/etc/apache2/sites-available/${PROJECT_NAME}.conf"
echo "${BLUE}🛠️ Criando configuração Apache...${RESET}"

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

# 8️⃣ Instalação de dependências
echo ""
echo "${BLUE}📦 Instalando dependências...${RESET}"
cd "$PROJECT_PATH" || exit

case $project_type in
    "Laravel")
        if command -v composer &>/dev/null; then
            composer install
            if [ ! -f .env ]; then
                echo "${YELLOW}Gerando arquivo .env...${RESET}"
                cp .env.example .env
            fi
            php artisan key:generate
        else
            echo "${RED}Composer não encontrado. Pule esta etapa.${RESET}"
        fi
        ;;
    "Vue"|"Node")
        if command -v npm &>/dev/null; then
            npm install
            [ "$project_type" = "Vue" ] && npm run build
        else
            echo "${RED}npm não encontrado.${RESET}"
        fi
        ;;
    "Python")
        if command -v pip &>/dev/null; then
            pip install -r requirements.txt
        else
            echo "${RED}pip não encontrado.${RESET}"
        fi
        ;;
    *)
        echo "${YELLOW}Nenhuma dependência a instalar.${RESET}"
        ;;
esac

# 9️⃣ SSL (se domínio)
if [ "$USE_PORT" = false ]; then
    echo ""
    echo "Deseja habilitar HTTPS (Certbot)?"
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

# 🔁 10️⃣ Recarregar Apache
echo ""
echo "${BLUE}🔁 Recarregando Apache...${RESET}"
sudo systemctl reload apache2

# ✅ Finalização
echo ""
echo "${BLUE}==========================================${RESET}"
echo "${GREEN}✅ DEPLOY CONCLUÍDO!${RESET}"
echo "Projeto: ${PROJECT_NAME}"
if [ "$USE_PORT" = true ]; then
    echo "Acesso: ${YELLOW}http://localhost:${PORT}${RESET}"
else
    echo "Acesso: ${YELLOW}https://${DOMAIN}${RESET}"
fi
echo "${BLUE}==========================================${RESET}"
