SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[GetDetailForDeferredTax]
(
@DefTaxContractTableType DefTaxContractTableType READONLY
)
AS
BEGIN
SET NOCOUNT ON;
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
SELECT
MIN(Date) AS Date,
DT.ContractId
INTO #ReprocessFlagSetDate
FROM DeferredTaxes DT
JOIN  @DefTaxContractTableType CT
ON DT.ContractId = CT.ContractId
AND IsReprocess = 1 AND IsScheduled = 1
GROUP BY DT.ContractId;
;
SELECT
MIN(Date) AS Date,
DT.ContractId
INTO #DefTaxStartDate
FROM DeferredTaxes DT
JOIN  @DefTaxContractTableType CT
ON DT.ContractId = CT.ContractId
AND DT.IsGLPosted = 1 AND IsScheduled = 1
GROUP BY DT.ContractId;
;
SELECT
MAX(Date) AS Date,
DT.ContractId
INTO #DefTaxRunDate
FROM DeferredTaxes DT
JOIN  @DefTaxContractTableType CT
ON DT.ContractId = CT.ContractId
AND DT.IsGLPosted = 1 AND IsScheduled = 1
GROUP BY DT.ContractId
;
SELECT * INTO #DeferredTaxDetail FROM (
SELECT
LL.ContractId,
RFS.Date ReprocessFlagSetDate,
RunDate = (CASE WHEN DTS.Date = DTR.Date THEN DTR.Date ELSE CAST(NULL AS DATE) END),
LL.DeferredTaxGLTemplateId GlTemplateId,
CAST(0 AS BIT) AS IsComputationPending
FROM LeveragedLeases LL
INNER JOIN Contracts C ON C.Id = LL.ContractId  AND LL.IsCurrent = 1
INNER JOIN @DefTaxContractTableType CT ON CT.ContractId = C.Id AND CT.ContractType = C.ContractType
LEFT JOIN #ReprocessFlagSetDate RFS ON RFS.ContractId = LL.ContractId
LEFT JOIN #DefTaxStartDate DTS ON DTS.ContractId = LL.ContractId
LEFT JOIN #DefTaxRunDate DTR ON DTR.ContractId = LL.ContractId
AND (RFS.Date IS NULL OR DTR.Date <= RFS.Date)
UNION
SELECT
LF.ContractId,
RFS.Date ReprocessFlagSetDate,
RunDate = (CASE WHEN DTS.Date = DTR.Date THEN DTR.Date ELSE CAST(NULL AS DATE) END),
LFD.DeferredTaxGLTemplateId GlTemplateId,
CAST(0 AS BIT) AS IsComputationPending
FROM LeaseFinances LF
INNER JOIN LeaseFinanceDetails LFD ON LF.Id = LFD.Id
INNER JOIN Contracts C ON C.Id = LF.ContractId AND LF.IsCurrent = 1
INNER JOIN @DefTaxContractTableType CT ON CT.ContractId = C.Id AND CT.ContractType = C.ContractType
LEFT JOIN #ReprocessFlagSetDate RFS ON RFS.ContractId = LF.ContractId
LEFT JOIN #DefTaxStartDate DTS ON DTS.ContractId = LF.ContractId
LEFT JOIN #DefTaxRunDate DTR ON DTR.ContractId = LF.ContractId
AND (RFS.Date IS NULL OR DTR.Date <= RFS.Date)
) AS Temp
;
SELECT
LF.ContractId,
CAST(1 AS BIT) AS IsComputationPending
INTO #TaxDepEntityDetails
FROM LeaseFinances LF
JOIN @DefTaxContractTableType CT ON LF.ContractId = CT.ContractId  AND LF.IsCurrent = 1
JOIN LeaseAssets LA ON LF.Id = LA.LeaseFinanceId AND LA.IsActive = 1
JOIN TaxDepEntities TDE ON TDE.AssetId = LA.AssetId AND TDE.IsActive = 1
AND TDE.ContractId = LF.ContractId AND TDE.IsComputationPending = 1
GROUP BY LF.ContractId
;
UPDATE #DeferredTaxDetail
SET #DeferredTaxDetail.IsComputationPending = ISNULL(#TaxDepEntityDetails.IsComputationPending,CAST(0 AS BIT))
FROM #DeferredTaxDetail LEFT JOIN #TaxDepEntityDetails
ON #DeferredTaxDetail.ContractId = #TaxDepEntityDetails.ContractId
SELECT
ContractId,
CAST(ReprocessFlagSetDate AS DATE) ReprocessFlagSetDate,
CAST(RunDate AS DATE) RunDate,
GlTemplateId,
IsComputationPending
FROM #DeferredTaxDetail;
;
SELECT
CTR.EffectiveDate,
CT.ContractId,
LE.Name LegalEntityName
FROM Contracts C
INNER JOIN @DefTaxContractTableType CT ON C.Id = CT.ContractId
INNER JOIN LeaseFinances LF ON C.Id = LF.ContractId
INNER JOIN LegalEntities LE ON LE.Id = LF.LegalEntityId
LEFT JOIN CorporateTaxRates CTR ON LE.Id = CTR.LegalEntityId AND CTR.IsActive = 1
WHERE LF.IsCurrent = 1
;
SELECT
LF.ContractId,
LF.Id,
LF.IsCurrent,
LFD.MaturityDate,
LFD.CommencementDate,
LIS.IncomeDateYear,
FromDate OpenPeriodStartDate
INTO #LeaseFinanceInfo
FROM LeaseFinances LF
INNER JOIN LeaseFinanceDetails LFD ON LF.Id = LFD.Id
INNER JOIN Contracts C ON C.Id = LF.ContractId AND LF.IsCurrent = 1
INNER JOIN @DefTaxContractTableType CT ON CT.ContractId = C.Id AND CT.ContractType = C.ContractType
INNER JOIN (
SELECT DISTINCT DATEPART(yyyy,LIS.IncomeDate) IncomeDateYear, CT.ContractId FROM LeaseIncomeSchedules LIS
JOIN LeaseFinances LF ON LIS.LeaseFinanceId = LF.Id
JOIN @DefTaxContractTableType CT ON CT.ContractId = LF.ContractId AND CT.ContractType = 'Lease'
INNER JOIN #DeferredTaxDetail DT ON LF.ContractId = DT.ContractId
WHERE (DT.RunDate IS NULL OR LIS.IncomeDate > DT.RunDate)
AND LIS.IncomeType <> 'InterimInterest' AND LIS.IncomeType <> 'InterimRent'
) AS LIS ON LIS.ContractId = CT.ContractId
LEFT JOIN GLFinancialOpenPeriods GL ON LF.LegalEntityId = GL.LegalEntityId AND GL.IsCurrent = 1
;
SELECT  LF.ContractId, LF.CommencementDate,LF.MaturityDate, LF.OpenPeriodStartDate
,STUFF((SELECT DISTINCT ', ' + CAST(IncomeDateYear AS VARCHAR(10)) [text()]
FROM #LeaseFinanceInfo
WHERE ContractId = LF.ContractId
FOR XML PATH(''), TYPE)
.value('.','NVARCHAR(MAX)'),1,2,' ') IncomeDateYearCSV
FROM #LeaseFinanceInfo LF
GROUP BY LF.ContractId, LF.CommencementDate, LF.MaturityDate, LF.OpenPeriodStartDate
SELECT
C.Id ContractId,
COUNT(LA.Id) AS AssetCount
FROM Contracts C
JOIN LeaseFinances LF ON C.Id = LF.ContractId AND LF.IsCurrent = 1
JOIN LeaseAssets LA ON LF.Id = LA.LeaseFinanceId AND LA.IsActive = 1
INNER JOIN @DefTaxContractTableType CT ON CT.ContractId = C.Id AND CT.ContractType = C.ContractType
GROUP BY
C.Id
END

GO
