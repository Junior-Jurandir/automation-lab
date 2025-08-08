# Script para visualizar logs - Windows PowerShell
# Autor: Automation Lab
# Versão: 1.0

param(
    [string]$Service = "",
    [switch]$Follow,
    [switch]$List,
    [switch]$Help,
    [int]$Tail = 50
)

# Função para mostrar ajuda
function Show-Help {
    Write-Host "Laboratório de Automação N8N - Visualizador de Logs" -ForegroundColor Blue
    Write-Host "====================================================" -ForegroundColor Blue
    Write-Host ""
    Write-Host "Uso: .\logs.ps1 [serviço] [opções]" -ForegroundColor White
    Write-Host ""
    Write-Host "Serviços disponíveis:" -ForegroundColor Yellow
    Write-Host "  n8n         Logs do N8N" -ForegroundColor White
    Write-Host "  postgres    Logs do PostgreSQL" -ForegroundColor White
    Write-Host "  sqlserver   Logs do SQL Server" -ForegroundColor White
    Write-Host "  redis       Logs do Redis" -ForegroundColor White
    Write-Host "  pgadmin     Logs do PgAdmin" -ForegroundColor White
    Write-Host "  adminer     Logs do Adminer" -ForegroundColor White
    Write-Host "  nginx       Logs do Nginx" -ForegroundColor White
    Write-Host "  all         Logs de todos os serviços" -ForegroundColor White
    Write-Host ""
    Write-Host "Opções:" -ForegroundColor Yellow
    Write-Host "  -Follow     Seguir logs em tempo real" -ForegroundColor White
    Write-Host "  -List       Listar status dos serviços" -ForegroundColor White
    Write-Host "  -Tail N     Mostrar últimas N linhas (padrão: 50)" -ForegroundColor White
    Write-Host "  -Help       Mostrar esta ajuda" -ForegroundColor White
    Write-Host ""
    Write-Host "Exemplos:" -ForegroundColor Yellow
    Write-Host "  .\logs.ps1 n8n              # Últimos logs do N8N" -ForegroundColor White
    Write-Host "  .\logs.ps1 n8n -Follow      # Seguir logs do N8N" -ForegroundColor White
    Write-Host "  .\logs.ps1 all -Follow      # Seguir todos os logs" -ForegroundColor White
    Write-Host "  .\logs.ps1 -List            # Listar status" -ForegroundColor White
    Write-Host "  .\logs.ps1 postgres -Tail 100  # 100 últimas linhas" -ForegroundColor White
    Write-Host ""
    Write-Host "Pressione Ctrl+C para sair do modo follow" -ForegroundColor Blue
    Write-Host ""
}

# Função para listar serviços e status
function Show-ServicesList {
    Write-Host "📋 Status dos Serviços:" -ForegroundColor Blue
    Write-Host "=======================" -ForegroundColor Blue
    Write-Host ""
    
    $services = @("n8n", "postgres", "sqlserver", "redis", "pgadmin", "adminer", "nginx")
    
    try {
        foreach ($service in $services) {
            $status = docker-compose ps $service 2>$null
            if ($status -match "Up") {
                Write-Host "  ✅ $service (rodando)" -ForegroundColor Green
            } elseif ($status -match "Exit") {
                Write-Host "  ❌ $service (parado)" -ForegroundColor Red
            } else {
                Write-Host "  ⚠️  $service (não encontrado)" -ForegroundColor Yellow
            }
        }
    } catch {
        Write-Host "❌ Erro ao verificar status dos serviços" -ForegroundColor Red
    }
    
    Write-Host ""
}

