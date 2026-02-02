#!/bin/sh
set -e

# 1. Verifica se as variáveis existem
if [ -z "$MQTT_USER" ] || [ -z "$MQTT_PASSWORD" ]; then
    echo "ERRO: Variaveis MQTT_USER ou MQTT_PASSWORD nao definidas!"
    exit 1
fi

echo "--- Configurando Usuario MQTT: $MQTT_USER ---"

# 2. Cria o arquivo de senha (sobrescreve o antigo para garantir senha nova)
# O comando 'touch' garante que o arquivo existe antes de escrever
touch /mosquitto/config/passwd
mosquitto_passwd -b -c /mosquitto/config/passwd "$MQTT_USER" "$MQTT_PASSWORD"

# 3. Ajusta permissões (Vital para nao dar erro de 'World Readable')
chmod 0700 /mosquitto/config/passwd
chown mosquitto:mosquitto /mosquitto/config/passwd

echo "--- Senha configurada. Iniciando Mosquitto... ---"

# 4. Inicia o Mosquitto Oficial
exec /usr/sbin/mosquitto -c /mosquitto/config/mosquitto.conf