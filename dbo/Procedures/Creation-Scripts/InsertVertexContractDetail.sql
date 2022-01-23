SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

--SP to fetch contract Details
CREATE PROCEDURE [dbo].[InsertVertexContractDetail]
(
@NoneSyndicationType NVARCHAR(100),
@JobStepInstanceId BIGINT
)
AS
BEGIN
CREATE TABLE #ContractDetails
(
ContractId				BIGINT,
TaxRemittanceType		NVARCHAR(100),
SequenceNumber			NVARCHAR(100),
IsSyndicated			BIT,
TaxAssessmentLevel		NVARCHAR(100),
LineofBusinessId		NVARCHAR(100),
DealProductTypeId		BIGINT,
CurrencyId				BIGINT
)
;WITH CTE_DistinctContractIds AS
(
SELECT
DISTINCT ContractId
FROM
SalesTaxReceivableDetailExtract
WHERE
IsVertexSupported = 1 AND InvalidErrorCode IS NULL AND JobStepInstanceId = @JobStepInstanceId
)
INSERT INTO #ContractDetails
(ContractId, TaxRemittanceType, SequenceNumber, IsSyndicated, TaxAssessmentLevel, LineofBusinessId, DealProductTypeId, CurrencyId)
SELECT
C.Id
,REPLACE(C.SalesTaxRemittanceMethod, 'Based','') -- We can change the enum value, so we dont need to trim
,C.SequenceNumber
,CASE WHEN C.SyndicationType = @NoneSyndicationType THEN 0 ELSE 1 END
,C.TaxAssessmentLevel
,C.LineofBusinessId
,C.DealProductTypeId
,C.CurrencyId
FROM CTE_DistinctContractIds DC
JOIN Contracts C ON DC.ContractId = C.Id;
;WITH CTE_GLOrg AS
(
SELECT
GLOrg.ContractId,
GL.BusinessCode
FROM
(
SELECT
CT.ContractId
,MAX(GL.Id) GLOrgStructureConfigId
FROM #ContractDetails CT
INNER JOIN LeaseFinances LF ON CT.ContractId = LF.ContractId 
INNER JOIN LeaseFinanceDetails LFD ON LF.Id = LFD.Id AND (LF.IsCurrent = 1 OR LFD.CreateSoftAssetsForCappedSalesTax = 1)
INNER JOIN GLOrgStructureConfigs GL ON GL.LegalEntityId = LF.LegalEntityId
AND GL.CostCenterId = LF.CostCenterId AND GL.LineofBusinessId = CT.LineofBusinessId
AND GL.IsActive = 1
GROUP BY CT.ContractId
) GLOrg
INNER JOIN GLOrgStructureConfigs GL ON GLOrg.GLOrgStructureConfigId = GL.Id
)
INSERT INTO VertexContractDetailExtract
	(ContractId, TaxRemittanceType, SequenceNumber, IsSyndicated, TaxAssessmentLevel, LineofBusinessId, DealProductTypeId, 
	 Term, ShortLeaseType, IsContractCapitalizeUpfront, LeaseFinanceId, NumberOfInceptionPayments, 
	 ClassificationContractType, CommencementDate, IsLease, BusCode,JobStepInstanceId,MaturityDate)
SELECT [ContractId], [TaxRemittanceType], [SequenceNumber], [IsSyndicated], [TaxAssessmentLevel], [LineofBusinessId], [DealProductTypeId], 
	 [Term], [ShortLeaseType], [IsContractCapitalizeUpfront], [LeaseFinanceId], [NumberOfInceptionPayments], 
	 [ClassificationContractType], [CommencementDate], [IsLease], [BusCode],[JobStepInstanceId],[MaturityDate] FROM
