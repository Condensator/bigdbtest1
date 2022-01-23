SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[MigrateCustomerThirdPartyRelationships]
(
@UserId BIGINT ,
@ModuleIterationStatusId BIGINT,
@CreatedTime DATETIMEOFFSET,
@ProcessedRecords BIGINT OUTPUT,
@FailedRecords BIGINT OUTPUT
)
AS
--DECLARE @UserId BIGINT;
--DECLARE @FailedRecords BIGINT;
--DECLARE @ProcessedRecords BIGINT;
--DECLARE @CreatedTime DATETIMEOFFSET;
--DECLARE @ModuleIterationStatusId BIGINT;
--SET @UserId = 1;
--SET @CreatedTime = SYSDATETIMEOFFSET();
--SELECT @ModuleIterationStatusId=MAX(ModuleIterationStatusId) from stgProcessingLog;
SET @FailedRecords = 0;
SET @ProcessedRecords = 0;
DECLARE @Module VARCHAR(50) = NULL
SET @Module = (SELECT StgModule.Name FROM StgModule INNER JOIN StgModuleIterationStatus ON StgModule.Id = StgModuleIterationStatus.ModuleId WHERE StgModuleIterationStatus.Id = @ModuleIterationStatusId)
EXEC ResetStagingTempFields @Module , NULL
CREATE TABLE #ErrorLogs
(
Id BIGINT NOT NULL IDENTITY PRIMARY KEY,
StagingRootEntityId BIGINT,
Result NVARCHAR(10),
Message NVARCHAR(MAX)
);
CREATE TABLE #FailedProcessingLogs
(
[Id] BIGINT NOT NULL,
[CustomerId] BIGINT NOT NULL
);
BEGIN
BEGIN TRY
BEGIN TRANSACTION
SET NOCOUNT ON
SET XACT_ABORT ON
CREATE TABLE #InsertedCustomerThirdParty
(
CustomerThirdPartyId BIGINT
);
CREATE TABLE #CreatedProcessingLogs
(
Id BIGINT
);

