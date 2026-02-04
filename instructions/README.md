# 📚 Documentação MOV Platform

Guias completos para desenvolvimento, deploy, operação e manutenção da plataforma.

---

## 📋 Índice de Guias

| Guia                                             | Descrição             | Quando Usar                          |
| ------------------------------------------------ | --------------------- | ------------------------------------ |
| **[DEPLOY.md](DEPLOY.md)** ⭐                    | **Deploy VPS Ubuntu** | **PRODUÇÃO** - Guia único definitivo |
| **[DEV-WORKFLOW.md](DEV-WORKFLOW.md)**           | Desenvolvimento local | Trabalhar localmente                 |
| **[UPDATES.md](UPDATES.md)**                     | Atualizar plataforma  | Aplicar mudanças                     |
| **[MQTT-CERT-RENEWAL.md](MQTT-CERT-RENEWAL.md)** | Certificados MQTT     | Troubleshooting SSL                  |

**Scripts:**

- **Setup Wizard:** `bash scripts/setup_wizard.sh` (configuração interativa)
- **Deploy:** `bash scripts/deploy.sh` (deploy em produção)
- Ver guia completo: [../scripts/SETUP-WIZARD-GUIDE.md](../scripts/SETUP-WIZARD-GUIDE.md)

---

## 🚀 Início Rápido por Cenário

### 🆕 Primeira Vez - Desenvolvimento Local

```bash
# 1. Configurar ambiente
bash scripts/setup_wizard.sh
# Escolha: Development

# 2. Iniciar plataforma
docker compose up -d

# 3. Acessar
# Grafana: http://localhost:3000
```

Guia detalhado: [DEV-WORKFLOW.md](DEV-WORKFLOW.md)

---

### 🚀 Deploy em Produção - VPS Hostinger

```bash
# 1. Conectar na VPS
ssh root@SEU_IP_VPS

# 2. Instalar Docker
curl -fsSL https://get.docker.com | sh

# 3. Clonar projeto
git clone <repo> && cd MOV-Plataform

# 4. Configurar (wizard interativo)
bash scripts/setup_wizard.sh
# Escolha: Production

# 5. Deploy
bash scripts/deploy.sh

# 6. Configurar firewall
bash scripts/setup_firewall.sh

# 7. SSL (se tiver domínio)
bash scripts/setup_ssl.sh seudominio.com
```

**Guia completo:** [DEPLOY.md](DEPLOY.md) ⭐

---

### 🔄 Atualizar Código em Produção

````bash
# 1. Backup primeiro!
bash scripts/backup.sh

# 2. Atualizar
bash scripts/update.sh

---

### 🔄 Preciso Atualizar o Código

**Local (desenvolvimento):**

1. Faça mudanças no código
2. Teste: `docker compose up -d --build [serviço]`
3. Commit: `git add . && git commit -m "..."`
4. Push: `git push`

**VPS (produção):**

1. **Backup primeiro!** `sudo /usr/local/bin/mov_remote_backup.sh`
2. Leia [UPDATES.md](UPDATES.md) - tipo de mudança correspondente
3. Na VPS: `git pull`
4. Rebuild: `docker compose -f docker-compose.yml -f docker-compose.prod.yml up -d --build`

---

### 🐛 Troubleshooting

**Containers não iniciam:**

```bash
# Ver logs
docker compose logs -f [serviço]

# Verificar status
docker compose ps

# Recriar completamente
docker compose down && docker compose up -d
````

**Certificados MQTT expirados:**

- Consulte [MQTT-CERT-RENEWAL.md](MQTT-CERT-RENEWAL.md)
- Renovação manual: `sudo /usr/local/bin/renew_mqtt_certs.sh`

**Grafana não carrega:**

```bash
# Verificar se está rodando
docker compose ps grafana

# Ver logs
docker compose logs grafana

# Reiniciar
docker compose restart grafana
```

**Backup falhou:**

```bash
# Ver logs do backup local
docker compose logs backup_job

