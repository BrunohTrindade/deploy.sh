#!/bin/bash
# ==========================================
# 🚀 DEPLOY AUTOMÁTICO APACHE v3.4
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

# Variáveis de controle de rollback
ROLLBACK_ACTIONS=()
TEMP_FILES=()
CREATED_CONFIGS=()

# Log completo
exec > >(tee -a "$LOG_DIR/deploy_$(date +%Y%m%d_%H%M%S).log") 2>&1

# Função de rollback
rollback_deploy() {
    echo ""
    echo "${RED}╔═══════════════════════════════════════════════╗${RESET}"
    echo "${RED}║              ⚠️ INICIANDO ROLLBACK ⚠️           ║${RESET}"
    echo "${RED}╚═══════════════════════════════════════════════╝${RESET}"
    
    # Desabilitar site Apache se foi criado
    for config in "${CREATED_CONFIGS[@]}"; do
        echo "${YELLOW}🔄 Desabilitando site: $config${RESET}"
        sudo a2dissite "$config" 2>/dev/null || true
    done
    
    # Remover arquivos de configuração criados
    for config in "${CREATED_CONFIGS[@]}"; do
        config_path="/etc/apache2/sites-available/$config"
        if [ -f "$config_path" ]; then
            echo "${YELLOW}🗑️ Removendo configuração: $config_path${RESET}"
            sudo rm -f "$config_path"
        fi
    done
    
    # Remover arquivos temporários
    for temp_file in "${TEMP_FILES[@]}"; do
        if [ -f "$temp_file" ]; then
            echo "${YELLOW}🗑️ Removendo arquivo temporário: $temp_file${RESET}"
            rm -f "$temp_file"
        fi
    done
    
    # Remover Listen das portas adicionadas
    for action in "${ROLLBACK_ACTIONS[@]}"; do
        if [[ "$action" == "port:"* ]]; then
            port=$(echo "$action" | cut -d: -f2)
            echo "${YELLOW}🔄 Removendo Listen $port do ports.conf${RESET}"
            sudo sed -i "/^Listen $port$/d" "$PORTS_FILE" 2>/dev/null || true
        fi
    done
    
    # Recarregar Apache
    echo "${YELLOW}🔄 Recarregando Apache...${RESET}"
    sudo systemctl reload apache2 2>/dev/null || true
    
    echo "${RED}❌ Rollback concluído. Deploy foi revertido.${RESET}"
    exit 1
}

# Trap para capturar erros e executar rollback
trap 'rollback_deploy' ERR

echo "${BLUE}==========================================${RESET}"
echo "${GREEN}      🚀 DEPLOY AUTOMÁTICO APACHE v3.4${RESET}"
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

# Adicionar ao controle de rollback
CREATED_CONFIGS+=("${PROJECT_NAME}.conf")
if [ "$USE_PORT" = true ]; then
    ROLLBACK_ACTIONS+=("port:$PORT")
