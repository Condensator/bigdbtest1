SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[UpdatesInAssumptionApprove]
(
@AssumptionId BIGINT
,@PortfolioId BIGINT
,@CreatedById BIGINT
,@CreatedTime DATETIMEOFFSET
,@NewSequenceNumber NVARCHAR(40)
)
AS
BEGIN
SET NOCOUNT ON
DECLARE @NewCustomerId BIGINT
DECLARE @OldCustomerId BIGINT
DECLARE @ContractId BIGINT
DECLARE @LeaseFinanceId BIGINT = NULL
DECLARE @LoanFinanceId BIGINT = NULL
DECLARE @BillToId BIGINT
DECLARE @OldBillToId BIGINT
DECLARE @AssumptionDate DATE
DECLARE @EffectiveDate DATE
DECLARE @ContractType NVARCHAR(28)
DECLARE @NewLocationId BIGINT = NULL
DECLARE @IsClone BIT
DECLARE @FederalIncomeTaxExempt BIT
DECLARE @MaxLocationCode INT = 1
DECLARE @NewCustomerPartyNumber NVARCHAR(40) = ''
DECLARE @ContractSubString NVARCHAR(1) = ''
DECLARE @SequenceNumber NVARCHAR(40) = ''
DECLARE @ContractCurrency NVARCHAR(3)
DECLARE @NextVal BIGINT
DECLARE @FirstVal BIGINT
DECLARE @IncrementBy INT
DECLARE @TaxAssessmentLevel NVARCHAR(50)

CREATE TABLE #InsertedTaxExemptRuleIds
(
Id BIGINT,
LocationId BIGINT
)

CREATE TABLE #NewLocationsForCustomer(
EffectiveFromDate DATE,
IsFLStampTaxExempt BIT,
LocationId BIGINT,
AssetId BIGINT,
IsCurrent BIT,
[Id] [bigint] ,
[Code] [nvarchar](100)  NULL,
[Name] [nvarchar](100) NULL,
[AddressLine1] [nvarchar](50)  NULL,
[AddressLine2] [nvarchar](50) NULL,
[Division] [nvarchar](40) NULL,
[City] [nvarchar](40) NULL,
[PostalCode] [nvarchar](12) NULL,
[Description] [nvarchar](200) NULL,
[TaxAreaVerifiedTillDate] [date] NULL,
[IsActive] [bit] NOT NULL,
[TaxAreaId] [bigint] NULL,
[ApprovalStatus] [nvarchar](9)  NULL,
[IncludedPostalCodeInLocationLookup] [bit]  NULL,
[TaxBasisType] [nvarchar](2) NULL,
[UpfrontTaxMode] [nvarchar](5) NULL,
[CountryTaxExemptionRate] [decimal](10, 6) NULL,
[StateTaxExemptionRate] [decimal](10, 6) NULL,
[DivisionTaxExemptionRate] [decimal](10, 6) NULL,
[CityTaxExemptionRate] [decimal](10, 6) NULL,
[CreatedById] [bigint]  NULL,
[CreatedTime] [datetimeoffset](7)  NULL,
[CustomerId] [bigint] NULL,
[StateId] [bigint] NOT NULL,
[JurisdictionId] [bigint] NULL,
[ContactPersonId] [bigint] NULL,
[JurisdictionDetailId] [bigint] NULL,
[Latitude] [decimal](11,8) NULL,
[Longitude] [decimal](11,8) NULL)
CREATE TABLE #InsertingAssetLocationsClone(
[EffectiveFromDate] [date],
[IsCurrent] [bit] ,
[UpfrontTaxMode] [nvarchar](5),
[TaxBasisType] [nvarchar](2) ,
[IsActive] [bit] ,
[CreatedById] [bigint] ,
[CreatedTime] [datetimeoffset](7) ,
[LocationId] [bigint] ,
[AssetId] [bigint] ,
[IsFLStampTaxExempt] [bit] )
SELECT
@NewCustomerId = NewCustomerId,
@OldCustomerId = OriginalCustomerId,
@AssumptionDate = AssumptionDate,
@BillToId=NewBillToId,
@ContractId = ContractId,
@ContractType = ContractType,
@IsClone = IsCloneAssetLocation,
@NewLocationId = NewLocationId,
@EffectiveDate = AssumptionDate
FROM Assumptions
WHERE ID = @AssumptionId
SELECT
@SequenceNumber = SequenceNumber,
@TaxAssessmentLevel = TaxAssessmentLevel
FROM Contracts
WHERE ID = @ContractId
SELECT @ContractCurrency = LastPaymentAmount_Currency,
@OldBillToId = BillToId
FROM dbo.Contracts WHERE ID = @ContractId
SELECT @NewCustomerPartyNumber = PartyNumber
FROM Parties WHERE Id = @NewCustomerId
CREATE TABLE #CreatedAssetLocationIds (
[Id] bigint NOT NULL,
[AssetId] bigint NOT NULL,
[LocationId] bigint NOT NULL)
CREATE TABLE #CreatedLocationIds (
[Id] bigint NOT NULL,
[Code] NVARCHAR(MAX) NOT NULL)
SELECT
	AssumptionAssets.AssetId,
	AssumptionAssets.BillToId,
	AssumptionAssets.LocationId,
	AssumptionAssets.AssumptionId