# Ver logs do backup remoto
tail -50 /var/log/mov_remote_backup.log

# Executar backup manual
sudo /usr/local/bin/mov_remote_backup.sh
```

---

## 📖 Estrutura de Cada Guia

### DEPLOY.md

- ✅ Pré-requisitos (VPS, domínio, Docker)
- ✅ Configuração passo a passo (8 etapas)
- ✅ Scripts automatizados
- ✅ Configuração de SSL/TLS
- ✅ Configuração de firewall
- ✅ Backup remoto
- ✅ Testes e validação

### DEV-WORKFLOW.md

- ✅ Setup inicial em nova máquina
- ✅ Clonar e configurar projeto
- ✅ Workflow diário (pull, edit, push)
- ✅ Trabalhar em equipe
- ✅ Sincronizar mudanças via Git
- ✅ Testar localmente antes de produção

### UPDATES.md

- ✅ Tipos de mudança (código, config, dashboard)
- ✅ Procedimento por tipo de atualização
- ✅ Atualização em desenvolvimento
- ✅ Atualização em produção
- ✅ Backup antes de atualizar (⚠️ IMPORTANTE)
- ✅ Scripts de update rápido

### MQTT-CERT-RENEWAL.md

- ✅ Renovação automática de certificados
- ✅ Verificação de status
- ✅ Renovação manual
- ✅ Troubleshooting de conexão
- ✅ Logs e auditoria
- ✅ Estrutura de arquivos

---

## 🔗 Links Rápidos

### Scripts Disponíveis

| Script                | Comando                                       | Descrição                           |
| --------------------- | --------------------------------------------- | ----------------------------------- |
| **Setup Inicial**     | `bash scripts/setup.sh`                       | Cria estrutura e gera credenciais   |
| **Deploy Produção**   | `bash scripts/deploy.sh`                      | Deploy completo em VPS              |
| **Firewall**          | `sudo bash scripts/setup_firewall.sh`         | Configura UFW automaticamente       |
| **SSL/TLS**           | `sudo bash scripts/setup_ssl.sh dominio.com`  | Let's Encrypt + renovação MQTT      |
| **Backup Remoto**     | `bash scripts/setup_remote_backup.sh`         | Configura backup em nuvem           |
| **Gerar Credenciais** | `bash scripts/generate_credentials.sh > .env` | Regenerar senhas                    |
| **Update**            | `bash scripts/update.sh`                      | Atualização rápida (pull + rebuild) |

### Arquivos Importantes

- **`.env`** - Credenciais (NUNCA commitar)
- **`docker-compose.yml`** - Configuração de desenvolvimento
- **`docker-compose.prod.yml`** - Overlay de produção
- **`mosquitto/config/mosquitto.conf`** - Configuração MQTT
- **`telegraf/config/telegraf.conf`** - Configuração de coleta
- **`nginx/conf.d/default.conf`** - Proxy reverso

---

## 💡 Boas Práticas

### ✅ Sempre Fazer

- **Backup antes de mudanças** em produção
- **Testar localmente** antes de enviar para VPS
- **Ver logs** após deploy/update
- **Commitar `.gitignore`** (proteger `.env`)
- **Documentar mudanças** no commit message

### ❌ Nunca Fazer

- **Commitar arquivo `.env`** no Git
- **Fazer `docker compose down -v`** sem backup (apaga dados!)
- **Editar produção sem backup** (RTO de 30 minutos se tiver backup)
- **Usar senhas fracas** (usar sempre `generate_credentials.sh`)
- **Expor InfluxDB/Grafana** diretamente (usar Nginx proxy)

---

## 📞 Suporte

- **Issues:** Abrir issue no GitHub
- **Segurança:** Consultar [SECURITY-REPORT.md](../SECURITY-REPORT.md)
- **Arquitetura:** Consultar [README.md](../README.md)

---

**Última atualização:** Fevereiro 2025  
**Versão da documentação:** 3.0
