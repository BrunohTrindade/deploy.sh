#!/bin/bash
# ==========================================
# 🚀 DEPLOY AUTOMÁTICO APACHE v3
# Autor: Bruno Trindade + GPT-5
# Sistema: Ubuntu / Debian
# ==========================================
# curl -s https://raw.githubusercontent.com/BrunohTrindade/deploy.sh/refs/heads/main/deploy.sh | bash
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

# ══════════════════════════════
# 📂 1️⃣ FONTE DO PROJETO
# ══════════════════════════════
echo ""
echo "${BLUE}┌─────────────────────────────────────────────┐${RESET}"
echo "${BLUE}│          📂 [1/10] FONTE DO PROJETO         │${RESET}"
echo "${BLUE}└─────────────────────────────────────────────┘${RESET}"
echo "${YELLOW}� Escolha de onde vem seu projeto:${RESET}"
echo ""
select source_type in "📁 Diretório local" "🌐 Git Clone"; do
    case $source_type in
        "📁 Diretório local")
            echo "${GREEN}📁 Você escolheu: Diretório local${RESET}"
            read -p "${BLUE}💭 Digite o caminho completo do projeto (ex: /var/www/meusite): ${RESET}" PROJECT_PATH
            PROJECT_NAME=$(basename "$PROJECT_PATH")
            break
            ;;
        "🌐 Git Clone")
            echo "${GREEN}🌐 Você escolheu: Git Clone${RESET}"
            read -p "${BLUE}💭 Digite o link do repositório Git: ${RESET}" GIT_LINK
            PROJECT_NAME=$(basename "$GIT_LINK" .git)
            PROJECT_PATH="$APACHE_DIR/$PROJECT_NAME"
            git clone "$GIT_LINK" "$PROJECT_PATH" || { echo "${ERROR} Falha ao clonar repositório"; exit 1; }
            break
            ;;
        *)
            echo "${RED}Escolha inválida.${RESET}"
            ;;
    esac
done < /dev/tty

# ══════════════════════════════
# 👤 2️⃣ USUÁRIO SUPERVISOR
# ══════════════════════════════
SUPERVISOR_USER="www-data"
echo ""
echo "${BLUE}┌─────────────────────────────────────────────┐${RESET}"
echo "${BLUE}│        👤 [2/10] USUÁRIO SUPERVISOR         │${RESET}"
echo "${BLUE}└─────────────────────────────────────────────┘${RESET}"
echo "${GREEN}� Usuário supervisor detectado: ${YELLOW}$SUPERVISOR_USER${RESET}"

# ══════════════════════════════
# 🔒 3️⃣ AJUSTAR PERMISSÕES
# ══════════════════════════════
echo ""
echo "${BLUE}┌─────────────────────────────────────────────┐${RESET}"
echo "${BLUE}│        🔒 [3/10] AJUSTAR PERMISSÕES         │${RESET}"
echo "${BLUE}└─────────────────────────────────────────────┘${RESET}"
echo "${YELLOW}� Configurando permissões de segurança...${RESET}"
if [ -d "$PROJECT_PATH" ]; then
    sudo chown -R "$SUPERVISOR_USER":www-data "$PROJECT_PATH"
    sudo chmod -R 775 "$PROJECT_PATH"
    echo "${CHECK} Permissões ajustadas para $SUPERVISOR_USER (owner) e www-data (group)"
else
    echo "${ERROR} Caminho $PROJECT_PATH não encontrado."
    exit 1
fi

# ══════════════════════════════
# 🚀 4️⃣ TIPO DE PROJETO
# ══════════════════════════════
echo ""
echo "${BLUE}┌─────────────────────────────────────────────┐${RESET}"
echo "${BLUE}│         🚀 [4/10] TIPO DE PROJETO          │${RESET}"
echo "${BLUE}└─────────────────────────────────────────────┘${RESET}"
echo "${YELLOW}� Selecione o tipo do seu projeto:${RESET}"
echo ""
select project_type in "⚡ Laravel" "🌟 Vue" "🟢 Node.js" "🐍 Python" "📄 HTML/PHP Simples"; do
    case $project_type in
        "⚡ Laravel"|"🌟 Vue"|"🟢 Node.js"|"🐍 Python"|"📄 HTML/PHP Simples")
            break
            ;;
        *)
            echo "${RED}Escolha inválida.${RESET}"
            ;;
    esac
