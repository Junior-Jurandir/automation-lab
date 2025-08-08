# 🪟 Instruções para Windows

Este documento fornece instruções específicas para executar o laboratório de automação N8N no Windows.

## 📋 Pré-requisitos para Windows

### Docker Desktop
1. **Instale o Docker Desktop**: https://www.docker.com/products/docker-desktop
2. **Configure WSL2** (recomendado):
   - Instale WSL2: `wsl --install`
   - Configure Docker para usar WSL2
3. **Verifique a instalação**:
   ```powershell
   docker --version
   docker-compose --version
   ```

### PowerShell ou Git Bash
- **PowerShell 5.1+** (já incluído no Windows)
- **Git Bash** (recomendado): https://git-scm.com/download/win
- **Windows Terminal** (opcional): https://aka.ms/terminal

## 🚀 Instalação no Windows

### Opção 1: PowerShell (Recomendado)

```powershell
# 1. Clone ou baixe o projeto
git clone <repository-url>
cd automation-lab

# 2. Copie o arquivo de configuração
Copy-Item .env.example .env

# 3. Edite o arquivo .env (use notepad ou seu editor preferido)
notepad .env

# 4. Inicie o laboratório
docker-compose up -d
```

### Opção 2: Git Bash (Linux-like)

```bash
# 1. Clone o projeto
git clone <repository-url>
cd automation-lab

# 2. Torne os scripts executáveis
chmod +x scripts/*.sh

# 3. Configure e inicie
cp .env.example .env
./scripts/start.sh
```

## 🛠 Comandos para Windows

### PowerShell

```powershell
# Iniciar laboratório
docker-compose up -d

# Parar laboratório
docker-compose down

# Ver logs
docker-compose logs -f

# Ver status
docker-compose ps

# Backup (manual)
docker-compose exec postgres pg_dumpall -U postgres > backup.sql

# Limpar tudo (CUIDADO!)
docker-compose down -v
```

### Usando Make no Windows

Se você tem `make` instalado (via Chocolatey, Scoop, ou WSL):

```powershell
# Instalar make via Chocolatey
choco install make

# Usar comandos make
make start
make stop
make logs
```

### Scripts PowerShell Equivalentes

Crie estes arquivos `.ps1` na pasta `scripts/`:

#### `scripts/start.ps1`
```powershell
# Script de inicialização para Windows
Write-Host "🔧 Iniciando Laboratório de Automação N8N" -ForegroundColor Blue

# Verificar se Docker está rodando
try {
    docker info | Out-Null
    Write-Host "✅ Docker está rodando" -ForegroundColor Green
} catch {
    Write-Host "❌ Docker não está rodando. Inicie o Docker Desktop primeiro." -ForegroundColor Red
    exit 1
}

# Criar diretórios necessários
$directories = @("data/n8n", "data/postgres", "data/sqlserver", "data/redis", "data/pgadmin", "logs", "config/n8n")
foreach ($dir in $directories) {
    if (!(Test-Path $dir)) {
        New-Item -ItemType Directory -Path $dir -Force | Out-Null
        Write-Host "✅ Criado: $dir" -ForegroundColor Green
    }
}

# Copiar .env se não existir
if (!(Test-Path ".env")) {
    Copy-Item ".env.example" ".env"
    Write-Host "✅ Arquivo .env criado" -ForegroundColor Green
    Write-Host "⚠️  Edite o arquivo .env com suas configurações" -ForegroundColor Yellow
}

# Iniciar serviços
Write-Host "🚀 Iniciando serviços..." -ForegroundColor Blue
docker-compose up -d

# Aguardar e verificar status
Start-Sleep -Seconds 10
docker-compose ps

Write-Host "🎉 Laboratório iniciado com sucesso!" -ForegroundColor Green
Write-Host "🌐 Acesse: https://localhost (N8N)" -ForegroundColor Yellow
```

#### `scripts/stop.ps1`
```powershell
# Script para parar o laboratório
param(
    [switch]$Remove,
    [switch]$Clean
)

Write-Host "🛑 Parando laboratório..." -ForegroundColor Blue

if ($Clean) {
    Write-Host "⚠️  ATENÇÃO: Esta operação irá apagar todos os dados!" -ForegroundColor Red
    $confirm = Read-Host "Tem certeza? Digite 'yes' para confirmar"
    if ($confirm -eq "yes") {
        docker-compose down -v
        Write-Host "✅ Containers e volumes removidos" -ForegroundColor Green
    } else {
        Write-Host "❌ Operação cancelada" -ForegroundColor Red
    }
} elseif ($Remove) {
    docker-compose down
    Write-Host "✅ Containers removidos" -ForegroundColor Green
} else {
    docker-compose stop
    Write-Host "✅ Serviços parados" -ForegroundColor Green
}
```

#### `scripts/logs.ps1`
```powershell
# Script para ver logs
param(
    [string]$Service = "all",
    [switch]$Follow
)

if ($Service -eq "all") {
    if ($Follow) {
        docker-compose logs -f
    } else {
        docker-compose logs --tail=50
    }
} else {
    if ($Follow) {
        docker-compose logs -f $Service
    } else {
        docker-compose logs --tail=50 $Service
    }
}
```

