#!/bin/bash
# ==============================================================================
# MOV Platform - Setup Wizard Interativo
# ==============================================================================
# Este script guia o usuário na configuração inicial da plataforma,
# permitindo escolher ambiente, componentes e configurações personalizadas.
# ==============================================================================

set -e

# Cores para output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Diretório do projeto
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
cd "$PROJECT_DIR"

# Funções auxiliares
print_header() {
    echo ""
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}  $1${NC}"
    echo -e "${BLUE}========================================${NC}"
    echo ""
}

print_success() {
    echo -e "${GREEN}✓${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

print_error() {
    echo -e "${RED}✗${NC} $1"
}

print_info() {
    echo -e "${BLUE}ℹ${NC} $1"
}

# Banner de boas-vindas
clear
echo -e "${GREEN}"
cat << "EOF"
    __  ________ _    __   ____  __      __  ____                 
   /  |/  / __ \ |  / /  / __ \/ /___ _/ /_/ __/___  _________ ___
  / /|_/ / / / / | / /  / /_/ / / __ `/ __/ /_/ __ \/ ___/ __ `__ \
 / /  / / /_/ /| |/ /  / ____/ / /_/ / /_/ __/ /_/ / /  / / / / / /
/_/  /_/\____/ |___/  /_/   /_/\__,_/\__/_/  \____/_/  /_/ /_/ /_/ 
                                                                    
EOF
echo -e "${NC}"
echo "                   Setup Wizard - Configuração Interativa"
echo ""

# Verificações iniciais
print_info "Verificando pré-requisitos..."

# Verificar Docker
if ! docker info > /dev/null 2>&1; then
    print_error "Docker não está rodando ou não está instalado"
    echo ""
    echo "Instale com: curl -fsSL https://get.docker.com | sh"
    exit 1
fi

# Verificar Docker Compose
if ! command -v docker compose &> /dev/null && ! command -v docker-compose &> /dev/null; then
    print_error "Docker Compose não encontrado"
    exit 1
fi

print_success "Docker e Docker Compose disponíveis"
echo ""

# Variáveis de configuração
ENVIRONMENT=""
INSTALL_GRAFANA="y"
INSTALL_INFLUXDB="y"
INSTALL_MOSQUITTO="y"
INSTALL_TELEGRAF="y"
INSTALL_ANALYTICS="y"
INSTALL_NGINX="n"
INSTALL_BACKUP="y"
GRAFANA_DOMAIN=""
MQTT_DOMAIN=""

# ==============================================================================
# ETAPA 1: Escolher Ambiente
# ==============================================================================
print_header "Etapa 1/3: Escolha o Ambiente"

echo "Selecione o tipo de ambiente para deploy:"
echo ""
echo -e "  ${GREEN}1)${NC} ${BLUE}Desenvolvimento${NC}"
echo "     • Todas as portas expostas (fácil acesso)"
echo "     • Sem SSL/TLS"
echo "     • Ideal para: Testes locais no seu PC"
echo ""
echo -e "  ${GREEN}2)${NC} ${BLUE}Staging${NC}"
echo "     • Portas seletivas expostas"
echo "     • SSL opcional"
echo "     • Ideal para: Homologação e testes"
echo ""
echo -e "  ${GREEN}3)${NC} ${BLUE}Produção${NC}"
echo "     • Apenas portas essenciais (80, 443, 8883)"
echo "     • SSL obrigatório"
echo "     • Firewall configurado"
echo "     • Ideal para: Deploy em VPS"
echo ""

while true; do
    read -p "Escolha [1-3]: " ENV_CHOICE
    case $ENV_CHOICE in
        1)
            ENVIRONMENT="development"
            print_success "Ambiente: Desenvolvimento"
            break
            ;;
        2)
            ENVIRONMENT="staging"
            print_success "Ambiente: Staging"
            break
            ;;
        3)
            ENVIRONMENT="production"
            INSTALL_NGINX="y"
            print_success "Ambiente: Produção"
            break
            ;;
        *)
            print_error "Opção inválida. Escolha 1, 2 ou 3."
            ;;
    esac
