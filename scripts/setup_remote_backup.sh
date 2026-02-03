#!/bin/bash
# MOV Platform - Backup Remoto GRATUITO (Google Drive/OneDrive/MEGA)
# Uso: bash scripts/setup_remote_backup.sh

set -e

echo "========================================="
echo "MOV Platform - Backup Remoto GRATUITO"
echo "========================================="
echo ""

# Cores
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# 1. Instalar Rclone
echo -e "${YELLOW}[1/4] Instalando Rclone...${NC}"
if ! command -v rclone &> /dev/null; then
    curl https://rclone.org/install.sh | sudo bash
    echo -e "${GREEN}✅ Rclone instalado${NC}"
else
    echo -e "${GREEN}✅ Rclone já instalado${NC}"
fi
echo ""

# 2. Escolher provedor
echo -e "${YELLOW}[2/4] Escolha o provedor GRATUITO:${NC}"
echo ""
echo "  1) Google Drive (15 GB grátis) ⭐ RECOMENDADO"
echo "  2) MEGA (20 GB grátis)"
echo "  3) OneDrive (5 GB grátis)"
echo "  4) Dropbox (2 GB grátis)"
echo ""
read -p "Opção [1-4]: " PROVIDER_CHOICE

case $PROVIDER_CHOICE in
    1)
        PROVIDER="drive"
        PROVIDER_NAME="Google Drive"
        ;;
    2)
        PROVIDER="mega"
        PROVIDER_NAME="MEGA"
        ;;
    3)
        PROVIDER="onedrive"
        PROVIDER_NAME="OneDrive"
        ;;
    4)
        PROVIDER="dropbox"
        PROVIDER_NAME="Dropbox"
        ;;
    *)
        echo -e "${RED}Opção inválida${NC}"
        exit 1
        ;;
esac

# 3. Perguntar sobre criptografia
echo ""
echo -e "${YELLOW}[3/4] Deseja criptografar os backups?${NC}"
echo ""
echo "ℹ️  Com criptografia:"
echo "   ✅ Google/MEGA não consegue ler seus dados"
echo "   ✅ Proteção contra vazamento de conta"
echo "   ⚠️  Precisa lembrar da senha (sem ela, perde os backups!)"
echo ""
echo "ℹ️  Sem criptografia:"
echo "   ⚠️  Provedor pode ver conteúdo dos arquivos"
echo "   ✅ Mais simples (não precisa senha extra)"
echo ""
read -p "Criptografar backups? [s/N]: " ENCRYPT

ENCRYPT_ENABLED=false
if [[ "$ENCRYPT" =~ ^[Ss]$ ]]; then
    ENCRYPT_ENABLED=true
fi

# 4. Configurar Rclone
echo ""
echo -e "${YELLOW}[4/4] Configurando $PROVIDER_NAME...${NC}"
echo ""
echo "📋 Instruções:"
echo "  1. Nome do remote: digite 'mov-drive'"
echo "  2. Tipo: escolha '$PROVIDER_NAME'"
echo "  3. Faça login na sua conta quando solicitado"
echo ""
read -p "Pressione ENTER para continuar..."

rclone config

# Verificar se configurou
if ! rclone listremotes | grep -q "mov-drive"; then
    echo -e "${RED}Remote 'mov-drive' não encontrado. Tente novamente.${NC}"
    exit 1
fi

echo ""
echo -e "${GREEN}✅ $PROVIDER_NAME configurado!${NC}"

# 5. Configurar criptografia se solicitado
REMOTE_NAME="mov-drive:MOV-Platform-Backups"
if [ "$ENCRYPT_ENABLED" = true ]; then
    echo ""
    echo -e "${YELLOW}Configurando criptografia...${NC}"
    echo ""
    
    # Verificar se .env existe e tem as senhas
    if [ -f "$HOME/MOV-Plataform/.env" ]; then
        echo "Carregando senhas de criptografia do arquivo .env..."
        source "$HOME/MOV-Plataform/.env"
        
        if [ -z "$BACKUP_CRYPT_PASSWORD" ] || [ -z "$BACKUP_CRYPT_SALT" ]; then
            echo -e "${RED}ERRO: Senhas de backup não encontradas no .env${NC}"
            echo "Execute: bash scripts/generate_credentials.sh > .env"
            exit 1
        fi
        
        CRYPT_PASS="$BACKUP_CRYPT_PASSWORD"
        CRYPT_PASS2="$BACKUP_CRYPT_SALT"
        echo -e "${GREEN}✅ Senhas carregadas do .env${NC}"
    else
        echo -e "${RED}ERRO: Arquivo .env não encontrado${NC}"
        echo "Execute primeiro: bash scripts/generate_credentials.sh > .env"
        exit 1
    fi
    
    # Criar configuração crypt
    rclone config create mov-backup crypt \
        remote "mov-drive:MOV-Platform-Backups" \
        filename_encryption standard \
        directory_name_encryption true \
        password "$(rclone obscure "$CRYPT_PASS")" \
        password2 "$(rclone obscure "$CRYPT_PASS2")"
    
    REMOTE_NAME="mov-backup:"
    echo ""
    echo -e "${GREEN}✅ Criptografia configurada!${NC}"
    echo -e "${YELLOW}⚠️  Senhas estão no arquivo .env - mantenha-o seguro!${NC}"
