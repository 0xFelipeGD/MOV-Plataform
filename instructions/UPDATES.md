# 🔄 Workflow de Desenvolvimento e Atualização

## 📋 Cenários Comuns de Atualização

### 1️⃣ Mudança no Dashboard do Grafana

### 2️⃣ Alteração no código Python (Analytics)

### 3️⃣ Novo dispositivo IoT (configuração Telegraf)

### 4️⃣ Mudança no Mosquitto

---

## 🔄 Workflow Completo (Git + VPS)

### **FASE 1: Desenvolvimento Local**

```bash
# 1. Fazer mudanças no código
# Exemplo: editar analytics/main.py

# 2. Testar localmente
docker compose down
docker compose up -d --build

# 3. Verificar se funcionou
docker compose logs analytics
docker compose logs grafana

# 4. Se tudo OK, commitar
git add .
git commit -m "feat: adiciona novo dashboard de temperatura"
git push origin main
```

---

### **FASE 2: Atualizar na VPS**

```bash
# 1. Conectar na VPS
ssh usuario@ip-vps

# 2. Entrar na pasta do projeto
cd MOV-Plataform

# 3. Puxar atualizações do GitHub
git pull

# 4. Reconstruir containers (se mudou código Python, Dockerfile, etc)
docker compose -f docker-compose.yml -f docker-compose.prod.yml up -d --build

# 5. Verificar se está rodando
docker compose ps
docker compose logs -f analytics
```

**Pronto!** Mudanças aplicadas na produção. 🚀

---

## 📝 Tipos de Mudança e Como Aplicar

### **A) Mudança no código Python (Analytics)**

**Local:**

```bash
# Editar analytics/main.py
nano analytics/main.py

# Testar
docker compose up -d --build analytics
docker compose logs analytics
```

**VPS:**

```bash
git pull
docker compose -f docker-compose.yml -f docker-compose.prod.yml up -d --build analytics
```

---

### **B) Mudança no Grafana (Dashboards)**

**Opção 1: Exportar/Importar JSON (Recomendado)**

