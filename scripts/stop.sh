#!/bin/bash

# Script para parar o laboratório de automação
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

# Função para parar os serviços
stop_services() {
    print_message $BLUE "🛑 Parando serviços..."
    
    if docker-compose ps | grep -q "Up"; then
        docker-compose stop
        print_message $GREEN "✅ Serviços parados"
    else
        print_message $YELLOW "⚠️  Nenhum serviço estava rodando"
    fi
}

# Função para remover containers (opcional)
remove_containers() {
    if [ "$1" = "--remove" ] || [ "$1" = "-r" ]; then
        print_message $BLUE "🗑️  Removendo containers..."
        docker-compose down
        print_message $GREEN "✅ Containers removidos"
    fi
}

# Função para limpar volumes (opcional)
clean_volumes() {
    if [ "$1" = "--clean" ] || [ "$1" = "-c" ]; then
        print_message $YELLOW "⚠️  Removendo volumes (dados serão perdidos)..."
        read -p "Tem certeza? (y/N): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            docker-compose down -v
            print_message $GREEN "✅ Volumes removidos"
        else
            print_message $BLUE "ℹ️  Operação cancelada"
        fi
    fi
}

# Função para mostrar ajuda
show_help() {
    echo "Uso: $0 [opções]"
    echo ""
    echo "Opções:"
    echo "  --remove, -r    Remove os containers após parar"
    echo "  --clean, -c     Remove containers e volumes (CUIDADO: dados serão perdidos)"
    echo "  --help, -h      Mostra esta ajuda"
    echo ""
}

# Função principal
main() {
    case "$1" in
        --help|-h)
            show_help
            exit 0
            ;;
        --clean|-c)
            print_message $BLUE "🔧 Parando e limpando laboratório..."
            stop_services
            clean_volumes "$1"
            ;;
        --remove|-r)
            print_message $BLUE "🔧 Parando e removendo containers..."
            stop_services
            remove_containers "$1"
            ;;
        *)
            print_message $BLUE "🔧 Parando laboratório..."
            stop_services
            ;;
    esac
    
    print_message $GREEN "✅ Operação concluída!"
}

# Executar função principal
main "$@"