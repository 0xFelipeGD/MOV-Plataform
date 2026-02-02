# 🏭 MOV Platform - Plataforma de Monitoramento IoT Industrial

Uma plataforma completa de monitoramento industrial baseada em IoT, utilizando MQTT, InfluxDB, Telegraf, Grafana e Analytics com Python.

## ⚡ Início Rápido (3 comandos!)

```bash
git clone <seu-repositorio> && cd MOV-Plataform
chmod +x scripts/setup.sh && ./scripts/setup.sh
docker compose up -d
```

**Pronto!** Acesse: http://localhost:3000 (Grafana) | http://localhost:8086 (InfluxDB)  
_Credenciais geradas automaticamente estão no arquivo `.env`_

---

## 📋 Índice

- [Início Rápido](#-início-rápido-3-comandos)
- [Sobre o Projeto](#sobre-o-projeto)
- [Arquitetura](#arquitetura)
- [Pré-requisitos](#pré-requisitos)
- [Instalação](#instalação)
- [Uso](#uso)
- [Configuração](#configuração)
- [Serviços](#serviços)
- [Backup Automático](#backup-automático)
- [Desenvolvimento](#desenvolvimento)

## 🎯 Sobre o Projeto

A **MOV Platform** é uma solução completa para monitoramento de dados industriais em tempo real. O sistema coleta dados de sensores IoT via protocolo MQTT, armazena em banco de dados de séries temporais, processa insights automaticamente e visualiza tudo em dashboards profissionais.

### Principais Funcionalidades

- 📡 Coleta de dados via MQTT
- 💾 Armazenamento em banco de dados de séries temporais (InfluxDB)
- 📊 Visualização em tempo real com Grafana
- 🤖 Processamento automático de insights com Python
- 🔒 Autenticação e segurança integradas
- 💾 Sistema de backup automático diário
- 🐳 Totalmente containerizado com Docker

## 🏗️ Arquitetura

```
┌─────────────┐
│   Sensores  │ (ESP32, Raspberry Pi, etc.)
│     IoT     │
└──────┬──────┘
       │ MQTT
       ▼
┌─────────────┐     ┌─────────────┐
│  Mosquitto  │────▶│  Telegraf   │
│   (Broker)  │     │  (Coletor)  │
└─────────────┘     └──────┬──────┘
                           │
                           ▼
                    ┌─────────────┐     ┌─────────────┐
                    │  InfluxDB   │◀────│  Analytics  │
                    │   (Dados)   │     │   (Python)  │
                    └──────┬──────┘     └─────────────┘
                           │
                           ▼
                    ┌─────────────┐
                    │   Grafana   │
                    │ (Dashboards)│
                    └─────────────┘
```

## 🔧 Pré-requisitos

- Docker (versão 20.10 ou superior)
- Docker Compose (versão 2.0 ou superior)
- 2GB de RAM disponível
- Portas disponíveis: 1883 (MQTT), 3000 (Grafana), 8086 (InfluxDB), 9001 (WebSockets)

## 📦 Instalação

### Instalação Rápida (Recomendado)

```bash
# 1. Clone o repositório
git clone <seu-repositorio>
cd MOV-Plataform

# 2. Execute o script de setup (cria estrutura e gera credenciais automaticamente)
chmod +x scripts/setup.sh
./scripts/setup.sh

# 3. Inicie a plataforma
docker compose up -d

# 4. Verifique se está tudo rodando
docker compose ps
```

**Pronto!** 🎉 A plataforma está funcionando. Acesse:

- **Grafana**: http://localhost:3000 (usuário: admin, senha: no arquivo `.env`)
- **InfluxDB**: http://localhost:8086
- **MQTT**: localhost:1883

---

### Instalação Manual (Opcional)

Se preferir configurar manualmente:

#### 1. Clone o repositório

```bash
git clone <seu-repositorio>
cd MOV-Plataform
```

#### 2. Gere as credenciais automaticamente

```bash
chmod +x scripts/generate_credentials.sh
./scripts/generate_credentials.sh > .env
```

Ou crie manualmente o arquivo `.env`:

```env
# MQTT Credentials
MQTT_USER=seu_usuario
MQTT_PASSWORD=sua_senha

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

## 💾 Backup Automático

Os backups são criados automaticamente a cada 24 horas em:

```
backups/
├── grafana_20260202_153045.tar.gz
└── influxdb_20260202_153045.tar.gz
```

### Restaurar um Backup

```bash
# Parar os serviços
sudo docker compose down

# Extrair backup do Grafana
tar xzf backups/grafana_YYYYMMDD_HHMMSS.tar.gz -C grafana/data/

# Extrair backup do InfluxDB
tar xzf backups/influxdb_YYYYMMDD_HHMMSS.tar.gz -C influxdb/data/

# Reiniciar
sudo docker compose up -d
```

## 🛠️ Desenvolvimento

### Estrutura do Projeto

```
MOV-Plataform/
├── docker-compose.yml        # Orquestração dos serviços
├── .env                       # Variáveis de ambiente (não versionado)
├── analytics/                 # Serviço de processamento Python
│   ├── Dockerfile
│   ├── main.py
│   └── requirements.txt
├── mosquitto/                 # Configurações MQTT
│   ├── config/
│   │   ├── mosquitto.conf
│   │   └── passwd
│   ├── data/                  # Dados persistidos
│   └── log/                   # Logs do broker
├── telegraf/                  # Configurações do coletor
│   └── config/
│       └── telegraf.conf
├── influxdb/                  # Dados e configurações do banco
│   ├── config/
│   └── data/
├── grafana/                   # Dashboards e configurações
│   └── data/
└── backups/                   # Backups automáticos
```

### Modificar o Analytics

1. Edite `analytics/main.py`
2. Reconstrua o container:

```bash
sudo docker compose up -d --build analytics
```

### Adicionar Dependências Python

1. Adicione no `analytics/requirements.txt`
2. Reconstrua:

```bash
sudo docker compose up -d --build analytics
```

### Verificar Status dos Containers

```bash
sudo docker compose ps
```

### Acessar Shell de um Container

```bash
sudo docker exec -it mov_analytics sh
sudo docker exec -it mov_influx bash
```

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
