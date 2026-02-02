#!/bin/bash
set -e

echo "=========================================="
echo "   MOV Platform - Setup Inicial"
echo "=========================================="
echo ""

# Cores para output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Função para printar mensagens coloridas
print_success() {
    echo -e "${GREEN}✓${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

print_error() {
    echo -e "${RED}✗${NC} $1"
}

# 1. Verificar se o arquivo .env existe
echo "1. Verificando arquivo .env..."
if [ ! -f .env ]; then
    print_warning "Arquivo .env não encontrado. Gerando credenciais..."
    if [ -f scripts/generate_credentials.sh ]; then
        chmod +x scripts/generate_credentials.sh
        ./scripts/generate_credentials.sh > .env
        print_success "Arquivo .env criado com credenciais geradas"
    else
        print_error "Script generate_credentials.sh não encontrado!"
        echo "Copie o .env.example e preencha manualmente:"
        echo "  cp .env.example .env"
        exit 1
    fi
else
    print_success "Arquivo .env já existe"
fi

# 2. Criar estrutura de diretórios necessária
echo ""
echo "2. Criando estrutura de diretórios..."

# Mosquitto
mkdir -p mosquitto/config mosquitto/data mosquitto/log
print_success "Diretórios do Mosquitto criados"

# InfluxDB
mkdir -p influxdb/config
print_success "Diretórios do InfluxDB criados"

# Backups
mkdir -p backups
print_success "Diretório de backups criado"

# 3. Configurar permissões corretas (SEGURANÇA)
echo ""
echo "3. Configurando permissões de segurança..."

# Mosquitto (UID 1883:1883)
if command -v sudo &> /dev/null; then
    sudo chown -R 1883:1883 mosquitto/config mosquitto/data mosquitto/log 2>/dev/null || \
        print_warning "Não foi possível ajustar permissões (sudo requerido). Execute: sudo chown -R 1883:1883 mosquitto/"
    sudo chmod -R 755 mosquitto/config mosquitto/data mosquitto/log 2>/dev/null || true
    
    # InfluxDB (UID 1000:1000)
    sudo chown -R 1000:1000 influxdb/config 2>/dev/null || \
        print_warning "Não foi possível ajustar permissões (sudo requerido). Execute: sudo chown -R 1000:1000 influxdb/config"
    sudo chmod -R 755 influxdb/config 2>/dev/null || true
    
    print_success "Permissões de segurança configuradas (containers rodam como usuários não-root)"
else
    print_warning "sudo não disponível. Execute manualmente: sudo chown -R 1883:1883 mosquitto/ && sudo chown -R 1000:1000 influxdb/config"
fi

# 4. Garantir que o entrypoint do Mosquitto tem permissão de execução
echo ""
echo "4. Configurando permissões de scripts..."
chmod +x mosquitto/docker-entrypoint.sh 2>/dev/null || true
chmod +x scripts/*.sh 2>/dev/null || true
print_success "Permissões de execução configuradas"

# 5. Verificar se Docker está rodando
echo ""
echo "5. Verificando Docker..."
if ! docker info > /dev/null 2>&1; then
    print_error "Docker não está rodando ou não está instalado"
    echo "Inicie o Docker e tente novamente"
    exit 1
fi
print_success "Docker está rodando"

# 6. Verificar se Docker Compose está disponível
if ! command -v docker compose &> /dev/null && ! command -v docker-compose &> /dev/null; then
    print_error "Docker Compose não encontrado"
    exit 1
fi
print_success "Docker Compose disponível"

# 6. Informações finais
echo ""
echo "=========================================="
echo "   Setup Concluído com Sucesso!"
echo "=========================================="
echo ""
echo "Próximos passos:"
echo ""
echo "1. Revisar o arquivo .env (opcional):"
echo "   ${YELLOW}nano .env${NC}"
echo ""
echo "2. Iniciar a plataforma:"
echo "   ${GREEN}docker compose up -d${NC}"
echo ""
echo "3. Verificar status dos containers:"
echo "   ${GREEN}docker compose ps${NC}"
echo ""
echo "4. Acessar os serviços:"
echo "   - Grafana: http://localhost:3000"
echo "   - InfluxDB: http://localhost:8086"
echo "   - MQTT: localhost:1883"
echo ""
echo "Senhas e tokens estão no arquivo .env"
echo ""
