# 🚀 MOV Platform - Guia COMPLETO de Deploy

**Nunca fez deploy? Sem problemas!** Este guia é passo a passo, sem pular nada.

---

## 📍 FASE 1: Desenvolvimento (no seu PC)

### Como testar localmente:

```bash
# Na pasta do projeto
docker compose up -d
```

**Acesso local:**

- Grafana: http://localhost:3000
- InfluxDB: http://localhost:8086
- MQTT: localhost:1883

**Tudo aberto, fácil de testar!** ✅

---

## 📍 FASE 2: Preparar Deploy na VPS

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
- Salva tudo no arquivo `.env`
- Configura permissões corretas
- Você NÃO precisa criar senhas manualmente

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

**Você NÃO precisa descomentar nada manualmente!** O script faz isso.

Agora acesse:

```
https://grafana.seusite.com.br
```

Deve aparecer o **cadeado verde 🔒** no navegador!

---

## ✅ PRONTO! Deploy Completo!

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

## 📋 Resumo: É só seguir os passos?

**SIM! Literalmente isso:**

```bash
# 1. Na VPS
git clone seu-repo
cd MOV-Plataform

# 2. Gerar senhas
bash scripts/generate_credentials.sh > .env

# 3. Deploy
bash scripts/deploy.sh

# 4. Firewall
sudo bash scripts/setup_firewall.sh

# 5. SSL (opcional)
sudo bash scripts/setup_ssl.sh seu-dominio.com
```

### ✅ **As credenciais do .env vão AUTOMATICAMENTE para:**

- ✅ Mosquitto (MQTT)
- ✅ InfluxDB
- ✅ Grafana
- ✅ Telegraf

### ❌ **Você NÃO precisa:**

- ❌ Editar arquivos de configuração manualmente
- ❌ Criar senhas você mesmo
- ❌ Configurar cada serviço individualmente
- ❌ Abrir/fechar portas manualmente
- ❌ Descomentar código no Nginx

**Tudo é AUTOMÁTICO!** 🎉

---

## 📚 APÊNDICE A: Instalar Docker na VPS

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

## 📚 APÊNDICE B: Diferenças Dev vs Prod

| Aspecto       | Desenvolvimento (PC) | Produção (VPS)              |
| ------------- | -------------------- | --------------------------- |
| **Comando**   | `docker compose up`  | `bash scripts/deploy.sh`    |
| **Grafana**   | `localhost:3000`     | `https://dominio` via Nginx |
| **InfluxDB**  | `localhost:8086`     | Fechado (SSH tunnel)        |
| **MQTT**      | `1883` sem SSL       | `8883` com SSL              |
| **Segurança** | Tudo aberto          | Firewall + SSL              |

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
