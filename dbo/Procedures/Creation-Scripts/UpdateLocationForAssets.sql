SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [dbo].[UpdateLocationForAssets]
(
	@AssetLocationDetail AssetLocationChangeTableType READONLY,
	@MoveChildAssets BIT,
	@AssetMode NVARCHAR(50),
	@NewLocationId bigint = null,
	@EffectiveFromDate date = null,
	@UpdatedById bigint,
	@UpdatedTime DATETIMEOFFSET ,
	@TaxBasisType NVARCHAR(50) = '_',
	@UpfrontTaxMode NVARCHAR(50) = '_',
	@AssetsLocationChangeId bigint,
	@Reason NVARCHAR(50),
	@SourceModule NVARCHAR(50)
)
AS
BEGIN

SET NOCOUNT ON;

CREATE TABLE #Assets
(
	[AssetId] BIGINT NOT NULL PRIMARY KEY,
	[IsFLStampTaxExempt] BIT,
	[ReciprocityAmount_Amount] Decimal(16,2),
	[ReciprocityAmount_Currency] NVarChar(3),
	[LienCredit_Amount] Decimal(16,2),
	[LienCredit_Currency] NVarChar(3),
	[UpfrontTaxAssessedInLegacySystem] BIT default 0
)

INSERT INTO #Assets([AssetId],[IsFLStampTaxExempt],[ReciprocityAmount_Amount],[ReciprocityAmount_Currency],[LienCredit_Amount],[LienCredit_Currency],[UpfrontTaxAssessedInLegacySystem])
SELECT [AssetId],[IsFLStampTaxExempt],[ReciprocityAmount_Amount],[ReciprocityAmount_Currency],[LienCredit_Amount],[LienCredit_Currency],[UpfrontTaxAssessedInLegacySystem] FROM @AssetLocationDetail
where [IsActive]=1;

IF(@MoveChildAssets = 1)
BEGIN
	INSERT INTO #Assets([AssetId],[IsFLStampTaxExempt],[ReciprocityAmount_Amount],[ReciprocityAmount_Currency],[LienCredit_Amount],[LienCredit_Currency],[UpfrontTaxAssessedInLegacySystem])
	SELECT 
		Assets.Id, 
		#Assets.IsFLStampTaxExempt,		
		#Assets.ReciprocityAmount_Amount,
		#Assets.ReciprocityAmount_Currency,
		#Assets.LienCredit_Amount,
		#Assets.LienCredit_Currency,
		#Assets.UpfrontTaxAssessedInLegacySystem

	FROM 
		#Assets
	JOIN Assets ON #Assets.AssetId = Assets.ParentAssetId
	WHERE Assets.ParentAssetId IS NOT NULL
	GROUP BY 
		Assets.Id, 
		#Assets.IsFLStampTaxExempt,
		#Assets.LienCredit_Amount,
		#Assets.LienCredit_Currency,
		#Assets.ReciprocityAmount_Amount,
		#Assets.ReciprocityAmount_Currency,
		#Assets.UpfrontTaxAssessedInLegacySystem
END

