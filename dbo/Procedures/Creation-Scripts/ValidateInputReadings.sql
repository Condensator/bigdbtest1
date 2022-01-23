SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[ValidateInputReadings]
(
@InstanceId UNIQUEIDENTIFIER,
@CPINumberIsMandatory NVARCHAR(200),
@MeterTypeIsMandatory NVARCHAR(200),
@EndPeriodDateIsMandatory NVARCHAR(200),
@ReadDateIsMandatory NVARCHAR(200),
@EndReadingIsMandatory NVARCHAR(200),
@CPUContractStatusCommenced NVARCHAR(10),
@CPUContractStatusPaidoff NVARCHAR(10),
@Replace NVARCHAR(20),
@Rollover NVARCHAR(20),
@AssetIdAndAliasNotMatching NVARCHAR(200),
@AssetIdIsNotValid NVARCHAR(200),
@AliasIsNotValid NVARCHAR(200),
@AssetSerialNumberNotValid NVARCHAR(200),
@InvalidMeterType NVARCHAR(200),
@AssetAndMeterTypeInvalidCombination NVARCHAR(200),
@AssetNotInCPUContract NVARCHAR(200),
@BeginReadingMustBePositive NVARCHAR(200),
@EndReadingValueMustBePositive NVARCHAR(200),
@ServiceCreditsMustBePositive NVARCHAR(200),
@BeginReadingExceedingMaxReading NVARCHAR(200),
@EndReadingExceedingMaxReading NVARCHAR(200),
@ContractMustBeCommencedOrPaidoff NVARCHAR(200),
@CPUContractInvalid NVARCHAR(200),
@EndReadingLessThanBeginReadingCheck NVARCHAR(200),
@RolloverReadingMaxReading NVARCHAR(200),
@ResetTypeModification NVARCHAR(200),
@SourceIsNotValid NVARCHAR(200),
@Dealer NVARCHAR(200),
@Customer NVARCHAR(200),
@Lessor NVARCHAR(200),
@Others NVARCHAR(200),
@MeterResetTypeIsNotValid NVARCHAR(200),
@EndReadingLessThanBeginReading NVARCHAR(200),
@EndPeriodDateForReplaceShouldBePreviousEndPeriodDate NVARCHAR(200),
@ReadDateLessThanScheduleBeginDate NVARCHAR(200),
@EndPeriodDateLessThanAssetBeginDate NVARCHAR(200),
@MeterReadingsForCPUAssetsPaidOffAtInception NVARCHAR(200),
@AssetMultipleSerialNumberType NVARCHAR(10),
@AssetMultipleSerialNumberNotValid NVARCHAR(200),
@CreatedById BIGINT,
@CreatedTime DATETIMEOFFSET
)
AS
BEGIN