else
    # Criar alias simples
    rclone config create mov-backup alias remote "$REMOTE_NAME"
    REMOTE_NAME="mov-backup:"
fi

# 6. Criar script de backup
echo ""
echo "Criando script de backup automático..."

sudo tee /usr/local/bin/mov_remote_backup.sh > /dev/null <<SCRIPT
#!/bin/bash
# MOV Platform - Backup Remoto Automático

BACKUP_DIR="\$HOME/MOV-Plataform/backups"
REMOTE="$REMOTE_NAME"
LOG="/var/log/mov_remote_backup.log"

log() {
    echo "[\$(date '+%Y-%m-%d %H:%M:%S')] \$1" | tee -a "\$LOG"
}

log "========================================="
log "Iniciando backup remoto..."

# Verificar backups locais
if [ ! -d "\$BACKUP_DIR" ]; then
    log "ERRO: Pasta \$BACKUP_DIR não existe"
    exit 1
fi

BACKUP_COUNT=\$(ls -1 "\$BACKUP_DIR"/*.tar.gz 2>/dev/null | wc -l)
if [ "\$BACKUP_COUNT" -eq 0 ]; then
    log "AVISO: Nenhum backup local encontrado"
    log "Verifique se o container backup_job está rodando"
    exit 1
fi

# Sincronizar para nuvem
log "Enviando \$BACKUP_COUNT arquivos para $PROVIDER_NAME..."
if rclone sync "\$BACKUP_DIR" "\$REMOTE" \\
    --include "*.tar.gz" \\
    --progress \\
    --log-file="\$LOG" \\
    --log-level INFO; then
    log "✅ Backup enviado com sucesso!"
else
    log "❌ ERRO: Falha no envio"
    exit 1
fi

# Limpar backups remotos antigos (manter últimos 30 dias)
log "Limpando backups com mais de 30 dias..."
rclone delete "\$REMOTE" \\
    --min-age 30d \\
    --include "*.tar.gz" \\
    2>&1 | tee -a "\$LOG"

# Espaço usado
log ""
log "Espaço usado na nuvem:"
rclone size "\$REMOTE" 2>&1 | tee -a "\$LOG"

log ""
log "========================================="
log "Backup remoto concluído!"
log "========================================="
SCRIPT

sudo chmod +x /usr/local/bin/mov_remote_backup.sh

echo -e "${GREEN}✅ Script criado: /usr/local/bin/mov_remote_backup.sh${NC}"

# 7. Configurar cron
echo ""
echo "Configurando agendamento automático (2h da manhã)..."
(crontab -l 2>/dev/null | grep -v "mov_remote_backup"; \
 echo "# Backup remoto MOV Platform - 2h da manhã"; \
 echo "0 2 * * * /usr/local/bin/mov_remote_backup.sh") | crontab -

echo -e "${GREEN}✅ Cron configurado!${NC}"

# 8. Teste
echo ""
read -p "Executar backup teste agora? [s/N]: " TEST
if [[ "$TEST" =~ ^[Ss]$ ]]; then
    echo ""
    echo "Executando backup teste..."
    sudo /usr/local/bin/mov_remote_backup.sh
fi

# Resumo final
echo ""
echo "========================================="
echo "✅ Backup Remoto Configurado!"
echo "========================================="
echo ""
echo "📦 Provedor: $PROVIDER_NAME"
if [ "$ENCRYPT_ENABLED" = true ]; then
    echo "🔐 Criptografia: ATIVADA (senhas no arquivo .env)"
else
    echo "🔐 Criptografia: DESATIVADA"
fi
echo "📁 Destino: MOV-Platform-Backups/"
echo "⏰ Agendamento: 2h da manhã (diário)"
echo "🗄️  Retenção: 30 dias"
echo ""
echo "📊 Comandos úteis:"
echo ""
echo "  Ver backups na nuvem:"
echo "  └─ rclone ls mov-backup:"
echo ""
echo "  Executar backup manual:"
echo "  └─ sudo /usr/local/bin/mov_remote_backup.sh"
echo ""
echo "  Baixar backup específico:"
echo "  └─ rclone copy mov-backup:grafana_20260203.tar.gz ."
echo ""
echo "  Restaurar todos os backups:"
echo "  └─ rclone sync mov-backup: ./backups"
echo ""
echo "  Ver logs:"
echo "  └─ tail -f /var/log/mov_remote_backup.log"
echo ""
echo "  Ver espaço usado:"
echo "  └─ rclone about mov-drive:"
echo ""
if [ "$ENCRYPT_ENABLED" = true ]; then
    echo "🔐 SEGURANÇA:"
    echo "   ✅ Senhas de criptografia estão no arquivo .env"
    echo "   ✅ Mantenha o .env seguro (já está no .gitignore)"
    echo "   ✅ Google Drive não consegue ler seus backups"
    echo "   ✅ Em caso de perda, restaure o .env junto com o sistema"
    echo ""
fi
echo "🌐 Acesse $PROVIDER_NAME no navegador para ver os arquivos:"
if [ "$PROVIDER" = "drive" ]; then
    echo "   https://drive.google.com"
elif [ "$PROVIDER" = "mega" ]; then
    echo "   https://mega.nz"
elif [ "$PROVIDER" = "onedrive" ]; then
    echo "   https://onedrive.live.com"
elif [ "$PROVIDER" = "dropbox" ]; then
    echo "   https://dropbox.com"
fi
echo ""