(
SELECT
	 CT.ContractId
	,TaxRemittanceType
	,SequenceNumber
	,IsSyndicated
	,TaxAssessmentLevel
	,CT.LineofBusinessId
	,DealProductTypeId
	,CAST((DATEDIFF(day,LFD.CommencementDate,LFD.MaturityDate) + 1) AS DECIMAL(10,2)) Term
	,DPT.LeaseType ShortLeaseType
	,LFD.CapitalizeUpfrontSalesTax IsContractCapitalizeUpfront
	,LF.Id AS LeaseFinanceId
	,LFD.NumberOfInceptionPayments
	,LFD.LeaseContractType ClassificationContractType
	,LFD.CommencementDate
	,1 AS IsLease
	,GLOrg.BusinessCode BusCode
	,@JobStepInstanceId JobStepInstanceId
	,LFD.MaturityDate
	,ROW_NUMBER() OVER (PARTITION BY LF.ContractId,LF.Id ORDER BY LF.Id DESC) RowNumber
FROM #ContractDetails CT
INNER JOIN LeaseFinances LF ON CT.ContractId = LF.ContractId
INNER JOIN LeaseFinanceDetails LFD ON LF.Id = LFD.Id AND (LF.IsCurrent = 1 OR (LFD.CreateSoftAssetsForCappedSalesTax = 1 AND LF.BookingStatus<>'Inactive'))
INNER JOIN DealProductTypes DPT ON CT.DealProductTypeId = DPT.Id
LEFT JOIN CTE_GLOrg GLOrg ON GLOrg.ContractId = CT.ContractId) AS VertexContractDetails
WHERE VertexContractDetails.RowNumber = 1;

;WITH CTE_GLOrg AS
(
SELECT
GLOrg.ContractId,
GL.BusinessCode
FROM
(
SELECT
CT.ContractId
,MAX(GL.Id) GLOrgStructureConfigId
FROM #ContractDetails CT
INNER JOIN LoanFinances LF ON CT.ContractId = LF.ContractId AND LF.IsCurrent = 1
INNER JOIN GLOrgStructureConfigs GL ON GL.LegalEntityId = LF.LegalEntityId
AND GL.CostCenterId = LF.CostCenterId AND GL.LineofBusinessId = CT.LineofBusinessId
AND GL.IsActive = 1
GROUP BY CT.ContractId
) GLOrg
INNER JOIN GLOrgStructureConfigs GL ON GLOrg.GLOrgStructureConfigId = GL.Id
)
INSERT INTO VertexContractDetailExtract
	(ContractId, TaxRemittanceType, SequenceNumber, IsSyndicated, TaxAssessmentLevel, LineofBusinessId, DealProductTypeId, 
	 Term, IsContractCapitalizeUpfront, LeaseFinanceId, NumberOfInceptionPayments, ClassificationContractType, 
	 IsLease, BusCode, CommencementDate,JobStepInstanceId,MaturityDate)
SELECT 
     CT.ContractId
	,TaxRemittanceType
	,SequenceNumber
	,IsSyndicated
	,TaxAssessmentLevel
	,CT.LineofBusinessId
	,DealProductTypeId
	,0 AS Term
	,0 AS IsContractCapitalizeUpfront
	,LF.Id AS LeaseFinanceId
	,0 AS NumberOfInceptionPayments
	,'_' AS ClassificationContractType
	,0 AS IsLease
	,GLOrg.BusinessCode
	,LF.CommencementDate
	,@JobStepInstanceId
	,LF.MaturityDate
FROM #ContractDetails CT
INNER JOIN LoanFinances LF ON CT.ContractId = LF.ContractId AND LF.IsCurrent = 1
LEFT JOIN CTE_GLOrg GLOrg ON GLOrg.ContractId = CT.ContractId
;


SELECT CommonAssetDetail.ContractId,CommonAssetDetail.LeaseFinanceId INTO #ContractDetailsForOldLeaseFinance FROM SalesTaxAssetDetailExtract CommonAssetDetail
LEFT JOIN VertexContractDetailExtract ContractDetail ON CommonAssetDetail.LeaseFinanceId = ContractDetail.LeaseFinanceId AND CommonAssetDetail.ContractId = ContractDetail.ContractId AND ContractDetail.JobstepInstanceId = @JobstepInstanceId
WHERE CommonAssetDetail.JobstepInstanceId = @JobstepInstanceId AND CommonAssetDetail.IsAssetFromOldFinance=1 AND ContractDetail.LeaseFinanceId IS NULL
GROUP BY  CommonAssetDetail.ContractId,CommonAssetDetail.LeaseFinanceId

