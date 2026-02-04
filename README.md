# 🏭 MOV Platform - Monitoramento Industrial IoT

**Plataforma profissional de coleta, processamento e visualização de dados IoT em tempo real.**

Arquitetura moderna baseada em containers Docker, com MQTT seguro, InfluxDB, Grafana e processamento analítico automatizado.

---

## 🎯 O Que é a MOV Platform?

Uma **solução self-hosted completa** para monitoramento industrial e IoT, projetada para empresas que precisam de **controle total sobre seus dados** sem custos recorrentes de SaaS.

### 💡 Por Que Escolher a MOV Platform?

#### 💰 **Economia Real**

- **SaaS Tradicional:** $50-200/mês por plataforma IoT
- **MOV Platform:** $5-20/mês (apenas VPS) → **Economia de $420-2.160/ano**

#### 🔒 **Segurança e Privacidade**

- Dados ficam no **SEU servidor** - sem enviar para terceiros
- Criptografia TLS/SSL em todas as comunicações (MQTT 8883, HTTPS 443)
- Backup criptografado AES-256 em nuvem gratuita (Google Drive/MEGA)
- **Facilita LGPD/GDPR:** Você controla onde os dados são armazenados

#### ⚡ **Facilidade Profissional**

- **Deploy completo em 10 minutos:** `bash scripts/deploy.sh`
- Renovação automática de certificados (HTTPS e MQTT)
- Backup diário automático (local 1h AM, remoto 2h AM)
- Scripts eliminam erro humano - configuração sempre consistente

#### 🏗️ **Qualidade de Código Comercial**

- **Documentação completa:** 5 guias cobrindo dev, deploy, operação e segurança
- Separação dev/prod com arquivos Docker Compose específicos
- Todos os containers com usuários não-root (princípio do menor privilégio)
- Health checks automáticos e restart policies inteligentes
- Credenciais geradas com OpenSSL (256-512 bits de entropia)

### 🎯 Ideal Para

| Setor                    | Casos de Uso                                                          |
| ------------------------ | --------------------------------------------------------------------- |
| 🏭 **Indústria 4.0**     | Sensores de temperatura, pressão, vibração; OEE; manutenção preditiva |
| 🌱 **Agronegócio**       | Monitoramento de estufas, irrigação inteligente, controle climático   |
| 🏢 **Automação Predial** | Consumo de energia, climatização, segurança patrimonial               |
| 🚚 **Logística**         | Rastreamento de frotas, telemetria de veículos, cold chain            |
| 🏥 **Saúde**             | Monitoramento de equipamentos hospitalares, freezers de vacinas       |
| ⚡ **Energia**           | Smart grids, usinas solares, monitoramento de geradores               |

---

## ⚡ Início Rápido

### Setup Interativo (Recomendado! 🌟)

```bash
# 1. Clonar e entrar no projeto
git clone <seu-repositorio> && cd MOV-Plataform

# 2. Executar o wizard de configuração
bash scripts/setup_wizard.sh

# 3. Seguir as instruções na tela
# O wizard configura tudo automaticamente: ambiente, componentes e credenciais!

# 4. Iniciar a plataforma
docker compose up -d
```

**Pronto!** Acesse:

- 📊 **Grafana:** http://localhost:3000 (Dashboards)
- 📈 **InfluxDB:** http://localhost:8086 (Banco de dados)
- 🔌 **MQTT:** localhost:1883 (Broker)

_Credenciais geradas automaticamente estão no arquivo `.env`_

### Deploy em Produção (VPS)

```bash
# Na VPS, executar:
chmod +x scripts/deploy.sh && bash scripts/deploy.sh
```

**Resultado:** Plataforma rodando com SSL/TLS, firewall configurado e backup automático.

**Para configuração completa de produção**, consulte [instructions/DEPLOY.md](instructions/DEPLOY.md)

---

## 📋 Índice

