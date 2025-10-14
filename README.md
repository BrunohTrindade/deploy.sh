# 🚀 Deploy Automático Apache v3

<div align="center">

![Deploy](https://img.shields.io/badge/Deploy-Automático-brightgreen?style=for-the-badge&logo=apache)
![Version](https://img.shields.io/badge/Version-3.0-blue?style=for-the-badge)
![OS](https://img.shields.io/badge/OS-Ubuntu%20%7C%20Debian-orange?style=for-the-badge&logo=linux)
![License](https://img.shields.io/badge/License-MIT-yellow?style=for-the-badge)

**🎯 Deploy seus projetos web em segundos com Apache configurado automaticamente!**

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
| 🔐 **SSL/HTTPS** | Certificado SSL com Certbot (Let's Encrypt) |
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

### **10 Passos Visuais e Interativos:**

```
┌─────────────────────────────────────────────┐
│          📂 [1/10] FONTE DO PROJETO         │
└─────────────────────────────────────────────┘
🔸 Diretório local ou Git Clone

┌─────────────────────────────────────────────┐
│        👤 [2/10] USUÁRIO SUPERVISOR         │
└─────────────────────────────────────────────┘
🔸 Detecção automática do usuário www-data

┌─────────────────────────────────────────────┐
│        🔒 [3/10] AJUSTAR PERMISSÕES         │
└─────────────────────────────────────────────┘
🔸 Configuração de segurança automática

┌─────────────────────────────────────────────┐
│         🚀 [4/10] TIPO DE PROJETO          │
└─────────────────────────────────────────────┘
🔸 Laravel, Vue, Node.js, Python ou HTML/PHP

┌─────────────────────────────────────────────┐
│         🌐 [5/10] TIPO DE ACESSO           │
└─────────────────────────────────────────────┘
🔸 Domínio personalizado ou porta específica

... e mais 5 passos automatizados!
```

---

## 🛠️ **Projetos Suportados**

<div align="center">

| Framework | Emoji | Auto-Config | Dependências |
|-----------|-------|-------------|--------------|
| **Laravel** | ⚡ | ✅ Public folder | Composer + .env |
| **Vue.js** | 🌟 | ✅ Dist folder | NPM + Build |
| **Node.js** | 🟢 | ✅ Root folder | NPM install |
| **Python** | 🐍 | ✅ Root folder | PIP requirements |
| **HTML/PHP** | 📄 | ✅ Root folder | Nenhuma |

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

---

## 🎊 **Resultado Final**

Após a execução, você verá:

```
╔═══════════════════════════════════════════════╗
║              🎉 DEPLOY CONCLUÍDO! 🎉          ║
╠═══════════════════════════════════════════════╣
║ 📦 Projeto: meu-site                          ║
║ 🌐 Acesso: https://meusite.com                ║
║ 📅 Deploy: 14/10/2025 15:30:45               ║
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