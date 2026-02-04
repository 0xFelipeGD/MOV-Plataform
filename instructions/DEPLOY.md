# 🚀 Deploy MOV Platform - VPS Ubuntu

**Guia único e definitivo para deploy em produção (VPS Hostinger/Ubuntu)**

---

## 📋 Checklist Pré-Deploy

Antes de começar, certifique-se de ter:

- [ ] VPS Hostinger ativa (Ubuntu 20.04/22.04/24.04)
- [ ] Acesso root via SSH
- [ ] IP público da VPS (ex: 203.45.67.89)
- [ ] Domínio (opcional, mas recomendado para SSL)
- [ ] Código do projeto em repositório Git

**Tempo estimado:** 30-45 minutos

---

## 🎯 FASE 1: Acesso Inicial à VPS Hostinger

### 1.1. Obter Credenciais SSH

No painel da Hostinger:

1. Vá em **VPS** → Sua VPS
2. Clique em **Informações SSH**
3. Anote:
   - **IP**: `203.45.67.89` (exemplo)
   - **Usuário**: `root`
   - **Senha**: (fornecida pela Hostinger)
   - **Porta SSH**: `22` (padrão)

### 1.2. Conectar via SSH

No seu computador (Linux/Mac/Windows com Git Bash):

```bash
# Conectar como root
ssh root@203.45.67.89

# Digite a senha quando solicitado
# Primeira vez: digite "yes" para aceitar fingerprint
```

✅ **Conectado!** Você verá algo como: `root@vps-123456:~#`

### 1.3. Atualizar Sistema

```bash
# Atualizar lista de pacotes
apt update

# Atualizar pacotes instalados
apt upgrade -y

# Instalar utilitários básicos
apt install -y curl git ufw htop nano
```

---

## 🐳 FASE 2: Instalar Docker e Docker Compose

### 2.1. Instalar Docker

```bash
# Script oficial Docker
curl -fsSL https://get.docker.com | sh

# Verificar instalação
docker --version
# Deve mostrar: Docker version 24.x.x ou superior
```

### 2.2. Instalar Docker Compose

```bash
# Já vem incluído no Docker moderno, verificar:
docker compose version

# Se não existir, instalar manualmente:
apt install -y docker-compose-plugin
```

### 2.3. Iniciar Docker

```bash
# Iniciar serviço
systemctl start docker

# Habilitar inicialização automática
systemctl enable docker

# Verificar status
systemctl status docker
# Deve estar "active (running)"
```

---

## 🔐 FASE 3: Configurar Firewall (UFW)

**ATENÇÃO:** Faça na ordem correta para não perder acesso SSH!

### 3.1. Configurar UFW

```bash
# Permitir SSH ANTES de ativar firewall (CRÍTICO!)
ufw allow 22/tcp comment 'SSH'

# Permitir portas da aplicação
ufw allow 80/tcp comment 'HTTP - Nginx'
ufw allow 443/tcp comment 'HTTPS - Nginx'
ufw allow 8883/tcp comment 'MQTT SSL - IoT Devices'

# Definir padrões
ufw default deny incoming
ufw default allow outgoing

# Ativar firewall
ufw --force enable

# Verificar regras
ufw status verbose
```

✅ **Saída esperada:**

```
Status: active

To                         Action      From
--                         ------      ----
22/tcp                     ALLOW       Anywhere
80/tcp                     ALLOW       Anywhere
443/tcp                    ALLOW       Anywhere
8883/tcp                   ALLOW       Anywhere
```

### 3.2. Portas Utilizadas

| Porta | Protocolo | Serviço        | Exposição                        |
| ----- | --------- | -------------- | -------------------------------- |
| 22    | TCP       | SSH            | Externa                          |
| 80    | TCP       | HTTP (Nginx)   | Externa                          |
| 443   | TCP       | HTTPS (Nginx)  | Externa                          |
| 8883  | TCP       | MQTT SSL       | Externa                          |
| 1883  | TCP       | MQTT (sem SSL) | **BLOQUEADA** (apenas localhost) |
| 3000  | TCP       | Grafana        | **BLOQUEADA** (via Nginx)        |
| 8086  | TCP       | InfluxDB       | **BLOQUEADA** (acesso interno)   |

---

## 📦 FASE 4: Clonar e Configurar Projeto

### 4.1. Criar Estrutura de Diretórios

```bash
# Criar pasta para projetos
mkdir -p /opt/apps
cd /opt/apps

# Clonar repositório
git clone https://github.com/seu-usuario/MOV-Plataform.git
cd MOV-Plataform

# Verificar estrutura
ls -la
```

### 4.2. Executar Setup Wizard

