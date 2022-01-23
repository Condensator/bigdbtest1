SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[GetContractsForAutoPayoffTaskChunk]
(
@UpdatedById BIGINT,
@UpdatedTime DATETIMEOFFSET,
@SystemDate DATE,
@BatchSize INT,
@TaskChunkServiceInstanceId BIGINT = NULL,
@JobStepInstanceId BIGINT,
@FixedTermPaymentTypeValue NVARCHAR(30),
@OTPPaymentTypeValue NVARCHAR(30), 
@SupplementalPaymentTypeValue NVARCHAR(30),
@ReceivableTypeLeasePayOffValue NVARCHAR(30),
@ReceivableTypeBuyoutValue NVARCHAR(30),
@ReceivableCategoryPayoffValue NVARCHAR(20),
@GLTransactionPayoffBuyoutARValue NVARCHAR(40),
@GLTransactionBookDepreciationValue NVARCHAR(40),
@LeaseBookingStatusCommencedValue NVARCHAR(20),
@LeaseContractTypeOperatingValue NVARCHAR(20),
@GLTransactionOperatingLeasePayoffValue NVARCHAR(40),
@GLTransactionCapitalLeasePayoffValue NVARCHAR(40),
@AssetFinancialTypeRealValue NVARCHAR(20),
@AssetFinancialTypeDummyValue NVARCHAR(20),
@AssetFinancialTypePlaceholderValue NVARCHAR(20)
)
AS
BEGIN
SET NOCOUNT ON;
DECLARE @AutoPayoffContractDetails TABLE
(
Id BIGINT,
AutoPayoffTemplateId BIGINT,
ContractId BIGINT,
PayoffEffectiveDate DATE
);
UPDATE
TOP (@BatchSize) AutoPayoffContracts
SET
UpdatedById = 1,
UpdatedTime = SYSDATETIME(),
TaskChunkServiceInstanceId = @TaskChunkServiceInstanceId,
IsProcessed = 1
OUTPUT
DELETED.Id,
DELETED.AutoPayoffTemplateId,
DELETED.ContractId,
DELETED.PayoffEffectiveDate
INTO @AutoPayoffContractDetails
WHERE
JobStepInstanceId = @JobStepInstanceId AND
TaskChunkServiceInstanceId IS NULL AND
IsProcessed = 0 AND
IsActive = 1
SELECT
C.SequenceNumber,
C.Id AS ContractId,
C.BillToId AS BillToId,
C.RemitToId AS RemitToId,
LF.CustomerId AS CustomerId,
LF.Id AS LeaseFinanceId,
LFD.MaturityDate AS MaturityDate,
CASE 
	WHEN AC.PayoffEffectiveDate > LFD.CommencementDate
	THEN LPS.Id 
	ELSE NULL 
END AS LeasePaymentScheduleId,
APT.Id AS AutoPayoffTemplateId,
APT.PayoffTemplateId AS PayoffTemplateId,
APT.ActivatePayoffQuote,
LE.GLConfigurationId,
PTTT.Id AS PayoffTemplateTerminationTypeId,
CASE 
	WHEN AC.PayoffEffectiveDate >= LFD.MaturityDate
	THEN CAST( 0 AS BIT)
	ELSE CAST( 1 AS BIT)
