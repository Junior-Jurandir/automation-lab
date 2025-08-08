FROM n8nio/n8n:latest

# Tornar-se root para realizar operações privilegiadas
USER root

# Fixar repositórios para estabilidade
RUN echo "https://dl-cdn.alpinelinux.org/alpine/v3.22/main" > /etc/apk/repositories && \
    echo "https://dl-cdn.alpinelinux.org/alpine/v3.22/community" >> /etc/apk/repositories


# Instalar dependências essenciais (evitando build-base completo)
RUN apk add --no-cache \
    curl \
    wget \
    git \
    python3 \
    py3-pip \
    py3-virtualenv \
    python3-dev \
    libffi-dev \
    openssl-dev \
    gcc \
    musl-dev \
    libc-dev

# Criar e ativar ambiente virtual
ENV VIRTUAL_ENV=/venv
RUN python3 -m venv $VIRTUAL_ENV
ENV PATH="$VIRTUAL_ENV/bin:$PATH"

# Instalar pacotes Python úteis
RUN pip install --no-cache-dir \
    requests \
    pandas \
    openpyxl \
    xlsxwriter \
    beautifulsoup4 \
    lxml \
    Pillow \
    python-dateutil \
    pytz

# Instalar pacotes Node.js úteis
RUN npm install -g \
    moment \
    lodash \
    axios \
    cheerio \
    csv-parser \
    xlsx

# Criar e ajustar permissões dos diretórios
RUN mkdir -p /home/node/logs /home/node/config /home/node/custom-nodes && \
    chown -R node:node /home/node/logs /home/node/config /home/node/custom-nodes

# Voltar para o usuário padrão do container
USER node

# Variáveis de ambiente do n8n
ENV N8N_USER_FOLDER=/home/node/.n8n
ENV N8N_LOG_LEVEL=info
ENV N8N_LOG_OUTPUT=console,file

EXPOSE 5678

CMD ["n8n", "start"]
