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
NC='\033[0m' # No Color

# Verificações iniciais
echo -e "${YELLOW}[1/7] Verificando pré-requisitos...${NC}"

if ! command -v docker &> /dev/null; then
    echo -e "${RED}❌ Docker não está instalado!${NC}"
    echo "Instale com: curl -fsSL https://get.docker.com | sh"
    exit 1
fi

if ! command -v docker compose &> /dev/null; then
    echo -e "${RED}❌ Docker Compose não está instalado!${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Docker e Docker Compose OK${NC}"
echo ""

# Verificar arquivo .env
echo -e "${YELLOW}[2/7] Verificando credenciais...${NC}"

if [ ! -f .env ]; then
    echo -e "${RED}❌ Arquivo .env não encontrado!${NC}"
    echo ""
    echo "Execute primeiro:"
    echo "  bash scripts/generate_credentials.sh > .env"
    echo ""
    exit 1
fi

echo -e "${GREEN}✅ Arquivo .env encontrado${NC}"
echo ""

# Parar containers existentes
echo -e "${YELLOW}[3/7] Parando containers antigos...${NC}"
docker compose down 2>/dev/null || true
echo -e "${GREEN}✅ Containers parados${NC}"
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
echo -e "${YELLOW}[5/7] Configurando Mosquitto para SSL...${NC}"

if ! grep -q "listener 8883" mosquitto/config/mosquitto.conf 2>/dev/null; then
    echo -e "${YELLOW}⚠️  Adicionando configuração SSL ao mosquitto.conf${NC}"
    cat >> mosquitto/config/mosquitto.conf <<EOF

# SSL/TLS Configuration
listener 8883
protocol mqtt
cafile /mosquitto/certs/ca.crt
certfile /mosquitto/certs/server.crt
keyfile /mosquitto/certs/server.key
require_certificate false
EOF
    echo -e "${GREEN}✅ Configuração SSL adicionada${NC}"
else
    echo -e "${GREEN}✅ Mosquitto já configurado para SSL${NC}"
fi
echo ""

# Iniciar em modo produção
echo -e "${YELLOW}[6/7] Iniciando containers em modo PRODUÇÃO...${NC}"
echo ""
docker compose -f docker-compose.yml -f docker-compose.prod.yml up -d
echo ""
echo -e "${GREEN}✅ Containers iniciados${NC}"
echo ""

# Aguardar serviços ficarem prontos
echo -e "${YELLOW}[7/7] Aguardando serviços ficarem prontos...${NC}"
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