## 🔧 Configurações Específicas do Windows

### Variáveis de Ambiente (.env)
```env
# Usar barras normais, não invertidas
DATA_PATH=./data
LOGS_PATH=./logs
CONFIG_PATH=./config

# Timezone para Windows
TIMEZONE=America/Sao_Paulo
```

### Permissões de Arquivo
No Windows, as permissões são gerenciadas diferentemente:

```powershell
# Dar permissões completas para o usuário atual
icacls data /grant "$env:USERNAME:(OI)(CI)F" /T
icacls logs /grant "$env:USERNAME:(OI)(CI)F" /T
```

### Firewall do Windows
Certifique-se de que as portas estão liberadas:

```powershell
# Liberar portas no firewall (execute como Administrador)
New-NetFirewallRule -DisplayName "N8N" -Direction Inbound -Port 5678 -Protocol TCP -Action Allow
New-NetFirewallRule -DisplayName "PostgreSQL" -Direction Inbound -Port 5432 -Protocol TCP -Action Allow
New-NetFirewallRule -DisplayName "SQL Server" -Direction Inbound -Port 1433 -Protocol TCP -Action Allow
New-NetFirewallRule -DisplayName "PgAdmin" -Direction Inbound -Port 8080 -Protocol TCP -Action Allow
New-NetFirewallRule -DisplayName "Adminer" -Direction Inbound -Port 8081 -Protocol TCP -Action Allow
```

## 🐛 Troubleshooting Windows

### Problemas Comuns

#### Docker não inicia
```powershell
# Verificar se Docker Desktop está rodando
Get-Process "Docker Desktop" -ErrorAction SilentlyContinue

# Reiniciar Docker Desktop
Stop-Process -Name "Docker Desktop" -Force
Start-Process "C:\Program Files\Docker\Docker\Docker Desktop.exe"
```

#### Problemas de permissão
```powershell
# Executar PowerShell como Administrador
Start-Process powershell -Verb runAs

# Verificar permissões
Get-Acl data | Format-List
```

#### Portas em uso
```powershell
# Verificar porta em uso
netstat -ano | findstr :5678

# Matar processo na porta
taskkill /PID <PID> /F
```

#### Problemas de rede
```powershell
# Resetar rede Docker
docker network prune -f
docker-compose down
docker-compose up -d
```

### Logs Detalhados
```powershell
# Ver logs do Docker Desktop
Get-Content "$env:APPDATA\Docker\log.txt" -Tail 50

# Ver logs específicos
docker-compose logs n8n --tail=100
```

## 📁 Estrutura de Arquivos Windows

```
automation-lab\
├── docker\
│   ├── n8n\
│   ├── postgres\
│   ├── sqlserver\
│   └── nginx\
├── data\           # Dados persistentes
├── logs\           # Logs dos serviços
├── config\         # Configurações
├── scripts\        # Scripts PowerShell
│   ├── start.ps1
│   ├── stop.ps1
│   └── logs.ps1
├── backups\        # Backups
├── docker-compose.yml
├── .env
└── README.md
```

## 🔒 Antivírus e Segurança

### Windows Defender
Adicione exclusões para melhor performance:

```powershell
# Adicionar exclusões (execute como Administrador)
Add-MpPreference -ExclusionPath "C:\Users\$env:USERNAME\automation-lab"
Add-MpPreference -ExclusionProcess "docker.exe"
Add-MpPreference -ExclusionProcess "dockerd.exe"
```

### Hyper-V
Certifique-se de que o Hyper-V está habilitado:

```powershell
# Verificar se Hyper-V está habilitado
Get-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V-All

# Habilitar Hyper-V (requer reinicialização)
Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V -All
```

## 🚀 Comandos Rápidos

### Arquivo batch para inicialização rápida (`start.bat`)
```batch
@echo off
echo Iniciando Laboratorio de Automacao N8N...
docker-compose up -d
echo.
echo Laboratorio iniciado!
echo Acesse: https://localhost
pause
```

### Arquivo batch para parar (`stop.bat`)
```batch
@echo off
echo Parando laboratorio...
docker-compose down
echo Laboratorio parado!
pause
```

## 📝 Notas Importantes

1. **WSL2**: Recomendado para melhor performance
2. **Recursos**: Reserve pelo menos 4GB RAM para Docker
3. **Espaço**: Certifique-se de ter pelo menos 10GB livres
4. **Updates**: Mantenha Docker Desktop atualizado
5. **Backup**: Use ferramentas nativas do Windows para backup

## 🆘 Suporte Windows

- **Docker Desktop Issues**: https://github.com/docker/for-win/issues
- **WSL2 Issues**: https://github.com/microsoft/WSL/issues
- **PowerShell Help**: `Get-Help docker-compose`

---

**Desenvolvido para funcionar perfeitamente no Windows! 🪟**