FROM postgres:15

# Instalar extensões adicionais
RUN apt-get update && apt-get install -y \
    postgresql-contrib \
    postgresql-15-postgis-3 \
    postgresql-15-postgis-3-scripts \
    postgresql-plpython3-15 \
    && rm -rf /var/lib/apt/lists/*

# Copiar scripts de inicialização
COPY init/ /docker-entrypoint-initdb.d/

# Definir permissões
RUN chmod +x /docker-entrypoint-initdb.d/*.sh

# Configurações personalizadas
ENV POSTGRES_INITDB_ARGS="--encoding=UTF-8 --locale=pt_BR.UTF-8"
ENV POSTGRES_HOST_AUTH_METHOD=md5

# Expor porta
EXPOSE 5432