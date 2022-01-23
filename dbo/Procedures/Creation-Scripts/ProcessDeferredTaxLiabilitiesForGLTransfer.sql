SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[ProcessDeferredTaxLiabilitiesForGLTransfer]
(
@EffectiveDate DATE,
@MovePLBalance BIT,
@PLEffectiveDate DATE = NULL,
@ContractType NVARCHAR(28),
@ContractIds ContractIdCollection READONLY
)
AS
BEGIN
SET NOCOUNT ON;
CREATE TABLE #DeferredTaxGLSummary
(
ContractId BIGINT,
GLTransactionType NVARCHAR(56),
GLTemplateId BIGINT,
GLEntryItem NVARCHAR(100),
Amount DECIMAL(16,2),
IsDebit BIT,
MatchingGLTemplateId BIGINT,
MatchingFilter NVARCHAR(80),
InstrumentTypeId BIGINT,
LineofBusinesssId BIGINT,
CostCenterId BIGINT,
LegalEntityId BIGINT
)
CREATE TABLE #DeferredTaxes (ContractId BIGINT,GLTemplateId BIGINT,ClearingGLTemplateId BIGINT,DeferredTaxDate DATE,DeferredTaxAllocationAmount DECIMAL(16,2),DeferredTaxAllocationClearedAmount DECIMAL(16,2));
INSERT INTO #DeferredTaxes
SELECT C.ContractId,
DeferredTaxes.GLTemplateId DeferredTaxeGLTemplateId,
DeferredTaxClearances.GLTemplateId ClearingGLTemplateId,
DeferredTaxes.Date DeferredTaxDate,
SUM(DeferredTaxes.DefTaxLiabBalance_Amount) DeferredTaxAllocationAmount,
SUM(CASE WHEN DeferredTaxClearances.Type = 'CLR' THEN DeferredTaxClearances.ClearedAmount_Amount ELSE 0 END) DeferredTaxAllocationClearedAmount
FROM @ContractIds C
JOIN DeferredTaxes ON DeferredTaxes.ContractId = C.ContractId AND DeferredTaxes.IsAccounting=1 AND DeferredTaxes.IsGLPosted=1 AND DeferredTaxes.Date <= @EffectiveDate
LEFT JOIN DeferredTaxClearances ON DeferredTaxes.Id = DeferredTaxClearances.DeferredTaxId
WHERE (DeferredTaxClearances.DeferredTaxId IS NULL OR DeferredTaxClearances.ClearedDate <= @EffectiveDate)
GROUP BY C.ContractId,DeferredTaxes.GLTemplateId,DeferredTaxClearances.GLTemplateId,DeferredTaxes.Date
IF NOT EXISTS(SELECT ContractId FROM #DeferredTaxes)
RETURN
INSERT INTO #DeferredTaxGLSummary(ContractId,GLTransactionType,GLTemplateId,GLEntryItem,Amount,IsDebit)
SELECT
DeferredTax.ContractId,
'DeferredTaxLiability',
DeferredTax.GLTemplateId,
'DeferredTaxAllocation',
SUM(DeferredTax.DeferredTaxAllocationAmount - DeferredTax.DeferredTaxAllocationClearedAmount),
0
FROM #DeferredTaxes DeferredTax
GROUP BY DeferredTax.GLTemplateId,DeferredTax.ContractId
INSERT INTO #DeferredTaxGLSummary(ContractId,GLTransactionType,GLTemplateId,GLEntryItem,Amount,IsDebit)
SELECT
DeferredTax.ContractId,
GLTransactionTypes.Name,
DeferredTax.ClearingGLTemplateId,
'DeferredTaxPayable',
SUM(DeferredTaxAllocationClearedAmount),
0
FROM #DeferredTaxes DeferredTax
JOIN GLTemplates ON DeferredTax.ClearingGLTemplateId = GLTemplates.Id
JOIN GLTransactionTypes ON GLTemplates.GLTransactionTypeId = GLTransactionTypes.Id
GROUP BY DeferredTax.ClearingGLTemplateId,DeferredTax.ContractId,GLTransactionTypes.Name
IF(@MovePLBalance=1)
BEGIN
INSERT INTO #DeferredTaxGLSummary(ContractId,GLTransactionType,GLTemplateId,GLEntryItem,Amount,IsDebit)
SELECT
DeferredTax.ContractId,
'DeferredTaxLiability',
DeferredTax.GLTemplateId,
'DeferredTaxOffset',
SUM(DeferredTaxAllocationAmount),
1
FROM #DeferredTaxes DeferredTax
JOIN GLTemplates ON DeferredTax.ClearingGLTemplateId = GLTemplates.Id
JOIN GLTransactionTypes ON GLTemplates.GLTransactionTypeId = GLTransactionTypes.Id
GROUP BY DeferredTax.GLTemplateId,DeferredTax.ContractId
END
SELECT * FROM #DeferredTaxGLSummary
IF OBJECT_ID('tempdb..#DeferredTaxGLSummary') IS NOT NULL
DROP TABLE #DeferredTaxGLSummary
IF OBJECT_ID('tempdb..#DeferredTaxes') IS NOT NULL
DROP TABLE #DeferredTaxes
END

GO
