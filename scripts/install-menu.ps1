# =============================================================================
# Sistema de Menu Interativo para Instalação Seletiva de Containers (Windows)
# =============================================================================
# Este script permite escolher quais containers serão instalados
# Uso: .\scripts\install-menu.ps1

# Configuração de erro
$ErrorActionPreference = "Stop"

# Cores para output
$RED = "`e[31m"
$GREEN = "`e[32m"
$YELLOW = "`e[33m"
$BLUE = "`e[34m"
$NC = "`e[0m"

# Diretórios
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$ProjectRoot = Split-Path -Parent $ScriptDir
$ComposeFile = Join-Path $ProjectRoot "docker-compose.yml"
$ComposeCustom = Join-Path $ProjectRoot "docker-compose.custom.yml"

# Serviços disponíveis
$Services = @{
    "n8n" = "Plataforma de Automação (requer PostgreSQL)"
    "postgres" = "Banco de dados PostgreSQL"
    "sqlserver" = "Banco de dados SQL Server"
    "nginx" = "Proxy reverso Nginx (requer n8n)"
    "pgadmin" = "Interface web PostgreSQL (requer postgres)"
    "adminer" = "Interface web universal para DB"
    "redis" = "Cache e message broker"
}

# Dependências entre serviços
$Dependencies = @{
    "n8n" = @("postgres")
    "nginx" = @("n8n")
    "pgadmin" = @("postgres")
}

# Estado dos serviços
$ServiceState = @{}
foreach ($service in $Services.Keys) {
    $ServiceState[$service] = $false
}

# Função para limpar tela
function Clear-Screen {
    Clear-Host
}

# Função para exibir cabeçalho
function Show-Header {
    Write-Host $BLUE
    Write-Host "╔══════════════════════════════════════════════════════════════╗"
    Write-Host "║              Instalação Seletiva de Containers               ║"
    Write-Host "║                    Automation Lab Platform                   ║"
    Write-Host "╚══════════════════════════════════════════════════════════════╝"
    Write-Host $NC
}

# Função para exibir menu de serviços
function Show-ServicesMenu {
    Write-Host $YELLOW"Selecione os containers que deseja instalar:"$NC
    Write-Host ""
    
    $index = 1
    foreach ($service in $Services.Keys) {
        $status = "[ ]"
        if ($ServiceState[$service]) {
            $status = "[✓]"
        }
        
        $description = $Services[$service]
        $dependency = ""
        if ($Dependencies.ContainsKey($service)) {
            $dependency = " (requer $($Dependencies[$service] -join ', '))"
        }
        
        Write-Host "$GREEN$index$NC) $status $service$NC - $description$YELLOW$dependency$NC"
        $index++
    }
    
    Write-Host ""
    Write-Host $BLUE"Opções:"$NC
    Write-Host "  $GREEN 1-7$NC - Alternar serviço"
    Write-Host "  $GREEN a$NC   - Selecionar todos"
    Write-Host "  $GREEN n$NC   - Selecionar nenhum"
    Write-Host "  $GREEN c$NC   - Continuar com seleção atual"
    Write-Host "  $GREEN q$NC   - Sair"
}

# Função para alternar serviço
function Toggle-Service {
    param($ServiceName)
    
    $currentState = $ServiceState[$ServiceName]
    
    if (-not $currentState) {
        # Ativando serviço - verificar dependências
        if ($Dependencies.ContainsKey($ServiceName)) {
            foreach ($dep in $Dependencies[$ServiceName]) {
                if (-not $ServiceState[$dep]) {
                    Write-Host $RED"Erro: $ServiceName requer $dep que não está selecionado"$NC
                    $response = Read-Host "Deseja ativar $dep também? (s/n)"
                    if ($response -eq "s" -or $response -eq "S") {
                        $ServiceState[$dep] = $true
                        Write-Host $GREEN"$dep ativado automaticamente"$NC
                    } else {
                        return $false
                    }
                }
            }
        }
    }
    
    $ServiceState[$ServiceName] = -not $currentState
    return $true
}

# Função para selecionar todos
function Select-All {
    foreach ($service in $Services.Keys) {
        $ServiceState[$service] = $true
    }
}

# Função para selecionar nenhum
function Select-None {
    foreach ($service in $Services.Keys) {
        $ServiceState[$service] = $false
    }
}

