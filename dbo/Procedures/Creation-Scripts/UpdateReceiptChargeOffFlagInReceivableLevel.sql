SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[UpdateReceiptChargeOffFlagInReceivableLevel] (
@JobStepInstanceId BIGINT,
@ContractTypeValues_Lease NVARCHAR(10),
@ContractTypeValues_Loan NVARCHAR(10),
@ValidReceivableTypes NVARCHAR(1000),
@ValidNonRentalReceivableTypes NVARCHAR(1000),
@ValidLeasePaymentTypes NVARCHAR(1000),
@ValidLoanPaymentTypes NVARCHAR(1000),
@BlendedItemBookRecognitionModeValues_Accrete NVARCHAR(10),
@BlendedItemBookRecognitionModeValues_Amortize NVARCHAR(10),
@AccountingTreatment_CashBased NVARCHAR(10),
@CreatedById BIGINT,
@CreatedTime DATETIMEOFFSET
) AS
BEGIN
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
SET NOCOUNT ON;
SELECT Id
INTO #ValidReceivableTypeIds
FROM ReceivableTypes
WHERE Name in (SELECT Item FROM dbo.ConvertCSVToStringTable(@ValidReceivableTypes, ','))

SELECT Id
INTO #ValidNonRentalReceivableTypeIds
FROM ReceivableTypes
WHERE Name in (SELECT Item FROM dbo.ConvertCSVToStringTable(@ValidNonRentalReceivableTypes, ','))

-- Rental Receivables
UPDATE RD_Extract
SET
IsChargeoffReceivable = 1,
UpdatedById = @CreatedById,
UpdatedTime = @CreatedTime
FROM (SELECT * FROM ReceiptReceivableDetails_Extract
WHERE JobStepInstanceId = @JobStepInstanceId AND IsChargeoffContract = 1
AND FunderId IS NULL) RD_Extract
JOIN #ValidReceivableTypeIds ON RD_Extract.ReceivableTypeId = #ValidReceivableTypeIds.Id
LEFT JOIN LeasePaymentSchedules ON RD_Extract.PaymentScheduleId = LeasePaymentSchedules.Id
AND LeasePaymentSchedules.IsActive = 1 AND RD_Extract.ContractType = @ContractTypeValues_Lease
AND LeasePaymentSchedules.PaymentType IN (SELECT Item FROM dbo.ConvertCSVToStringTable(@ValidLeasePaymentTypes, ','))
LEFT JOIN LoanPaymentSchedules ON RD_Extract.PaymentScheduleId = LoanPaymentSchedules.Id
AND LoanPaymentSchedules.IsActive = 1 AND RD_Extract.ContractType = @ContractTypeValues_Loan
AND LoanPaymentSchedules.PaymentType IN (SELECT Item FROM dbo.ConvertCSVToStringTable(@ValidLoanPaymentTypes, ','))
WHERE (LeasePaymentSchedules.Id IS NOT NULL OR LoanPaymentSchedules.Id IS NOT NULL)
;
--FAS91 Blended Item Receivables
UPDATE RD_Extract
SET
IsChargeoffReceivable = 1,
UpdatedById = @CreatedById,
UpdatedTime = @CreatedTime
FROM (SELECT * FROM ReceiptReceivableDetails_Extract
WHERE JobStepInstanceId = @JobStepInstanceId AND IsChargeoffContract = 1
AND FunderId IS NULL) RD_Extract
JOIN Sundries ON RD_Extract.ReceivableId = Sundries.ReceivableId AND Sundries.IsActive = 1
JOIN BlendedItemDetails ON BlendedItemDetails.SundryId = Sundries.Id AND BlendedItemDetails.IsActive = 1
JOIN BlendedItems ON BlendedItems.Id = BlendedItemDetails.BlendedItemId
AND BlendedItems.IsActive = 1 AND BlendedItems.IsFAS91 = 1
WHERE (BlendedItems.BookRecognitionMode = @BlendedItemBookRecognitionModeValues_Accrete
OR BlendedItems.BookRecognitionMode = @BlendedItemBookRecognitionModeValues_Amortize)
AND RD_Extract.IsGlposted=0;
-- Non Rental Receivables Eligible For Recovery

UPDATE ReceiptReceivableDetails_Extract
SET
IsChargeoffReceivable = 1,
UpdatedById = @CreatedById,
UpdatedTime = @CreatedTime
FROM ReceiptReceivableDetails_Extract RD
JOIN #ValidNonRentalReceivableTypeIds ON RD.ReceivableTypeId = #ValidNonRentalReceivableTypeIds.Id
WHERE JobStepInstanceId = @JobStepInstanceId AND IsChargeoffContract = 1
AND IsChargeoffReceivable = 0 AND FunderId IS NULL
AND IsGLPosted = 0
;
DROP TABLE #ValidReceivableTypeIds
DROP TABLE #ValidNonRentalReceivableTypeIds
END

GO