done

# ==============================================================================
# ETAPA 2: Selecionar Componentes
# ==============================================================================
print_header "Etapa 2/3: Selecione os Componentes"

echo "Escolha quais serviços deseja instalar:"
echo ""
print_info "Pressione Enter para aceitar o padrão [Y/n]"
echo ""

# Grafana
read -p "  📊 Grafana (Dashboards de visualização)? [Y/n]: " input
INSTALL_GRAFANA="${input:-y}"

# InfluxDB
read -p "  💾 InfluxDB (Banco de dados de séries temporais)? [Y/n]: " input
INSTALL_INFLUXDB="${input:-y}"

# Mosquitto
read -p "  🔌 Mosquitto (Broker MQTT para IoT)? [Y/n]: " input
INSTALL_MOSQUITTO="${input:-y}"

# Telegraf
if [[ "$INSTALL_MOSQUITTO" =~ ^[Yy]$ ]] && [[ "$INSTALL_INFLUXDB" =~ ^[Yy]$ ]]; then
    read -p "  📡 Telegraf (Coletor MQTT → InfluxDB)? [Y/n]: " input
    INSTALL_TELEGRAF="${input:-y}"
else
    INSTALL_TELEGRAF="n"
    print_warning "Telegraf desabilitado (requer Mosquitto e InfluxDB)"
fi

# Analytics
if [[ "$INSTALL_INFLUXDB" =~ ^[Yy]$ ]]; then
    read -p "  🤖 Analytics (Processamento Python em tempo real)? [Y/n]: " input
    INSTALL_ANALYTICS="${input:-y}"
else
    INSTALL_ANALYTICS="n"
    print_warning "Analytics desabilitado (requer InfluxDB)"
fi

# Nginx
if [ "$ENVIRONMENT" != "production" ]; then
    read -p "  🌐 Nginx (Proxy reverso com SSL)? [y/N]: " input
    INSTALL_NGINX="${input:-n}"
else
    INSTALL_NGINX="y"
    print_info "Nginx obrigatório em produção (proxy reverso + SSL)"
fi

# Backup
read -p "  💾 Sistema de Backup automático? [Y/n]: " input
INSTALL_BACKUP="${input:-y}"

echo ""
print_success "Componentes selecionados!"

# ==============================================================================
# ETAPA 3: Configurações Específicas
# ==============================================================================
print_header "Etapa 3/3: Configurações Específicas"

# Domínios (apenas em produção)
if [ "$ENVIRONMENT" = "production" ]; then
    echo "Configuração de Domínios (para SSL):"
    echo ""
    print_info "Você pode pular esta etapa e configurar depois"
    echo ""
    
    read -p "  Domínio para Grafana (ex: grafana.exemplo.com) [Enter para pular]: " GRAFANA_DOMAIN
    
    if [[ "$INSTALL_MOSQUITTO" =~ ^[Yy]$ ]]; then
        read -p "  Domínio para MQTT (ex: mqtt.exemplo.com) [Enter para pular]: " MQTT_DOMAIN
    fi
    
    # Salvar domínios se fornecidos
    if [ -n "$GRAFANA_DOMAIN" ] || [ -n "$MQTT_DOMAIN" ]; then
        cat > .env.domains <<EOF
# Domínios configurados pelo Setup Wizard
GRAFANA_DOMAIN=${GRAFANA_DOMAIN:-grafana.exemplo.com}
MQTT_DOMAIN=${MQTT_DOMAIN:-mqtt.exemplo.com}
EOF
        print_success "Domínios salvos em .env.domains"
    fi
fi