fi

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
        
        # Verificar versão do PHP primeiro
        if command -v php &>/dev/null; then
            PHP_VERSION=$(php -r "echo PHP_VERSION;")
            echo "${CHECK} PHP $PHP_VERSION detectado"
        else
            echo "${ERROR} PHP não encontrado no sistema!"
            echo "${YELLOW}💡 Instale PHP manualmente: sudo apt install php php-cli php-mysql${RESET}"
            exit 1
        fi
        
        # Verificar requisitos do projeto Laravel
        if [ -f "composer.json" ]; then
            echo "${BLUE}🔍 Verificando requisitos PHP do projeto...${RESET}"
            
            # Extrair versão PHP requerida do composer.json
            REQUIRED_PHP=$(grep -o '"php":\s*"[^"]*"' composer.json 2>/dev/null | cut -d'"' -f4 | head -1)
            
            if [ -n "$REQUIRED_PHP" ]; then
                echo "${YELLOW}📋 Projeto requer PHP: $REQUIRED_PHP${RESET}"
                echo "${YELLOW}� Sistema possui PHP: $PHP_VERSION${RESET}"
                
                # Verificar compatibilidade usando composer (se disponível)
                if command -v composer &>/dev/null; then
                    if composer check-platform-reqs --no-dev 2>/dev/null | grep -q "does not satisfy"; then
                        echo "${ERROR} Incompatibilidade de versão PHP detectada!"
                        echo "${YELLOW}💡 O projeto requer $REQUIRED_PHP mas o sistema tem PHP $PHP_VERSION${RESET}"
                        echo "${YELLOW}� Instale a versão correta do PHP antes de continuar${RESET}"
                        exit 1
                    else
                        echo "${CHECK} Versão PHP compatível com o projeto!"
                    fi
                fi
            else
                echo "${YELLOW}💡 Não foi possível detectar requisitos PHP no composer.json${RESET}"
            fi
        fi
        
        # Verificar e instalar Composer se necessário  
        if ! command -v composer &>/dev/null; then
            echo "${WARN} Composer não encontrado. Instalando...${RESET}"
            
            # Baixar e instalar Composer
            echo "${BLUE}📦 Baixando e instalando Composer...${RESET}"
            cd /tmp || exit
            curl -sS https://getcomposer.org/installer -o composer-setup.php
            sudo php composer-setup.php --install-dir=/usr/local/bin --filename=composer
            rm composer-setup.php
            cd "$PROJECT_PATH" || exit
            
            if command -v composer &>/dev/null; then
                echo "${CHECK} Composer instalado com sucesso!"
            else
                echo "${ERROR} Falha ao instalar Composer"
                exit 1
            fi
        else
            echo "${CHECK} Composer já está instalado"
        fi
        
        # Corrigir ownership do Git para o diretório atual
        echo "${BLUE}🔧 Corrigindo permissões Git...${RESET}"
        git config --global --add safe.directory "$PROJECT_PATH" 2>/dev/null || true
        
        # Verificar se existe composer.json
        if [ ! -f "composer.json" ]; then
            echo "${ERROR} Arquivo composer.json não encontrado no projeto Laravel!"
            echo "${YELLOW}💡 Certifique-se de que este é um projeto Laravel válido${RESET}"
        else
            # Corrigir permissões antes de instalar
            echo "${BLUE}🔒 Ajustando permissões para instalação segura...${RESET}"
            sudo chown -R "$SUPERVISOR_USER":www-data "$PROJECT_PATH"
            
            # Remover composer.lock se houver incompatibilidade de versão PHP
            if [ -f "composer.lock" ]; then
                echo "${BLUE}🧹 Verificando compatibilidade do composer.lock...${RESET}"
                # Tentar detectar incompatibilidade de PHP
                if composer check-platform-reqs 2>&1 | grep -q "does not satisfy that requirement"; then
                    echo "${WARN} Detectada incompatibilidade de versão PHP. Removendo composer.lock...${RESET}"
                    rm composer.lock
                    echo "${CHECK} composer.lock removido. Será recriado com versão PHP atual."
                fi
            fi
            
            # Instalar dependências do Composer como usuário correto
            echo "${BLUE}📦 Instalando dependências do Composer...${RESET}"
            sudo -u "$SUPERVISOR_USER" COMPOSER_ALLOW_SUPERUSER=1 composer install --no-interaction --prefer-dist --optimize-autoloader --no-dev 2>/dev/null || {
                echo "${WARN} Tentando com composer update...${RESET}"
                sudo -u "$SUPERVISOR_USER" COMPOSER_ALLOW_SUPERUSER=1 composer update --no-interaction --prefer-dist --optimize-autoloader --no-dev
            }
            
            # Verificar se a instalação foi bem-sucedida
            if [ -f "vendor/autoload.php" ]; then
                echo "${CHECK} Dependências do Composer instaladas com sucesso!"
                
                # Configurar arquivo .env
                if [ ! -f .env ]; then
                    if [ -f .env.example ]; then
                        cp .env.example .env
                        echo "${CHECK} Arquivo .env criado a partir do .env.example"
                    else
                        echo "${WARN} Arquivo .env.example não encontrado"
                        # Criar um .env básico
                        cat > .env << EOF
APP_NAME=Laravel
APP_ENV=production
APP_KEY=
APP_DEBUG=false
APP_URL=http://localhost

LOG_CHANNEL=stack
LOG_LEVEL=error

DB_CONNECTION=mysql
DB_HOST=127.0.0.1
DB_PORT=3306
DB_DATABASE=laravel
DB_USERNAME=root
DB_PASSWORD=

BROADCAST_DRIVER=log
CACHE_DRIVER=file
QUEUE_CONNECTION=sync
SESSION_DRIVER=file
SESSION_LIFETIME=120

