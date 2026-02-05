#!/bin/sh
set -e

# 1. Verifica se as variáveis existem
if [ -z "$MQTT_USER" ] || [ -z "$MQTT_PASSWORD" ]; then
    echo "ERRO: Variaveis MQTT_USER ou MQTT_PASSWORD nao definidas!"
    exit 1
fi

echo "--- Configurando Usuario MQTT: $MQTT_USER ---"

# 2. Cria o arquivo de senha (sobrescreve o antigo para garantir senha nova)
# Remove arquivo antigo se existir (resolve problema de permissão)
rm -f /mosquitto/config/passwd 2>/dev/null || true

# Cria novo arquivo de senha
mosquitto_passwd -b -c /mosquitto/config/passwd "$MQTT_USER" "$MQTT_PASSWORD"

# 3. Ajusta permissões (Vital para nao dar erro de 'World Readable')
chmod 0600 /mosquitto/config/passwd 2>/dev/null || echo "Não foi possível ajustar permissões (ok se já estiverem corretas)"

echo "--- Senha configurada. Iniciando Mosquitto... ---"

# 4. Inicia o Mosquitto Oficial
exec /usr/sbin/mosquitto -c /mosquitto/config/mosquitto.conf