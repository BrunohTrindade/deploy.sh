#!/bin/bash
# ==========================================
# 🚀 DEPLOY AUTOMÁTICO APACHE v3.6 - SIMPLES
# Autor: Bruno Trindade
# Sistema: Ubuntu / Debian
# ==========================================
# curl -s https://raw.githubusercontent.com/BrunohTrindade/deploy.sh/refs/heads/main/deploy-simples.sh | bash

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
echo "${GREEN}      🚀 DEPLOY AUTOMÁTICO APACHE v3.6${RESET}"
echo "${BLUE}==========================================${RESET}"
echo ""

# ══════════════════════════════
# 📂 1️⃣ FONTE DO PROJETO
# ══════════════════════════════
echo ""
echo "${BLUE}┌─────────────────────────────────────────────┐${RESET}"
echo "${BLUE}│          📂 [1/8] FONTE DO PROJETO          │${RESET}"
echo "${BLUE}└─────────────────────────────────────────────┘${RESET}"
echo "${YELLOW}Escolha de onde vem seu projeto:${RESET}"
echo ""
select source_type in "📁 Diretório local" "🌐 Git Clone"; do
    case $source_type in
        "📁 Diretório local")
            echo "${GREEN}📁 Você escolheu: Diretório local${RESET}"
            read -p "${BLUE}💭 Digite o caminho completo do projeto: ${RESET}" PROJECT_PATH
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
done

# ══════════════════════════════
# 🔒 2️⃣ AJUSTAR PERMISSÕES
# ══════════════════════════════
echo ""
echo "${BLUE}┌─────────────────────────────────────────────┐${RESET}"
echo "${BLUE}│        🔒 [2/8] AJUSTAR PERMISSÕES          │${RESET}"
echo "${BLUE}└─────────────────────────────────────────────┘${RESET}"
echo "${YELLOW}Configurando permissões de segurança...${RESET}"
if [ -d "$PROJECT_PATH" ]; then
    sudo chown -R www-data:www-data "$PROJECT_PATH"
    sudo chmod -R 775 "$PROJECT_PATH"
    echo "${CHECK} Permissões ajustadas para www-data"
else
    echo "${ERROR} Caminho $PROJECT_PATH não encontrado."
    exit 1
fi

# ══════════════════════════════
# 🚀 3️⃣ TIPO DE PROJETO
# ══════════════════════════════
echo ""
echo "${BLUE}┌─────────────────────────────────────────────┐${RESET}"
echo "${BLUE}│         🚀 [3/8] TIPO DE PROJETO           │${RESET}"
echo "${BLUE}└─────────────────────────────────────────────┘${RESET}"

# Detectar automaticamente
if [ -f "$PROJECT_PATH/composer.json" ] && grep -q "laravel" "$PROJECT_PATH/composer.json"; then
    PROJECT_TYPE="Laravel"
    DOC_ROOT="${PROJECT_PATH}/public"
    echo "${CHECK} Laravel detectado automaticamente!"
elif [ -f "$PROJECT_PATH/package.json" ] && grep -q "vue" "$PROJECT_PATH/package.json"; then
    PROJECT_TYPE="Vue"
    DOC_ROOT="${PROJECT_PATH}/dist"
    echo "${CHECK} Vue.js detectado automaticamente!"
elif [ -f "$PROJECT_PATH/package.json" ]; then
    PROJECT_TYPE="Node.js"
    DOC_ROOT="${PROJECT_PATH}"
    echo "${CHECK} Node.js detectado automaticamente!"
elif [ -f "$PROJECT_PATH/requirements.txt" ]; then
    PROJECT_TYPE="Python"
    DOC_ROOT="${PROJECT_PATH}"
    echo "${CHECK} Python detectado automaticamente!"
else
    PROJECT_TYPE="HTML/PHP"
    DOC_ROOT="${PROJECT_PATH}"
    echo "${CHECK} Projeto HTML/PHP detectado!"
fi

echo "${BLUE}Tipo: $PROJECT_TYPE${RESET}"
echo "${BLUE}DocumentRoot: $DOC_ROOT${RESET}"

# ══════════════════════════════
# 🌐 4️⃣ CONFIGURAR ACESSO
# ══════════════════════════════
echo ""
echo "${BLUE}┌─────────────────────────────────────────────┐${RESET}"
echo "${BLUE}│         🌐 [4/8] CONFIGURAR ACESSO         │${RESET}"
echo "${BLUE}└─────────────────────────────────────────────┘${RESET}"
echo "${YELLOW}Como você quer acessar seu projeto?${RESET}"
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
            echo "${BLUE}🔍 Procurando porta livre...${RESET}"
            for i in {8000..9000}; do
                if ! ss -tuln | grep -q ":$i "; then
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
done

