SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[GetGLAccountNumber]
(
@InstrumentTypeId bigint
,@GLTemplateDetailID BigInt
,@ContractType nvarchar(10)
,@ContractId BigInt
,@LegalEntityId BigInt
,@LineOfBusinessId BigInt
,@AccountNumber nvarchar(200)
,@CostCenterID BIGINT
,@CurrencyID BIGINT
,@IsForCash tinyint
,@LegalEntityBankGLSegmentValue Nvarchar(100)
)
RETURNS Nvarchar(100)
AS
BEGIN
--DECLARE  @InstrumentTypeId bigint = 37
--  ,@GLTemplateDetailID BigInt = 2240
--  ,@ContractType nvarchar(10) ='Lease'
--  ,@ContractId BigInt = 22439
--  ,@LegalEntityId BigInt = 3
--  ,@LineOfBusinessId BigInt = 28
--  ,@CostCenterID BIGINT =60
--  ,@CurrencyID BIGINT =1
--  ,@AccountNumber nvarchar(100)
--  ,@IsForCash tinyint= 0
--  ,@LegalEntityBankGLSegmentValue Nvarchar(100) = 'BUSDLL490000'
DECLARE  @LegalEntityGlSegmentValue nvarChar(100) = ''
,@CostCenter NvarChar(100)=''
,@RollupCostCenter NvarChar(100)=''
,@LegalEntityRollupCostCenter nvarchar(100) =''
,@AcquisitionId Nvarchar(10) =''
,@AnalysisCode NVARCHAR(80)=''
,@BusCode NVARCHAR(80)=''
,@GLTemplateId bigint
,@EntryItemId bigint
,@GLAccountID bigint
,@TransactionType nvarchar(100)=''
,@DefaultCashCenter Nvarchar(100)=''
,@DefaultGLAccount Nvarchar(100)=''
SELECT @LegalEntityGlSegmentValue = GLSegmentValue,@DefaultCashCenter=CostCenter,@DefaultGLAccount=GLAccountNumber FROM LegalEntities WHERE Id = @LegalEntityId
SELECT @CostCenter = CostCenter FROM dbo.CostCenterConfigs WHERE ID = @CostCenterID
SELECT @RollupCostCenter = CostCenter FROM RollupCostCenters WHERE RollupCostCenters.InstrumentTypeId = @InstrumentTypeId AND GLEntryItemId = @EntryItemId AND LegalEntityId = @LegalEntityId
SELECT TOP 1 @LegalEntityRollupCostCenter = CostCenter FROM LegalEntityLineOfBusinesses WHERE LegalEntityId = @LegalEntityId AND LineofBusinessId = @LineOfBusinessId and IsActive =1 ;
SELECT @GLTemplateId = GLTemplateId, @GLAccountID = GLAccountId, @EntryItemId= EntryItemId FROM GLTemplateDetails Where Id= @GLTemplateDetailID
SELECT @BusCode = BusinessCode FROM dbo.GLOrgStructureConfigs WHERE LegalEntityId = @LegalEntityId AND LineofBusinessId = @LineOfBusinessId AND CostCenterId = @CostCenterID AND CurrencyId = @CurrencyID
SELECT @AnalysisCode = Value FROM dbo.GlobalParameters WHERE Category ='GL' AND Name='AnalysisCode'
SELECT @TransactionType = Code from DealProductTypes where id in (select DealProductTypeId from COntracts Where Id=@ContractId)
IF @ContractType = 'Customer'
BEGIN
SELECT @TransactionType = LEFT(Code,6) from InstrumentTypes where id = @InstrumentTypeId
END
IF @ContractType = 'Lease'
SELECT @AcquisitionId = AcquisitionId FROM LeaseFinances Where ContractId = @ContractId AND IsCurrent = 1
ELSE IF @ContractType = 'Loan'
SELECT @AcquisitionId = AcquisitionId FROM LoanFinances Where ContractId = @ContractId AND IsCurrent = 1
ELSE IF @ContractType = 'LeveragedLease'
SELECT @AcquisitionId = AcquisitionId FROM LeveragedLeases Where ContractId = @ContractId AND IsCurrent = 1
ELSE SET @AcquisitionId = ISNULL((SELECT Value FROM PortfolioParameters pp
INNER JOIN dbo.PortfolioParameterConfigs ppc ON ppc.Name = 'AcquisitionId' AND ppc.Category = 'GL' AND pp.PortfolioParameterConfigId = ppc.Id
INNER JOIN dbo.CostCenterConfigs ccc ON ccc.Id = @CostCenterID AND pp.PortfolioId = ccc.PortfolioId), 'LW00')
;WITH
CTE_GlAccountDetails
AS
(
SELECT
GLAccountDetails.Id [GLAccountDetailID]
,GLAccountDetails.SegmentNumber
,GLAccountDetails.IsDynamic
,GLAccountDetails.SegmentValue
,GLAccountDetails.GLAccountId
,GLAccountDetails.DynamicSegmentTypeId
,GLSegmentTypes.Name [SegmentName]
FROM
GLAccounts
INNER JOIN GLAccountDetails
ON GLAccounts.Id = GLAccountDetails.GLAccountId
LEFT JOIN GLSegmentTypes
ON GLSegmentTypes.Id = GLAccountDetails.DynamicSegmentTypeId
WHERE
GLAccountID = @GLAccountID
),
CTE_InstrumentTypeGLAccounts
AS
(
SELECT
InstrumentTypeGLAccounts.GLAccountNumber
,GLTemplateDetails.GlAccountID
,InstrumentTypeGLAccounts.UseRollupCostCenter
FROM
InstrumentTypeGLAccounts
INNER JOIN GlTemplates
ON InstrumentTypeGLAccounts.GLTemplateId = GlTemplates.Id
INNER JOIN GLTemplateDetails
ON GLTemplateDetails.GLTemplateId = GlTemplates.Id
WHERE
InstrumentTypeGLAccounts.InstrumentTypeID = @InstrumentTypeId
AND InstrumentTypeGLAccounts.GLEntryItemId = @EntryItemId
AND InstrumentTypeGLAccounts.GLTemplateId = @GLTemplateId
AND GLTemplateDetails.GLAccountID = @GLAccountID
AND InstrumentTypeGLAccounts.IsActive = 1
)
SELECT
@AccountNumber = COALESCE(@AccountNumber + CASE WHEN LEN(@AccountNumber)>0 THEN '-' ELSE '' END, '') + RS.GLAccountNumber
FROM
(
SELECT DISTINCT
CTE_GlAccountDetails.GLAccountDetailID
,CTE_GlAccountDetails.SegmentNumber
,CASE
WHEN CTE_GlAccountDetails.IsDynamic = 0 THEN CONVERT(Nvarchar(100),CTE_GlAccountDetails.SegmentValue)
ELSE
CASE
WHEN CTE_GlAccountDetails.SegmentName = 'LegalEntity' THEN CONVERT(Nvarchar(100),ISNULL(@LegalEntityGlSegmentValue, 'LegalEntity'))
WHEN CTE_GlAccountDetails.SegmentName = 'BusCode' THEN CONVERT(Nvarchar(100),ISNULL(@BusCode, 'BusCode'))
WHEN CTE_GlAccountDetails.SegmentName = 'GLAccountNumber' THEN
CASE WHEN @IsForCash = 1 AND LEN(@DefaultGLAccount) > 0
THEN @DefaultGLAccount ELSE CONVERT(Nvarchar(100),ISNULL(CTE_InstrumentTypeGLAccounts.GLAccountNumber, 'GLAccountNumber'))
END
WHEN CTE_GlAccountDetails.SegmentName = 'CostCenter' THEN
CASE WHEN @IsForCash = 1 AND LEN(@DefaultCashCenter)>0
THEN @DefaultCashCenter ELSE
CASE WHEN LEN(@CostCenter) > 0 THEN @CostCenter
ELSE
CASE
WHEN CTE_InstrumentTypeGLAccounts.UseRollupCostCenter = 1 THEN  CONVERT(Nvarchar(100),ISNULL(@RollupCostCenter, 'CostCenter'))
ELSE @LegalEntityRollupCostCenter
END
END
END
WHEN CTE_GlAccountDetails.SegmentName = 'AcquistionId' THEN CONVERT(Nvarchar(100),@AcquisitionId)
WHEN CTE_GlAccountDetails.SegmentName = 'AffiliateCode' THEN CONVERT(Nvarchar(100),ISNULL(AffiliateCodes.Code, ''))
WHEN CTE_GlAccountDetails.SegmentName = 'AnalysisCode' THEN
CASE WHEN @IsForCash =1 AND LEN(@LegalEntityGlSegmentValue)>0 THEN CONVERT(Nvarchar(100),@LegalEntityBankGLSegmentValue)
ELSE CONVERT(Nvarchar(100),ISNULL(@AnalysisCode, '00000000000'))
END
WHEN CTE_GlAccountDetails.SegmentName = 'BranchCostCenter' THEN ' '
END
END
GLAccountNumber
FROM
CTE_GlAccountDetails
LEFT JOIN CTE_InstrumentTypeGLAccounts
ON CTE_GlAccountDetails.GLAccountID = CTE_InstrumentTypeGLAccounts.GlAccountID
LEFT JOIN AffiliateCodes
ON AffiliateCodes.GLAccountNumber = CTE_InstrumentTypeGLAccounts.GLAccountNumber
AND AffiliateCodes.LegalEntityId = @LegalEntityId
)RS
WHERE
LEN(REPLACE(RS.GLAccountNumber, ' ', '.')) > 0
ORDER BY RS.SegmentNumber
RETURN @AccountNumber
END

GO
