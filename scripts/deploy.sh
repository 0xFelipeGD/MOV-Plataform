#!/bin/bash
# MOV Platform - Script de Deploy para VPS
# Uso: bash scripts/deploy.sh

set -e

echo "========================================="
echo "MOV Platform - Deploy em Produção (VPS)"
echo "========================================="
echo ""

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_success() { echo -e "${GREEN}✅${NC} $1"; }
print_error() { echo -e "${RED}❌${NC} $1"; }
print_warning() { echo -e "${YELLOW}⚠️${NC} $1"; }
print_info() { echo -e "${BLUE}ℹ${NC} $1"; }

# Verificações iniciais
echo "[1/6] Verificando pré-requisitos..."

if ! command -v docker &> /dev/null; then
    print_error "Docker não está instalado!"
    echo "Instale com: curl -fsSL https://get.docker.com | sh"
    exit 1
fi

if ! command -v docker compose &> /dev/null; then
    print_error "Docker Compose não está instalado!"
    exit 1
fi

print_success "Docker e Docker Compose OK"
echo ""

# Verificar arquivo .env
echo "[2/6] Verificando credenciais..."

if [ ! -f .env ]; then
    print_error "Arquivo .env não encontrado!"
    echo ""
    echo "Execute primeiro o setup wizard:"
    echo "  bash scripts/setup_wizard.sh"
    echo ""
    echo "Ou execute o setup básico:"
    echo "  bash scripts/setup.sh"
    echo ""
    exit 1
fi

print_success "Arquivo .env encontrado"
echo ""

# Parar containers existentes
echo "[3/6] Parando containers antigos..."
docker compose down 2>/dev/null || true
print_success "Containers parados"
echo ""

# Verificar certificados SSL para Mosquitto
echo -e "${YELLOW}[4/7] Verificando certificados SSL (Mosquitto)...${NC}"

if [ ! -f mosquitto/certs/ca.crt ] || [ ! -f mosquitto/certs/server.crt ] || [ ! -f mosquitto/certs/server.key ]; then
    echo -e "${YELLOW}⚠️  Certificados SSL não encontrados para Mosquitto${NC}"
    echo ""
    echo "Gerando certificados autoassinados para teste..."
    mkdir -p mosquitto/certs
    
    # Gerar certificados autoassinados
    openssl req -new -x509 -days 365 -extensions v3_ca \
        -keyout mosquitto/certs/ca.key \
        -out mosquitto/certs/ca.crt \
        -subj "/CN=MOV-CA" \
        -nodes 2>/dev/null
    
    openssl genrsa -out mosquitto/certs/server.key 2048 2>/dev/null
    
    openssl req -new \
        -key mosquitto/certs/server.key \
        -out mosquitto/certs/server.csr \
        -subj "/CN=mov-broker" 2>/dev/null
    
    openssl x509 -req -in mosquitto/certs/server.csr \
        -CA mosquitto/certs/ca.crt \
        -CAkey mosquitto/certs/ca.key \
        -CAcreateserial \
        -out mosquitto/certs/server.crt \
        -days 365 2>/dev/null
    
    chmod 644 mosquitto/certs/*.crt
    chmod 600 mosquitto/certs/*.key
    
    echo -e "${GREEN}✅ Certificados SSL gerados${NC}"
    echo -e "${YELLOW}⚠️  Para produção, use certificados válidos (Let's Encrypt)${NC}"
else
    echo -e "${GREEN}✅ Certificados SSL encontrados${NC}"
fi
echo ""

# Atualizar configuração do Mosquitto para usar SSL
echo "[5/6] Configurando Mosquitto para SSL..."

if ! grep -q "listener 8883" mosquitto/config/mosquitto.conf 2>/dev/null; then
    print_warning "Adicionando configuração SSL ao mosquitto.conf"
    cat >> mosquitto/config/mosquitto.conf <<EOF

# =============================================================================
# SSL/TLS Configuration (Adicionado automaticamente por deploy.sh)
# =============================================================================
listener 8883
protocol mqtt
cafile /mosquitto/certs/ca.crt
certfile /mosquitto/certs/server.crt
keyfile /mosquitto/certs/server.key
require_certificate false
allow_anonymous false
password_file /mosquitto/config/passwd
EOF
    print_success "Configuração SSL adicionada"
else
    print_success "Mosquitto já configurado para SSL"
fi
echo ""

# Corrigir permissões
echo "[6/6] Corrigindo permissões dos diretórios..."

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

# Mosquitto precisa de UID 1883
configure_permissions "mosquitto/config" "1883" "1883"
configure_permissions "mosquitto/data" "1883" "1883"
configure_permissions "mosquitto/log" "1883" "1883"
configure_permissions "mosquitto/certs" "1883" "1883"

# Certificados com permissões especiais
if [ -d "mosquitto/certs" ]; then
    chmod 600 mosquitto/certs/*.key 2>/dev/null || true
    chmod 644 mosquitto/certs/*.crt 2>/dev/null || true
fi

# InfluxDB precisa de UID 1000
configure_permissions "influxdb" "1000" "1000"

# Grafana precisa de UID 472
if [ -d "grafana" ]; then
    configure_permissions "grafana" "472" "472"
fi

print_success "Permissões configuradas"
echo ""

# Iniciar em modo produção
echo "[7/7] Iniciando containers em modo PRODUÇÃO..."
echo ""
docker compose -f docker-compose.yml -f docker-compose.prod.yml up -d
echo ""
print_success "Containers iniciados"
echo ""

# Aguardar serviços ficarem prontos
echo "[8/8] Aguardando serviços ficarem prontos..."
sleep 5

# Verificar status
echo ""
echo "========================================="
echo "Status dos Serviços:"
echo "========================================="
docker compose ps
echo ""

# Informações de acesso
echo "========================================="
echo "🎉 Deploy Concluído!"
echo "========================================="
echo ""
echo "📊 Grafana:"
echo "   Local:  http://localhost (via Nginx)"
echo "   VPS:    https://grafana.seudominio.com (após configurar DNS)"
echo ""
echo "🔌 MQTT Broker (SSL):"
echo "   Porta:  8883"
echo "   Protocolo: MQTTS"
echo ""
echo "📈 InfluxDB:"
echo "   Acesso via SSH tunnel:"
echo "   ssh -L 8086:localhost:8086 usuario@sua-vps"
echo ""
echo "🔐 Credenciais:"
echo "   Todas as senhas estão no arquivo .env"
echo ""
echo "⚠️  PRÓXIMOS PASSOS:"
echo "   1. Configure o firewall: bash scripts/setup_firewall.sh"
echo "   2. Configure SSL (Let's Encrypt): bash scripts/setup_ssl.sh"
echo "   3. Atualize o domínio em nginx/conf.d/default.conf"
echo ""
