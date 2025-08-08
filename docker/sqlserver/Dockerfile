FROM mcr.microsoft.com/mssql/server:2022-latest

USER root

RUN apt-get update && apt-get install -y \
    curl \
    wget \
    unzip \
    gnupg \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

RUN curl https://packages.microsoft.com/keys/microsoft.asc | apt-key add - \
    && curl https://packages.microsoft.com/config/ubuntu/20.04/prod.list > /etc/apt/sources.list.d/msprod.list \
    && apt-get update \
    && ACCEPT_EULA=Y apt-get install -y mssql-tools unixodbc-dev \
       -o Dpkg::Options::="--force-overwrite" \
    && echo 'export PATH="$PATH:/opt/mssql-tools/bin"' >> ~/.bashrc

ENV PATH="$PATH:/opt/mssql-tools/bin"

RUN mkdir -p /docker-entrypoint-initdb.d /var/opt/mssql/log

COPY init/ /docker-entrypoint-initdb.d/
COPY entrypoint.sh /usr/local/bin/

RUN chmod +x /usr/local/bin/entrypoint.sh && \
    find /docker-entrypoint-initdb.d -type f -name "*.sh" -exec chmod +x {} \;

USER mssql

EXPOSE 1433

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]