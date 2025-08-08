FROM nginx:alpine

# Instalar certificados SSL e ferramentas
RUN apk add --no-cache \
    openssl \
    curl \
    && rm -rf /var/cache/apk/*

# Criar diretório para certificados SSL
RUN mkdir -p /etc/nginx/ssl

# Gerar certificado SSL auto-assinado para desenvolvimento
RUN openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
    -keyout /etc/nginx/ssl/nginx.key \
    -out /etc/nginx/ssl/nginx.crt \
    -subj "/C=BR/ST=SP/L=SaoPaulo/O=AutomationLab/CN=localhost"

# Copiar configuração personalizada
COPY nginx.conf /etc/nginx/nginx.conf

# Expor portas
EXPOSE 80 443

# Comando de inicialização
CMD ["nginx", "-g", "daemon off;"]