```bash
# Executar wizard interativo
bash scripts/setup_wizard.sh
```

**Responda as perguntas do wizard:**

```
Etapa 1/3: Escolha o Ambiente
  Selecione: 3 (Production - VPS com SSL, firewall, segurança máxima)

Etapa 2/3: Componentes para Instalar
  Grafana? [Y/n]: Y
  InfluxDB? [Y/n]: Y
  Mosquitto (MQTT)? [Y/n]: Y
  Telegraf? [Y/n]: Y
  Analytics (Python)? [Y/n]: Y
  Nginx? [Y/n]: Y
  Backup automático? [Y/n]: Y

Etapa 3/3: Configurações Específicas
  Domínio para Grafana: grafana.seudominio.com
  Domínio para MQTT: mqtt.seudominio.com
  (ou pressione Enter para pular e configurar depois)

  Limite de temperatura (°C): 30.0
  Intervalo de processamento (segundos): 10
```

✅ **O wizard criará:**

- Arquivo `.env` com credenciais seguras
- Estrutura de diretórios
- Configuração de permissões
- Arquivo de configuração `.setup_config`

### 4.3. Verificar Arquivo .env

```bash
# Ver credenciais geradas
cat .env

# Exemplo de saída:
# MQTT_USER=admin_a1b2c3d4
# MQTT_PASSWORD=xQ9k7...
# INFLUX_TOKEN=8s9k2...
# GRAFANA_PASSWORD=pL3m4...
```

🔒 **IMPORTANTE:** Anote essas credenciais em local seguro!

---

## 🚀 FASE 5: Deploy da Aplicação

### 5.1. Executar Deploy

```bash
# Executar script de deploy
bash scripts/deploy.sh
```

**O que acontece:**

1. ✅ Verifica Docker e Docker Compose
2. ✅ Valida arquivo .env
3. ✅ Para containers antigos (se existirem)
4. ✅ Gera certificados SSL autoassinados (temporários)
5. ✅ Configura Mosquitto para SSL
6. ✅ Ajusta permissões dos diretórios
7. ✅ Inicia containers em modo produção
8. ✅ Aguarda serviços ficarem prontos

### 5.2. Verificar Containers

```bash
# Ver status de todos os containers
docker compose ps

# Deve mostrar todos como "running" e "healthy"
```

✅ **Saída esperada:**

```
NAME              STATUS          PORTS
mov_mosquitto     Up (healthy)    0.0.0.0:8883->8883/tcp
mov_influxdb      Up (healthy)    -
mov_grafana       Up (healthy)    -
mov_telegraf      Up (healthy)    -
mov_analytics     Up (healthy)    -
mov_nginx         Up (healthy)    0.0.0.0:80->80/tcp, 0.0.0.0:443->443/tcp
```

### 5.3. Verificar Logs (se necessário)

```bash
# Modo recomendado: usar script logs.sh
./scripts/logs.sh              # Menu interativo
./scripts/logs.sh all          # Todos os serviços
./scripts/logs.sh grafana      # Serviço específico
./scripts/logs.sh mosquitto    # MQTT

# Ou usar docker compose diretamente:
docker compose logs -f         # Todos os serviços
docker compose logs -f grafana # Serviço específico

# Pressione CTRL+C para sair
```

---

## 🌐 FASE 6: Configurar DNS (se tiver domínio)

### 6.1. Configurar Registros DNS

No seu provedor de domínio (Registro.br, GoDaddy, Hostinger DNS, etc.):

**Tipo A - Apontar domínios para IP da VPS:**

```
Tipo: A
Nome: grafana
Valor: 203.45.67.89 (seu IP da VPS)
TTL: 3600

Tipo: A
Nome: mqtt
Valor: 203.45.67.89
TTL: 3600
```

### 6.2. Verificar Propagação DNS

```bash
# No seu computador (não na VPS)
nslookup grafana.seudominio.com

# Deve retornar o IP da sua VPS
```

⏱️ **Propagação DNS:** Pode levar 5 minutos a 48 horas (geralmente 15-30 min)

---

## 🔒 FASE 7: Configurar SSL/TLS (Let's Encrypt)

**Aguarde propagação DNS antes de continuar!**

### 7.1. Instalar Certificados SSL

```bash
# Executar script de SSL
bash scripts/setup_ssl.sh grafana.seudominio.com
```

**O que acontece:**

1. Instala Certbot
2. Valida DNS
3. Para Nginx temporariamente
4. Obtém certificado Let's Encrypt
5. **Atualiza automaticamente** nginx/conf.d/default.conf (descomenta HTTPS e substitui domínio)
6. Copia certificados para Mosquitto
7. Configura renovação automática
8. Reinicia serviços