;WITH CTE_GLOrg AS
(
SELECT
GLOrg.ContractId,
GL.BusinessCode
FROM
(
SELECT
CT.ContractId
,MAX(GL.Id) GLOrgStructureConfigId
FROM #ContractDetails CT
INNER JOIN LeaseFinances LF ON CT.ContractId = LF.ContractId 
INNER JOIN LeaseFinanceDetails LFD ON LF.Id = LFD.Id AND LF.IsCurrent = 0
INNER JOIN #ContractDetailsForOldLeaseFinance OldFinance ON OldFinance.ContractId= CT.ContractId AND OldFinance.LeaseFinanceId = LF.Id
INNER JOIN GLOrgStructureConfigs GL ON GL.LegalEntityId = LF.LegalEntityId
AND GL.CostCenterId = LF.CostCenterId AND GL.LineofBusinessId = CT.LineofBusinessId
AND GL.IsActive = 1
GROUP BY CT.ContractId
) GLOrg
INNER JOIN GLOrgStructureConfigs GL ON GLOrg.GLOrgStructureConfigId = GL.Id
)
INSERT INTO VertexContractDetailExtract
	(ContractId, TaxRemittanceType, SequenceNumber, IsSyndicated, TaxAssessmentLevel, LineofBusinessId, DealProductTypeId, 
	 Term, ShortLeaseType, IsContractCapitalizeUpfront, LeaseFinanceId, NumberOfInceptionPayments, 
	 ClassificationContractType, CommencementDate, IsLease, BusCode,JobStepInstanceId,MaturityDate)
SELECT [ContractId], [TaxRemittanceType], [SequenceNumber], [IsSyndicated], [TaxAssessmentLevel], [LineofBusinessId], [DealProductTypeId], 
	 [Term], [ShortLeaseType], [IsContractCapitalizeUpfront], [LeaseFinanceId], [NumberOfInceptionPayments], 
	 [ClassificationContractType], [CommencementDate], [IsLease], [BusCode],[JobStepInstanceId],[MaturityDate] FROM
(
SELECT
	 CT.ContractId
	,TaxRemittanceType
	,SequenceNumber
	,IsSyndicated
	,TaxAssessmentLevel
	,CT.LineofBusinessId
	,DealProductTypeId
	,CAST((DATEDIFF(day,LFD.CommencementDate,LFD.MaturityDate) + 1) AS DECIMAL(10,2)) Term
	,DPT.LeaseType ShortLeaseType
	,LFD.CapitalizeUpfrontSalesTax IsContractCapitalizeUpfront
	,LF.Id AS LeaseFinanceId
	,LFD.NumberOfInceptionPayments
	,LFD.LeaseContractType ClassificationContractType
	,LFD.CommencementDate
	,1 AS IsLease
	,GLOrg.BusinessCode BusCode
	,@JobStepInstanceId JobStepInstanceId
	,LFD.MaturityDate
	,ROW_NUMBER() OVER (PARTITION BY LF.ContractId,LF.Id ORDER BY LF.Id DESC) RowNumber
FROM #ContractDetails CT
INNER JOIN LeaseFinances LF ON CT.ContractId = LF.ContractId
INNER JOIN LeaseFinanceDetails LFD ON LF.Id = LFD.Id AND LF.IsCurrent = 0
INNER JOIN #ContractDetailsForOldLeaseFinance OldFinance ON OldFinance.ContractId= CT.ContractId AND OldFinance.LeaseFinanceId = LF.Id
INNER JOIN DealProductTypes DPT ON CT.DealProductTypeId = DPT.Id
LEFT JOIN CTE_GLOrg GLOrg ON GLOrg.ContractId = CT.ContractId) AS VertexContractDetails
WHERE VertexContractDetails.RowNumber = 1;
END

GO
