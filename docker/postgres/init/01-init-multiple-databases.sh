#!/bin/bash
set -e

# Função para criar múltiplos bancos de dados
create_multiple_databases() {
    local databases=$1
    local users=$2
    
    echo "Criando múltiplos bancos de dados: $databases"
    echo "Criando múltiplos usuários: $users"
    
    # Converter strings em arrays
    IFS=',' read -ra DB_ARRAY <<< "$databases"
    IFS=',' read -ra USER_ARRAY <<< "$users"
    
    # Criar bancos de dados
    for db in "${DB_ARRAY[@]}"; do
        echo "Criando banco de dados: $db"
        psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" <<-EOSQL
            CREATE DATABASE "$db";
EOSQL
    done
    
    # Criar usuários
    for user_info in "${USER_ARRAY[@]}"; do
        IFS=':' read -ra USER_PASS <<< "$user_info"
        local username=${USER_PASS[0]}
        local password=${USER_PASS[1]}
        
        echo "Criando usuário: $username"
        psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" <<-EOSQL
            CREATE USER "$username" WITH PASSWORD '$password';
            ALTER USER "$username" CREATEDB;
EOSQL
        
        # Conceder permissões nos bancos de dados
        for db in "${DB_ARRAY[@]}"; do
            psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$db" <<-EOSQL
                GRANT ALL PRIVILEGES ON DATABASE "$db" TO "$username";
                GRANT ALL ON SCHEMA public TO "$username";
EOSQL
        done
    done
}

# Instalar extensões úteis
install_extensions() {
    local databases=$1
    
    IFS=',' read -ra DB_ARRAY <<< "$databases"
    
    for db in "${DB_ARRAY[@]}"; do
        echo "Instalando extensões no banco: $db"
        psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$db" <<-EOSQL
            CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
            CREATE EXTENSION IF NOT EXISTS "pgcrypto";
            CREATE EXTENSION IF NOT EXISTS "hstore";
            CREATE EXTENSION IF NOT EXISTS "ltree";
            CREATE EXTENSION IF NOT EXISTS "pg_trgm";
            CREATE EXTENSION IF NOT EXISTS "unaccent";
EOSQL
    done
}

# Executar funções se as variáveis estiverem definidas
if [ -n "$POSTGRES_MULTIPLE_DATABASES" ]; then
    echo "Configurando múltiplos bancos de dados..."
    create_multiple_databases "$POSTGRES_MULTIPLE_DATABASES" "$POSTGRES_MULTIPLE_USERS"
    install_extensions "$POSTGRES_MULTIPLE_DATABASES"
fi

echo "Inicialização do PostgreSQL concluída!"