# Configurações do Analytics
if [[ "$INSTALL_ANALYTICS" =~ ^[Yy]$ ]]; then
    echo ""
    echo "Configurações do Analytics:"
    read -p "  Limite de temperatura (°C) para alertas [30.0]: " TEMP_THRESHOLD
    TEMP_THRESHOLD="${TEMP_THRESHOLD:-30.0}"
    
    read -p "  Intervalo de processamento (segundos) [10]: " ANALYTICS_INTERVAL
    ANALYTICS_INTERVAL="${ANALYTICS_INTERVAL:-10}"
fi

# ==============================================================================
# RESUMO DA CONFIGURAÇÃO
# ==============================================================================
print_header "Resumo da Configuração"

echo -e "${BLUE}Ambiente:${NC} $ENVIRONMENT"
echo ""
echo -e "${BLUE}Componentes:${NC}"
[[ "$INSTALL_GRAFANA" =~ ^[Yy]$ ]] && echo "  ✓ Grafana"
[[ "$INSTALL_INFLUXDB" =~ ^[Yy]$ ]] && echo "  ✓ InfluxDB"
[[ "$INSTALL_MOSQUITTO" =~ ^[Yy]$ ]] && echo "  ✓ Mosquitto (MQTT)"
[[ "$INSTALL_TELEGRAF" =~ ^[Yy]$ ]] && echo "  ✓ Telegraf"
[[ "$INSTALL_ANALYTICS" =~ ^[Yy]$ ]] && echo "  ✓ Analytics (Temp: ${TEMP_THRESHOLD}°C, Intervalo: ${ANALYTICS_INTERVAL}s)"
[[ "$INSTALL_NGINX" =~ ^[Yy]$ ]] && echo "  ✓ Nginx"
[[ "$INSTALL_BACKUP" =~ ^[Yy]$ ]] && echo "  ✓ Backup automático"

if [ "$ENVIRONMENT" = "production" ]; then
    echo ""
    echo -e "${BLUE}Domínios:${NC}"
    [ -n "$GRAFANA_DOMAIN" ] && echo "  • Grafana: $GRAFANA_DOMAIN"
    [ -n "$MQTT_DOMAIN" ] && echo "  • MQTT: $MQTT_DOMAIN"
fi

echo ""
read -p "Confirmar e continuar? [Y/n]: " CONFIRM
if [[ ! "$CONFIRM" =~ ^[Yy]$|^$ ]]; then
    print_warning "Setup cancelado pelo usuário."
    exit 0
fi

# ==============================================================================
# EXECUTANDO CONFIGURAÇÃO
# ==============================================================================
print_header "Executando Configuração"

# 1. Gerar arquivo .env se não existir
echo -n "Gerando credenciais... "
if [ ! -f .env ]; then
    # Gerar credenciais inline (sem depender de script externo)
    cat > .env <<ENVFILE
# ==========================================
# MOV Platform - Credenciais de Produção
# Gerado em: $(date)
# MANTENHA ESTE ARQUIVO SEGURO!
# ==========================================

# MQTT Credentials
MQTT_USER=admin_$(openssl rand -hex 4)
MQTT_PASSWORD=$(openssl rand -base64 32 | tr -d '\n')

# InfluxDB Configuration
INFLUX_USER=admin_influx
INFLUX_PASSWORD=$(openssl rand -base64 32 | tr -d '\n')
INFLUX_ORG=mov_industria
INFLUX_BUCKET=mov_dados
INFLUX_TOKEN=$(openssl rand -base64 64 | tr -d '\n')

# Grafana
GRAFANA_PASSWORD=$(openssl rand -base64 32 | tr -d '\n')

# Backup Remoto - Criptografia
BACKUP_CRYPT_PASSWORD=$(openssl rand -base64 32 | tr -d '\n')
BACKUP_CRYPT_SALT=$(openssl rand -base64 32 | tr -d '\n')
ENVFILE
    
    # Adicionar configurações do Analytics se instalado
    if [[ "$INSTALL_ANALYTICS" =~ ^[Yy]$ ]]; then
        cat >> .env <<ENVFILE