done < /dev/tty

# ══════════════════════════════
# 🌐 5️⃣ TIPO DE ACESSO
# ══════════════════════════════
echo ""
echo "${BLUE}┌─────────────────────────────────────────────┐${RESET}"
echo "${BLUE}│         🌐 [5/10] TIPO DE ACESSO           │${RESET}"
echo "${BLUE}└─────────────────────────────────────────────┘${RESET}"
echo "${YELLOW}� Como você quer acessar seu projeto?${RESET}"
echo ""
select access_type in "🌍 Domínio" "🔌 Porta"; do
    case $access_type in
        "🌍 Domínio")
            echo "${GREEN}🌍 Você escolheu: Acesso por domínio${RESET}"
            read -p "${BLUE}💭 Digite o domínio (ex: exemplo.com): ${RESET}" DOMAIN
            USE_PORT=false
            break
            ;;
        "🔌 Porta")
            echo "${GREEN}🔌 Você escolheu: Acesso por porta${RESET}"
            USE_PORT=true
            echo "${BLUE}🔍 Verificando portas usadas...${RESET}"
            USED_PORTS=$(ss -tuln | awk '{print $5}' | grep -oE '[0-9]+$' | sort -n | uniq | grep -E '^8[0-9]{3}$')
            echo "${YELLOW}📊 Portas em uso: ${USED_PORTS:-nenhuma}${RESET}"
            for i in {8000..9000}; do
                if ! echo "$USED_PORTS" | grep -q "$i"; then
                    SUGGESTED_PORT=$i
                    break
                fi
            done
            echo "${GREEN}💡 Porta sugerida livre: ${YELLOW}$SUGGESTED_PORT${RESET}"
            read -p "${BLUE}💭 Digite a porta desejada (padrão $SUGGESTED_PORT): ${RESET}" CUSTOM_PORT
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
done < /dev/tty

# ------------------------------
# 📁 Ajustar DocumentRoot baseado no projeto
case $project_type in
    "⚡ Laravel") DOC_ROOT="${PROJECT_PATH}/public" ;;
    "🌟 Vue") DOC_ROOT="${PROJECT_PATH}/dist" ;;
    *) DOC_ROOT="${PROJECT_PATH}" ;;
esac

# ══════════════════════════════
# 📋 6️⃣ VERIFICAR ESTRUTURA
# ══════════════════════════════
echo ""
echo "${BLUE}┌─────────────────────────────────────────────┐${RESET}"
echo "${BLUE}│        📋 [6/10] VERIFICAR ESTRUTURA        │${RESET}"
echo "${BLUE}└─────────────────────────────────────────────┘${RESET}"
echo "${YELLOW}� Verificando arquivo inicial do projeto...${RESET}"
if [ -f "$DOC_ROOT/index.php" ] || [ -f "$DOC_ROOT/index.html" ]; then
    echo "${CHECK} Arquivo inicial encontrado em $DOC_ROOT"
else
    echo "${WARN} Nenhum arquivo inicial encontrado em $DOC_ROOT"
    read -p "${YELLOW}❓ Deseja continuar mesmo assim? (s/n): ${RESET}" CONTINUE
    [[ ! "$CONTINUE" =~ ^[Ss]$ ]] && { echo "🚫 Deploy cancelado"; exit 1; }
fi

# ══════════════════════════════
# ⚙️ 7️⃣ CONFIGURAR APACHE
# ══════════════════════════════
echo ""
echo "${BLUE}┌─────────────────────────────────────────────┐${RESET}"
echo "${BLUE}│        ⚙️ [7/10] CONFIGURAR APACHE          │${RESET}"
echo "${BLUE}└─────────────────────────────────────────────┘${RESET}"
echo "${YELLOW}� Criando VirtualHost Apache...${RESET}"
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

