SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[ReceiptLockBoxMandatoryDataValidator]
(
@JobStepInstanceId BIGINT,
@BusinessUnitId BIGINT,
@DefaultReceiptLegalEntityNumber NVARCHAR(200),
@LockboxErrorMessages LockboxErrorMessage READONLY
)
AS
BEGIN
SET NOCOUNT ON;
DECLARE @ErrorDelimiter AS CHAR = ','
DECLARE @PortfolioId AS BIGINT
SELECT @PortfolioId = PortfolioId FROM BusinessUnits WHERE Id = @BusinessUnitId
DECLARE @DefaultReceiptLegalEntityId AS BIGINT
SELECT @DefaultReceiptLegalEntityId = Id FROM LegalEntities WHERE LegalEntityNumber = @DefaultReceiptLegalEntityNumber
DECLARE @ReceiptLockBoxErrorCodeValues_LB009 AS NVARCHAR(200)
SELECT @ReceiptLockBoxErrorCodeValues_LB009 = LEM.ErrorMessage FROM @LockboxErrorMessages LEM WHERE LEM.ErrorCode = 'LB009'
DECLARE @ReceiptLockBoxErrorCodeValues_LB002 AS NVARCHAR(200)
SELECT @ReceiptLockBoxErrorCodeValues_LB002 = LEM.ErrorMessage FROM @LockboxErrorMessages LEM WHERE LEM.ErrorCode = 'LB002'
UPDATE ReceiptPostByLockBox_Extract
SET
IsValid = 0,
HasMandatoryFields = 0,
ErrorCode = CONCAT(ErrorCode, @ErrorDelimiter , 'LB009'),
ErrorMessage = CONCAT(ErrorMessage, @ErrorDelimiter, @ReceiptLockBoxErrorCodeValues_LB009)
WHERE
JobStepInstanceId = @JobStepInstanceId AND
dbo.IsStringNullOrEmpty(LegalEntityNumber) = 1 AND
dbo.IsStringNullOrEmpty(InvoiceNumber) = 1 AND
dbo.IsStringNullOrEmpty(ContractNumber) = 1 AND
dbo.IsStringNullOrEmpty(CustomerNumber) = 1 AND
ReceivedDate IS NULL AND
ReceivedAmount IS NULL AND
dbo.IsStringNullOrEmpty(BankName) = 1 AND
dbo.IsStringNullOrEmpty(BankAccountNumber) = 1 AND
BankAccountNumberEncrypted IS NULL
DECLARE @ReceiptLockBoxErrorCodeValues_LB001 AS NVARCHAR(200)
SELECT @ReceiptLockBoxErrorCodeValues_LB001 = LEM.ErrorMessage
FROM @LockboxErrorMessages LEM
WHERE LEM.ErrorCode = 'LB001'
UPDATE ReceiptPostByLockBox_Extract
SET
IsValid = 0,
HasMandatoryFields = 0,
ErrorCode = CONCAT(ErrorCode, @ErrorDelimiter + 'LB001'),
ErrorMessage = CONCAT(ErrorMessage, @ErrorDelimiter + REPLACE(@ReceiptLockBoxErrorCodeValues_LB001, '@Columnname',
CASE
WHEN ReceivedAmount IS NULL AND ReceivedDate IS NULL AND dbo.IsStringNullOrEmpty(CheckNumber) = 1
THEN 'Received Amount, Received Date, Check Number'
WHEN ReceivedAmount IS NULL AND ReceivedDate IS NULL
THEN 'Received Amount, Received Date'
WHEN ReceivedDate IS NULL AND dbo.IsStringNullOrEmpty(CheckNumber) = 1
THEN 'Received Date, Check Number'
WHEN dbo.IsStringNullOrEmpty(CheckNumber) = 1 AND ReceivedAmount IS NULL
THEN 'Check Number, Received Amount'
WHEN ReceivedAmount IS NULL
THEN 'Received Amount'
WHEN ReceivedDate IS NULL
THEN 'Received Date'
WHEN dbo.IsStringNullOrEmpty(CheckNumber) = 1
THEN 'Check Number'
END))
WHERE
JobStepInstanceId = @JobStepInstanceId AND
(
ReceivedAmount IS NULL OR
ReceivedDate IS NULL OR
dbo.IsStringNullOrEmpty(CheckNumber) = 1
)
UPDATE ReceiptPostByLockBox_Extract
SET
IsValid = 0,
HasMandatoryFields = 0,
ErrorCode = CONCAT(ErrorCode, @ErrorDelimiter + 'LB001'),
ErrorMessage = CONCAT(ErrorMessage, @ErrorDelimiter + REPLACE(@ReceiptLockBoxErrorCodeValues_LB001, '@Columnname', 'Legal Entity Number, Customer Number, Contract Number, Invoice Number'))
WHERE
JobStepInstanceId = @JobStepInstanceId AND
@DefaultReceiptLegalEntityId IS NULL AND
dbo.IsStringNullOrEmpty(LegalEntityNumber) = 1 AND
dbo.IsStringNullOrEmpty(CustomerNumber) = 1 AND
dbo.IsStringNullOrEmpty(ContractNumber) = 1 AND
dbo.IsStringNullOrEmpty(InvoiceNumber) = 1
;
UPDATE ReceiptPostByLockBox_Extract
SET
IsValid = 0,
HasMandatoryFields = 0,
ErrorCode = CONCAT(ErrorCode, @ErrorDelimiter + 'LB002'),
ErrorMessage = CONCAT(ErrorMessage, @ErrorDelimiter + @ReceiptLockBoxErrorCodeValues_LB002)
WHERE
@JobStepInstanceId = JobStepInstanceId AND
(
(BankAccountNumberEncrypted IS NULL AND dbo.IsStringNullOrEmpty(BankName) = 0) OR
(BankAccountNumberEncrypted IS NOT NULL AND dbo.IsStringNullOrEmpty(BankName) = 1) OR
(BankAccountNumberEncrypted IS NOT NULL AND @DefaultReceiptLegalEntityNumber IS NOT NULL AND dbo.IsStringNullOrEmpty(LegalEntityNumber) = 1 
	AND BankAccountNumberEncrypted NOT IN (SELECT AccountNumber_CT FROM BankAccounts WHERE Id IN 
	(SELECT BankAccountId FROM LegalEntityBankAccounts WHERE LegalEntityId  = @DefaultReceiptLegalEntityId AND IsActive = 1)))
)
END

GO