--create CustomerThirdPartyRelations
SELECT CTPR.Id,P.Id 'PartyId',C.CustomerNumber INTO #ProcessableCTPR
FROM stgCustomerThirdPartyRelationship CTPR
INNER JOIN stgCustomer C ON CTPR.CustomerId = C.Id
INNER JOIN Parties P ON C.CustomerNumber=P.PartyNumber
WHERE CTPR.IsMigrated=0;
Select @ProcessedRecords = ISNULL(COUNT(Id), 0) FROM stgCustomerThirdPartyRelationship
WHERE IsMigrated=0;
INSERT INTO #ErrorLogs
SELECT
CTPR.Id
,'Error'
,('Invalid Customer {'+ISNULL(CTPR.ThirdPartyCustomerNumber,'NULL')+'} configured for CustomerThirdPartyRelationship Id {'+CONVERT(NVARCHAR(MAX),CTPR.Id)+'} with CustomerId {'+CONVERT(NVARCHAR(MAX),CTPR.CustomerId)+'}')
FROM stgCustomerThirdPartyRelationship CTPR
INNER JOIN stgCustomer C ON CTPR.CustomerId = C.Id
LEFT JOIN Parties P ON C.CustomerNumber=P.PartyNumber
WHERE P.Id Is NULL AND CTPR.IsMigrated=0
UPDATE stgCustomerThirdPartyRelationship Set R_ThirdPartyCustomerId = TP.Id
FROM stgCustomerThirdPartyRelationship CTPR
INNER JOIN #ProcessableCTPR PTR ON PTR.Id = CTPR.Id
INNER JOIN Parties TP ON TP.PartyNumber = CTPR.ThirdPartyCustomerNumber
INNER JOIN Customers C ON TP.Id = C.Id
WHERE CTPR.ThirdPartyCustomerNumber Is NOT NULL
INSERT INTO #ErrorLogs
SELECT
CTPR.Id
,'Error'
,('Invalid ThirdParty {'+ISNULL(CTPR.ThirdPartyCustomerNumber,'NULL')+'} configured for CustomerThirdPartyRelationship Id {'+CONVERT(NVARCHAR(MAX),CTPR.Id)+'} with CustomerId {'+CONVERT(NVARCHAR(MAX),CTPR.CustomerId)+'}')
FROM stgCustomerThirdPartyRelationship CTPR
INNER JOIN #ProcessableCTPR TPR ON CTPR.Id = TPR.Id
WHERE CTPR.R_ThirdPartyCustomerId Is NULL
------------------------------------------------------------------------
UPDATE stgCustomerThirdPartyRelationship Set R_ThirdPartyAddressId = PA.Id
FROM stgCustomerThirdPartyRelationship CTPR
INNER JOIN #ProcessableCTPR PTR ON PTR.Id = CTPR.Id
INNER JOIN PartyAddresses PA ON PA.UniqueIdentifier = CTPR.AddressUniqueIdentifier
WHERE CTPR.ThirdPartyCustomerNumber IS NOT NULL AND CTPR.AddressUniqueIdentifier IS NOT NULL
INSERT INTO #ErrorLogs
SELECT
CTPR.Id
,'Error'
,('Invalid ThirdParty Address UniqueIdentifer {'+ISNULL(CTPR.AddressUniqueIdentifier,'NULL')+'} for CustomerThirdPartyRelationship Id {'+CONVERT(NVARCHAR(MAX),CTPR.Id)+'} with CustomerId {'+CONVERT(NVARCHAR(MAX),CTPR.CustomerId)+'}')
FROM stgCustomerThirdPartyRelationship CTPR
INNER JOIN #ProcessableCTPR CTR ON CTPR.Id = CTR.Id
WHERE CTPR.R_ThirdPartyAddressId Is NULL AND CTPR.AddressUniqueIdentifier IS NOT NULL
--------------------------------------------------------------------------
UPDATE stgCustomerThirdPartyRelationship Set R_VendorId = P.Id
FROM stgCustomerThirdPartyRelationship CTPR
INNER JOIN #ProcessableCTPR PTR ON PTR.Id = CTPR.Id
INNER JOIN Parties P ON P.PartyNumber = CTPR.VendorNumber
INNER JOIN Vendors V ON P.Id = V.Id
WHERE CTPR.VendorNumber IS NOT NULL
AND V.Status = 'Active'
AND V.Type != 'ShippingCompany'
AND V.Type != 'RefurbCenter'
AND V.Type != 'Warehouse'
INSERT INTO #ErrorLogs
SELECT
CTPR.Id
,'Error'
,('Invalid Vendor Number {'+ISNULL(CTPR.VendorNumber,'NULL')+'} for CustomerThirdPartyRelationship Id {'+CONVERT(NVARCHAR(MAX),CTPR.Id)+'} with CustomerId {'+CONVERT(NVARCHAR(MAX),CTPR.CustomerId)+'}')
FROM stgCustomerThirdPartyRelationship CTPR
INNER JOIN #ProcessableCTPR CTR ON CTPR.Id = CTR.Id
WHERE CTPR.R_VendorId Is NULL AND CTPR.VendorNumber IS NOT NULL
--------------------------------------------------------------------------
INSERT INTO #ErrorLogs
SELECT
CTR.Id
,'Error'
,('Customer cannot be a Third Party to himself. Check for the following third party assignments : '+ CTPR.ThirdPartyCustomerNumber+' for CustomerId {'+CONVERT(NVARCHAR(MAX),CTPR.CustomerId)+'}') AS Message
FROM
stgCustomerThirdPartyRelationship CTPR
INNER JOIN #ProcessableCTPR CTR ON CTPR.Id = CTR.Id
WHERE
(CTPR.ThirdPartyCustomerNumber = CTR.CustomerNumber)
INSERT INTO #ErrorLogs
SELECT
CTR.Id
,'Error'
,('Third Party chosen for Relationship Type Corporate Guarantor must be a Commercial Customer. Check for the following third party assignments : '+ CTPR.ThirdPartyCustomerNumber+' for CustomerId {'+CONVERT(NVARCHAR(MAX),CTPR.CustomerId)+'}') AS Message
FROM
stgCustomerThirdPartyRelationship CTPR
INNER JOIN #ProcessableCTPR CTR ON CTPR.Id = CTR.Id
INNER JOIN Parties TP ON TP.Id = CTPR.R_ThirdPartyCustomerId
WHERE
CTPR.RelationshipType = 'CorporateGuarantor'
AND TP.IsCorporate = 0
----------------------------------------------------------------------------------------------------------------

