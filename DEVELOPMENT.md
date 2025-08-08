# 👨‍💻 Guia de Desenvolvimento

Este documento fornece informações detalhadas para desenvolvedores que desejam contribuir ou personalizar o laboratório de automação.

## 📋 Índice

- [Arquitetura](#arquitetura)
- [Desenvolvimento Local](#desenvolvimento-local)
- [Customização](#customização)
- [Debugging](#debugging)
- [Testes](#testes)
- [Contribuição](#contribuição)

## 🏗 Arquitetura

### Visão Geral

O laboratório é composto por múltiplos containers Docker orquestrados via Docker Compose:

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│     Nginx       │    │      N8N        │    │   PostgreSQL    │
│  (Proxy/SSL)    │◄──►│  (Automação)    │◄──►│   (Database)    │
└─────────────────┘    └─────────────────┘    └─────────────────┘
         │                       │                       │
         ▼                       ▼                       ▼
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│    PgAdmin      │    │   SQL Server    │    │     Redis       │
│  (DB Manager)   │    │   (Database)    │    │    (Cache)      │
└─────────────────┘    └─────────────────┘    └─────────────────┘
         │
         ▼
┌─────────────────┐
│    Adminer      │
│ (Universal DB)  │
└─────────────────┘
```

### Rede Docker

- **Nome da rede**: `automation-network`
- **Subnet**: `172.20.0.0/16`
- **Driver**: `bridge`

### Volumes Persistentes

| Volume | Descrição | Container |
|--------|-----------|-----------|
| `./data/n8n` | Dados do N8N | n8n |
| `./data/postgres` | Dados PostgreSQL | postgres |
| `./data/sqlserver` | Dados SQL Server | sqlserver |
| `./data/redis` | Dados Redis | redis |
| `./data/pgadmin` | Configurações PgAdmin | pgadmin |

## 🔧 Desenvolvimento Local

### Pré-requisitos

- Docker 20.10+
- Docker Compose 2.0+
- Git
- Make (opcional, mas recomendado)
- Node.js 16+ (para desenvolvimento de nodes customizados)
- Python 3.8+ (para scripts auxiliares)

### Setup do Ambiente

```bash
# 1. Clone o repositório
git clone <repository-url>
cd automation-lab

# 2. Configure variáveis de ambiente
cp .env.example .env
# Edite .env conforme necessário

# 3. Torne os scripts executáveis
chmod +x scripts/*.sh

# 4. Inicie o ambiente
make install
```

### Estrutura de Desenvolvimento

```
automation-lab/
├── docker/                    # Dockerfiles e configurações
│   ├── n8n/
│   │   ├── Dockerfile         # N8N customizado
│   │   └── custom-nodes/      # Nodes personalizados
│   ├── postgres/
│   │   ├── Dockerfile         # PostgreSQL com extensões
│   │   └── init/              # Scripts de inicialização
│   └── ...
├── src/                       # Código fonte (se aplicável)
│   ├── nodes/                 # Nodes customizados do N8N
│   ├── scripts/               # Scripts Python/Node.js
│   └── workflows/             # Templates de workflows
├── tests/                     # Testes automatizados
│   ├── unit/
│   ├── integration/
│   └── e2e/
└── docs/                      # Documentação adicional
```

## 🎨 Customização

### Adicionando Nodes Customizados ao N8N

1. **Criar estrutura do node**:
```bash
mkdir -p docker/n8n/custom-nodes/n8n-nodes-custom
cd docker/n8n/custom-nodes/n8n-nodes-custom
```

2. **Criar package.json**:
```json
{
  "name": "n8n-nodes-custom",
  "version": "1.0.0",
  "description": "Custom nodes for N8N",
  "main": "index.js",
  "n8n": {
    "nodes": [
      "dist/nodes/CustomNode/CustomNode.node.js"
    ]
  }
}
```

3. **Modificar Dockerfile do N8N**:
```dockerfile
# Adicionar ao Dockerfile
COPY custom-nodes/ /home/node/custom-nodes/
RUN cd /home/node/custom-nodes/n8n-nodes-custom && npm install
```

### Adicionando Extensões ao PostgreSQL

1. **Modificar script de inicialização**:
```bash
# Editar docker/postgres/init/01-init-multiple-databases.sh
# Adicionar extensões na função install_extensions()
```

2. **Exemplo de extensão**:
```sql
CREATE EXTENSION IF NOT EXISTS "pg_stat_statements";
CREATE EXTENSION IF NOT EXISTS "pg_buffercache";
```

### Configurações Personalizadas

#### N8N
```bash
# Editar config/n8n/config.json
{
  "nodes": {
    "include": ["n8n-nodes-custom"],
    "exclude": []
  }
}
```

#### Nginx
```bash
# Adicionar configurações em config/nginx/
# Exemplo: rate limiting, custom headers, etc.
```

## 🐛 Debugging

### Logs Detalhados

```bash
# Habilitar debug no N8N
export N8N_LOG_LEVEL=debug

# Ver logs em tempo real
make logs-follow

# Logs específicos
docker-compose logs -f n8n --tail=100
```

### Debug do N8N

1. **Modo debug**:
```bash
# No container N8N
N8N_LOG_LEVEL=debug n8n start
```

2. **Debug de workflows**:
```bash
# Executar workflow específico
n8n execute --id <workflow-id>
```

### Debug de Bancos de Dados

#### PostgreSQL
```bash
# Conectar ao banco
make db-postgres-cli

# Ver queries ativas
SELECT * FROM pg_stat_activity;

# Ver locks
SELECT * FROM pg_locks;
```

#### SQL Server
```bash
# Conectar ao banco
make db-sqlserver-cli

# Ver processos ativos
SELECT * FROM sys.dm_exec_sessions;
```

### Monitoramento de Performance

```bash
# Recursos dos containers
make monitor

# Estatísticas detalhadas
docker stats --format "table {{.Container}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.NetIO}}"
```

## 🧪 Testes

### Estrutura de Testes

```bash
tests/
├── unit/                      # Testes unitários
│   ├── test_scripts.py
│   └── test_nodes.js
├── integration/               # Testes de integração
│   ├── test_database.py
│   └── test_n8n_api.js
└── e2e/                      # Testes end-to-end
    ├── test_workflows.py
    └── test_ui.js
```

### Executando Testes

```bash
# Testes unitários
python -m pytest tests/unit/

# Testes de integração
python -m pytest tests/integration/

# Testes E2E
python -m pytest tests/e2e/
```

### Testes de Workflows

```bash
# Testar workflow específico
n8n execute --id <workflow-id> --input '{"data": "test"}'

# Validar workflow
n8n validate --file workflow.json
```

## 🔄 CI/CD

### GitHub Actions (Exemplo)

```yaml
name: CI/CD Pipeline

on:
  push:
    branches: [ main, develop ]
  pull_request:
    branches: [ main ]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v2
    
    - name: Setup Docker
      uses: docker/setup-buildx-action@v1
    
    - name: Run tests
      run: |
        make install
        make test
    
    - name: Cleanup
      run: make clean
```

### Deployment

```bash
# Build para produção
docker-compose -f docker-compose.prod.yml build

# Deploy
docker-compose -f docker-compose.prod.yml up -d
```

## 📊 Métricas e Monitoramento

### Prometheus + Grafana (Opcional)

```yaml
# Adicionar ao docker-compose.yml
prometheus:
  image: prom/prometheus
  ports:
    - "9090:9090"
  volumes:
    - ./config/prometheus:/etc/prometheus

grafana:
  image: grafana/grafana
  ports:
    - "3000:3000"
  volumes:
    - ./data/grafana:/var/lib/grafana
```

### Métricas do N8N

```bash
# Endpoint de métricas (se habilitado)
curl http://localhost:5678/metrics
```

## 🔒 Segurança

### Boas Práticas

1. **Senhas seguras**: Use senhas complexas em produção
2. **SSL/TLS**: Configure certificados válidos
3. **Firewall**: Limite acesso às portas necessárias
4. **Backup**: Mantenha backups regulares e seguros
5. **Updates**: Mantenha imagens atualizadas

### Auditoria

```bash
# Verificar vulnerabilidades nas imagens
docker scan n8nio/n8n:latest

# Verificar configurações de segurança
docker-compose config --quiet
```

## 🤝 Contribuição

### Processo de Contribuição

1. **Fork** o repositório
2. **Clone** seu fork
3. **Crie** uma branch para sua feature
4. **Desenvolva** e teste suas mudanças
5. **Commit** com mensagens descritivas
6. **Push** para sua branch
7. **Abra** um Pull Request

### Padrões de Código

#### Shell Scripts
```bash
#!/bin/bash
set -e  # Parar em caso de erro

# Usar funções
function_name() {
    local param=$1
    # código aqui
}
```

#### Docker
```dockerfile
# Usar multi-stage builds quando possível
FROM node:16-alpine AS builder
# build steps

FROM node:16-alpine AS runtime
# runtime steps
```

#### Documentação
- Use Markdown para documentação
- Inclua exemplos práticos
- Mantenha atualizado com mudanças

### Testes Obrigatórios

Antes de submeter PR:

```bash
# Executar todos os testes
make test

# Verificar linting
make lint

# Testar build
make rebuild
```

## 📚 Recursos Adicionais

### Links Úteis

- [Documentação N8N](https://docs.n8n.io/)
- [PostgreSQL Docs](https://www.postgresql.org/docs/)
- [SQL Server Docs](https://docs.microsoft.com/en-us/sql/)
- [Docker Compose](https://docs.docker.com/compose/)

### Comunidade

- [N8N Community](https://community.n8n.io/)
- [Discord](https://discord.gg/n8n)
- [GitHub Issues](https://github.com/n8n-io/n8n/issues)

### Exemplos

Veja a pasta `examples/` para:
- Workflows de exemplo
- Configurações avançadas
- Scripts de automação
- Integrações personalizadas

---

**Happy Coding! 🚀**