# ══════════════════════════════
# ⚙️ 5️⃣ CONFIGURAR APACHE
# ══════════════════════════════
echo ""
echo "${BLUE}┌─────────────────────────────────────────────┐${RESET}"
echo "${BLUE}│        ⚙️ [5/8] CONFIGURAR APACHE           │${RESET}"
echo "${BLUE}└─────────────────────────────────────────────┘${RESET}"
echo "${YELLOW}Criando VirtualHost Apache...${RESET}"

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
        Options Indexes FollowSymLinks
    </Directory>

    ErrorLog \${APACHE_LOG_DIR}/${PROJECT_NAME}_error.log
    CustomLog \${APACHE_LOG_DIR}/${PROJECT_NAME}_access.log combined
</VirtualHost>
EOF

sudo a2enmod rewrite > /dev/null 2>&1
sudo a2ensite "${PROJECT_NAME}.conf" > /dev/null 2>&1
echo "${CHECK} VirtualHost criado e habilitado!"

# ══════════════════════════════
# 📦 6️⃣ INSTALAR DEPENDÊNCIAS
# ══════════════════════════════
echo ""
echo "${BLUE}┌─────────────────────────────────────────────┐${RESET}"
echo "${BLUE}│       📦 [6/8] INSTALAR DEPENDÊNCIAS        │${RESET}"
echo "${BLUE}└─────────────────────────────────────────────┘${RESET}"

cd "$PROJECT_PATH" || exit

case $PROJECT_TYPE in
    "Laravel")
        echo "${BLUE}⚡ Processando projeto Laravel...${RESET}"
        
        # Verificar PHP
        if ! command -v php &>/dev/null; then
            echo "${ERROR} PHP não encontrado! Instale: sudo apt install php php-cli php-mysql"
            exit 1
        fi
        
        # Instalar Composer se necessário
        if ! command -v composer &>/dev/null; then
            echo "${YELLOW}📦 Instalando Composer...${RESET}"
            curl -sS https://getcomposer.org/installer | php
            sudo mv composer.phar /usr/local/bin/composer
        fi
        
        # Instalar dependências
        echo "${BLUE}📦 Instalando dependências...${RESET}"
        sudo -u www-data composer install --no-interaction --prefer-dist --optimize-autoloader --no-dev
        
        # Configurar .env
        if [ ! -f .env ]; then
            if [ -f .env.example ]; then
                cp .env.example .env
                echo "${CHECK} Arquivo .env criado"
            fi
        fi
        
        # Gerar chave
        sudo -u www-data php artisan key:generate --force
        
        # Cache
        sudo -u www-data php artisan config:cache
        sudo -u www-data php artisan route:cache
        sudo -u www-data php artisan view:cache
        
        echo "${CHECK} Laravel configurado!"
        ;;
        
    "Vue"|"Node.js")
        echo "${BLUE}🌟 Processando projeto $PROJECT_TYPE...${RESET}"
        
        if ! command -v npm &>/dev/null; then
            echo "${YELLOW}📦 Instalando Node.js...${RESET}"
            curl -fsSL https://deb.nodesource.com/setup_lts.x | sudo -E bash -
            sudo apt-get install -y nodejs
        fi
        
        if [ -f "package.json" ]; then
            echo "${BLUE}📦 Instalando dependências NPM...${RESET}"
            sudo -u www-data npm install
            
            if [ "$PROJECT_TYPE" = "Vue" ]; then
                echo "${BLUE}🏗️ Build do projeto Vue...${RESET}"
                sudo -u www-data npm run build
            fi
        fi
        echo "${CHECK} $PROJECT_TYPE configurado!"
        ;;
        
    "Python")
        echo "${BLUE}🐍 Processando projeto Python...${RESET}"
        
        if [ -f "requirements.txt" ]; then
            if command -v pip3 &>/dev/null; then
                sudo -u www-data pip3 install -r requirements.txt
            else
                sudo apt install -y python3-pip
                sudo -u www-data pip3 install -r requirements.txt
            fi
        fi
        echo "${CHECK} Python configurado!"
        ;;
        
    *)
        echo "${YELLOW}📄 Projeto HTML/PHP - Nenhuma dependência especial${RESET}"
        ;;
esac