INSERT INTO EnmasseMeterReadingInstances (CPINumber,AssetId,Alias,SerialNumber,MeterType,EndPeriodDate,ReadDate,BeginReading,EndReading,ServiceCredits
,Source,IsEstimated,MeterResetType,InstanceId,RowId,IsFaulted,IsFirstReadingCorrected,OriginalBeginReading,OriginalSource,CreatedById,CreatedTime,IsFirstReading,IsCorrection,IsAggregate)
SELECT CPINumber,AssetId,Alias,SerialNumber,MeterType,EndPeriodDate,ReadDate,BeginReading,EndReading,ServiceCredits
,Source,IsEstimated,MeterResetType,InstanceId,ROW_NUMBER() OVER (ORDER BY ID) as RowId,0,0,BeginReading,Source,@CreatedById,@CreatedTime,0,0,0
FROM EnmasseMeterReadingInputs
WHERE EnmasseMeterReadingInputs.InstanceId = @InstanceId
UPDATE EnmasseMeterReadingInstances
SET EnmasseMeterReadingInstances.MatchedAssetId = Assets.Id
FROM
EnmasseMeterReadingInstances
INNER JOIN Assets
ON EnmasseMeterReadingInstances.AssetId = Assets.Id AND
Assets.Alias = EnmasseMeterReadingInstances.Alias
WHERE
EnmasseMeterReadingInstances.InstanceId = @InstanceId AND
EnmasseMeterReadingInstances.Alias IS NOT NULL AND
EnmasseMeterReadingInstances.AssetId IS NOT NULL
INSERT INTO EnmasseMeterReadingLogs
(
EnmasseMeterReadingInstanceId
,Error
,CreatedById
,CreatedTime
)
SELECT
EnmasseMeterReadingInstances.Id
,@AssetIdAndAliasNotMatching
,@CreatedById
,@CreatedTime
FROM
EnmasseMeterReadingInstances
WHERE
ROWId IN (
SELECT
ROWId
FROM
EnmasseMeterReadingInstances
WHERE
EnmasseMeterReadingInstances.InstanceId = @InstanceId AND
AssetId IS NOT NULL AND
Alias IS NOT NULL AND
MatchedAssetId IS NULL
) AND
EnmasseMeterReadingInstances.InstanceId = @InstanceId
UPDATE EnmasseMeterReadingInstances
SET EnmasseMeterReadingInstances.MatchedAssetId = Assets.Id
FROM
EnmasseMeterReadingInstances
INNER JOIN Assets
ON EnmasseMeterReadingInstances.AssetId = Assets.Id
WHERE
EnmasseMeterReadingInstances.InstanceId = @InstanceId AND
EnmasseMeterReadingInstances.Alias IS NULL
INSERT INTO EnmasseMeterReadingLogs
(
EnmasseMeterReadingInstanceId
,Error
,CreatedById
,CreatedTime
)
SELECT
EnmasseMeterReadingInstances.Id
,@AssetIdIsNotValid
,@CreatedById
,@CreatedTime
FROM
EnmasseMeterReadingInstances
WHERE
ROWId IN (
SELECT
ROWId
FROM
EnmasseMeterReadingInstances
WHERE
EnmasseMeterReadingInstances.InstanceId = @InstanceId AND
AssetId IS NOT NULL AND
Alias IS NULL AND
MatchedAssetId IS NULL
)AND
EnmasseMeterReadingInstances.InstanceId = @InstanceId
UPDATE
EnmasseMeterReadingInstances
SET
MatchedAssetId = Assets.Id
FROM
EnmasseMeterReadingInstances
INNER JOIN Assets
ON EnmasseMeterReadingInstances.Alias = Assets.Alias
WHERE
EnmasseMeterReadingInstances.AssetId IS NULL AND
EnmasseMeterReadingInstances.InstanceId = @InstanceId
INSERT INTO EnmasseMeterReadingLogs
(
EnmasseMeterReadingInstanceId
,Error
,CreatedById
,CreatedTime
)
SELECT
EnmasseMeterReadingInstances.Id
,@AliasIsNotValid
,@CreatedById
,@CreatedTime
FROM
EnmasseMeterReadingInstances
WHERE ROWId IN (
SELECT
ROWId
FROM
EnmasseMeterReadingInstances
WHERE EnmasseMeterReadingInstances.Alias IS NOT NULL AND
EnmasseMeterReadingInstances.AssetId IS NULL AND
MatchedAssetId IS NULL AND
InstanceId = @InstanceId
) AND
EnmasseMeterReadingInstances.InstanceId = @InstanceId
INSERT INTO EnmasseMeterReadingLogs
(
EnmasseMeterReadingInstanceId
,Error
,CreatedById
,CreatedTime
)
SELECT
EnmasseMeterReadingInstances.Id
,@CPINumberIsMandatory
,@CreatedById
,@CreatedTime
FROM
EnmasseMeterReadingInstances
WHERE
ROWId IN (
SELECT
ROWId
FROM
EnmasseMeterReadingInstances
WHERE
EnmasseMeterReadingInstances.InstanceId = @InstanceId AND
CPINumber IS NULL
) AND
EnmasseMeterReadingInstances.InstanceId = @InstanceId
INSERT INTO EnmasseMeterReadingLogs
(
EnmasseMeterReadingInstanceId
,Error
,CreatedById
,CreatedTime
)
SELECT
EnmasseMeterReadingInstances.Id
,@MeterTypeIsMandatory
,@CreatedById
,@CreatedTime
FROM
EnmasseMeterReadingInstances
WHERE
ROWId IN (
SELECT
ROWId
FROM
EnmasseMeterReadingInstances
WHERE
EnmasseMeterReadingInstances.InstanceId = @InstanceId AND
MeterType IS NULL
) AND
EnmasseMeterReadingInstances.InstanceId = @InstanceId
INSERT INTO EnmasseMeterReadingLogs
(
EnmasseMeterReadingInstanceId
,Error
,CreatedById
,CreatedTime
)
SELECT
EnmasseMeterReadingInstances.Id
,@EndPeriodDateIsMandatory
,@CreatedById
,@CreatedTime
FROM
EnmasseMeterReadingInstances
WHERE
ROWId IN (
SELECT
ROWId
FROM
EnmasseMeterReadingInstances
WHERE
EnmasseMeterReadingInstances.InstanceId = @InstanceId AND
EndPeriodDate IS NULL
) AND
EnmasseMeterReadingInstances.InstanceId = @InstanceId
INSERT INTO EnmasseMeterReadingLogs
(
EnmasseMeterReadingInstanceId
,Error
,CreatedById
,CreatedTime
)
SELECT
EnmasseMeterReadingInstances.Id
,@ReadDateIsMandatory
,@CreatedById
,@CreatedTime
FROM
EnmasseMeterReadingInstances
WHERE
ROWId IN (
SELECT
ROWId
FROM
EnmasseMeterReadingInstances
WHERE
EnmasseMeterReadingInstances.InstanceId = @InstanceId AND
ReadDate IS NULL
) AND
EnmasseMeterReadingInstances.InstanceId = @InstanceId
INSERT INTO EnmasseMeterReadingLogs
(
EnmasseMeterReadingInstanceId
,Error
,CreatedById
,CreatedTime
)
SELECT
EnmasseMeterReadingInstances.Id
,@EndReadingIsMandatory
,@CreatedById
,@CreatedTime
FROM
EnmasseMeterReadingInstances
WHERE
ROWId IN (
SELECT
ROWId
FROM
EnmasseMeterReadingInstances
WHERE
EnmasseMeterReadingInstances.InstanceId = @InstanceId AND
EndReading IS NULL
) AND
EnmasseMeterReadingInstances.InstanceId = @InstanceId
INSERT INTO EnmasseMeterReadingLogs
(
EnmasseMeterReadingInstanceId
,Error
,CreatedById
,CreatedTime
)
SELECT
EnmasseMeterReadingInstances.Id
,@SourceIsNotValid
,@CreatedById
,@CreatedTime
FROM
EnmasseMeterReadingInstances
WHERE ROWId IN (
SELECT
ROWId
FROM
EnmasseMeterReadingInstances
WHERE EnmasseMeterReadingInstances.Source NOT IN(@Dealer,@Customer,@Lessor,@Others) AND
InstanceId = @InstanceId
) AND
EnmasseMeterReadingInstances.InstanceId = @InstanceId
INSERT INTO EnmasseMeterReadingLogs
(
EnmasseMeterReadingInstanceId
,Error
,CreatedById
,CreatedTime
)
SELECT
EnmasseMeterReadingInstances.Id
,@MeterResetTypeIsNotValid
,@CreatedById
,@CreatedTime
FROM
EnmasseMeterReadingInstances
WHERE ROWId IN (
SELECT
ROWId
FROM
EnmasseMeterReadingInstances
WHERE EnmasseMeterReadingInstances.MeterResetType NOT IN('_',@Replace,@Rollover) AND
InstanceId = @InstanceId
) AND
EnmasseMeterReadingInstances.InstanceId = @InstanceId
UPDATE
EnmasseMeterReadingInstances
SET
CPUAssetId = CPUAssets.Id
FROM
EnmasseMeterReadingInstances
INNER JOIN CPUAssets
ON EnmasseMeterReadingInstances.MatchedAssetId = CPUAssets.AssetId AND
CPUAssets.IsActive = 1
INNER JOIN CPUSchedules
ON CPUAssets.CPUScheduleId = CPUSchedules.Id
INNER JOIN CPUContracts
ON CPUSchedules.CPUFinanceId = CPUContracts.CPUFinanceId AND
CPUContracts.SequenceNumber = EnmasseMeterReadingInstances.CPINumber
INNER JOIN CPUBaseStructures
ON CPUSchedules.Id = CPUBaseStructures.Id
INNER JOIN AssetMeterTypes
ON CPUSchedules.MeterTypeId = AssetMeterTypes.Id AND
EnmasseMeterReadingInstances.MeterType = AssetMeterTypes.Name
INNER JOIN AssetMeters
ON AssetMeters.AssetId = CPUAssets.AssetId AND
AssetMeters.AssetMeterTypeId = AssetMeterTypes.Id
WHERE
EnmasseMeterReadingInstances.InstanceId = @InstanceId
AND (
CPUAssets.PayoffDate IS NULL
OR (CPUBaseStructures.IsAggregate = 0 AND EnmasseMeterReadingInstances.EndPeriodDate <= CPUAssets.PayoffDate)
OR CPUAssets.BeginDate != CPUAssets.PayoffDate
)
SELECT DISTINCT
EnmasseMeterReadingInstances.Id,
BusinessUnits.PortFolioId ,
CPUAssets.Id CPUAssetId,
CPUContracts.Id CPUContractId,
CPUAssets.MaximumReading,
CPUAssetMeterReadings.MeterResetType,
CPUAssetMeterReadings.EndPeriodDate,
AssetMeters.BeginReading,
CPUSchedules.Id CPUScheduleId,
EnmasseMeterReadingInstances.InstanceId,
CPUBaseStructures.IsAggregate,
CPUAssets.BeginDate,
AssetMeters.IsActive AssetMetersActive,
AssetMeterTypes.IsActive AssetMeterTypesActive,
CPUAssetMeterReadingHeaders.Id CPUAssetMeterReadingHeaderId,
CPUContracts.Status,
CPUContracts.SequenceNumber,
CPUSchedules.ScheduleNumber,
ScheduleBeginDate=CPUSchedules.CommencementDate,
PayOffDate = CPUAssets.PayoffDate
INTO #ContractInfo
FROM
EnmasseMeterReadingInstances
INNER JOIN CPUContracts
ON EnmasseMeterReadingInstances.CPINumber = CPUContracts.SequenceNumber
INNER JOIN CPUFinances
ON CPUContracts.CPUFinanceId = CPUFinances.Id
INNER JOIN LegalEntities
ON CPUFinances.LegalEntityId = LegalEntities.Id
INNER JOIN BusinessUnits
ON LegalEntities.BusinessUnitId = BusinessUnits.Id
INNER JOIN CPUSchedules
ON CPUSchedules.CPUFinanceId = CPUFinances.Id AND CPUSchedules.IsActive=1
INNER JOIN CPUAssets
ON CPUSchedules.Id = CPUAssets.CPUScheduleId AND
CPUAssets.IsActive = 1 AND
EnmasseMeterReadingInstances.MatchedAssetId = CPUAssets.AssetId
INNER JOIN AssetMeterTypes
ON CPUSchedules.MeterTypeId = AssetMeterTypes.Id AND
EnmasseMeterReadingInstances.MeterType = AssetMeterTypes.Name
INNER JOIN AssetMeters
ON AssetMeters.AssetId = CPUAssets.AssetId AND
AssetMeters.AssetMeterTypeId = AssetMeterTypes.Id
INNER JOIN CPUOverageStructures ON CPUSchedules.Id = CPUOverageStructures.Id
INNER JOIN CPUBaseStructures ON CPUSchedules.Id = CPUBaseStructures.Id
INNER JOIN CPUAssetMeterReadingHeaders
ON CPUAssets.Id = CPUAssetMeterReadingHeaders.CPUAssetId
LEFT JOIN CPUAssetMeterReadings
ON EnmasseMeterReadingInstances.CPUAssetId = CPUAssetMeterReadings.CPUAssetId AND
EnmasseMeterReadingInstances.EndPeriodDate = CPUAssetMeterReadings.EndPeriodDate AND
CPUAssetMeterReadings.MeterResetType <> @Replace AND
CPUAssetMeterReadings.IsActive = 1
WHERE EnmasseMeterReadingInstances.InstanceId = @InstanceId
UPDATE
EnmasseMeterReadingInstances
SET
CPUContractId = #ContractInfo.CPUContractId,
PortFolioId = #ContractInfo.PortfolioId,
CPUScheduleId = #ContractInfo.CPUScheduleId,
CPUAssetMeterReadingHeaderId= #ContractInfo.CPUAssetMeterReadingHeaderId,
MeterMaxReading = #ContractInfo.MaximumReading,
ContractSequenceNumber = #ContractInfo.SequenceNumber,
ScheduleNumber = #ContractInfo.ScheduleNumber
FROM
EnmasseMeterReadingInstances
INNER JOIN #ContractInfo
ON EnmasseMeterReadingInstances.Id = #ContractInfo.Id
WHERE
(
#ContractInfo.Status = @CPUContractStatusCommenced
OR #ContractInfo.Status = @CPUContractStatusPaidoff
)
AND
EnmasseMeterReadingInstances.InstanceId = @InstanceId
INSERT INTO EnmasseMeterReadingLogs
(
EnmasseMeterReadingInstanceId
,Error
,CreatedById
,CreatedTime
)
SELECT
EnmasseMeterReadingInstances.Id
,REPLACE(@MeterReadingsForCPUAssetsPaidOffAtInception,'@PayoffDate',PayOffDate)
,@CreatedById
,@CreatedTime
FROM
EnmasseMeterReadingInstances
JOIN #ContractInfo ON EnmasseMeterReadingInstances.Id = #ContractInfo.Id
WHERE #ContractInfo.BeginDate = #ContractInfo.PayoffDate
AND EnmasseMeterReadingInstances.InstanceId = @InstanceId
INSERT INTO EnmasseMeterReadingLogs
(
EnmasseMeterReadingInstanceId
,Error
,CreatedById
,CreatedTime
)
SELECT
EnmasseMeterReadingInstances.Id
,@ContractMustBeCommencedOrPaidoff
,@CreatedById
,@CreatedTime
FROM
EnmasseMeterReadingInstances
WHERE
EnmasseMeterReadingInstances.Id IN
(
SELECT Id
FROM
#ContractInfo
WHERE
#ContractInfo.Status NOT IN (@CPUContractStatusCommenced, @CPUContractStatusPaidoff)
)
AND EnmasseMeterReadingInstances.InstanceId = @InstanceId
INSERT INTO EnmasseMeterReadingLogs
(
EnmasseMeterReadingInstanceId
,Error
,CreatedById
,CreatedTime
)
SELECT
EnmasseMeterReadingInstances.Id
,@CPUContractInvalid
,@CreatedById
,@CreatedTime
FROM
EnmasseMeterReadingInstances
WHERE Id NOT IN (SELECT Id FROM #ContractInfo) AND
EnmasseMeterReadingInstances.InstanceId = @InstanceId
------------------------------- Validation For Read Date---------------------------------------------------
INSERT INTO EnmasseMeterReadingLogs
(
EnmasseMeterReadingInstanceId
,Error
,CreatedById
,CreatedTime
)
SELECT EnmasseMeterReadingInstances.Id
,@ReadDateLessThanScheduleBeginDate
,@CreatedById
,@CreatedTime
FROM EnmasseMeterReadingInstances
INNER JOIN #ContractInfo ON EnmasseMeterReadingInstances.Id = #ContractInfo.Id
WHERE EnmasseMeterReadingInstances.ReadDate < #ContractInfo.ScheduleBeginDate  AND
EnmasseMeterReadingInstances.InstanceId = @InstanceId

INSERT INTO EnmasseMeterReadingLogs
(
EnmasseMeterReadingInstanceId
,Error
,CreatedById
,CreatedTime
)
SELECT EnmasseMeterReadingInstances.Id
,@EndPeriodDateLessThanAssetBeginDate
,@CreatedById
,@CreatedTime
FROM EnmasseMeterReadingInstances
INNER JOIN #ContractInfo ON EnmasseMeterReadingInstances.Id = #ContractInfo.Id
WHERE EnmasseMeterReadingInstances.EndPeriodDate < #ContractInfo.BeginDate AND
EnmasseMeterReadingInstances.InstanceId = @InstanceId
------------------------------------------------------------------------------------------------------------
INSERT INTO EnmasseMeterReadingLogs
(
EnmasseMeterReadingInstanceId
,Error
,CreatedById
,CreatedTime
)
SELECT
EnmasseMeterReadingInstances.Id
,@AssetNotInCPUContract
,@CreatedById
,@CreatedTime
FROM
EnmasseMeterReadingInstances
WHERE MatchedAssetId IS NOT NULL AND
CPUContractId IS NOT NULL AND
CPUAssetId IS NULL AND
EnmasseMeterReadingInstances.InstanceId = @InstanceId
UPDATE
EnmasseMeterReadingInstances
SET
AssetMeterTypeId = AssetMeterTypes.Id
FROM
EnmasseMeterReadingInstances
INNER JOIN AssetMeterTypes
ON AssetMeterTypes.Name = EnmasseMeterReadingInstances.MeterType AND
AssetMeterTypes.PortfolioId = EnmasseMeterReadingInstances.PortFolioId
WHERE
EnmasseMeterReadingInstances.MatchedAssetId IS NOT NULL AND
EnmasseMeterReadingInstances.InstanceId = @InstanceId
INSERT INTO EnmasseMeterReadingLogs
(
EnmasseMeterReadingInstanceId
,Error
,CreatedById
,CreatedTime
)
SELECT
EnmasseMeterReadingInstances.Id
,@InvalidMeterType
,@CreatedById
,@CreatedTime
FROM
EnmasseMeterReadingInstances
WHERE AssetMeterTypeId IS NULL AND
MeterType IS NOT NULL AND
EnmasseMeterReadingInstances.InstanceId = @InstanceId
INSERT INTO EnmasseMeterReadingLogs
(
EnmasseMeterReadingInstanceId
,Error
,CreatedById
,CreatedTime
)
SELECT  EnmasseMeterReadingInstances.Id
,@AssetAndMeterTypeInvalidCombination
,@CreatedById
,@CreatedTime
FROM
EnmasseMeterReadingInstances
WHERE ROWId NOT IN (
SELECT
ROWId
FROM
EnmasseMeterReadingInstances
INNER JOIN CPUAssets ON EnmasseMeterReadingInstances.CPUAssetId= CPUAssets.Id AND
CPUAssets.IsActive=1
INNER JOIN CPUSchedules ON CPUAssets.CPUScheduleId = CPUSchedules.Id AND
EnmasseMeterReadingInstances.AssetMeterTypeId = CPUSchedules.MeterTypeId AND
CPUSchedules.IsActive=1
WHERE EnmasseMeterReadingInstances.AssetMeterTypeId IS NOT NULL AND
MeterType IS NOT NULL AND
EnmasseMeterReadingInstances.InstanceId = @InstanceId) AND
EnmasseMeterReadingInstances.InstanceId = @InstanceId
UPDATE EnmasseMeterReadingInstances
SET IsAggregate = #ContractInfo.IsAggregate
FROM EnmasseMeterReadingInstances
JOIN #ContractInfo
ON EnmasseMeterReadingInstances.Id = #ContractInfo.Id
UPDATE  EnmasseMeterReadingInstances SET IsFaulted = 1
FROM
EnmasseMeterReadingInstances
INNER JOIN EnmasseMeterReadingLogs
ON EnmasseMeterReadingLogs.EnmasseMeterReadingInstanceId = EnmasseMeterReadingInstances.Id AND 
IsFaulted = 0 AND
EnmasseMeterReadingInstances.InstanceId = @InstanceId

INSERT INTO EnmasseMeterReadingLogs
(
EnmasseMeterReadingInstanceId
,Error
,CreatedById
,CreatedTime
)
SELECT EnmasseMeterReadingInstanceId = InvalidRecord.Id, 
	Error= InvalidRecord.Error, 
	@CreatedById,
	@CreatedTime FROM (
		SELECT EnmasseMeterReadingInstances.Id,@AssetMultipleSerialNumberNotValid AS Error FROM EnmasseMeterReadingInstances 
		INNER JOIN Assets A ON EnmasseMeterReadingInstances.MatchedAssetId = A.Id 
		WHERE EnmasseMeterReadingInstances.SerialNumber IS NOT NULL AND IsFaulted=0 AND InstanceId = @InstanceId
		AND A.Quantity > 1 
		AND EnmasseMeterReadingInstances.SerialNumber <> @AssetMultipleSerialNumberType
		AND EXISTS (SELECT 1 FROM AssetSerialNumbers ASN WHERE ASN.AssetId = EnmasseMeterReadingInstances.MatchedAssetId AND ASN.IsActive = 1)

		UNION 

		SELECT EnmasseMeterReadingInstances.Id,@AssetSerialNumberNotValid AS Error FROM EnmasseMeterReadingInstances 
		inner join Assets A ON EnmasseMeterReadingInstances.MatchedAssetId = A.Id 
		INNER JOIN AssetSerialNumbers ASN ON ASN.AssetId = A.Id AND ASN.IsActive = 1
		WHERE EnmasseMeterReadingInstances.SerialNumber IS NOT NULL AND IsFaulted=0 AND InstanceId = @InstanceId
		AND A.Quantity = 1 
		AND EnmasseMeterReadingInstances.SerialNumber <> ISNULL(ASN.SerialNumber,'')

		UNION

		SELECT EnmasseMeterReadingInstances.Id,@AssetSerialNumberNotValid AS Error FROM EnmasseMeterReadingInstances
		WHERE EnmasseMeterReadingInstances.SerialNumber IS NOT NULL AND IsFaulted=0 AND InstanceId = @InstanceId 
		AND NOT EXISTS (SELECT 1 FROM AssetSerialNumbers ASN WHERE ASN.AssetId = EnmasseMeterReadingInstances.MatchedAssetId AND ASN.IsActive = 1)
		) InvalidRecord

INSERT INTO EnmasseMeterReadingLogs
(
EnmasseMeterReadingInstanceId
,Error
,CreatedById
,CreatedTime
)
SELECT EnmasseMeterReadingInstances.Id
,@BeginReadingMustBePositive
,@CreatedById
,@CreatedTime
FROM EnmasseMeterReadingInstances
WHERE BeginReading<0 AND  IsFaulted = 0 AND
EnmasseMeterReadingInstances.InstanceId = @InstanceId
INSERT INTO EnmasseMeterReadingLogs
(
EnmasseMeterReadingInstanceId
,Error
,CreatedById
,CreatedTime
)
SELECT EnmasseMeterReadingInstances.Id
,@EndReadingValueMustBePositive
,@CreatedById
,@CreatedTime
FROM EnmasseMeterReadingInstances
WHERE EndReading<0 AND  IsFaulted = 0 AND
EnmasseMeterReadingInstances.InstanceId = @InstanceId
INSERT INTO EnmasseMeterReadingLogs
(
EnmasseMeterReadingInstanceId
,Error
,CreatedById
,CreatedTime
)
SELECT EnmasseMeterReadingInstances.Id
,@ServiceCreditsMustBePositive
,@CreatedById
,@CreatedTime
FROM EnmasseMeterReadingInstances
WHERE ServiceCredits<0 AND  IsFaulted = 0 AND
EnmasseMeterReadingInstances.InstanceId = @InstanceId
INSERT INTO EnmasseMeterReadingLogs
(
EnmasseMeterReadingInstanceId
,Error
,CreatedById
,CreatedTime
)
SELECT EnmasseMeterReadingInstances.Id
,CONCAT(@BeginReadingExceedingMaxReading , ': { ',#ContractInfo.MaximumReading ,' }')
,@CreatedById
,@CreatedTime
FROM EnmasseMeterReadingInstances
INNER JOIN #ContractInfo ON EnmasseMeterReadingInstances.Id = #ContractInfo.Id
WHERE #ContractInfo.MaximumReading <> 0 AND
EnmasseMeterReadingInstances.BeginReading > #ContractInfo.MaximumReading AND
IsFaulted = 0 AND
EnmasseMeterReadingInstances.InstanceId = @InstanceId
INSERT INTO EnmasseMeterReadingLogs
(
EnmasseMeterReadingInstanceId
,Error
,CreatedById
,CreatedTime
)
SELECT EnmasseMeterReadingInstances.Id
,CONCAT(@EndReadingExceedingMaxReading , ': { ', #ContractInfo.MaximumReading ,' }')
,@CreatedById
,@CreatedTime
FROM EnmasseMeterReadingInstances
INNER JOIN #ContractInfo ON EnmasseMeterReadingInstances.Id = #ContractInfo.Id
WHERE #ContractInfo.MaximumReading <> 0 AND
EnmasseMeterReadingInstances.EndReading > #ContractInfo.MaximumReading AND
IsFaulted = 0 AND
EnmasseMeterReadingInstances.InstanceId = @InstanceId
INSERT INTO EnmasseMeterReadingLogs
(
EnmasseMeterReadingInstanceId
,Error
,CreatedById
,CreatedTime
)
SELECT EnmasseMeterReadingInstances.Id
,@EndReadingLessThanBeginReadingCheck
,@CreatedById
,@CreatedTime
FROM EnmasseMeterReadingInstances
WHERE(EnmasseMeterReadingInstances.MeterResetType <> @Rollover AND
EnmasseMeterReadingInstances.BeginReading > EnmasseMeterReadingInstances.EndReading) AND
IsFaulted = 0 AND
EnmasseMeterReadingInstances.InstanceId = @InstanceId
INSERT INTO EnmasseMeterReadingLogs
(
EnmasseMeterReadingInstanceId
,Error
,CreatedById
,CreatedTime
)
SELECT EnmasseMeterReadingInstances.Id
,@RolloverReadingMaxReading
,@CreatedById
,@CreatedTime
FROM EnmasseMeterReadingInstances
INNER JOIN #ContractInfo ON EnmasseMeterReadingInstances.Id = #ContractInfo.Id
WHERE #ContractInfo.MaximumReading=0 AND EnmasseMeterReadingInstances.MeterResetType=@Rollover AND
IsFaulted = 0 AND
EnmasseMeterReadingInstances.InstanceId = @InstanceId
INSERT INTO EnmasseMeterReadingLogs
(
EnmasseMeterReadingInstanceId
,Error
,CreatedById
,CreatedTime
)
SELECT EnmasseMeterReadingInstances.Id
,@ResetTypeModification
,@CreatedById
,@CreatedTime
FROM EnmasseMeterReadingInstances
INNER JOIN #ContractInfo ON EnmasseMeterReadingInstances.Id = #ContractInfo.Id AND
EnmasseMeterReadingInstances.CPUAssetId = #ContractInfo.CPUAssetId
WHERE (#ContractInfo.EndPeriodDate IS NOT NULL AND
EnmasseMeterReadingInstances.MeterResetType <> @Replace AND
#ContractInfo.MeterResetType <> EnmasseMeterReadingInstances.MeterResetType) AND
IsFaulted = 0 AND
EnmasseMeterReadingInstances.InstanceId = @InstanceId
UPDATE  EnmasseMeterReadingInstances SET IsFaulted = 1
FROM
EnmasseMeterReadingInstances
INNER JOIN EnmasseMeterReadingLogs
ON EnmasseMeterReadingLogs.EnmasseMeterReadingInstanceId = EnmasseMeterReadingInstances.Id AND
EnmasseMeterReadingInstances.InstanceId = @InstanceId
--Should validate valid CPU schedule assets.
--Persisted Non Replace for correction
UPDATE EnmasseMeterReadingInstances
SET IsCorrection = 1
FROM
EnmasseMeterReadingInstances Uploads
INNER JOIN CPUAssetMeterReadings on Uploads.CPUAssetId = CPUAssetMeterReadings.CPUAssetId
AND Uploads.EndPeriodDate = CPUAssetMeterReadings.EndPeriodDate
AND CPUAssetMeterReadings.IsActive=1
WHERE Uploads.InstanceId = @InstanceId
AND (Uploads.MeterResetType <> @Replace AND Uploads.MeterResetType <> @Replace)
AND Uploads.IsFaulted = 0
SELECT EnmasseMeterReadingInstances.EndPeriodDate
,EnmasseMeterReadingInstances.CPUAssetId
,MIN(ROWID) MinRowId
INTO #InMemoryReadings
FROM EnmasseMeterReadingInstances
WHERE (EnmasseMeterReadingInstances.MeterResetType  <> @Replace)
AND IsCorrection = 0
AND EnmasseMeterReadingInstances.InstanceId = @InstanceId
AND EnmasseMeterReadingInstances.IsFaulted = 0
GROUP BY EnmasseMeterReadingInstances.EndPeriodDate
,EnmasseMeterReadingInstances.CPUAssetId
HAVING COUNT(*) > 1



--START : Verifing If Reset Type is modified.

CREATE TABLE #MeterReadingsWithFaultyResetType (Id BIGINT)

--Find out last peristent reading input for each incoming asset period
SELECT
               LastPersistentAssetMeterReadingForEachPeriod.CPUAssetId,
               LastPersistentAssetMeterReadingForEachPeriod.EndPeriodDate,
               LastPersistentAssetMeterReadingForEachPeriod.MeterResetType
INTO      
               #CorrectionReadingBaseInfo
FROM
               (
                              SELECT 
                                             ROW_NUMBER() 
                                                            OVER(PARTITION BY CPUAssetMeterReadings.CPUAssetId,CPUAssetMeterReadings.EndPeriodDate ORDER BY CPUAssetMeterReadings.Id DESC) 
                                             [LastPersistentMeterReading],
                                             CPUAssetMeterReadings.MeterResetType,
                                             CPUAssetMeterReadings.CPUAssetId,
                                             CPUAssetMeterReadings.EndPeriodDate
                              FROM 
                                             EnmasseMeterReadingInstances 
                                             INNER JOIN CPUAssetMeterReadings ON EnmasseMeterReadingInstances.CPUAssetId = CPUAssetMeterReadings.CPUAssetId 
                                                                                 AND EnmasseMeterReadingInstances.EndPeriodDate=CPUAssetMeterReadings.EndPeriodDate
                                                                                 AND CPUAssetMeterReadings.IsActive=1  
                                                                                 AND EnmasseMeterReadingInstances.IsFaulted=0
																				 AND CPUAssetMeterReadings.MeterResetType != @Replace
                              WHERE 
                                             EnmasseMeterReadingInstances.InstanceId = @InstanceId
                                             
               )
               LastPersistentAssetMeterReadingForEachPeriod
WHERE
               [LastPersistentMeterReading] = 1

--Find out first non persistent input for each incoming asset period
INSERT INTO 
               #CorrectionReadingBaseInfo
SELECT
               FirstReadingForEachNonPersistentAssetPeriod.CPUAssetId,
               FirstReadingForEachNonPersistentAssetPeriod.EndPeriodDate,
               FirstReadingForEachNonPersistentAssetPeriod.MeterResetType
FROM
               (
                              SELECT 
                                             ROW_NUMBER() 
                                                            OVER(PARTITION BY EnmasseMeterReadingInstances.CPUAssetId,EnmasseMeterReadingInstances.EndPeriodDate ORDER BY EnmasseMeterReadingInstances.Id)
                                             [FirstNonPersistentMeterReading],
                                             EnmasseMeterReadingInstances.CPUAssetId,
                                             EnmasseMeterReadingInstances.EndPeriodDate,
                                             EnmasseMeterReadingInstances.MeterResetType,
											 EnmasseMeterReadingInstances.IsFaulted
                              FROM 
                                             EnmasseMeterReadingInstances 
							  WHERE 
							  NOT EXISTS 
							  (
							   SELECT  #CorrectionReadingBaseInfo.CPUAssetId, #CorrectionReadingBaseInfo.EndPeriodDate 
							   FROM #CorrectionReadingBaseInfo WHERE EnmasseMeterReadingInstances.CPUAssetId = #CorrectionReadingBaseInfo.CPUAssetId
							   AND EnmasseMeterReadingInstances.EndPeriodDate = #CorrectionReadingBaseInfo.EndPeriodDate
							  )
							  AND IsFaulted=0
							  AND EnmasseMeterReadingInstances.MeterResetType != @Replace
							  AND EnmasseMeterReadingInstances.InstanceId= @InstanceId
                                             
               )
               FirstReadingForEachNonPersistentAssetPeriod
WHERE
               [FirstNonPersistentMeterReading] = 1

-- Reject all readings having meter reset types other than the reset type of Last peristent or first non persistent record
UPDATE 
               EnmasseMeterReadingInstances
SET  
               EnmasseMeterReadingInstances.IsFaulted=1
OUTPUT 
               inserted.Id INTO #MeterReadingsWithFaultyResetType
FROM 
               EnmasseMeterReadingInstances
               INNER JOIN #CorrectionReadingBaseInfo 
                              ON         EnmasseMeterReadingInstances.CPUAssetId = #CorrectionReadingBaseInfo.CPUAssetId 
                                             AND EnmasseMeterReadingInstances.EndPeriodDate=#CorrectionReadingBaseInfo.EndPeriodDate
WHERE 
               EnmasseMeterReadingInstances.MeterResetType != @Replace
               AND EnmasseMeterReadingInstances.MeterResetType != #CorrectionReadingBaseInfo.MeterResetType
               AND EnmasseMeterReadingInstances.IsFaulted=0
               AND EnmasseMeterReadingInstances.InstanceId = @InstanceId

INSERT INTO EnmasseMeterReadingLogs
(
               EnmasseMeterReadingInstanceId,
               Error,
               CreatedById,
               CreatedTime
)
SELECT 
               EnmasseMeterReadingInstances.Id,
               @ResetTypeModification,
               @CreatedById,
               @CreatedTime
FROM 
               EnmasseMeterReadingInstances
               INNER JOIN #MeterReadingsWithFaultyResetType ON EnmasseMeterReadingInstances.Id=#MeterReadingsWithFaultyResetType.Id
WHERE 
               EnmasseMeterReadingInstances.InstanceId = @InstanceId 

--END  : Verifing If Reset Type is modified.


--In Memory Correction
UPDATE EnmasseMeterReadingInstances
SET IsCorrection = 1
FROM EnmasseMeterReadingInstances
INNER JOIN #InMemoryReadings ON EnmasseMeterReadingInstances.CPUAssetId = #InMemoryReadings.CPUAssetId
AND EnmasseMeterReadingInstances.EndPeriodDate = #InMemoryReadings.EndPeriodDate
WHERE EnmasseMeterReadingInstances.ROWId <> #InMemoryReadings.MinRowId AND
EnmasseMeterReadingInstances.IsFaulted = 0 AND
EnmasseMeterReadingInstances.MeterResetType <> @Replace AND
EnmasseMeterReadingInstances.InstanceId = @InstanceId;
UPDATE EnmasseMeterReadingInstances
SET EnmasseMeterReadingInstances.CPUOverageAssessmentId = CPUAssetMeterReadings.CPUOverageAssessmentId
FROM  EnmasseMeterReadingInstances
INNER JOIN CPUAssetMeterReadings ON EnmasseMeterReadingInstances.CPUAssetId = CPUAssetMeterReadings.CPUAssetId AND
EnmasseMeterReadingInstances.EndPeriodDate = CPUAssetMeterReadings.EndPeriodDate
WHERE EnmasseMeterReadingInstances.MeterResetType = @Replace AND
EnmasseMeterReadingInstances.IsFaulted = 0 AND
EnmasseMeterReadingInstances.InstanceId = @InstanceId;
IF (OBJECT_ID('tempdb..#InMemoryReadings')) IS NOT NULL
DROP TABLE #InMemoryReadings
UPDATE EnmasseMeterReadingInstances
SET AssetBeginDate = CPUAssets.BeginDate
FROM EnmasseMeterReadingInstances
INNER JOIN CPUAssets ON EnmasseMeterReadingInstances.CPUAssetId = CPUAssets.Id
WHERE EnmasseMeterReadingInstances.IsFaulted = 0 AND
EnmasseMeterReadingInstances.InstanceId= @InstanceId
SELECT ROW_NUMBER() OVER (
PARTITION BY EnmasseMeterReadingInstances.CPUAssetId ORDER BY EnmasseMeterReadingInstances.ROWID
) FirstReading
,EnmasseMeterReadingInstances.CPUAssetId
,ISNULL(#ContractInfo.BeginReading, 0) AS MeterTypeBeginReading
,EnmasseMeterReadingInstances.ROWId
,AssetMetersActive
,AssetMeterTypesActive
INTO #CPUAssetInfo
FROM EnmasseMeterReadingInstances
INNER JOIN #ContractInfo
ON #ContractInfo.Id = EnmasseMeterReadingInstances.Id
WHERE EnmasseMeterReadingInstances.IsCorrection = 0 AND
EnmasseMeterReadingInstances.InstanceId = @InstanceId AND
EnmasseMeterReadingInstances.IsFaulted = 0
--CPUBaseStructures
--Max Reading for addition if there are meter readings already
SELECT #CPUAssetInfo.CPUAssetId
,MAX(CPUAssetMeterReadings.EndPeriodDate) MaxEndPeriodDate
INTO #MaxEndPeriodDates
FROM #CPUAssetInfo
INNER JOIN CPUAssetMeterReadings ON #CPUAssetInfo.CPUAssetId = CPUAssetMeterReadings.CPUAssetId
AND CPUAssetMeterReadings.IsActive = 1
GROUP BY #CPUAssetInfo.CPUAssetId
SELECT CPUAssetMeterReadings.CPUAssetId
,MIN(CPUAssetMeterReadings.EndPeriodDate) MinEndPeriodDate
INTO #MINEndPeriodDates
FROM EnmasseMeterReadingInstances
INNER JOIN CPUAssetMeterReadings ON EnmasseMeterReadingInstances.CPUAssetId = CPUAssetMeterReadings.CPUAssetId
AND CPUAssetMeterReadings.IsActive = 1
WHERE EnmasseMeterReadingInstances.InstanceId = @InstanceId AND
EnmasseMeterReadingInstances.IsCorrection=1
GROUP BY CPUAssetMeterReadings.CPUAssetId
SELECT #CPUAssetInfo.CPUAssetId
,MAX(CPUAssetMeterReadings.Id) MaxReadingId
INTO #MaxReadings
FROM #CPUAssetInfo
INNER JOIN CPUAssetMeterReadings ON #CPUAssetInfo.CPUAssetId = CPUAssetMeterReadings.CPUAssetId
AND CPUAssetMeterReadings.IsActive = 1
INNER JOIN #MaxEndPeriodDates ON CPUAssetMeterReadings.EndPeriodDate = #MaxEndPeriodDates.MaxEndPeriodDate
AND CPUAssetMeterReadings.CPUAssetId = #MaxEndPeriodDates.CPUAssetId
GROUP BY #CPUAssetInfo.CPUAssetId
--Corrections
-- Max reading is retrieved only for persisted records new add will have null
SELECT #CPUAssetInfo.ROWId
,CPUAssetMeterReadings.EndReading PreviousEndReading
,CPUAssetMeterReadings.EndPeriodDate PreviousEndPeriodDate
,CPUAssetMeterReadings.BeginPeriodDate PreviousBeginPeriodDate
,#MaxReadings.MaxReadingId
,CPUAssetMeterReadings.CPUAssetId
INTO #FirstReadings
FROM #CPUAssetInfo
LEFT JOIN #MaxReadings ON #CPUAssetInfo.CPUAssetId = #MaxReadings.CPUAssetId
LEFT JOIN CPUAssetMeterReadings ON CPUAssetMeterReadings.Id = #MaxReadings.MaxReadingId
WHERE FirstReading = 1
UPDATE UR
SET IsFirstReading = 1
,BeginReading = CASE
WHEN #FirstReadings.MaxReadingId IS NULL
THEN CASE
WHEN UR.BeginReading IS NOT NULL
THEN UR.BeginReading
ELSE CASE
WHEN #CPUAssetInfo.AssetMeterTypesActive=1 AND #CPUAssetInfo.AssetMetersActive=1
THEN #CPUAssetInfo.MeterTypeBeginReading
ELSE 0
END
END
ELSE #FirstReadings.PreviousEndReading
END
FROM EnmasseMeterReadingInstances UR
INNER JOIN #FirstReadings ON #FirstReadings.ROWId = UR.ROWId
INNER JOIN #CPUAssetInfo ON #FirstReadings.ROWId = #CPUAssetInfo.ROWId
WHERE UR.IsFaulted = 0 AND
UR.InstanceId = @InstanceId AND
UR.MeterResetType<>@Replace
UPDATE UR
SET BeginReading =  0
FROM EnmasseMeterReadingInstances UR
WHERE UR.IsFaulted = 0 AND
UR.InstanceId = @InstanceId AND
UR.MeterResetType=@Replace AND
UR.BeginReading IS NULL
INSERT INTO EnmasseMeterReadingLogs
(
EnmasseMeterReadingInstanceId
,Error
,CreatedById
,CreatedTime
)
SELECT EnmasseMeterReadingInstances.Id
,@EndPeriodDateForReplaceShouldBePreviousEndPeriodDate
,@CreatedById
,@CreatedTime
FROM #FirstReadings
INNER JOIN EnmasseMeterReadingInstances ON #FirstReadings.CPUAssetId = EnmasseMeterReadingInstances.CPUAssetId
AND IsFaulted = 0
AND EnmasseMeterReadingInstances.InstanceId = @InstanceId
AND EnmasseMeterReadingInstances.MeterResetType = @Replace
WHERE EnmasseMeterReadingInstances.EndPeriodDate < #FirstReadings.PreviousEndPeriodDate
UPDATE  EnmasseMeterReadingInstances SET IsFaulted = 1
FROM
EnmasseMeterReadingInstances
INNER JOIN EnmasseMeterReadingLogs
ON EnmasseMeterReadingLogs.EnmasseMeterReadingInstanceId = EnmasseMeterReadingInstances.Id AND
EnmasseMeterReadingInstances.InstanceId = @InstanceId
AND EnmasseMeterReadingInstances.IsFaulted=0
AND EnmasseMeterReadingInstances.MeterResetType = @Replace
UPDATE URCorrection
SET URCorrection.IsFirstReadingCorrected = 1
FROM EnmasseMeterReadingInstances UR
INNER JOIN EnmasseMeterReadingInstances URCorrection ON UR.EndPeriodDate = URCorrection.EndPeriodDate AND UR.Id<>URCorrection.Id
AND UR.CPUAssetId = URCorrection.CPUAssetId
WHERE UR.IsFaulted = 0 AND
UR.InstanceId = @InstanceId AND
URCorrection.InstanceId = @InstanceId AND
UR.IsFirstReading = 1 AND
URCorrection.IsCorrection = 1 AND
UR.MeterResetType<>@Replace AND
URCorrection.MeterResetType<>@Replace
UPDATE URCorrection
SET URCorrection.IsFirstReadingCorrected = 1
FROM EnmasseMeterReadingInstances URCorrection
INNER JOIN #MINEndPeriodDates ON URCorrection.EndPeriodDate =#MINEndPeriodDates.MinEndPeriodDate AND
URCorrection.CPUAssetId = #MINEndPeriodDates.CPUAssetId
WHERE URCorrection.IsFaulted = 0 AND
URCorrection.InstanceId = @InstanceId AND
URCorrection.IsCorrection = 1 AND
URCorrection.MeterResetType<>@Replace
--Begin date
--Non Replace -- Add of readings which has max reading
UPDATE EnmasseMeterReadingInstances
SET EnmasseMeterReadingInstances.BeginPeriodDate = DATEADD(dd, 1, #FirstReadings.PreviousEndPeriodDate)
FROM EnmasseMeterReadingInstances
INNER JOIN #CPUAssetInfo ON EnmasseMeterReadingInstances.CPUAssetId = #CPUAssetInfo.CPUAssetId
LEFT JOIN #FirstReadings ON EnmasseMeterReadingInstances.ROWId = #FirstReadings.ROWId
AND EnmasseMeterReadingInstances.ROWId = #FirstReadings.ROWId
WHERE #CPUAssetInfo.FirstReading = 1
AND #FirstReadings.MaxReadingId IS NOT NULL
AND EnmasseMeterReadingInstances.IsFaulted = 0 AND
EnmasseMeterReadingInstances.InstanceId = @InstanceId
AND EnmasseMeterReadingInstances.MeterResetType<>@Replace
--Begin date For Fresh readings For Non Aggregate
--Non Replace -- Add of readings which has max reading
UPDATE EnmasseMeterReadingInstances
SET EnmasseMeterReadingInstances.BeginPeriodDate = #ContractInfo.BeginDate
FROM EnmasseMeterReadingInstances
INNER JOIN #CPUAssetInfo ON EnmasseMeterReadingInstances.CPUAssetId = #CPUAssetInfo.CPUAssetId
INNER JOIN #ContractInfo ON EnmasseMeterReadingInstances.Id = #ContractInfo.Id
INNER JOIN #FirstReadings ON EnmasseMeterReadingInstances.ROWId = #FirstReadings.ROWId
AND EnmasseMeterReadingInstances.ROWId = #FirstReadings.ROWId
WHERE #CPUAssetInfo.FirstReading = 1 AND
#FirstReadings.MaxReadingId IS NULL AND
EnmasseMeterReadingInstances.IsFaulted = 0 AND
#ContractInfo.IsAggregate=0 AND
EnmasseMeterReadingInstances.InstanceId = @InstanceId
UPDATE EnmasseMeterReadingInstances
SET EnmasseMeterReadingInstances.BeginPeriodDate = CASE WHEN CPUAssetMeterReadings.EndPeriodDate=EnmasseMeterReadingInstances.EndPeriodDate THEN CPUAssetMeterReadings.BeginPeriodDate
ELSE  NULL END
FROM EnmasseMeterReadingInstances
INNER JOIN CPUAssetMeterReadings ON EnmasseMeterReadingInstances.CPUAssetId =CPUAssetMeterReadings.CPUAssetId AND
EnmasseMeterReadingInstances.IsFaulted = 0 AND
CPUAssetMeterReadings.EndPeriodDate=EnmasseMeterReadingInstances.EndPeriodDate
WHERE EnmasseMeterReadingInstances.InstanceId = @InstanceId
AND EnmasseMeterReadingInstances.MeterResetType=@Replace
UPDATE EnmasseMeterReadingInstances
SET EnmasseMeterReadingInstances.BeginPeriodDate = CASE WHEN EnmasseMeterReadingInstances.EndPeriodDate>#FirstReadings.PreviousEndPeriodDate THEN DATEADD(dd, 1, #FirstReadings.PreviousEndPeriodDate)
ELSE  NULL END
FROM EnmasseMeterReadingInstances
INNER JOIN #CPUAssetInfo ON EnmasseMeterReadingInstances.CPUAssetId = #CPUAssetInfo.CPUAssetId AND EnmasseMeterReadingInstances.IsFaulted = 0
INNER JOIN #ContractInfo ON EnmasseMeterReadingInstances.Id = #ContractInfo.Id
INNER JOIN #FirstReadings ON EnmasseMeterReadingInstances.ROWId = #FirstReadings.ROWId AND
EnmasseMeterReadingInstances.EndPeriodDate>#FirstReadings.PreviousEndPeriodDate
WHERE EnmasseMeterReadingInstances.InstanceId = @InstanceId
AND EnmasseMeterReadingInstances.MeterResetType=@Replace AND
EnmasseMeterReadingInstances.BeginPeriodDate IS NULL
--Replace -- Add of readings which has max reading
-- Update Begin Readings
--For Correction
UPDATE EnmasseMeterReadingInstances
SET BeginReading = CPUAssetMeterReadings.BeginReading,
BeginPeriodDate = CPUAssetMeterReadings.BeginPeriodDate,
CPUOverageAssessmentId = CPUAssetMeterReadings.CPUOverageAssessmentId
FROM EnmasseMeterReadingInstances
INNER JOIN CPUAssetMeterReadings ON EnmasseMeterReadingInstances.CPUAssetId = CPUAssetMeterReadings.CPUAssetId
AND EnmasseMeterReadingInstances.EndPeriodDate = CPUAssetMeterReadings.EndPeriodDate
WHERE EnmasseMeterReadingInstances.IsCorrection = 1
AND CPUAssetMeterReadings.IsActive = 1
AND EnmasseMeterReadingInstances.IsFaulted = 0
AND EnmasseMeterReadingInstances.InstanceId = @InstanceId
AND EnmasseMeterReadingInstances.IsFirstReadingCorrected = 0
SELECT COUNT(DISTINCT CPUScheduleId) CPUSchedulesToProcess FROM
EnmasseMeterReadingInstances
WHERE IsFaulted =0 AND
EnmasseMeterReadingInstances.InstanceId = @InstanceId
IF (OBJECT_ID('tempdb..#InMemoryReadings')) IS NOT NULL
DROP TABLE #InMemoryReadings
IF (OBJECT_ID('tempdb..#CPUAssetInfo')) IS NOT NULL
DROP TABLE #CPUAssetInfo
IF (OBJECT_ID('tempdb..#MaxReadings')) IS NOT NULL
DROP TABLE #MaxReadings
IF (OBJECT_ID('tempdb..#FirstReadings')) IS NOT NULL
DROP TABLE #FirstReadings
IF (OBJECT_ID('tempdb..#ContractInfo')) IS NOT NULL
DROP TABLE #ContractInfo
IF (OBJECT_ID('tempdb..#MaxEndPeriodDates')) IS NOT NULL
DROP TABLE #MaxEndPeriodDates
IF (OBJECT_ID('tempdb..#MINEndPeriodDates')) IS NOT NULL
DROP TABLE #MINEndPeriodDates
IF (OBJECT_ID('tempdb..#CorrectionReadingBaseInfo')) IS NOT NULL
DROP TABLE #CorrectionReadingBaseInfo
IF (OBJECT_ID('tempdb..#MeterReadingsWithFaultyResetType')) IS NOT NULL
DROP TABLE #MeterReadingsWithFaultyResetType

END

GO
