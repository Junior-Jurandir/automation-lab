#!/bin/bash

# Script de inicialização do laboratório de automação
# Autor: Automation Lab
# Versão: 1.0

set -e

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Função para imprimir mensagens coloridas
print_message() {
    local color=$1
    local message=$2
    echo -e "${color}${message}${NC}"
}

# Função para verificar se o Docker está rodando
check_docker() {
    if ! docker info > /dev/null 2>&1; then
        print_message $RED "❌ Docker não está rodando. Por favor, inicie o Docker primeiro."
        exit 1
    fi
    print_message $GREEN "✅ Docker está rodando"
}

# Função para verificar se o Docker Compose está instalado
check_docker_compose() {
    if ! command -v docker-compose &> /dev/null; then
        print_message $RED "❌ Docker Compose não está instalado."
        exit 1
    fi
    print_message $GREEN "✅ Docker Compose está disponível"
}

# Função para criar diretórios necessários
create_directories() {
    print_message $BLUE "📁 Criando diretórios necessários..."
    
    directories=(
        "data/n8n"
        "data/postgres"
        "data/sqlserver"
        "data/redis"
        "data/pgadmin"
        "logs/postgres"
        "logs/sqlserver"
        "logs/nginx"
        "config/n8n"
    )
    
    for dir in "${directories[@]}"; do
        mkdir -p "$dir"
        print_message $GREEN "  ✅ Criado: $dir"
    done
}

# Função para definir permissões
set_permissions() {
    print_message $BLUE "🔐 Configurando permissões..."
    
    # Permissões para PostgreSQL
    sudo chown -R 999:999 data/postgres logs/postgres 2>/dev/null || true
    
    # Permissões para SQL Server
    sudo chown -R 10001:0 data/sqlserver logs/sqlserver 2>/dev/null || true
    
    # Permissões para N8N
    sudo chown -R 1000:1000 data/n8n config/n8n 2>/dev/null || true
    
    # Permissões para PgAdmin
    sudo chown -R 5050:5050 data/pgadmin 2>/dev/null || true
    
    print_message $GREEN "✅ Permissões configuradas"
}

# Função para iniciar os serviços
start_services() {
    print_message $BLUE "🚀 Iniciando serviços..."
    
    # Construir e iniciar os containers
    docker-compose build --no-cache
    docker-compose up -d
    
    print_message $GREEN "✅ Serviços iniciados"
}

# Função para verificar status dos serviços
check_services() {
    print_message $BLUE "🔍 Verificando status dos serviços..."
    
    sleep 10
    
    services=("postgres" "sqlserver" "redis" "n8n" "pgadmin" "adminer" "nginx")
    
    for service in "${services[@]}"; do
        if docker-compose ps | grep -q "$service.*Up"; then
            print_message $GREEN "  ✅ $service está rodando"
        else
            print_message $RED "  ❌ $service não está rodando"
        fi
    done
}

# Função para mostrar informações de acesso
show_access_info() {
    print_message $BLUE "🌐 Informações de Acesso:"
    echo ""
    print_message $YELLOW "N8N (Automação):"
    echo "  URL: https://localhost"
    echo "  Usuário: admin"
    echo "  Senha: admin123"
    echo ""
    print_message $YELLOW "PgAdmin (PostgreSQL):"
    echo "  URL: http://localhost:8080"
    echo "  Email: admin@automation.local"
    echo "  Senha: admin123"
    echo ""
    print_message $YELLOW "Adminer (Universal DB):"
    echo "  URL: http://localhost:8081"
    echo ""
    print_message $YELLOW "PostgreSQL:"
    echo "  Host: localhost"
    echo "  Porta: 5432"
    echo "  Usuário: postgres"
    echo "  Senha: postgres123"
    echo ""
    print_message $YELLOW "SQL Server:"
    echo "  Host: localhost"
    echo "  Porta: 1433"
    echo "  Usuário: sa"
    echo "  Senha: SqlServer123!"
    echo ""
    print_message $YELLOW "Redis:"
    echo "  Host: localhost"
    echo "  Porta: 6379"
    echo "  Senha: redis123"
    echo ""
}

# Função principal
main() {
    print_message $BLUE "🔧 Iniciando Laboratório de Automação N8N"
    echo "=================================================="
    
    check_docker
    check_docker_compose
    create_directories
    set_permissions
    start_services
    check_services
    
    echo ""
    print_message $GREEN "🎉 Laboratório iniciado com sucesso!"
    echo ""
    show_access_info
    
    print_message $BLUE "📝 Para parar os serviços, execute: ./scripts/stop.sh"
    print_message $BLUE "📝 Para ver logs, execute: ./scripts/logs.sh [serviço]"
}

# Executar função principal
main "$@"