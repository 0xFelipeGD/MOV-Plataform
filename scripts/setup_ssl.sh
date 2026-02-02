#!/bin/bash
# MOV Platform - Configuração de SSL com Let's Encrypt
# Uso: sudo bash scripts/setup_ssl.sh seudominio.com

set -e

echo "========================================="
echo "MOV Platform - Configuração SSL (Certbot)"
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
    --non-interactive \
    --agree-tos \
    --email admin@$DOMAIN \
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
sed -i "s/# server_name grafana.seudominio.com/server_name $DOMAIN/" nginx/conf.d/default.conf
echo "✅ Configuração atualizada"
echo ""

# Reiniciar Nginx
echo "Reiniciando Nginx..."
docker compose -f docker-compose.yml -f docker-compose.prod.yml up -d nginx
echo "✅ Nginx reiniciado"
echo ""

# Configurar renovação automática
echo "Configurando renovação automática..."
(crontab -l 2>/dev/null; echo "0 3 * * * certbot renew --quiet --deploy-hook 'docker compose -f $PWD/docker-compose.yml -f $PWD/docker-compose.prod.yml restart nginx'") | crontab -
echo "✅ Renovação automática configurada (3h da manhã)"
echo ""

echo "========================================="
echo "✅ SSL Configurado com Sucesso!"
echo "========================================="
echo ""
echo "🌐 Seu site agora está disponível em:"
echo "   https://$DOMAIN"
echo ""
echo "📋 Certificados em:"
echo "   nginx/ssl/fullchain.pem"
echo "   nginx/ssl/privkey.pem"
echo ""
echo "🔄 Renovação automática:"
echo "   Certificados serão renovados automaticamente"
echo "   Verificação diária às 3h da manhã"
echo ""
