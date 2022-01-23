SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[ReceiptLockboxFieldDataValidator]
(
@JobStepInstanceId BIGINT,
@LockboxErrorMessages LockboxErrorMessage READONLY
)
AS
BEGIN
SET NOCOUNT ON;
----------------------------------------------
DECLARE @SingleQuote AS CHAR = CHAR(39)
DECLARE @ErrorDelimiter AS CHAR = ','
DECLARE @Blank AS CHAR = ''
DECLARE @Active AS nvarchar(6)= 'Active'
----------------------------------------------
DECLARE @ErrorMessage_LB005 AS NVARCHAR(200)
SELECT @ErrorMessage_LB005 = LEM.ErrorMessage FROM @LockboxErrorMessages LEM WHERE LEM.ErrorCode = 'LB005'
----------------------------------------------
;WITH CTE_Contracts AS
(
SELECT SequenceNumber FROM Contracts
UNION ALL
SELECT SequenceNumber FROM Discountings
)
UPDATE ReceiptPostByLockBox_Extract
SET
IsValidLegalEntity =
CASE
WHEN LE.Id IS NULL THEN 0
ELSE 1
END,
IsValidInvoice =
CASE
WHEN RI.Id IS NULL THEN 0
ELSE 1
END,
IsValidContract =
CASE
WHEN C.SequenceNumber IS NULL THEN 0
ELSE 1
END,
IsValidCustomer =
CASE
WHEN CUS.Id IS NULL THEN 0
ELSE 1
END,
IsValidBankName =
CASE
WHEN BB.Id IS NULL THEN 0
ELSE 1
END,
IsValidBankAccountNumber =
CASE
WHEN BA.Id IS NULL THEN 0
ELSE 1
END
FROM ReceiptPostByLockBox_Extract RPBLE
LEFT JOIN LegalEntities LE ON RPBLE.LegalEntityNumber = LE.LegalEntityNumber AND LE.Status = @Active
LEFT JOIN ReceivableInvoices RI ON RPBLE.InvoiceNumber = RI.Number AND RI.IsActive = 1
LEFT JOIN CTE_Contracts C ON RPBLE.ContractNumber = C.SequenceNumber
LEFT JOIN Parties P ON RPBLE.CustomerNumber = P.PartyNumber
LEFT JOIN BankBranches BB ON RPBLE.BankName = BB.BankName AND BB.IsActive = 1
LEFT JOIN BankAccounts BA ON RPBLE.BankAccountNumberEncrypted = BA.AccountNumber_CT AND BA.IsActive = 1
LEFT JOIN dbo.Customers CUS ON P.Id = CUS.Id AND CUS.Status = @Active 
WHERE RPBLE.JobStepInstanceId = @JobStepInstanceId
SELECT
RPBLE.Id,
RPBLE.LegalEntityNumber,
RPBLE.CustomerNumber,
RPBLE.ContractNumber,
RPBLE.InvoiceNumber,
RPBLE.BankName,
RPBLE.BankAccountNumber,
RPBLE.BankAccountNumberEncrypted,
RPBLE.IsValidLegalEntity,
RPBLE.IsValidInvoice,
RPBLE.IsValidContract,
RPBLE.IsValidCustomer,
RPBLE.IsValidBankName,
RPBLE.IsValidBankAccountNumber,
RPBLE.IsValid,
CAST('' AS NVARCHAR(200)) AS ErrorMessage
INTO #ErrorInfo
FROM ReceiptPostByLockBox_Extract RPBLE
WHERE RPBLE.JobStepInstanceId = @JobStepInstanceId
UPDATE #ErrorInfo
SET
IsValid = 0,
ErrorMessage = CONCAT(ErrorMessage , ',' , 'Legal Entity Number')
WHERE dbo.IsStringNullOrEmpty(LegalEntityNumber) = 0 AND IsValidLegalEntity = 0
UPDATE #ErrorInfo
SET
IsValid = 0,
ErrorMessage = CONCAT(ErrorMessage , ',' , 'Customer Number')
WHERE dbo.IsStringNullOrEmpty(CustomerNumber) = 0 AND IsValidCustomer = 0
UPDATE #ErrorInfo
SET
IsValid = 0,
ErrorMessage = CONCAT(ErrorMessage , ',' , 'Contract Number')
WHERE dbo.IsStringNullOrEmpty(ContractNumber) = 0 AND IsValidContract = 0
UPDATE #ErrorInfo
SET
IsValid = 0,
ErrorMessage = CONCAT(ErrorMessage , ',' , 'Invoice Number')
WHERE dbo.IsStringNullOrEmpty(InvoiceNumber) = 0 AND IsValidInvoice = 0
UPDATE #ErrorInfo
SET
IsValid = 0,
ErrorMessage = CONCAT(ErrorMessage , ',' , 'Bank Name')
WHERE dbo.IsStringNullOrEmpty(BankName) = 0 AND IsValidBankName = 0
UPDATE #ErrorInfo
SET
IsValid = 0,
ErrorMessage = CONCAT(ErrorMessage , ',' , 'Bank Account Number')
WHERE dbo.IsStringNullOrEmpty(BankAccountNumber) = 0 AND IsValidBankAccountNumber = 0
UPDATE ReceiptPostByLockBox_Extract
SET
IsValid = 0,
ErrorCode = CONCAT(ErrorCode, @ErrorDelimiter , 'LB005'),
ErrorMessage = CONCAT(RPBLE.ErrorMessage, @ErrorDelimiter , REPLACE(@ErrorMessage_LB005, '@Entity', SUBSTRING(EI.ErrorMessage, 2, LEN(EI.ErrorMessage))))
FROM #ErrorInfo EI
JOIN ReceiptPostByLockBox_Extract RPBLE ON EI.Id = RPBLE.Id
WHERE EI.ErrorMessage <> @Blank
END

GO
