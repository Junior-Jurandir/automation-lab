-- Script de inicialização para SQL Server
-- Criar bancos de dados para automação

USE master;
GO

-- Criar banco de dados para N8N (se necessário)
IF NOT EXISTS (SELECT name FROM sys.databases WHERE name = 'N8N_DB')
BEGIN
    CREATE DATABASE N8N_DB;
    PRINT 'Banco de dados N8N_DB criado com sucesso.';
END
GO

-- Criar banco de dados para automações
IF NOT EXISTS (SELECT name FROM sys.databases WHERE name = 'AutomationDB')
BEGIN
    CREATE DATABASE AutomationDB;
    PRINT 'Banco de dados AutomationDB criado com sucesso.';
END
GO

-- Criar banco de dados de teste
IF NOT EXISTS (SELECT name FROM sys.databases WHERE name = 'TestDB')
BEGIN
    CREATE DATABASE TestDB;
    PRINT 'Banco de dados TestDB criado com sucesso.';
END
GO

-- Configurar banco AutomationDB
USE AutomationDB;
GO

-- Criar schema para automações
IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = 'automation')
BEGIN
    EXEC('CREATE SCHEMA automation');
    PRINT 'Schema automation criado com sucesso.';
END
GO

-- Criar tabela de exemplo para logs de automação
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'automation_logs')
BEGIN
    CREATE TABLE automation.automation_logs (
        id BIGINT IDENTITY(1,1) PRIMARY KEY,
        workflow_id NVARCHAR(255) NOT NULL,
        execution_id NVARCHAR(255) NOT NULL,
        status NVARCHAR(50) NOT NULL,
        message NVARCHAR(MAX),
        data NVARCHAR(MAX),
        created_at DATETIME2 DEFAULT GETDATE(),
        updated_at DATETIME2 DEFAULT GETDATE()
    );
    
    -- Criar índices
    CREATE INDEX IX_automation_logs_workflow_id ON automation.automation_logs(workflow_id);
    CREATE INDEX IX_automation_logs_execution_id ON automation.automation_logs(execution_id);
    CREATE INDEX IX_automation_logs_status ON automation.automation_logs(status);
    CREATE INDEX IX_automation_logs_created_at ON automation.automation_logs(created_at);
    
    PRINT 'Tabela automation_logs criada com sucesso.';
END
GO

-- Criar tabela para configurações
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'automation_config')
BEGIN
    CREATE TABLE automation.automation_config (
        id BIGINT IDENTITY(1,1) PRIMARY KEY,
        config_key NVARCHAR(255) NOT NULL UNIQUE,
        config_value NVARCHAR(MAX),
        description NVARCHAR(500),
        is_active BIT DEFAULT 1,
        created_at DATETIME2 DEFAULT GETDATE(),
        updated_at DATETIME2 DEFAULT GETDATE()
    );
    
    -- Inserir configurações padrão
    INSERT INTO automation.automation_config (config_key, config_value, description) VALUES
    ('max_retry_attempts', '3', 'Número máximo de tentativas para automações'),
    ('default_timeout', '300', 'Timeout padrão em segundos'),
    ('log_retention_days', '30', 'Dias para manter logs de automação'),
    ('notification_email', 'admin@automation.local', 'Email para notificações');
    
    PRINT 'Tabela automation_config criada e populada com sucesso.';
END
GO

-- Criar usuário para automações (opcional)
IF NOT EXISTS (SELECT * FROM sys.server_principals WHERE name = 'automation_user')
BEGIN
    CREATE LOGIN automation_user WITH PASSWORD = 'AutoUser123!';
    PRINT 'Login automation_user criado com sucesso.';
END
GO

USE AutomationDB;
GO

IF NOT EXISTS (SELECT * FROM sys.database_principals WHERE name = 'automation_user')
BEGIN
    CREATE USER automation_user FOR LOGIN automation_user;
    ALTER ROLE db_datareader ADD MEMBER automation_user;
    ALTER ROLE db_datawriter ADD MEMBER automation_user;
    GRANT EXECUTE ON SCHEMA::automation TO automation_user;
    PRINT 'Usuário automation_user criado e configurado com sucesso.';
END
GO

PRINT 'Inicialização do SQL Server concluída com sucesso!';
GO