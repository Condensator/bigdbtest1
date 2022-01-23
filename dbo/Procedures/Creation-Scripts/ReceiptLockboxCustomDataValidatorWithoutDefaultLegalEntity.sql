SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[ReceiptLockboxCustomDataValidatorWithoutDefaultLegalEntity]
(
@JobStepInstanceId BIGINT,
@AllowInterCompanyTransfer BIT,
@LockboxErrorMessages LockboxErrorMessage READONLY,
@ReceivableEntityTypeValues_CT NVARCHAR(2),
@ReceivableEntityTypeValues_DT NVARCHAR(2)
)
AS
BEGIN
SET NOCOUNT ON;
---------------------------------------------
DECLARE @SingleQuote AS CHAR = CHAR(39)
DECLARE @ErrorDelimiter AS CHAR = ','
---------------------------------------------
SELECT * INTO #LockboxErrorMessages FROM @LockboxErrorMessages
DECLARE @InvalidAttributesMessage NVARCHAR(200)
SELECT @InvalidAttributesMessage = ErrorMessage FROM #LockboxErrorMessages WHERE ErrorCode = 'LB500'
----------------------------------------------
SELECT
LE.LegalEntityNumber,
LDPC.LegalEntityId
INTO #DefaultLockboxParameterInfo
FROM LockboxDefaultParameterConfigs LDPC
INNER JOIN LegalEntities LE ON LDPC.LegalEntityId = LE.Id
WHERE LDPC.IsActive = 1
GROUP BY
LE.LegalEntityNumber,
LDPC.LegalEntityId
-------------------------------------------------
-- LE Validations
-- LE is NULL
--EXCLUDE NA
UPDATE ReceiptPostByLockBox_Extract
SET
IsValid = 0,
HasMandatoryFields = 0,
ErrorCode = CONCAT(ErrorCode, @ErrorDelimiter, 'LB004'),
ErrorMessage = CONCAT(ErrorMessage, @ErrorDelimiter, REPLACE((SELECT ErrorMessage FROM #LockboxErrorMessages WHERE ErrorCode = 'LB004'), '@LegalEntityNumber', + @SingleQuote + LE.LegalEntityNumber + @SingleQuote))
FROM ReceiptPostByLockBox_Extract RPBLE
JOIN ReceivableInvoices RI ON RPBLE.InvoiceNumber = RI.Number
INNER JOIN LegalEntities LE ON RI.LegalEntityId = LE.Id
LEFT JOIN #DefaultLockboxParameterInfo DLEI ON RI.LegalEntityId = DLEI.LegalEntityId
WHERE
RPBLE.JobStepInstanceId = @JobStepInstanceId AND
dbo.IsStringNullOrEmpty(RPBLE.LegalEntityNumber) = 1 AND
IsValidInvoice = 1 AND
DLEI.LegalEntityId IS NULL
AND RPBLE.IsNonAccrualLoan=0
-- LE, Invoice Number is null
;WITH ContractExtractInfo AS
(
SELECT
C.Id AS ContractId,
RPBLE.Id AS ExtractId
FROM ReceiptPostByLockBox_Extract RPBLE
JOIN Contracts C ON RPBLE.ContractNumber = C.SequenceNumber
WHERE
JobStepInstanceId = @JobStepInstanceId AND
dbo.IsStringNullOrEmpty(RPBLE.LegalEntityId) = 1 AND
dbo.IsStringNullOrEmpty(RPBLE.InvoiceNumber) = 1 AND
IsValidContract = 1
),
ContractLegalEntityExtractInfo AS
(
SELECT LF.LegalEntityId, CEI.ExtractId
FROM ContractExtractInfo CEI
JOIN LeaseFinances LF ON CEI.ContractId = LF.ContractId
UNION
SELECT LL.LegalEntityId, CEI.ExtractId
FROM ContractExtractInfo CEI
JOIN LeveragedLeases LL ON CEI.ContractId = LL.ContractId
UNION
SELECT LF.LegalEntityId, CEI.ExtractId
FROM ContractExtractInfo CEI
JOIN LoanFinances LF ON CEI.ContractId = LF.ContractId
)
UPDATE ReceiptPostByLockBox_Extract
SET
IsValid = 0,
HasMandatoryFields = 0,
ErrorCode = CONCAT(ErrorCode, @ErrorDelimiter, 'LB004'),
ErrorMessage = CONCAT(ErrorMessage, @ErrorDelimiter, REPLACE((SELECT ErrorMessage FROM #LockboxErrorMessages WHERE ErrorCode = 'LB004'), '@LegalEntityNumber', + @SingleQuote + LE.LegalEntityNumber + @SingleQuote))
FROM ContractLegalEntityExtractInfo CLEEI
INNER JOIN ReceiptPostByLockBox_Extract RPBLE ON CLEEI.ExtractId = RPBLE.Id
INNER JOIN LegalEntities LE ON CLEEI.LegalEntityId = LE.Id
LEFT JOIN #DefaultLockboxParameterInfo DLEN ON CLEEI.LegalEntityId = DLEN.LegalEntityId
WHERE DLEN.LegalEntityId IS NULL
-- LE, Invoice, contract numbers are null
UPDATE ReceiptPostByLockBox_Extract
SET
IsValid = 0,
ErrorCode = CONCAT(ErrorCode, @ErrorDelimiter, 'LB008'),
ErrorMessage = CONCAT(ErrorMessage, @ErrorDelimiter, (SELECT ErrorMessage FROM #LockboxErrorMessages WHERE ErrorCode = 'LB008'))
WHERE
JobStepInstanceId = @JobStepInstanceId AND
dbo.IsStringNullOrEmpty(LegalEntityNumber) = 1 AND
dbo.IsStringNullOrEmpty(InvoiceNumber) = 1 AND
dbo.IsStringNullOrEmpty(ContractNumber) = 1 AND
IsValidCustomer = 1
AND IsNonAccrualLoan=0
;
UPDATE ReceiptPostByLockBox_Extract
SET
IsValid = 0
WHERE
JobStepInstanceId = @JobStepInstanceId AND
IsValidLegalEntity = 0 AND IsValidCustomer = 0 AND
LegalEntityNumber IS NOT NULL AND
(InvoiceNumber IS NULL OR InvoiceNumber = '') AND
(ContractNumber IS NULL OR ContractNumber = '') AND
(CustomerNumber IS NOT NULL AND CustomerNumber <> '')
AND IsNonAccrualLoan=0
-------------------------------------------------
UPDATE ReceiptPostByLockBox_Extract
SET
IsValid = 1
WHERE
HasMandatoryFields = 1 AND JobStepInstanceId = @JobStepInstanceId AND
IsValidContract = 1 AND
IsValidCustomer = 1 AND
IsValidLegalEntity = 1 AND
IsContractCustomerAssociated = 1 AND
IsContractLegalEntityAssociated = 1
AND IsNonAccrualLoan=0
UPDATE ReceiptPostByLockBox_Extract
SET
IsValid = 1
WHERE
HasMandatoryFields = 1 AND JobStepInstanceId = @JobStepInstanceId AND
IsValidContract = 1 AND
IsValidCustomer = 1 AND
IsValidLegalEntity = 1 AND
(IsContractCustomerAssociated = 1 OR IsContractLegalEntityAssociated = 1)
AND IsNonAccrualLoan=0
UPDATE ReceiptPostByLockBox_Extract
SET
IsValid = 1
WHERE
HasMandatoryFields = 1 AND JobStepInstanceId = @JobStepInstanceId AND
IsValidContract = 1 AND
dbo.IsStringNullOrEmpty(LegalEntityNumber) = 1 AND
dbo.IsStringNullOrEmpty(InvoiceNumber) = 1 AND
dbo.IsStringNullOrEmpty(CustomerNumber) = 1
AND IsNonAccrualLoan=0
UPDATE ReceiptPostByLockBox_Extract
SET
IsValid = 1
FROM ReceiptPostByLockBox_Extract RPBLE
WHERE
HasMandatoryFields = 1 AND JobStepInstanceId = @JobStepInstanceId AND
IsContractCustomerAssociated = 1 AND
dbo.IsStringNullOrEmpty(LegalEntityNumber) = 1 AND
dbo.IsStringNullOrEmpty(InvoiceNumber) = 1 AND IsNonAccrualLoan=0
UPDATE ReceiptPostByLockBox_Extract
SET
IsValid = 1,
Comment = @InvalidAttributesMessage
WHERE
HasMandatoryFields = 1 AND JobStepInstanceId = @JobStepInstanceId AND
IsValidContract = 1 AND
IsValidCustomer = 0 AND dbo.IsStringNullOrEmpty(CustomerNumber) = 0 AND
dbo.IsStringNullOrEmpty(LegalEntityNumber) = 1 AND
dbo.IsStringNullOrEmpty(InvoiceNumber) = 1 AND IsNonAccrualLoan=0
UPDATE ReceiptPostByLockBox_Extract
SET
IsValid = 1
WHERE
HasMandatoryFields = 1 AND JobStepInstanceId = @JobStepInstanceId AND
IsContractLegalEntityAssociated = 1 AND
dbo.IsStringNullOrEmpty(InvoiceNumber) = 1 AND
dbo.IsStringNullOrEmpty(CustomerNumber) = 1 AND IsNonAccrualLoan=0
UPDATE ReceiptPostByLockBox_Extract
SET
IsValid = 1,
Comment = @InvalidAttributesMessage
WHERE
HasMandatoryFields = 1 AND JobStepInstanceId = @JobStepInstanceId AND
IsValidLegalEntity = 0 AND dbo.IsStringNullOrEmpty(LegalEntityNumber) = 0 AND
((IsValidContract = 1 AND IsInvoiceContractAssociated = 1) OR (IsValidCustomer = 1 AND IsInvoiceCustomerAssociated = 1))AND
IsValidInvoice = 1 AND IsNonAccrualLoan=0
UPDATE ReceiptPostByLockBox_Extract
SET
IsValid = 1
WHERE
HasMandatoryFields = 1 AND JobStepInstanceId = @JobStepInstanceId AND
IsValidContract = 1 AND
IsValidCustomer = 1 AND
IsValidLegalEntity = 1 AND
IsContractCustomerAssociated = 1 AND
IsContractLegalEntityAssociated = 1 AND IsNonAccrualLoan=0
UPDATE ReceiptPostByLockBox_Extract
SET
IsValid = 1,
Comment =
CASE
WHEN IsContractLegalEntityAssociated = 0 THEN REPLACE((SELECT ErrorMessage FROM #LockboxErrorMessages WHERE ErrorCode = 'LB212'), '@Entity', 'LegalEntity')
ELSE REPLACE((SELECT ErrorMessage FROM #LockboxErrorMessages WHERE ErrorCode = 'LB212'), '@Entity', 'Customer')
END
WHERE
HasMandatoryFields = 1 AND JobStepInstanceId = @JobStepInstanceId AND
IsValidInvoice = 0 AND
IsValidContract = 1 AND
IsValidCustomer = 1 AND
IsValidLegalEntity = 1 AND
(
(IsContractCustomerAssociated = 1 AND IsContractLegalEntityAssociated = 0) OR
(IsContractCustomerAssociated = 0 AND IsContractLegalEntityAssociated = 1)
)
AND IsNonAccrualLoan=0
--------------------------
UPDATE ReceiptPostByLockBox_Extract
SET IsValid = 1
WHERE
HasMandatoryFields = 1 AND JobStepInstanceId = @JobStepInstanceId AND
IsValidInvoice = 1 AND
(IsValidCustomer = 0 OR IsValidContract = 0 OR IsValidLegalEntity = 0) AND
dbo.IsStringNullOrEmpty(LegalEntityId) = 1 AND IsNonAccrualLoan=0

UPDATE ReceiptPostByLockBox_Extract
SET IsValid = 0
WHERE
JobStepInstanceId = @JobStepInstanceId AND
IsValidInvoice = 0 AND
dbo.IsStringNullOrEmpty(LegalEntityId) = 1 AND
dbo.IsStringNullOrEmpty(ContractNumber) = 1 AND
dbo.IsStringNullOrEmpty(CustomerNumber) = 1 AND IsNonAccrualLoan=0
------------------------------------------------
DECLARE @InvalidInvoiceErrorMessage AS NVARCHAR(200)
SET @InvalidInvoiceErrorMessage = @ErrorDelimiter + REPLACE((SELECT ErrorMessage FROM #LockboxErrorMessages WHERE ErrorCode = 'LB005'), '@Entity', 'Invoice Number')
UPDATE ReceiptPostByLockBox_Extract
SET
IsValid = 0,
ErrorCode = REPLACE(ErrorCode, @ErrorDelimiter + 'LB005', ''),
ErrorMessage = REPLACE(ErrorMessage, @InvalidInvoiceErrorMessage, '')
WHERE
JobStepInstanceId = @JobStepInstanceId AND
IsValidInvoice = 0 AND dbo.IsStringNullOrEmpty(InvoiceNumber) = 0 AND
IsValidCustomer = 1 AND
dbo.IsStringNullOrEmpty(LegalEntityNumber) = 1 AND
dbo.IsStringNullOrEmpty(ContractNumber) = 1 AND
(IsValidLegalEntity = 1 OR dbo.IsStringNullOrEmpty(LegalEntityNumber) = 1) AND
(IsValidContract = 1 OR dbo.IsStringNullOrEmpty(ContractNumber) = 1) AND IsNonAccrualLoan=0
UPDATE ReceiptPostByLockBox_Extract
SET
IsValid = 0,
ErrorCode = CONCAT(ErrorCode, @ErrorDelimiter, 'LB401'),
ErrorMessage = CONCAT(ErrorMessage, @ErrorDelimiter, (SELECT ErrorMessage FROM #LockboxErrorMessages WHERE ErrorCode = 'LB401'))
WHERE
JobStepInstanceId = @JobStepInstanceId AND
IsValidInvoice = 0 AND dbo.IsStringNullOrEmpty(InvoiceNumber) = 0 AND
IsValidCustomer = 1 AND
dbo.IsStringNullOrEmpty(LegalEntityNumber) = 1 AND
dbo.IsStringNullOrEmpty(ContractNumber) = 1 AND IsNonAccrualLoan=0
------------------------------------------------
UPDATE ReceiptPostByLockBox_Extract
SET
IsValid = 0,
ErrorCode = 'LB402',
ErrorMessage = (SELECT ErrorMessage FROM #LockboxErrorMessages WHERE ErrorCode = 'LB402')
WHERE
JobStepInstanceId = @JobStepInstanceId AND
IsValidInvoice = 1 AND
IsValidCustomer = 1 AND
IsInvoiceCustomerAssociated = 0 AND
(dbo.IsStringNullOrEmpty(LegalEntityNumber) = 1 OR IsValidLegalEntity = 0)AND
(dbo.IsStringNullOrEmpty(ContractNumber) = 1 OR IsValidContract = 0)AND 
IsNonAccrualLoan=0
;WITH ContractExtractInfo AS
(
SELECT RPBLE.Id AS ExtractId, C.Id AS EntityId, @ReceivableEntityTypeValues_CT AS EntityType
FROM ReceiptPostByLockBox_Extract RPBLE
JOIN Contracts C ON RPBLE.ContractNumber = C.SequenceNumber
WHERE RPBLE.JobStepInstanceId = @JobStepInstanceId
UNION
SELECT RPBLE.Id AS ExtractId, D.Id AS EntityId, @ReceivableEntityTypeValues_DT AS EntityType
FROM ReceiptPostByLockBox_Extract RPBLE
JOIN Discountings D ON RPBLE.ContractNumber = D.SequenceNumber
WHERE RPBLE.JobStepInstanceId = @JobStepInstanceId
),
ContractCustomerExtractInfo AS
(
SELECT CEI.ExtractId, LF.CustomerId, @ReceivableEntityTypeValues_CT AS EntityType
FROM ContractExtractInfo CEI
JOIN LeaseFinances LF ON CEI.EntityId = LF.ContractId
WHERE EntityType = @ReceivableEntityTypeValues_CT
UNION
SELECT CEI.ExtractId, LF.CustomerId, @ReceivableEntityTypeValues_CT AS EntityType
FROM ContractExtractInfo CEI
JOIN LoanFinances LF ON CEI.EntityId = LF.ContractId
WHERE EntityType = @ReceivableEntityTypeValues_CT
UNION
SELECT CEI.ExtractId, LL.CustomerId, @ReceivableEntityTypeValues_CT AS EntityType
FROM ContractExtractInfo CEI
JOIN LeveragedLeases LL ON CEI.EntityId = LL.ContractId
WHERE EntityType = @ReceivableEntityTypeValues_CT
UNION
SELECT CEI.ExtractId, DF.FunderId AS CustomerId, @ReceivableEntityTypeValues_DT AS EntityType
FROM ContractExtractInfo CEI
JOIN DiscountingFinances DF ON CEI.EntityId = DF.DiscountingId
WHERE EntityType = @ReceivableEntityTypeValues_DT
)
SELECT
RPBLE.Id AS ExtractId,
CASE
WHEN RI.CustomerId = CCEI.CustomerId THEN 1
ELSE 0
END AS IsCommonCustomer
INTO #CommonCustomerValidationInfo
FROM ReceiptPostByLockBox_Extract RPBLE
LEFT JOIN ReceivableInvoices RI ON RPBLE.InvoiceNumber = RI.Number
LEFT JOIN ContractCustomerExtractInfo CCEI ON RPBLE.Id = CCEI.ExtractId
WHERE RPBLE.JobStepInstanceId = @JobStepInstanceId
UPDATE ReceiptPostByLockBox_Extract
SET
IsValid = 0,
ErrorCode = CONCAT(ErrorCode, @ErrorDelimiter, 'LB403'),
ErrorMessage = CONCAT(ErrorMessage, @ErrorDelimiter, (SELECT ErrorMessage FROM #LockboxErrorMessages WHERE ErrorCode = 'LB403'))
FROM ReceiptPostByLockBox_Extract RPBLE
JOIN #CommonCustomerValidationInfo CCVI ON RPBLE.Id = CCVI.ExtractId
WHERE CCVI.IsCommonCustomer = 0 AND IsValidContract = 1 AND IsValidInvoice = 1 AND IsNonAccrualLoan=0
UPDATE ReceiptPostByLockBox_Extract
SET
IsValid = 0,
ErrorCode = CONCAT(ErrorCode, @ErrorDelimiter, 'LB406'),
ErrorMessage = CONCAT(ErrorMessage, @ErrorDelimiter, (SELECT ErrorMessage FROM #LockboxErrorMessages WHERE ErrorCode = 'LB406'))
FROM ReceiptPostByLockBox_Extract RPBLE
JOIN #CommonCustomerValidationInfo CCVI ON RPBLE.Id = CCVI.ExtractId
WHERE CCVI.IsCommonCustomer = 1 AND IsInvoiceContractAssociated = 0 AND IsValidInvoice = 1 AND IsValidContract = 1 AND IsNonAccrualLoan=0
UPDATE ReceiptPostByLockBox_Extract
SET
IsValid = 1,
Comment = (SELECT ErrorMessage FROM #LockboxErrorMessages WHERE ErrorCode = 'LB404')
WHERE
HasMandatoryFields = 1 AND JobStepInstanceId = @JobStepInstanceId AND
IsValidInvoice = 1 AND
IsValidContract = 1 AND
IsInvoiceContractAssociated = 0 AND 
IsValidCustomer = 1 AND
IsInvoiceCustomerAssociated = 1 AND
LegalEntityId IS NOT NULL AND 
IsNonAccrualLoan=0
UPDATE ReceiptPostByLockBox_Extract
SET	IsValid = 1
WHERE
HasMandatoryFields = 1 AND JobStepInstanceId = @JobStepInstanceId AND
IsInvoiceLegalEntityAssociated = 1 AND IsNonAccrualLoan=0
UPDATE ReceiptPostByLockBox_Extract
SET
IsValid = 0,
ErrorCode = CONCAT(ErrorCode, @ErrorDelimiter, 'LB405'),
ErrorMessage = CONCAT(ErrorMessage, @ErrorDelimiter, (SELECT ErrorMessage FROM #LockboxErrorMessages WHERE ErrorCode = 'LB405'))
WHERE
JobStepInstanceId = @JobStepInstanceId AND
IsValidInvoice = 1 AND
IsValidLegalEntity = 1 AND
IsInvoiceLegalEntityAssociated = 0 AND
dbo.IsStringNullOrEmpty(ContractNumber) = 1 AND
dbo.IsStringNullOrEmpty(CustomerNumber) = 1 AND IsNonAccrualLoan=0
UPDATE ReceiptPostByLockBox_Extract
SET
IsValid = 1
WHERE
HasMandatoryFields = 1 AND JobStepInstanceId = @JobStepInstanceId AND
IsValidInvoice = 0 AND
IsValidLegalEntity = 1 AND
dbo.IsStringNullOrEmpty(CustomerNumber) = 1 AND
dbo.IsStringNullOrEmpty(ContractNumber) = 1 AND IsNonAccrualLoan=0
UPDATE ReceiptPostByLockBox_Extract
SET IsValid = 1
WHERE
HasMandatoryFields = 1 AND JobStepInstanceId = @JobStepInstanceId AND
IsInvoiceCustomerAssociated = 1 AND
IsInvoiceContractAssociated = 1 AND
IsContractCustomerAssociated = 1 AND IsNonAccrualLoan=0
UPDATE ReceiptPostByLockBox_Extract
SET IsValid = 1
WHERE
HasMandatoryFields = 1 AND JobStepInstanceId = @JobStepInstanceId AND
IsInvoiceLegalEntityAssociated = 1 AND
IsContractLegalEntityAssociated = 1 AND IsNonAccrualLoan=0

UPDATE ReceiptPostByLockBox_Extract
	SET
		IsValid = 1,
		Comment = (SELECT ErrorMessage FROM #LockboxErrorMessages WHERE ErrorCode = 'LB410')
	WHERE
		HasMandatoryFields = 1 AND
		JobStepInstanceId = @JobStepInstanceId 
	AND IsValidInvoice=1
	AND IsValidCustomer=1
	AND IsInvoiceCustomerAssociated = 0
	AND IsInvoiceLegalEntityAssociated = 1 
	AND IsNonAccrualLoan=0
	;	

UPDATE ReceiptPostByLockBox_Extract
SET IsValid = 1,
	Comment = (SELECT ErrorMessage FROM #LockboxErrorMessages WHERE ErrorCode = 'LB411')
WHERE JobStepInstanceId = @JobStepInstanceId AND
	HasMandatoryFields = 1 AND
	IsValidInvoice = 1 AND
	IsValidContract = 1 AND
	IsInvoiceContractAssociated = 0 AND 
	(IsInvoiceLegalEntityAssociated = 1 OR IsContractLegalEntityAssociated = 1) AND  
	IsNonAccrualLoan=0
;
END

GO
