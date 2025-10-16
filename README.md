# 🚀 Deploy Automático Apache v3.6

<div align="center">

![Deploy](https://img.shields.io/badge/Deploy-Automático-brightgreen?style=for-the-badge&logo=apache)
![Version](https://img.shields.io/badge/Version-3.6-blue?style=for-the-badge)
![OS](https://img.shields.io/badge/OS-Ubuntu%20%7C%20Debian-orange?style=for-the-badge&logo=linux)
![License](https://img.shields.io/badge/License-MIT-yellow?style=for-the-badge)

**🎯 Deploy seus projetos web em segundos com Apache configurado automaticamente!**

**✨ NOVO v3.6: Migrations com config:clear + Diagnóstico completo de deploy!**

</div>

---

## ✨ **O que este script faz?**

Este script **revolucionário** automatiza completamente o deploy de projetos web no Apache, desde a configuração inicial até a finalização com SSL. **Sem complicações, sem configurações manuais!**

### 🎪 **Funcionalidades Principais**

| Recurso | Descrição |
|---------|-----------|
| 📂 **Multi-Source** | Deploy de diretório local ou repositório Git |
| 🚀 **Multi-Framework** | Laravel, Vue.js, Node.js, Python e HTML/PHP |
| 🌐 **Acesso Flexível** | Por domínio personalizado ou porta específica |
| 🔒 **Segurança** | Configuração automática de permissões |
| ⚙️ **Apache Auto** | VirtualHost criado automaticamente |
| 📦 **Dependências** | Instalação automática (Composer, NPM, PIP) |
| 🔧 **Fix Automático** | Corrige problemas de permissão, Git e compatibilidade |
| 🐘 **PHP Smart** | Verificação de compatibilidade de versão PHP |
| 🔄 **Rollback Auto** | Reverte tudo automaticamente se algo falhar |
| 🧪 **Teste Automático** | Valida se o site está funcionando após deploy |
| 🔍 **Diagnóstico** | Identifica problemas automaticamente se algo falhar |
| �🗄️ **Banco Dados** | Configuração automática do .env (MySQL, PostgreSQL, SQLite) |
| 🐬 **MySQL Auto** | Instalação automática do MySQL + Criação de bancos |
| 🚀 **Migrations** | Execução opcional de migrations do Laravel |
| �🔐 **SSL/HTTPS** | Certificado SSL com Certbot (Let's Encrypt) |
| 📊 **Logs** | Sistema completo de logs de deploy |

---

## 🚀 **Instalação Ultra-Rápida**

### **Uma linha. Pronto. Funcionando.**

```bash
curl -s https://raw.githubusercontent.com/BrunohTrindade/deploy.sh/refs/heads/main/deploy.sh | bash
```

> 💡 **Isso é tudo!** O script será baixado e executado automaticamente.

---

## 🎯 **Como Funciona**

### **11 Passos Visuais e Interativos:**

```
┌─────────────────────────────────────────────┐
│          📂 [1/11] FONTE DO PROJETO         │
└─────────────────────────────────────────────┘
🔸 Diretório local ou Git Clone

┌─────────────────────────────────────────────┐
│        👤 [2/11] USUÁRIO SUPERVISOR         │
└─────────────────────────────────────────────┘
🔸 Detecção automática do usuário www-data

┌─────────────────────────────────────────────┐
│        🔒 [3/11] AJUSTAR PERMISSÕES         │
└─────────────────────────────────────────────┘
🔸 Configuração de segurança automática

┌─────────────────────────────────────────────┐
│         🚀 [4/11] TIPO DE PROJETO          │
└─────────────────────────────────────────────┘
🔸 Laravel, Vue, Node.js, Python ou HTML/PHP

┌─────────────────────────────────────────────┐
│         🌐 [5/11] TIPO DE ACESSO           │
└─────────────────────────────────────────────┘
🔸 Domínio personalizado ou porta específica

┌─────────────────────────────────────────────┐
│      🗄️ [8.1/11] CONFIGURAR BANCO (.ENV)   │
└─────────────────────────────────────────────┘
🔸 MySQL, PostgreSQL ou SQLite + Migrations

... e mais 6 passos automatizados!
```

---

## 🛠️ **Projetos Suportados**

<div align="center">

| Framework | Emoji | Auto-Config | Dependências | Banco |
|-----------|-------|-------------|--------------|--------|
| **Laravel** | ⚡ | ✅ Public folder | Composer + .env + Key | � MySQL Auto-Install + Create DB |
| **Vue.js** | 🌟 | ✅ Dist folder | NPM + Build | ❌ N/A |
| **Node.js** | 🟢 | ✅ Root folder | NPM install | ❌ N/A |
| **Python** | 🐍 | ✅ Root folder | PIP requirements | ❌ N/A |
| **HTML/PHP** | 📄 | ✅ Root folder | Nenhuma | ❌ N/A |

</div>

---

## 🌍 **Exemplos de Uso**

### **🔗 Deploy via Git Clone**
```bash
# O script perguntará:
# 💭 Digite o link do repositório Git: 
# https://github.com/usuario/meu-projeto.git
```

### **📁 Deploy Diretório Local**
```bash
# O script perguntará:
# 💭 Digite o caminho completo do projeto: 
# /var/www/meusite
```

### **🌐 Acesso por Domínio**
```bash
# 💭 Digite o domínio (ex: exemplo.com): 
# meusite.com
# ✅ SSL automático com Let's Encrypt!
```

### **🔌 Acesso por Porta**
```bash
# 💡 Porta sugerida livre: 8001
# 💭 Digite a porta desejada (padrão 8001): 
# http://localhost:8001
```

### **🗄️ Configuração de Banco (Laravel)**
```bash
# 🔸 Deseja configurar a conexão com banco de dados?
# ✅ Sim

# 📊 Selecione o tipo de banco de dados:
# 🐬 MySQL

# ⚠️ MySQL não está instalado no sistema
# 🔸 Deseja instalar o MySQL Server?
# ✅ Sim
# 💭 Digite a senha ROOT desejada para o MySQL: ********
# � Instalando MySQL Server...
# ✅ MySQL instalado e configurado com sucesso!

# � Usando credenciais do MySQL recém-instalado
# 💭 Digite o NOME do banco de dados: meu_laravel_app

# 🔍 Testando conexão com o servidor de banco...
# ✅ Conexão com servidor MySQL testada com sucesso!
# 💾 Banco 'meu_laravel_app' não existe. Criando...
# ✅ Banco de dados 'meu_laravel_app' criado com sucesso!

# 📝 Configurando arquivo .env...
# ✅ Arquivo .env configurado com sucesso!

# 🚀 Deseja executar as migrations do Laravel?
# ✅ Sim
# 🚀 Executando migrations...
# ✅ Migrations executadas com sucesso!
```

---

## 🔧 **Correções Automáticas v3.4**

### **🛠️ Problemas Corrigidos Automaticamente:**

- ❌➡️✅ **Composer como root**: Executa como usuário correto
- ❌➡️✅ **Git ownership**: Adiciona diretório ao safe.directory
- ❌➡️✅ **PHP incompatível**: Remove composer.lock e atualiza dependências
- ❌➡️✅ **Versão PHP**: Verifica compatibilidade e para se incompatível
- ❌➡️✅ **Rollback**: Reverte todas as mudanças se algo falhar
- ❌➡️✅ **Permissões**: Ajusta ownership antes da instalação
- ❌➡️✅ **Cache produção**: Otimiza automaticamente para performance
- ❌➡️✅ **Segurança .env**: Define permissões 640 no arquivo

### **🎯 Fluxo de Recuperação:**
1. **Detecta** problemas automaticamente
2. **Remove** composer.lock se incompatível
3. **Executa** composer update quando necessário  
4. **Aplica** permissões corretas
5. **Otimiza** cache para produção

---

## 🧪 **Deploy Testing & Diagnostics v3.6**

### **🎯 Novas Funcionalidades:**

- **🔄 Config Clear**: Executa `php artisan config:clear` antes das migrations
- **🧪 Teste Automático**: Valida se site está respondendo após deploy
- **🔍 Diagnóstico Inteligente**: Identifica problemas automaticamente
- **📊 Validação Apache**: Testa configuração antes de aplicar
- **⚡ Reload Estratégico**: Recarrega Apache nos momentos certos

### **🔧 Fluxo de Validação:**

```bash
# 🔄 Limpando cache de configuração...
# ✅ Cache de configuração limpo!
# 🚀 Executando migrations...
# ✅ Migrations executadas com sucesso!

# 🧪 [11/11] TESTE FINAL
# 🔍 Testando acesso ao site: http://localhost:8082
# ✅ Site respondendo corretamente!
# ✅ Laravel detectado na resposta!
```

### **🚨 Diagnóstico Automático se Falhar:**

```bash
# ❌ Site não está respondendo!
# 🔧 Diagnóstico rápido:
# ✅ Apache está rodando
# ✅ Site está habilitado  
# ✅ Porta 8082 está ouvindo
# ✅ DocumentRoot (/var/www/GPS-Tracker/public) existe
# ✅ DocumentRoot contém arquivos
# ✅ index.php do Laravel encontrado
# 💡 Tente acessar manualmente: http://localhost:8082
# 💡 Verifique os logs: sudo tail -f /var/log/apache2/GPS-Tracker_error.log
```

---

## 🔧 **Fix .env Database Connection v3.5**

### **🐛 Problema Resolvido:**

O Laravel estava falhando nas migrations com erro:
```
Access denied for user ''@'localhost' (using password: YES)
```

### **🎯 Causa Identificada:**
- ✅ Credenciais salvas corretamente no .env
- ❌ `DB_CONNECTION` não estava sendo definido
- ❌ Laravel usava configuração padrão incorreta

### **🔧 Solução Implementada:**
- **Verificação de escopo**: Garante que `DB_CONNECTION` está definido
- **Fallback inteligente**: Define `mysql` se variável estiver vazia
- **Debug visual**: Mostra valores sendo configurados
- **Validação pós-config**: Confirma se .env foi atualizado

### **📋 Output da Correção:**
```bash
📝 Atualizando .env com:
   DB_CONNECTION=mysql
   DB_HOST=localhost
   DB_PORT=3306
   DB_DATABASE=testando
   DB_USERNAME=root
   DB_PASSWORD=***

🔍 Verificando configuração do .env...
✅ DB_CONNECTION configurado corretamente
```

---

## �🔄 **Sistema de Rollback Automático v3.4**

### **🛡️ Proteção Total contra Falhas:**

- 🚨 **Detecta** qualquer erro durante o deploy
- 🔄 **Reverte** todas as mudanças automaticamente
- 🗑️ **Remove** configurações criadas
- ⚡ **Restaura** estado original do sistema

### **🎯 O que é Revertido:**

- **Configurações Apache**: Remove VirtualHost criado
- **Sites habilitados**: Desabilita site do Apache
- **Portas Listen**: Remove portas adicionadas ao ports.conf
- **Arquivos temporários**: Limpa arquivos criados
- **Estado Apache**: Recarrega configuração original

### **🔄 Fluxo de Rollback:**

```bash
# ❌ Erro detectado durante instalação...

# ╔═══════════════════════════════════════════════╗
# ║              ⚠️ INICIANDO ROLLBACK ⚠️           ║
# ╚═══════════════════════════════════════════════╝

# 🔄 Desabilitando site: meu-projeto.conf
# 🗑️ Removendo configuração Apache
# 🔄 Removendo porta do ports.conf
# 🔄 Recarregando Apache...
# ❌ Rollback concluído. Deploy foi revertido.
```

## 🐘 **PHP: Verificação de Compatibilidade v3.4**

### **🎯 Verificação Automática de Compatibilidade:**

- 🔍 **Detecta** versão PHP atual do sistema
- 📋 **Lê** requisitos PHP do `composer.json`
- ⚖️ **Compara** versões automaticamente
- 🚨 **Alerta** sobre incompatibilidades
- 📦 **Oferece** instalação da versão correta

### **🔄 Fluxo de Verificação:**

```bash
# 🔍 Verificando requisitos PHP do projeto...
# 📋 Projeto requer PHP: ^8.0
# 📋 Sistema possui PHP: 7.4.33

# 🔸 Deseja tentar instalar PHP 8.0?
# ✅ Sim

# 📦 Tentando instalar PHP 8.0...
# 📦 Adicionando repositório ondrej/php...
# 📦 Instalando PHP 8.0 e extensões...
# ✅ PHP atualizado para versão: 8.0.30

# ✅ Versão PHP compatível com o projeto!
```

### **🛠️ Recursos Avançados:**

- **Repositório ondrej/php**: Acesso a todas as versões PHP
- **Extensões automáticas**: Instala todas as extensões necessárias
- **Update-alternatives**: Define nova versão como padrão
- **Verificação pós-instalação**: Confirma compatibilidade
- **Opção de override**: Permite continuar mesmo com incompatibilidade

---

## �🐬 **MySQL: Instalação e Configuração Automática**

### **🎯 O que o script faz com MySQL:**

- 🔍 **Detecta** se MySQL já está instalado
- 📦 **Instala** MySQL Server se não estiver presente
- 🔐 **Configura** senha root de forma segura
- 🗄️ **Cria** o banco de dados automaticamente
- ✅ **Testa** conexão antes de configurar
- 📝 **Atualiza** arquivo `.env` do Laravel
- 🚀 **Executa** migrations (opcional)

### **🛡️ Configurações de Segurança Aplicadas:**
- Remove usuários anônimos padrão
- Remove acesso root remoto desnecessário
- Remove banco de teste padrão
- Aplica configurações recomendadas

---

## 🎊 **Resultado Final**

Após a execução, você verá:

```
╔═══════════════════════════════════════════════╗
║              🎉 DEPLOY CONCLUÍDO! 🎉         ║
╠═══════════════════════════════════════════════╣
║ 📦 Projeto: meu-laravel-app                   ║
║ 🌐 Acesso: https://meusite.com                ║
║ 🗄️ Banco: MySQL (meu_projeto)                 ║
║ 📅 Deploy: 15/10/2025 15:30:45               ║
╚═══════════════════════════════════════════════╝

🚀 Seu projeto está online e funcionando!
```

---

## 📋 **Pré-requisitos**

- 🐧 **SO**: Ubuntu 18.04+ ou Debian 9+
- 🔧 **Apache2**: Será instalado automaticamente se necessário
- 👤 **Usuário**: Acesso sudo
- 🌐 **Internet**: Para downloads e certificados SSL

---

## 📊 **Logs e Monitoramento**

O script mantém logs detalhados em:
```
~/deploy_logs/deploy_YYYYMMDD_HHMMSS.log
```

Perfeito para **debug** e **auditoria** de deploys!

---

## 🔧 **Solução de Problemas**

### **Problemas Comuns**

| Problema | Solução |
|----------|---------|
| ❌ Porta em uso | O script sugere automaticamente uma porta livre |
| ❌ Sem permissão | Execute com usuário que tenha acesso sudo |
| ❌ Domínio não resolve | Verifique DNS antes de configurar SSL |
| ❌ Dependências faltando | O script instala automaticamente quando possível |
| ❌ Erro na conexão DB | Verifique se o banco existe e as credenciais estão corretas |
| ❌ Migrations falham | Certifique-se que o banco foi criado antes de executar |
| ❌ Falha instalação MySQL | Execute: `sudo apt update && sudo apt install mysql-server` |
| ❌ Erro criar banco | Verifique permissões do usuário MySQL |
| ❌ Composer como root | **CORRIGIDO v3.3**: Executa como usuário correto automaticamente |
| ❌ Git ownership error | **CORRIGIDO v3.3**: Adiciona ao safe.directory automaticamente |
| ❌ PHP version mismatch | **CORRIGIDO v3.4**: Para deploy e orienta instalação manual |
| ❌ Deploy failure | **NOVO v3.4**: Sistema de rollback automático reverte tudo |

---

## 🤝 **Contribuição**

Encontrou um bug? Tem uma sugestão? 

1. 🍴 **Fork** este repositório
2. 🌿 Crie uma **branch** (`git checkout -b feature/MinhaFeature`)
3. 📝 **Commit** suas mudanças (`git commit -m 'Add: MinhaFeature'`)
4. 📤 **Push** para a branch (`git push origin feature/MinhaFeature`)
5. 🔄 Abra um **Pull Request**

---

## 📄 **Licença**

Este projeto está sob a licença **MIT**. Veja o arquivo [LICENSE](LICENSE) para mais detalhes.

---

## 👨‍💻 **Autor**

<div align="center">

**Bruno Trindade** + **GPT-5**

[![GitHub](https://img.shields.io/badge/GitHub-BrunohTrindade-black?style=for-the-badge&logo=github)](https://github.com/BrunohTrindade)

*"Automatizar deploys para focar no que realmente importa: código!"*

</div>

---

<div align="center">

### 🌟 **Se este projeto te ajudou, deixe uma ⭐!**

**Deploy automático nunca foi tão fácil!** 🚀

</div>