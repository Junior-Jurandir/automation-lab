# 🚀 Laboratório de Automação N8N

Um ambiente Docker completo e modular para desenvolvimento de automações usando N8N, PostgreSQL e SQL Server.

## 📋 Índice

- [Visão Geral](#-visão-geral)
- [Pré-requisitos](#-pré-requisitos)
- [Instalação Rápida](#-instalação-rápida)
- [Serviços Incluídos](#-serviços-incluídos)
- [Estrutura do Projeto](#-estrutura-do-projeto)
- [Uso](#-uso)
- [Configuração](#-configuração)
- [Backup e Restauração](#-backup-e-restauração)
- [Desenvolvimento](#-desenvolvimento)
- [Troubleshooting](#-troubleshooting)
- [Contribuição](#-contribuição)

## 🎯 Visão Geral

Este laboratório fornece um ambiente completo para desenvolvimento de automações com:

- **N8N**: Plataforma de automação visual
- **PostgreSQL**: Banco de dados principal com extensões
- **SQL Server**: Banco de dados Microsoft para integração
- **Redis**: Cache e message broker
- **PgAdmin**: Interface web para PostgreSQL
- **Adminer**: Interface web universal para bancos
- **Nginx**: Proxy reverso com SSL

## 🔧 Pré-requisitos

- Docker 20.10+
- Docker Compose 2.0+
- 4GB RAM disponível
- 10GB espaço em disco
- Portas disponíveis: 80, 443, 1433, 5432, 5678, 6379, 8080, 8081

## ⚡ Instalação Rápida

```bash
# 1. Clone ou baixe este projeto
git clone <repository-url>
cd automation-lab

# 2. Instale e inicie (usando Makefile)
make install

# OU usando scripts diretamente
chmod +x scripts/*.sh
./scripts/start.sh
```

## 🛠 Serviços Incluídos

| Serviço | Porta | URL | Usuário | Senha |
|---------|-------|-----|---------|-------|
| N8N | 5678 | https://localhost | admin | admin123 |
| PgAdmin | 8080 | http://localhost:8080 | admin@automation.local | admin123 |
| Adminer | 8081 | http://localhost:8081 | - | - |
| PostgreSQL | 5432 | localhost:5432 | postgres | postgres123 |
| SQL Server | 1433 | localhost:1433 | sa | SqlServer123! |
| Redis | 6379 | localhost:6379 | - | redis123 |
| Nginx | 80/443 | https://localhost | - | - |

## 📁 Estrutura do Projeto

```
automation-lab/
├── docker/                    # Dockerfiles customizados
│   ├── n8n/
│   │   └── Dockerfile
│   ├── postgres/
│   │   ├── Dockerfile
│   │   └── init/              # Scripts de inicialização
│   ├── sqlserver/
│   │   ├── Dockerfile
│   │   ├── entrypoint.sh
│   │   └── init/
│   └── nginx/
│       ├── Dockerfile
│       └── nginx.conf
├── data/                      # Dados persistentes
│   ├── n8n/
│   ├── postgres/
│   ├── sqlserver/
│   ├── redis/
│   └── pgadmin/
├── config/                    # Configurações
│   ├── n8n/
│   ├── pgadmin/
│   └── nginx/
├── logs/                      # Logs dos serviços
├── scripts/                   # Scripts de gerenciamento
│   ├── start.sh
│   ├── stop.sh
│   ├── logs.sh
│   └── backup.sh
├── backups/                   # Backups automáticos
├── docker-compose.yml         # Configuração principal
├── .env.example              # Variáveis de ambiente
├── Makefile                  # Comandos facilitados
└── README.md                 # Esta documentação
```

## 🚀 Uso

### Comandos com Makefile (Recomendado)

```bash
# Gerenciamento básico
make start          # Iniciar laboratório
make stop           # Parar laboratório
make restart        # Reiniciar laboratório
make status         # Ver status dos serviços

# Logs
make logs           # Ver logs de todos os serviços
make logs-n8n       # Ver logs do N8N
make logs-follow    # Seguir logs em tempo real

# Backup
make backup         # Backup completo
make backup-data    # Backup apenas dados
make backup-list    # Listar backups

# Desenvolvimento
make dev-shell-n8n  # Shell no container N8N
make db-postgres-cli # CLI do PostgreSQL

# Acesso rápido
make open-n8n       # Abrir N8N no navegador
make open-pgadmin   # Abrir PgAdmin no navegador

# Ajuda
make help           # Ver todos os comandos
```

### Comandos com Scripts

```bash
# Iniciar laboratório
./scripts/start.sh

# Parar laboratório
./scripts/stop.sh

# Ver logs
./scripts/logs.sh n8n          # Logs do N8N
./scripts/logs.sh all -f       # Todos os logs em tempo real

# Backup
./scripts/backup.sh --full     # Backup completo
./scripts/backup.sh --list     # Listar backups
```

## ⚙️ Configuração

### Variáveis de Ambiente

1. Copie o arquivo de exemplo:
```bash
cp .env.example .env
```

2. Edite as configurações no arquivo `.env`:
```bash
# Configurações do N8N
N8N_BASIC_AUTH_USER=seu_usuario
N8N_BASIC_AUTH_PASSWORD=sua_senha_segura

# Configurações do PostgreSQL
POSTGRES_PASSWORD=sua_senha_postgres

# Configurações do SQL Server
MSSQL_SA_PASSWORD=SuaSenhaSegura123!
```

### Configurações Avançadas

#### N8N
- Workflows salvos em: `data/n8n/`
- Configurações em: `config/n8n/`
- Logs em: `logs/n8n/`

#### PostgreSQL
- Dados em: `data/postgres/`
- Scripts de inicialização: `docker/postgres/init/`
- Bancos criados automaticamente: `n8n`, `automation_db`, `test_db`

#### SQL Server
- Dados em: `data/sqlserver/`
- Scripts de inicialização: `docker/sqlserver/init/`
- Bancos criados: `AutomationDB`, `TestDB`

## 💾 Backup e Restauração

### Backup Automático

```bash
# Backup completo
make backup

# Backup específico
make backup-data        # Apenas dados
make backup-workflows   # Apenas workflows N8N
```

### Restauração

```bash
# Parar serviços
make stop

# Restaurar dados (exemplo)
tar -xzf backups/automation_lab_backup_YYYYMMDD_HHMMSS.tar.gz

# Reiniciar serviços
make start
```

### Limpeza de Backups

```bash
# Limpar backups antigos (7 dias)
./scripts/backup.sh --cleanup

# Limpar backups antigos (30 dias)
./scripts/backup.sh --cleanup 30
```

## 👨‍💻 Desenvolvimento

### Acessar Containers

```bash
# Shell no N8N
make dev-shell-n8n

# Shell no PostgreSQL
make dev-shell-postgres

# CLI do PostgreSQL
make db-postgres-cli

# CLI do SQL Server
make db-sqlserver-cli
```

### Instalar Pacotes Adicionais no N8N

```bash
# Acessar container
docker-compose exec n8n /bin/sh

# Instalar pacote npm
npm install -g nome-do-pacote

# Instalar pacote Python
pip3 install nome-do-pacote
```

### Desenvolvimento de Workflows

1. Acesse N8N: https://localhost
2. Crie seus workflows
3. Use as conexões de banco pré-configuradas:
   - PostgreSQL: `postgres:5432`
   - SQL Server: `sqlserver:1433`
   - Redis: `redis:6379`

### Monitoramento

```bash
# Ver uso de recursos
make monitor

# Ver informações do sistema
make info

# Ver logs em tempo real
make logs-follow
```

## 🔍 Troubleshooting

### Problemas Comuns

#### Porta já em uso
```bash
# Verificar portas em uso
netstat -tulpn | grep :5678

# Parar processo na porta
sudo kill -9 $(lsof -t -i:5678)
```

#### Permissões de arquivo
```bash
# Corrigir permissões
sudo chown -R $USER:$USER data/
sudo chmod -R 755 data/
```

#### Container não inicia
```bash
# Ver logs detalhados
make logs-n8n

# Reconstruir container
make rebuild
```

#### Banco de dados não conecta
```bash
# Verificar status
make status

# Reiniciar apenas o banco
docker-compose restart postgres
```

### Logs Detalhados

```bash
# Logs de todos os serviços
make logs

# Logs específicos
docker-compose logs -f n8n
docker-compose logs -f postgres
docker-compose logs -f sqlserver
```

### Reset Completo

```bash
# CUIDADO: Apaga todos os dados!
make clean-all
make install
```

## 🔒 Segurança

### Configurações de Produção

1. **Altere todas as senhas padrão**
2. **Configure SSL adequadamente**
3. **Use variáveis de ambiente seguras**
4. **Configure firewall adequadamente**
5. **Mantenha backups regulares**

### Senhas Padrão (ALTERE EM PRODUÇÃO!)

- N8N: admin/admin123
- PostgreSQL: postgres/postgres123
- SQL Server: sa/SqlServer123!
- PgAdmin: admin@automation.local/admin123
- Redis: redis123

## 🤝 Contribuição

1. Fork o projeto
2. Crie uma branch para sua feature
3. Commit suas mudanças
4. Push para a branch
5. Abra um Pull Request

## 📄 Licença

Este projeto está sob a licença MIT. Veja o arquivo LICENSE para detalhes.

## 🆘 Suporte

- **Issues**: Abra uma issue no GitHub
- **Documentação**: Consulte este README
- **Logs**: Use `make logs` para diagnóstico

## 🔄 Atualizações

```bash
# Atualizar imagens
make update

# Reconstruir containers
make rebuild

# Backup antes de atualizar
make backup
```

---

**Desenvolvido com ❤️ para a comunidade de automação**