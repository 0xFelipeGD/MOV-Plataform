#!/bin/bash
# MOV Platform - Configuração de SSL com Let's Encrypt e renovação MQTT
# Uso: sudo bash scripts/setup_ssl.sh seudominio.com

set -e

echo "========================================="
echo "MOV Platform - Configuração SSL (Certbot + MQTT)"
echo "========================================="
echo ""

# Verificar argumento
if [ -z "$1" ]; then
    echo "❌ Uso: sudo bash scripts/setup_ssl.sh seudominio.com"
    echo ""
    echo "Exemplo:"
    echo "  sudo bash scripts/setup_ssl.sh grafana.exemplo.com"
    echo ""
    exit 1
fi

DOMAIN=$1

# Verificar se é root
if [ "$EUID" -ne 0 ]; then 
    echo "❌ Este script precisa ser executado como root (sudo)"
    exit 1
fi

# Instalar Certbot
echo "[1/4] Verificando/Instalando Certbot..."
if ! command -v certbot &> /dev/null; then
    apt-get update
    apt-get install -y certbot
    echo "✅ Certbot instalado"
else
    echo "✅ Certbot já instalado"
fi
echo ""

# Verificar DNS
echo "[2/4] Verificando DNS do domínio..."
echo "Domínio: $DOMAIN"
echo ""
echo "⚠️  Certifique-se que o DNS está apontando para este servidor!"
read -p "Pressione ENTER para continuar ou CTRL+C para cancelar..."
echo ""

# Parar Nginx temporariamente
echo "[3/4] Parando Nginx temporariamente..."
docker compose -f docker-compose.yml -f docker-compose.prod.yml stop nginx
echo "✅ Nginx parado"
echo ""

# Gerar certificado
echo "[4/4] Gerando certificado SSL..."
certbot certonly --standalone \
    -d $DOMAIN \
    --preferred-challenges http

# Copiar certificados para pasta do projeto
echo ""
echo "Copiando certificados..."
mkdir -p nginx/ssl
cp /etc/letsencrypt/live/$DOMAIN/fullchain.pem nginx/ssl/
cp /etc/letsencrypt/live/$DOMAIN/privkey.pem nginx/ssl/
chmod 644 nginx/ssl/fullchain.pem
chmod 600 nginx/ssl/privkey.pem
echo "✅ Certificados copiados"
echo ""

# Atualizar configuração do Nginx
echo "Atualizando nginx/conf.d/default.conf..."

# Fazer backup
cp nginx/conf.d/default.conf nginx/conf.d/default.conf.bak

# Descomentar bloco de redirecionamento HTTP -> HTTPS
sed -i 's/^# # Redireciona HTTP para HTTPS/# Redireciona HTTP para HTTPS/' nginx/conf.d/default.conf
sed -i '/^# # Redireciona/,/^# }/ { /^# server {/,/^# }/ { s/^# //; s/grafana\.seudominio\.com/'"$DOMAIN"'/g; } }' nginx/conf.d/default.conf

# Descomentar bloco HTTPS
sed -i '/^# # Grafana - HTTPS/,/^# }$/ { s/^# //; s/grafana\.seudominio\.com/'"$DOMAIN"'/g; }' nginx/conf.d/default.conf

echo "✓ Configuração atualizada (backup salvo)"
echo ""

# Reiniciar Nginx
echo "Reiniciando Nginx..."
docker compose -f docker-compose.yml -f docker-compose.prod.yml up -d nginx
echo "✅ Nginx reiniciado"
echo ""

# Configurar renovação automática de certificados HTTPS e MQTT
echo "Configurando renovação automática..."

# Hook para recarregar nginx após renovação
HOOK_SCRIPT="/etc/letsencrypt/renewal-hooks/deploy/reload-nginx.sh"
mkdir -p /etc/letsencrypt/renewal-hooks/deploy

cat > "$HOOK_SCRIPT" <<'EOF'
#!/bin/bash
# Hook de renovação: copia certificados e reinicia Nginx

PROJECT_DIR="/home/$(logname)/Desktop/MOV-Plataform"

if [ -d "$PROJECT_DIR/nginx/ssl" ]; then
    cp /etc/letsencrypt/live/*/fullchain.pem "$PROJECT_DIR/nginx/ssl/"
    cp /etc/letsencrypt/live/*/privkey.pem "$PROJECT_DIR/nginx/ssl/"
    chmod 644 "$PROJECT_DIR/nginx/ssl/fullchain.pem"
    chmod 600 "$PROJECT_DIR/nginx/ssl/privkey.pem"
    
    cd "$PROJECT_DIR"
    docker compose restart nginx
fi
EOF

chmod +x "$HOOK_SCRIPT"
echo "✓ Hook de renovação HTTPS criado"

# Script de renovação de certificados MQTT
cat > /usr/local/bin/renew_mqtt_certs.sh <<'MQTT_SCRIPT'
#!/bin/bash
# Script de Renovação Automática de Certificados MQTT
# Executado automaticamente pelo cron