# Função para mostrar logs de um serviço específico
function Show-ServiceLogs {
    param(
        [string]$ServiceName,
        [bool]$FollowLogs = $false,
        [int]$TailLines = 50
    )
    
    try {
        # Verificar se o serviço existe
        $serviceStatus = docker-compose ps $ServiceName 2>$null
        if (!$serviceStatus) {
            Write-Host "❌ Serviço '$ServiceName' não encontrado." -ForegroundColor Red
            Show-ServicesList
            return
        }
        
        if ($FollowLogs) {
            Write-Host "📋 Seguindo logs do serviço: $ServiceName (Ctrl+C para sair)" -ForegroundColor Blue
            Write-Host "=============================================================" -ForegroundColor Blue
            docker-compose logs -f $ServiceName
        } else {
            Write-Host "📋 Últimas $TailLines linhas do serviço: $ServiceName" -ForegroundColor Blue
            Write-Host "=================================================" -ForegroundColor Blue
            docker-compose logs --tail=$TailLines $ServiceName
        }
    } catch {
        Write-Host "❌ Erro ao acessar logs do serviço '$ServiceName': $($_.Exception.Message)" -ForegroundColor Red
    }
}

# Função para mostrar logs de todos os serviços
function Show-AllLogs {
    param(
        [bool]$FollowLogs = $false,
        [int]$TailLines = 20
    )
    
    try {
        if ($FollowLogs) {
            Write-Host "📋 Seguindo logs de todos os serviços (Ctrl+C para sair)" -ForegroundColor Blue
            Write-Host "=========================================================" -ForegroundColor Blue
            docker-compose logs -f
        } else {
            Write-Host "📋 Últimas $TailLines linhas de todos os serviços" -ForegroundColor Blue
            Write-Host "=================================================" -ForegroundColor Blue
            docker-compose logs --tail=$TailLines
        }
    } catch {
        Write-Host "❌ Erro ao acessar logs: $($_.Exception.Message)" -ForegroundColor Red
    }
}

# Função para verificar se há containers rodando
function Test-ContainersRunning {
    try {
        $runningContainers = docker-compose ps --services --filter "status=running"
        return $runningContainers.Count -gt 0
    } catch {
        return $false
    }
}

# Função principal
function Main {
    if ($Help) {
        Show-Help
        return
    }
    
    if ($List) {
        Show-ServicesList
        return
    }
    
    # Verificar se docker-compose está disponível
    try {
        docker-compose --version | Out-Null
    } catch {
        Write-Host "❌ Docker Compose não está disponível" -ForegroundColor Red
        exit 1
    }
    
    # Verificar se há containers rodando
    if (!(Test-ContainersRunning)) {
        Write-Host "⚠️  Nenhum serviço está rodando." -ForegroundColor Yellow
        Write-Host "💡 Execute '.\scripts\start.ps1' para iniciar os serviços." -ForegroundColor Blue
        Show-ServicesList
        return
    }
    
    # Determinar qual serviço mostrar
    if ([string]::IsNullOrEmpty($Service) -or $Service -eq "all") {
        if ([string]::IsNullOrEmpty($Service)) {
            Write-Host "⚠️  Nenhum serviço especificado. Mostrando logs de todos os serviços." -ForegroundColor Yellow
        }
        Show-AllLogs -FollowLogs $Follow -TailLines $Tail
    } else {
        # Validar nome do serviço
        $validServices = @("n8n", "postgres", "sqlserver", "redis", "pgadmin", "adminer", "nginx")
        if ($validServices -contains $Service) {
            Show-ServiceLogs -ServiceName $Service -FollowLogs $Follow -TailLines $Tail
        } else {
            Write-Host "❌ Serviço '$Service' não é válido." -ForegroundColor Red
            Write-Host ""
            Write-Host "Serviços válidos: $($validServices -join ', ')" -ForegroundColor Yellow
            Write-Host ""
            Show-ServicesList
        }
    }
}

# Configurar tratamento de Ctrl+C para modo follow
$null = Register-EngineEvent PowerShell.Exiting -Action {
    Write-Host ""
    Write-Host "👋 Saindo do visualizador de logs..." -ForegroundColor Blue
}

# Executar função principal
try {
    Main
} catch {
    Write-Host ""
    Write-Host "❌ Erro inesperado: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "💡 Use '.\logs.ps1 -Help' para ver a ajuda" -ForegroundColor Blue
}