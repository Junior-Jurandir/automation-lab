#!/bin/bash

# Script de verificação de saúde do laboratório
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

# Função para verificar se um serviço está rodando
check_service_health() {
    local service=$1
    local expected_status="Up"
    
    if docker-compose ps | grep -q "$service.*$expected_status"; then
        print_message $GREEN "  ✅ $service está saudável"
        return 0
    else
        print_message $RED "  ❌ $service não está saudável"
        return 1
    fi
}

# Função para verificar conectividade de rede
check_network_connectivity() {
    local service=$1
    local port=$2
    local host=${3:-localhost}
    
    if timeout 5 bash -c "</dev/tcp/$host/$port" 2>/dev/null; then
        print_message $GREEN "  ✅ $service ($host:$port) está acessível"
        return 0
    else
        print_message $RED "  ❌ $service ($host:$port) não está acessível"
        return 1
    fi
}

# Função para verificar saúde do banco de dados
check_database_health() {
    print_message $BLUE "🗄️  Verificando saúde dos bancos de dados..."
    
    local postgres_healthy=0
    local sqlserver_healthy=0
    
    # PostgreSQL
    if docker-compose exec -T postgres pg_isready -U postgres >/dev/null 2>&1; then
        print_message $GREEN "  ✅ PostgreSQL está respondendo"
        postgres_healthy=1
    else
        print_message $RED "  ❌ PostgreSQL não está respondendo"
    fi
    
    # SQL Server
    if docker-compose exec -T sqlserver /opt/mssql-tools/bin/sqlcmd -S localhost -U sa -P "$MSSQL_SA_PASSWORD" -Q "SELECT 1" >/dev/null 2>&1; then
        print_message $GREEN "  ✅ SQL Server está respondendo"
        sqlserver_healthy=1
    else
        print_message $RED "  ❌ SQL Server não está respondendo"
    fi
    
    return $((postgres_healthy + sqlserver_healthy))
}

# Função para verificar saúde do N8N
check_n8n_health() {
    print_message $BLUE "🔄 Verificando saúde do N8N..."
    
    # Verificar endpoint de saúde
    if curl -f -s http://localhost:5678/healthz >/dev/null 2>&1; then
        print_message $GREEN "  ✅ N8N endpoint de saúde está respondendo"
    else
        print_message $RED "  ❌ N8N endpoint de saúde não está respondendo"
        return 1
    fi
    
    # Verificar se consegue acessar a interface
    if curl -f -s http://localhost:5678 >/dev/null 2>&1; then
        print_message $GREEN "  ✅ N8N interface está acessível"
    else
        print_message $RED "  ❌ N8N interface não está acessível"
        return 1
    fi
    
    return 0
}

# Função para verificar uso de recursos
check_resource_usage() {
    print_message $BLUE "📊 Verificando uso de recursos..."
    
    # Verificar uso de CPU e memória dos containers
    docker stats --no-stream --format "table {{.Container}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.MemPerc}}" | while read line; do
        if [[ $line == *"CONTAINER"* ]]; then
            continue
        fi
        
        container=$(echo $line | awk '{print $1}')
        cpu=$(echo $line | awk '{print $2}' | sed 's/%//')
        mem_perc=$(echo $line | awk '{print $4}' | sed 's/%//')
        
        # Verificar se CPU > 80%
        if (( $(echo "$cpu > 80" | bc -l) )); then
            print_message $YELLOW "  ⚠️  $container: CPU alta ($cpu%)"
        fi
        
        # Verificar se Memória > 80%
        if (( $(echo "$mem_perc > 80" | bc -l) )); then
            print_message $YELLOW "  ⚠️  $container: Memória alta ($mem_perc%)"
        fi
    done
    
    print_message $GREEN "  ✅ Verificação de recursos concluída"
}