# Função para validar seleção
function Validate-Selection {
    $hasSelected = $false
    
    foreach ($service in $Services.Keys) {
        if ($ServiceState[$service]) {
            $hasSelected = $true
            break
        }
    }
    
    if (-not $hasSelected) {
        Write-Host $RED"Erro: Nenhum serviço selecionado"$NC
        return $false
    }
    
    # Verificar dependências críticas
    foreach ($service in $Services.Keys) {
        if ($ServiceState[$service]) {
            if ($Dependencies.ContainsKey($service)) {
                foreach ($dep in $Dependencies[$service]) {
                    if (-not $ServiceState[$dep]) {
                        Write-Host $RED"Erro: $service requer $dep que não está selecionado"$NC
                        return $false
                    }
                }
            }
        }
    }
    
    return $true
}

# Função para gerar docker-compose personalizado
function Generate-CustomCompose {
    Write-Host $GREEN"Gerando docker-compose.custom.yml..."$NC
    
    $content = @"
version: '3.8'

# Docker Compose personalizado gerado pelo menu de instalação
# Serviços selecionados: $($ServiceState.Keys | Where-Object { $ServiceState[$_] } -join ', ')

services:
"@

    # Ler o docker-compose original
    $originalContent = Get-Content $ComposeFile -Raw
    
    # Extrair serviços selecionados
    foreach ($service in $Services.Keys) {
        if ($ServiceState[$service]) {
            # Extrair seção do serviço
            $pattern = "(?ms)^  $service:.*?^(?=  [^ ]|\z)"
            $match = [regex]::Match($originalContent, $pattern)
            if ($match.Success) {
                $content += "`n" + $match.Value
            }
        }
    }
    
    # Adicionar networks e volumes base
    $content += @"

networks:
  automation-network:
    driver: bridge
    ipam:
      config:
        - subnet: 172.20.0.0/16

volumes:
  postgres_data:
  sqlserver_data:
  n8n_data:
  redis_data:
  pgadmin_data:
"@

    Set-Content -Path $ComposeCustom -Value $content
    
    Write-Host $GREEN"Arquivo docker-compose.custom.yml gerado com sucesso!"$NC
}

# Função principal do menu
function Main-Menu {
    Clear-Screen
    
    while ($true) {
        Show-Header
        Show-ServicesMenu
        
        Write-Host ""
        $choice = Read-Host "Escolha uma opção"
        
        switch ($choice) {
            { $_ -match '^[1-7]$' } {
                $index = 1
                foreach ($service in $Services.Keys) {
                    if ($index -eq [int]$choice) {
                        Toggle-Service $service
                        break
                    }
                    $index++
                }
            }
            { $_ -eq 'a' -or $_ -eq 'A' } {
                Select-All
            }
            { $_ -eq 'n' -or $_ -eq 'N' } {
                Select-None
            }
            { $_ -eq 'c' -or $_ -eq 'C' } {
                if (Validate-Selection) {
                    break
                } else {
                    Read-Host "Pressione Enter para continuar..."
                }
            }
            { $_ -eq 'q' -or $_ -eq 'Q' } {
                Write-Host $YELLOW"Instalação cancelada pelo usuário"$NC
                exit 0
            }
            default {
                Write-Host $RED"Opção inválida"$NC
                Start-Sleep -Seconds 1
            }
        }
    }
    
    # Mostrar resumo
    Clear-Screen
    Show-Header
    Write-Host $GREEN"Resumo da instalação:"$NC
    Write-Host ""
    
    foreach ($service in $Services.Keys) {
        if ($ServiceState[$service]) {
            Write-Host "  $GREEN✓$NC $service"
        }
    }
    
    $response = Read-Host "Deseja continuar com esta configuração? (s/n)"
    
    if ($response -ne "s" -and $response -ne "S") {
        Write-Host $YELLOW"Instalação cancelada pelo usuário"$NC
        exit 0
    }
    
    Generate-CustomCompose
    
    Write-Host ""
    Write-Host $GREEN"Configuração concluída!"$NC
    Write-Host "Para iniciar os containers, execute: $YELLOW docker-compose -f docker-compose.custom.yml up -d"$NC
}

# Executar menu
Main-Menu