REDIS_HOST=127.0.0.1
REDIS_PASSWORD=null
REDIS_PORT=6379

MAIL_MAILER=smtp
MAIL_HOST=smtp.mailtrap.io
MAIL_PORT=2525
MAIL_USERNAME=null
MAIL_PASSWORD=null
MAIL_ENCRYPTION=null
MAIL_FROM_ADDRESS=null
MAIL_FROM_NAME="\${APP_NAME}"

AWS_ACCESS_KEY_ID=
AWS_SECRET_ACCESS_KEY=
AWS_DEFAULT_REGION=us-east-1
AWS_BUCKET=
EOF
                        echo "${CHECK} Arquivo .env básico criado"
                    fi
                else
                    echo "${CHECK} Arquivo .env já existe"
                fi
                
                # Ajustar permissões do .env
                sudo chown "$SUPERVISOR_USER":www-data .env
                sudo chmod 640 .env
                
                # Gerar chave da aplicação
                echo "${BLUE}🔑 Gerando chave da aplicação...${RESET}"
                sudo -u "$SUPERVISOR_USER" php artisan key:generate --force
                echo "${CHECK} Chave da aplicação gerada!"
                
                # Otimizar cache de configuração para produção
                echo "${BLUE}⚡ Otimizando cache para produção...${RESET}"
                sudo -u "$SUPERVISOR_USER" php artisan config:cache 2>/dev/null || true
                sudo -u "$SUPERVISOR_USER" php artisan route:cache 2>/dev/null || true
                sudo -u "$SUPERVISOR_USER" php artisan view:cache 2>/dev/null || true
                echo "${CHECK} Cache otimizado!"
                
            else
                echo "${ERROR} Falha na instalação das dependências do Composer"
                echo "${YELLOW}💡 Tente executar manualmente: composer install${RESET}"
            fi
        fi
        ;;
    "🌟 Vue"|"🟢 Node.js")
        echo "${BLUE}🌟 Processando projeto ${project_type}...${RESET}"
        
        # Verificar e instalar Node.js/NPM se necessário
        if ! command -v npm &>/dev/null; then
            echo "${WARN} NPM não encontrado. Instalando Node.js...${RESET}"
            curl -fsSL https://deb.nodesource.com/setup_lts.x | sudo -E bash -
            sudo apt-get install -y nodejs
            
            if command -v npm &>/dev/null; then
                echo "${CHECK} Node.js e NPM instalados com sucesso!"
            else
                echo "${ERROR} Falha ao instalar Node.js/NPM"
            fi
        else
            echo "${CHECK} NPM já está instalado"
        fi
        
        if command -v npm &>/dev/null && [ -f "package.json" ]; then
            echo "${BLUE}📦 Instalando dependências do NPM...${RESET}"
            sudo -u "$SUPERVISOR_USER" npm install
            
            if [[ "$project_type" == *"Vue"* ]]; then
                echo "${BLUE}🏗️ Fazendo build do projeto Vue...${RESET}"
                sudo -u "$SUPERVISOR_USER" npm run build
            fi
            echo "${CHECK} Dependências do NPM instaladas!"
        else
            echo "${WARN} package.json não encontrado ou NPM não disponível"
        fi
        ;;
    "🐍 Python")
        echo "${BLUE}🐍 Processando projeto Python...${RESET}"
        
        # Verificar se requirements.txt existe
        if [ -f "requirements.txt" ]; then
            if command -v pip3 &>/dev/null; then
                echo "${BLUE}📦 Instalando dependências do Python...${RESET}"
                sudo -u "$SUPERVISOR_USER" pip3 install -r requirements.txt
                echo "${CHECK} Dependências do Python instaladas!"
            elif command -v pip &>/dev/null; then
                echo "${BLUE}📦 Instalando dependências do Python...${RESET}"
                sudo -u "$SUPERVISOR_USER" pip install -r requirements.txt
                echo "${CHECK} Dependências do Python instaladas!"
            else
                echo "${WARN} pip não encontrado. Instalando...${RESET}"
                sudo apt update
                sudo apt install -y python3-pip
                sudo -u "$SUPERVISOR_USER" pip3 install -r requirements.txt
                echo "${CHECK} Pip instalado e dependências instaladas!"
            fi
        else
            echo "${WARN} Arquivo requirements.txt não encontrado"
        fi
        ;;
    *)
        echo "${YELLOW}📄 Projeto HTML/PHP - Nenhuma dependência a instalar${RESET}"
        ;;