MERGE stgProcessingLog AS ProcessingLog
USING
(
SELECT DISTINCT StagingRootEntityId FROM #ErrorLogs WITH (NOLOCK)
)AS ErrorCTPR
ON(ProcessingLog.StagingRootEntityId = ErrorCTPR.StagingRootEntityId AND ProcessingLog.ModuleIterationStatusId = @ModuleIterationStatusId)
WHEN MATCHED THEN
UPDATE SET UpdatedTime = @CreatedTime
WHEN NOT MATCHED THEN
INSERT
(
StagingRootEntityId
,CreatedById
,CreatedTime
,ModuleIterationStatusId
)
VALUES
(
ErrorCTPR.StagingRootEntityId
,@UserId
,@CreatedTime
,@ModuleIterationStatusId
)
OUTPUT Inserted.Id,ErrorCTPR.StagingRootEntityId INTO #FailedProcessingLogs;
INSERT INTO
stgProcessingLogDetail
(
Message
,Type
,CreatedById
,CreatedTime
,ProcessingLogId
)
SELECT
#ErrorLogs.Message
,'Error'
,@UserId
,@CreatedTime
,#FailedProcessingLogs.Id
FROM
#ErrorLogs
INNER JOIN #FailedProcessingLogs
ON #ErrorLogs.StagingRootEntityId = #FailedProcessingLogs.CustomerId
print 'Validations Logged'
----------------------------------------------------------------------------------------------------------------
MERGE INTO [dbo].[CustomerThirdPartyRelationships] T
using
(
select
CTPR.[RelationshipType]
,CTPR.[Description]
,CTPR.[ActivationDate]
,CTPR.[CreatedById]
,CTPR.[CreatedTime]
,CTPR.[R_ThirdPartyCustomerId]
,CTR.[PartyId]
,CTPR.[LimitByDurationInMonths]
,CTPR.[LimitByPercentage]
,CTPR.[LimitByAmount_Amount]
,CTPR.[LimitByAmount_Currency]
,ISNULL(CTPR.[Scope],'_') as Scope
,ISNULL(CTPR.[Coverage],'_') as Coverage
,CTPR.[R_ThirdPartyAddressId]
,CTPR.Id
,CTPR.[R_VendorId]
FROM
stgCustomerThirdPartyRelationship CTPR
INNER JOIN #ProcessableCTPR CTR ON CTPR.Id = CTR.Id
WHERE (CTPR.Id not in (Select StagingRootEntityId FROM #ErrorLogs)))
as Source
on 1 = 0
when not matched then
insert
(
[RelationshipType]
,[Description]
,[IsActive]
,[ActivationDate]
,[IsNewRelation]
,[IsNewAddress]
,[CreatedById]
,[CreatedTime]
,[ThirdPartyId]
,[ThirdPartyContactId]
,[CustomerId]
,[IsFromAssumption]
,[IsAssumptionApproved]
,[LimitByDurationInMonths]
,[LimitByPercentage]
,[LimitByAmount_Amount]
,[LimitByAmount_Currency]
,[Scope]
,[Coverage]
,[PersonalGuarantorCustomerOrContact]
,[IsNewContact]
,[ThirdPartyAddressId]
,[VendorId]
)
Values
(
Source.[RelationshipType]
,Source.[Description]
,1
,Source.[ActivationDate]
,0
,0
,1
,@CreatedTime
,Source.R_ThirdPartyCustomerId
,NULL
,Source.PartyId
,0
,0
,Source.LimitByDurationInMonths
,Source.LimitByPercentage
,Source.LimitByAmount_Amount
,Source.LimitByAmount_Currency
,Source.Scope
,Source.Coverage
,'Customer'
,0
,Source.R_ThirdPartyAddressId
,Source.R_VendorId
)
OUTPUT Source.Id INTO #InsertedCustomerThirdParty;
UPDATE stgCustomerThirdPartyRelationship
SET IsMigrated=1 where Id in (Select CustomerThirdPartyId from #InsertedCustomerThirdParty)
----------------------------------------------------------------------------------------------------------------------------------
MERGE stgProcessingLog AS ProcessingLog
USING
(
SELECT DISTINCT CustomerThirdPartyId FROM #InsertedCustomerThirdParty
)
AS ProcessCTPR
ON(ProcessingLog.StagingRootEntityId = ProcessCTPR.CustomerThirdPartyId AND ProcessingLog.ModuleIterationStatusId = @ModuleIterationStatusId)
WHEN MATCHED THEN
UPDATE SET UpdatedTime = sysdatetimeoffset(),UpdatedById = @UserId
WHEN NOT MATCHED THEN
INSERT
(
StagingRootEntityId
,CreatedById
,CreatedTime
,ModuleIterationStatusId
)
VALUES
(
ProcessCTPR.CustomerThirdPartyId
,@UserId
,@CreatedTime
,@ModuleIterationStatusId
)
OUTPUT Inserted.Id INTO #CreatedProcessingLogs;
INSERT INTO stgProcessingLogDetail
(
Message
,Type
,CreatedById
,CreatedTime
,ProcessingLogId
)
SELECT
'Successful'
,'Information'
,@UserId
,@CreatedTime
,Id
FROM #CreatedProcessingLogs
DROP TABLE #InsertedCustomerThirdParty
DROP TABLE #CreatedProcessingLogs
DROP TABLE #ProcessableCTPR
COMMIT TRANSACTION
END TRY
BEGIN CATCH
DECLARE @ErrorMessage Nvarchar(max);
DECLARE @ErrorLine Nvarchar(max);
DECLARE @ErrorSeverity INT;
DECLARE @ErrorState INT;
DECLARE @ErrorLogs ErrorMessageList;
DECLARE @ModuleName Nvarchar(max) = 'MigrateCustomerThirdPartyRelationship'
Insert into @ErrorLogs(StagingRootEntityId, ModuleIterationStatusId, Message,Type) VALUES (0,@ModuleIterationStatusId,ERROR_MESSAGE(),'Error')
SELECT  @ErrorSeverity = ERROR_SEVERITY(), @ErrorState = ERROR_STATE(),@ErrorLine=ERROR_LINE(),@ErrorMessage=ERROR_MESSAGE()
IF (XACT_STATE()) = -1
BEGIN
ROLLBACK TRANSACTION;
EXEC [dbo].[ExceptionLog] @ErrorLogs,@ErrorLine,@UserId,@CreatedTime,@ModuleName
set @FailedRecords = @FailedRecords+@ProcessedRecords;
END;
IF (XACT_STATE()) = 1
BEGIN
COMMIT TRANSACTION;
RAISERROR (@ErrorMessage,@ErrorSeverity, @ErrorState);
END;
END CATCH
IF(@FailedRecords = 0)
SET @FailedRecords =ISNULL((SELECT COUNT(DISTINCT StagingRootEntityId) FROM #ErrorLogs),0);
DROP TABLE #ErrorLogs
DROP TABLE #FailedProcessingLogs
SET NOCOUNT OFF
SET XACT_ABORT OFF
END

GO
