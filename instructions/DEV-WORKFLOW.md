# 💻 MOV Platform - Workflow de Desenvolvimento

**Guia completo para desenvolver localmente, trabalhar em equipe e sincronizar código.**

---

## 📋 Visão Geral

### O Que Este Guia Cobre

✅ Setup inicial em nova máquina  
✅ Desenvolvimento local  
✅ Trabalho em equipe (Git workflow)  
✅ Sincronização de mudanças  
✅ Testes antes de produção  
✅ Boas práticas

### Para Quem É Este Guia

- Desenvolvedores começando no projeto
- Equipes trabalhando colaborativamente
- Quem precisa desenvolver em múltiplos computadores
- Onboarding de novos membros da equipe

---

## 🎯 Cenários Principais

### ✅ Cenário 1: Sou Novo no Projeto

**Objetivo:** Configurar ambiente de desenvolvimento pela primeira vez.

**Siga:** [SETUP INICIAL](#-setup-inicial---primeira-vez-novo-pc)

---

### ✅ Cenário 2: Já Tenho o Projeto, Quero Começar a Desenvolver

**Objetivo:** Workflow diário de desenvolvimento.

**Siga:** [WORKFLOW DIÁRIO](#-workflow-di%C3%A1rio)

---

### ✅ Cenário 3: Trabalho em Equipe

**Objetivo:** Sincronizar código com outros desenvolvedores.

**Siga:** [TRABALHO EM EQUIPE](#-trabalho-em-equipe)

---

## 📍 SETUP INICIAL - Primeira Vez (Novo PC)

### **PASSO 1: Instalar pré-requisitos**

#### No Linux/Mac:

```bash
# Docker
curl -fsSL https://get.docker.com | sh

# Adicionar usuário ao grupo docker
sudo usermod -aG docker $USER

# IMPORTANTE: Sair e entrar novamente ou reiniciar
```

#### No Windows:

- Instalar [Docker Desktop](https://www.docker.com/products/docker-desktop/)
- Instalar [Git](https://git-scm.com/downloads)

**Verificar instalação:**

```bash
docker --version
docker compose version
git --version
```

---

### **PASSO 2: Clonar o repositório**

```bash
# Ir para pasta de projetos
cd ~/Desktop  # ou onde você quiser

# Clonar do GitHub
git clone https://github.com/seuusuario/MOV-Plataform.git

# Entrar na pasta
cd MOV-Plataform

# Ver estrutura
ls -la
```

Você verá:

```
docker-compose.yml
docker-compose.prod.yml
.gitignore
DEPLOY.md
WORKFLOW.md
DEV-WORKFLOW.md  ← Este arquivo
analytics/
mosquitto/
nginx/
scripts/
telegraf/
```

---

### **PASSO 3: Executar setup wizard**

```bash
# Executar wizard interativo (cria estrutura e gera credenciais)
bash scripts/setup_wizard.sh
```

**Responda as perguntas:**

- Ambiente: `1) Development`
- Componentes: tecle `Y` para todos (padrão)
- Configurações: pode pular domínios (Enter)

**O que o wizard faz:**

- ✓ Cria estrutura de diretórios necessária
- ✓ Gera arquivo .env com credenciais seguras (OpenSSL)
- ✓ Configura permissões corretas (UIDs 1883, 1000, 472)
- ✓ Valida Docker e Docker Compose

**Ver as credenciais geradas:**

```bash
cat .env
```

**💡 Nota:** O arquivo `.env` NÃO vai pro Git (está no `.gitignore`), então cada desenvolvedor tem suas próprias credenciais locais.

---

### **PASSO 4: Iniciar ambiente de desenvolvimento**

```bash
# Iniciar todos os containers
docker compose up -d

# Ver status
docker compose ps

# Ver logs (se quiser)
docker compose logs -f
```

**Aguarde ~30 segundos** para tudo inicializar.

---

### **PASSO 5: Acessar serviços locais**

Abra no navegador:

**Grafana:** http://localhost:3000

- Usuário: `admin`
- Senha: (veja `GRAFANA_PASSWORD` no arquivo `.env`)

**InfluxDB:** http://localhost:8086

- Usuário: `admin_influx`
- Senha: (veja `INFLUX_PASSWORD` no `.env`)

**MQTT:**

- Host: `localhost`
- Porta: `1883`
- Usuário/Senha: (veja `MQTT_USER` e `MQTT_PASSWORD` no `.env`)

---

## 🔄 WORKFLOW DIÁRIO

### **Começar a trabalhar (puxar atualizações)**

```bash
# 1. Entrar na pasta do projeto
cd MOV-Plataform

# 2. Puxar últimas mudanças do GitHub
git pull

# 3. Verificar se há novos arquivos ou mudanças
git status

# 4. Reiniciar containers (se houver mudanças no código)
docker compose down
docker compose up -d --build

# 5. Ver logs pra garantir que está tudo OK
docker compose logs
```

---

### **Visualizar logs dos containers**

Use o script `logs.sh` para facilitar a visualização:

```bash
# Modo interativo (menu)
./scripts/logs.sh

# Ver logs de um container específico
./scripts/logs.sh mosquitto
./scripts/logs.sh influxdb
./scripts/logs.sh grafana

# Ver logs de todos os containers
./scripts/logs.sh all

# Ver últimas 200 linhas sem seguir em tempo real
./scripts/logs.sh analytics -n 200 --no-follow

# Apenas novos logs (tail)
./scripts/logs.sh telegraf -t
```

**Atalho rápido:** Execute sem argumentos para menu interativo!

---

### **Fazer mudanças no código**

#### **Exemplo 1: Editar código Python (Analytics)**

```bash
# 1. Abrir arquivo
nano analytics/main.py
# ou use seu editor favorito: VSCode, PyCharm, etc.

# 2. Fazer mudanças no código

# 3. Testar (rebuild apenas o analytics)
docker compose up -d --build analytics

# 4. Ver logs para verificar
./scripts/logs.sh analytics
# ou: docker compose logs -f analytics

# 5. Se funcionar, parar os logs (Ctrl+C) e continuar
```

---

#### **Exemplo 2: Adicionar novo tópico MQTT no Telegraf**

```bash
# 1. Editar configuração
nano telegraf/config/telegraf.conf

# 2. Adicionar novo tópico:
[[inputs.mqtt_consumer]]
  topics = [
    "sensor/temperatura",
    "sensor/umidade",
    "sensor/novo_sensor"  # ← Adicionar aqui
  ]

# 3. Reiniciar Telegraf
docker compose restart telegraf

# 4. Ver logs
docker compose logs -f telegraf
```

---

## 🔧 TROUBLESHOOTING

### Erro de permissão no Mosquitto ou InfluxDB

Se você ver erros como:

- `Permission denied` ao criar arquivos
- `touch: /mosquitto/config/passwd: Permission denied`
- InfluxDB não consegue escrever configuração

**Solução:**

```bash
# Corrigir permissões manualmente
sudo chown -R 1883:1883 mosquitto/
sudo chown -R 1000:1000 influxdb/
sudo chown -R 472:472 grafana/

# Reinicie os containers
docker compose restart
```

### Containers não iniciam após git clone

**Causa:** Diretórios necessários não foram criados.

**Solução:**

```bash
# Re-executar o setup wizard
bash scripts/setup_wizard.sh
# Escolher: Development

# Iniciar containers
docker compose up -d
```

### Container fica reiniciando (restart loop)

```bash
# Ver o que está acontecendo (usando script)
./scripts/logs.sh <nome-do-container>

# Exemplos:
./scripts/logs.sh mosquitto
./scripts/logs.sh influxdb
./scripts/logs.sh telegraf

# Ou usando docker compose diretamente:
docker compose logs mosquitto
```

---

#### **Exemplo 3: Criar novo dashboard no Grafana**

1. **Acesse** http://localhost:3000
2. **Crie** o dashboard visualmente
3. **Exporte** o dashboard:
   - Dashboard → Share → Export → Save to file
4. **Salve** em `grafana/provisioning/dashboards/meu_dashboard.json`
5. **Commit** (veja próxima seção)

---

### **Commitar e enviar mudanças**

```bash
# 1. Ver o que mudou
git status

# 2. Ver diferenças linha por linha (opcional)
git diff

# 3. Adicionar arquivos modificados
git add analytics/main.py
# ou adicionar tudo:
git add .

# 4. Commitar com mensagem descritiva
git commit -m "feat: adiciona análise de temperatura média"

# 5. Enviar para GitHub
git push origin main
```

**💡 Dicas de mensagens de commit:**

```bash
# Novos recursos
git commit -m "feat: adiciona novo sensor de pressão"

# Correções
git commit -m "fix: corrige bug no cálculo de média"

# Mudanças técnicas
git commit -m "chore: atualiza versão do InfluxDB"

# Documentação
git commit -m "docs: atualiza README com novos sensores"
```

---

### **Finalizar o dia (parar containers)**

```bash
# Parar todos os containers
docker compose down

# Ou deixar rodando em background (recomendado para não ter que reiniciar sempre)
# Nesse caso, não precisa fazer nada!
```

---

## 🔀 TRABALHANDO EM MÚLTIPLOS PCs

### **Cenário: Você trabalhou no PC 1, agora está no PC 2**

#### **No PC 2:**

```bash
# 1. Entrar na pasta
cd MOV-Plataform

# 2. Puxar suas mudanças do PC 1
git pull

# 3. Reiniciar containers com as novas mudanças
docker compose down
docker compose up -d --build

# 4. Continuar trabalhando...
```

---

### **Cenário: Trabalho em equipe (você e outras pessoas)**

#### **Sincronizar antes de começar:**

```bash
# SEMPRE fazer isso ANTES de começar a codificar
git pull
```

#### **Se der conflito ao puxar:**

```bash
# Git vai avisar que há conflitos
# Exemplo: analytics/main.py tem conflito

# 1. Abrir o arquivo
nano analytics/main.py

# 2. Você verá algo assim:
<<<<<<< HEAD
# Sua mudança
=======
# Mudança do colega
>>>>>>> origin/main

# 3. Decidir qual manter (ou mesclar ambas)
# 4. Remover as marcações <<<<<<, =======, >>>>>>>
# 5. Salvar

# 6. Marcar como resolvido
git add analytics/main.py

# 7. Finalizar merge
git commit -m "merge: resolve conflito em analytics"

# 8. Enviar
git push
```

---

## 🧪 TESTAR MUDANÇAS LOCALMENTE

### **Testar tudo antes de commitar:**

```bash
# 1. Rebuild completo
docker compose down
docker compose up -d --build

# 2. Verificar se todos os containers estão UP
docker compose ps

# 3. Ver logs de todos os serviços
docker compose logs

# 4. Testar funcionalidades:
# - Acessar Grafana
# - Verificar se dados estão chegando no InfluxDB
# - Testar MQTT (se aplicável)

# 5. Se tudo OK, commitar!
git add .
git commit -m "feat: sua mensagem aqui"
git push
```

---

## 🐛 TROUBLESHOOTING

### **"Container não inicia depois do git pull"**

```bash
# Ver qual container está com problema
docker compose ps

# Ver logs do container com erro
docker compose logs [nome-do-container]

# Exemplos:
docker compose logs analytics
docker compose logs influxdb
docker compose logs mosquitto
```

---

### **"Mudanças não aparecem depois do rebuild"**

```bash
# Forçar rebuild sem cache
docker compose build --no-cache
docker compose up -d
```

---

### **"Porta já está em uso"**

```bash
# Ver o que está usando a porta (exemplo: 3000)
sudo lsof -i :3000

# Matar processo
sudo kill -9 [PID]

# Ou parar containers antigos
docker compose down
```

---

### **"Esqueci de fazer pull e já fiz mudanças"**

```bash
# Opção 1: Guardar suas mudanças temporariamente
git stash           # Guarda mudanças
git pull            # Puxa atualizações
git stash pop       # Recupera suas mudanças

# Opção 2: Commit suas mudanças antes
git add .
git commit -m "WIP: trabalho em progresso"
git pull            # Vai fazer merge automático
```

---

## 📋 CHECKLIST - Antes de Commitar

- [ ] Código testado localmente
- [ ] Todos os containers rodando sem erros
- [ ] Logs não mostram erros críticos
- [ ] Funcionalidade testada no navegador/ferramenta
- [ ] Arquivos sensíveis NÃO adicionados (`.env`, senhas, etc)
- [ ] Mensagem de commit descritiva

```bash
# Verificar o que vai ser commitado
git status

# Ver diferenças
git diff

# Verificar se .env NÃO está na lista
# Se estiver, REMOVA:
git reset .env
```

---

## 📊 ESTRUTURA DO PROJETO

```
MOV-Plataform/
├── analytics/              # Código Python (análises)
│   ├── Dockerfile
│   ├── main.py            # ← EDITAR: Lógica de análise
│   └── requirements.txt   # ← EDITAR: Adicionar bibliotecas Python
│
├── grafana/
│   └── provisioning/      # ← EDITAR: Adicionar dashboards JSON
│
├── mosquitto/
│   └── config/
│       └── mosquitto.conf # ← EDITAR: Configuração MQTT
│
├── nginx/
│   ├── nginx.conf         # ← Raramente editar
│   └── conf.d/
│       └── default.conf   # ← EDITAR: Configuração de domínios
│
├── scripts/               # Scripts de automação
│   ├── setup_wizard.sh    # Setup interativo (USE ESTE)
│   ├── deploy.sh          # Deploy produção
│   ├── update.sh          # Update rápido
│   ├── backup.sh          # Backup manual
│   ├── setup_firewall.sh  # Firewall VPS
│   └── setup_ssl.sh       # SSL/TLS
│
├── telegraf/
│   └── config/
│       └── telegraf.conf  # ← EDITAR: Adicionar sensores/tópicos
│
├── docker-compose.yml      # ← EDITAR: Adicionar serviços
├── docker-compose.prod.yml # Configuração de produção
├── .gitignore             # Arquivos ignorados pelo Git
├── .env                   # ← NÃO COMMITAR (credenciais locais)
├── README.md              # Documentação principal
└── instructions/          # Guias de documentação
    ├── DEPLOY.md          # Guia de deploy VPS
    ├── UPDATES.md         # Guia de atualização
    └── DEV-WORKFLOW.md    # ← Este arquivo (desenvolvimento)
```

---

## 🎓 COMANDOS GIT ESSENCIAIS

```bash
# Status do repositório
git status

# Ver histórico de commits
git log --oneline

# Ver diferenças
git diff

# Adicionar arquivos
git add arquivo.py
git add .              # Adiciona tudo

# Commitar
git commit -m "mensagem"

# Enviar para GitHub
git push

# Puxar do GitHub
git pull

# Ver branches
git branch

# Criar nova branch
git checkout -b feature/nova-funcionalidade

# Voltar para main
git checkout main

# Ver repositório remoto
git remote -v

# Desfazer mudanças não commitadas
git checkout -- arquivo.py
git reset --hard      # CUIDADO: remove TODAS mudanças não commitadas
```

---

## 🚀 DICAS DE PRODUTIVIDADE

### **1. Use VSCode com extensões:**

- Docker
- Python
- GitLens
- Remote - SSH (para editar direto na VPS se necessário)

### **2. Alias úteis (.bashrc ou .zshrc):**

```bash
alias dc='docker compose'
alias dcup='docker compose up -d'
alias dcdown='docker compose down'
alias dclog='docker compose logs -f'
alias dcps='docker compose ps'
alias dcbuild='docker compose up -d --build'

alias gs='git status'
alias ga='git add'
alias gc='git commit -m'
alias gp='git push'
alias gl='git pull'
alias glog='git log --oneline --graph --all'
```

### **3. Testar mudanças rapidamente:**

```bash
# Rebuild apenas um serviço específico
docker compose up -d --build analytics

# Ver logs de um serviço específico
docker compose logs -f analytics

# Executar comando dentro do container
docker compose exec analytics python -c "print('teste')"
```

---

## 💡 BOAS PRÁTICAS

### ✅ **SIM - Faça:**

1. **Sempre git pull antes de começar a trabalhar**
2. **Teste local antes de commitar**
3. **Commits pequenos e frequentes** (melhor que 1 commit gigante)
4. **Mensagens descritivas** nos commits
5. **Use branches** para features grandes
6. **Documente** código complexo com comentários

### ❌ **NÃO - Evite:**

1. **Commitar arquivo `.env`** (tem no .gitignore, mas cuidado!)
2. **Commitar senhas ou tokens** em código
3. **Fazer push sem testar**
4. **Commits com mensagens genéricas** ("update", "fix", "teste")
5. **Trabalhar muito tempo sem fazer commits** (risco de perder trabalho)

---

## 📚 RECURSOS ADICIONAIS

- **Docker:** https://docs.docker.com/
- **Git:** https://git-scm.com/doc
- **InfluxDB:** https://docs.influxdata.com/
- **Grafana:** https://grafana.com/docs/
- **Mosquitto:** https://mosquitto.org/documentation/

---

## 🎉 RESUMO RÁPIDO

```bash
# Setup inicial (primeira vez)
git clone https://github.com/seuusuario/MOV-Plataform.git
cd MOV-Plataform
bash scripts/setup_wizard.sh  # Escolher: Development
docker compose up -d

# Workflow diário
git pull                           # Puxar atualizações
# ... fazer mudanças ...
docker compose up -d --build       # Testar
git add .                          # Adicionar mudanças
git commit -m "feat: descrição"    # Commitar
git push                           # Enviar

# Ver o que está rodando
docker compose ps
docker compose logs -f

# Parar tudo
docker compose down
```

---

**🎯 Agora você está pronto para desenvolver em qualquer PC!**

**Dúvidas?** Veja também:

- [DEPLOY.md](DEPLOY.md) - Deploy em produção
- [UPDATES.md](UPDATES.md) - Atualizar plataforma
