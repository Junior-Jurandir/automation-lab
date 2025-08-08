# Script para parar o laboratório - Windows PowerShell
# Autor: Automation Lab
# Versão: 1.0

param(
    [switch]$Remove,
    [switch]$Clean,
    [switch]$Help
)

# Função para mostrar ajuda
function Show-Help {
    Write-Host "Laboratório de Automação N8N - Script de Parada" -ForegroundColor Blue
    Write-Host "================================================" -ForegroundColor Blue
    Write-Host ""
    Write-Host "Uso: .\stop.ps1 [opções]" -ForegroundColor White
    Write-Host ""
    Write-Host "Opções:" -ForegroundColor Yellow
    Write-Host "  -Remove    Remove os containers após parar" -ForegroundColor White
    Write-Host "  -Clean     Remove containers e volumes (CUIDADO: dados serão perdidos)" -ForegroundColor White
    Write-Host "  -Help      Mostra esta ajuda" -ForegroundColor White
    Write-Host ""
    Write-Host "Exemplos:" -ForegroundColor Yellow
    Write-Host "  .\stop.ps1           # Apenas parar serviços" -ForegroundColor White
    Write-Host "  .\stop.ps1 -Remove   # Parar e remover containers" -ForegroundColor White
    Write-Host "  .\stop.ps1 -Clean    # Parar e limpar tudo (CUIDADO!)" -ForegroundColor White
    Write-Host ""
}

# Função para parar serviços
function Stop-Services {
    Write-Host "🛑 Parando serviços..." -ForegroundColor Blue
    
    try {
        $runningServices = docker-compose ps --services --filter "status=running"
        if ($runningServices) {
            docker-compose stop
            Write-Host "✅ Serviços parados" -ForegroundColor Green
        } else {
            Write-Host "⚠️  Nenhum serviço estava rodando" -ForegroundColor Yellow
        }
    } catch {
        Write-Host "❌ Erro ao parar serviços: $($_.Exception.Message)" -ForegroundColor Red
    }
}

# Função para remover containers
function Remove-Containers {
    Write-Host "🗑️  Removendo containers..." -ForegroundColor Blue
    
    try {
        docker-compose down
        Write-Host "✅ Containers removidos" -ForegroundColor Green
    } catch {
        Write-Host "❌ Erro ao remover containers: $($_.Exception.Message)" -ForegroundColor Red
    }
}

# Função para limpar volumes
function Remove-Volumes {
    Write-Host "⚠️  ATENÇÃO: Removendo volumes (dados serão perdidos)..." -ForegroundColor Red
    Write-Host ""
    Write-Host "Esta operação irá apagar TODOS os dados dos bancos de dados," -ForegroundColor Red
    Write-Host "workflows do N8N, configurações e logs!" -ForegroundColor Red
    Write-Host ""
    
    $confirmation = Read-Host "Tem certeza? Digite 'yes' para confirmar"
    
    if ($confirmation -eq "yes") {
        try {
            docker-compose down -v
            Write-Host "✅ Volumes removidos" -ForegroundColor Green
            
            # Remover também diretórios locais se existirem
            $dataDirectories = @("data", "logs")
            foreach ($dir in $dataDirectories) {
                if (Test-Path $dir) {
                    $removeLocal = Read-Host "Remover também diretório local '$dir'? (s/N)"
                    if ($removeLocal -eq "s" -or $removeLocal -eq "S") {
                        Remove-Item -Path $dir -Recurse -Force
                        Write-Host "✅ Diretório '$dir' removido" -ForegroundColor Green
                    }
                }
            }
        } catch {
            Write-Host "❌ Erro ao remover volumes: $($_.Exception.Message)" -ForegroundColor Red
        }
    } else {
        Write-Host "❌ Operação cancelada" -ForegroundColor Yellow
    }
}

# Função para verificar status após operação
function Show-Status {
    Write-Host ""
    Write-Host "📊 Status atual:" -ForegroundColor Blue
    
    try {
        $containers = docker-compose ps
        if ($containers -match "Up") {
            Write-Host "Alguns containers ainda estão rodando:" -ForegroundColor Yellow
            docker-compose ps
        } else {
            Write-Host "✅ Nenhum container está rodando" -ForegroundColor Green
        }
    } catch {
        Write-Host "✅ Nenhum container encontrado" -ForegroundColor Green
    }
}

# Função principal
function Main {
    if ($Help) {
        Show-Help
        return
    }
    
    # Verificar se docker-compose está disponível
    try {
        docker-compose --version | Out-Null
    } catch {
        Write-Host "❌ Docker Compose não está disponível" -ForegroundColor Red
        exit 1
    }
    
    if ($Clean) {
        Write-Host "🔧 Parando e limpando laboratório..." -ForegroundColor Blue
        Write-Host "====================================" -ForegroundColor Blue
        Stop-Services
        Remove-Volumes
    } elseif ($Remove) {
        Write-Host "🔧 Parando e removendo containers..." -ForegroundColor Blue
        Write-Host "====================================" -ForegroundColor Blue
        Stop-Services
        Remove-Containers
    } else {
        Write-Host "🔧 Parando laboratório..." -ForegroundColor Blue
        Write-Host "=========================" -ForegroundColor Blue
        Stop-Services
    }
    
    Show-Status
    
    Write-Host ""
    Write-Host "✅ Operação concluída!" -ForegroundColor Green
    
    if (!$Clean -and !$Remove) {
        Write-Host ""
        Write-Host "💡 Para iniciar novamente: .\scripts\start.ps1" -ForegroundColor Blue
        Write-Host "💡 Para remover containers: .\scripts\stop.ps1 -Remove" -ForegroundColor Blue
        Write-Host "💡 Para limpar tudo: .\scripts\stop.ps1 -Clean" -ForegroundColor Blue
    }
}

# Executar função principal
Main