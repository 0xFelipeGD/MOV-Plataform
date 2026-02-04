#!/bin/bash

# Script para visualizar logs dos containers Docker
# Uso: ./logs.sh [container] [opções]

set -e

# Cores para output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Diretório do projeto
PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$PROJECT_DIR"

# Função para mostrar uso
show_usage() {
    echo -e "${BLUE}=== Visualizador de Logs - MOV Platform ===${NC}"
    echo ""
    echo "Uso: ./logs.sh [container] [opções]"
    echo ""
    echo "Containers disponíveis:"
    echo "  all          - Todos os containers"
    echo "  mosquitto    - Broker MQTT"
    echo "  influxdb     - Banco de dados de séries temporais"
    echo "  telegraf     - Agente de coleta de métricas"
    echo "  grafana      - Dashboard de visualização"
    echo "  analytics    - Serviço de analytics"
    echo "  nginx        - Servidor web/proxy reverso"
    echo ""
    echo "Opções:"
    echo "  -f, --follow    - Seguir logs em tempo real (padrão)"
    echo "  -n, --lines N   - Mostrar últimas N linhas (padrão: 100)"
    echo "  --no-follow     - Mostrar logs sem seguir"
    echo "  -t, --tail      - Apenas seguir novos logs"
    echo ""
    echo "Exemplos:"
    echo "  ./logs.sh mosquitto           # Logs do Mosquitto em tempo real"
    echo "  ./logs.sh all -n 50           # Últimas 50 linhas de todos"
    echo "  ./logs.sh influxdb --no-follow # Logs do InfluxDB sem seguir"
    echo "  ./logs.sh                     # Menu interativo"
}

# Função para verificar se docker-compose está rodando
check_running() {
    if ! docker compose ps --quiet 2>/dev/null | grep -q .; then
        echo -e "${YELLOW}Aviso: Nenhum container está rodando${NC}"
        echo "Execute: docker compose up -d"
        exit 1
    fi
}

# Função para listar containers rodando
list_containers() {
    echo -e "${GREEN}Containers rodando:${NC}"
    docker compose ps --format "table {{.Name}}\t{{.Status}}\t{{.Ports}}"
    echo ""
}

# Função para menu interativo
interactive_menu() {
    echo -e "${BLUE}=== Visualizador de Logs - MOV Platform ===${NC}"
    echo ""
    list_containers
    echo "Selecione o container para ver logs:"
    echo "  1) Todos os containers"
    echo "  2) Mosquitto (MQTT)"
    echo "  3) InfluxDB"
    echo "  4) Telegraf"
    echo "  5) Grafana"
    echo "  6) Analytics"
    echo "  7) Nginx"
    echo "  0) Sair"
    echo ""
    read -p "Escolha [1-7]: " choice
    
    case $choice in
        1) CONTAINER="all" ;;
        2) CONTAINER="mosquitto" ;;
        3) CONTAINER="influxdb" ;;
        4) CONTAINER="telegraf" ;;
        5) CONTAINER="grafana" ;;
        6) CONTAINER="analytics" ;;
        7) CONTAINER="nginx" ;;
        0) exit 0 ;;
        *) echo "Opção inválida"; exit 1 ;;
    esac
    
    echo ""
    read -p "Seguir logs em tempo real? [S/n]: " follow
    if [[ $follow =~ ^[Nn] ]]; then
        FOLLOW_MODE="--no-follow"
    else
        FOLLOW_MODE="--follow"
    fi
    
    read -p "Quantas linhas mostrar inicialmente? [100]: " lines
    LINES=${lines:-100}
}

# Parsear argumentos
CONTAINER=""
FOLLOW_MODE="--follow"
LINES=100
TAIL_ONLY=false

if [ $# -eq 0 ]; then
    # Modo interativo
    check_running
    interactive_menu
else
    # Modo command-line
    CONTAINER=$1
    shift
    
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                show_usage
                exit 0
                ;;
            -f|--follow)
                FOLLOW_MODE="--follow"
                shift
                ;;
            --no-follow)
                FOLLOW_MODE="--no-follow"
                shift
                ;;
            -n|--lines)
                LINES=$2
                shift 2
                ;;
            -t|--tail)
                TAIL_ONLY=true
                shift
                ;;
            *)
                echo "Opção desconhecida: $1"
                show_usage
                exit 1
                ;;
        esac
    done
fi

# Verificar se containers estão rodando
check_running

# Montar comando docker compose logs
CMD="docker compose logs"

if [ "$FOLLOW_MODE" == "--follow" ]; then
    CMD="$CMD --follow"
fi

if [ "$TAIL_ONLY" == true ]; then
    CMD="$CMD --tail=0"
else
    CMD="$CMD --tail=$LINES"
fi

# Adicionar timestamps
CMD="$CMD --timestamps"

# Adicionar container(es)
if [ "$CONTAINER" == "all" ]; then
    echo -e "${GREEN}Mostrando logs de todos os containers...${NC}"
else
    echo -e "${GREEN}Mostrando logs do container: $CONTAINER${NC}"
    CMD="$CMD $CONTAINER"
fi

echo -e "${YELLOW}Pressione Ctrl+C para sair${NC}"
echo ""

# Executar comando
eval $CMD
