SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[InsertReceivableDetailToAssetLevel]
(
@AmendmentType NVARCHAR(100),
@AmendmentStatus NVARCHAR(100),
@PayoffStatus NVARCHAR(100),
@AssetFinancialTypeReal NVARCHAR(100),
@AssetFinancialTypePlaceholder NVARCHAR(100),
@AssetFinancialTypeNegativeReturn NVARCHAR(100),
@JobStepInstanceId BIGINT,
@ContractFullyPaidOffStatus NVARCHAR(100)
)
AS
BEGIN
SET NOCOUNT ON;


CREATE TABLE #PayoffSundryDetail
(
	 ReceivableDetailId BIGINT
)

CREATE TABLE #ReceivableExtractDetails
(
	ReceivableDetailId BIGINT,
	AssetId BIGINT,
	CustomerCost DECIMAL(16,2),
	ExtendedPrice DECIMAL(16,2),
	ContractId BIGINT,
	LeaseFinanceId BIGINT,
	ReceivableTaxType NVARCHAR(15)
)

INSERT INTO #ReceivableExtractDetails
(	
	ReceivableDetailId,
	AssetId,
	CustomerCost,
	ExtendedPrice,
	ContractId,
	LeaseFinanceId,
	ReceivableTaxType
)
SELECT
	R.ReceivableDetailId,
	LA.AssetId,
	LA.CustomerCost_Amount, --LA.NBV_Amount + LA.Markup_Amount + LA.InterimMarkup_Amount - LA.ETCAdjustmentAmount_Amount
	R.ExtendedPrice,
	C.Id,
	L.Id,
	R.ReceivableTaxType
FROM SalesTaxReceivableDetailExtract R
INNER JOIN Contracts C ON R.ContractId = C.Id AND R.JobStepInstanceId = @JobStepInstanceId
INNER JOIN LeaseFinances L on L.ContractId = C.Id AND c.Status <> @ContractFullyPaidOffStatus
INNER JOIN LeaseAssets LA on LA.LeaseFinanceId = L.ID AND LA.AssetId IS NOT NULL
WHERE R.AssetId IS NULL AND R.ContractId IS NOT NULL AND R.LocationId IS NULL
AND L.IsCurrent=1 AND (LA.TerminationDate > R.ReceivableDueDate OR LA.IsActive=1) AND R.InvalidErrorCode IS NULL;

INSERT INTO #ReceivableExtractDetails
(
	ReceivableDetailId,
	AssetId,
	CustomerCost,
	ExtendedPrice,
	ContractId,
	LeaseFinanceId,
	ReceivableTaxType
)
SELECT
	 R.ReceivableDetailId,
	 LALA.AssetId,
	 LALA.CustomerCost_Amount, --LALA.NBV_Amount + LALA.Markup_Amount + LALA.InterimMarkup_Amount - LALA.ETCAdjustmentAmount_Amount
	 R.ExtendedPrice,
	 CT.ContractId,
	 LeaseFinanceId = CT.Id,
	 R.ReceivableTaxType
FROM SalesTaxReceivableDetailExtract R
INNER JOIN LeaseFinances CT ON R.ContractId = CT.ContractId AND R.JobStepInstanceId = @JobStepInstanceId
INNER JOIN Payoffs PO ON CT.Id = PO.LeaseFinanceId AND PO.FullPayoff = 1 AND PO.Status = @PayoffStatus
INNER JOIN PayoffAssets PA ON Po.Id= PA.PayoffId AND PA.IsActive =1
INNER JOIN LeaseAssets LALA ON LALA.Id = PA.LeaseAssetId AND LALA.IsActive = 1
INNER JOIN Assets A ON LALA.AssetId = A.Id AND LALA.IsActive = 1
AND A.FinancialType IN (@AssetFinancialTypeReal, @AssetFinancialTypePlaceholder, @AssetFinancialTypeNegativeReturn)
WHERE R.AssetId IS NULL AND R.ContractId IS NOT NULL AND R.LocationId IS NULL AND R.InvalidErrorCode IS NULL;

INSERT INTO #PayoffSundryDetail
SELECT 
	EXT.ReceivableDetailId
FROM #ReceivableExtractDetails EXT
INNER JOIN Payoffs PO ON EXT.LeaseFinanceId = PO.LeaseFinanceId AND EXT.ReceivableTaxType = 'VAT' 
INNER JOIN PayoffSundries PS ON PO.Id = PS.PayoffId AND PS.SundryId IS NOT NULL
--AND A.FinancialType IN (@AssetFinancialTypeReal, @AssetFinancialTypePlaceholder, @AssetFinancialTypeNegativeReturn)

INSERT INTO SalesTaxContractBasedSplitupReceivableDetailExtract
(
	ReceivableDetailId,
	AssetId,
	CustomerCost,
	ExtendedPrice,
	IsProcessed,
	JobStepInstanceId
)
SELECT  
	 RecExt.ReceivableDetailId,
	 RecExt.AssetId,
	 RecExt.CustomerCost, --LALA.NBV_Amount + LALA.Markup_Amount + LALA.InterimMarkup_Amount - LALA.ETCAdjustmentAmount_Amount
	 RecExt.ExtendedPrice,
     0,
	 @JobStepInstanceId
FROM #ReceivableExtractDetails RecExt
LEFT JOIN #PayoffSundryDetail PayoffSun ON RecExt.ReceivableDetailId = PayoffSun.ReceivableDetailId 
WHERE PayoffSun.ReceivableDetailId IS NULL

END

GO
