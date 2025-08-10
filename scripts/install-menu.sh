#!/bin/bash

# =============================================================================
# Sistema de Menu Interativo para Instalação Seletiva de Containers
# =============================================================================
# Este script permite escolher quais containers serão instalados
# Uso: ./scripts/install-menu.sh

set -e

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Diretórios
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
COMPOSE_FILE="$PROJECT_ROOT/docker-compose.yml"
COMPOSE_CUSTOM="$PROJECT_ROOT/docker-compose.custom.yml"

# Serviços disponíveis
declare -A SERVICES=(
    ["n8n"]="Plataforma de Automação (requer PostgreSQL)"
    ["postgres"]="Banco de dados PostgreSQL"
    ["sqlserver"]="Banco de dados SQL Server"
    ["nginx"]="Proxy reverso Nginx (requer n8n)"
    ["pgadmin"]="Interface web PostgreSQL (requer postgres)"
    ["adminer"]="Interface web universal para DB"
    ["redis"]="Cache e message broker"
)

# Dependências entre serviços
declare -A DEPENDENCIES=(
    ["n8n"]="postgres"
    ["nginx"]="n8n"
    ["pgadmin"]="postgres"
)

# Estado dos serviços (0=desmarcado, 1=marcado)
declare -A SERVICE_STATE

# Inicializar todos os serviços como desmarcados
for service in "${!SERVICES[@]}"; do
    SERVICE_STATE[$service]=0
done

# Função para limpar tela
clear_screen() {
    clear
}

# Função para exibir cabeçalho
show_header() {
    echo -e "${BLUE}"
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║              Instalação Seletiva de Containers               ║"
    echo "║                    Automation Lab Platform                   ║"
    echo "╚══════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
}

# Função para exibir menu de serviços
show_services_menu() {
    echo -e "${YELLOW}Selecione os containers que deseja instalar:${NC}"
    echo ""
    
    local index=1
    for service in "${!SERVICES[@]}"; do
        local status="[ ]"
        if [ ${SERVICE_STATE[$service]} -eq 1 ]; then
            status="[✓]"
        fi
        
        local description="${SERVICES[$service]}"
        local dependency=""
        if [ -n "${DEPENDENCIES[$service]}" ]; then
            dependency=" (requer ${DEPENDENCIES[$service]})"
        fi
        
        echo -e "${GREEN}$index${NC}) $status ${service}${NC} - ${description}${YELLOW}${dependency}${NC}"
        ((index++))
    done
    
    echo ""
    echo -e "${BLUE}Opções:${NC}"
    echo "  ${GREEN}1-7${NC} - Alternar serviço"
    echo "  ${GREEN}a${NC}   - Selecionar todos"
    echo "  ${GREEN}n${NC}   - Selecionar nenhum"
    echo "  ${GREEN}c${NC}   - Continuar com seleção atual"
    echo "  ${GREEN}q${NC}   - Sair"
}

# Função para alternar serviço
toggle_service() {
    local service_name=$1
    local current_state=${SERVICE_STATE[$service_name]}
    
    # Verificar dependências
    if [ $current_state -eq 0 ]; then
        # Ativando serviço - verificar se dependências estão ativadas
        local dep=${DEPENDENCIES[$service_name]}
        if [ -n "$dep" ] && [ ${SERVICE_STATE[$dep]} -eq 0 ]; then
            echo -e "${RED}Erro: $service_name requer $dep que não está selecionado${NC}"
            read -p "Deseja ativar $dep também? (s/n): " -n 1 -r
            echo
            if [[ $REPLY =~ ^[Ss]$ ]]; then
                SERVICE_STATE[$dep]=1
                echo -e "${GREEN}$dep ativado automaticamente${NC}"
            else
                return 1
            fi
        fi
    fi
    
    SERVICE_STATE[$service_name]=$((1 - current_state))
    return 0
}

# Função para selecionar todos
select_all() {
    for service in "${!SERVICES[@]}"; do
        SERVICE_STATE[$service]=1
    done
}

# Função para selecionar nenhum
select_none() {
    for service in "${!SERVICES[@]}"; do
        SERVICE_STATE[$service]=0
    done
}

