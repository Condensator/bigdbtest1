SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[ValidateSundries]
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
        (Id       BIGINT NOT NULL, 
         SundryId BIGINT NOT NULL
        );
        CREATE TABLE #CreatedProcessingLogs([Id] BIGINT NOT NULL);
        SET @ProcessedRecords =
        (
            SELECT ISNULL(COUNT(Id), 0)
            FROM dbo.stgSundry
            WHERE IsMigrated = 0
        );
        INSERT INTO #ErrorLogs
        SELECT DISTINCT 
               sd.Id
             , 'Error'
             , 'Invalid InstrumentTypeCode : ' + ISNULL(sd.InstrumentTypeCode, ' ') + ' for Sundry {Id : ' + CONVERT(NVARCHAR(10), sd.Id) + '} with EntityType {' + sd.EntityType + '}'
        FROM stgSundry sd
             LEFT JOIN dbo.InstrumentTypes it ON sd.InstrumentTypeCode = it.Code
                                                 AND it.IsActive = 1
        WHERE it.Id IS NULL
              AND sd.IsMigrated = 0
              AND sd.InstrumentTypeCode IS NOT NULL;
        INSERT INTO #ErrorLogs
        SELECT DISTINCT 
               sd.Id
             , 'Error'
             , 'Atleast one asset must be present for the asset based sundry { Id : ' + CONVERT(NVARCHAR(10), sd.Id) + '}'
        FROM stgSundry sd
        WHERE sd.Id NOT IN (SELECT SundryId FROM stgSundryDetail)
              AND sd.IsMigrated = 0
              AND sd.IsAssetBased = 1;
        INSERT INTO #ErrorLogs
        SELECT DISTINCT 
               sd.Id
             , 'Error'
             , 'Asset must not be present for the sundry as it is not set as IsAssetBased for Sundry {Id : ' + CONVERT(NVARCHAR(10), sd.Id) + '} with EntityType {' + sd.EntityType + '}'
        FROM stgSundry sd
        WHERE sd.Id IN (SELECT SundryId FROM stgSundryDetail)
              AND sd.IsMigrated = 0
              AND sd.IsAssetBased = 0;
        INSERT INTO #ErrorLogs
        SELECT DISTINCT 
               sd.Id
             , 'Error'
             , 'Cost Center cannot be null for Sundry {Id : ' + CONVERT(NVARCHAR(10), sd.Id) + '} with EntityType {' + sd.EntityType + '}'
        FROM stgSundry sd
        WHERE sd.CostCenterName IS NULL
              AND sd.IsMigrated = 0
              AND sd.EntityType = 'CU';
        INSERT INTO #ErrorLogs
        SELECT DISTINCT 
               sd.Id
             , 'Error'
             , 'Invalid Cost Center for Sundry {Id : ' + CONVERT(NVARCHAR(10), sd.Id) + '} with EntityType {' + sd.EntityType + '}'
        FROM stgSundry sd
             LEFT JOIN CostCenterConfigs CostCenterConfig ON UPPER(CostCenterConfig.CostCenter) = UPPER(sd.CostCenterName)
        WHERE sd.CostCenterName IS NOT NULL
              AND sd.IsMigrated = 0
              AND sd.EntityType = 'CU'
              AND CostCenterConfig.Id IS NULL;
        INSERT INTO #ErrorLogs
        SELECT DISTINCT 
               sd.Id
             , 'Error'
             , 'Payable sundry can not be Asset Based for Sundry {Id : ' + CONVERT(NVARCHAR(10), sd.Id) + '} with EntityType {' + sd.EntityType + '}'
        FROM stgSundry sd
        WHERE sd.IsMigrated = 0
              AND sd.IsAssetBased = 1
              AND sd.SundryType = 'Payable';
        INSERT INTO #ErrorLogs
        SELECT DISTINCT 
               sd.Id
             , 'Error'
             , 'Invalid LegalEntityNumber : ' + ISNULL(sd.LegalEntityNumber, ' ') + 'for Sundry {Id : ' + CONVERT(NVARCHAR(10), sd.Id) + '} with EntityType {' + sd.EntityType + '}'
        FROM stgSundry sd
             LEFT JOIN dbo.LegalEntities le ON sd.LegalEntityNumber = le.LegalEntityNumber
                                               AND le.STATUS = 'Active'
        WHERE sd.IsMigrated = 0
              AND le.Id IS NULL
              AND sd.LegalEntityNumber IS NOT NULL;
        INSERT INTO #ErrorLogs
        SELECT DISTINCT 
               sd.Id
             , 'Error'
             , 'Entity Type must be either Contract or Customer for Sundry {Id : ' + CONVERT(NVARCHAR(10), sd.Id) + '} with EntityType {' + sd.EntityType + '}'
        FROM stgSundry sd
        WHERE sd.IsMigrated = 0
              AND sd.EntityType != 'CT'
              AND sd.EntityType != 'CU'
              AND sd.IsMigrated = 0;
        UPDATE stgSundry
          SET 
              R_ReceivableCodeId = ReceivableCodes.Id
            , R_ReceivableGroupingOption = ReceivableCodes.DefaultInvoiceReceivableGroupingOption
        FROM stgSundry sd
             INNER JOIN ReceivableCodes ON sd.ReceivableCodeName = ReceivableCodes.Name
                                           AND ReceivableCodes.IsActive = 1
                                           AND sd.IsMigrated = 0;
        INSERT INTO #ErrorLogs
        SELECT DISTINCT 
               sd.Id
             , 'Error'
             , 'Valid Receivable Code is required for Sundry {Id : ' + CONVERT(NVARCHAR(10), sd.Id) + '} with EntityType {' + sd.EntityType + '}'
        FROM stgSundry sd
        WHERE sd.IsMigrated = 0
              AND sd.SundryType != 'PayableOnly'
              AND (sd.ReceivableCodeName IS NULL
                   OR sd.R_ReceivableCodeId IS NULL);
        INSERT INTO #ErrorLogs
        SELECT DISTINCT 
               sd.Id
             , 'Error'
             , 'Invalid currency code : ' + ISNULL(sd.CurrencyCode, ' ') + 'for Sundry {Id : ' + CONVERT(NVARCHAR(10), sd.Id) + '} with EntityType {' + sd.EntityType + '}'
        FROM stgSundry sd
             LEFT JOIN CurrencyCodes CurrencyCode ON sd.CurrencyCode = CurrencyCode.ISO
                                                     AND CurrencyCode.IsActive = 1
             LEFT JOIN Currencies Currency ON CurrencyCode.Id = Currency.CurrencyCodeId
                                              AND Currency.IsActive = 1
        WHERE sd.IsMigrated = 0
              AND Currency.Id IS NULL
              AND sd.CurrencyCode IS NOT NULL;
        INSERT INTO #ErrorLogs
        SELECT DISTINCT 
               sd.Id
             , 'Error'
             , 'Valid Receivable Remit to is required for Sundry {Id : ' + CONVERT(NVARCHAR(10), sd.Id) + '} with EntityType {' + ISNULL(sd.EntityType,' ') + '}' AS Message
			 FROM stgSundry sd
			 INNER JOIN LegalEntities ON sd.LegalEntityNumber = LegalEntities.LegalEntityNumber
             LEFT JOIN RemitToes ON RemitToes.UniqueIdentifier = sd.ReceivableRemitToUniqueIdentifier AND RemitToes.IsActive = 1
             LEFT JOIN LegalEntityRemitToes LegalEntityRemitTo ON LegalEntities.Id = LegalEntityRemitTo.LegalEntityId
			 AND RemitToes.Id = LegalEntityRemitTo.RemitToId AND LegalEntityRemitTo.IsActive = 1 
        WHERE sd.IsMigrated = 0
              AND sd.SundryType != 'PayableOnly'
              AND (RemitToes.Id IS NULL or LegalEntityRemitTo .Id IS NULL)
        INSERT INTO #ErrorLogs
        SELECT DISTINCT 
               sd.Id
             , 'Error'
             , ('Payable Code is required for Sundry {Id : ' + CONVERT(NVARCHAR(10), sd.Id) + '} with EntityType {' + sd.EntityType + '}') AS Message
        FROM stgSundry sd
        WHERE (sd.SundryType = 'PayableOnly' OR sd.SundryType = 'PassThrough')
              AND sd.PayableCodeName IS NULL
              AND sd.IsMigrated = 0;

        INSERT INTO #ErrorLogs
        SELECT DISTINCT 
               sd.Id
              ,'Error'
			  ,('Payable Code must be of Type "Misc AP"' + ' : ' +IsNull(PayableCodeName,'Null') +' for Sundry {Id : '+ISNULL(CONVERT(NVARCHAR,sd.Id),' ')+'} with EntityType {'+sd.EntityType+'}') AS Message
        FROM stgSundry sd
		LEFT JOIN PayableCodes PayableCode ON  UPPER(sd.PayableCodeName) = UPPER(PayableCode.Name)
                                                   AND PayableCode.IsActive = 1
        LEFT JOIN PayableTypes ON PayableTypes.Id = PayableCode.PayableTypeId AND PayableTypes.IsActive = 1 AND PayableTypes.Name = 'MiscAP'
        WHERE (sd.SundryType = 'PayableOnly' OR sd.SundryType = 'PassThrough')
              AND sd.PayableCodeName IS NOT NULL AND PayableTypes.Id IS NULL
              AND sd.IsMigrated = 0;
        INSERT INTO #ErrorLogs
        SELECT DISTINCT 
               sd.Id
             , 'Error'
             , ('Payable Remit To is required for Sundry {Id : ' + CONVERT(NVARCHAR(10), sd.Id) + '} with EntityType {' + sd.EntityType + '}') AS Message
        FROM stgSundry sd
        WHERE (sd.SundryType = 'PayableOnly' OR sd.SundryType = 'PassThrough')
              AND sd.IsMigrated = 0
              AND sd.PayableRemitToUniqueIdentifier IS NULL;
        INSERT INTO #ErrorLogs
        SELECT DISTINCT 
               sd.Id
             , 'Error'
             , 'Invalid Branch Name : ' + ISNULL(sd.BranchName, 'NULL') + ' for Sundry {Id : ' + CONVERT(NVARCHAR(10), sd.Id) + '} with EntityType {' + sd.EntityType + '}'
        FROM stgSundry sd
		LEFT JOIN Branches Branch ON sd.BranchName = Branch.BranchName 
        WHERE Branch.Id IS NULL
              AND sd.BranchName IS NOT NULL
              AND sd.IsMigrated = 0
			  AND Branch.Status = 'Active'
              AND sd.EntityType = 'CU';
        SET @FailedRecords =
        (
            SELECT ISNULL(COUNT(DISTINCT StagingRootEntityId), 0)
            FROM #ErrorLogs
        );
        MERGE stgProcessingLog AS ProcessingLog
        USING
        (
            SELECT Id
            FROM stgSundry
            WHERE IsMigrated = 0
                  AND Id NOT IN
            (
                SELECT StagingRootEntityId
                FROM #ErrorLogs
            )
        ) AS ProcessedSundrys
        ON(ProcessingLog.StagingRootEntityId = ProcessedSundrys.Id
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
        (ProcessedSundrys.Id
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
        ) AS ErrorSundrys
        ON(ProcessingLog.StagingRootEntityId = ErrorSundrys.StagingRootEntityId
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
        (ErrorSundrys.StagingRootEntityId
       , @UserId
       , @CreatedTime
       , @ModuleIterationStatusId
        )
        OUTPUT Inserted.Id
             , ErrorSundrys.StagingRootEntityId
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
             JOIN #FailedProcessingLogs ON #ErrorLogs.StagingRootEntityId = #FailedProcessingLogs.SundryId;
        DROP TABLE #ErrorLogs;
        DROP TABLE #FailedProcessingLogs;
        DROP TABLE #CreatedProcessingLogs;
    END;

GO