✅ **Tudo é feito automaticamente!** O script já descomenta HTTPS e substitui o domínio.

### 7.2. Verificar Configuração Nginx

```bash
# Ver configuração atualizada
cat nginx/conf.d/default.conf | grep -A5 "listen 443"

# Deve mostrar o bloco HTTPS descomentado com seu domínio
```

### 7.3. Testar HTTPS

```bash
# Testar do servidor
curl -I https://grafana.seudominio.com

# Deve retornar: HTTP/2 200
```

🌐 **Acesse no navegador:** https://grafana.seudominio.com

---

## 📊 FASE 8: Configurar Grafana

### 8.1. Primeiro Acesso

1. Acesse: https://grafana.seudominio.com
2. Login:
   - **Usuário:** `admin`
   - **Senha:** (do arquivo `.env`, variável `GRAFANA_PASSWORD`)

3. Troque a senha (recomendado)

### 8.2. Adicionar Data Source (InfluxDB)

No Grafana:

1. Menu ☰ → **Connections** → **Data sources**
2. **Add data source** → **InfluxDB**
3. Configurar:

```
Query Language: Flux
URL: http://influxdb:8086
Organization: mov_org
Token: (copiar do .env, variável INFLUX_TOKEN)
```

4. **Save & Test** → Deve aparecer "Data source is working"

### 8.3. Importar Dashboard (opcional)

1. Menu ☰ → **Dashboards** → **Import**
2. Upload `.json` ou usar ID do Grafana.com
3. Exemplos úteis:
   - **11074** - MQTT Topics
   - **14251** - InfluxDB OSS Metrics
   - **928** - Telegraf System Dashboard

---

## 📡 FASE 9: Testar Conexão MQTT

### 9.1. Do Próprio Servidor (teste local)

```bash
# Instalar cliente MQTT
apt install -y mosquitto-clients

# Publicar mensagem de teste
mosquitto_pub -h localhost -p 1883 \
  -u "admin_xxxx" \
  -P "senha_do_env" \
  -t "test/topic" \
  -m "Hello MOV Platform"

# Assinar tópico em outro terminal
mosquitto_sub -h localhost -p 1883 \
  -u "admin_xxxx" \
  -P "senha_do_env" \
  -t "test/topic"
```

### 9.2. De Dispositivo Externo (IoT)

**Configuração Node-RED / ESP32 / Raspberry:**

```
Broker: mqtt.seudominio.com (ou IP da VPS)
Porta: 8883
TLS: Habilitado
Usuário: (do .env, MQTT_USER)
Senha: (do .env, MQTT_PASSWORD)
```

**Exemplo Python:**

```python
import paho.mqtt.client as mqtt

client = mqtt.Client()
client.username_pw_set("admin_xxxx", "senha_do_env")
client.tls_set()  # Habilita SSL
client.connect("mqtt.seudominio.com", 8883, 60)
client.publish("sensor/temperatura", "25.5")
```

---

## 🔄 FASE 10: Configurar Backup Automático

### 10.1. Backup Local (Diário)

Já está configurado automaticamente! Verifica com:

```bash
# Ver configuração do cron
crontab -l | grep backup

# Testar backup manual
bash scripts/backup.sh
```

**Localização dos backups:**

- `/opt/apps/MOV-Plataform/backups/`
- Rotação: 7 dias (backups mais antigos são deletados)

### 10.2. Backup Remoto (Recomendado)

```bash
# Executar configuração de backup remoto
bash scripts/setup_remote_backup.sh
```

**Responda as perguntas:**

```
Servidor remoto: backup.exemplo.com
Usuário SSH: backup_user
Porta SSH: 22
Diretório remoto: /backups/mov-platform
```

**Testa conexão:**

```bash
# Executar backup teste
/usr/local/bin/mov_remote_backup.sh
```

---

## ✅ FASE 11: Validação Final

### 11.1. Checklist de Validação

Execute cada comando e confirme funcionamento:

```bash
# 1. Todos os containers rodando
docker compose ps
# ✅ Todos devem estar "Up" e "healthy"

# 2. Firewall ativo
ufw status
# ✅ Portas 22, 80, 443, 8883 abertas

# 3. HTTPS funcionando
curl -I https://grafana.seudominio.com
# ✅ HTTP/2 200

# 4. Grafana acessível
# ✅ Abra no navegador e faça login

# 5. MQTT funcionando
mosquitto_sub -h localhost -p 1883 -u admin_xxxx -P senha -t test
# ✅ Conecta sem erros

# 6. Backup configurado
crontab -l
# ✅ Deve ter entrada para backup diário
```

### 11.2. Monitoramento

