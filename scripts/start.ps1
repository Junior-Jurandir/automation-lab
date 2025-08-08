# Script de inicialização para Windows PowerShell
# Autor: Automation Lab
# Versão: 1.0

param(
    [switch]$Help
)

# Função para mostrar ajuda
function Show-Help {
    Write-Host "Laboratório de Automação N8N - Script de Inicialização" -ForegroundColor Blue
    Write-Host "======================================================" -ForegroundColor Blue
    Write-Host ""
    Write-Host "Uso: .\start.ps1 [opções]" -ForegroundColor White
    Write-Host ""
    Write-Host "Opções:" -ForegroundColor Yellow
    Write-Host "  -Help    Mostra esta ajuda" -ForegroundColor White
    Write-Host ""
    Write-Host "Exemplos:" -ForegroundColor Yellow
    Write-Host "  .\start.ps1           # Iniciar laboratório" -ForegroundColor White
    Write-Host "  .\start.ps1 -Help     # Mostrar ajuda" -ForegroundColor White
    Write-Host ""
}

# Função para verificar se Docker está rodando
function Test-DockerRunning {
    try {
        docker info | Out-Null
        return $true
    } catch {
        return $false
    }
}

# Função para criar diretórios necessários
function New-RequiredDirectories {
    Write-Host "📁 Criando diretórios necessários..." -ForegroundColor Blue
    
    $directories = @(
        "data\n8n",
        "data\postgres", 
        "data\sqlserver",
        "data\redis",
        "data\pgadmin",
        "logs\postgres",
        "logs\sqlserver", 
        "logs\nginx",
        "config\n8n"
    )
    
    foreach ($dir in $directories) {
        if (!(Test-Path $dir)) {
            New-Item -ItemType Directory -Path $dir -Force | Out-Null
            Write-Host "  ✅ Criado: $dir" -ForegroundColor Green
        }
    }
}

# Função para configurar arquivo .env
function Initialize-EnvironmentFile {
    if (!(Test-Path ".env")) {
        if (Test-Path ".env.example") {
            Copy-Item ".env.example" ".env"
            Write-Host "✅ Arquivo .env criado a partir do exemplo" -ForegroundColor Green
            Write-Host "⚠️  Edite o arquivo .env com suas configurações antes de continuar" -ForegroundColor Yellow
            
            $response = Read-Host "Deseja editar o arquivo .env agora? (s/N)"
            if ($response -eq "s" -or $response -eq "S") {
                notepad .env
                Write-Host "Pressione qualquer tecla após salvar o arquivo .env..." -ForegroundColor Yellow
                $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
            }
        } else {
            Write-Host "❌ Arquivo .env.example não encontrado!" -ForegroundColor Red
            exit 1
        }
    } else {
        Write-Host "✅ Arquivo .env já existe" -ForegroundColor Green
    }
}

# Função para iniciar serviços
function Start-Services {
    Write-Host "🚀 Iniciando serviços..." -ForegroundColor Blue
    
    try {
        # Construir e iniciar containers
        docker-compose build --no-cache
        docker-compose up -d
        
        Write-Host "✅ Serviços iniciados" -ForegroundColor Green
    } catch {
        Write-Host "❌ Erro ao iniciar serviços: $($_.Exception.Message)" -ForegroundColor Red
        exit 1
    }
}

# Função para verificar status dos serviços
function Test-ServicesHealth {
    Write-Host "🔍 Verificando status dos serviços..." -ForegroundColor Blue
    
    Start-Sleep -Seconds 10
    
    $services = @("postgres", "sqlserver", "redis", "n8n", "pgadmin", "adminer", "nginx")
    
    foreach ($service in $services) {
        $status = docker-compose ps $service
        if ($status -match "Up") {
            Write-Host "  ✅ $service está rodando" -ForegroundColor Green
        } else {
            Write-Host "  ❌ $service não está rodando" -ForegroundColor Red
        }
    }
}

# Função para mostrar informações de acesso
function Show-AccessInfo {
    Write-Host ""
    Write-Host "🌐 Informações de Acesso:" -ForegroundColor Blue
    Write-Host "=========================" -ForegroundColor Blue
    Write-Host ""
    Write-Host "N8N (Automação):" -ForegroundColor Yellow
    Write-Host "  URL: https://localhost" -ForegroundColor White
    Write-Host "  Usuário: admin" -ForegroundColor White
    Write-Host "  Senha: admin123" -ForegroundColor White
    Write-Host ""
    Write-Host "PgAdmin (PostgreSQL):" -ForegroundColor Yellow
    Write-Host "  URL: http://localhost:8080" -ForegroundColor White
    Write-Host "  Email: admin@automation.local" -ForegroundColor White
    Write-Host "  Senha: admin123" -ForegroundColor White
    Write-Host ""
    Write-Host "Adminer (Universal DB):" -ForegroundColor Yellow
    Write-Host "  URL: http://localhost:8081" -ForegroundColor White
    Write-Host ""
    Write-Host "PostgreSQL:" -ForegroundColor Yellow
    Write-Host "  Host: localhost" -ForegroundColor White
    Write-Host "  Porta: 5432" -ForegroundColor White
    Write-Host "  Usuário: postgres" -ForegroundColor White
    Write-Host "  Senha: postgres123" -ForegroundColor White
    Write-Host ""
    Write-Host "SQL Server:" -ForegroundColor Yellow
    Write-Host "  Host: localhost" -ForegroundColor White
    Write-Host "  Porta: 1433" -ForegroundColor White
    Write-Host "  Usuário: sa" -ForegroundColor White
    Write-Host "  Senha: SqlServer123!" -ForegroundColor White
    Write-Host ""
    Write-Host "Redis:" -ForegroundColor Yellow
    Write-Host "  Host: localhost" -ForegroundColor White
    Write-Host "  Porta: 6379" -ForegroundColor White
    Write-Host "  Senha: redis123" -ForegroundColor White
    Write-Host ""
    Write-Host "📝 Para parar os serviços: .\scripts\stop.ps1" -ForegroundColor Blue
    Write-Host "📝 Para ver logs: .\scripts\logs.ps1" -ForegroundColor Blue
}

# Função principal
function Main {
    if ($Help) {
        Show-Help
        return
    }
    
    Write-Host "🔧 Iniciando Laboratório de Automação N8N" -ForegroundColor Blue
    Write-Host "==========================================" -ForegroundColor Blue
    Write-Host ""
    
    # Verificar se Docker está rodando
    if (!(Test-DockerRunning)) {
        Write-Host "❌ Docker não está rodando. Por favor, inicie o Docker Desktop primeiro." -ForegroundColor Red
        Write-Host "💡 Aguarde o Docker Desktop inicializar completamente antes de tentar novamente." -ForegroundColor Yellow
        exit 1
    }
    Write-Host "✅ Docker está rodando" -ForegroundColor Green
    
    # Verificar se docker-compose está disponível
    try {
        docker-compose --version | Out-Null
        Write-Host "✅ Docker Compose está disponível" -ForegroundColor Green
    } catch {
        Write-Host "❌ Docker Compose não está disponível" -ForegroundColor Red
        exit 1
    }
    
    # Criar diretórios necessários
    New-RequiredDirectories
    
    # Configurar arquivo .env
    Initialize-EnvironmentFile
    
    # Iniciar serviços
    Start-Services
    
    # Verificar status
    Test-ServicesHealth
    
    Write-Host ""
    Write-Host "🎉 Laboratório iniciado com sucesso!" -ForegroundColor Green
    
    # Mostrar informações de acesso
    Show-AccessInfo
}

# Executar função principal
Main