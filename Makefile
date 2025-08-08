# Makefile para Laboratório de Automação N8N
# Facilita o gerenciamento do ambiente Docker

.PHONY: help start stop restart logs backup clean install status

# Variáveis
COMPOSE_FILE = docker-compose.yml
SCRIPTS_DIR = scripts

# Comando padrão
.DEFAULT_GOAL := help

# Ajuda
help: ## Mostra esta ajuda
	@echo "Laboratório de Automação N8N - Comandos Disponíveis:"
	@echo "=================================================="
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "\033[36m%-15s\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST)
	@echo ""
	@echo "Exemplos de uso:"
	@echo "  make install    # Primeira instalação"
	@echo "  make start      # Iniciar laboratório"
	@echo "  make logs       # Ver logs de todos os serviços"
	@echo "  make backup     # Fazer backup completo"

# Instalação inicial
install: ## Instala e configura o laboratório pela primeira vez
	@echo "🔧 Instalando laboratório de automação..."
	@if [ ! -f .env ]; then \
		cp .env.example .env; \
		echo "✅ Arquivo .env criado a partir do exemplo"; \
		echo "⚠️  Edite o arquivo .env com suas configurações"; \
	fi
	@chmod +x $(SCRIPTS_DIR)/*.sh
	@echo "✅ Permissões dos scripts configuradas"
	@$(SCRIPTS_DIR)/start.sh

# Iniciar serviços
start: ## Inicia todos os serviços do laboratório
	@$(SCRIPTS_DIR)/start.sh

# Parar serviços
stop: ## Para todos os serviços
	@$(SCRIPTS_DIR)/stop.sh

# Reiniciar serviços
restart: ## Reinicia todos os serviços
	@$(SCRIPTS_DIR)/stop.sh
	@sleep 5
	@$(SCRIPTS_DIR)/start.sh

# Ver logs
logs: ## Mostra logs de todos os serviços
	@$(SCRIPTS_DIR)/logs.sh all

# Ver logs de um serviço específico
logs-n8n: ## Mostra logs do N8N
	@$(SCRIPTS_DIR)/logs.sh n8n

logs-postgres: ## Mostra logs do PostgreSQL
	@$(SCRIPTS_DIR)/logs.sh postgres

logs-sqlserver: ## Mostra logs do SQL Server
	@$(SCRIPTS_DIR)/logs.sh sqlserver

logs-follow: ## Segue logs de todos os serviços em tempo real
	@$(SCRIPTS_DIR)/logs.sh all -f

# Status dos serviços
status: ## Mostra status de todos os serviços
	@echo "📊 Status dos Serviços:"
	@echo "======================"
	@docker-compose ps

# Backup
backup: ## Faz backup completo do laboratório
	@$(SCRIPTS_DIR)/backup.sh --full

backup-data: ## Faz backup apenas dos dados
	@$(SCRIPTS_DIR)/backup.sh --data

backup-db: ## Faz backup apenas dos bancos de dados
	@$(SCRIPTS_DIR)/backup.sh --databases

backup-workflows: ## Faz backup apenas dos workflows do N8N
	@$(SCRIPTS_DIR)/backup.sh --workflows

backup-list: ## Lista backups existentes
	@$(SCRIPTS_DIR)/backup.sh --list

# Limpeza
clean: ## Para e remove todos os containers (mantém dados)
	@$(SCRIPTS_DIR)/stop.sh --remove

clean-all: ## Remove containers e volumes (CUIDADO: apaga dados!)
	@echo "⚠️  ATENÇÃO: Esta operação irá apagar todos os dados!"
	@read -p "Tem certeza? Digite 'yes' para confirmar: " confirm; \
	if [ "$$confirm" = "yes" ]; then \
		$(SCRIPTS_DIR)/stop.sh --clean; \
	else \
		echo "❌ Operação cancelada"; \
	fi

# Atualizar imagens
update: ## Atualiza todas as imagens Docker
	@echo "🔄 Atualizando imagens Docker..."
	@docker-compose pull
	@echo "✅ Imagens atualizadas"

# Reconstruir containers
rebuild: ## Reconstrói todos os containers
	@echo "🔨 Reconstruindo containers..."
	@docker-compose build --no-cache
	@echo "✅ Containers reconstruídos"

# Comandos de desenvolvimento
dev-shell-n8n: ## Abre shell no container do N8N
	@docker-compose exec n8n /bin/sh

dev-shell-postgres: ## Abre shell no container do PostgreSQL
	@docker-compose exec postgres /bin/bash

dev-shell-sqlserver: ## Abre shell no container do SQL Server
	@docker-compose exec sqlserver /bin/bash

# Comandos de banco de dados
db-postgres-cli: ## Conecta ao PostgreSQL via CLI
	@docker-compose exec postgres psql -U postgres

db-sqlserver-cli: ## Conecta ao SQL Server via CLI
	@docker-compose exec sqlserver /opt/mssql-tools/bin/sqlcmd -S localhost -U sa

# Monitoramento
monitor: ## Mostra uso de recursos dos containers
	@echo "📊 Uso de Recursos:"
	@echo "=================="
	@docker stats --format "table {{.Container}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.NetIO}}\t{{.BlockIO}}"

# Informações do sistema
info: ## Mostra informações do sistema
	@echo "ℹ️  Informações do Sistema:"
	@echo "=========================="
	@echo "Docker Version: $$(docker --version)"
	@echo "Docker Compose Version: $$(docker-compose --version)"
	@echo "Containers ativos: $$(docker ps -q | wc -l)"
	@echo "Imagens locais: $$(docker images -q | wc -l)"
	@echo "Volumes: $$(docker volume ls -q | wc -l)"
	@echo "Redes: $$(docker network ls -q | wc -l)"

# Acesso rápido às interfaces
open-n8n: ## Abre N8N no navegador
	@echo "🌐 Abrindo N8N..."
	@python3 -m webbrowser https://localhost 2>/dev/null || \
	 python -m webbrowser https://localhost 2>/dev/null || \
	 echo "Acesse: https://localhost"

open-pgadmin: ## Abre PgAdmin no navegador
	@echo "🌐 Abrindo PgAdmin..."
	@python3 -m webbrowser http://localhost:8080 2>/dev/null || \
	 python -m webbrowser http://localhost:8080 2>/dev/null || \
	 echo "Acesse: http://localhost:8080"

open-adminer: ## Abre Adminer no navegador
	@echo "🌐 Abrindo Adminer..."
	@python3 -m webbrowser http://localhost:8081 2>/dev/null || \
	 python -m webbrowser http://localhost:8081 2>/dev/null || \
	 echo "Acesse: http://localhost:8081"