# ══════════════════════════════
# 📦 8️⃣ INSTALAR DEPENDÊNCIAS
# ══════════════════════════════
echo ""
echo "${BLUE}┌─────────────────────────────────────────────┐${RESET}"
echo "${BLUE}│       📦 [8/10] INSTALAR DEPENDÊNCIAS       │${RESET}"
echo "${BLUE}└─────────────────────────────────────────────┘${RESET}"
echo "${YELLOW}⚡ Instalando dependências do projeto...${RESET}"
cd "$PROJECT_PATH" || exit

case $project_type in
    "⚡ Laravel")
        echo "${BLUE}⚡ Processando projeto Laravel...${RESET}"
        command -v composer &>/dev/null && { composer install; [ ! -f .env ] && cp .env.example .env; php artisan key:generate; } || echo "${WARN} Composer não encontrado"
        ;;
    "🌟 Vue"|"🟢 Node.js")
        echo "${BLUE}🌟 Processando projeto ${project_type}...${RESET}"
        command -v npm &>/dev/null && { npm install; [[ "$project_type" == *"Vue"* ]] && npm run build; } || echo "${WARN} npm não encontrado"
        ;;
    "🐍 Python")
        echo "${BLUE}🐍 Processando projeto Python...${RESET}"
        command -v pip &>/dev/null && pip install -r requirements.txt || echo "${WARN} pip não encontrado"
        ;;
    *)
        echo "${YELLOW}📄 Projeto HTML/PHP - Nenhuma dependência a instalar${RESET}"
        ;;
esac

# ══════════════════════════════
# 🔐 9️⃣ CONFIGURAR SSL
# ══════════════════════════════
if [ "$USE_PORT" = false ]; then
    echo ""
    echo "${BLUE}┌─────────────────────────────────────────────┐${RESET}"
    echo "${BLUE}│         🔐 [9/10] CONFIGURAR SSL            │${RESET}"
    echo "${BLUE}└─────────────────────────────────────────────┘${RESET}"
    echo "${YELLOW}� Deseja configurar SSL/HTTPS? (Recomendado)${RESET}"
    echo ""
    select enable_ssl in "✅ Sim" "❌ Não"; do
        case $enable_ssl in
            "✅ Sim")
                echo "${GREEN}✅ Configurando SSL com Certbot...${RESET}"
                sudo apt install -y certbot python3-certbot-apache
                sudo certbot --apache -d "$DOMAIN"
                break
                ;;
            "❌ Não") 
                echo "${YELLOW}❌ SSL não será configurado${RESET}"
                break 
                ;;
        esac
    done < /dev/tty
fi

# ══════════════════════════════
# � 10️⃣ FINALIZAR DEPLOY
# ══════════════════════════════
echo ""
echo "${BLUE}┌─────────────────────────────────────────────┐${RESET}"
echo "${BLUE}│         🔄 [10/10] FINALIZAR DEPLOY         │${RESET}"
echo "${BLUE}└─────────────────────────────────────────────┘${RESET}"
echo "${YELLOW}� Recarregando Apache...${RESET}"
sudo systemctl reload apache2

# ══════════════════════════════
# 🎉 FINALIZAÇÃO
# ══════════════════════════════
echo ""
echo "${GREEN}╔═══════════════════════════════════════════════╗${RESET}"
echo "${GREEN}║              🎉 DEPLOY CONCLUÍDO! 🎉          ║${RESET}"
echo "${GREEN}╠═══════════════════════════════════════════════╣${RESET}"
echo "${GREEN}║ ${BLUE}📦 Projeto: ${YELLOW}$PROJECT_NAME${GREEN}                    ║${RESET}"
echo "${GREEN}║ ${BLUE}🌐 Acesso: ${YELLOW}${USE_PORT:+http://localhost:$PORT}${DOMAIN:+https://$DOMAIN}${GREEN}              ║${RESET}"
echo "${GREEN}║ ${BLUE}📅 Deploy: ${YELLOW}$(date '+%d/%m/%Y %H:%M:%S')${GREEN}         ║${RESET}"
echo "${GREEN}╚═══════════════════════════════════════════════╝${RESET}"
echo ""
echo "${BLUE}🚀 Seu projeto está online e funcionando!${RESET}"
