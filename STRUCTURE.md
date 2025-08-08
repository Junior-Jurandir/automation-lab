# 📊 Estrutura Completa do Laboratório N8N

## 🎯 Visão Geral
Laboratório Docker completo e modular para desenvolvimento de automações com N8N, PostgreSQL e SQL Server.

## 📁 Estrutura de Arquivos

```
automation-lab/
├── 📄 README.md                    # Documentação principal
├── 📄 DEVELOPMENT.md               # Guia de desenvolvimento
├── 📄 WINDOWS.md                   # Instruções específicas Windows
├── 📄 docker-compose.yml           # Configuração Docker principal
├── 📄 docker-compose.prod.yml      # Configuração para produção
├── 📄 Makefile                     # Comandos facilitados (Linux/Mac)
├── 📄 .env.example                 # Exemplo de variáveis de ambiente
├── 📄 .gitignore                   # Arquivos ignorados pelo Git
│
├── 🐳 docker/                      # Dockerfiles customizados
│   ├── n8n/
│   │   └── 📄 Dockerfile           # N8N com dependências extras
│   ├── postgres/
│   │   ├── 📄 Dockerfile           # PostgreSQL com extensões
│   │   └── init/
│   │       └── 📄 01-init-multiple-databases.sh
│   ├── sqlserver/
│   │   ├── 📄 Dockerfile           # SQL Server customizado
│   │   ├── 📄 entrypoint.sh        # Script de entrada
│   │   └── init/
│   │       └── 📄 01-init-databases.sql
│   └── nginx/
│       ├── 📄 Dockerfile           # Nginx com SSL
│       └── 📄 nginx.conf           # Configuração proxy
│
├── 📂 data/                        # Dados persistentes (ignorado)
│   ├── 📄 .gitkeep
│   ├── n8n/                       # Workflows e configurações N8N
│   ├── postgres/                  # Dados PostgreSQL
│   ├── sqlserver/                 # Dados SQL Server
│   ├── redis/                     # Dados Redis
│   └── pgadmin/                   # Configurações PgAdmin
│
├── 📂 logs/                        # Logs dos serviços (ignorado)
│   ├── 📄 .gitkeep
│   ├── postgres/
│   ├── sqlserver/
│   ├── nginx/
│   └── n8n/
│
├── ⚙️ config/                      # Configurações
│   ├── n8n/
│   │   └── 📄 config.json          # Configuração N8N
│   ├── pgadmin/
│   │   └── 📄 servers.json         # Servidores pré-configurados
│   └── nginx/
│       └── 📄 n8n-additional.conf  # Configurações extras
│
├── 💾 backups/                     # Backups (ignorado)
│   └── 📄 .gitkeep
│
└── 🔧 scripts/                     # Scripts de gerenciamento
    ├── 📄 start.sh                 # Iniciar laboratório (Linux/Mac)
    ├── 📄 stop.sh                  # Parar laboratório (Linux/Mac)
    ├── 📄 logs.sh                  # Visualizar logs (Linux/Mac)
    ├── 📄 backup.sh                # Backup completo (Linux/Mac)
    ├── 📄 health-check.sh          # Verificação de saúde
    ├── 📄 start.ps1                # Iniciar laboratório (Windows)
    ├── 📄 stop.ps1                 # Parar laboratório (Windows)
    └── 📄 logs.ps1                 # Visualizar logs (Windows)
```

## 🛠 Serviços Configurados

### N8N (Automação)
- **Porta**: 5678
- **URL**: https://localhost
- **Credenciais**: admin/admin123
- **Recursos**: Nodes customizados, Python, bibliotecas extras

### PostgreSQL (Banco Principal)
- **Porta**: 5432
- **Credenciais**: postgres/postgres123
- **Bancos**: n8n, automation_db, test_db
- **Extensões**: UUID, pgcrypto, hstore, ltree, pg_trgm

### SQL Server (Banco Microsoft)
- **Porta**: 1433
- **Credenciais**: sa/SqlServer123!
- **Bancos**: AutomationDB, TestDB
- **Recursos**: Agent habilitado, schemas customizados

### Redis (Cache)
- **Porta**: 6379
- **Senha**: redis123
- **Recursos**: Persistência, configurações otimizadas

### PgAdmin (Interface PostgreSQL)
- **Porta**: 8080
- **URL**: http://localhost:8080
- **Credenciais**: admin@automation.local/admin123

### Adminer (Interface Universal)
- **Porta**: 8081
- **URL**: http://localhost:8081
- **Recursos**: Suporte a múltiplos SGBDs

### Nginx (Proxy Reverso)
- **Portas**: 80, 443
- **Recursos**: SSL, proxy para N8N, load balancing

## 🚀 Comandos Principais

### Linux/Mac (com Make)
```bash
make install    # Primeira instalação
make start      # Iniciar laboratório
make stop       # Parar laboratório
make logs       # Ver logs
make backup     # Backup completo
make help       # Ver todos os comandos
```

