#!/bin/bash

# Script de backup para o laboratório de automação
# Autor: Automation Lab
# Versão: 1.0

set -e

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configurações
BACKUP_DIR="backups"
DATE=$(date +%Y%m%d_%H%M%S)
BACKUP_NAME="automation_lab_backup_$DATE"

# Função para imprimir mensagens coloridas
print_message() {
    local color=$1
    local message=$2
    echo -e "${color}${message}${NC}"
}

# Função para criar diretório de backup
create_backup_dir() {
    mkdir -p "$BACKUP_DIR"
    print_message $GREEN "✅ Diretório de backup criado: $BACKUP_DIR"
}

# Função para fazer backup dos dados
backup_data() {
    print_message $BLUE "💾 Fazendo backup dos dados..."
    
    # Criar arquivo tar com os dados
    tar -czf "$BACKUP_DIR/$BACKUP_NAME.tar.gz" \
        data/ \
        config/ \
        docker-compose.yml \
        .env 2>/dev/null || true
    
    print_message $GREEN "✅ Backup dos dados criado: $BACKUP_DIR/$BACKUP_NAME.tar.gz"
}

# Função para fazer backup dos bancos de dados
backup_databases() {
    print_message $BLUE "🗄️  Fazendo backup dos bancos de dados..."
    
    # Backup PostgreSQL
    if docker-compose ps | grep -q "postgres.*Up"; then
        print_message $BLUE "  📊 Fazendo backup do PostgreSQL..."
        docker-compose exec -T postgres pg_dumpall -U postgres > "$BACKUP_DIR/postgres_backup_$DATE.sql"
        print_message $GREEN "  ✅ Backup do PostgreSQL criado"
    else
        print_message $YELLOW "  ⚠️  PostgreSQL não está rodando, pulando backup"
    fi
    
    # Backup SQL Server
    if docker-compose ps | grep -q "sqlserver.*Up"; then
        print_message $BLUE "  📊 Fazendo backup do SQL Server..."
        # Criar script de backup para SQL Server
        cat > "$BACKUP_DIR/sqlserver_backup_$DATE.sql" << EOF
-- Backup gerado em $(date)
-- Execute este script em um SQL Server para restaurar os dados

-- Backup do banco AutomationDB
BACKUP DATABASE [AutomationDB] TO DISK = '/var/opt/mssql/data/AutomationDB_$DATE.bak'
WITH FORMAT, INIT, NAME = 'AutomationDB-Full Database Backup', SKIP, NOREWIND, NOUNLOAD, STATS = 10;

-- Backup do banco TestDB
BACKUP DATABASE [TestDB] TO DISK = '/var/opt/mssql/data/TestDB_$DATE.bak'
WITH FORMAT, INIT, NAME = 'TestDB-Full Database Backup', SKIP, NOREWIND, NOUNLOAD, STATS = 10;
EOF
        print_message $GREEN "  ✅ Script de backup do SQL Server criado"
    else
        print_message $YELLOW "  ⚠️  SQL Server não está rodando, pulando backup"
    fi
}

# Função para fazer backup das configurações do N8N
backup_n8n_workflows() {
    print_message $BLUE "🔄 Fazendo backup dos workflows do N8N..."
    
    if [ -d "data/n8n" ]; then
        # Copiar workflows e credenciais
        mkdir -p "$BACKUP_DIR/n8n_backup_$DATE"
        cp -r data/n8n/* "$BACKUP_DIR/n8n_backup_$DATE/" 2>/dev/null || true
        
        # Criar arquivo tar dos workflows
        tar -czf "$BACKUP_DIR/n8n_workflows_$DATE.tar.gz" -C "$BACKUP_DIR" "n8n_backup_$DATE"
        rm -rf "$BACKUP_DIR/n8n_backup_$DATE"
        
        print_message $GREEN "✅ Backup dos workflows do N8N criado"
    else
        print_message $YELLOW "⚠️  Diretório do N8N não encontrado, pulando backup"
    fi
}

# Função para listar backups existentes
list_backups() {
    print_message $BLUE "📋 Backups existentes:"
    
    if [ -d "$BACKUP_DIR" ] && [ "$(ls -A $BACKUP_DIR)" ]; then
        ls -la "$BACKUP_DIR" | grep -E "\.(tar\.gz|sql)$" | while read -r line; do
            filename=$(echo "$line" | awk '{print $9}')
            size=$(echo "$line" | awk '{print $5}')
            date=$(echo "$line" | awk '{print $6, $7, $8}')
            print_message $GREEN "  📦 $filename ($size bytes) - $date"
        done
    else
        print_message $YELLOW "  ⚠️  Nenhum backup encontrado"
    fi
}

# Função para limpar backups antigos
cleanup_old_backups() {
    local days=${1:-7}
    
    print_message $BLUE "🧹 Limpando backups com mais de $days dias..."
    
    if [ -d "$BACKUP_DIR" ]; then
        find "$BACKUP_DIR" -name "*.tar.gz" -o -name "*.sql" -type f -mtime +$days -delete
        print_message $GREEN "✅ Backups antigos removidos"
    fi
}

# Função para mostrar ajuda
show_help() {
    echo "Uso: $0 [opções]"
    echo ""
    echo "Opções:"
    echo "  --full, -f          Backup completo (dados + bancos + workflows)"
    echo "  --data, -d          Backup apenas dos dados"
    echo "  --databases, -db    Backup apenas dos bancos de dados"
    echo "  --workflows, -w     Backup apenas dos workflows do N8N"
    echo "  --list, -l          Listar backups existentes"
    echo "  --cleanup [dias]    Limpar backups antigos (padrão: 7 dias)"
    echo "  --help, -h          Mostrar esta ajuda"
    echo ""
    echo "Exemplos:"
    echo "  $0 --full           # Backup completo"
    echo "  $0 --data           # Backup apenas dos dados"
    echo "  $0 --list           # Listar backups"
    echo "  $0 --cleanup 30     # Limpar backups com mais de 30 dias"
    echo ""
}

# Função principal
main() {
    local action="full"
    local cleanup_days=7
    
    # Processar argumentos
    while [[ $# -gt 0 ]]; do
        case $1 in
            --full|-f)
                action="full"
                shift
                ;;
            --data|-d)
                action="data"
                shift
                ;;
            --databases|-db)
                action="databases"
                shift
                ;;
            --workflows|-w)
                action="workflows"
                shift
                ;;
            --list|-l)
                list_backups
                exit 0
                ;;
            --cleanup)
                if [[ $2 =~ ^[0-9]+$ ]]; then
                    cleanup_days=$2
                    shift 2
                else
                    shift
                fi
                cleanup_old_backups "$cleanup_days"
                exit 0
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
    
    print_message $BLUE "🔧 Iniciando backup do laboratório..."
    echo "=================================================="
    
    create_backup_dir
    
    case $action in
        "full")
            backup_data
            backup_databases
            backup_n8n_workflows
            ;;
        "data")
            backup_data
            ;;
        "databases")
            backup_databases
            ;;
        "workflows")
            backup_n8n_workflows
            ;;
    esac
    
    print_message $GREEN "🎉 Backup concluído com sucesso!"
    print_message $BLUE "📁 Arquivos salvos em: $BACKUP_DIR/"
}

# Executar função principal
main "$@"