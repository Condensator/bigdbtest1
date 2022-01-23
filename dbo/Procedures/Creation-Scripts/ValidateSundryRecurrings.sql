SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[ValidateSundryRecurrings]
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
            FROM dbo.stgSundryRecurring
            WHERE IsMigrated = 0
        );
        SELECT DISTINCT 
               LineofBusinessId
             , LegalEntityId
        INTO #LegalEntityLOB
        FROM GLOrgStructureConfigs
        WHERE IsActive = 1;
        INSERT INTO #ErrorLogs
        SELECT DISTINCT 
               sr.Id
             , 'Error'
             , 'Invalid InstrumentTypeCode : ' + ISNULL(sr.InstrumentTypeCode, ' ') + ' for sundry recurring {Id : ' + ISNULL(CONVERT(NVARCHAR, sr.Id), ' ') + '} with EntityType {' + sr.EntityType + '}'
        FROM stgSundryRecurring sr
             LEFT JOIN InstrumentTypes ON InstrumentTypes.Code = sr.InstrumentTypeCode
                                          AND InstrumentTypes.IsActive = 1
        WHERE InstrumentTypes.Id IS NULL
              AND IsMigrated = 0
              AND sr.EntityType != 'CT';
        INSERT INTO #ErrorLogs
        SELECT DISTINCT 
               sr.Id
             , 'Error'
             , 'At least one asset must be present for the asset based sundry { Id : ' + CONVERT(NVARCHAR, sr.Id) + '}'
        FROM stgSundryRecurring sr
        WHERE sr.Id NOT IN (SELECT SundryRecurringId FROM stgSundryRecurringPaymentDetail)
              AND IsMigrated = 0
              AND sr.IsAssetBased = 1
              AND sr.SundryType != 'PayableOnly';
        INSERT INTO #ErrorLogs
        SELECT DISTINCT 
               sr.Id
             , 'Error'
             , 'Asset must not be present for the sundry as it is not set as IsAssetBased for sundry recurring { Id : ' + CONVERT(NVARCHAR, sr.Id) + '}'
        FROM stgSundryRecurring sr
        WHERE sr.R_SundryRecurringPaymentDetailId IS NOT NULL
              AND IsMigrated = 0
              AND sr.IsAssetBased = 0;
        INSERT INTO #ErrorLogs
        SELECT DISTINCT 
               sr.Id
             , 'Error'
             , 'Payable sundry can not be Asset Based for sundry recurring { Id : ' + CONVERT(NVARCHAR, sr.Id) + '}'
        FROM stgSundryRecurring sr
        WHERE sr.IsMigrated = 0
              AND sr.IsAssetBased = 1
              AND sr.SundryType = 'PayableOnly';
        	  INSERT INTO #ErrorLogs
        SELECT DISTINCT 
               SR.Id
             , 'Error'
             , 'Invalid LegalEntityNumber : ' + ISNULL(SR.LegalEntityNumber, ' ') + 'for SundryRecurring {Id : ' + CONVERT(NVARCHAR, SR.Id) + '} with EntityType {' + SR.EntityType + '}'
        FROM stgSundryRecurring SR
             LEFT JOIN LegalEntities ON SR.LegalEntityNumber = LegalEntities.LegalEntityNumber
                                               AND LegalEntities.STATUS = 'Active'
        WHERE SR.IsMigrated = 0
              AND LegalEntities.Id IS NULL
              AND SR.LegalEntityNumber IS NOT NULL;
        
		 INSERT INTO #ErrorLogs
        SELECT DISTINCT 
               sr.Id
             , 'Error'
             , 'Entity Type must be either Contract or Customer for sundry recurring { Id : ' + CONVERT(NVARCHAR, sr.Id) + '}'
        FROM stgSundryRecurring sr
        WHERE sr.IsMigrated = 0
              AND sr.EntityType != 'CT'
              AND sr.EntityType != 'CU'
              AND sr.IsMigrated = 0;
        INSERT INTO #ErrorLogs
        SELECT DISTINCT 
               sr.Id
             , 'Error'
             , 'Valid Receivable Code is required for sundry recurring { Id : ' + CONVERT(NVARCHAR, sr.Id) + '}'
        FROM stgSundryRecurring sr
             LEFT JOIN ReceivableCodes ON sr.ReceivableCodeName = ReceivableCodes.Name
                                          AND ReceivableCodes.IsActive = 1
        WHERE sr.IsMigrated = 0
              AND sr.SundryType != 'PayableOnly'
              AND (sr.ReceivableCodeName IS NULL
                   OR sr.Id IS NULL);
        INSERT INTO #ErrorLogs
        SELECT DISTINCT 
               SR.Id
             , 'Error'
             , 'Receivable Remit to must belong to the selected Legal Entity for sundryRecurring {Id : ' + CONVERT(NVARCHAR, SR.Id) + '} with EntityType {' + ISNULL(SR.EntityType,' ') + '}' AS Message
			 FROM stgSundryRecurring SR
			 INNER JOIN LegalEntities ON SR.LegalEntityNumber = LegalEntities.LegalEntityNumber
             LEFT JOIN RemitToes ON RemitToes.UniqueIdentifier = SR.ReceivableRemitToUniqueIdentifier AND RemitToes.IsActive = 1
             LEFT JOIN LegalEntityRemitToes LegalEntityRemitTo ON LegalEntities.Id = LegalEntityRemitTo.LegalEntityId
			 AND RemitToes.Id = LegalEntityRemitTo.RemitToId AND LegalEntityRemitTo.IsActive = 1 
        WHERE SR.IsMigrated = 0
              AND SR.SundryType != 'PayableOnly'
              AND (RemitToes.Id IS NULL or LegalEntityRemitTo .Id IS NULL)
        INSERT INTO #ErrorLogs
        SELECT DISTINCT 
               sr.Id
             , 'Error'
             , 'Valid Receivable Remit to is required for sundry recurring { Id : ' + CONVERT(NVARCHAR, sr.Id) + '}' AS Message
        FROM stgSundryRecurring sr
             LEFT JOIN RemitToes ON UPPER(RemitToes.UniqueIdentifier) = UPPER(sr.ReceivableRemitToUniqueIdentifier)
                                    AND RemitToes.IsActive = 1
        WHERE RemitToes.Id IS NULL
              AND IsMigrated = 0
              AND sr.SundryType != 'PayableOnly';
        INSERT INTO #ErrorLogs
        SELECT DISTINCT 
               sr.Id
             , 'Error'
             , ('Assign at asset level field should be false for sundry recurring { Id : ' + CONVERT(NVARCHAR, sr.Id) + '}') AS Message
        FROM stgSundryRecurring sr
        WHERE sr.IsMigrated = 0
              AND sr.IsAssetBased = 0
              AND sr.IsApplyAtAssetLevel = 1;
        INSERT INTO #ErrorLogs
        SELECT DISTINCT 
               sr.Id
             , 'Error'
             , ('Bill Past End Date field should be false for sundry recurring { Id : ' + CONVERT(NVARCHAR, sr.Id) + '}') AS Message
        FROM stgSundryRecurring sr
        WHERE sr.IsMigrated = 0
              AND sr.IsRentalBased = 0
              AND sr.BillPastEndDate = 1;
        INSERT INTO #ErrorLogs
        SELECT DISTINCT 
               sr.Id
             , 'Error'
             , ('No.Of Payment Schedule records should match with NumberOfPayments field for sundry recurring { Id : ' + CONVERT(NVARCHAR, sr.Id) + '}') AS Message
        FROM stgSundryRecurring sr
             INNER JOIN
        (
            SELECT COUNT(Id) AS Count
                 , SundryRecurringId
            FROM stgSundryRecurringPaymentSchedule
            GROUP BY SundryRecurringId
        ) AS schedule ON schedule.SundryRecurringId = sr.Id
        WHERE sr.IsMigrated = 0
              AND sr.IsRentalBased = 0
              AND sr.BillPastEndDate = 1
              AND Count != sr.NumberOfPayments
              AND sr.GeneratePaymentSchedule = 0;
        INSERT INTO #ErrorLogs
        SELECT DISTINCT 
               sr.Id
             , 'Error'
             , ('Payable Code is required for sundry recurring { Id : ' + CONVERT(NVARCHAR, sr.Id) + '}') AS Message
        FROM stgSundryRecurring sr
        WHERE(sr.SundryType = 'PayableOnly'
              OR sr.SundryType = 'PassThrough')
             AND sr.PayableCodeName IS NULL
             AND sr.IsMigrated = 0;

		INSERT INTO #ErrorLogs
		SELECT DISTINCT 
			   sr.Id
			 , 'Error'
			 , ('Payable Code must be of Type "Misc AP"' + ' : ' +IsNull(PayableCodeName,'Null') + ' for sundry recurring { Id : ' + CONVERT(NVARCHAR, sr.Id) + '}') AS Message
		FROM stgSundryRecurring SR
		    LEFT JOIN PayableCodes PayableCode ON UPPER(SR.PayableCodeName) = UPPER(PayableCode.Name)
                                                   AND PayableCode.IsActive = 1
			 LEFT JOIN PayableTypes ON PayableTypes.Id = PayableCode.PayableTypeId AND PayableTypes.IsActive = 1 AND PayableTypes.Name = 'MiscAP'
		WHERE (SR.SundryType = 'PayableOnly' OR SR.SundryType = 'PassThrough')
			  AND SR.PayableCodeName IS NOT NULL AND  PayableTypes.Id IS NULL 
			  AND SR.IsMigrated=0 ;
        INSERT INTO #ErrorLogs
        SELECT DISTINCT 
               sr.Id
             , 'Error'
             , ('Payable Remit To is required for sundry recurring { Id : ' + CONVERT(NVARCHAR, sr.Id) + '}') AS Message
        FROM stgSundryRecurring sr
        WHERE(sr.SundryType = 'PayableOnly'
              OR sr.SundryType = 'PassThrough')
             AND IsMigrated = 0
             AND sr.PayableRemitToUniqueIdentifier IS NULL;
        INSERT INTO #ErrorLogs
        SELECT DISTINCT 
               sr.Id
             , 'Error'
             , ('Valid Payable Remit To is required for sundry recurring { Id : ' + CONVERT(NVARCHAR, sr.Id) + '}') AS Message
        FROM stgSundryRecurring sr
             LEFT JOIN RemitToes PayableRemitTo ON UPPER(sr.PayableRemitToUniqueIdentifier) = UPPER(PayableRemitTo.UniqueIdentifier)
                                                   AND PayableRemitTo.IsActive = 1
        WHERE(sr.SundryType = 'PayableOnly'
              OR sr.SundryType = 'PassThrough')
             AND sr.IsMigrated = 0
             AND PayableRemitTo.Id IS NULL
             AND sr.PayableRemitToUniqueIdentifier IS NOT NULL;
        INSERT INTO #ErrorLogs
        SELECT DISTINCT 
               sr.Id
             , 'Error'
             , ('Number of Payment must be greater than zero for sundry recurring { Id : ' + CONVERT(NVARCHAR, sr.Id) + '}') AS Message
        FROM stgSundryRecurring sr
        WHERE IsMigrated = 0
              AND (sr.NumberOfPayments IS NULL
                   OR sr.NumberOfPayments = 0);
        INSERT INTO #ErrorLogs
        SELECT DISTINCT 
               sr.Id
             , 'Error'
             , ('Due Day must be zero for sundry recurring { Id : ' + CONVERT(NVARCHAR, sr.Id) + '}') AS Message
        FROM stgSundryRecurring sr
        WHERE IsMigrated = 0
              AND sr.DueDay > 0
              AND (sr.Frequency = 'Days'
                   OR sr.Frequency = 'Weekly'
                   OR sr.Frequency = 'BiWeekly');
        INSERT INTO #ErrorLogs
        SELECT DISTINCT 
               sr.Id
             , 'Error'
             , ('Number of Days must be zero for sundry recurring { Id : ' + CONVERT(NVARCHAR, sr.Id) + '}') AS Message
        FROM stgSundryRecurring sr
        WHERE IsMigrated = 0
              AND sr.NumberOfDays > 0
              AND sr.Frequency != 'Days';
        INSERT INTO #ErrorLogs
        SELECT DISTINCT 
               sr.Id
             , 'Error'
             , ('Frequency should not be null for sundry recurring { Id : ' + CONVERT(NVARCHAR, sr.Id) + '}') AS Message
        FROM stgSundryRecurring sr
        WHERE IsMigrated = 0
              AND sr.Frequency IS NULL;
        INSERT INTO #ErrorLogs
        SELECT DISTINCT 
               sr.Id
             , 'Error'
             , ('Due Day should not be null for sundry recurring { Id : ' + CONVERT(NVARCHAR, sr.Id) + '}') AS Message
        FROM stgSundryRecurring sr
        WHERE IsMigrated = 0
              AND sr.DueDay IS NULL
              AND Frequency != 'Days';
        INSERT INTO #ErrorLogs
        SELECT DISTINCT 
               sr.Id
             , 'Error'
             , ('Due Day must be between 1 and 31 for sundry recurring { Id : ' + CONVERT(NVARCHAR, sr.Id) + '}') AS Message
        FROM stgSundryRecurring sr
        WHERE IsMigrated = 0
              AND sr.DueDay NOT BETWEEN 1 AND 31
              AND Frequency != 'Days'
              AND Frequency != 'Weekly'
              AND Frequency != 'BiWeekly';
        INSERT INTO #ErrorLogs
        SELECT DISTINCT 
               sr.Id
             , 'Error'
             , ('Number of Days must be 28 or 30 for sundry recurring { Id : ' + CONVERT(NVARCHAR, sr.Id) + '}') AS Message
        FROM stgSundryRecurring sr
        WHERE IsMigrated = 0
              AND sr.Frequency = 'Daily'
              AND (sr.NumberOfDays != 28
                   AND sr.NumberOfDays != 30);
        INSERT INTO #ErrorLogs
        SELECT DISTINCT 
               sr.Id
             , 'Error'
             , ('Payable Amount should be less than or equal to Receivable Amount for sundry recurring { Id : ' + CONVERT(NVARCHAR, sr.Id) + '}') AS Message
        FROM stgSundryRecurring sr
             INNER JOIN stgSundryRecurringPaymentDetail detail ON sr.Id = detail.SundryRecurringId
        WHERE detail.PayableAmount_Amount > detail.Amount_Amount
              AND sr.IsMigrated = 0
              AND sr.IsApplyAtAssetLevel = 1
              AND sr.SundryType = 'PassThrough';
        INSERT INTO #ErrorLogs
        SELECT DISTINCT 
               sr.Id
             , 'Error'
             , 'Invalid CostCenter : ' + ISNULL(sr.CostCenterName, ' ') + ' for sundry recurring {Id : ' + ISNULL(CONVERT(NVARCHAR, sr.Id), ' ') + '} with EntityType {' + sr.EntityType + '}'
        FROM stgSundryRecurring sr
             LEFT JOIN CostCenterConfigs CostCenterConfig ON UPPER(CostCenterConfig.CostCenter) = UPPER(SR.CostCenterName)
        WHERE sr.Ismigrated = 0
              AND CostCenterConfig.Id IS NULL AND SR.CostCenterName IS NOT NULL;
		SET @FailedRecords =
        (
            SELECT ISNULL(COUNT(DISTINCT StagingRootEntityId), 0)
            FROM #ErrorLogs
        );
        MERGE stgProcessingLog AS ProcessingLog
        USING
        (
            SELECT Id
            FROM stgSundryRecurring
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
