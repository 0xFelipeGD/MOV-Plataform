# 🚀 Início Rápido - MOV Platform

Este guia te leva de **zero** a **plataforma rodando** em menos de 2 minutos!

## ✅ Pré-requisitos

- Docker instalado e rodando
- Git instalado
- Portas 1883, 3000 e 8086 disponíveis

## 📥 Passo 1: Clone o repositório

```bash
git clone <seu-repositorio>
cd MOV-Plataform
```

## ⚙️ Passo 2: Execute o setup automático

```bash
chmod +x scripts/setup.sh
./scripts/setup.sh
```

**O que o script faz:**

- ✓ Cria estrutura de diretórios
- ✓ Gera credenciais seguras automaticamente
- ✓ Cria arquivo `.env` com todas as configurações
- ✓ Valida instalação do Docker

## 🚀 Passo 3: Inicie a plataforma

```bash
docker compose up -d
```

## ✅ Passo 4: Verifique se está funcionando

```bash
docker compose ps
```

Todos os containers devem estar com status **Up** e **healthy**:

```
NAME            STATUS
mov_broker      Up X seconds
mov_influx      Up X seconds (healthy)
mov_telegraf    Up X seconds (healthy)
mov_grafana     Up X seconds (healthy)
mov_analytics   Up X seconds
mov_backup      Up X seconds
```

## 🌐 Passo 5: Acesse os serviços

| Serviço  | URL                   | Credenciais                        |
| -------- | --------------------- | ---------------------------------- |
| Grafana  | http://localhost:3000 | Usuário: admin<br>Senha: no `.env` |
| InfluxDB | http://localhost:8086 | Ver arquivo `.env`                 |
| MQTT     | localhost:1883        | Ver arquivo `.env`                 |

## 📝 Onde estão as senhas?

Todas as credenciais foram geradas automaticamente e estão no arquivo `.env`:

```bash
cat .env
```

## 🔧 Comandos úteis

```bash
# Parar todos os serviços
docker compose down

# Ver logs de todos os serviços
docker compose logs -f

# Ver logs de um serviço específico
docker compose logs -f mosquitto
docker compose logs -f influxdb
docker compose logs -f telegraf

# Reiniciar a plataforma
docker compose restart

# Atualizar e reiniciar
docker compose down && docker compose up -d
```

## 🆘 Problemas?

### Container não inicia

```bash
# Veja os logs do container com problema
docker compose logs <nome-do-container>

# Exemplo:
docker compose logs mosquitto
```

### Portas já em uso

Se alguma porta já estiver em uso (1883, 3000, 8086), você precisa:

1. Parar o serviço que está usando a porta, ou
2. Editar o `docker-compose.yml` para usar outras portas

### Resetar tudo

```bash
# ATENÇÃO: Isso apaga TODOS os dados!
docker compose down -v
rm -rf mosquitto/data/* mosquitto/log/* backups/*
./scripts/setup.sh
docker compose up -d
```

## 📚 Próximos Passos

1. **Configure dispositivos IoT** para enviar dados via MQTT para `localhost:1883`
2. **Crie dashboards no Grafana** acessando http://localhost:3000
3. **Explore os dados** no InfluxDB em http://localhost:8086
4. Consulte o [README.md](README.md) completo para configurações avançadas

---

## 🎉 Sucesso!

Sua plataforma MOV está rodando! Agora você pode começar a coletar dados dos seus sensores IoT.

**Dúvidas?** Consulte a [documentação completa](README.md) ou os [guias de instruções](instructions/).
