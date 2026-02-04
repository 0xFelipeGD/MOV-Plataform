# 🧙 Setup Wizard - Guia de Uso

O **Setup Wizard** é um assistente interativo que simplifica a configuração inicial da MOV Platform, permitindo escolher exatamente o que você precisa.

## 🚀 Como Usar

### Execução

```bash
cd MOV-Plataform
bash scripts/setup_wizard.sh
```

ou simplesmente:

```bash
./scripts/setup_wizard.sh
```

## 📋 Fluxo do Wizard

### Etapa 1: Escolha do Ambiente

O wizard pergunta qual tipo de ambiente você está configurando:

#### 🖥️ **Desenvolvimento**

- Todas as portas expostas (localhost)
- Sem SSL/TLS
- Ideal para desenvolvimento local
- Acesso direto ao Grafana (3000), InfluxDB (8086), MQTT (1883)

#### 🔧 **Staging**

- Portas seletivas
- SSL opcional
- Ideal para testes de homologação

#### 🏭 **Produção**

- Apenas portas essenciais: 80, 443, 8883
- SSL obrigatório
- Firewall configurado
- Nginx como proxy reverso

### Etapa 2: Seleção de Componentes

Você pode escolher quais serviços instalar:

- **📊 Grafana** - Dashboards de visualização
- **💾 InfluxDB** - Banco de dados de séries temporais
- **🔌 Mosquitto** - Broker MQTT para dispositivos IoT
- **📡 Telegraf** - Coletor que liga MQTT ao InfluxDB
- **🤖 Analytics** - Processamento Python em tempo real
- **🌐 Nginx** - Proxy reverso com SSL
- **💾 Backup** - Sistema de backup automático

**Dica:** Pressione Enter para aceitar os padrões (recomendados)

### Etapa 3: Configurações Específicas

#### Em Produção:

- **Domínios:** Configure domínios para SSL (ex: `grafana.empresa.com`)
- Você pode pular e configurar depois

#### Se Analytics estiver habilitado:

- **Limite de temperatura:** Para alertas críticos (padrão: 30°C)
- **Intervalo de processamento:** Frequência de análise (padrão: 10s)

### Etapa 4: Resumo e Confirmação

O wizard mostra um resumo completo de tudo que será configurado. Você pode:

- ✅ Confirmar e continuar
- ❌ Cancelar e recomeçar

### Etapa 5: Execução Automática

O wizard executa automaticamente:

1. ✅ Geração de credenciais seguras
2. ✅ Criação de diretórios necessários
3. ✅ Configuração de permissões
4. ✅ Geração de docker-compose customizado
5. ✅ Criação de overrides para ambiente

## 📂 Arquivos Gerados

Após a execução, você terá:

```
MOV-Plataform/
├── .env                          # Credenciais geradas
├── .env.domains                  # Domínios (se configurou)
├── .setup_config                 # Configuração do wizard
├── docker-compose.override.yml   # Overrides de ambiente
├── mosquitto/
│   ├── config/
│   ├── data/
│   ├── log/
│   └── certs/
├── influxdb/
│   └── config/
├── nginx/
│   ├── conf.d/
│   └── ssl/
└── backups/
```

## 🎯 Exemplos de Uso

### Exemplo 1: Desenvolvimento Local Completo

```bash
bash scripts/setup_wizard.sh

# Escolhas:
# Ambiente: 1 (Desenvolvimento)
# Componentes: [Enter] para aceitar todos
# Resultado: Plataforma completa pronta para dev
```

Depois:

```bash
docker compose up -d
# Acesse: http://localhost:3000 (Grafana)
```

### Exemplo 2: Produção sem Analytics

```bash
bash scripts/setup_wizard.sh

# Escolhas:
# Ambiente: 3 (Produção)
# Grafana: Y
# InfluxDB: Y
# Mosquitto: Y
# Telegraf: Y
# Analytics: n  ← Desabilitar
# Nginx: Y (obrigatório)
# Backup: Y
# Domínio Grafana: grafana.minhaempresa.com
# Domínio MQTT: mqtt.minhaempresa.com
```

Depois:

```bash
bash scripts/deploy.sh
sudo bash scripts/setup_firewall.sh
sudo bash scripts/setup_ssl.sh grafana.minhaempresa.com
```

### Exemplo 3: Apenas Coleta de Dados (sem Grafana)

```bash
bash scripts/setup_wizard.sh

# Escolhas:
# Ambiente: 1 (Desenvolvimento)
# Grafana: n  ← Desabilitar
# InfluxDB: Y
# Mosquitto: Y
# Telegraf: Y
# Analytics: n
# Nginx: n
# Backup: Y
```

Útil para edge devices que apenas coletam e armazenam dados.

## 🔄 Executar Novamente

Se quiser reconfigurar, basta executar o wizard novamente:

```bash
bash scripts/setup_wizard.sh
```

**Nota:** O arquivo `.env` existente será mantido. Se quiser gerar novas credenciais, delete o `.env` antes:

```bash
rm .env
bash scripts/setup_wizard.sh
```

## ⚙️ Configurações Avançadas

### Customizar Componentes Manualmente

Após rodar o wizard, você pode editar manualmente:

**Arquivo `.setup_config`:**

```bash
ENVIRONMENT=production
INSTALL_GRAFANA=y
INSTALL_INFLUXDB=y
INSTALL_MOSQUITTO=y
INSTALL_TELEGRAF=y
INSTALL_ANALYTICS=n
INSTALL_NGINX=y
INSTALL_BACKUP=y
```

### Override para Desenvolvimento

O wizard cria automaticamente `docker-compose.override.yml` em modo desenvolvimento:

```yaml
# docker-compose.override.yml (auto-gerado)
services:
  influxdb:
    ports:
      - "8086:8086"
  grafana:
    ports:
      - "3000:3000"
```

Você pode editá-lo para adicionar outras customizações.

## 🐛 Troubleshooting

### "Script não encontrado"

```bash
# Verifique se está no diretório correto
cd MOV-Plataform
ls scripts/setup_wizard.sh

# Torne executável
chmod +x scripts/setup_wizard.sh
```

### "Permission denied" ao criar diretórios

```bash
# Execute com permissões adequadas
sudo bash scripts/setup_wizard.sh
```

### "generate_credentials.sh não encontrado"

```bash
# Verifique se o arquivo existe
ls scripts/generate_credentials.sh

# Torne executável
chmod +x scripts/generate_credentials.sh
```

### Quero começar do zero

```bash
# Remover configurações anteriores
rm -f .env .env.domains .setup_config docker-compose.override.yml

# Executar wizard novamente
bash scripts/setup_wizard.sh
```

## 🔒 Segurança

O wizard:

- ✅ Gera senhas fortes automaticamente (256-512 bits)
- ✅ Salva credenciais apenas em `.env` (não commitado)
- ✅ Configura permissões corretas para arquivos sensíveis
- ✅ Cria usuários não-root nos containers

**Importante:** Nunca commite o arquivo `.env` no Git!

## 📚 Próximos Passos

Após o wizard, siga o guia do ambiente escolhido:

### Desenvolvimento

1. `docker compose up -d`
2. Acesse http://localhost:3000
3. Veja [DEV-WORKFLOW.md](../instructions/DEV-WORKFLOW.md)

### Produção

1. `bash scripts/deploy.sh`
2. `sudo bash scripts/setup_firewall.sh`
3. `sudo bash scripts/setup_ssl.sh seu-dominio.com`
4. `bash scripts/setup_remote_backup.sh`
5. Veja [DEPLOY.md](../instructions/DEPLOY.md)

## 💡 Dicas

- ✅ Execute o wizard em uma sessão SSH persistente (use `screen` ou `tmux`)
- ✅ Teste primeiro em ambiente de desenvolvimento
- ✅ Faça backup do `.env` em local seguro
- ✅ Use domínios reais em produção para SSL funcionar
- ✅ Configure backup remoto logo após o deploy

## 🆘 Suporte

Se encontrar problemas:

1. Veja os logs: `docker compose logs`
2. Consulte [DEPLOY.md](../instructions/DEPLOY.md)
3. Abra uma issue no GitHub

---

**Versão:** 1.0  
**Atualizado:** 04 de Fevereiro de 2026