### Linux/Mac (Scripts diretos)
```bash
./scripts/start.sh              # Iniciar
./scripts/stop.sh               # Parar
./scripts/logs.sh n8n           # Logs do N8N
./scripts/backup.sh --full      # Backup
./scripts/health-check.sh       # Verificar saúde
```

### Windows (PowerShell)
```powershell
.\scripts\start.ps1             # Iniciar
.\scripts\stop.ps1              # Parar
.\scripts\logs.ps1 n8n          # Logs do N8N
.\scripts\logs.ps1 -List        # Status dos serviços
```

## 🔧 Configuração

### Arquivo .env
```env
# Copiar de .env.example e personalizar
N8N_BASIC_AUTH_USER=seu_usuario
N8N_BASIC_AUTH_PASSWORD=sua_senha
POSTGRES_PASSWORD=sua_senha_postgres
MSSQL_SA_PASSWORD=SuaSenhaSegura123!
```

### Personalização
- **N8N**: Adicionar nodes em `docker/n8n/custom-nodes/`
- **PostgreSQL**: Scripts em `docker/postgres/init/`
- **SQL Server**: Scripts em `docker/sqlserver/init/`
- **Nginx**: Configurações em `config/nginx/`

## 📊 Monitoramento

### Health Check
```bash
./scripts/health-check.sh --full    # Verificação completa
./scripts/health-check.sh --quick   # Verificação rápida
./scripts/health-check.sh --report  # Gerar relatório
```

### Logs em Tempo Real
```bash
# Linux/Mac
make logs-follow

# Windows
.\scripts\logs.ps1 all -Follow
```

### Status dos Serviços
```bash
# Linux/Mac
make status

# Windows
.\scripts\logs.ps1 -List
```

## 💾 Backup e Restauração

### Backup Completo
```bash
# Linux/Mac
make backup

# Windows (manual)
docker-compose exec postgres pg_dumpall -U postgres > backup.sql
```

### Tipos de Backup
- **Completo**: Dados + bancos + workflows
- **Dados**: Apenas volumes Docker
- **Bancos**: Apenas PostgreSQL e SQL Server
- **Workflows**: Apenas configurações N8N

## 🔒 Segurança

### Configurações Padrão (ALTERAR EM PRODUÇÃO!)
- N8N: admin/admin123
- PostgreSQL: postgres/postgres123
- SQL Server: sa/SqlServer123!
- PgAdmin: admin@automation.local/admin123
- Redis: redis123

### SSL/TLS
- Certificado auto-assinado incluído
- Configuração para certificados válidos em produção

## 🌐 Acesso às Interfaces

| Serviço | URL | Credenciais |
|---------|-----|-------------|
| N8N | https://localhost | admin/admin123 |
| PgAdmin | http://localhost:8080 | admin@automation.local/admin123 |
| Adminer | http://localhost:8081 | - |

## 🔄 Atualizações

### Atualizar Imagens
```bash
# Linux/Mac
make update

# Manual
docker-compose pull
docker-compose up -d
```

### Reconstruir Containers
```bash
# Linux/Mac
make rebuild

# Manual
docker-compose build --no-cache
docker-compose up -d
```

## 🆘 Troubleshooting

### Problemas Comuns
1. **Porta em uso**: Verificar com `netstat` ou `lsof`
2. **Permissões**: Ajustar com `chown` e `chmod`
3. **Espaço em disco**: Verificar com `df -h`
4. **Memória**: Monitorar com `docker stats`

### Logs de Debug
```bash
# Ver logs detalhados
docker-compose logs --tail=100 n8n
docker-compose logs --tail=100 postgres
```

### Reset Completo
```bash
# CUIDADO: Apaga todos os dados!
# Linux/Mac
make clean-all

# Windows
.\scripts\stop.ps1 -Clean
```

## 📚 Documentação Adicional

- **README.md**: Documentação principal
- **DEVELOPMENT.md**: Guia para desenvolvedores
- **WINDOWS.md**: Instruções específicas Windows
- **Comentários no código**: Explicações detalhadas

## 🤝 Contribuição

1. Fork o repositório
2. Crie uma branch para sua feature
3. Desenvolva e teste
4. Abra um Pull Request

## 📈 Próximos Passos

### Melhorias Planejadas
- [ ] Monitoring com Prometheus/Grafana
- [ ] Backup automático agendado
- [ ] Cluster multi-node
- [ ] CI/CD pipeline
- [ ] Testes automatizados

### Integrações Adicionais
- [ ] Elasticsearch para logs
- [ ] RabbitMQ para filas
- [ ] MinIO para storage
- [ ] Vault para secrets

---

**Laboratório completo e pronto para uso! 🚀**

**Total de arquivos**: 25+ arquivos configurados
**Compatibilidade**: Linux, macOS, Windows
**Documentação**: 100% completa
**Scripts**: Automação total