# Analytics Configuration
ANALYTICS_TEMP_THRESHOLD=${TEMP_THRESHOLD}
ANALYTICS_INTERVAL=${ANALYTICS_INTERVAL}
ENVFILE
    fi
    
    chmod 600 .env
    print_success "Credenciais geradas e protegidas"
else
    print_info "Arquivo .env já existe (mantido)"
fi

# 2. Criar estrutura de diretórios
echo -n "Criando estrutura de diretórios... "
[[ "$INSTALL_MOSQUITTO" =~ ^[Yy]$ ]] && mkdir -p mosquitto/{config,data,log,certs}
[[ "$INSTALL_INFLUXDB" =~ ^[Yy]$ ]] && mkdir -p influxdb/config
[[ "$INSTALL_NGINX" =~ ^[Yy]$ ]] && mkdir -p nginx/{conf.d,ssl}
[[ "$INSTALL_BACKUP" =~ ^[Yy]$ ]] && mkdir -p backups
print_success "Diretórios criados"

# 3. Configurar permissões (inline - não depende de script externo)
echo -n "Configurando permissões... "

# Função inline para configurar permissões
configure_permissions() {
    local path="$1"
    local uid="$2"
    local gid="$3"
    
    if [ -d "$path" ]; then
        if command -v sudo &> /dev/null; then
            sudo chown -R "$uid:$gid" "$path" 2>/dev/null || true
            sudo chmod -R 755 "$path" 2>/dev/null || true
        else
            chown -R "$uid:$gid" "$path" 2>/dev/null || true
            chmod -R 755 "$path" 2>/dev/null || true
        fi
    fi
}

# Mosquitto (UID:GID 1883:1883)
[[ "$INSTALL_MOSQUITTO" =~ ^[Yy]$ ]] && configure_permissions "$PROJECT_DIR/mosquitto/config" "1883" "1883"
[[ "$INSTALL_MOSQUITTO" =~ ^[Yy]$ ]] && configure_permissions "$PROJECT_DIR/mosquitto/data" "1883" "1883"
[[ "$INSTALL_MOSQUITTO" =~ ^[Yy]$ ]] && configure_permissions "$PROJECT_DIR/mosquitto/log" "1883" "1883"

