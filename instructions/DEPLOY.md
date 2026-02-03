# 🚀 MOV Platform - Guia Completo de Deploy em Produção

**Primeira vez fazendo deploy?** Este guia explica tudo passo a passo, sem pular nada.

---

## 📋 Visão Geral

### O Que Este Guia Cobre

✅ Deploy completo em servidor VPS (Ubuntu/Debian)  
✅ Configuração de segurança (firewall, SSL/TLS)  
✅ Backup automatizado local e remoto  
✅ Separação desenvolvimento vs produção  
✅ Troubleshooting e validação

### Tempo Estimado

- **Setup inicial:** 20-30 minutos
- **Com SSL e backup:** 40-60 minutos

### Pré-requisitos

- VPS com Ubuntu 20.04+ ou Debian (mínimo 2GB RAM)
- Domínio apontando para VPS (opcional, para SSL)
- Docker instalado na VPS (ver Apêndice A)
- Conhecimento básico de SSH

---

## 📍 FASE 1: Teste Local (Desenvolvimento)

**Antes de fazer deploy em produção, teste localmente no seu PC:**

### Desenvolvimento Local

```bash
# 1. Clonar projeto
git clone <seu-repositorio>
cd MOV-Plataform

# 2. Gerar credenciais
bash scripts/setup.sh

# 3. Iniciar serviços
docker compose up -d

# 4. Verificar status
docker compose ps
```

### Acessos Locais

| Serviço      | URL                   | Credenciais |
| ------------ | --------------------- | ----------- |
| **Grafana**  | http://localhost:3000 | Ver `.env`  |
| **InfluxDB** | http://localhost:8086 | Ver `.env`  |
| **MQTT**     | localhost:1883        | Ver `.env`  |

💡 **Dica:** No desenvolvimento, todas as portas ficam abertas para facilitar testes.

---

## 📍 FASE 2: Preparar Ambiente de Produção

### O que você precisa TER antes:

#### ✅ 1. Uma VPS (servidor na nuvem)

Exemplos: DigitalOcean, AWS, Azure, Contabo, etc.

- Sistema: Ubuntu 20.04+ ou Debian
- RAM: Mínimo 2GB
- Acesso SSH (usuário e senha ou chave SSH)

#### ✅ 2. Um domínio (opcional mas recomendado)

Exemplo: `seusite.com.br`

- Compre em: Registro.br, GoDaddy, Namecheap, etc.
- Configure DNS apontando para o IP da VPS:
  ```
  Tipo A: grafana.seusite.com.br → 203.45.67.89 (IP da sua VPS)
  ```

#### ✅ 3. Docker instalado na VPS

Veja "Apêndice A" no final deste arquivo.

---

## 📍 FASE 3: Deploy PASSO A PASSO

### **PASSO 1: Conectar na VPS**

No seu computador:

```bash
ssh usuario@203.45.67.89
# Troque pelo seu usuário e IP da VPS
```

Agora você está DENTRO da VPS! 🖥️

---

### **PASSO 2: Clonar o repositório**

Na VPS, rode:

```bash
# Clone seu projeto
git clone https://github.com/seuusuario/MOV-Plataform.git

# Entre na pasta
cd MOV-Plataform

# Verifique se os arquivos estão lá
ls -la
```

Você deve ver: `docker-compose.yml`, `scripts/`, `nginx/`, etc.

**Importante:** Verifique se todos os scripts têm permissão de execução:

```bash
chmod +x scripts/*.sh
chmod +x mosquitto/docker-entrypoint.sh
```

---

### **PASSO 3: Executar setup automático**

Na VPS:

```bash
chmod +x scripts/setup.sh
./scripts/setup.sh
```

**O que isso faz:**

- Cria estrutura de diretórios necessária
- Gera senhas aleatórias e fortes automaticamente
- **Gera senhas de criptografia para backups** (automático)
- Salva tudo no arquivo `.env`
- Configura permissões corretas
- Você NÃO precisa criar senhas manualmente

**O arquivo .env contém:**

- Senhas MQTT, InfluxDB, Grafana
- Tokens de autenticação
- **Senhas de criptografia de backup** (geradas automaticamente)

**Alternativa (manual):**

```bash
# Se preferir gerar apenas as credenciais
bash scripts/generate_credentials.sh > .env

# E criar diretórios manualmente
mkdir -p mosquitto/{config,data,log} influxdb/config backups
```