INTO #AssumptionAssetsForUpdation
FROM AssumptionAssets
WHERE AssumptionId = @AssumptionId
	AND AssumptionAssets.IsActive = 1
UPDATE PayableInvoices SET CustomerId = @NewCustomerId , UpdatedById= @CreatedById,UpdatedTime = @CreatedTime
WHERE ContractId = @ContractId AND Status <> 'InActive'
IF @ContractType = 'Lease'
BEGIN
SELECT @LeaseFinanceId = Id,
@FederalIncomeTaxExempt = IsFederalIncomeTaxExempt
FROM LeaseFinances WHERE ContractId = @ContractId AND IsCurrent = 1
UPDATE LeaseFinances SET CustomerId = @NewCustomerId , UpdatedById= @CreatedById,UpdatedTime = @CreatedTime  WHERE Id = @LeaseFinanceId
UPDATE LPS
SET VATAmount_Amount = APS.VATAmount_Amount,
	VATAmount_Currency = APS.VATAmount_Currency,
	CustomerId = A.NewCustomerId,
	UpdatedById = @CreatedById,
	UpdatedTime = @CreatedTime
FROM AssumptionPaymentSchedules APS JOIN LeasePaymentSchedules LPS ON APS.LeasePaymentScheduleId = LPS.Id
JOIN Assumptions A ON APS.AssumptionId = A.Id
WHERE APS.IsActive = 1 AND APS.AssumptionId = @AssumptionId AND APS.Calculate = 1
SELECT *
INTO #BlendedItemsToBeUpdated
FROM BlendedItems WHERE Id in (
SELECT BlendedItemId FROM LeaseBlendedItems WHERE LeaseFinanceId in (
SELECT Id FROM LeaseFinances WHERE ContractId in (
SELECT Id FROM Contracts WHERE Id in (
SELECT ContractId FROM Assumptions WHERE Id=@AssumptionId
)
)
)
)
UPDATE BlendedItems SET LocationId=#AssumptionAssetsForUpdation.LocationId
, BillToId= #AssumptionAssetsForUpdation.BillToId
, UpdatedById= @CreatedById
,UpdatedTime = @CreatedTime
FROM LeaseAssets
INNER JOIN #AssumptionAssetsForUpdation ON  LeaseAssets.AssetId = #AssumptionAssetsForUpdation.AssetId
WHERE BlendedItems.Id IN (SELECT Id FROM #BlendedItemsToBeUpdated
WHERE #BlendedItemsToBeUpdated.[Type] = 'Income'
AND #BlendedItemsToBeUpdated.LeaseAssetId IS NOT NULL)
AND BlendedItems.LeaseAssetId = LeaseAssets.Id
UPDATE BlendedItems SET BillToId= #AssumptionAssetsForUpdation.BillToId , UpdatedById= @CreatedById,UpdatedTime = @CreatedTime
FROM LeaseAssets
INNER JOIN #AssumptionAssetsForUpdation ON  LeaseAssets.AssetId = #AssumptionAssetsForUpdation.AssetId
WHERE BlendedItems.Id IN (SELECT Id FROM #BlendedItemsToBeUpdated
WHERE #BlendedItemsToBeUpdated.[Type] <> 'Income'
AND #BlendedItemsToBeUpdated.LeaseAssetId IS NOT NULL)
AND	 BlendedItems.LeaseAssetId = LeaseAssets.Id
UPDATE BlendedItems SET LocationId=@NewLocationId, BillToId= @BillToId, UpdatedById= @CreatedById,UpdatedTime = @CreatedTime
WHERE BlendedItems.Id IN (SELECT Id FROM #BlendedItemsToBeUpdated
WHERE #BlendedItemsToBeUpdated.[Type] = 'Income'
AND #BlendedItemsToBeUpdated.LeaseAssetId IS NULL)
UPDATE BlendedItems SET BillToId= @BillToId, UpdatedById= @CreatedById,UpdatedTime = @CreatedTime
WHERE BlendedItems.Id IN (SELECT Id FROM #BlendedItemsToBeUpdated
WHERE #BlendedItemsToBeUpdated.[Type] <> 'Income'
AND #BlendedItemsToBeUpdated.LeaseAssetId IS NULL)
END
ELSE
BEGIN
SELECT @LoanFinanceId = Id,
@FederalIncomeTaxExempt = IsFederalIncomeTaxExempt
FROM LoanFinances WHERE ContractId = @ContractId AND IsCurrent = 1
UPDATE LoanFinances SET CustomerId = @NewCustomerId, UpdatedById= @CreatedById,UpdatedTime = @CreatedTime  WHERE Id = @LoanFinanceId
UPDATE LoanPaymentSchedules SET CustomerId = @NewCustomerId WHERE LoanFinanceId = @LoanFinanceId AND StartDate >= @AssumptionDate
END
UPDATE Contracts SET BillToId = @BillToId, UpdatedById= @CreatedById,UpdatedTime = @CreatedTime  WHERE Id = @ContractId
UPDATE LeaseAssets SET BillToId = #AssumptionAssetsForUpdation.BillToId,UpdatedById= @CreatedById,UpdatedTime = @CreatedTime FROM #AssumptionAssetsForUpdation
WHERE LeaseAssets.LeaseFinanceId = @LeaseFinanceId AND #AssumptionAssetsForUpdation.AssetId = LeaseAssets.AssetId
UPDATE Assets SET CustomerId = @NewCustomerId, UpdatedById= @CreatedById,UpdatedTime = @CreatedTime  WHERE Id in (SELECT AssetId FROM #AssumptionAssetsForUpdation)
Create Table #AssetDetails(
[AcquisitionDate] [Date],
[Status][nvarchar](20),
[FinancialType][nvarchar](20),
[ParentAssetId] [BigInt],
[LegalEntityId] [BigInt],
[AssetId] [BigInt],
[PropertyTaxReportCodeId] [BigInt]
)
Insert into #AssetDetails(
[AcquisitionDate],
[Status],
[FinancialType],
[ParentAssetId],
[LegalEntityId],
[AssetId],
[PropertyTaxReportCodeId] )
Select
Assets.AcquisitionDate,
Assets.Status,
Assets.FinancialType,
Assets.ParentAssetId,
Assets.LegalEntityId,
Assets.Id as AssetId,
Assets.PropertyTaxReportCodeId
from Assets join #AssumptionAssetsForUpdation
on Assets.Id=#AssumptionAssetsForUpdation.AssetId

Insert into AssetHistories(Reason,AsOfDate,AcquisitionDate,Status,FinancialType,SourceModule,SourceModuleId,IsReversed,CustomerId,ParentAssetId,LegalEntityId,ContractId,AssetId,PropertyTaxReportCodeId,CreatedById,CreatedTime)
Select 'CustomerChange',@AssumptionDate,AcquisitionDate,Status,FinancialType,'Assumption',@AssumptionId,0,@NewCustomerId,ParentAssetId,LegalEntityId,@ContractId,AssetId,PropertyTaxReportCodeId,@CreatedById,@CreatedTime 
from #AssetDetails 	
IF (@IsClone = 1)
BEGIN
INSERT INTO #NewLocationsForCustomer
(EffectiveFromDate
,IsFLStampTaxExempt
,LocationId
,AssetId
,IsCurrent
,[Id]
,[Code]
,[Name]
,[AddressLine1]
,[AddressLine2]
,[Division]
,[City]
,[PostalCode]
,[Description]
,[TaxAreaVerifiedTillDate]
,[IsActive]
,[TaxAreaId]
,[ApprovalStatus]
,[IncludedPostalCodeInLocationLookup]
,[TaxBasisType]
,[UpfrontTaxMode]
,[CountryTaxExemptionRate]
,[StateTaxExemptionRate]
,[DivisionTaxExemptionRate]
,[CityTaxExemptionRate]
,[CreatedById]
,[CreatedTime]
,[CustomerId]
,[StateId]
,[JurisdictionId]
,[ContactPersonId]
,[JurisdictionDetailId]
,[Latitude]
,[Longitude])
SELECT
AssetLocations.EffectiveFromDate
,AssetLocations.IsFLStampTaxExempt
,AssetLocations.LocationId
,AssetLocations.AssetId
,AssetLocations.IsCurrent
,Locations.[Id]
,Locations.[Code]
,Locations.[Name]
,Locations.[AddressLine1]
,Locations.[AddressLine2]
,Locations.[Division]
,Locations.[City]
,Locations.[PostalCode]
,Locations.[Description]
,Locations.[TaxAreaVerifiedTillDate]
,1
,Locations.[TaxAreaId]
,Locations.[ApprovalStatus]
,Locations.[IncludedPostalCodeInLocationLookup]
,Locations.[TaxBasisType]
,Locations.[UpfrontTaxMode]
,Locations.[CountryTaxExemptionRate]
,Locations.[StateTaxExemptionRate]
,Locations.[DivisionTaxExemptionRate]
,Locations.[CityTaxExemptionRate]
,Locations.[CreatedById]
,Locations.[CreatedTime]
,Locations.[CustomerId]
,Locations.[StateId]
,Locations.[JurisdictionId]
,Locations.[ContactPersonId]
,Locations.[JurisdictionDetailId]
,Locations.[Latitude]
,Locations.[Longitude]
FROM #AssumptionAssetsForUpdation [AssumptionAssets]
INNER JOIN AssetLocations ON AssumptionAssets.AssetId = AssetLocations.AssetId
INNER JOIN Locations ON Locations.Id = AssetLocations.LocationId
WHERE AssetLocations.ID IN (SELECT Id FROM AssetLocations
WHERE AssetId IN (SELECT AssetId FROM #AssumptionAssetsForUpdation)
AND IsActive = 1
AND EffectiveFromDate >=@AssumptionDate)
SELECT COUNT(AssetId) [Count], AssetId
INTO #NewLocationsWithEffectiveDateGreaterThanAssumptionDate
FROM #NewLocationsForCustomer
GROUP BY AssetId
INSERT INTO #NewLocationsForCustomer
(EffectiveFromDate
,IsFLStampTaxExempt
,LocationId
,AssetId
,IsCurrent
,[Id]
,[Code]
,[Name]
,[AddressLine1]
,[AddressLine2]
,[Division]
,[City]
,[PostalCode]
,[Description]
,[TaxAreaVerifiedTillDate]
,[IsActive]
,[TaxAreaId]
,[ApprovalStatus]
,[IncludedPostalCodeInLocationLookup]
,[TaxBasisType]
,[UpfrontTaxMode]
,[CountryTaxExemptionRate]
,[StateTaxExemptionRate]
,[DivisionTaxExemptionRate]
,[CityTaxExemptionRate]
,[CreatedById]
,[CreatedTime]
,[CustomerId]
,[StateId]
,[JurisdictionId]
,[ContactPersonId]
,[JurisdictionDetailId]
,[Latitude]
,[Longitude])
SELECT
AssetLocations.EffectiveFromDate
,AssetLocations.IsFLStampTaxExempt
,AssetLocations.LocationId
,AssetLocations.AssetId
,AssetLocations.IsCurrent
,Locations.[Id]
,Locations.[Code]
,Locations.[Name]
,Locations.[AddressLine1]
,Locations.[AddressLine2]
,Locations.[Division]
,Locations.[City]
,Locations.[PostalCode]
,Locations.[Description]
,Locations.[TaxAreaVerifiedTillDate]
,1
,Locations.[TaxAreaId]
,Locations.[ApprovalStatus]
,Locations.[IncludedPostalCodeInLocationLookup]
,Locations.[TaxBasisType]
,Locations.[UpfrontTaxMode]
,Locations.[CountryTaxExemptionRate]
,Locations.[StateTaxExemptionRate]
,Locations.[DivisionTaxExemptionRate]
,Locations.[CityTaxExemptionRate]
,Locations.[CreatedById]
,Locations.[CreatedTime]
,Locations.[CustomerId]
,Locations.[StateId]
,Locations.[JurisdictionId]
,Locations.[ContactPersonId]
,Locations.[JurisdictionDetailId]
,Locations.[Latitude]
,Locations.[Longitude]
FROM #AssumptionAssetsForUpdation [AssumptionAssets]
INNER JOIN AssetLocations ON AssumptionAssets.AssetId = AssetLocations.AssetId
INNER JOIN Locations ON Locations.Id = AssetLocations.LocationId
WHERE Locations.ID IN (SELECT Locationid FROM
(SELECT AssetLocations.*,
RANK() OVER ( PARTITION BY AssetId ORDER BY IsCurrent DESC,EffectiveFromDate DESC, AssetLocations.Id DESC ) [Rank]
FROM AssetLocations
INNER JOIN Locations ON Locations.Id = AssetLocations.LocationId
WHERE  AssetId IN (SELECT AssetId FROM #AssumptionAssetsForUpdation) AND AssetLocations.IsActive = 1
AND (Locations.CustomerId IS NULL OR Locations.CustomerId = @OldCustomerId)
)T
WHERE Rank = 1)
AND AssetLocations.AssetId NOT IN (SELECT AssetID FROM #NewLocationsWithEffectiveDateGreaterThanAssumptionDate)
SELECT
Id,
TaxExemptRuleId
INTO #ExistingLocationsToBeCreatedForNewCustomer
FROM Locations
WHERE CustomerId = @OldCustomerId
AND Locations.Id IN (SELECT ID FROM #NewLocationsForCustomer)
MERGE INTO TaxExemptRules
USING (SELECT #ExistingLocationsToBeCreatedForNewCustomer.*,
TaxExemptRules.IsCountryTaxExempt,TaxExemptRules.IsStateTaxExempt,TaxExemptRules.IsCountyTaxExempt,TaxExemptRules.IsCityTaxExempt FROM  #ExistingLocationsToBeCreatedForNewCustomer
INNER JOIN TaxExemptRules ON #ExistingLocationsToBeCreatedForNewCustomer.TaxExemptRuleId = TaxExemptRules.Id) AS TE
ON 1 = 0
WHEN NOT MATCHED THEN
INSERT
([EntityType]
,[IsCountryTaxExempt]
,[IsStateTaxExempt]
,[IsCityTaxExempt]
,[IsCountyTaxExempt]
,[CreatedById]
,[CreatedTime]
,[TaxExemptionReasonId])
VALUES(
'Location'
,IsCountryTaxExempt
,IsStateTaxExempt
,IsCityTaxExempt
,IsCountyTaxExempt
,@CreatedById
,@CreatedTime
,(SELECT TOP 1 ID FROM TaxExemptionReasonConfigs WHERE EntityType = 'Location' AND Reason = 'Dummy')
)
OUTPUT inserted.Id,TE.Id INTO #InsertedTaxExemptRuleIds;
INSERT INTO [dbo].[Locations]
([Code]
,[Name]
,[AddressLine1]
,[AddressLine2]
,[Division]
,[City]
,[PostalCode]
,[Description]
,[TaxAreaVerifiedTillDate]
,[IsActive]
,[TaxAreaId]
,[ApprovalStatus]
,[IncludedPostalCodeInLocationLookup]
,[TaxBasisType]
,[UpfrontTaxMode]
,[CountryTaxExemptionRate]
,[StateTaxExemptionRate]
,[DivisionTaxExemptionRate]
,[CityTaxExemptionRate]
,[CreatedById]
,[CreatedTime]
,[CustomerId]
,[StateId]
,[JurisdictionId]
,[ContactPersonId]
,[TaxExemptRuleId]
,[JurisdictionDetailId],
[PortfolioId]
,[Latitude]
,[Longitude])
OUTPUT inserted.Id , inserted.Code INTO #CreatedLocationIds
SELECT
DISTINCT #NewLocationsForCustomer.[Code]
,#NewLocationsForCustomer.[Name]
,#NewLocationsForCustomer.[AddressLine1]
,#NewLocationsForCustomer.[AddressLine2]
,#NewLocationsForCustomer.[Division]
,#NewLocationsForCustomer.[City]
,#NewLocationsForCustomer.[PostalCode]
,#NewLocationsForCustomer.[Description]
,#NewLocationsForCustomer.[TaxAreaVerifiedTillDate]
,#NewLocationsForCustomer.[IsActive]
,#NewLocationsForCustomer.[TaxAreaId]
,#NewLocationsForCustomer.[ApprovalStatus]
,#NewLocationsForCustomer.[IncludedPostalCodeInLocationLookup]
,#NewLocationsForCustomer.[TaxBasisType]
,#NewLocationsForCustomer.[UpfrontTaxMode]
,#NewLocationsForCustomer.[CountryTaxExemptionRate]
,#NewLocationsForCustomer.[StateTaxExemptionRate]
,#NewLocationsForCustomer.[DivisionTaxExemptionRate]
,#NewLocationsForCustomer.[CityTaxExemptionRate]
,@CreatedById
,@CreatedTime
,@NewCustomerId
,#NewLocationsForCustomer.[StateId]
,#NewLocationsForCustomer.[JurisdictionId]
,#NewLocationsForCustomer.[ContactPersonId]
,#InsertedTaxExemptRuleIds.Id
,#NewLocationsForCustomer.[JurisdictionDetailId]
,@PortfolioId
,#NewLocationsForCustomer.[Latitude]
,#NewLocationsForCustomer.[Longitude]
FROM #ExistingLocationsToBeCreatedForNewCustomer
INNER JOIN #NewLocationsForCustomer ON #ExistingLocationsToBeCreatedForNewCustomer.Id = #NewLocationsForCustomer.LocationId
INNER JOIN #InsertedTaxExemptRuleIds ON #NewLocationsForCustomer.LocationId = #InsertedTaxExemptRuleIds.LocationId
SET @MaxLocationCode = CONVERT(INT, (SELECT current_value FROM sys.sequences WHERE name = 'Location'))
SELECT
Locations.Id [NewLocationId],
Locations.Code ,
States.ShortName [StateShortName] ,
ROW_NUMBER() OVER(ORDER BY Locations.Code) + @MaxLocationCode - 1 [rownumber]
INTO #LocationsToBeUpdated
FROM #CreatedLocationIds
INNER JOIN Locations ON Locations.Code = #CreatedLocationIds.Code
INNER JOIN States ON Locations.StateId = States.Id
WHERE Locations.Id IN (SELECT ID FROM #CreatedLocationIds)
set @IncrementBy = (SELECT COUNT(*) FROM #LocationsToBeUpdated)
IF (@IncrementBy > 0)
BEGIN
	EXEC dbo.GetNextSqlSequence 'Location',@IncrementBy, @NextValue = @NextVal OUTPUT, @FirstValue = @FirstVal OUTPUT
END
UPDATE Locations SET Code = (@NewCustomerPartyNumber+ '-' + COALESCE(StateShortName,'') +'-'+ CONVERT(nvarchar(10), rownumber)) , UpdatedById= @CreatedById,UpdatedTime = @CreatedTime
FROM #LocationsToBeUpdated INNER JOIN Locations ON Locations.Id = #LocationsToBeUpdated.NewLocationId
SELECT
#CreatedLocationIds.Id [NewLocationId],
Locations.Id [OldLocationId]
INTO #OldandNewLocationMapping
FROM #CreatedLocationIds
INNER JOIN Locations ON Locations.Code = #CreatedLocationIds.Code
INSERT INTO [dbo].[LocationTaxAreaHistories]
([TaxAreaId]
,[TaxAreaEffectiveDate]
,[CreatedById]
,[CreatedTime]
,[LocationId])
SELECT
LTAH.TaxAreaId,
LTAH.TaxAreaEffectiveDate,
@CreatedById,
@CreatedTime,
ONM.NewLocationId
FROM LocationTaxAreaHistories LTAH
INNER JOIN #OldandNewLocationMapping ONM ON ONM.OldLocationId = LTAH.LocationId

INSERT INTO [dbo].[AssetLocations]
([EffectiveFromDate]
,[IsCurrent]
,[UpfrontTaxMode]
,[TaxBasisType]
,[IsActive]
,[CreatedById]
,[CreatedTime]
,[LocationId]
,[AssetId]
,[IsFLStampTaxExempt]
,ReciprocityAmount_Amount
,ReciprocityAmount_Currency
,LienCredit_Amount
,LienCredit_Currency
,UpfrontTaxAssessedInLegacySystem)
OUTPUT inserted.Id , inserted.AssetId, inserted.LocationId INTO #CreatedAssetLocationIds
SELECT
EffectiveFromDate,
IsCurrent,
UpfrontTaxMode,
TaxBasisType,
IsActive,
@CreatedById,
@CreatedTime,
#OldandNewLocationMapping.NewLocationId,
AssetId,
IsFLStampTaxExempt,
0,
@ContractCurrency,
0,
@ContractCurrency,
CAST(0 AS BIT)
FROM #ExistingLocationsToBeCreatedForNewCustomer
INNER JOIN #NewLocationsForCustomer ON #ExistingLocationsToBeCreatedForNewCustomer.Id = #NewLocationsForCustomer.LocationId
INNER JOIN #OldandNewLocationMapping ON #ExistingLocationsToBeCreatedForNewCustomer.Id  = #OldandNewLocationMapping.OldLocationId

UPDATE AssetLocations SET IsCurrent = 0, UpdatedById= @CreatedById,UpdatedTime = @CreatedTime
WHERE AssetId IN (SELECT AssetId FROM #AssumptionAssetsForUpdation) AND IsActive = 1 AND IsCurrent = 1

UPDATE AssetLocations
SET
	EffectiveFromDate=@EffectiveDate,
	UpdatedById= @CreatedById,
	UpdatedTime = @CreatedTime,
	TaxBasisType = AssetLocationsToUpdate.TaxBasisType
FROM
	(
		SELECT	AL.Id AS AssetLocationId,
				TaxBasisType = ISNULL(TBT.Name,AL.TaxBasisType),
				RANK() OVER ( PARTITION BY AL.AssetId ORDER BY AL.EffectiveFromDate , AL.Id DESC ) RankNumber
		FROM AssetLocations AL
			INNER JOIN #AssumptionAssetsForUpdation AAU ON AL.AssetId = AAU.AssetId AND AL.IsActive = 1
			LEFT JOIN AssumptionTaxAssessmentDetails ATD ON AAU.AssumptionId = ATD.AssumptionId AND ATD.IsActive = 1
			LEFT JOIN TaxBasisTypes TBT ON ATD.TaxBasisTypeId = TBT.Id
			WHERE AL.LocationId in (SELECT NewLocationId FROM #OldandNewLocationMapping)
	) AssetLocationsToUpdate
WHERE AssetLocationsToUpdate.AssetLocationId = Id
	AND AssetLocationsToUpdate.RankNumber = 1

UPDATE AssetLocations
SET IsCurrent = 1,
	UpdatedById= @CreatedById,
	UpdatedTime = @CreatedTime
FROM
	(
		SELECT	AL.Id AS AssetLocationId,
				TaxBasisType = ISNULL(TBT.Name,AL.TaxBasisType),
				RANK() OVER ( PARTITION BY AL.AssetId ORDER BY AL.EffectiveFromDate DESC, AL.Id DESC ) RankNumber
		FROM AssetLocations AL
			INNER JOIN #AssumptionAssetsForUpdation AAU ON AL.AssetId = AAU.AssetId AND AL.IsActive = 1
			LEFT JOIN AssumptionTaxAssessmentDetails ATD ON AAU.AssumptionId = ATD.AssumptionId AND ATD.IsActive = 1
			LEFT JOIN TaxBasisTypes TBT ON ATD.TaxBasisTypeId = TBT.Id
	) AssetLocationsToUpdate
WHERE AssetLocationsToUpdate.AssetLocationId = Id
	AND AssetLocationsToUpdate.RankNumber = 1

UPDATE AssetLocations SET IsActive=0
WHERE Id in(
	SELECT MIN(AL.Id) FROM AssetLocations AL
	JOIN #AssumptionAssetsForUpdation A ON AL.AssetId = A.AssetId and AL.IsActive=1
	GROUP BY AL.AssetId,AL.EffectiveFromDate
	HAVING COUNT(*) > 1
	);

IF(@TaxAssessmentLevel = 'Asset')
BEGIN
UPDATE AL
	SET AL.UpfrontTaxAssessedInLegacySystem = CAST(0 AS BIT)
FROM #AssumptionAssetsForUpdation AAU
JOIN AssetLocations AL ON AL.AssetId = AAU.AssetId AND AL.IsActive = 1
	AND AL.UpfrontTaxAssessedInLegacySystem = 1
JOIN Locations L ON AL.LocationId = L.Id AND L.CustomerId IS NULL
END

END

IF (@IsClone = 0 AND @NewLocationId IS NOT NULL)
BEGIN
UPDATE AssetLocations SET IsCurrent = 0, UpdatedById= @CreatedById,UpdatedTime = @CreatedTime  WHERE AssetId IN (SELECT AssetId FROM #AssumptionAssetsForUpdation) AND IsActive = 1 AND IsCurrent = 1
UPDATE AssetLocations SET IsActive = 0, UpdatedById= @CreatedById,UpdatedTime = @CreatedTime  WHERE AssetId IN (SELECT AssetId FROM #AssumptionAssetsForUpdation) AND EffectiveFromDate >= @EffectiveDate AND IsActive = 1
UPDATE Locations SET CustomerId = @NewCustomerId, UpdatedById= @CreatedById,UpdatedTime = @CreatedTime  WHERE Id IN (SELECT LocationId FROM #AssumptionAssetsForUpdation) AND CustomerId IS NULL
SELECT
Locations.TaxBasisType,
@FederalIncomeTaxExempt [IsFederalIncomeTaxExempt],
Locations.UpfrontTaxMode,
@EffectiveDate [EffectiveDate],
1 [IsCurrent],
1 [IsActive],
Locations.Id [LocationId],
AssumptionAssets.AssetId INTO #InsertIntoAssetLocations
FROM AssumptionAssets
INNER JOIN Locations ON AssumptionAssets.LocationId = Locations.Id
WHERE Locations.IsActive = 1
AND AssumptionAssets.AssumptionId = @AssumptionId
AND AssumptionAssets.IsActive = 1
INSERT INTO [dbo].[AssetLocations]
([EffectiveFromDate]
,[IsCurrent]
,[UpfrontTaxMode]
,[TaxBasisType]
,[IsActive]
,[CreatedById]
,[CreatedTime]
,[LocationId]
,[AssetId]
,[IsFLStampTaxExempt]
,ReciprocityAmount_Amount
,ReciprocityAmount_Currency
,LienCredit_Amount
,LienCredit_Currency
,UpfrontTaxAssessedInLegacySystem)
SELECT
EffectiveDate,
IsCurrent,
UpfrontTaxMode,
TaxBasisType,
IsActive,
@CreatedById,
@CreatedTime,
LocationId,
AssetId,
IsFederalIncomeTaxExempt,
0,
@ContractCurrency,
0,
@ContractCurrency,
CAST(0 AS BIT)
FROM #InsertIntoAssetLocations

UPDATE AssetLocations
SET IsCurrent = 1,
	UpdatedById= @CreatedById,
	UpdatedTime = @CreatedTime,
	TaxBasisType = AssetLocationToUpdate.TaxBasisType
FROM
	(
		SELECT AL.Id AS AssetLocationId,
		TaxBasisType = ISNULL(TBT.Name,AL.TaxBasisType),
		RANK() OVER ( PARTITION BY AL.AssetId ORDER BY AL.EffectiveFromDate DESC, AL.Id DESC ) RankNumber
		FROM AssetLocations AL
			INNER JOIN #AssumptionAssetsForUpdation AAU ON AL.AssetId = AAU.AssetId AND AL.IsActive = 1
			LEFT JOIN AssumptionTaxAssessmentDetails ATD ON AAU.AssumptionId = ATD.AssumptionId AND ATD.IsActive = 1
			LEFT JOIN TaxBasisTypes TBT ON ATD.TaxBasisTypeId = TBT.Id
	) AssetLocationToUpdate
WHERE AssetLocationToUpdate.AssetLocationId = Id
	AND AssetLocationToUpdate.RankNumber = 1

UPDATE AssetLocations SET IsActive=0
WHERE Id in(
	SELECT MIN(AL.Id) FROM AssetLocations AL
	JOIN #AssumptionAssetsForUpdation A ON AL.AssetId = A.AssetId and AL.IsActive=1
	GROUP BY AL.AssetId,AL.EffectiveFromDate
	HAVING COUNT(*) > 1
	);

END


DECLARE @ContractACHAssignmentCount INT = (SELECT COUNT(ID) FROM ContractACHAssignments WHERE ContractBillingId = @ContractId)
DECLARE @BankAccountId BIGINT = (SELECT TOP 1 BankAccounts.ID FROM PartyBankAccounts
INNER JOIN BankAccounts ON PartyBankAccounts.BankAccountId = BankAccounts.Id
WHERE PartyId = @NewCustomerId
AND BankAccounts.IsActive = 1
AND BankAccounts.IsPrimaryACH = 1)
UPDATE ContractAssumptionHistories SET IsActive = 0 , UpdatedById= @CreatedById,UpdatedTime = @CreatedTime
WHERE ContractId = @ContractId AND AssumptionDate >= @AssumptionDate
UPDATE Contracts SET Contracts.SequenceNumber = @NewSequenceNumber ,UpdatedById= @CreatedById,UpdatedTime = @CreatedTime
WHERE Id = @ContractId AND @NewSequenceNumber <> Contracts.SequenceNumber
INSERT INTO ContractAssumptionHistories
(
AssumptionId,
AssumptionDate,
CustomerId,
ContractId,
BillToId,
IsActive,
CreatedTime,
CreatedById,
FinanceId,
SequenceNumber
)
VALUES
(
@AssumptionId,
@AssumptionDate,
@OldCustomerId,
@ContractId,
@OldBillToId,
1,
@CreatedTime,
@CreatedById,
ISNULL(@LeaseFinanceId,@LoanFinanceId),
@SequenceNumber
)
IF @ContractType = 'Lease'
BEGIN
SELECT driversAssignedToAssets.DriverId,assumptionAssets.AssetId,assumptionAssets.Id assumptionAssetsId,
assumptionAssets.UpdateDriverAssignment,assumptionAssets.NewDriverId,driversAssignedToAssets.Assigneddate INTO #DriverDetailsForUpdation
FROM AssumptionAssets assumptionAssets LEFT JOIN DriversAssignedToAssets driversAssignedToAssets
ON assumptionAssets.AssetId = driversAssignedToAssets.AssetId
AND driversAssignedToAssets.Assign=1
WHERE assumptionAssets.AssumptionId=@AssumptionId AND assumptionAssets.IsActive=1 AND
(driversAssignedToAssets.DriverId IS NULL OR driversAssignedToAssets.Assign=1 )
SELECT DriversAssignedToAssets.AssetId
,DriversAssignedToAssets.DriverId
,DriversAssignedToAssets.Id DriversAssignedToAssetId
,DriversAssignedToAssets.AssignedDate
INTO #UnassignedAssets
FROM DriversAssignedToAssets
Where DriversAssignedToAssets.DriverId IN (SELECT DriverId  FROM  #DriverDetailsForUpdation WHERE #DriverDetailsForUpdation.UpdateDriverAssignment=1)
AND DriversAssignedToAssets.AssetId NOT IN (SELECT AssetId FROM  #DriverDetailsForUpdation )
AND DriversAssignedToAssets.Assign=1
UPDATE DriversAssignedToAssets SET Assign=0,UnassignedDate=@AssumptionDate,UpdatedById = @CreatedById,UpdatedTime =@CreatedTime
Where Id IN (SELECT DriversAssignedToAssetId FROM #UnassignedAssets)
UPDATE Drivers SET CustomerId = @NewCustomerId,UpdatedById = @CreatedById,UpdatedTime =@CreatedTime WHERE Id IN (SELECT DriverId  FROM  #DriverDetailsForUpdation WHERE #DriverDetailsForUpdation.UpdateDriverAssignment=1)
INSERT INTO DriverHistories(ReasonDescription,CustomerId,DriverId,CreatedById,CreatedTime,SourceModule,SourceId)
SELECT DISTINCT
'CustomerChanged' , @NewCustomerId , DriverId , @CreatedById , @CreatedTime , 'Assumption', @AssumptionId
FROM #DriverDetailsForUpdation
WHERE #DriverDetailsForUpdation.UpdateDriverAssignment=1 AND #DriverDetailsForUpdation.DriverId IS NOT NULL
INSERT INTO DriverHistories(AssignedDate,UnassignedDate,ReasonDescription,AssetId,CustomerId,DriverId,CreatedById,CreatedTime,SourceModule,SourceId,ContractId)
SELECT  DISTINCT AssignedDate,@AssumptionDate,'DriverUnassigned',AssetId,@OldCustomerId,DriverId,@CreatedById,@CreatedTime,'Assumption', @AssumptionId,@ContractId
FROM #DriverDetailsForUpdation
WHERE #DriverDetailsForUpdation.UpdateDriverAssignment=1 AND #DriverDetailsForUpdation.DriverId IS NOT NULL
INSERT INTO DriverHistories(AssignedDate,UnassignedDate,ReasonDescription,AssetId,CustomerId,DriverId,CreatedById,CreatedTime,SourceModule,SourceId,ContractId)
SELECT  DISTINCT @AssumptionDate,null,'DriverAssigned',AssetId,@NewCustomerId,DriverId,@CreatedById,@CreatedTime,'Assumption', @AssumptionId,@ContractId
FROM #DriverDetailsForUpdation
WHERE #DriverDetailsForUpdation.UpdateDriverAssignment=1 AND #DriverDetailsForUpdation.DriverId IS NOT NULL
INSERT INTO DriverHistories(AssignedDate,UnassignedDate,ReasonDescription,AssetId,CustomerId,DriverId,CreatedById,CreatedTime,SourceModule,SourceId,ContractId)
SELECT DISTINCT AssignedDate,@AssumptionDate,'DriverUnassigned',AssetId,@OldCustomerId,DriverId,@CreatedById,@CreatedTime,'Assumption', @AssumptionId,@ContractId  FROM #UnassignedAssets
SELECT DriversAssignedToAssets.AssetId
,DriversAssignedToAssets.DriverId
,DriversAssignedToAssets.Id DriversAssignedToAssetId
,DriversAssignedToAssets.AssignedDate
INTO #UnassignedDrivers
FROM DriversAssignedToAssets
Where DriversAssignedToAssets.DriverId IN (SELECT DriverId  FROM  #DriverDetailsForUpdation WHERE #DriverDetailsForUpdation.UpdateDriverAssignment=0)
AND DriversAssignedToAssets.AssetId  IN (SELECT AssetId FROM  #DriverDetailsForUpdation WHERE #DriverDetailsForUpdation.UpdateDriverAssignment=0)
AND DriversAssignedToAssets.Assign=1
UPDATE DriversAssignedToAssets SET Assign=0,UnassignedDate=@AssumptionDate,UpdatedById = @CreatedById,UpdatedTime =@CreatedTime
Where Id IN (SELECT DriversAssignedToAssetId FROM #UnassignedDrivers)
INSERT INTO DriverHistories(AssignedDate,UnassignedDate,ReasonDescription,AssetId,CustomerId,DriverId,CreatedById,CreatedTime,SourceModule,SourceId,ContractId)
SELECT DISTINCT AssignedDate,@AssumptionDate,'DriverUnassigned',AssetId,@OldCustomerId,DriverId,@CreatedById,@CreatedTime,'Assumption', @AssumptionId,@ContractId  FROM #UnassignedDrivers
INSERT INTO [dbo].[DriversAssignedToAssets]
([Assign]
,[AssignedDate]
,[IsPrimary]
,[AssetId]
,[DriverId]
,[CreatedById]
,[CreatedTime])
SELECT
1,
@AssumptionDate,
0,
AssetId,
NewDriverId,
@CreatedById,
@CreatedTime
FROM  #DriverDetailsForUpdation
WHERE #DriverDetailsForUpdation.UpdateDriverAssignment=0
AND NewDriverId IS NOT NULL
INSERT INTO DriverHistories(AssignedDate,ReasonDescription,AssetId,CustomerId,DriverId,CreatedById,CreatedTime,SourceModule,SourceId,ContractId )
SELECT DISTINCT @AssumptionDate,'DriverAssigned',AssetId,@NewCustomerId,NewDriverId,@CreatedById,@CreatedTime,'Assumption',@AssumptionId,@ContractId
FROM  #DriverDetailsForUpdation
WHERE #DriverDetailsForUpdation.UpdateDriverAssignment=0
AND NewDriverId IS NOT NULL
END

END

GO