# ══════════════════════════════
# 🗄️ 7️⃣ CONFIGURAR BANCO (Laravel)
# ══════════════════════════════
if [ "$PROJECT_TYPE" = "Laravel" ] && [ -f .env ]; then
    echo ""
    echo "${BLUE}┌─────────────────────────────────────────────┐${RESET}"
    echo "${BLUE}│       🗄️ [7/8] CONFIGURAR BANCO (.ENV)      │${RESET}"
    echo "${BLUE}└─────────────────────────────────────────────┘${RESET}"
    echo "${YELLOW}Deseja configurar a conexão com banco de dados?${RESET}"
    echo ""
    select configure_db in "✅ Sim" "❌ Não"; do
        case $configure_db in
            "✅ Sim")
                echo "${GREEN}✅ Configurando conexão com banco...${RESET}"
                
                select db_type in "🐬 MySQL" "🪶 SQLite"; do
                    case $db_type in
                        "🐬 MySQL")
                            read -p "${BLUE}💭 Host do banco (localhost): ${RESET}" DB_HOST
                            DB_HOST=${DB_HOST:-localhost}
                            read -p "${BLUE}💭 Usuário do banco: ${RESET}" DB_USERNAME
                            read -s -p "${BLUE}💭 Senha do banco: ${RESET}" DB_PASSWORD
                            echo ""
                            read -p "${BLUE}💭 Nome do banco: ${RESET}" DB_DATABASE
                            
                            # Atualizar .env
                            sed -i "s/DB_CONNECTION=.*/DB_CONNECTION=mysql/" .env
                            sed -i "s/DB_HOST=.*/DB_HOST=$DB_HOST/" .env
                            sed -i "s/DB_DATABASE=.*/DB_DATABASE=$DB_DATABASE/" .env
                            sed -i "s/DB_USERNAME=.*/DB_USERNAME=$DB_USERNAME/" .env
                            sed -i "s/DB_PASSWORD=.*/DB_PASSWORD=$DB_PASSWORD/" .env
                            
                            echo "${CHECK} MySQL configurado!"
                            break
                            ;;
                        "🪶 SQLite")
                            mkdir -p database
                            touch database/database.sqlite
                            sudo chown www-data:www-data database/database.sqlite
                            
                            sed -i "s/DB_CONNECTION=.*/DB_CONNECTION=sqlite/" .env
                            sed -i "s/DB_DATABASE=.*/DB_DATABASE=database\/database.sqlite/" .env
                            
                            echo "${CHECK} SQLite configurado!"
                            break
                            ;;
                    esac
                done
                
                # Migrations
                echo "${YELLOW}Executar migrations?${RESET}"
                select run_migrations in "✅ Sim" "❌ Não"; do
                    case $run_migrations in
                        "✅ Sim")
                            php artisan migrate --force
                            echo "${CHECK} Migrations executadas!"
                            break
                            ;;
                        "❌ Não")
                            break
                            ;;
                    esac
                done
                break
                ;;
            "❌ Não")
                echo "${YELLOW}❌ Configuração de banco ignorada${RESET}"
                break
                ;;
        esac
    done
fi

# ══════════════════════════════
# 🔄 8️⃣ FINALIZAR
# ══════════════════════════════
echo ""
echo "${BLUE}┌─────────────────────────────────────────────┐${RESET}"
echo "${BLUE}│         🔄 [8/8] FINALIZAR DEPLOY          │${RESET}"
echo "${BLUE}└─────────────────────────────────────────────┘${RESET}"
echo "${YELLOW}Recarregando Apache...${RESET}"
sudo systemctl reload apache2

# ══════════════════════════════
# 🎉 FINALIZAÇÃO
# ══════════════════════════════
echo ""
echo "${GREEN}╔═══════════════════════════════════════════════╗${RESET}"
echo "${GREEN}║              🎉 DEPLOY CONCLUÍDO! 🎉          ║${RESET}"
echo "${GREEN}╠═══════════════════════════════════════════════╣${RESET}"
echo "${GREEN}║ ${BLUE}📦 Projeto: ${YELLOW}$PROJECT_NAME${GREEN}                    ║${RESET}"
if [ "$USE_PORT" = true ]; then
    echo "${GREEN}║ ${BLUE}🌐 Acesso: ${YELLOW}http://localhost:$PORT${GREEN}              ║${RESET}"
    echo "${GREEN}║ ${BLUE}🔗 Teste: ${YELLOW}curl http://localhost:$PORT${GREEN}         ║${RESET}"
else
    echo "${GREEN}║ ${BLUE}🌐 Acesso: ${YELLOW}http://$DOMAIN${GREEN}              ║${RESET}"
fi
echo "${GREEN}║ ${BLUE}📅 Deploy: ${YELLOW}$(date '+%d/%m/%Y %H:%M:%S')${GREEN}         ║${RESET}"
echo "${GREEN}║ ${BLUE}📝 Log: ${YELLOW}$LOG_DIR/deploy_$(date +%Y%m%d)*.log${GREEN}  ║${RESET}"
echo "${GREEN}╚═══════════════════════════════════════════════╝${RESET}"
echo ""
echo "${BLUE}🚀 Seu projeto está online!${RESET}"

# Teste rápido
if [ "$USE_PORT" = true ]; then
    echo ""
    echo "${BLUE}🔍 Testando conectividade...${RESET}"
    if curl -s --connect-timeout 5 "http://localhost:$PORT" >/dev/null; then
        echo "${CHECK} ✅ Projeto respondendo em http://localhost:$PORT"
    else
        echo "${WARN} ⚠️ Projeto não está respondendo. Verifique:"
        echo "   • sudo systemctl status apache2"
        echo "   • sudo tail -f /var/log/apache2/${PROJECT_NAME}_error.log"
        echo "   • ls -la $DOC_ROOT"
    fi
fi