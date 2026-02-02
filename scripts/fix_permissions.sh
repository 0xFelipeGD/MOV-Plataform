#!/bin/bash
set -e

echo "=== Corrigindo permissões dos diretórios dos containers ==="

# Mosquitto (UID:GID 1883:1883)
echo "Configurando permissões do Mosquitto..."
sudo chown -R 1883:1883 mosquitto/config mosquitto/data mosquitto/log
sudo chmod -R 755 mosquitto/config mosquitto/data mosquitto/log

# InfluxDB (UID:GID 1000:1000)
echo "Configurando permissões do InfluxDB..."
sudo chown -R 1000:1000 influxdb/config
sudo chmod -R 755 influxdb/config

echo "✓ Permissões corrigidas com sucesso!"