- [O Que é a MOV Platform?](#-o-que-é-a-mov-platform)
- [Início Rápido](#-início-rápido)
- [Arquitetura](#-arquitetura)
- [Stack Tecnológica](#-stack-tecnológica)
- [Pré-requisitos](#-pré-requisitos)
- [Instalação](#-instalação)
- [Configuração](#%EF%B8%8F-configuração)
- [Serviços](#-serviços)
- [Backup e Segurança](#-backup-e-segurança)
- [Desenvolvimento](#%EF%B8%8F-desenvolvimento)
- [Documentação Completa](#-documentação-completa)
- [Segurança](#-segurança)
- [Contribuindo](#-contribuindo)
- [Licença](#-licença)

---

## �️ Arquitetura

```
┌───────────────────────────────────────────────────────────┐
│                    CAMADA DE SENSORES                     │
│  ESP32, Raspberry Pi, Arduino, Node-RED, Sensores IoT     │
└─────────────────────┬─────────────────────────────────────┘
                      │ MQTT (porta 1883 dev / 8883 prod)
                      ▼
┌─────────────────────────────────────────────────────────┐
│              🔌 Eclipse Mosquitto (Broker)              │
│  Autenticação obrigatória | SSL/TLS em produção         │
└──────────┬──────────────────────────────┬───────────────┘
           │                              │
           │                              ▼
           │                    ┌──────────────────────┐
           │                    │   📊 Grafana 10.3    │
           │                    │   Dashboards Live     │
           │                    └──────────────────────┘
           │                              ▲
           ▼                              │
┌──────────────────────┐     ┌───────────┴──────────────┐
│  📡 Telegraf 1.29    │────▶│   💾 InfluxDB 2.x        │
│  MQTT → InfluxDB     │     │   Séries Temporais       │
└──────────────────────┘     └───────────┬──────────────┘
                                         │
                                         ▼
                              ┌────────────────────────┐
                              │  🤖 Analytics Python   │
                              │  Processamento & Regras│
                              └────────────────────────┘
                                         │
                                         ▼
                              ┌────────────────────────┐
                              │  💾 Backup Automático  │
                              │  Local + Remoto        │
                              └────────────────────────┘
```

### Fluxo de Dados

1. **Coleta:** Sensores enviam dados via MQTT para o Mosquitto
2. **Roteamento:** Telegraf consome mensagens do tópico `mov/dados/#`
3. **Armazenamento:** Dados gravados no InfluxDB com tags e fields
4. **Visualização:** Grafana consulta InfluxDB e renderiza dashboards
5. **Processamento:** Analytics lê InfluxDB, processa regras e grava insights
6. **Proteção:** Backup diário compacta dados de Grafana e InfluxDB

---

## 🛠️ Stack Tecnológica

| Componente            | Versão | Função                             | Porta                        |
| --------------------- | ------ | ---------------------------------- | ---------------------------- |
| **Eclipse Mosquitto** | 2.x    | Broker MQTT com TLS                | 1883 (dev), 8883 (prod)      |
| **InfluxDB**          | 2.x    | Banco de dados de séries temporais | 8086                         |
| **Telegraf**          | 1.29   | Coletor MQTT → InfluxDB            | -                            |
| **Grafana**           | 10.3.3 | Visualização e dashboards          | 3000 (dev), via Nginx (prod) |
| **Python**            | 3.11+  | Processamento analítico            | -                            |
| **Nginx**             | Alpine | Proxy reverso com SSL              | 80, 443                      |
| **Docker**            | 24+    | Orquestração de containers         | -                            |
| **Rclone**            | Latest | Backup remoto criptografado        | -                            |

**Diferenciais:**

- ✅ Usuários não-root em todos os containers
- ✅ Health checks com restart automático
- ✅ Separação dev/prod com overlays Docker Compose
- ✅ Volumes persistentes para dados críticos

---

                    │  InfluxDB   │◀────│  Analytics  │
                    │   (Dados)   │     │   (Python)  │
                    └──────┬──────┘     └─────────────┘
                           │
                           ▼
                    ┌─────────────┐
                    │   Grafana   │
                    │ (Dashboards)│
                    └─────────────┘

````

## 🔧 Pré-requisitos

- Docker (versão 20.10 ou superior)
- Docker Compose (versão 2.0 ou superior)
- 2GB de RAM disponível
- Portas disponíveis: 1883 (MQTT), 3000 (Grafana), 8086 (InfluxDB), 9001 (WebSockets)

## 📦 Instalação

### Instalação Rápida (Recomendado)

#### Opção 1: Setup Wizard Interativo ⭐ NOVO

```bash
# 1. Clone o repositório
git clone <seu-repositorio>
cd MOV-Plataform

# 2. Execute o wizard interativo (escolha ambiente e componentes)
chmod +x scripts/setup_wizard.sh
./scripts/setup_wizard.sh

# 3. Siga as instruções na tela
# O wizard irá configurar tudo automaticamente!
```

---

### Instalação Manual (Não Recomendado)

Se por algum motivo você não puder usar o wizard, pode criar manualmente:

#### 1. Clone o repositório

```bash
git clone <seu-repositorio>
cd MOV-Plataform
```

#### 2. Crie o arquivo `.env` manualmente:

```env
# MQTT Credentials
MQTT_USER=admin
MQTT_PASSWORD=sua_senha_forte_aqui

# InfluxDB Configuration
INFLUX_USER=admin
INFLUX_PASSWORD=sua_senha_influx  # Mínimo 8 caracteres
INFLUX_ORG=mov_industria
INFLUX_BUCKET=mov_dados
INFLUX_TOKEN=seu_token_aqui

# Grafana
GRAFANA_PASSWORD=sua_senha_grafana
```

#### 3. Crie a estrutura de diretórios

```bash
mkdir -p mosquitto/{config,data,log} influxdb/config backups
```

#### 4. Inicie a plataforma

```bash
docker compose up -d
```

## 🚀 Uso

### Iniciar a Plataforma

```bash
sudo docker compose up -d
```

O `-d` (detached) executa em segundo plano. Os serviços estarão disponíveis em:

- **Grafana**: http://localhost:3000 (usuário: `admin`)
- **InfluxDB**: http://localhost:8086
- **MQTT Broker**: `localhost:1883`
- **MQTT WebSocket**: `ws://localhost:9001`

### Parar a Plataforma

#### Opção 1: Pausar os containers (rápido)

```bash
sudo docker compose stop
```

**O que faz:** Apenas congela os containers.
**Vantagem:** É super rápido para ligar de novo depois.

#### Opção 2: Parar e remover containers (recomendado)

```bash
sudo docker compose down -v
```

**O que faz:** Para os containers e remove a rede virtual criada pelo Docker.

⚠️ **IMPORTANTE:** Você **NÃO PERDE** seus dados (dashboards, usuários, histórico de medições). Tudo está salvo nos volumes Docker e pastas `data/`. Pode rodar sem medo!

### Reiniciar a Plataforma

```bash
sudo docker compose restart
```

⚠️ **Atenção ao Reiniciar:** Se o InfluxDB apresentar problemas após reiniciar (container "zumbi"), limpe a pasta de configuração:

```bash
sudo rm -rf influxdb/config/*
sudo docker compose up -d
```

Isso força o InfluxDB a recriar as configurações do zero sem perder os dados do volume.

### Ver Logs

```bash
# Todos os serviços
sudo docker compose logs -f

# Serviço específico
sudo docker compose logs -f analytics
sudo docker compose logs -f mosquitto
sudo docker compose logs -f telegraf
```

## ⚙️ Configuração

### Formato de Mensagens MQTT

Os dados devem ser enviados no tópico `mov/dados/#` com o seguinte formato JSON:

```json
{
  "timestamp": "2026-02-02T15:04:05.999Z",
  "tags": {
    "dispositivo": "sensor_01",
    "localizacao": "linha_producao_1",
    "tipo": "temperatura",
    "cliente": "empresa_x"
  },
  "fields": {
    "temperatura_c": 25.5,
    "umidade": 60.0,
    "pressao": 1013.25
  }
}
```

### Exemplo de Publicação (usando mosquitto_pub)

```bash
mosquitto_pub -h localhost -p 1883 \
  -u seu_usuario -P sua_senha \
  -t "mov/dados/sensor01" \
  -m '{"timestamp":"2026-02-02T15:04:05.999Z","tags":{"dispositivo":"sensor_01","localizacao":"fabrica","tipo":"temperatura","cliente":"acme"},"fields":{"temperatura_c":28.5}}'
```

## 🔌 Serviços

### 1. Mosquitto (MQTT Broker)

**Porta:** 1883 (MQTT), 9001 (WebSocket)
**Container:** `mov_broker`

Broker MQTT responsável por receber dados dos sensores IoT. Configurado com autenticação obrigatória.

### 2. InfluxDB

**Porta:** 8086
**Container:** `mov_influx`

Banco de dados de séries temporais otimizado para dados de IoT. Armazena todas as medições com alta performance.

### 3. Telegraf

**Container:** `mov_telegraf`

Agente de coleta que consome mensagens MQTT e grava no InfluxDB automaticamente. Executa a cada 5 segundos.

### 4. Grafana

**Porta:** 3000
**Container:** `mov_grafana`

Plataforma de visualização com dashboards interativos. Acesse com o usuário `admin` e a senha configurada no `.env`.

### 5. Analytics (Python)

**Container:** `mov_analytics`

Serviço Python que processa dados em tempo real, gerando insights automáticos:

- Verifica temperaturas críticas (> 30°C)
- Grava status calculado de volta no InfluxDB
- Executa análises a cada 10 segundos

### 6. Backup Automático

**Container:** `mov_backup`

Sistema de backup automatizado que:

- Executa diariamente
- Compacta dados do Grafana e InfluxDB
- Salva em `./backups/`
- Remove backups com mais de 7 dias automaticamente

## 💾 Backup e Segurança

### Sistema de Backup Multi-Camada

A MOV Platform implementa **proteção de dados profissional** com dupla camada de backup:

#### 🔵 Camada 1: Backup Local Automático

- **Frequência:** Diário às 1h AM
- **Conteúdo:** Dados completos de Grafana e InfluxDB
- **Formato:** `.tar.gz` comprimido
- **Retenção:** 7 dias (limpeza automática)
- **Localização:** `./backups/`

```bash
# Backups gerados automaticamente
backups/
├── grafana_20250202_010000.tar.gz
└── influxdb_20250202_010000.tar.gz
```

#### 🔵 Camada 2: Backup Remoto Criptografado (Opcional)

- **Frequência:** Diário às 2h AM
- **Provedores suportados:**
  - Google Drive (15GB grátis)
  - MEGA (20GB grátis)
  - OneDrive (5GB grátis)
  - Dropbox (2GB grátis)
- **Criptografia:** AES-256 em trânsito via Rclone
- **Retenção:** 30 dias
- **Senhas:** Armazenadas em `.env` (256 bits de entropia)

**Configurar backup remoto:**

```bash
bash scripts/setup_remote_backup.sh
# Menu interativo com 4 opções de provedor
# Criptografia opcional (recomendado)
```

### Segurança Implementada

| Camada           | Proteção                             | Status      |
| ---------------- | ------------------------------------ | ----------- |
| **Rede**         | Firewall UFW (script automatizado)   | ✅ Produção |
| **Transporte**   | TLS 1.2+ (MQTT 8883, HTTPS 443)      | ✅ Produção |
| **Autenticação** | Credenciais fortes (256-512 bits)    | ✅ Dev/Prod |
| **Backup**       | AES-256 + armazenamento redundante   | ✅ Opcional |
| **Containers**   | Usuários não-root, health checks     | ✅ Dev/Prod |
| **Certificados** | Let's Encrypt + renovação automática | ✅ Produção |

**Para relatório completo de segurança**, consulte [SECURITY-REPORT.md](SECURITY-REPORT.md)

**Pontuação de segurança:** 92/100 ⭐⭐⭐⭐⭐

### Restauração de Backup

```bash
# Parar containers
sudo docker compose down

# Restaurar arquivos
tar xzf backups/grafana_YYYYMMDD_HHMMSS.tar.gz -C grafana/data/
tar xzf backups/influxdb_YYYYMMDD_HHMMSS.tar.gz -C influxdb/data/

# Corrigir permissões
sudo chown -R 472:472 grafana/data/
sudo chown -R 1000:1000 influxdb/data/

# Reiniciar
sudo docker compose up -d
```

**Tempo de recuperação (RTO):** ~30 minutos
**Ponto de recuperação (RPO):** Até 24 horas

---

## � Documentação Completa

A MOV Platform oferece **documentação de nível comercial** para todas as etapas:

| Arquivo                                                                    | Conteúdo                                      | Público-Alvo                |
| -------------------------------------------------------------------------- | --------------------------------------------- | --------------------------- |
| **[README.md](README.md)**                                                 | Visão geral, quick start, arquitetura         | Desenvolvedores, gestores   |
| **[SECURITY-REPORT.md](SECURITY-REPORT.md)**                               | Análise completa de segurança (92/100)        | CISO, auditores, arquitetos |
| **[instructions/DEPLOY.md](instructions/DEPLOY.md)**                       | Guia passo a passo de deploy em VPS           | DevOps, sysadmins           |
| **[instructions/DEV-WORKFLOW.md](instructions/DEV-WORKFLOW.md)**           | Workflow de desenvolvimento local e em equipe | Desenvolvedores             |
| **[instructions/UPDATES.md](instructions/UPDATES.md)**                     | Procedimentos de atualização e manutenção     | DevOps                      |
| **[instructions/MQTT-CERT-RENEWAL.md](instructions/MQTT-CERT-RENEWAL.md)** | Gerenciamento de certificados MQTT            | Sysadmins                   |

**Destaque:** Todos os guias incluem exemplos práticos, comandos testados e troubleshooting.

---

## 🔐 Segurança

- MQTT configurado com autenticação obrigatória
- Senhas armazenadas em variáveis de ambiente
- Comunicação entre containers em rede interna
- InfluxDB com token de acesso

## 📝 Notas Importantes

- Os dados persistem mesmo após `docker compose down` graças aos volumes
- Fechar o terminal **NÃO** para os containers (rodando com `-d`)
- Para limpar completamente (incluindo volumes): `sudo docker compose down -v` ⚠️ **Isso apaga TODOS os dados!**
- Logs são rotacionados automaticamente pelo Docker

## 🤝 Contribuindo

Contribuições são bem-vindas! Sinta-se à vontade para abrir issues e pull requests.

## 📄 Licença

Este projeto é **propriedade comercial** e todos os direitos são reservados. O uso, distribuição ou modificação sem autorização expressa é proibido.

## 📧 Contato

Para dúvidas ou sugestões, abra uma issue no repositório.

---

**MOV Platform** - Monitoramento Industrial Inteligente 🏭
````
