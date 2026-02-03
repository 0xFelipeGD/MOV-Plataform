#!/bin/bash
set -e

# ==============================================================================
# MOV Platform - Script de Correção de Permissões
# ==============================================================================
# Uso: ./scripts/fix_permissions.sh [diretório_projeto]
# Se não especificado, usa o diretório pai do script
# ==============================================================================

# Determinar diretório do projeto
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="${1:-$(dirname "$SCRIPT_DIR")}"

echo "=== MOV Platform - Corrigindo Permissões ==="
echo "Diretório do projeto: $PROJECT_DIR"
echo ""

# Função para corrigir permissões com verificação
fix_permissions() {
    local path="$1"
    local uid="$2"
    local gid="$3"
    local name="$4"
    
    if [ -d "$path" ]; then
        echo "Configurando permissões do $name..."
        sudo chown -R "$uid:$gid" "$path"
        sudo chmod -R 755 "$path"
        echo "✓ $name configurado ($uid:$gid)"
    else
        echo "⚠ Diretório $path não encontrado, criando..."
        mkdir -p "$path"
        sudo chown -R "$uid:$gid" "$path"
        sudo chmod -R 755 "$path"
        echo "✓ $name criado e configurado ($uid:$gid)"
    fi
}

# Mosquitto (UID:GID 1883:1883)
fix_permissions "$PROJECT_DIR/mosquitto/config" "1883" "1883" "Mosquitto config"
fix_permissions "$PROJECT_DIR/mosquitto/data" "1883" "1883" "Mosquitto data"
fix_permissions "$PROJECT_DIR/mosquitto/log" "1883" "1883" "Mosquitto log"

# InfluxDB (UID:GID 1000:1000)
fix_permissions "$PROJECT_DIR/influxdb/config" "1000" "1000" "InfluxDB config"

echo ""
echo "✓ Todas as permissões foram corrigidas com sucesso!"
