SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[SyndicationChangeAssetStatus]
(
@FinanceId BigInt,
@ContractId BigInt,
@EffectiveDate DateTimeOffSet = NULL,
@AssetInvestorLeasedStatus Varchar(15),
@AssetHistoryReason Varchar(15),
@AssetLeasedStatus Varchar(15),
@Module nvarchar(25),
@CreatedById bigint,
@CurrentTime DateTimeOffSet,
@SyndicationType Nvarchar(16),
@PropertyTaxResponsibility Nvarchar(16) = NULL,
@LeaseContractType Nvarchar(16),
@LeaseTransactionType Nvarchar(64),
@AssetHistoryReasonForReportCode Varchar(25),
@ErrorAssetCount Int out
)
AS
BEGIN
SET NOCOUNT ON;

SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
DECLARE @AsOfDate DateTimeOffSet = @EffectiveDate
CREATE TABLE #ChangedAssets
(
AssetId BigInt,
AsOfDate DateTimeOffSet,
AssetStatus Varchar(20),
CreateNewHistory Bit,
ContractId BigInt,
PropertyTaxReportCodeId BigInt
)
CREATE TABLE #AssetLocations
(
EffectiveFromDate DateTimeOffSet,
AssetId BIGINT
)
INSERT INTO #AssetLocations
SELECT MAX(AL.EffectiveFromDate),A.Id FROM LeaseAssets LA
Join Assets A ON LA.AssetId = A.Id
Left Join AssetLocations AL ON A.Id = AL.AssetId
WHERE LA.LeaseFinanceId = @FinanceId
And AL.EffectiveFromDate < = @AsOfDate
And LA.IsActive = 1
GROUP BY A.Id
INSERT INTO #ChangedAssets (AssetId, AsOfDate, AssetStatus, CreateNewHistory, ContractId, PropertyTaxReportCodeId)
SELECT  DISTINCT
LA.AssetId,
@AsOfDate,
A.Status,
0,
@ContractId,
PTRC.Id
FROM
LeaseAssets LA
Inner Join Assets A On LA.AssetId = A.Id
Left Join #AssetLocations ALTEMP on a.Id = ALTEMP.AssetId
Left Join AssetLocations AL on A.Id = AL.AssetId
Left Join Locations L on AL.LocationId = L.Id
Left Join States S on L.StateId = S.Id
Left Join PropertyTaxReportCodeStateAssociations PTSA on S.Id = PTSA.StateId
Left Join PropertyTaxReportCodeConfigs PTRC on PTSA.PropertyTaxReportCodeConfigId = PTRC.Id
WHERE LA.LeaseFinanceId = @FinanceId
And (ALTEMP.AssetId IS NULL OR (ALTEMP.AssetId IS NOT NULL AND AL.EffectiveFromDate = ALTEMP.EffectiveFromDate))
And (PTSA.Id IS NULL OR (PTSA.Id IS NOT NULL AND PTSA.LeaseContractType = @LeaseContractType AND PTSA.LeaseTransactionType = @LeaseTransactionType))
And LA.IsActive = 1
UPDATE Assets Set Status = CASE WHEN @SyndicationType = 'FullSale' THEN @AssetInvestorLeasedStatus ELSE @AssetLeasedStatus END
,PropertyTaxResponsibility =  CASE WHEN @PropertyTaxResponsibility IS NOT NULL THEN @PropertyTaxResponsibility END
,PropertyTaxReportCodeId = CASE WHEN C.PropertyTaxReportCodeId IS NOT NULL THEN C.PropertyTaxReportCodeId END
,UpdatedById = @CreatedById
,UpdatedTime = @CurrentTime
--,IsPariallyOwned = CASE WHEN @SyndicationType = 'ParticipatedSale' THEN 1 ELSE 0 END
FROM #ChangedAssets C Inner Join dbo.Assets A on C.AssetId =A.Id and C.AssetStatus = A.Status;


INSERT INTO [dbo].[AssetHistories]
([Reason]
,[AsOfDate]
,[AcquisitionDate]
,[Status]
,[FinancialType]
,[SourceModule]
,[SourceModuleId]
,[CreatedById]
,[CreatedTime]
,[CustomerId]
,[ParentAssetId]
,[LegalEntityId]
,[AssetId]
,[IsReversed]
,[PropertyTaxReportCodeId])
SELECT @AssetHistoryReason
,C.AsOfDate
,[AcquisitionDate]
,A.Status
,[FinancialType]
,@Module
,@ContractId
,@CreatedById
,@CurrentTime
,[CustomerId]
,[ParentAssetId]
,[LegalEntityId]
,[AssetId]
,0
,A.PropertyTaxReportCodeId 
FROM #ChangedAssets C Inner Join dbo.Assets A on C.AssetId =A.Id
WHERE C.CreateNewHistory = 0
UPDATE [dbo].[AssetHistories] SET AsOfDate = C.AsOfDate FROM #ChangedAssets C JOIN [dbo].[AssetHistories] AH ON C.AssetId = AH.AssetId
WHERE C.CreateNewHistory = 0 AND AH.Id = (SELECT TOP 1 Id FROM [dbo].[AssetHistories] WHERE AssetId = AH.AssetId AND Status in (C.AssetStatus) ORDER BY ID DESC)
INSERT INTO [dbo].[AssetHistories]
([Reason]
,[AsOfDate]
,[AcquisitionDate]
,[Status]
,[FinancialType]
,[SourceModule]
,[SourceModuleId]
,[CreatedById]
,[CreatedTime]
,[CustomerId]
,[ParentAssetId]
,[LegalEntityId]
,[AssetId]
,[IsReversed]
,[PropertyTaxReportCodeId])
SELECT @AssetHistoryReasonForReportCode
,C.AsOfDate
,[AcquisitionDate]
,A.Status
,[FinancialType]
,@Module
,@ContractId
,@CreatedById
,@CurrentTime
,[CustomerId]
,[ParentAssetId]
,[LegalEntityId]
,[AssetId]
,0
,A.PropertyTaxReportCodeId
FROM #ChangedAssets C Inner Join dbo.Assets A on C.AssetId =A.Id
WHERE C.CreateNewHistory = 0

END

GO
