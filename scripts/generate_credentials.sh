#!/bin/bash
# MOV Platform - Gerador de Credenciais Seguras
# Uso: ./generate_credentials.sh > .env

set -e

echo "# =========================================="
echo "# MOV Platform - Credenciais de Produção"
echo "# Gerado em: $(date)"
echo "# MANTENHA ESTE ARQUIVO SEGURO!"
echo "# =========================================="
echo ""

echo "# MQTT Credentials"
MQTT_USER="admin_$(openssl rand -hex 4)"
MQTT_PASS=$(openssl rand -base64 32 | tr -d '\n')
echo "MQTT_USER=$MQTT_USER"
echo "MQTT_PASSWORD=$MQTT_PASS"
echo ""

echo "# InfluxDB Configuration"
INFLUX_PASS=$(openssl rand -base64 32 | tr -d '\n')
INFLUX_TOKEN=$(openssl rand -base64 64 | tr -d '\n')
echo "INFLUX_USER=admin_influx"
echo "INFLUX_PASSWORD=$INFLUX_PASS"
echo "INFLUX_ORG=mov_industria"
echo "INFLUX_BUCKET=mov_dados"
echo "INFLUX_TOKEN=$INFLUX_TOKEN"
echo ""

echo "# Grafana"
GRAFANA_PASS=$(openssl rand -base64 32 | tr -d '\n')
echo "GRAFANA_PASSWORD=$GRAFANA_PASS"
echo ""


echo "# =========================================="
echo "# SALVE ESTAS CREDENCIAIS EM LOCAL SEGURO!"
echo "# Recomendação: Use um gerenciador de senhas"
echo "# =========================================="

# Salvar resumo em arquivo separado (sem as senhas completas)
cat > .credentials_info.txt <<EOF
MOV Platform - Informações de Acesso
=====================================
Gerado em: $(date)

Usuários criados:
- MQTT: $MQTT_USER
- InfluxDB: admin_influx
- Grafana: admin

IMPORTANTE: As senhas estão no arquivo .env
NÃO compartilhe o arquivo .env

Para acessar os serviços:
- Grafana: https://seu-dominio.com:3000
  Usuário: admin
  Senha: [veja .env]

- InfluxDB: https://seu-dominio.com:8086
  Usuário: admin_influx
  Organização: mov_industria
  Bucket: mov_dados
  Token: [veja .env]

- MQTT: mqtts://seu-dominio.com:8883
  Usuário: $MQTT_USER
  Senha: [veja .env]
EOF

echo "" >&2
echo "✅ Arquivo .credentials_info.txt criado com informações básicas" >&2
echo "⚠️  Redirecione a saída deste script para .env:" >&2
echo "   ./scripts/generate_credentials.sh > .env" >&2