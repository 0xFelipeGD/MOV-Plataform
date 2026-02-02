#!/bin/bash
# MOV Platform - Configuração de Firewall (UFW)
# Uso: sudo bash scripts/setup_firewall.sh

set -e

echo "========================================="
echo "MOV Platform - Configuração de Firewall"
echo "========================================="
echo ""

# Verificar se é root
if [ "$EUID" -ne 0 ]; then 
    echo "❌ Este script precisa ser executado como root (sudo)"
    exit 1
fi

# Verificar se UFW está instalado
if ! command -v ufw &> /dev/null; then
    echo "UFW não instalado. Instalando..."
    apt-get update
    apt-get install -y ufw
fi

echo "Configurando regras do firewall..."
echo ""

# Reset UFW (cuidado em produção!)
echo "⚠️  Resetando configurações antigas..."
ufw --force reset

# Política padrão: bloqueia entrada, permite saída
ufw default deny incoming
ufw default allow outgoing

echo "✅ Política padrão configurada (deny incoming, allow outgoing)"
echo ""

# SSH - IMPORTANTE: Permitir antes de ativar!
echo "Permitindo SSH (porta 22)..."
ufw allow 22/tcp comment 'SSH'
echo "✅ SSH permitido"
echo ""

# HTTP/HTTPS - Nginx
echo "Permitindo HTTP/HTTPS (portas 80, 443)..."
ufw allow 80/tcp comment 'HTTP - Nginx'
ufw allow 443/tcp comment 'HTTPS - Nginx'
echo "✅ HTTP/HTTPS permitidos"
echo ""

# MQTT SSL
echo "Permitindo MQTT SSL (porta 8883)..."
ufw allow 8883/tcp comment 'MQTT SSL - IoT Devices'
echo "✅ MQTT SSL permitido"
echo ""

# Mostrar regras antes de ativar
echo "========================================="
echo "Regras configuradas:"
echo "========================================="
ufw show added
echo ""

# Ativar firewall
echo "⚠️  Ativando firewall..."
ufw --force enable

echo ""
echo "========================================="
echo "✅ Firewall configurado e ativado!"
echo "========================================="
echo ""
echo "📋 Resumo das portas ABERTAS:"
echo "   22   - SSH (administração)"
echo "   80   - HTTP (Nginx → Grafana)"
echo "   443  - HTTPS (Nginx → Grafana)"
echo "   8883 - MQTT SSL (dispositivos IoT)"
echo ""
echo "🔒 Portas FECHADAS (acesso interno/localhost):"
echo "   1883 - MQTT sem SSL"
echo "   3000 - Grafana direto"
echo "   8086 - InfluxDB direto"
echo ""
echo "Status atual:"
ufw status verbose
echo ""