set -e

PROJECT_DIR="/home/$(logname)/MOV-Plataform"
CERT_DIR="$PROJECT_DIR/mosquitto/certs"
LOG_FILE="/var/log/mqtt_cert_renewal.log"

echo "[$(date)] Iniciando renovação de certificados MQTT..." >> $LOG_FILE

# Verificar validade do certificado atual
if [ -f "$CERT_DIR/server.crt" ]; then
    EXPIRY_DATE=$(openssl x509 -enddate -noout -in "$CERT_DIR/server.crt" | cut -d= -f2)
    EXPIRY_EPOCH=$(date -d "$EXPIRY_DATE" +%s)
    CURRENT_EPOCH=$(date +%s)
    DAYS_LEFT=$(( ($EXPIRY_EPOCH - $CURRENT_EPOCH) / 86400 ))
    
    echo "[$(date)] Dias restantes do certificado: $DAYS_LEFT" >> $LOG_FILE
    
    # Renovar se faltarem menos de 30 dias
    if [ $DAYS_LEFT -lt 30 ]; then
        echo "[$(date)] Certificado expira em menos de 30 dias. Renovando..." >> $LOG_FILE
        
        # Gerar novos certificados
        cd "$CERT_DIR"
        
        # Backup dos certificados antigos
        mkdir -p backup_$(date +%Y%m%d)
        cp *.crt *.key backup_$(date +%Y%m%d)/ 2>/dev/null || true
        
        # Gerar nova CA
        openssl req -new -x509 -days 365 -extensions v3_ca \
            -keyout ca.key \
            -out ca.crt \
            -subj "/CN=MOV-CA" \
            -nodes 2>/dev/null
        
        # Gerar nova chave do servidor
        openssl genrsa -out server.key 2048 2>/dev/null
        
        # Gerar requisição de assinatura
        openssl req -new \
            -key server.key \
            -out server.csr \
            -subj "/CN=mov-broker" 2>/dev/null
        
        # Assinar certificado
        openssl x509 -req -in server.csr \
            -CA ca.crt \
            -CAkey ca.key \
            -CAcreateserial \
            -out server.crt \
            -days 365 2>/dev/null
        
        # Permissões corretas
        chmod 644 *.crt
        chmod 600 *.key
        
        echo "[$(date)] Certificados renovados com sucesso!" >> $LOG_FILE
        
        # Reiniciar Mosquitto
        cd "$PROJECT_DIR"
        docker compose restart mosquitto >> $LOG_FILE 2>&1
        
        echo "[$(date)] Mosquitto reiniciado" >> $LOG_FILE
    else
        echo "[$(date)] Certificado ainda válido. Nenhuma ação necessária." >> $LOG_FILE
    fi
else
    echo "[$(date)] ERRO: Certificado não encontrado em $CERT_DIR/server.crt" >> $LOG_FILE
    exit 1
fi

echo "[$(date)] Renovação de certificados MQTT concluída." >> $LOG_FILE
MQTT_SCRIPT

chmod +x /usr/local/bin/renew_mqtt_certs.sh
echo "✓ Script de renovação MQTT criado"

# Adicionar cron jobs para renovação automática
(crontab -l 2>/dev/null | grep -v "certbot renew" | grep -v "renew_mqtt_certs.sh"; \
 echo "# Renovação automática de certificados HTTPS - 3h da manhã"; \
 echo "0 3 * * * certbot renew --quiet"; \
 echo ""; \
 echo "# Renovação automática de certificados MQTT - 4h da manhã"; \
 echo "0 4 * * * /usr/local/bin/renew_mqtt_certs.sh") | crontab -

echo "✓ Renovação automática configurada"
echo "   - HTTPS: 3h da manhã (diária)"
echo "   - MQTT: 4h da manhã (verifica e renova se < 30 dias)"
echo ""

echo "========================================="
echo "✅ SSL Configurado com Sucesso!"
echo "========================================="
echo ""
echo "🌐 HTTPS (Nginx/Grafana):"
echo "   URL: https://$DOMAIN"
echo "   Certificados: nginx/ssl/*.pem"
echo "   Renovação: Automática (Let's Encrypt)"
echo ""
echo "🔐 MQTT SSL:"
echo "   Porta: 8883"
echo "   Certificados: mosquitto/certs/*.crt"
echo "   Renovação: Automática (quando < 30 dias)"
echo "   Log: /var/log/mqtt_cert_renewal.log"
echo ""
echo "🔄 Renovação automática configurada:"
echo "   - Certificados HTTPS: verificação diária às 3h"
echo "   - Certificados MQTT: verificação diária às 4h"
echo "   - MQTT renovado automaticamente se expirar em < 30 dias"
echo ""
echo "📋 Para verificar status dos certificados MQTT:"
echo "   openssl x509 -enddate -noout -in mosquitto/certs/server.crt"
echo ""
echo "📋 Para forçar renovação MQTT manualmente:"
echo "   sudo /usr/local/bin/renew_mqtt_certs.sh"
echo ""