1. **Criar dashboard no Grafana local** (http://localhost:3000)
2. **Exportar dashboard:**
   - Dashboard → Share → Export → Save to file
   - Salvar em `grafana/provisioning/dashboards/meu_dashboard.json`

3. **Commit e push:**

```bash
git add grafana/provisioning/
git commit -m "feat: novo dashboard de temperatura"
git push
```

4. **Na VPS:**

```bash
git pull
docker compose -f docker-compose.yml -f docker-compose.prod.yml restart grafana
```

**Opção 2: Fazer direto no Grafana da VPS**

- Acesse https://grafana.seudominio.com
- Crie/edite o dashboard direto lá
- **Problema:** Mudanças não ficam no Git (não é versionado)

---

### **C) Adicionar novo dispositivo IoT (Telegraf)**

**Local:**

```bash
# Editar telegraf/config/telegraf.conf
nano telegraf/config/telegraf.conf

# Adicionar novo subscription MQTT
[[inputs.mqtt_consumer]]
  topics = [
    "sensor/temperatura",
    "sensor/umidade",
    "sensor/novo_dispositivo"  # ← Novo!
  ]

# Testar
docker compose restart telegraf
docker compose logs telegraf
```

**VPS:**

```bash
git pull
docker compose -f docker-compose.yml -f docker-compose.prod.yml restart telegraf
```

---

### **D) Mudança no Mosquitto (configuração)**

**Local:**

```bash
# Editar mosquitto/config/mosquitto.conf
nano mosquitto/config/mosquitto.conf

# Testar
docker compose restart mosquitto
docker compose logs mosquitto
```

**VPS:**

```bash
git pull
docker compose -f docker-compose.yml -f docker-compose.prod.yml restart mosquitto
```

---

## ⚡ Atalhos Rápidos

### **Script de Update Rápido**

Crie `scripts/update.sh`:

```bash
#!/bin/bash
# Atualizar deploy na VPS
set -e

echo "🔄 Atualizando MOV Platform..."

# Pull do Git
git pull

# Rebuild e restart
docker compose -f docker-compose.yml -f docker-compose.prod.yml up -d --build

# Mostrar status
echo ""
echo "✅ Atualizado! Status:"
docker compose ps

echo ""
echo "📋 Ver logs:"
echo "  docker compose logs -f [serviço]"
```

**Uso na VPS:**

```bash
bash scripts/update.sh
```

---

## 🎯 Boas Práticas

### ✅ **SIM - Faça isso:**

1. **Sempre teste local antes** de fazer push
2. **Use commits descritivos:**
   ```bash
   git commit -m "feat: adiciona dashboard de pressão"
   git commit -m "fix: corrige bug no analytics ao ler sensor"
   git commit -m "chore: atualiza telegraf para nova versão"
   ```
3. **Use branches para mudanças grandes:**
   ```bash
   git checkout -b feature/novo-dashboard
   # faz mudanças
   git commit -m "..."
   git push origin feature/novo-dashboard
   # Depois: merge pra main
   ```

### ❌ **NÃO - Evite:**

1. **Editar código direto na VPS** (não fica versionado no Git)
2. **Fazer push sem testar local**
3. **Esquecer de fazer backup antes de grandes mudanças**

---

## 🔧 Troubleshooting

### **"Git pull dá erro de conflito"**

```bash
# Na VPS, se você editou algo por acidente
git stash  # Guarda mudanças locais
git pull   # Puxa do GitHub
```

### **"Container não reinicia depois do update"**

```bash
# Ver o erro
docker compose logs [serviço]

# Forçar rebuild completo
docker compose -f docker-compose.yml -f docker-compose.prod.yml down
docker compose -f docker-compose.yml -f docker-compose.prod.yml up -d --build
```

### **"Mudança no Grafana não aparece"**

```bash
# Limpar cache do navegador ou abrir em aba anônima
# Ou forçar restart
docker compose restart grafana
```

---

## 📊 Resumo Visual do Workflow

```
┌──────────────────┐
│  Seu Computador  │
│  (Desenvolvimento)│
└─────────┬────────┘
          │
          │ 1. Editar código
          │ 2. Testar local
          │    docker compose up
          │
          ▼
┌──────────────────┐
│     GitHub       │
│   (Repositório)  │
└─────────┬────────┘
          │
          │ 3. git commit + push
          │
          ▼
┌──────────────────┐
│       VPS        │
│   (Produção)     │
└──────────────────┘
          │
          │ 4. ssh na VPS
          │ 5. git pull
          │ 6. docker compose up -d --build
          │
          ▼
    ✅ Atualizado!
```

---

## 🎓 Exemplo Prático Completo

**Cenário:** Cliente quer monitorar um novo sensor de pressão.

### **1. No seu PC:**

```bash
# Editar Telegraf
nano telegraf/config/telegraf.conf

# Adicionar:
# [[inputs.mqtt_consumer]]
#   topics = ["sensor/pressao"]

# Testar
docker compose restart telegraf
docker compose logs telegraf

# Commitar
git add telegraf/config/telegraf.conf
git commit -m "feat: adiciona monitoramento de pressão"
git push
```

### **2. Na VPS:**

```bash
ssh usuario@ip-vps
cd MOV-Plataform
git pull
docker compose -f docker-compose.yml -f docker-compose.prod.yml restart telegraf
```

### **3. No Grafana:**

- Acesse https://grafana.seudominio.com
- Crie novo painel com query do InfluxDB:
  ```flux
  from(bucket: "mov_dados")
    |> range(start: -1h)
    |> filter(fn: (r) => r["_measurement"] == "pressao")
  ```
- Exporta JSON do dashboard
- Salva em `grafana/provisioning/dashboards/`
- Commit + push

**Pronto! Cliente já vê o novo sensor.** 🎉

---

## 💡 Dica Extra: CI/CD Automático (Avançado)

Para deploy automático ao fazer push (usando GitHub Actions):

```yaml
# .github/workflows/deploy.yml
name: Deploy to VPS

on:
  push:
    branches: [main]

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - name: Deploy via SSH
        uses: appleboy/ssh-action@master
        with:
          host: ${{ secrets.VPS_HOST }}
          username: ${{ secrets.VPS_USER }}
          key: ${{ secrets.SSH_KEY }}
          script: |
            cd /caminho/MOV-Plataform
            git pull
            docker compose -f docker-compose.yml -f docker-compose.prod.yml up -d --build
```

**Aí é só fazer push que já atualiza automático!** 🚀