END AS PayoffAtFixedTerm
INTO #AutoContractDetails
FROM Contracts C
JOIN @AutoPayoffContractDetails AC ON C.Id = AC.ContractId
JOIN AutoPayoffTemplates APT ON AC.AutoPayoffTemplateId = APT.Id
JOIN PayoffTemplateTerminationTypeConfigs PTTTC ON APT.PayoffTemplateTerminationTypeConfigId = PTTTC.Id
JOIN PayOffTemplateTerminationTypes PTTT ON PTTTC.Id = PTTT.PayoffTemplateTerminationTypeConfigId
AND APT.PayoffTemplateId = PTTT.PayOffTemplateId
AND PTTT.IsActive = 1
JOIN LeaseFinances LF ON C.Id = LF.ContractId
JOIN LeaseFinanceDetails LFD ON LF.Id = LFD.Id AND LF.IsCurrent = 1
JOIN LegalEntities LE ON LF.LegalEntityId = LE.Id
JOIN LeasePaymentSchedules LPS ON LFD.Id = LPS.LeaseFinanceDetailId
WHERE (LPS.EndDate = AC.PayoffEffectiveDate OR (LPS.StartDate = AC.PayoffEffectiveDate AND LPS.PaymentNumber = 1))
AND LPS.PaymentType IN (@FixedTermPaymentTypeValue , @OTPPaymentTypeValue , @SupplementalPaymentTypeValue)
AND LPS.IsActive = 1
SELECT
RT.Name,
MIN(RC.Id) AS ReceivableCodeId,
ACD.GLConfigurationId AS GLConfigurationId
INTO #GLConfigurationReceivableCodeIds
FROM ReceivableCodes RC
JOIN ReceivableCategories RCS ON RC.ReceivableCategoryId = RCS.Id
JOIN ReceivableTypes RT ON RC.ReceivableTypeId = RT.Id
JOIN GLTemplates GLT ON RC.GLTemplateId = GLT.Id
JOIN GLTransactionTypes GTT ON GLT.GLTransactionTypeId = GTT.Id
JOIN #AutoContractDetails ACD ON GLT.GLConfigurationId = ACD.GLConfigurationId
JOIN Contracts C ON ACD.ContractId = C.Id
JOIN LeaseFinances LF ON C.Id = LF.ContractId AND LF.IsCurrent = 1
JOIN LegalEntities LE ON LF.LegalEntityId = LE.Id
JOIN BusinessUnits BU ON LE.BusinessUnitId = BU.Id AND RC.PortfolioId = BU.PortfolioId
WHERE (RT.Name = @ReceivableTypeLeasePayOffValue OR RT.Name = @ReceivableTypeBuyoutValue)
AND RCS.Name = @ReceivableCategoryPayoffValue
AND GTT.Name = @GLTransactionPayoffBuyoutARValue
AND RC.IsActive = 1
AND RCS.IsActive = 1
AND RT.IsActive = 1
GROUP BY ACD.GLConfigurationId, RT.Name
SELECT
GTT.Name,
MIN(GT.Id) AS GLTemplateId,
GT.GLConfigurationId
INTO #GLTemplateIds
FROM Contracts C
JOIN @AutoPayoffContractDetails AC ON C.Id = AC.ContractId
JOIN LeaseFinances LF ON C.Id = LF.ContractId AND LF.IsCurrent = 1
JOIN LeaseFinanceDetails LFD ON LF.Id = LFD.Id
JOIN LegalEntities LE ON LF.LegalEntityId = LE.Id
JOIN GLConfigurations GLC ON LE.GLConfigurationId = GLC.Id
JOIN GLTemplates GT ON GT.GLConfigurationId = GLC.Id
JOIN GLTransactionTypes GTT ON GT.GLTransactionTypeId = GTT.Id
WHERE GT.IsActive = 1
AND GTT.IsActive = 1
AND ((GTT.Name = CASE
WHEN LFD.LeaseContractType = @LeaseContractTypeOperatingValue
THEN @GLTransactionOperatingLeasePayoffValue
ELSE
@GLTransactionCapitalLeasePayoffValue
END) OR GTT.Name = @GLTransactionBookDepreciationValue)
GROUP BY GT.GLConfigurationId, GTT.Name
SELECT LF.Id AS LeaseFinanceId,
LeaseAssetIdsInCSV = STUFF(
(SELECT ',' + CAST(LeaseAssets.Id AS NVARCHAR(8))
FROM LeaseAssets
JOIN Assets ON LeaseAssets.AssetId = Assets.Id
WHERE LeaseAssets.LeaseFinanceId = LF.Id
AND LeaseAssets.CapitalizedForId IS NULL
AND LeaseAssets.IsActive = 1
AND (Assets.FinancialType = @AssetFinancialTypeRealValue
OR Assets.FinancialType = @AssetFinancialTypeDummyValue
OR Assets.FinancialType = @AssetFinancialTypePlaceholderValue)
FOR XML PATH ('')), 1, 1, ''
)
INTO #LeaseFinanceAssetDetails
FROM Contracts C
JOIN #AutoContractDetails ACD ON C.Id = ACD.ContractId
JOIN LeaseFinances LF ON ACD.ContractId = LF.ContractId AND LF.IsCurrent = 1
JOIN LeaseFinanceDetails LFD ON LF.Id = LFD.Id
GROUP BY LF.Id
SELECT
ACD.SequenceNumber,
ACD.ContractId,
ACD.BillToId,
ACD.RemitToId,
ACD.CustomerId,
ACD.LeaseFinanceId,
ACD.LeasePaymentScheduleId,
ACD.AutoPayoffTemplateId,
ACD.PayoffTemplateId,
ACD.ActivatePayoffQuote,
ACD.PayoffTemplateTerminationTypeId,
GLCRC.ReceivableCodeId AS PayoffReceivableCodeId,
GLCRCB.ReceivableCodeId AS BuyoutReceivableCodeId,
PT.TemplateType AS QuoteType,
PGL.GLTemplateId AS PayoffGLTemplateId,
PGLI.GLTemplateId AS InventoryGLTemplateId,
LFAD.LeaseAssetIdsInCSV,
CASE
WHEN PP.Value = 'True'
THEN BU.CurrentBusinessDate
WHEN PP.Value ='False'
THEN @SystemDate
END AS ApplicableBusinessDate,
ACD.PayoffAtFixedTerm,
APCD.PayoffEffectiveDate
FROM @AutoPayoffContractDetails APCD
JOIN #AutoContractDetails ACD ON APCD.ContractId = ACD.ContractId AND APCD.AutoPayoffTemplateId = ACD.AutoPayoffTemplateId
JOIN AutoPayoffTemplates APT ON APT.Id = ACD.AutoPayoffTemplateId
JOIN LeaseFinances LF ON ACD.ContractId = LF.ContractId AND LF.IsCurrent = 1
JOIN LeaseFinanceDetails LFD ON LF.Id = LFD.Id
JOIN #LeaseFinanceAssetDetails LFAD ON LF.Id = LFAD.LeaseFinanceId
JOIN LegalEntities LE ON LF.LegalEntityId = LE.Id
JOIN PayOffTemplates PT ON ACD.PayoffTemplateId = PT.Id
JOIN GLConfigurations GLC ON LE.GLConfigurationId = GLC.Id
JOIN BusinessUnits BU ON LE.BusinessUnitId = BU.Id
JOIN Portfolios P ON BU.PortfolioId = P.Id
JOIN PortfolioParameters PP ON P.Id = PP.PortfolioId
JOIN PortfolioParameterConfigs PPC ON PP.PortfolioParameterConfigId = PPC.Id AND PPC.Name = 'IsBusinessDateApplicable' AND PPC.Category = 'BusinessUnit'
LEFT JOIN #GLConfigurationReceivableCodeIds GLCRC ON GLCRC.GLConfigurationId = GLC.Id AND GLCRC.Name = @ReceivableTypeLeasePayOffValue
LEFT JOIN #GLConfigurationReceivableCodeIds GLCRCB ON GLCRCB.GLConfigurationId = GLC.Id AND GLCRCB.Name = @ReceivableTypeBuyoutValue
LEFT JOIN #GLTemplateIds PGLI ON PGLI.GLConfigurationId = GLC.Id AND PGLI.Name = @GLTransactionBookDepreciationValue
LEFT JOIN #GLTemplateIds PGL ON GLC.Id = PGL.GLConfigurationId AND (PGL.Name = CASE
WHEN LFD.LeaseContractType = @LeaseContractTypeOperatingValue
THEN @GLTransactionOperatingLeasePayoffValue
ELSE
@GLTransactionCapitalLeasePayoffValue
END)
DROP TABLE #AutoContractDetails
DROP TABLE #GLTemplateIds
DROP TABLE #GLConfigurationReceivableCodeIds
DROP TABLE #LeaseFinanceAssetDetails
SET NOCOUNT OFF;
END

GO
