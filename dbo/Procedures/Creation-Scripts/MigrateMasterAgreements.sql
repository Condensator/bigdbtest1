SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[MigrateMasterAgreements]  
(   
 @UserId BIGINT,  
 @ModuleIterationStatusId BIGINT,  
 @CreatedTime DATETIME,  
 @ProcessedRecords BIGINT OUTPUT,  
 @FailedRecords BIGINT OUTPUT
)  
AS  
--declare @UserId BIGINT;
--declare @ModuleIterationStatusId BIGINT;
--declare @CreatedTime DATETIME;  
--declare @ProcessedRecords BIGINT;  
--declare @FailedRecords BIGINT;
--SET @UserId = 1;
--SET @CreatedTime = SYSDATETIMEOFFSET();	
--SELECT @ModuleIterationStatusId=MAX(ModuleIterationStatusId) from stgProcessingLog;
BEGIN
SET NOCOUNT ON;
SET XACT_ABORT ON;
SET @FailedRecords = 0  
SET @ProcessedRecords = 0  
DECLARE @TakeCount INT = 500  
DECLARE @SkipCount INT = 0  
DECLARE @MaxMasterAgreementId INT = 0  
DECLARE @BatchCount INT = 0
DECLARE @TotalRecordsCount INT = (SELECT COUNT(Id) FROM stgMasterAgreement MasterAgreement WHERE IsMigrated = 0)  
  CREATE TABLE #ErrorLogs  
  (  
   Id BIGINT NOT NULL IDENTITY PRIMARY KEY,  
   StagingRootEntityId BIGINT,  
   Result NVARCHAR(10),  
   Message NVARCHAR(MAX)  
  )  
  CREATE TABLE #FailedProcessingLogs  
  (  
   MergeAction NVARCHAR(20),  
   InsertedId BIGINT,  
   ErrorId BIGINT  
  ) 
