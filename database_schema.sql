CREATE DATABASE FintechWalletDB;
GO
USE FintechWalletDB;
GO

CREATE TABLE Wallets (
    WalletId UNIQUEIDENTIFIER PRIMARY KEY DEFAULT NEWID(),
    CustomerName NVARCHAR(100) NOT NULL,
    Balance DECIMAL(18, 2) NOT NULL DEFAULT 0.00,
    Currency NVARCHAR(3) DEFAULT 'TRY',
    CreatedAt DATETIME DEFAULT GETDATE()
);
GO

CREATE TABLE Transactions (
    TransactionId UNIQUEIDENTIFIER PRIMARY KEY DEFAULT NEWID(),
    SenderWalletId UNIQUEIDENTIFIER NOT NULL FOREIGN KEY REFERENCES Wallets(WalletId),
    ReceiverWalletId UNIQUEIDENTIFIER NOT NULL FOREIGN KEY REFERENCES Wallets(WalletId),
    Amount DECIMAL(18, 2) NOT NULL,
    TransactionStatus NVARCHAR(20) DEFAULT 'PENDING',
    CreatedAt DATETIME DEFAULT GETDATE()
);
GO

CREATE TABLE AuditLogs (
    LogId UNIQUEIDENTIFIER PRIMARY KEY DEFAULT NEWID(),
    TransactionId UNIQUEIDENTIFIER NULL,
    ActionType NVARCHAR(50) NOT NULL,
    LogMessage NVARCHAR(255) NOT NULL,
    LogDate DATETIME DEFAULT GETDATE()
);
GO

CREATE PROCEDURE ProcessMoneyTransfer
    @SenderWalletId UNIQUEIDENTIFIER,
    @ReceiverWalletId UNIQUEIDENTIFIER,
    @Amount DECIMAL(18, 2)
AS
BEGIN
    SET NOCOUNT ON;

    IF @Amount <= 0
    BEGIN
        RAISERROR('Amount must be greater than zero.', 16, 1);
        RETURN;
    END

    DECLARE @SenderBalance DECIMAL(18, 2);

    BEGIN TRY
        BEGIN TRANSACTION;

        SELECT @SenderBalance = Balance
        FROM Wallets WITH (UPDLOCK, ROWLOCK)
        WHERE WalletId = @SenderWalletId;

        IF @SenderBalance IS NULL
        BEGIN
            RAISERROR('Sender wallet not found.', 16, 1);
            RETURN;
        END

        IF @SenderBalance < @Amount
        BEGIN
            RAISERROR('Insufficient balance.', 16, 1);
            RETURN;
        END

        UPDATE Wallets
        SET Balance = Balance - @Amount
        WHERE WalletId = @SenderWalletId;

        UPDATE Wallets
        SET Balance = Balance + @Amount
        WHERE WalletId = @ReceiverWalletId;

        INSERT INTO Transactions (SenderWalletId, ReceiverWalletId, Amount, TransactionStatus)
        VALUES (@SenderWalletId, @ReceiverWalletId, @Amount, 'COMPLETED');

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
        BEGIN
            ROLLBACK TRANSACTION;
        END

        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        RAISERROR(@ErrorMessage, 16, 1);
    END CATCH
END;
GO

CREATE TRIGGER trg_AfterTransactionInsert
ON Transactions
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;

    INSERT INTO AuditLogs (TransactionId, ActionType, LogMessage)
    SELECT 
        i.TransactionId,
        'TRANSFER_COMPLETED',
        'Amount: ' + CAST(i.Amount AS NVARCHAR(20)) + ' | Sender: ' + CAST(i.SenderWalletId AS NVARCHAR(36)) + ' | Receiver: ' + CAST(i.ReceiverWalletId AS NVARCHAR(36))
    FROM inserted i
    WHERE i.TransactionStatus = 'COMPLETED';
END;
GO