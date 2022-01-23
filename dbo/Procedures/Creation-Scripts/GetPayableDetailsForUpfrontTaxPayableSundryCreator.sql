SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[GetPayableDetailsForUpfrontTaxPayableSundryCreator]
(
@JobStepInstanceId BIGINT NULL,
@IsToProcessAccrualBasedReceivables BIT,
@LeaseFinanceId BIGINT NULL,
@IsCapitalizeUpfront BIT,
@ReceiptId BIGINT NULL,
@IsFromManualSalesTax BIT,
@ReceivableDetailIds NVARCHAR(MAX) NULL,
@CTEntity NVARCHAR(5),
@VendorSalesTaxResponsibility NVARCHAR(10),
@ReceiptStatusPosted NVARCHAR(15),
@UCTaxBasisType NVARCHAR(5),
@URTaxBasisType NVARCHAR(5),
@CashBasedTaxPreference NVARCHAR(15),
@AccrualBasedTaxPreference NVARCHAR(15),
@NonCashReceiptClassification NVARCHAR(23),
@ReceiptStatusCompleted NVARCHAR(15)
)
AS
BEGIN
CREATE TABLE #ReceivableDetailIds
( Id BIGINT PRIMARY KEY
);
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
IF (@IsCapitalizeUpfront = 0 AND @IsToProcessAccrualBasedReceivables = 1)
BEGIN
IF (@IsFromManualSalesTax = 0)
BEGIN
INSERT INTO #ReceivableDetailIds
SELECT DISTINCT  ReceivableDetailId
FROM SalesTaxReceivableDetailExtract
WHERE JobStepInstanceId = @JobStepInstanceId
AND InvalidErrorCode IS NULL
END
ELSE
BEGIN
INSERT INTO #ReceivableDetailIds
SELECT DISTINCT * FROM ConvertCSVToBigIntTable(@ReceivableDetailIds,',');
END
SELECT AdjustmentBasisReceivableDetailId
INTO #AdjustmentReceivableDetails
FROM ReceivableDetails AdjustmentReceivable
JOIN #ReceivableDetailIds RDIds ON AdjustmentReceivable.AdjustmentBasisReceivableDetailId = RdIds.Id
WHERE AdjustmentReceivable.IsActive = 1
;WITH CTE_LeaseAsset
AS(
SELECT RD.Id ReceivableDetailID,
LA.AssetId AS AssetId,
LA.Id AS LeaseAssetId,
PI.VendorId AS VendorId
FROM
ReceivableDetails RD
JOIN #ReceivableDetailIds RDids ON RDids.ID = RD.Id
JOIN LeaseAssets LA ON RD.AssetId = LA.AssetId
JOIN PayableInvoiceAssets PIA ON PIA.AssetId = LA.AssetId AND PIA.IsActive = 1
JOIN PayableInvoices PI ON PI.Id = PIA.PayableInvoiceId AND PI.ParentPayableInvoiceId IS NULL
WHERE   RD.IsActive=1
AND RD.IsTaxAssessed = 1
AND LA.IsActive = 1
AND LA.Capitalizationtype ='_'
UNION ALL
SELECT RD.Id ReceivableDetailID,
LA.AssetId AS AssetId,
LA.Id AS LeaseAssetId,
PI.VendorId AS VendorId
FROM ReceivableDetails RD
JOIN #ReceivableDetailIds RDids ON RDids.ID = RD.Id
JOIN LeaseAssets LA ON RD.AssetId = LA.AssetId
JOIN LeaseAssets CFLA ON CFLA.Id = LA.CapitalizedForId
JOIN PayableInvoiceAssets PIA ON PIA.AssetId = CFLA.AssetId AND PIA.IsActive = 1
JOIN PayableInvoices PI ON PI.Id = PIA.PayableInvoiceId AND PI.ParentPayableInvoiceId IS NULL
WHERE   RD.IsActive=1
AND RD.IsTaxAssessed = 1
AND LA.IsActive = 1
AND LA.Capitalizationtype  IN ('CapitalizedInterimRent' , 'CapitalizedInterimInterest')
)
SELECT DISTINCT
R.DueDate AS PayableDueDate,
R.LegalEntityId AS LegalEntityId,
C.Id AS ContractId,
LF.CustomerId AS CustomerId,
LF.LineofBusinessId AS LineofBusinessId,
LF.InstrumentTypeId AS InstrumentTypeId,
RTD.Amount_Currency AS Currency,
CTE.VendorId AS VendorId,
CASE WHEN STRH.EffectiveTillDate IS NOT NULL AND  STRH.EffectiveTillDate>=R.DueDate THEN STRH.VendorRemitToId ELSE LA.VendorRemitToId END AS VendorRemitToId,
LF.VendorPayableCodeId  AS PayableCodeId,
RTD.Amount_Amount*RTD.UpfrontPayableFactor AS UpfrontSaleTaxAmount,
CTE.AssetID AS AssetId,
RD.Id AS ReceivableDetailId,
C.CurrencyId,
C.CostCenterId,
LF.BranchId
FROM Receivables R
JOIN ReceivableDetails RD on R.Id = Rd.ReceivableId
JOIN Contracts C ON C.Id = R.EntityId AND R.EntityType = @CTEntity
JOIN LeaseFinances LF ON LF.ContractId = C.Id AND LF.IsCurrent=1
JOIN LeaseFinanceDetails LFD ON LFD.Id = LF.Id
JOIN LegalEntities LE ON LE.Id = LF.LegalEntityId
JOIN ReceivableTaxDetails RTD ON RTD.ReceivableDetailId = RD.Id
JOIN #ReceivableDetailIds RDids ON RDids.ID = RD.Id
JOIN LeaseAssets LA ON LA.LeaseFinanceId = LF.Id AND RD.AssetId = LA.AssetId AND LA.IsActive =1
JOIN CTE_LeaseAsset CTE ON CTE.LeaseAssetId = LA.ID
LEFT JOIN ContractSalesTaxRemittanceResponsibilityHistories STRH ON STRH.AssetId = RD.AssetId AND LF.ContractId = STRH.ContractId
LEFT JOIN #AdjustmentReceivableDetails ARD ON ARD.AdjustmentBasisReceivableDetailId = RD.Id
WHERE R.IsActive = 1
AND RD.IsActive = 1
AND LFD.CapitalizeUpfrontSalesTax = @IsCapitalizeUpfront
AND (@IsToProcessAccrualBasedReceivables = 1 AND LE.TaxRemittancePreference = @AccrualBasedTaxPreference)
AND RTD.IsActive = 1
AND RD.IsTaxAssessed = 1
AND ( (RTD.TaxBasisType = @URTaxBasisType AND RTD.FairMarketValue_Amount <> 0.00) OR (RTD.TaxBasisType = @UCTaxBasisType AND RTD.Cost_Amount <> 0.00))
AND ((STRH.EffectiveTillDate IS NOT NULL AND  STRH.EffectiveTillDate>=R.DueDate AND STRH.SalesTaxRemittanceResponsibility = @VendorSalesTaxResponsibility)
OR (STRH.EffectiveTillDate IS NOT NULL AND  STRH.EffectiveTillDate < R.DueDate AND LA.SalesTaxRemittanceResponsibility =@VendorSalesTaxResponsibility )
OR (STRH.EffectiveTillDate IS NULL AND LA.SalesTaxRemittanceResponsibility =@VendorSalesTaxResponsibility ))
AND RTD.Amount_Amount <> 0.00
AND RD.AdjustmentBasisReceivableDetailId IS NULL
AND ARD.AdjustmentBasisReceivableDetailId IS NULL
AND RTD.UpfrontPayableFactor <> 0
DROP TABLE #ReceivableDetailIds
DROP TABLE #AdjustmentReceivableDetails
END
ELSE IF (@IsCapitalizeUpfront = 0 AND @IsToProcessAccrualBasedReceivables = 0)
BEGIN
SELECT AdjustmentBasisReceivableDetailId
INTO #AdjustmentReceivableDetailInfos
FROM ReceivableDetails AdjustmentReceivable
JOIN ReceiptApplicationReceivableDetails RARD ON RARD.ReceivableDetailId = AdjustmentReceivable.AdjustmentBasisReceivableDetailId
JOIN ReceiptApplications RA ON RARD.ReceiptApplicationId = RA.ID
JOIN Receipts R ON R.Id = RA.ReceiptId
WHERE AdjustmentReceivable.IsActive = 1
AND RARD.IsActive = 1
AND R.Id = @ReceiptId
AND (R.Status = @ReceiptStatusPosted OR (R.ReceiptClassification = @NonCashReceiptClassification AND R.Status = @ReceiptStatusCompleted))
;WITH CTE_LeaseAssets
AS
(
SELECT RD.Id AS ReceivableDetailId,
LA.AssetId As AssetId,
LA.ID AS LeaseAssetId,
PI.VendorId
FROM
Receipts R
JOIN ReceiptApplications RA ON R.ID = RA.ReceiptId
JOIN ReceiptApplicationReceivableDetails RARD ON RA.Id = RARD.ReceiptApplicationId
JOIN ReceivableDetails RD ON RD.Id = RARD.ReceivableDetailId
JOIN LeaseAssets LA ON LA.AssetId = RD.AssetId
JOIN PayableInvoiceAssets PIA ON PIA.AssetId = LA.AssetId AND PIA.IsActive = 1
JOIN PayableInvoices PI ON PI.Id = PIA.PayableInvoiceId AND PI.ParentPayableInvoiceId IS NULL
WHERE (R.Status = @ReceiptStatusPosted OR (R.ReceiptClassification = @NonCashReceiptClassification AND R.Status = @ReceiptStatusCompleted))
AND RD.IsActive = 1
AND R.Id =@ReceiptId
AND RD.IsTaxAssessed = 1
AND LA.Capitalizationtype ='_'
UNION ALL
SELECT RD.Id AS ReceivableDetailId,
LA.AssetId As AssetId,
LA.ID AS LeaseAssetId,
PI.VendorId
FROM
Receipts R
JOIN ReceiptApplications RA ON R.ID = RA.ReceiptId
JOIN ReceiptApplicationReceivableDetails RARD ON RA.Id = RARD.ReceiptApplicationId
JOIN ReceivableDetails RD ON RD.Id = RARD.ReceivableDetailId
JOIN LeaseAssets LA ON LA.AssetId = RD.AssetId
JOIN LeaseAssets CFLA ON CFLA.Id = LA.CapitalizedForId
JOIN PayableInvoiceAssets PIA ON PIA.AssetId = CFLA.AssetId AND PIA.IsActive = 1
JOIN PayableInvoices PI ON PI.Id = PIA.PayableInvoiceId AND PI.ParentPayableInvoiceId IS NULL
WHERE (R.Status = @ReceiptStatusPosted OR (R.ReceiptClassification = @NonCashReceiptClassification AND R.Status = @ReceiptStatusCompleted))
AND RD.IsActive = 1
AND R.Id =@ReceiptId
AND RD.IsTaxAssessed = 1
AND LA.Capitalizationtype  IN ('CapitalizedInterimRent' , 'CapitalizedInterimInterest')
)
,CTE_PayableDetailsForReceipt
AS(
SELECT DISTINCT
Re.DueDate AS PayableDueDate,
LF.LegalEntityId AS LegalEntityId,
C.Id AS ContractId,
LF.CustomerId AS CustomerId,
LF.LineofBusinessId AS LineofBusinessId,
LF.InstrumentTypeId AS InstrumentTypeId,
R.ReceiptAmount_Currency AS Currency,
CTE.VendorId AS VendorId,
CASE WHEN STRH.EffectiveTillDate IS NOT NULL AND  STRH.EffectiveTillDate>=Re.DueDate THEN STRH.VendorRemitToId  ELSE LA.VendorRemitToId END AS VendorRemitToId,
LF.VendorPayableCodeId  AS PayableCodeId,
RARD.TaxApplied_Amount * RTD.UpfrontPayableFactor AS UpfrontSaleTaxAmount,
CTE.AssetID AS AssetId,
R.Id AS ReceiptId,
C.CurrencyId,
C.CostCenterId,
LF.BranchId,
RD.Id AS ReceivableDetailId,
RARD.Id AS ReceiptApplicationReceivableDetailId
FROM ReceivableDetails RD
JOIN ReceiptApplicationReceivableDetails RARD ON RARD.ReceivableDetailId = RD.Id
JOIN ReceiptApplications RA ON RARD.ReceiptApplicationId = RA.ID
JOIN Receipts R ON R.Id = RA.ReceiptId
JOIN Receivables Re ON Re.Id = Rd.ReceivableId
JOIN Contracts C ON C.Id = Re.EntityId AND Re.EntityType = @CTEntity
JOIN LeaseFinances LF ON LF.ContractId = C.Id AND LF.IsCurrent=1
JOIN LeaseFinanceDetails LFD ON LFD.Id = LF.Id
JOIN LegalEntities LE ON LE.Id = LF.LegalEntityId
JOIN ReceivableTaxDetails RTD ON RTD.ReceivableDetailId = RD.Id
JOIN LeaseAssets LA ON LA.LeaseFinanceId = LF.Id AND RD.AssetId = LA.AssetId AND LA.IsActive =1
JOIN CTE_LeaseAssets CTE ON CTE.LeaseAssetId = LA.Id
LEFT JOIN ContractSalesTaxRemittanceResponsibilityHistories STRH ON STRH.AssetId = RD.AssetId AND LF.ContractId = STRH.ContractId
LEFT JOIN #AdjustmentReceivableDetailInfos ARD ON ARD.AdjustmentBasisReceivableDetailId = RD.Id
WHERE (R.Status = @ReceiptStatusPosted OR (R.ReceiptClassification = @NonCashReceiptClassification AND R.Status = @ReceiptStatusCompleted))
AND RD.IsActive = 1
AND R.Id =@ReceiptId
AND LFD.CapitalizeUpfrontSalesTax = @IsCapitalizeUpfront
AND  (@IsToProcessAccrualBasedReceivables = 0 AND LE.TaxRemittancePreference=@CashBasedTaxPreference)
AND RD.IsTaxAssessed = 1
AND ( (RTD.TaxBasisType = @URTaxBasisType AND RTD.FairMarketValue_Amount <> 0.00) OR (RTD.TaxBasisType = @UCTaxBasisType AND RTD.Cost_Amount <> 0.00))
AND ((STRH.EffectiveTillDate IS NOT NULL AND  STRH.EffectiveTillDate>=Re.DueDate AND STRH.SalesTaxRemittanceResponsibility = @VendorSalesTaxResponsibility)
OR (STRH.EffectiveTillDate IS NOT NULL AND  STRH.EffectiveTillDate < Re.DueDate AND LA.SalesTaxRemittanceResponsibility =@VendorSalesTaxResponsibility )
OR (STRH.EffectiveTillDate IS NULL AND LA.SalesTaxRemittanceResponsibility =@VendorSalesTaxResponsibility ))
AND RARD.IsActive = 1
AND Re.IsActive = 1
AND RTD.IsActive = 1
AND RARD.TaxApplied_Amount <> 0.00
AND RD.AdjustmentBasisReceivableDetailId IS NULL
AND ARD.AdjustmentBasisReceivableDetailId IS NULL
)
SELECT DISTINCT
PayableDueDate,
LegalEntityId,
ContractId,
CustomerId,
LineofBusinessId,
InstrumentTypeId,
Currency,
VendorId,
VendorRemitToId,
PayableCodeId,
SUM(UpfrontSaleTaxAmount) AS UpfrontSaleTaxAmount,
AssetId,
ReceiptId,
CurrencyId,
CostCenterId,
BranchId,
ReceivableDetailId
FROM CTE_PayableDetailsForReceipt
GROUP BY PayableDueDate,
LegalEntityId,
ContractId,
CustomerId,
LineofBusinessId,
InstrumentTypeId,
Currency,
VendorId,
VendorRemitToId,
PayableCodeId,
AssetId,
ReceiptId,
CurrencyId,
CostCenterId,
BranchId,
ReceivableDetailId
DROP TABLE #AdjustmentReceivableDetailInfos
END
ELSE IF @IsCapitalizeUpfront = 1
BEGIN
;WITH CTE_LeaseAsset
AS(
SELECT LF.Id LeaseFinanceId,
LA.AssetId AS AssetId,
LA.Id AS LeaseAssetId,
PI.VendorId AS VendorId
FROM
LeaseFinances LF
JOIN LeaseAssets LA ON LF.Id = LA.LeaseFinanceId
JOIN PayableInvoiceAssets PIA ON PIA.AssetId = LA.AssetId AND PIA.IsActive = 1
JOIN PayableInvoices PI ON PI.Id = PIA.PayableInvoiceId AND PI.ParentPayableInvoiceId IS NULL
WHERE LF.Id = @LeaseFinanceId
AND LA.AssessedUpfrontTax_Amount <> 0.00
AND LA.IsActive = 1
AND LA.Capitalizationtype ='_'
UNION ALL
SELECT LF.Id LeaseFinanceId,
LA.AssetId AS AssetId,
LA.Id AS LeaseAssetId,
PI.VendorId AS VendorId
FROM
LeaseFinances LF
JOIN LeaseAssets LA ON LF.Id = LA.LeaseFinanceId
JOIN LeaseAssets CFLA ON CFLA.Id = LA.CapitalizedForId
JOIN PayableInvoiceAssets PIA ON PIA.AssetId = CFLA.AssetId AND PIA.IsActive = 1
JOIN PayableInvoices PI ON PI.Id = PIA.PayableInvoiceId AND PI.ParentPayableInvoiceId IS NULL
WHERE LF.Id = @LeaseFinanceId
AND LA.AssessedUpfrontTax_Amount <> 0.00
AND LA.IsActive = 1
AND LA.Capitalizationtype  IN ('CapitalizedInterimRent' , 'CapitalizedInterimInterest')
)
SELECT DISTINCT
LFD.CommencementDate AS PayableDueDate,
LF.LegalEntityId AS LegalEntityId,
LF.ContractId AS ContractId,
LF.CustomerId AS CustomerId,
LF.LineofBusinessId AS LineofBusinessId,
LF.InstrumentTypeId AS InstrumentTypeId,
LA.AssessedUpfrontTax_Currency AS Currency,
CTE.VendorId AS VendorId,
CASE WHEN STRH.EffectiveTillDate IS NOT NULL AND  STRH.EffectiveTillDate>=LFD.CommencementDate THEN STRH.VendorRemitToId ELSE LA.VendorRemitToId END AS VendorRemitToId,
LF.VendorPayableCodeId AS PayableCodeId,
LA.AssessedUpfrontTax_Amount AS UpfrontSaleTaxAmount,
CTE.LeaseAssetId AS LeaseAssetId,
CTE.AssetId AS AssetId,
C.CurrencyId,
C.CostCenterId,
LF.BranchId
FROM LeaseFinances LF
JOIN Contracts C ON LF.ContractId = C.Id
JOIN LeaseFinanceDetails LFD ON LFD.Id = LF.Id
JOIN LeaseAssets LA ON LA.LeaseFinanceId = LF.Id AND LA.IsActive = 1
JOIN CTE_LeaseAsset CTE ON LA.Id = CTE.LeaseAssetId
LEFT JOIN ContractSalesTaxRemittanceResponsibilityHistories STRH ON STRH.AssetId = LA.AssetId AND LF.ContractId = STRH.ContractId
WHERE LF.Id = @LeaseFinanceId
AND LA.AssessedUpfrontTax_Amount <> 0.00
AND ((STRH.EffectiveTillDate IS NOT NULL AND  STRH.EffectiveTillDate>=LFD.CommencementDate AND STRH.SalesTaxRemittanceResponsibility = @VendorSalesTaxResponsibility)
OR (STRH.EffectiveTillDate IS NOT NULL AND  STRH.EffectiveTillDate < LFD.CommencementDate AND LA.SalesTaxRemittanceResponsibility =@VendorSalesTaxResponsibility )
OR (STRH.EffectiveTillDate IS NULL AND LA.SalesTaxRemittanceResponsibility =@VendorSalesTaxResponsibility ))
END
END

GO