```bash
# Ver uso de recursos
htop

# Ver logs em tempo real
docker compose logs -f

# Ver status do sistema
systemctl status docker
```

---

## 🎯 Resumo de Acessos

### URLs de Acesso

| Serviço      | URL                                                        | Credenciais                       |
| ------------ | ---------------------------------------------------------- | --------------------------------- |
| **Grafana**  | https://grafana.seudominio.com                             | Usuário: `admin`<br>Senha: `.env` |
| **MQTT SSL** | mqtt.seudominio.com:8883                                   | Usuário: `.env`<br>Senha: `.env`  |
| **InfluxDB** | Via SSH tunnel<br>`ssh -L 8086:localhost:8086 root@VPS_IP` | Token: `.env`                     |

### SSH Tunnel para InfluxDB (acesso externo)

```bash
# Do seu computador
ssh -L 8086:localhost:8086 root@203.45.67.89

# Acesse http://localhost:8086 no navegador
```

---

## 🔧 Manutenção e Operação

### Comandos Úteis

```bash
# Ver logs (recomendado: usar script)
./scripts/logs.sh              # Menu interativo
./scripts/logs.sh [serviço]    # Serviço específico
./scripts/logs.sh all -n 100   # Últimas 100 linhas de todos

# Ver logs (alternativa: docker compose)
docker compose logs -f [serviço]

# Reiniciar serviço específico
docker compose restart [serviço]

# Parar tudo
docker compose down

# Iniciar tudo
docker compose -f docker-compose.yml -f docker-compose.prod.yml up -d

# Atualizar código
git pull origin main
bash scripts/update.sh

# Backup manual
bash scripts/backup.sh

# Ver uso de disco
df -h

# Limpar docker (cuidado!)
docker system prune -a
```

### Atualização da Plataforma

```bash
# 1. Fazer backup
bash scripts/backup.sh

# 2. Parar serviços
docker compose down

# 3. Atualizar código
git pull origin main

# 4. Reconstruir e iniciar
docker compose -f docker-compose.yml -f docker-compose.prod.yml up -d --build

# 5. Verificar
docker compose ps
```

---

## ⚠️ Troubleshooting

### Container não inicia

```bash
# Ver logs detalhados
docker compose logs [nome_container]

# Verificar permissões
ls -la mosquitto/ influxdb/ grafana/

# Recriar container
docker compose up -d --force-recreate [nome_container]
```

### Erro de permissão (Mosquitto/InfluxDB)

```bash
# Reajustar permissões
sudo chown -R 1883:1883 mosquitto/
sudo chown -R 1000:1000 influxdb/
sudo chown -R 472:472 grafana/

# Reiniciar
docker compose restart
```

### SSL não funciona

```bash
# Verificar certificados
ls -la /etc/letsencrypt/live/grafana.seudominio.com/

# Renovar certificado manualmente
certbot renew --force-renewal

# Verificar configuração Nginx
docker compose exec nginx nginx -t

# Reiniciar Nginx
docker compose restart nginx
```

### MQTT não conecta

```bash
# Verificar senha
cat .env | grep MQTT

# Testar localmente
mosquitto_sub -h localhost -p 1883 -u admin_xxxx -P senha -t test

# Ver logs Mosquitto
docker compose logs -f mosquitto

# Verificar certificados SSL
ls -la mosquitto/certs/
```

### Sem espaço em disco

```bash
# Ver uso
df -h

# Limpar logs antigos
docker compose logs --tail=100 > /dev/null

# Limpar imagens não usadas
docker image prune -a

# Limpar volumes órfãos (CUIDADO!)
docker volume prune
```

---

## 📞 Suporte e Recursos

### Documentação Adicional

- **Setup Wizard:** `scripts/SETUP-WIZARD-GUIDE.md`
- **Deploy Geral:** `instructions/DEPLOY.md`
- **Dev Workflow:** `instructions/DEV-WORKFLOW.md`
- **Atualizações:** `instructions/UPDATES.md`

### Links Úteis

- Docker: https://docs.docker.com/
- Grafana: https://grafana.com/docs/
- InfluxDB: https://docs.influxdata.com/
- Mosquitto: https://mosquitto.org/documentation/
- Let's Encrypt: https://letsencrypt.org/

---

## ✨ Parabéns!

Sua plataforma MOV está rodando em produção na Hostinger! 🎉

**Próximos passos recomendados:**

1. ✅ Configurar alertas no Grafana
2. ✅ Conectar dispositivos IoT
3. ✅ Criar dashboards personalizados
4. ✅ Configurar backup remoto
5. ✅ Documentar sua instalação específica

---

**Documento atualizado:** Fevereiro 2026  
**Versão MOV Platform:** v3.0
