#!/bin/bash
# MOV Platform - Script de Atualização Rápida
# Uso: bash scripts/update.sh

set -e

echo "========================================="
echo "🔄 MOV Platform - Atualização Rápida"
echo "========================================="
echo ""

# Verificar se estamos no diretório correto
if [ ! -f "docker-compose.yml" ]; then
    echo "❌ Erro: Execute este script na raiz do projeto!"
    exit 1
fi

# Verificar mudanças locais não commitadas
if ! git diff-index --quiet HEAD -- 2>/dev/null; then
    echo "⚠️  ATENÇÃO: Você tem mudanças não commitadas!"
    echo ""
    git status --short
    echo ""
    read -p "Deseja continuar mesmo assim? (s/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Ss]$ ]]; then
        echo "Atualização cancelada."
        exit 1
    fi
fi

echo "[1/4] Puxando atualizações do Git..."
git pull
echo "✅ Git atualizado"
echo ""

echo "[2/4] Parando containers..."
docker compose -f docker-compose.yml -f docker-compose.prod.yml down
echo "✅ Containers parados"
echo ""

echo "[3/4] Reconstruindo e iniciando containers..."
docker compose -f docker-compose.yml -f docker-compose.prod.yml up -d --build
echo "✅ Containers iniciados"
echo ""

echo "[4/4] Aguardando serviços ficarem prontos..."
sleep 5

echo ""
echo "========================================="
echo "✅ Atualização Concluída!"
echo "========================================="
echo ""
echo "📊 Status dos Serviços:"
docker compose ps
echo ""
echo "📋 Para ver logs em tempo real:"
echo "   docker compose logs -f [serviço]"
echo ""
echo "Exemplos:"
echo "   docker compose logs -f analytics"
echo "   docker compose logs -f grafana"
echo "   docker compose logs -f mosquitto"
echo ""