UPDATE Assets SET AssetMode = @AssetMode,MoveChildAssets = @MoveChildAssets, UpdatedById=@UpdatedById, UpdatedTime=@UpdatedTime WHERE Id IN (SELECT AssetId FROM #Assets)

IF @NewLocationId IS NULL
BEGIN
IF @EffectiveFromDate IS NOT NULL
BEGIN
UPDATE AssetLocations SET EffectiveFromDate = @EffectiveFromDate,UpdatedById=@UpdatedById, UpdatedTime=@UpdatedTime WHERE AssetId IN (SELECT AssetId FROM #Assets) AND IsCurrent =1
END
IF @TaxBasisType <> '_'
BEGIN
UPDATE AssetLocations SET TaxBasisType = @TaxBasisType, UpfrontTaxMode = @UpfrontTaxMode,UpdatedById=@UpdatedById, UpdatedTime=@UpdatedTime WHERE AssetId IN (SELECT AssetId FROM #Assets) AND IsCurrent =1
END
END

IF @NewLocationId IS NOT NULL
BEGIN
Declare @StateId bigint

SELECT @TaxBasisType = CASE WHEN @TaxBasisType = '_' THEN Locations.TaxBasisType ELSE @TaxBasisType END , @UpfrontTaxMode = CASE WHEN @UpfrontTaxMode = '_' THEN Locations.UpfrontTaxMode ELSE @UpfrontTaxMode END, @StateId = StateId 
FROM Locations 
WHERE Id = @NewLocationId

INSERT INTO AssetLocations
	(
	 EffectiveFromDate
	,IsCurrent
	,TaxBasisType
	,UpfrontTaxMode
	,IsActive
	,LocationId
	,AssetId
	,IsFLStampTaxExempt
	,CreatedById
	,CreatedTime
	,LienCredit_Amount
	,LienCredit_Currency
	,ReciprocityAmount_Amount
	,ReciprocityAmount_Currency
	,UpfrontTaxAssessedInLegacySystem)
SELECT
	@EffectiveFromDate
	,0
	,@TaxBasisType
	,@UpfrontTaxMode
	,1
	,@NewLocationId
	,AssetRecords.AssetId
	,AssetRecords.IsFLStampTaxExempt
	,@UpdatedById
	,@UpdatedTime
	,AssetRecords.LienCredit_Amount
	,AssetRecords.LienCredit_Currency
	,AssetRecords.ReciprocityAmount_Amount
	,AssetRecords.ReciprocityAmount_Currency
	,AssetRecords.UpfrontTaxAssessedInLegacySystem
FROM 
	#Assets as AssetRecords
 
SELECT
	Assets.ID AssetId, 
	Assets.PropertyTaxReportCodeId,
	Contracts.Id AS ContractID,
	LeaseFinanceDetails.LeaseContractType,
	Contracts.DealProductTypeId
INTO #ContractInfo
FROM 
	#Assets	
	JOIN Assets
		ON #Assets.AssetId = Assets.Id
	JOIN LeaseAssets
		ON Assets.Id = LeaseAssets.AssetId AND LeaseAssets.IsActive = 1
	JOIN LeaseFinanceDetails
		ON LeaseAssets.LeaseFinanceId = LeaseFinanceDetails.Id
	JOIN LeaseFinances
		ON LeaseFinanceDetails.Id = LeaseFinances.Id
		AND LeaseFinances.Iscurrent = 1
	JOIN Contracts
		ON LeaseFinances.ContractId = Contracts.Id

SELECT 
	#ContractInfo.AssetId,
	PTA.PropertyTaxReportCodeConfigId ,
	#ContractInfo.ContractID
INTO #TempPTReportCode
FROM #ContractInfo
JOIN PropertyTaxReportCodeStateAssociations PTA
		ON #ContractInfo.LeaseContractType = PTA.LeaseContractType 
		AND PTA.StateId = @StateId
		AND PTA.IsActive = 1
JOIN DealProductTypes
		ON #ContractInfo.DealProductTypeId = DealProductTypes.Id
		AND DealProductTypes.Name = PTA.LeaseTransactionType
		AND DealProductTypes.IsActive = 1
	JOIN PropertyTaxReportCodeConfigs
		ON PropertyTaxReportCodeConfigs.Id = PTA.PropertyTaxReportCodeConfigId
		AND PropertyTaxReportCodeConfigs.IsActive = 1
WHERE
 #ContractInfo.PropertyTaxReportCodeId <> PTA.PropertyTaxReportCodeConfigId


UPDATE Assets 
SET PropertyTaxReportCodeId = #TempPTReportCode.PropertyTaxReportCodeConfigId 
, UpdatedById=@UpdatedById, UpdatedTime=@UpdatedTime
FROM 
	Assets
	JOIN #TempPTReportCode
		ON Assets.Id = #TempPTReportCode.AssetId
END


INSERT INTO AssetHistories
	(Reason
	,AsOfDate
	,AcquisitionDate
	,Status
	,FinancialType
	,SourceModule
	,SourceModuleId
	,CreatedById
	,CreatedTime
	,CustomerId
	,ParentAssetId
	,LegalEntityId
	,ContractId
	,AssetId
	,PropertyTaxReportCodeId
	,IsReversed)

SELECT
	 @Reason
	,@EffectiveFromDate
	,AcquisitionDate
	,Status
	,FinancialType
	,@SourceModule
	,@AssetsLocationChangeId
	,@UpdatedById
	,@UpdatedTime
	,CustomerId
	,ParentAssetId
	,LegalEntityId
	,#TempPTReportCode.ContractID
	,AssetId
	,#TempPTReportCode.PropertyTaxReportCodeConfigId
	,0
FROM 
	#TempPTReportCode
	JOIN Assets
		ON #TempPTReportCode.AssetId = Assets.Id

SELECT DISTINCT A.AssetId,LA.SalesTaxRemittanceResponsibility,LA.VendorRemitToId,LF.ContractId,LF.Id AS LeaseFinanceId
INTO #ContractSalesTaxRemittanceResponsibilityHistoryDetails
FROM #Assets A
INNER JOIN LeaseAssets LA ON LA.AssetId = A.AssetId AND LA.IsActive=1
INNER JOIN LeaseFinances LF ON LF.Id = LA.LeaseFinanceId AND LF.IsCurrent = 1
WHERE LA.SalesTaxRemittanceResponsibility <> 'Lessor'

INSERT INTO [ContractSalesTaxRemittanceResponsibilityHistories](ContractId,AssetId,EffectiveTillDate,SalesTaxRemittanceResponsibility,VendorRemitToId,CreatedById,CreatedTime)
SELECT ContractId,AssetId,DATEADD(DAY,-1,@EffectiveFromDate),SalesTaxRemittanceResponsibility,VendorRemitToId,@UpdatedById,@UpdatedTime FROM
#ContractSalesTaxRemittanceResponsibilityHistoryDetails

UPDATE LeaseAsset
SET SalesTaxRemittanceResponsibility = 'Lessor',
VendorRemitToId = NULL,
UpdatedById=@UpdatedById,
UpdatedTime=@UpdatedTime
FROM LeaseAssets LeaseAsset
JOIN  #ContractSalesTaxRemittanceResponsibilityHistoryDetails  A ON A.AssetId = LeaseAsset.AssetId AND LeaseAsset.LeaseFinanceId = A.LeaseFinanceId
WHERE LeaseAsset.IsActive = 1 AND LeaseAsset.SalesTaxRemittanceResponsibility <> 'Lessor'

IF OBJECT_ID(N'tempdb..#AssetLocations') IS NOT NULL
DROP TABLE #AssetLocations

select Id,AssetId,EffectiveFromDate,IsActive,IsCurrent,UpdatedById,UpdatedTime into #AssetLocations from AssetLocations WHERE IsActive = 1  AND Assetid IN (SELECT AssetId FROM #Assets)

UPDATE #AssetLocations SET IsCurrent = 0, UpdatedById=@UpdatedById, UpdatedTime=@UpdatedTime
WHERE IsCurrent = 1 AND Assetid IN (SELECT AssetId FROM #Assets)

UPDATE #AssetLocations SET #AssetLocations.IsCurrent = 1 , UpdatedById=@UpdatedById, UpdatedTime=@UpdatedTime 
WHERE Id IN 
(
	SELECT MAX(#AssetLocations.Id) AssetLocationId
	FROM #AssetLocations
	INNER JOIN 
		(
			SELECT MAX(EffectiveFromDate) EffectiveFromDate, AssetId FROM #AssetLocations	
			WHERE AssetId IN (SELECT AssetId FROM #Assets) AND IsActive=1
			GROUP BY AssetId
		) AS AER 
		ON #AssetLocations.AssetId = AER.AssetId
	WHERE #AssetLocations.EffectiveFromDate = AER.EffectiveFromDate AND IsActive=1
	GROUP BY #AssetLocations.AssetId
) AND IsCurrent = 0 AND IsActive=1

UPDATE #AssetLocations SET IsActive=0 
WHERE Id in(
	SELECT MIN(AL.Id) FROM #AssetLocations AL
	JOIN #Assets A ON AL.AssetId = A.AssetId and AL.IsActive=1
	GROUP BY AL.AssetId,AL.EffectiveFromDate 
	HAVING COUNT(*) > 1
	)

update AssetLocations set IsCurrent=AL.IsCurrent,
IsActive=AL.IsActive,
UpdatedById=AL.UpdatedById,
UpdatedTime=AL.UpdatedTime
from  #AssetLocations AL where AssetLocations.Id=AL.Id

drop table #AssetLocations
END

GO