# Função para verificar espaço em disco
check_disk_space() {
    print_message $BLUE "💾 Verificando espaço em disco..."
    
    # Verificar espaço disponível
    available_space=$(df -h . | awk 'NR==2 {print $4}' | sed 's/G//')
    
    if (( $(echo "$available_space < 1" | bc -l) )); then
        print_message $RED "  ❌ Pouco espaço em disco disponível: ${available_space}GB"
        return 1
    elif (( $(echo "$available_space < 5" | bc -l) )); then
        print_message $YELLOW "  ⚠️  Espaço em disco baixo: ${available_space}GB"
    else
        print_message $GREEN "  ✅ Espaço em disco adequado: ${available_space}GB"
    fi
    
    return 0
}

# Função para verificar logs de erro
check_error_logs() {
    print_message $BLUE "📋 Verificando logs de erro..."
    
    local error_count=0
    
    # Verificar logs do N8N por erros
    if docker-compose logs n8n --tail=50 2>/dev/null | grep -i "error\|exception\|failed" >/dev/null; then
        error_count=$((error_count + 1))
        print_message $YELLOW "  ⚠️  Erros encontrados nos logs do N8N"
    fi
    
    # Verificar logs do PostgreSQL por erros
    if docker-compose logs postgres --tail=50 2>/dev/null | grep -i "error\|fatal" >/dev/null; then
        error_count=$((error_count + 1))
        print_message $YELLOW "  ⚠️  Erros encontrados nos logs do PostgreSQL"
    fi
    
    # Verificar logs do SQL Server por erros
    if docker-compose logs sqlserver --tail=50 2>/dev/null | grep -i "error\|failed" >/dev/null; then
        error_count=$((error_count + 1))
        print_message $YELLOW "  ⚠️  Erros encontrados nos logs do SQL Server"
    fi
    
    if [ $error_count -eq 0 ]; then
        print_message $GREEN "  ✅ Nenhum erro crítico encontrado nos logs"
    else
        print_message $YELLOW "  ⚠️  $error_count serviço(s) com erros nos logs"
    fi
    
    return $error_count
}

# Função para gerar relatório de saúde
generate_health_report() {
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    local report_file="logs/health_report_$(date +%Y%m%d_%H%M%S).txt"
    
    print_message $BLUE "📄 Gerando relatório de saúde..."
    
    {
        echo "=========================================="
        echo "RELATÓRIO DE SAÚDE DO LABORATÓRIO"
        echo "Data/Hora: $timestamp"
        echo "=========================================="
        echo ""
        
        echo "STATUS DOS SERVIÇOS:"
        docker-compose ps
        echo ""
        
        echo "USO DE RECURSOS:"
        docker stats --no-stream
        echo ""
        
        echo "ESPAÇO EM DISCO:"
        df -h .
        echo ""
        
        echo "ÚLTIMOS LOGS (N8N):"
        docker-compose logs n8n --tail=20
        echo ""
        
        echo "ÚLTIMOS LOGS (PostgreSQL):"
        docker-compose logs postgres --tail=10
        echo ""
        
        echo "ÚLTIMOS LOGS (SQL Server):"
        docker-compose logs sqlserver --tail=10
        echo ""
        
    } > "$report_file"
    
    print_message $GREEN "  ✅ Relatório salvo em: $report_file"
}

# Função para mostrar resumo
show_summary() {
    local total_checks=$1
    local failed_checks=$2
    local success_rate=$(( (total_checks - failed_checks) * 100 / total_checks ))
    
    echo ""
    print_message $BLUE "📊 RESUMO DA VERIFICAÇÃO DE SAÚDE"
    echo "=================================================="
    print_message $BLUE "Total de verificações: $total_checks"
    print_message $BLUE "Verificações com falha: $failed_checks"
    print_message $BLUE "Taxa de sucesso: $success_rate%"
    
    if [ $failed_checks -eq 0 ]; then
        print_message $GREEN "🎉 Todos os sistemas estão saudáveis!"
    elif [ $failed_checks -le 2 ]; then
        print_message $YELLOW "⚠️  Alguns problemas menores detectados"
    else
        print_message $RED "❌ Problemas críticos detectados - ação necessária"
    fi
}