WHILE @SkipCount <= @TotalRecordsCount  
  BEGIN 
  BEGIN TRY
  BEGIN TRANSACTION
  CREATE TABLE #CreatedMasterAgreementIds  
  (  
   MergeAction NVARCHAR(20),  
   InsertedId BIGINT,  
   MasterAgreementId BIGINT,  
  )  
  CREATE TABLE #CreatedProcessingLogs  
  (  
   MergeAction NVARCHAR(20),  
   InsertedId BIGINT  
  )  
  SELECT   
   TOP(@TakeCount) * INTO #MasterAgreementSubset   
  FROM   
   stgMasterAgreement MasterAgreement  
  WHERE  
   MasterAgreement.Id > @MaxMasterAgreementId AND MasterAgreement.IsMigrated = 0   
  ORDER BY   
   MasterAgreement.Id  
  SELECT   
     MasterAgreement.Id [MasterAgreementId]  
	,MasterAgreement.Number
	,MasterAgreement.AgreementAlias
	,MasterAgreement.AgreementDate
	,MasterAgreement.ReceivedDate
	,'Active' AS Status
	,MasterAgreement.ActivationDate
	,MasterAgreement.LineOfBusinessName
	,MasterAgreement.LegalEntityNumber
	,MasterAgreement.CustomerPartyNumber
	,MasterAgreement.AgreementTypeName
	,MasterAgreement.IsMigrated
	,LineofBusinesses.Id LineofBusinessId
	,LegalEntities.Id LegalEntityid
	,Customers.Id CustomerId
	,AgreementTypes.Id AgreementTypeId
     INTO #MasterAgreementMappedWithTarget  
  FROM   
	#MasterAgreementSubset MasterAgreement
	LEFT JOIN LineofBusinesses   
		ON MasterAgreement.LineOfBusinessName = LineofBusinesses.Name  
		AND LineofBusinesses.IsActive=1
	LEFT JOIN LegalEntities
		ON MasterAgreement.LegalEntityNumber = LegalEntities.LegalEntityNumber
	LEFT JOIN Parties
		ON MasterAgreement.CustomerPartyNumber = Parties.PartyNumber
	LEFT JOIN Customers
		ON Parties.Id = Customers.Id
	LEFT JOIN AgreementTypeConfigs AS atc  ON REPLACE(LTRIM(RTRIM( MasterAgreement.AgreementTypeName)), ' ', '') = REPLACE(LTRIM(RTRIM( atc.Name)), ' ', '')
	LEFT JOIN AgreementTypes
		ON AgreementTypes.AgreementTypeConfigId = atc.Id
		AND AgreementTypes.IsActive = 1
  WHERE  
   MasterAgreement.Id > @MaxMasterAgreementId    
  ORDER BY   
   MasterAgreement.Id  
  SELECT @MaxMasterAgreementId = MAX(MasterAgreementId) FROM #MasterAgreementMappedWithTarget;
  SELECT @BatchCount = ISNULL(COUNT(MasterAgreementId),0) FROM #MasterAgreementMappedWithTarget;
  INSERT INTO #ErrorLogs  
  SELECT  
     MasterAgreementId  
    ,'Error'  
    ,('Line of Business is invalid for Master Agreement :'+ISNULL(MasterAgreementMappedWithTarget.Number,'')) AS Message  
  FROM   
   #MasterAgreementMappedWithTarget MasterAgreementMappedWithTarget
   WHERE   
   LineofBusinessId IS NULL AND LineOfBusinessName IS NOT NULL
  INSERT INTO #ErrorLogs  
  SELECT  
     MasterAgreementId  
    ,'Error'  
    ,('Legal Entity is invalid for Master Agreement :'+ISNULL(MasterAgreementMappedWithTarget.Number,'')) AS Message  
  FROM   
   #MasterAgreementMappedWithTarget   MasterAgreementMappedWithTarget
   WHERE   
   LegalEntityid IS NULL AND LegalEntityNumber IS NOT NULL
   INSERT INTO #ErrorLogs  
  SELECT  
     MasterAgreementId  
    ,'Error' 
    ,('Customer Party Number is invalid for Master Agreement :'+ISNULL(MasterAgreementMappedWithTarget.Number,'')) AS Message  
  FROM   
   #MasterAgreementMappedWithTarget   MasterAgreementMappedWithTarget
   WHERE   
   CustomerId IS NULL AND CustomerPartyNumber IS NOT NULL
   INSERT INTO #ErrorLogs  
  SELECT  
     MasterAgreementId  
    ,'Error'  
    ,('Agreement Type Name is invalid for Master Agreement :'+ISNULL(MasterAgreementMappedWithTarget.Number,'')) AS Message  
  FROM   
   #MasterAgreementMappedWithTarget   MasterAgreementMappedWithTarget
   WHERE   
   AgreementTypeId IS NULL 
    INSERT INTO #ErrorLogs  
    SELECT  
     DISTINCT MasterAgreementId  
    ,'Error'  
    ,('Line of Business and Legal entity combination is invalid for Master Agreement :'+ISNULL(MasterAgreementMappedWithTarget.Number,'')) AS Message  
  FROM   
   #MasterAgreementMappedWithTarget   MasterAgreementMappedWithTarget
   JOIN LegalEntities LE ON MasterAgreementMappedWithTarget.LegalEntityNumber = LE.LegalEntityNumber
   JOIN GLOrgStructureConfigs GSC ON LE.Id = GSC.LegalEntityId AND MasterAgreementMappedWithTarget.LineofBusinessId = GSC.LineofbusinessId
   AND GSC.ISActive = 1
    Group by LE.Id,MasterAgreementMappedWithTarget.LineofBusinessId,MasterAgreementMappedWithTarget.MasterAgreementId  ,MasterAgreementMappedWithTarget.Number
   Having Count(*) = 0
    INSERT INTO #ErrorLogs  
   SELECT Distinct
      MasterAgreementId  
	 ,'Error'
	 ,('The entered value for the field Agreement #:'+ISNULL(MasterAgreementMappedWithTarget.Number,'') +' already exists in Master Agreement. Please enter a unique value.') AS Message
   FROM 
   MasterAgreements
   JOIN #MasterAgreementMappedWithTarget MasterAgreementMappedWithTarget 
   ON MasterAgreements.Number = MasterAgreementMappedWithTarget.Number
  MERGE MasterAgreements AS MasterAgreement  
  USING (SELECT  
    #MasterAgreementMappedWithTarget.* , #ErrorLogs.StagingRootEntityId
      FROM  
    #MasterAgreementMappedWithTarget  
      LEFT JOIN #ErrorLogs  
       ON #MasterAgreementMappedWithTarget.MasterAgreementId = #ErrorLogs.StagingRootEntityId
	) AS MasterAgreementToMigrate 
  ON (MasterAgreement.Number = MasterAgreementToMigrate.[Number] AND MasterAgreement.CustomerId = MasterAgreementToMigrate.CustomerId)  
  WHEN MATCHED AND MasterAgreementToMigrate.StagingRootEntityId IS NULL THEN  
   UPDATE SET MasterAgreement.Number = MasterAgreementToMigrate.Number  
  WHEN NOT MATCHED AND MasterAgreementToMigrate.StagingRootEntityId IS NULL  
  THEN  
   INSERT  
           ( Number
			,AgreementAlias
			,AgreementDate
			,ReceivedDate
			,Status
			,ActivationDate
			,CreatedById
			,CreatedTime
			,LineofBusinessId
			,LegalEntityId
			,CustomerId
			,AgreementTypeId
		   )  
     VALUES  
           ( 
		     MasterAgreementToMigrate.Number
			,MasterAgreementToMigrate.AgreementAlias
			,MasterAgreementToMigrate.AgreementDate
			,MasterAgreementToMigrate.ReceivedDate
			,MasterAgreementToMigrate.Status
			,MasterAgreementToMigrate.ActivationDate
			,@UserId  
			,@CreatedTime  
			,MasterAgreementToMigrate.LineofBusinessId
			,MasterAgreementToMigrate.LegalEntityId
			,MasterAgreementToMigrate.CustomerId
			,MasterAgreementToMigrate.AgreementTypeId
			) 
  OUTPUT $action, Inserted.Id, MasterAgreementToMigrate.MasterAgreementId INTO #CreatedMasterAgreementIds;  
  UPDATE stgMasterAgreement SET IsMigrated = 1 WHERE Id IN (SELECT MasterAgreementId FROM #CreatedMasterAgreementIds)  
  MERGE stgProcessingLog AS ProcessingLog  
  USING (SELECT  
    MasterAgreementId  
      FROM  
    #CreatedMasterAgreementIds
     ) AS ProcessedMasterAgreements  
  ON (ProcessingLog.StagingRootEntityId = ProcessedMasterAgreements.MasterAgreementId AND ProcessingLog.ModuleIterationStatusId = @ModuleIterationStatusId)  
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
    ProcessedMasterAgreements.MasterAgreementId  
      ,@UserId  
      ,@CreatedTime  
      ,@ModuleIterationStatusId  
   )  
  OUTPUT $action, Inserted.Id INTO #CreatedProcessingLogs;  
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
      'Successful'  
     ,'Information'
     ,@UserId  
     ,@CreatedTime  
     ,InsertedId  
  FROM  
   #CreatedProcessingLogs
 SET @SkipCount = @SkipCount + @TakeCount; 
  MERGE stgProcessingLog AS ProcessingLog  
  USING (SELECT  
     DISTINCT StagingRootEntityId  
      FROM  
    #ErrorLogs   
     ) AS ErrorMasterAgreements 
  ON (ProcessingLog.StagingRootEntityId = ErrorMasterAgreements.StagingRootEntityId AND ProcessingLog.ModuleIterationStatusId = @ModuleIterationStatusId)  
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
    ErrorMasterAgreements.StagingRootEntityId  
      ,@UserId  
      ,@CreatedTime  
      ,@ModuleIterationStatusId  
   )  
  OUTPUT $action, Inserted.Id,ErrorMasterAgreements.StagingRootEntityId INTO #FailedProcessingLogs;   
  DECLARE @TotalRecordsFailed INT = (SELECT  COUNT( DISTINCT InsertedId) FROM #FailedProcessingLogs)  
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
     ,#ErrorLogs.Result  
     ,@UserId  
     ,@CreatedTime  
     ,#FailedProcessingLogs.InsertedId  
  FROM  
   #ErrorLogs  
  INNER JOIN #FailedProcessingLogs  
    ON #ErrorLogs.StagingRootEntityId = #FailedProcessingLogs.ErrorId  
 SET @FailedRecords = @FailedRecords+(SELECT COUNT(DISTINCT StagingRootEntityId) FROM #ErrorLogs)
 DELETE #FailedProcessingLogs
 DELETE #ErrorLogs
 DROP TABLE #CreatedMasterAgreementIds  
 DROP TABLE #MasterAgreementSubset  
 DROP TABLE #MasterAgreementMappedWithTarget  
 DROP TABLE #CreatedProcessingLogs  
COMMIT TRANSACTION
END TRY
BEGIN CATCH
	SET @SkipCount = @SkipCount  + @TakeCount;
	DECLARE @ErrorMessage Nvarchar(max);
	DECLARE @ErrorLine Nvarchar(max);
	DECLARE @ErrorSeverity INT;
	DECLARE @ErrorState INT;
	DECLARE @ErrorLogs ErrorMessageList;
	DECLARE @ModuleName Nvarchar(max) = 'MigrateMasterAgreements'
	Insert into @ErrorLogs(StagingRootEntityId, ModuleIterationStatusId, Message,Type) VALUES (0,@ModuleIterationStatusId,ERROR_MESSAGE(),'Error')
	SELECT  @ErrorSeverity = ERROR_SEVERITY(), @ErrorState = ERROR_STATE(),@ErrorLine=ERROR_LINE(),@ErrorMessage=ERROR_MESSAGE()
	IF (XACT_STATE()) = -1  
	BEGIN  
		ROLLBACK TRANSACTION;
		EXEC [dbo].[ExceptionLog] @ErrorLogs,@ErrorLine,@UserId,@CreatedTime,@ModuleName
		SET @FailedRecords = @FailedRecords+@BatchCount;
	END;  
	IF (XACT_STATE()) = 1  
	BEGIN
		COMMIT TRANSACTION;
		RAISERROR (@ErrorMessage,@ErrorSeverity, @ErrorState);     
	END;  
END CATCH
 END   
  SET @ProcessedRecords = @ProcessedRecords + @TotalRecordsCount  
 DROP TABLE #FailedProcessingLogs
 DROP TABLE #ErrorLogs
 SET NOCOUNT OFF;
 SET XACT_ABORT OFF;
 END

GO
