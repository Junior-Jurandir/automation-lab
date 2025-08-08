#!/bin/bash

# Script para visualizar logs dos serviços
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

# Função para mostrar logs de um serviço específico
show_service_logs() {
    local service=$1
    local follow=${2:-false}
    
    if [ "$follow" = "true" ]; then
        print_message $BLUE "📋 Seguindo logs do serviço: $service (Ctrl+C para sair)"
        docker-compose logs -f "$service"
    else
        print_message $BLUE "📋 Últimos logs do serviço: $service"
        docker-compose logs --tail=50 "$service"
    fi
}

# Função para mostrar logs de todos os serviços
show_all_logs() {
    local follow=${1:-false}
    
    if [ "$follow" = "true" ]; then
        print_message $BLUE "📋 Seguindo logs de todos os serviços (Ctrl+C para sair)"
        docker-compose logs -f
    else
        print_message $BLUE "📋 Últimos logs de todos os serviços"
        docker-compose logs --tail=20
    fi
}

# Função para listar serviços disponíveis
list_services() {
    print_message $BLUE "📋 Serviços disponíveis:"
    echo ""
    services=("n8n" "postgres" "sqlserver" "redis" "pgadmin" "adminer" "nginx")
    
    for service in "${services[@]}"; do
        if docker-compose ps | grep -q "$service"; then
            status=$(docker-compose ps "$service" | tail -n 1 | awk '{print $4}')
            if [[ $status == *"Up"* ]]; then
                print_message $GREEN "  ✅ $service (rodando)"
            else
                print_message $RED "  ❌ $service (parado)"
            fi
        else
            print_message $YELLOW "  ⚠️  $service (não encontrado)"
        fi
    done
    echo ""
}

# Função para mostrar ajuda
show_help() {
    echo "Uso: $0 [serviço] [opções]"
    echo ""
    echo "Serviços disponíveis:"
    echo "  n8n         - Logs do N8N"
    echo "  postgres    - Logs do PostgreSQL"
    echo "  sqlserver   - Logs do SQL Server"
    echo "  redis       - Logs do Redis"
    echo "  pgadmin     - Logs do PgAdmin"
    echo "  adminer     - Logs do Adminer"
    echo "  nginx       - Logs do Nginx"
    echo "  all         - Logs de todos os serviços"
    echo ""
    echo "Opções:"
    echo "  -f, --follow    Seguir logs em tempo real"
    echo "  -l, --list      Listar status dos serviços"
    echo "  -h, --help      Mostrar esta ajuda"
    echo ""
    echo "Exemplos:"
    echo "  $0 n8n          # Mostrar últimos logs do N8N"
    echo "  $0 n8n -f       # Seguir logs do N8N em tempo real"
    echo "  $0 all -f       # Seguir logs de todos os serviços"
    echo "  $0 -l           # Listar status dos serviços"
    echo ""
}

# Função principal
main() {
    local service=""
    local follow=false
    
    # Processar argumentos
    while [[ $# -gt 0 ]]; do
        case $1 in
            -f|--follow)
                follow=true
                shift
                ;;
            -l|--list)
                list_services
                exit 0
                ;;
            -h|--help)
                show_help
                exit 0
                ;;
            n8n|postgres|sqlserver|redis|pgadmin|adminer|nginx|all)
                service=$1
                shift
                ;;
            *)
                print_message $RED "❌ Argumento desconhecido: $1"
                show_help
                exit 1
                ;;
        esac
    done
    
    # Verificar se Docker Compose está disponível
    if ! command -v docker-compose &> /dev/null; then
        print_message $RED "❌ Docker Compose não está instalado."
        exit 1
    fi
    
    # Verificar se há containers rodando
    if ! docker-compose ps | grep -q "Up"; then
        print_message $YELLOW "⚠️  Nenhum serviço está rodando."
        print_message $BLUE "💡 Execute './scripts/start.sh' para iniciar os serviços."
        exit 1
    fi
    
    # Mostrar logs baseado no serviço especificado
    if [ -z "$service" ]; then
        print_message $YELLOW "⚠️  Nenhum serviço especificado. Mostrando logs de todos os serviços."
        show_all_logs "$follow"
    elif [ "$service" = "all" ]; then
        show_all_logs "$follow"
    else
        # Verificar se o serviço existe
        if docker-compose ps | grep -q "$service"; then
            show_service_logs "$service" "$follow"
        else
            print_message $RED "❌ Serviço '$service' não encontrado."
            list_services
            exit 1
        fi
    fi
}

# Executar função principal
main "$@"