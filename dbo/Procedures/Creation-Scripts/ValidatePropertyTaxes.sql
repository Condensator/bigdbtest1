SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[ValidatePropertyTaxes]
(@UserId                  BIGINT, 
 @ModuleIterationStatusId BIGINT, 
 @CreatedTime             DATETIMEOFFSET, 
 @ProcessedRecords        BIGINT OUTPUT, 
 @FailedRecords           BIGINT OUTPUT
)
AS
    BEGIN
        CREATE TABLE #ErrorLogs
        (Id                  BIGINT NOT NULL IDENTITY PRIMARY KEY, 
         StagingRootEntityId BIGINT, 
         Result              NVARCHAR(10), 
         Message             NVARCHAR(MAX)
        );
        CREATE TABLE #FailedProcessingLogs
        ([Id]            BIGINT NOT NULL, 
         [PropertyTaxId] BIGINT NOT NULL
        );
        CREATE TABLE #CreatedProcessingLogs([Id] BIGINT NOT NULL);
        SET @ProcessedRecords =
        (
            SELECT ISNULL(COUNT(Id), 0)
            FROM stgPropertyTax
            WHERE IsMigrated = 0
        );
        INSERT INTO #ErrorLogs
        SELECT  PropertyTax.Id
             , 'Error'
             , CONCAT('Selected State must be valid for PropertyTax : ',PropertyTax.Id) AS Message
        FROM stgPropertyTax PropertyTax
             LEFT JOIN States s ON PropertyTax.StateShortName = s.ShortName
                                   AND s.IsActive = 1
        WHERE s.Id IS NULL
              AND PropertyTax.IsMigrated = 0
              AND PropertyTax.StateShortName IS NOT NULL;
        INSERT INTO #ErrorLogs
        SELECT PropertyTax.Id
             , 'Error'
             , CONCAT('Selected receivable code must be valid for PropertyTax : ',PropertyTax.Id) AS Message
        FROM stgPropertyTax PropertyTax
             LEFT JOIN ReceivableCodes ON ReceivableCodes.Name = PropertyTax.ReceivableCodeName
                                          AND ReceivableCodes.IsActive = 1
        WHERE PropertyTax.ReceivableCodeName IS NOT NULL AND ReceivableCodes.Id IS NULL 
              AND PropertyTax.IsMigrated = 0;
        INSERT INTO #ErrorLogs
        SELECT PropertyTax.Id
             , 'Error'
             , CONCAT('Selected receivable code for admin fee must be valid for PropertyTax : ',PropertyTax.Id) AS Message
        FROM stgPropertyTax PropertyTax
             LEFT JOIN ReceivableCodes ON ReceivableCodes.Name = PropertyTax.ReceivableCodeNameForAdminFee
                                          AND ReceivableCodes.IsActive = 1
        WHERE PropertyTax.ReceivableCodeNameForAdminFee IS NOT NULL AND ReceivableCodes.Id IS NULL
              AND PropertyTax.IsMigrated = 0;
        SET @FailedRecords =
        (
            SELECT ISNULL(COUNT(DISTINCT StagingRootEntityId), 0)
            FROM #ErrorLogs
        );
        MERGE stgProcessingLog AS ProcessingLog
        USING
        (
            SELECT Id
            FROM stgPropertyTax
            WHERE IsMigrated = 0
                  AND Id NOT IN
            (
                SELECT StagingRootEntityId
                FROM #ErrorLogs
            )
        ) AS ProcessedPropertyTaxes
        ON(ProcessingLog.StagingRootEntityId = ProcessedPropertyTaxes.Id
           AND ProcessingLog.ModuleIterationStatusId = @ModuleIterationStatusId)
            WHEN MATCHED
            THEN UPDATE SET 
                            UpdatedTime = @CreatedTime
            WHEN NOT MATCHED
            THEN
              INSERT(StagingRootEntityId
                   , CreatedById
                   , CreatedTime
                   , ModuleIterationStatusId)
              VALUES
        (ProcessedPropertyTaxes.Id
       , @UserId
       , @CreatedTime
       , @ModuleIterationStatusId
        )
        OUTPUT Inserted.Id
               INTO #CreatedProcessingLogs;
        INSERT INTO stgProcessingLogDetail
        (Message
       , Type
       , CreatedById
       , CreatedTime
       , ProcessingLogId
        )
        SELECT 'Successful'
             , 'Information'
             , @UserId
             , @CreatedTime
             , Id
        FROM #CreatedProcessingLogs;
        MERGE stgProcessingLog AS ProcessingLog
        USING
        (
            SELECT DISTINCT 
                   StagingRootEntityId
            FROM #ErrorLogs
        ) AS ErrorPropertyTaxes
        ON(ProcessingLog.StagingRootEntityId = ErrorPropertyTaxes.StagingRootEntityId
           AND ProcessingLog.ModuleIterationStatusId = @ModuleIterationStatusId)
            WHEN MATCHED
            THEN UPDATE SET 
                            UpdatedTime = @CreatedTime
                          , UpdatedById = @UserId
            WHEN NOT MATCHED
            THEN
              INSERT(StagingRootEntityId
                   , CreatedById
                   , CreatedTime
                   , ModuleIterationStatusId)
              VALUES
        (ErrorPropertyTaxes.StagingRootEntityId
       , @UserId
       , @CreatedTime
       , @ModuleIterationStatusId
        )
        OUTPUT Inserted.Id
             , ErrorPropertyTaxes.StagingRootEntityId
               INTO #FailedProcessingLogs;
        INSERT INTO stgProcessingLogDetail
        (Message
       , Type
       , CreatedById
       , CreatedTime
       , ProcessingLogId
        )
        SELECT #ErrorLogs.Message
             , 'Error'
             , @UserId
             , @CreatedTime
             , #FailedProcessingLogs.Id
        FROM #ErrorLogs
             JOIN #FailedProcessingLogs ON #ErrorLogs.StagingRootEntityId = #FailedProcessingLogs.PropertyTaxId;
        DROP TABLE #ErrorLogs;
        DROP TABLE #FailedProcessingLogs;
        DROP TABLE #CreatedProcessingLogs;
    END;

GO
