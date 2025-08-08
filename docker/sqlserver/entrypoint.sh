#!/bin/bash
set -e

# Iniciar SQL Server em background
/opt/mssql/bin/sqlservr &

# Aguardar SQL Server estar pronto
echo "Aguardando SQL Server inicializar..."
sleep 30

# Executar scripts de inicialização
for script in /docker-entrypoint-initdb.d/*.sql; do
    if [ -f "$script" ]; then
        echo "Executando script: $script"
        /opt/mssql-tools/bin/sqlcmd -S localhost -U sa -P "$SA_PASSWORD" -i "$script"
    fi
done

# Executar scripts shell de inicialização
for script in /docker-entrypoint-initdb.d/*.sh; do
    if [ -f "$script" ] && [ "$script" != "/docker-entrypoint-initdb.d/entrypoint.sh" ]; then
        echo "Executando script shell: $script"
        bash "$script"
    fi
done

echo "Inicialização concluída. SQL Server pronto para uso."

# Manter o processo principal em execução
wait