**Veja as senhas geradas:**

```bash
cat .env
```

Vai aparecer algo assim:

```
MQTT_USER=admin_a1b2c3
MQTT_PASSWORD=xYz123AbC456...
INFLUX_USER=admin_influx
INFLUX_PASSWORD=aBc789XyZ...
```

**💡 IMPORTANTE:** Guarde essas senhas! Você vai precisar delas depois.

---

### **PASSO 4: Rodar o deploy**

Na VPS:

```bash
bash scripts/deploy.sh
```

**O que esse script FAZ automaticamente:**

1. ✅ Verifica se Docker está instalado
2. ✅ Para containers antigos (se existirem)
3. ✅ Gera certificados SSL para MQTT
4. ✅ Configura Mosquitto para usar SSL
5. ✅ Inicia TODOS os containers (InfluxDB, Grafana, MQTT, Telegraf, etc)
6. ✅ Usa configuração SEGURA (portas fechadas)

**Aguarde uns 30 segundos.** Você verá mensagens verdes ✅ de sucesso.

---

### **PASSO 5: Configurar Firewall**

Na VPS:

```bash
sudo bash scripts/setup_firewall.sh
```

**O que isso faz:**

- Bloqueia TODAS as portas (segurança máxima)
- Abre APENAS:
  - Porta 22 (SSH - para você acessar)
  - Porta 80 (HTTP)
  - Porta 443 (HTTPS)
  - Porta 8883 (MQTT SSL - para dispositivos IoT)

**Pronto!** Seu servidor está protegido 🔒

---

### **PASSO 6: Testar acesso (SEM SSL ainda)**

No navegador do seu PC, acesse:

```
http://203.45.67.89
# Troque pelo IP da sua VPS
```

Você deve ver o **Grafana** aparecer! 🎉

**Login padrão:**

- Usuário: `admin`
- Senha: (veja no arquivo `.env` na VPS o valor de `GRAFANA_PASSWORD`)

**⚠️ ATENÇÃO:** Ainda está em HTTP (sem cadeado). Vamos adicionar HTTPS agora!

---

### **PASSO 7: Configurar HTTPS (SSL) - OPCIONAL mas RECOMENDADO**

**Pré-requisito:** Ter um domínio configurado (ex: `grafana.seusite.com.br`)

Na VPS:

```bash
sudo bash scripts/setup_ssl.sh grafana.seusite.com.br
# Troque pelo seu domínio real
```

**O que isso faz AUTOMATICAMENTE:**

1. ✅ Instala o Certbot (ferramenta de certificados)
2. ✅ Gera certificado SSL/TLS **GRÁTIS** do Let's Encrypt
3. ✅ Atualiza configuração do Nginx para usar HTTPS
4. ✅ Configura renovação automática (certificados expiram a cada 90 dias)
5. ✅ Configura renovação automática de certificados MQTT

**Você NÃO precisa descomentar nada manualmente!** O script faz isso.

Agora acesse:

```
https://grafana.seusite.com.br
```

Deve aparecer o **cadeado verde 🔒** no navegador!

---

### **PASSO 8: Configurar Backup Remoto (Google Drive/OneDrive) - RECOMENDADO**

**Por que fazer isso?** Se o servidor pegar fogo ou for hackeado, seus backups estarão seguros na nuvem! 🌐

Na VPS:

```bash
bash scripts/setup_remote_backup.sh
```

**O que isso faz:**

1. ✅ Instala Rclone (ferramenta de sincronização)
2. ✅ Você escolhe: Google Drive (15 GB grátis), MEGA (20 GB), OneDrive ou Dropbox
3. ✅ Faz login na sua conta (abre o navegador automaticamente)
4. ✅ Pergunta se quer criptografar (RECOMENDADO para dados sensíveis)
5. ✅ **Usa senhas do .env automaticamente** (geradas no PASSO 3)
6. ✅ Configura envio automático TODO DIA às 2h da manhã
7. ✅ Mantém 30 dias de backups na nuvem

**Você faz UMA VEZ e depois esquece!** Funciona sozinho para sempre.

**Exemplo de escolha:**

- Opção 1 (Google Drive) ⭐ RECOMENDADO
- Criptografar? **S** (usa senhas do .env automaticamente)
- Login no Google (abre navegador)
- Pronto! Backups diários automáticos

