#!/bin/sh
# ==============================================================================
# MOV Platform - Script de Backup Automático
# ==============================================================================
# Este script é executado pelo container de backup.
# Realiza backup de Grafana e InfluxDB a cada 24 horas.
# Backups com mais de 7 dias são automaticamente removidos.
# ==============================================================================

# Configurações
BACKUP_INTERVAL=${BACKUP_INTERVAL:-86400}  # 24 horas em segundos
RETENTION_DAYS=${RETENTION_DAYS:-7}        # Dias de retenção

echo "=== MOV Platform - Serviço de Backup ==="
echo "Intervalo: ${BACKUP_INTERVAL}s | Retenção: ${RETENTION_DAYS} dias"
echo ""

while true; do
    DATE=$(date +%Y%m%d_%H%M%S)
    echo "--- Iniciando Backup [$DATE] ---"
    
    # Backup do Grafana
    echo "Compactando Grafana..."
    if tar czf /output/grafana_${DATE}.tar.gz -C /input/grafana . 2>/dev/null; then
        echo "✓ Grafana: backup concluído"
    else
        echo "⚠ Grafana: falha no backup (diretório pode estar vazio)"
    fi
    
    # Backup do InfluxDB
    echo "Compactando InfluxDB..."
    if tar czf /output/influxdb_${DATE}.tar.gz -C /input/influxdb . 2>/dev/null; then
        echo "✓ InfluxDB: backup concluído"
    else
        echo "⚠ InfluxDB: falha no backup (diretório pode estar vazio)"
    fi
    
    # Limpeza de backups antigos
    echo "Removendo backups com mais de ${RETENTION_DAYS} dias..."
    DELETED=$(find /output -name '*.tar.gz' -mtime +${RETENTION_DAYS} -delete -print | wc -l)
    echo "✓ ${DELETED} arquivo(s) antigo(s) removido(s)"
    
    # Mostrar espaço utilizado
    BACKUP_SIZE=$(du -sh /output 2>/dev/null | cut -f1)
    echo "Tamanho total dos backups: ${BACKUP_SIZE:-0}"
    
    echo "--- Backup Concluído! Dormindo por ${BACKUP_INTERVAL}s ---"
    echo ""
    
    sleep ${BACKUP_INTERVAL}
done