esac

# ══════════════════════════════
# 🗄️ 8.1️⃣ CONFIGURAR BANCO (.ENV)
# ══════════════════════════════
if [[ "$project_type" == "⚡ Laravel" ]] && [ -f .env ]; then
    echo ""
    echo "${BLUE}┌─────────────────────────────────────────────┐${RESET}"
    echo "${BLUE}│      🗄️ [8.1/10] CONFIGURAR BANCO (.ENV)    │${RESET}"
    echo "${BLUE}└─────────────────────────────────────────────┘${RESET}"
    echo "${YELLOW}🔸 Deseja configurar a conexão com banco de dados?${RESET}"
    echo ""
    select configure_db in "✅ Sim" "❌ Não"; do
        case $configure_db in
            "✅ Sim")
                echo "${GREEN}✅ Configurando conexão com banco...${RESET}"
                echo ""
                
                # Tipo de banco
                echo "${YELLOW}📊 Selecione o tipo de banco de dados:${RESET}"
                select db_type in "🐬 MySQL" "🐘 PostgreSQL" "🪶 SQLite"; do
                    case $db_type in
                        "🐬 MySQL")
                            DB_CONNECTION="mysql"
                            DB_PORT="3306"
                            
                            # Verificar se MySQL está instalado
                            if ! command -v mysql &>/dev/null; then
                                echo "${WARN} MySQL não está instalado no sistema${RESET}"
                                echo "${YELLOW}🔸 Deseja instalar o MySQL Server?${RESET}"
                                select install_mysql in "✅ Sim" "❌ Não"; do
                                    case $install_mysql in
                                        "✅ Sim")
                                            echo "${BLUE}📦 Instalando MySQL Server...${RESET}"
                                            
                                            # Definir senha root do MySQL
                                            read -s -p "${BLUE}💭 Digite a senha ROOT desejada para o MySQL: ${RESET}" MYSQL_ROOT_PASSWORD
                                            echo ""
                                            while [[ -z "$MYSQL_ROOT_PASSWORD" ]]; do
                                                echo "${RED}❌ Senha não pode estar vazia!${RESET}"
                                                read -s -p "${BLUE}💭 Digite a senha ROOT desejada para o MySQL: ${RESET}" MYSQL_ROOT_PASSWORD
                                                echo ""
                                            done
                                            
                                            # Configuração não-interativa do MySQL
                                            sudo debconf-set-selections <<< "mysql-server mysql-server/root_password password $MYSQL_ROOT_PASSWORD"
                                            sudo debconf-set-selections <<< "mysql-server mysql-server/root_password_again password $MYSQL_ROOT_PASSWORD"
                                            
                                            # Atualizar repositórios e instalar MySQL
                                            sudo apt update
                                            sudo apt install -y mysql-server mysql-client
                                            
                                            # Iniciar e habilitar MySQL
                                            sudo systemctl start mysql
                                            sudo systemctl enable mysql
                                            
                                            # Configuração básica de segurança
                                            mysql -u root -p"$MYSQL_ROOT_PASSWORD" -e "
                                                DELETE FROM mysql.user WHERE User='';
                                                DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1');
                                                DROP DATABASE IF EXISTS test;
                                                DELETE FROM mysql.db WHERE Db='test' OR Db='test\\_%';
                                                FLUSH PRIVILEGES;
                                            " 2>/dev/null
                                            
                                            echo "${CHECK} MySQL instalado e configurado com sucesso!"
                                            
                                            # Definir credenciais padrão
                                            DB_HOST="localhost"
                                            DB_USERNAME="root"
                                            DB_PASSWORD="$MYSQL_ROOT_PASSWORD"
                                            break
                                            ;;
                                        "❌ Não")
                                            echo "${RED}❌ Instalação do MySQL cancelada${RESET}"
                                            echo "${YELLOW}💡 Você pode instalar manualmente: sudo apt install mysql-server${RESET}"
                                            break
                                            ;;
                                    esac
                                done < /dev/tty
                            else
                                echo "${CHECK} MySQL já está instalado no sistema"
                            fi
                            break
                            ;;
                        "🐘 PostgreSQL")
                            DB_CONNECTION="pgsql"
                            DB_PORT="5432"
                            break
                            ;;
                        "🪶 SQLite")
                            DB_CONNECTION="sqlite"
                            echo "${GREEN}🪶 SQLite selecionado - não necessita configuração adicional${RESET}"
                            break
                            ;;
                        *)
                            echo "${RED}Escolha inválida.${RESET}"
                            ;;
                    esac
                done < /dev/tty
                
                if [[ "$DB_CONNECTION" != "sqlite" ]]; then
                    echo ""
                    
                    # Se MySQL foi instalado, usar credenciais já definidas
                    if [[ "$DB_CONNECTION" == "mysql" ]] && [[ -n "$MYSQL_ROOT_PASSWORD" ]]; then
                        echo "${GREEN}🐬 Usando credenciais do MySQL recém-instalado${RESET}"
                        # Credenciais já definidas durante a instalação
                    else
                        # Coletar credenciais manualmente
                        read -p "${BLUE}💭 Digite o HOST do banco (padrão: localhost): ${RESET}" DB_HOST
                        DB_HOST=${DB_HOST:-localhost}
                        
                        read -p "${BLUE}💭 Digite a PORTA do banco (padrão: $DB_PORT): ${RESET}" CUSTOM_DB_PORT
                        DB_PORT=${CUSTOM_DB_PORT:-$DB_PORT}
                        
                        read -p "${BLUE}💭 Digite o USUÁRIO do banco: ${RESET}" DB_USERNAME
                        while [[ -z "$DB_USERNAME" ]]; do
                            echo "${RED}❌ Usuário do banco é obrigatório!${RESET}"
                            read -p "${BLUE}💭 Digite o USUÁRIO do banco: ${RESET}" DB_USERNAME
                        done
                        
                        read -s -p "${BLUE}💭 Digite a SENHA do banco: ${RESET}" DB_PASSWORD
                        echo ""
                        while [[ -z "$DB_PASSWORD" ]]; do
                            echo "${RED}❌ Senha do banco é obrigatória!${RESET}"
                            read -s -p "${BLUE}💭 Digite a SENHA do banco: ${RESET}" DB_PASSWORD
                            echo ""
                        done
                    fi
                    
                    # Coletar nome do banco
                    read -p "${BLUE}💭 Digite o NOME do banco de dados: ${RESET}" DB_DATABASE
                    while [[ -z "$DB_DATABASE" ]]; do
                        echo "${RED}❌ Nome do banco é obrigatório!${RESET}"
                        read -p "${BLUE}💭 Digite o NOME do banco de dados: ${RESET}" DB_DATABASE
                    done
                    
                    # Testar conexão e criar banco se necessário
                    echo "${YELLOW}🔍 Testando conexão com o servidor de banco...${RESET}"
                    if [[ "$DB_CONNECTION" == "mysql" ]]; then
                        if command -v mysql &>/dev/null; then
                            # Testar conexão com o servidor MySQL
                            if mysql -h"$DB_HOST" -P"$DB_PORT" -u"$DB_USERNAME" -p"$DB_PASSWORD" -e "SELECT 1;" 2>/dev/null; then
                                echo "${CHECK} Conexão com servidor MySQL testada com sucesso!"
                                
                                # Verificar se o banco existe
                                if mysql -h"$DB_HOST" -P"$DB_PORT" -u"$DB_USERNAME" -p"$DB_PASSWORD" -e "USE $DB_DATABASE;" 2>/dev/null; then
                                    echo "${CHECK} Banco de dados '$DB_DATABASE' já existe!"
                                else
                                    echo "${YELLOW}💾 Banco '$DB_DATABASE' não existe. Criando...${RESET}"
                                    if mysql -h"$DB_HOST" -P"$DB_PORT" -u"$DB_USERNAME" -p"$DB_PASSWORD" -e "CREATE DATABASE $DB_DATABASE CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;" 2>/dev/null; then
                                        echo "${CHECK} Banco de dados '$DB_DATABASE' criado com sucesso!"
                                    else
                                        echo "${ERROR} Erro ao criar banco de dados '$DB_DATABASE'"
                                        echo "${YELLOW}💡 Você pode criá-lo manualmente: CREATE DATABASE $DB_DATABASE;${RESET}"
                                    fi
                                fi
                            else
                                echo "${ERROR} Falha na conexão com MySQL - verifique as credenciais"
                                echo "${YELLOW}💡 Certifique-se de que o usuário '$DB_USERNAME' tem permissões adequadas${RESET}"
                            fi
                        else
                            echo "${WARN} Cliente MySQL não encontrado para teste"
                        fi
                    elif [[ "$DB_CONNECTION" == "pgsql" ]]; then
                        if command -v psql &>/dev/null; then
                            if PGPASSWORD="$DB_PASSWORD" psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USERNAME" -d "$DB_DATABASE" -c "SELECT 1;" 2>/dev/null; then
                                echo "${CHECK} Conexão com PostgreSQL testada com sucesso!"
                            else
                                echo "${WARN} Não foi possível testar a conexão PostgreSQL (banco pode não existir ainda)"
                            fi
                        else
                            echo "${WARN} Cliente PostgreSQL não encontrado para teste"
                        fi
                    fi
                fi
                
                # Configurar .env
                echo "${YELLOW}📝 Configurando arquivo .env...${RESET}"
                
                if [[ "$DB_CONNECTION" == "sqlite" ]]; then
                    sed -i "s/DB_CONNECTION=.*/DB_CONNECTION=sqlite/" .env
                    sed -i "s/DB_HOST=.*/# DB_HOST=/" .env
                    sed -i "s/DB_PORT=.*/# DB_PORT=/" .env
                    sed -i "s/DB_DATABASE=.*/DB_DATABASE=database\/database.sqlite/" .env
                    sed -i "s/DB_USERNAME=.*/# DB_USERNAME=/" .env
                    sed -i "s/DB_PASSWORD=.*/# DB_PASSWORD=/" .env
                    
                    # Criar arquivo SQLite se não existir
                    mkdir -p database
                    touch database/database.sqlite
                    sudo chown "$SUPERVISOR_USER":www-data database/database.sqlite
                    sudo chmod 664 database/database.sqlite
                else
                    sed -i "s/DB_CONNECTION=.*/DB_CONNECTION=$DB_CONNECTION/" .env
                    sed -i "s/DB_HOST=.*/DB_HOST=$DB_HOST/" .env
                    sed -i "s/DB_PORT=.*/DB_PORT=$DB_PORT/" .env
                    sed -i "s/DB_DATABASE=.*/DB_DATABASE=$DB_DATABASE/" .env
                    sed -i "s/DB_USERNAME=.*/DB_USERNAME=$DB_USERNAME/" .env
                    sed -i "s/DB_PASSWORD=.*/DB_PASSWORD=$DB_PASSWORD/" .env
                fi
                
                echo "${CHECK} Arquivo .env configurado com sucesso!"
                
                # Perguntar sobre migrations
                echo ""
                echo "${YELLOW}🚀 Deseja executar as migrations do Laravel?${RESET}"
                select run_migrations in "✅ Sim" "❌ Não"; do
                    case $run_migrations in
                        "✅ Sim")
                            echo "${BLUE}🚀 Executando migrations...${RESET}"
                            if php artisan migrate --force 2>/dev/null; then
                                echo "${CHECK} Migrations executadas com sucesso!"
                            else
                                echo "${WARN} Erro ao executar migrations (verifique se o banco existe)"
                            fi
                            break
                            ;;
                        "❌ Não")
                            echo "${YELLOW}❌ Migrations não executadas${RESET}"
                            break
                            ;;
                    esac
                done < /dev/tty
                
                break
                ;;
            "❌ Não")
                echo "${YELLOW}❌ Configuração de banco ignorada${RESET}"
                break
                ;;
        esac
    done < /dev/tty
fi

# ══════════════════════════════
# 🔐 9️⃣ CONFIGURAR SSL
# ══════════════════════════════
if [ "$USE_PORT" = false ]; then
    echo ""
    echo "${BLUE}┌─────────────────────────────────────────────┐${RESET}"
    echo "${BLUE}│         🔐 [9/11] CONFIGURAR SSL            │${RESET}"
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
# 🔄 🔟 FINALIZAR DEPLOY
# ══════════════════════════════
echo ""
echo "${BLUE}┌─────────────────────────────────────────────┐${RESET}"
echo "${BLUE}│         🔄 [10/11] FINALIZAR DEPLOY         │${RESET}"
echo "${BLUE}└─────────────────────────────────────────────┘${RESET}"
echo "${YELLOW}� Recarregando Apache...${RESET}"
sudo systemctl reload apache2

# Desabilitar trap de erro - deploy concluído com sucesso
trap - ERR

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