# Função para mostrar ajuda
show_help() {
    echo "Uso: $0 [opções]"
    echo ""
    echo "Opções:"
    echo "  --quick, -q     Verificação rápida (apenas serviços)"
    echo "  --full, -f      Verificação completa (padrão)"
    echo "  --report, -r    Gerar relatório detalhado"
    echo "  --help, -h      Mostrar esta ajuda"
    echo ""
    echo "Exemplos:"
    echo "  $0              # Verificação completa"
    echo "  $0 --quick      # Verificação rápida"
    echo "  $0 --report     # Verificação com relatório"
    echo ""
}

# Função principal
main() {
    local mode="full"
    local generate_report=false
    local total_checks=0
    local failed_checks=0
    
    # Processar argumentos
    while [[ $# -gt 0 ]]; do
        case $1 in
            --quick|-q)
                mode="quick"
                shift
                ;;
            --full|-f)
                mode="full"
                shift
                ;;
            --report|-r)
                generate_report=true
                shift
                ;;
            --help|-h)
                show_help
                exit 0
                ;;
            *)
                print_message $RED "❌ Argumento desconhecido: $1"
                show_help
                exit 1
                ;;
        esac
    done
    
    print_message $BLUE "🔍 Iniciando verificação de saúde do laboratório..."
    echo "=================================================="
    
    # Verificar se Docker Compose está disponível
    if ! command -v docker-compose &> /dev/null; then
        print_message $RED "❌ Docker Compose não está instalado."
        exit 1
    fi
    
    # Verificações básicas (sempre executadas)
    print_message $BLUE "🐳 Verificando status dos containers..."
    services=("n8n" "postgres" "sqlserver" "redis" "pgadmin" "adminer" "nginx")
    
    for service in "${services[@]}"; do
        total_checks=$((total_checks + 1))
        if ! check_service_health "$service"; then
            failed_checks=$((failed_checks + 1))
        fi
    done
    
    # Verificações de conectividade
    print_message $BLUE "🌐 Verificando conectividade de rede..."
    network_checks=(
        "N8N:5678"
        "PostgreSQL:5432"
        "SQL-Server:1433"
        "Redis:6379"
        "PgAdmin:8080"
        "Adminer:8081"
        "Nginx:80"
    )
    
    for check in "${network_checks[@]}"; do
        IFS=':' read -ra ADDR <<< "$check"
        service_name=${ADDR[0]}
        port=${ADDR[1]}
        
        total_checks=$((total_checks + 1))
        if ! check_network_connectivity "$service_name" "$port"; then
            failed_checks=$((failed_checks + 1))
        fi
    done
    
    # Verificações específicas do N8N
    total_checks=$((total_checks + 1))
    if ! check_n8n_health; then
        failed_checks=$((failed_checks + 1))
    fi
    
    # Verificações completas (se solicitado)
    if [ "$mode" = "full" ]; then
        # Verificar bancos de dados
        total_checks=$((total_checks + 1))
        db_result=$(check_database_health)
        if [ $? -eq 0 ]; then
            failed_checks=$((failed_checks + 1))
        fi
        
        # Verificar recursos
        total_checks=$((total_checks + 1))
        if ! check_resource_usage; then
            failed_checks=$((failed_checks + 1))
        fi
        
        # Verificar espaço em disco
        total_checks=$((total_checks + 1))
        if ! check_disk_space; then
            failed_checks=$((failed_checks + 1))
        fi
        
        # Verificar logs de erro
        total_checks=$((total_checks + 1))
        if ! check_error_logs; then
            failed_checks=$((failed_checks + 1))
        fi
    fi
    
    # Gerar relatório se solicitado
    if [ "$generate_report" = true ]; then
        generate_health_report
    fi
    
    # Mostrar resumo
    show_summary $total_checks $failed_checks
    
    # Retornar código de saída baseado no resultado
    if [ $failed_checks -eq 0 ]; then
        exit 0
    elif [ $failed_checks -le 2 ]; then
        exit 1
    else
        exit 2
    fi
}

# Executar função principal
main "$@"