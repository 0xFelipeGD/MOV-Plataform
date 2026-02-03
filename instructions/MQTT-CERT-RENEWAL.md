# 🔐 Renovação Automática de Certificados MQTT

## 📋 Visão Geral

A MOV Platform implementa renovação automática de certificados SSL/TLS para o broker MQTT (Mosquitto), garantindo que os certificados sejam renovados antes de expirarem.

## ⚙️ Como Funciona

### Configuração Inicial

Quando você executa o script `setup_ssl.sh`, além de configurar certificados HTTPS com Let's Encrypt, o sistema também configura a renovação automática de certificados MQTT:

```bash
sudo bash scripts/setup_ssl.sh seudominio.com
```

Este comando:

1. Configura certificados HTTPS (Let's Encrypt) para Nginx/Grafana
2. **Cria script de renovação automática de certificados MQTT**
3. Configura tarefas cron para renovação automática de ambos

### Script de Renovação

O script `/usr/local/bin/renew_mqtt_certs.sh` é criado automaticamente e executa:

1. **Verifica validade** do certificado MQTT atual
2. **Calcula dias restantes** até expiração
3. **Renova automaticamente** se faltarem menos de 30 dias
4. **Faz backup** dos certificados antigos
5. **Reinicia Mosquitto** após renovação
6. **Registra tudo** em log

### Agendamento (Cron)

Duas tarefas são configuradas automaticamente:

```bash
# Renovação HTTPS (Let's Encrypt) - 3h da manhã
0 3 * * * certbot renew --quiet --deploy-hook 'docker compose restart nginx'

# Renovação MQTT - 4h da manhã
0 4 * * * /usr/local/bin/renew_mqtt_certs.sh
```

## 🔍 Verificação e Monitoramento

### Verificar Validade do Certificado Atual

```bash
openssl x509 -enddate -noout -in mosquitto/certs/server.crt
```

**Saída esperada:**

```
notAfter=Feb  3 12:34:56 2027 GMT
```

### Verificar Dias Restantes

```bash
echo "Dias restantes: $(( ($(date -d "$(openssl x509 -enddate -noout -in mosquitto/certs/server.crt | cut -d= -f2)" +%s) - $(date +%s)) / 86400 ))"
```

### Verificar Logs de Renovação

```bash
sudo tail -f /var/log/mqtt_cert_renewal.log
```

**Exemplo de log:**

```
[Mon Feb  3 04:00:01 UTC 2026] Iniciando renovação de certificados MQTT...
[Mon Feb  3 04:00:01 UTC 2026] Dias restantes do certificado: 28
[Mon Feb  3 04:00:01 UTC 2026] Certificado expira em menos de 30 dias. Renovando...
[Mon Feb  3 04:00:03 UTC 2026] Certificados renovados com sucesso!
[Mon Feb  3 04:00:05 UTC 2026] Mosquitto reiniciado
[Mon Feb  3 04:00:05 UTC 2026] Renovação de certificados MQTT concluída.
```

### Verificar Tarefas Cron

```bash
crontab -l | grep mqtt
```

## 🔧 Operações Manuais

### Forçar Renovação Imediata

Se precisar renovar os certificados manualmente (sem esperar 30 dias):

```bash
sudo /usr/local/bin/renew_mqtt_certs.sh
```

### Renovar Certificados Manualmente (Passo a Passo)

```bash
# 1. Entre na pasta de certificados
cd mosquitto/certs/

# 2. Backup dos certificados atuais
mkdir -p backup_manual_$(date +%Y%m%d)
cp *.crt *.key backup_manual_$(date +%Y%m%d)/

# 3. Gerar nova CA
openssl req -new -x509 -days 365 -extensions v3_ca \
    -keyout ca.key \
    -out ca.crt \
    -subj "/CN=MOV-CA" \
    -nodes

# 4. Gerar nova chave do servidor
openssl genrsa -out server.key 2048

# 5. Gerar requisição de assinatura
openssl req -new \
    -key server.key \
    -out server.csr \
    -subj "/CN=mov-broker"

# 6. Assinar certificado
openssl x509 -req -in server.csr \
    -CA ca.crt \
    -CAkey ca.key \
    -CAcreateserial \
    -out server.crt \
    -days 365

# 7. Permissões corretas
chmod 644 *.crt
chmod 600 *.key

# 8. Reiniciar Mosquitto
cd ../..
docker compose restart mosquitto

# 9. Verificar
docker compose logs mosquitto | tail -20
```

### Desabilitar Renovação Automática

Se por algum motivo precisar desabilitar:

```bash
# Remover tarefa do cron
crontab -l | grep -v "renew_mqtt_certs.sh" | crontab -

# Verificar
crontab -l
```

## 📂 Estrutura de Arquivos

```
MOV-Plataform/
├── mosquitto/
│   └── certs/
│       ├── ca.crt                    # Certificado da Autoridade Certificadora
│       ├── ca.key                    # Chave privada da CA
│       ├── server.crt                # Certificado do servidor MQTT
│       ├── server.key                # Chave privada do servidor
│       └── backup_YYYYMMDD/          # Backups automáticos de certificados
│           ├── ca.crt
│           ├── ca.key
│           ├── server.crt
│           └── server.key
└── scripts/
    └── setup_ssl.sh                  # Script que configura renovação automática
```

## 🔒 Segurança

### Validade dos Certificados

- **Certificados MQTT:** 365 dias
- **Renovação automática:** Quando faltarem menos de 30 dias
- **Margem de segurança:** 30 dias antes da expiração

### Permissões

```bash
# Verificar permissões dos certificados
ls -l mosquitto/certs/

# Saída esperada:
# -rw-r--r-- 1 root root 1234 Feb  3 12:00 ca.crt
# -rw------- 1 root root 1675 Feb  3 12:00 ca.key
# -rw-r--r-- 1 root root 1234 Feb  3 12:00 server.crt
# -rw------- 1 root root 1675 Feb  3 12:00 server.key
```

### Backup Automático

Antes de cada renovação, o sistema cria backup em:

```
mosquitto/certs/backup_YYYYMMDD/
```

## ⚠️ Troubleshooting

### Erro: "Certificado não encontrado"

**Sintoma:**

```
[Tue Feb  3 04:00:01 UTC 2026] ERRO: Certificado não encontrado em .../server.crt
```

**Solução:**

```bash
# Execute o deploy novamente para gerar certificados
bash scripts/deploy.sh
```

### Erro: "Permissão negada"

**Sintoma:**

```
chmod: cannot access '*.key': Permission denied
```

**Solução:**

```bash
# Execute o script de renovação com sudo
sudo /usr/local/bin/renew_mqtt_certs.sh
```

### Mosquitto não reinicia após renovação

**Verificar:**

```bash
# Ver logs do Mosquitto
docker compose logs mosquitto

# Verificar se container está rodando
docker compose ps mosquitto

# Reiniciar manualmente se necessário
docker compose restart mosquitto
```

### Certificados renovados mas clientes não conectam

**Motivo:** Clientes podem estar usando o certificado CA antigo

**Solução:**

1. Clientes precisam atualizar o arquivo `ca.crt`
2. Baixar novo certificado:

   ```bash
   # No servidor
   cat mosquitto/certs/ca.crt

   # Copiar conteúdo e atualizar nos clientes (ESP32, Node-RED, etc.)
   ```

## 📊 Monitoramento em Produção

### Alertas Recomendados

Configure alertas para:

- Certificados expirando em menos de 15 dias
- Falha na renovação automática
- Logs de erro em `/var/log/mqtt_cert_renewal.log`

### Script de Verificação

Criar script de monitoramento:

```bash
#!/bin/bash
# check_mqtt_certs.sh

CERT_FILE="mosquitto/certs/server.crt"
WARN_DAYS=15

if [ ! -f "$CERT_FILE" ]; then
    echo "CRITICAL: Certificado não encontrado!"
    exit 2
fi

EXPIRY_DATE=$(openssl x509 -enddate -noout -in "$CERT_FILE" | cut -d= -f2)
EXPIRY_EPOCH=$(date -d "$EXPIRY_DATE" +%s)
CURRENT_EPOCH=$(date +%s)
DAYS_LEFT=$(( ($EXPIRY_EPOCH - $CURRENT_EPOCH) / 86400 ))

if [ $DAYS_LEFT -lt 0 ]; then
    echo "CRITICAL: Certificado expirou há $((DAYS_LEFT * -1)) dias!"
    exit 2
elif [ $DAYS_LEFT -lt $WARN_DAYS ]; then
    echo "WARNING: Certificado expira em $DAYS_LEFT dias!"
    exit 1
else
    echo "OK: Certificado válido por $DAYS_LEFT dias"
    exit 0
fi
```

## 🎯 Melhorias Futuras

Para ambientes de produção críticos, considere:

1. **Certificados de CA Confiável**
   - Usar Let's Encrypt também para MQTT (requer DNS)
   - Certificados comerciais para máxima compatibilidade

2. **Monitoramento Centralizado**
   - Integrar com Prometheus/Grafana
   - Alertas via Slack/Email/Telegram

3. **Redundância**
   - Backup remoto de certificados (S3, etc.)
   - Múltiplos brokers MQTT com failover

## 📚 Referências

- [Mosquitto TLS Configuration](https://mosquitto.org/man/mosquitto-tls-7.html)
- [OpenSSL Documentation](https://www.openssl.org/docs/)
- [Let's Encrypt Best Practices](https://letsencrypt.org/docs/integration-guide/)

---

**Última atualização:** 03/02/2026  
**Versão:** 1.0  
**Autor:** GitHub Copilot