# Função para validar seleção
validate_selection() {
    local has_selected=0
    
    for service in "${!SERVICES[@]}"; do
        if [ ${SERVICE_STATE[$service]} -eq 1 ]; then
            has_selected=1
            break
        fi
    done
    
    if [ $has_selected -eq 0 ]; then
        echo -e "${RED}Erro: Nenhum serviço selecionado${NC}"
        return 1
    fi
    
    # Verificar dependências críticas
    for service in "${!SERVICES[@]}"; do
        if [ ${SERVICE_STATE[$service]} -eq 1 ]; then
            local dep=${DEPENDENCIES[$service]}
            if [ -n "$dep" ] && [ ${SERVICE_STATE[$dep]} -eq 0 ]; then
                echo -e "${RED}Erro: $service requer $dep que não está selecionado${NC}"
                return 1
            fi
        fi
    done
    
    return 0
}

# Função para gerar docker-compose personalizado
generate_custom_compose() {
    echo -e "${GREEN}Gerando docker-compose.custom.yml...${NC}"
    
    cat > "$COMPOSE_CUSTOM" << 'EOF'
version: '3.8'

# Docker Compose personalizado gerado pelo menu de instalação
# Serviços selecionados: [SERVICES_LIST]

services:
EOF

    local services_list=""
    for service in "${!SERVICES[@]}"; do
        if [ ${SERVICE_STATE[$service]} -eq 1 ]; then
            services_list="$services_list $service"
            
            # Extrair configuração do serviço do docker-compose original
            awk -v service="$service" '
                /^  [^ #]/ { current_service=$0; gsub(/:/, "", current_service); gsub(/  /, "", current_service) }
                current_service == service { print }
                /^  [^ #]/ && current_service != service { current_service="" }
            ' "$COMPOSE_FILE" >> "$COMPOSE_CUSTOM"
            
            echo "" >> "$COMPOSE_CUSTOM"
        fi
    done
    
    # Adicionar networks e volumes base
    cat >> "$COMPOSE_CUSTOM" << 'EOF'

networks:
  automation-network:
    driver: bridge
    ipam:
      config:
        - subnet: 172.20.0.0/16

volumes:
  postgres_data:
  sqlserver_data:
  n8n_data:
  redis_data:
  pgadmin_data:
EOF
    
    # Substituir placeholder
    sed -i "s/\[SERVICES_LIST\]/$services_list/" "$COMPOSE_CUSTOM"
    
    echo -e "${GREEN}Arquivo docker-compose.custom.yml gerado com sucesso!${NC}"
}

# Função principal do menu
main_menu() {
    clear_screen
    
    while true; do
        show_header
        show_services_menu
        
        echo ""
        read -p "Escolha uma opção: " -n 1 -r
        echo
        
        case $REPLY in
            [1-7])
                local index=1
                for service in "${!SERVICES[@]}"; do
                    if [ $index -eq $REPLY ]; then
                        toggle_service "$service"
                        break
                    fi
                    ((index++))
                done
                ;;
            [aA])
                select_all
                ;;
            [nN])
                select_none
                ;;
            [cC])
                if validate_selection; then
                    break
                else
                    read -p "Pressione Enter para continuar..."
                fi
                ;;
            [qQ])
                echo -e "${YELLOW}Instalação cancelada pelo usuário${NC}"
                exit 0
                ;;
            *)
                echo -e "${RED}Opção inválida${NC}"
                sleep 1
                ;;
        esac
    done
    
    # Mostrar resumo
    clear_screen
    show_header
    echo -e "${GREEN}Resumo da instalação:${NC}"
    echo ""
    
    for service in "${!SERVICES[@]}"; do
        if [ ${SERVICE_STATE[$service]} -eq 1 ]; then
            echo -e "  ${GREEN}✓${NC} $service"
        fi
    done
    
    echo ""
    read -p "Deseja continuar com esta configuração? (s/n): " -n 1 -r
    echo
    
    if [[ ! $REPLY =~ ^[Ss]$ ]]; then
        echo -e "${YELLOW}Instalação cancelada pelo usuário${NC}"
        exit 0
    fi
    
    generate_custom_compose
    
    echo ""
    echo -e "${GREEN}Configuração concluída!${NC}"
    echo -e "Para iniciar os containers, execute: ${YELLOW}docker-compose -f docker-compose.custom.yml up -d${NC}"
}

# Executar menu
main_menu