**🔐 Segurança:**

- Senhas de criptografia geradas automaticamente (256 bits)
- Armazenadas no .env (seguro, não vai para GitHub)
- Google Drive **não consegue** ler seus backups criptografados
- Em caso de perda: restaure o .env junto com os backups

**Ver seus backups:**

- Acesse https://drive.google.com
- Pasta: "MOV-Platform-Backups"
- Arquivos: grafana_20260203.tar.gz, influxdb_20260203.tar.gz

---

## ✅ PRONTO! Deploy Completo!

### ⏰ Automação Configurada (funciona sozinho):

**Você configurou uma vez, agora tudo roda automaticamente:**

- 🔄 **1h da manhã:** Backup local (Grafana + InfluxDB) → pasta `./backups`
- 🌐 **2h da manhã:** Backup enviado para Google Drive/MEGA (se configurou)
- 🔐 **3h da manhã:** Renovação de certificados HTTPS (Let's Encrypt)
- 🔒 **4h da manhã:** Renovação de certificados MQTT (autoassinados)

**Você não precisa fazer NADA! Sistema se mantém sozinho.** 🎉

### Seus acessos em PRODUÇÃO:

#### 📊 **Grafana (Cliente/Você/Dashboards)**

```
https://grafana.seudominio.com  (se configurou SSL)
ou
http://ip-da-vps  (sem SSL)
```

#### 🔌 **MQTT (Dispositivos IoT e Node-RED)**

**No Node-RED, configure o bloco MQTT:**

```
Server: ip-da-vps (ou dominio)
Port: 8883
Protocol: MQTTS (SSL/TLS)
Username: (veja MQTT_USER no .env)
Password: (veja MQTT_PASSWORD no .env)
```

**⚠️ IMPORTANTE:** Porta 1883 (sem SSL) está FECHADA por segurança!

#### 📈 **InfluxDB (Administração - quando você precisar)**

InfluxDB está FECHADO (seguro). Para acessar:

No **seu computador local**, rode:

```bash
ssh -L 8086:localhost:8086 usuario@ip-da-vps
```

Deixe esse terminal aberto e acesse no navegador:

```
http://localhost:8086
```

Você está acessando o InfluxDB da VPS de forma SEGURA via túnel SSH! 🔐

---

## 🔄 Atualizar Deploy (depois de mudanças no código)

Na VPS:

```bash
# Puxar atualizações do Git
git pull

# Reiniciar containers
docker compose -f docker-compose.yml -f docker-compose.prod.yml up -d --build
```

---

## 🆘 Problemas Comuns

### "Não consigo acessar o Grafana"

**Verificar se está rodando:**

```bash
docker compose ps
```

Todos devem estar "Up". Se algum estiver "Exit", veja os logs:

```bash
docker compose logs grafana
docker compose logs nginx
```

**Verificar firewall:**

```bash
sudo ufw status
```

Porta 80 e 443 devem estar "ALLOW".

---

### "Node-RED não conecta no MQTT"

**Certifique-se:**

1. Porta: `8883` (não 1883)
2. Protocolo: `MQTTS` ou `SSL/TLS`
3. Usuário e senha: veja no `.env` da VPS

**Ver logs do Mosquitto:**

```bash
docker compose logs mosquitto
```

---

### "Esqueci as senhas!"

Na VPS:

```bash
cat .env
```

Todas as senhas estão lá!

---

---

## 📋 Resumo Executivo

### Deploy Completo em 5 Comandos

```bash
# 1. Clonar projeto na VPS
git clone https://github.com/usuario/MOV-Plataform.git
cd MOV-Plataform

# 2. Gerar credenciais automaticamente
bash scripts/generate_credentials.sh > .env

# 3. Deploy com SSL/TLS automático
bash scripts/deploy.sh

# 4. Configurar firewall (UFW)
sudo bash scripts/setup_firewall.sh

# 5. SSL Let's Encrypt (se tiver domínio)
sudo bash scripts/setup_ssl.sh seu-dominio.com
```

### ✅ O Que os Scripts Fazem Automaticamente

| Script                    | Ação                                                |
| ------------------------- | --------------------------------------------------- |
| `generate_credentials.sh` | Gera senhas criptográficas (256-512 bits)           |
| `deploy.sh`               | Inicia containers em modo produção com SSL/TLS MQTT |
| `setup_firewall.sh`       | Configura UFW (permite apenas 22, 80, 443, 8883)    |
| `setup_ssl.sh`            | Let's Encrypt HTTPS + renovação automática          |

### ✅ Credenciais do .env Aplicadas Automaticamente Em

- ✅ Mosquitto (broker MQTT)
- ✅ InfluxDB (banco de dados)
- ✅ Grafana (dashboards)
- ✅ Telegraf (coletor)
- ✅ Analytics (processamento Python)

### ❌ Você NÃO Precisa

- ❌ Editar arquivos `.conf` manualmente
- ❌ Criar senhas fracas você mesmo
- ❌ Configurar serviços um por um
- ❌ Abrir/fechar portas manualmente
- ❌ Lembrar de renovar certificados

**🎯 Resultado:** Plataforma segura rodando em produção com backup automático e renovação de certificados.

---

## 🎯 Checklist de Validação Pós-Deploy

### 1. Verificar Status dos Containers

```bash
# Ver status de todos os serviços
docker compose ps

# Resultado esperado: todos "Up" ou "Up (healthy)"
```

### 2. Verificar Logs

```bash
# Ver últimas 50 linhas de todos os serviços
docker compose logs --tail=50

# Ver logs em tempo real de um serviço
docker compose logs -f grafana
docker compose logs -f mosquitto
docker compose logs -f influxdb
```

### 3. Testar Acessos

#### Com Domínio Configurado

- **Grafana:** https://seu-dominio.com
  - Deve redirecionar HTTP → HTTPS automaticamente
  - Certificado SSL válido (Let's Encrypt)
  - Login com credenciais do `.env`

- **MQTT:** `seu-dominio.com:8883`
  - Conexão SSL/TLS obrigatória
  - Autenticação com credenciais do `.env`

#### Sem Domínio (Apenas IP)

```bash
# SSH tunnel para Grafana
ssh -L 3000:localhost:3000 usuario@ip-vps
# Acesse: http://localhost:3000

# SSH tunnel para InfluxDB
ssh -L 8086:localhost:8086 usuario@ip-vps
# Acesse: http://localhost:8086
```

### 4. Testar Publicação MQTT

```bash
# Publicar mensagem de teste (sem SSL - apenas desenvolvimento)
mosquitto_pub -h seu-dominio.com -p 1883 \
  -u "$MQTT_USER" -P "$MQTT_PASSWORD" \
  -t "mov/dados/teste" \
  -m '{"timestamp":"2026-02-03T10:00:00Z","tags":{"dispositivo":"teste","tipo":"temperatura"},"fields":{"temperatura_c":25.5}}'

# Publicar com SSL/TLS (produção)
mosquitto_pub -h seu-dominio.com -p 8883 \
  --cafile /etc/ssl/certs/ca-certificates.crt \
  -u "$MQTT_USER" -P "$MQTT_PASSWORD" \
  -t "mov/dados/teste" \
  -m '{"temperatura_c":25.5}'
```

### 5. Verificar Firewall

```bash
# Ver status do UFW
sudo ufw status verbose

# Resultado esperado:
# Status: active
# 22/tcp     ALLOW IN    SSH
# 80/tcp     ALLOW IN    HTTP
# 443/tcp    ALLOW IN    HTTPS
# 8883/tcp   ALLOW IN    MQTT SSL
```

### 6. Verificar Certificados SSL

```bash
# Verificar certificado HTTPS (Let's Encrypt)
sudo certbot certificates

# Verificar certificado MQTT
openssl x509 -in mosquitto/certs/server.crt -noout -dates

# Ver dias restantes
openssl x509 -in mosquitto/certs/server.crt -noout -enddate
```

### 7. Testar Backup Automático

```bash
# Ver logs do container de backup
docker compose logs backup_job

# Verificar se backups estão sendo criados
ls -lh backups/

# Executar backup remoto manualmente (se configurado)
sudo /usr/local/bin/mov_remote_backup.sh

# Ver logs do backup remoto
tail -50 /var/log/mov_remote_backup.log
```

### 8. Verificar Cron Jobs

```bash
# Listar cron jobs do root
sudo crontab -l

# Resultado esperado:
# 0 3 * * * certbot renew --quiet --deploy-hook 'docker compose restart nginx'
# 0 4 * * * /usr/local/bin/renew_mqtt_certs.sh
# 0 2 * * * /usr/local/bin/mov_remote_backup.sh >> /var/log/mov_remote_backup.log 2>&1
```

### ✅ Checklist Final

| Item                 | Comando de Verificação      | Status Esperado             |
| -------------------- | --------------------------- | --------------------------- |
| Containers rodando   | `docker compose ps`         | Todos "Up"                  |
| Grafana acessível    | Abrir https://dominio       | Login aparece               |
| MQTT conecta         | `mosquitto_pub` com SSL     | Sem erros                   |
| Firewall ativo       | `sudo ufw status`           | Active                      |
| Certificados válidos | `sudo certbot certificates` | Valid, >30 dias             |
| Backup funciona      | `ls backups/`               | Arquivos `.tar.gz` recentes |
| Cron configurado     | `sudo crontab -l`           | 3 jobs listados             |

---

## � Backup e Recuperação

### Backup Local (automático)

**Container `backup_job` roda TODO DIA às 1h da manhã:**

```bash
# Ver backups locais
ls -lh backups/

# Saída:
# grafana_20260203_010000.tar.gz  (dashboards, configurações)
# influxdb_20260203_010000.tar.gz (todos os dados de sensores)
```

**Retenção:** 7 dias locais (limpa automaticamente)

---

### Backup Remoto (Google Drive/MEGA)

**Se você configurou o `setup_remote_backup.sh`, TODO DIA às 2h da manhã os backups vão para a nuvem.**

**Comandos úteis:**

```bash
# Ver backups na nuvem
rclone ls mov-backup:

# Executar backup manual agora
sudo /usr/local/bin/mov_remote_backup.sh

# Ver logs do último backup
tail -50 /var/log/mov_remote_backup.log

# Ver espaço usado no Google Drive
rclone about mov-drive:
```

**Acesso via navegador:**

- Google Drive: https://drive.google.com
- Pasta: "MOV-Platform-Backups"

---

### Restaurar de um Backup

**Cenário: Servidor pegou fogo 🔥 ou dados corrompidos**

#### 1. Baixar backup da nuvem:

```bash
# Listar backups disponíveis
rclone ls mov-backup:

# Baixar o mais recente
rclone copy mov-backup:grafana_20260203_010000.tar.gz ./
rclone copy mov-backup:influxdb_20260203_010000.tar.gz ./
```

#### 2. Parar containers:

```bash
docker compose down
```

#### 3. Extrair backups:

```bash
# Restaurar Grafana
tar -xzf grafana_20260203_010000.tar.gz -C /var/lib/docker/volumes/grafana_data/_data/

# Restaurar InfluxDB
tar -xzf influxdb_20260203_010000.tar.gz -C /var/lib/docker/volumes/influxdb_data/_data/
```

#### 4. Reiniciar:

```bash
docker compose -f docker-compose.yml -f docker-compose.prod.yml up -d
```

**✅ Tudo restaurado!** Dashboards, dados, configurações voltam ao normal.

---

## 🔧 Comandos de Manutenção

### Ver status dos serviços:

```bash
docker compose ps
docker compose logs -f        # Ver logs em tempo real
docker compose logs grafana   # Logs de um serviço específico
```

### Ver agendamentos automáticos:

```bash
# Ver tarefas cron configuradas
crontab -l

# Saída esperada:
# 0 3 * * * certbot renew --quiet --deploy-hook 'docker compose restart nginx'
# 0 4 * * * /usr/local/bin/renew_mqtt_certs.sh
# 0 2 * * * /usr/local/bin/mov_remote_backup.sh
```

### Espaço em disco:

```bash
# Ver espaço usado pelos containers
docker system df

# Limpar containers/imagens antigas
docker system prune -a
```

### Certificados MQTT:

```bash
# Ver validade do certificado
openssl x509 -enddate -noout -in mosquitto/certs/server.crt

# Ver log de renovação
sudo tail -f /var/log/mqtt_cert_renewal.log

# Forçar renovação agora
sudo /usr/local/bin/renew_mqtt_certs.sh
```

---

## 🔐 Segurança do Backup e Credenciais

### Arquivo .env - O que tem dentro:

```bash
# Ver conteúdo (na VPS)
cat .env

# Exemplo:
MQTT_PASSWORD=xYz123...
GRAFANA_PASSWORD=aBc456...
BACKUP_CRYPT_PASSWORD=pQr789...  ← Senha de criptografia dos backups
BACKUP_CRYPT_SALT=lMn012...      ← Salt da criptografia
```

### Como funciona a segurança:

```
┌─────────────────────────────────────┐
│  Arquivo .env (no servidor)         │
│  ✅ NÃO vai para GitHub (.gitignore)│
│  ✅ Senhas fortes (256 bits)        │
│  ✅ Geradas automaticamente          │
└──────────────┬──────────────────────┘
               │
               ▼
┌─────────────────────────────────────┐
│  Backup Local (.tar.gz)             │
│  ✅ Dados do Grafana + InfluxDB     │
└──────────────┬──────────────────────┘
               │
               ▼ (se escolheu criptografar)
┌─────────────────────────────────────┐
│  Rclone Crypt (AES-256)             │
│  ✅ Usa senhas do .env              │
│  ✅ Criptografa antes de enviar     │
└──────────────┬──────────────────────┘
               │
               ▼
┌─────────────────────────────────────┐
│  Google Drive (nuvem)               │
│  ✅ Arquivos criptografados         │
│  ❌ Google NÃO consegue ler         │
│  ❌ Hacker NÃO consegue descriptografar│
└─────────────────────────────────────┘
```

### Se alguém invadir seu Google Drive:

**SEM criptografia:**

```
❌ Pessoa baixa: grafana_20260203.tar.gz
❌ Extrai e vê tudo: senhas, dados, tokens
```

**COM criptografia (usando .env):**

```
✅ Pessoa baixa: arquivo criptografado (lixo binário)
❌ Tenta extrair: IMPOSSÍVEL sem a senha do .env
✅ Seus dados estão seguros!
```

### Proteger o arquivo .env:

```bash
# Permissões corretas (apenas você lê)
chmod 600 .env
ls -la .env
# Saída: -rw------- 1 usuario usuario .env

# Fazer backup do .env (IMPORTANTE!)
cp .env .env.backup
scp .env seu-computador-local:~/backups/mov-platform-env-$(date +%Y%m%d)

# Guardar em gerenciador de senhas
# 1Password, Bitwarden, KeePass, etc.
```

### Clonar em outra máquina:

```bash
# Máquina nova (desenvolvimento, outra VPS, etc)
git clone https://github.com/seu-usuario/MOV-Plataform.git
cd MOV-Plataform

# Opção 1: Gerar novas credenciais (recomendado para dev)
bash scripts/generate_credentials.sh > .env

# Opção 2: Copiar .env da produção (para recuperação)
scp vps-producao:~/MOV-Plataform/.env .

# Configurar backup (usa senhas do .env automaticamente)
bash scripts/setup_remote_backup.sh
```

### Níveis de segurança:

| Componente                       | Proteção                 | Onde Está       |
| -------------------------------- | ------------------------ | --------------- |
| **Senhas MQTT/Grafana/InfluxDB** | 🔒 Arquivo .env (local)  | Servidor apenas |
| **Token Google Drive**           | 🔒 /root/.config/rclone/ | Servidor apenas |
| **Senhas de criptografia**       | 🔒 Arquivo .env (local)  | Servidor apenas |
| **Backups locais**               | ⚠️ Não criptografados    | ./backups/      |
| **Backups remotos**              | 🔐 AES-256 (se escolheu) | Google Drive    |

### ⚠️ NUNCA faça:

```bash
# ❌ ERRADO - Commitar .env no Git
git add .env
git commit -m "add env"  # ← Suas senhas vão para o GitHub!

# ✅ CORRETO - .env já está no .gitignore
git status
# .env não aparece (está ignorado)
```

---

## �📚 APÊNDICE A: Instalar Docker na VPS

Se a VPS não tem Docker ainda:

```bash
# Atualizar sistema
sudo apt update && sudo apt upgrade -y

# Instalar Docker
curl -fsSL https://get.docker.com | sh

# Adicionar seu usuário ao grupo docker
sudo usermod -aG docker $USER

# IMPORTANTE: Sair e entrar novamente no SSH
exit
# Conecte novamente
ssh usuario@ip-vps

# Testar
docker --version
docker compose version
```

---

## 📚 APÊNDICE B: Diferenças Desenvolvimento vs Produção

### Tabela Comparativa

| Aspecto                 | Desenvolvimento (PC)          | Produção (VPS)                                             |
| ----------------------- | ----------------------------- | ---------------------------------------------------------- |
| **Arquivo Compose**     | `docker-compose.yml`          | `docker-compose.yml` + `docker-compose.prod.yml` (overlay) |
| **Comando Iniciar**     | `docker compose up -d`        | `bash scripts/deploy.sh`                                   |
| **Grafana**             | `localhost:3000` direto       | `https://dominio` via Nginx com SSL                        |
| **InfluxDB**            | `localhost:8086` exposto      | `127.0.0.1:8086` (SSH tunnel apenas)                       |
| **MQTT**                | Porta `1883` sem criptografia | Porta `8883` com SSL/TLS                                   |
| **Mosquitto WebSocket** | Porta `9001` exposta          | Removida (não exposta)                                     |
| **Firewall**            | Desabilitado                  | UFW ativo (22, 80, 443, 8883)                              |
| **SSL/TLS**             | Opcional                      | Obrigatório (Let's Encrypt)                                |
| **Backup**              | Manual                        | Automático (1h AM local, 2h AM remoto)                     |
| **Logs**                | `docker compose logs`         | Logs persistidos + `/var/log/`                             |
| **Credenciais**         | `.env` local gerado           | `.env` gerado na VPS (único por servidor)                  |
| **Health Checks**       | Ativos                        | Ativos                                                     |
| **Restart Policy**      | `unless-stopped`              | `unless-stopped`                                           |

### Porque Essa Separação?

**Desenvolvimento (Local):**

- 🎯 **Objetivo:** Facilitar testes e debug
- ✅ Portas abertas para acesso direto
- ✅ Sem criptografia (mais rápido)
- ✅ Logs visíveis no terminal

**Produção (VPS):**

- 🎯 **Objetivo:** Segurança e confiabilidade
- ✅ Apenas portas essenciais expostas
- ✅ Criptografia obrigatória (TLS/SSL)
- ✅ Firewall bloqueando tudo exceto necessário
- ✅ Backup automático para recuperação

---

## 📚 APÊNDICE C: Arquitetura de Segurança

```
                    INTERNET
                       ↓
        ┌──────────────────────────┐
        │  Firewall UFW (VPS)      │
        │  Permite: 22,80,443,8883 │
        └──────────────────────────┘
                       ↓
        ┌──────────────────────────┐
        │  Nginx (porta 80/443)    │
        │  Proxy + SSL             │
        └──────────────────────────┘
                       ↓
        ┌──────────────────────────────────┐
        │  Rede Interna Docker             │
        │                                  │
        │  ┌─────────┐   ┌─────────┐     │
        │  │Grafana  │←→ │InfluxDB │     │
        │  │:3000    │   │:8086    │     │
        │  └─────────┘   └─────────┘     │
        │                                  │
        │  ┌──────────┐  ┌──────────┐    │
        │  │Mosquitto │←→│Telegraf  │    │
        │  │:8883     │  │          │    │
        │  └──────────┘  └──────────┘    │
        └──────────────────────────────────┘
```

**Serviços VISÍVEIS na internet:**

- ✅ Nginx (80/443) → Grafana
- ✅ Mosquitto (8883) → IoT

**Serviços INVISÍVEIS (rede interna):**

- 🔒 Grafana porta 3000 (só via Nginx)
- 🔒 InfluxDB porta 8086 (só via SSH ou rede Docker)
- 🔒 Telegraf (sem porta externa)

---

## 📚 APÊNDICE D: Como funciona o .env

Quando você roda:

```bash
bash scripts/generate_credentials.sh > .env
```

Um arquivo `.env` é criado com:

```bash
MQTT_USER=admin_abc123
MQTT_PASSWORD=yzk98HFds...
INFLUX_USER=admin_influx
INFLUX_PASSWORD=AbX21mnQ...
GRAFANA_PASSWORD=LoP45kJm...
```

No `docker-compose.yml`, cada serviço tem:

```yaml
environment:
  - INFLUX_USER=${INFLUX_USER} # ← Docker SUBSTITUI pelo valor do .env
  - INFLUX_PASSWORD=${INFLUX_PASSWORD}
```

**Docker lê o .env automaticamente!** Não precisa fazer nada.

---

**🎉 Agora você está pronto para fazer deploy!**

**Dúvidas?** Cada script tem comentários explicando o que faz linha por linha.