# Certificados Mosquitto
if [[ "$INSTALL_MOSQUITTO" =~ ^[Yy]$ ]] && [ -d "$PROJECT_DIR/mosquitto/certs" ]; then
    configure_permissions "$PROJECT_DIR/mosquitto/certs" "1883" "1883"
    chmod 600 "$PROJECT_DIR/mosquitto/certs"/*.key 2>/dev/null || true
    chmod 644 "$PROJECT_DIR/mosquitto/certs"/*.crt 2>/dev/null || true
fi

# InfluxDB (UID:GID 1000:1000)
[[ "$INSTALL_INFLUXDB" =~ ^[Yy]$ ]] && configure_permissions "$PROJECT_DIR/influxdb/config" "1000" "1000"

# Scripts executáveis
chmod +x scripts/*.sh 2>/dev/null || true
chmod +x mosquitto/docker-entrypoint.sh 2>/dev/null || true

print_success "Permissões configuradas"

# 4. Gerar docker-compose customizado
echo -n "Gerando configuração Docker Compose... "

# Criar arquivo de configuração para geração
cat > .setup_config <<EOF
ENVIRONMENT=$ENVIRONMENT
INSTALL_GRAFANA=$INSTALL_GRAFANA
INSTALL_INFLUXDB=$INSTALL_INFLUXDB
INSTALL_MOSQUITTO=$INSTALL_MOSQUITTO
INSTALL_TELEGRAF=$INSTALL_TELEGRAF
INSTALL_ANALYTICS=$INSTALL_ANALYTICS
INSTALL_NGINX=$INSTALL_NGINX
INSTALL_BACKUP=$INSTALL_BACKUP
EOF

print_success "Configuração salva"

# 5. Criar arquivo docker-compose.override.yml customizado para ambiente
if [ "$ENVIRONMENT" = "development" ]; then
    cat > docker-compose.override.yml <<EOF
# docker-compose.override.yml
# Configuração automática para ambiente de Desenvolvimento
# Gerado pelo Setup Wizard

services:
EOF

    if [[ "$INSTALL_INFLUXDB" =~ ^[Yy]$ ]]; then
        cat >> docker-compose.override.yml <<EOF
  influxdb:
    ports:
      - "8086:8086"
EOF
    fi

    if [[ "$INSTALL_GRAFANA" =~ ^[Yy]$ ]]; then
        cat >> docker-compose.override.yml <<EOF
  grafana:
    ports:
      - "3000:3000"
EOF
    fi
    
    print_info "Arquivo docker-compose.override.yml criado (portas expostas para dev)"
fi

# ==============================================================================
# FINALIZAÇÃO
# ==============================================================================
print_header "Setup Concluído com Sucesso!"

echo -e "${GREEN}✓${NC} Ambiente configurado: ${BLUE}$ENVIRONMENT${NC}"
echo -e "${GREEN}✓${NC} Componentes instalados: $(echo "$INSTALL_GRAFANA $INSTALL_INFLUXDB $INSTALL_MOSQUITTO $INSTALL_TELEGRAF $INSTALL_ANALYTICS $INSTALL_NGINX $INSTALL_BACKUP" | grep -o 'y' | wc -l) de 7"
echo ""

print_info "Próximos passos:"
echo ""

case $ENVIRONMENT in
    development)
        echo -e "  ${BLUE}1.${NC} Iniciar a plataforma:"
        echo "     ${YELLOW}docker compose up -d${NC}"
        echo ""
        echo -e "  ${BLUE}2.${NC} Acessar serviços:"
        [[ "$INSTALL_GRAFANA" =~ ^[Yy]$ ]] && echo "     • Grafana: http://localhost:3000"
        [[ "$INSTALL_INFLUXDB" =~ ^[Yy]$ ]] && echo "     • InfluxDB: http://localhost:8086"
        [[ "$INSTALL_MOSQUITTO" =~ ^[Yy]$ ]] && echo "     • MQTT: localhost:1883"
        echo ""
        echo -e "  ${BLUE}3.${NC} Ver logs:"
        echo "     ${YELLOW}docker compose logs -f${NC}"
        ;;
    
    staging)
        echo -e "  ${BLUE}1.${NC} Iniciar a plataforma:"
        echo "     ${YELLOW}docker compose up -d${NC}"
        echo ""
        echo -e "  ${BLUE}2.${NC} Configurar SSL (opcional):"
        echo "     ${YELLOW}sudo bash scripts/setup_ssl.sh seu-dominio.com${NC}"
        ;;
    
    production)
        echo -e "  ${BLUE}1.${NC} Executar o deploy:"
        echo "     ${YELLOW}bash scripts/deploy.sh${NC}"
        echo ""
        echo -e "  ${BLUE}2.${NC} Configurar firewall:"
        echo "     ${YELLOW}sudo bash scripts/setup_firewall.sh${NC}"
        echo ""
        echo -e "  ${BLUE}3.${NC} Configurar SSL:"
        if [ -n "$GRAFANA_DOMAIN" ]; then
            echo "     ${YELLOW}sudo bash scripts/setup_ssl.sh $GRAFANA_DOMAIN${NC}"
        else
            echo "     ${YELLOW}sudo bash scripts/setup_ssl.sh seu-dominio.com${NC}"
        fi
        echo ""
        echo -e "  ${BLUE}4.${NC} Configurar backup remoto (recomendado):"
        echo "     ${YELLOW}bash scripts/setup_remote_backup.sh${NC}"
        ;;
esac

echo ""
print_info "Senhas e tokens estão no arquivo: ${YELLOW}.env${NC}"
print_warning "Mantenha o arquivo .env seguro e não commite no Git!"

echo ""
echo -e "${BLUE}========================================${NC}"
echo -e "${GREEN}   Boa sorte com sua plataforma IoT!${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""
