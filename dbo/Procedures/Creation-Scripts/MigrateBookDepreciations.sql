SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[MigrateBookDepreciations]
(
	@UserId BIGINT ,
	@ModuleIterationStatusId BIGINT,
	@CreatedTime DATETIMEOFFSET,
	@ProcessedRecords BIGINT OUTPUT,
	@FailedRecords BIGINT OUTPUT 
)
AS
BEGIN
SET NOCOUNT ON
SET XACT_ABORT ON
DECLARE @Counter INT = 0
DECLARE @TakeCount INT = 50000
DECLARE @SkipCount INT = 0
DECLARE @MaxBookDepId INT = 0
DECLARE @BatchCount INT = 0
--	DECLARE @UserId BIGINT ;
--	DECLARE @ModuleIterationStatusId BIGINT;
--	DECLARE @CreatedTime DATETIMEOFFSET;
--	DECLARE @ProcessedRecords BIGINT;
--	DECLARE @FailedRecords BIGINT  ;
--SET @ModuleIterationStatusId = 91153
--SET @UserId = 1
--SET @CreatedTime=SYSDATETIMEOFFSET()
SET @FailedRecords = 0
SET @ProcessedRecords = 0
BEGIN
	DECLARE @TotalRecordsCount INT = (SELECT COUNT(Id) FROM stgBookDepreciation 
										 WHERE	IsMigrated = 0 )
	SET @MaxBookDepId = 0
	SET @SkipCount = 0
	    CREATE TABLE #ErrorLogs
		(
			Id BIGINT not null IDENTITY PRIMARY KEY,
			StagingRootEntityId BIGINT,
			Result NVARCHAR(10),
			Message NVARCHAR(MAX)
		)
		CREATE TABLE #FailedProcessingLogs 
		(
			 [Action] NVARCHAR(10) NOT NULL,
			 [Id] bigint NOT NULL,
			 [BookDepreciationId] bigint NOT NULL
	    )
	WHILE @SkipCount < @TotalRecordsCount
	 BEGIN
	 BEGIN TRY  
     BEGIN TRANSACTION	
		CREATE TABLE #CreatedBookDepreciationIds (
							 [Action] NVARCHAR(10) NOT NULL,
							 [Id] bigint NOT NULL,
							 [BookDepreciationId] bigint NOT NULL)
		CREATE TABLE #CreatedProcessingLogs (
							 [Action] NVARCHAR(10) NOT NULL,
							 [Id] bigint NOT NULL)
		SELECT 
			TOP(@TakeCount) * INTO #BookDepreciationSubset 
		FROM 
			stgBookDepreciation IntermediateBookDepreciation
		WHERE
			IsMigrated = 0 AND 
			(IntermediateBookDepreciation.Id > @MaxBookDepId )
		ORDER BY 
			IntermediateBookDepreciation.Id
		SELECT  
	   IntermediateBookDepreciation.Id [BookDepreciationId]
      ,IntermediateBookDepreciation.[CostBasis_Amount]
      ,IntermediateBookDepreciation.[CostBasis_Currency]
      ,IntermediateBookDepreciation.[Salvage_Amount]
      ,IntermediateBookDepreciation.[Salvage_Currency]
      ,IntermediateBookDepreciation.[BeginDate]
      ,IntermediateBookDepreciation.[EndDate]
      ,IntermediateBookDepreciation.[RemainingLifeInMonths]
      ,IntermediateBookDepreciation.[PerDayDepreciationFactor]
      ,IntermediateBookDepreciation.[TerminatedDate]
      ,IntermediateBookDepreciation.[IsInOTP]
      ,IntermediateBookDepreciation.[LastAmortRunDate]
      ,IntermediateBookDepreciation.[ReversalPostDate]
      ,IntermediateBookDepreciation.[AssetAlias]
      ,IntermediateBookDepreciation.[ContractSequenceNumber]
      ,IntermediateBookDepreciation.[GLTemplateName]
      ,IntermediateBookDepreciation.[InstrumentTypeCode]
      ,IntermediateBookDepreciation.[LineofBusinessName]
      ,IntermediateBookDepreciation.[IsMigrated]
      ,IntermediateBookDepreciation.[CreatedById]
      ,IntermediateBookDepreciation.[CreatedTime]
      ,IntermediateBookDepreciation.[UpdatedById]
      ,IntermediateBookDepreciation.[UpdatedTime]
	  ,IntermediateBookDepreciation.BookDepreciationTemplateName 
	  ,IntermediateBookDepreciation.BranchName
	  ,IntermediateBookDepreciation.IsLessorOwned
	  ,Assets.Id [AssetId]
	  ,Contracts.Id [ContractId]
	  ,GLTemplates.Id [GLTemplateId]
	  ,InstrumentTypes.Id [InstrumentTypeId]
	  ,LineofBusinesses.Id [LineofBusinessId]
	  ,GLOrgStructureConfigs.Id [GlOrgStructureConfigId]
	  ,LegalEntities.LegalEntityNumber
	  ,BookDepreciationTemplates.Id [BookDepreciationTemplateId]
	  ,Branches.Id [BranchId]
	  ,CostCenterConfigs.Id [CostCenterId]
	  ,Assets.IsLeaseComponent [IsLeaseComponent]
	   INTO #BookDepreciationsMappedWithTarget
		FROM 
			#BookDepreciationSubset IntermediateBookDepreciation
		LEFT JOIN Assets
			   ON IntermediateBookDepreciation.AssetAlias = Assets.Alias
 		LEFT JOIN Contracts
			   ON IntermediateBookDepreciation.ContractSequenceNumber = Contracts.SequenceNumber
		LEFT JOIN GLTemplates
			   ON IntermediateBookDepreciation.GLTemplateName = GLTemplates.Name				  
		LEFT JOIN InstrumentTypes
			   ON IntermediateBookDepreciation.InstrumentTypeCode = InstrumentTypes.Code
		LEFT JOIN LineofBusinesses
			   ON IntermediateBookDepreciation.LineofBusinessName = LineofBusinesses.Name
		LEFT JOIN LegalEntities
			   ON Assets.LegalEntityId = LegalEntities.Id
		LEFT JOIN GLOrgStructureConfigs
			  ON  GLOrgStructureConfigs.LineOfBusinessId = LineOfBusinesses.Id AND
			     GLOrgStructureConfigs.LegalEntityId = LegalEntities.Id AND
				 GLOrgStructureConfigs.IsActive = 1
		LEFT JOIN BookDepreciationTemplates 
			 ON BookDepreciationTemplates.Name = IntermediateBookDepreciation.BookDepreciationTemplateName 
			 AND BookDepreciationTemplates.IsActive = 1
		LEFT JOIN Branches 
			 ON Branches.BranchName = IntermediateBookDepreciation.BranchName 
			 AND Branches.Status = 'Active'
		LEFT JOIN CostCenterConfigs
			ON CostCenterConfigs.CostCenter = IntermediateBookDepreciation.CostCenterName
			AND CostCenterConfigs.IsActive = 1  
		WHERE			
			IntermediateBookDepreciation.Id > @MaxBookDepId 
		ORDER BY 
			IntermediateBookDepreciation.Id
		SELECT @MaxBookDepId = MAX(BookDepreciationId) FROM #BookDepreciationsMappedWithTarget;		
		SELECT @BatchCount = ISNULL(COUNT(BookDepreciationId),0) FROM #BookDepreciationsMappedWithTarget; 
		INSERT INTO #ErrorLogs
		SELECT
		   BookDepreciationId
		  ,'Error'
		  ,('Reversal Post Date should be within financial open period :' + CAST(GLFinancialOpenPeriods.FromDate AS VARCHAR(50))+' and '+ CAST(GLFinancialOpenPeriods.ToDate AS VARCHAR(50)) ) AS Message
		FROM 
			#BookDepreciationsMappedWithTarget
		LEFT JOIN Assets ON #BookDepreciationsMappedWithTarget.AssetAlias = Assets.Alias
		LEFT JOIN LegalEntities ON Assets.LegalEntityId = LegalEntities.Id
		LEFT JOIN GLFinancialOpenPeriods ON LegalEntities.Id = GLFinancialOpenPeriods.LegalEntityId
		WHERE
			#BookDepreciationsMappedWithTarget.ReversalPostDate IS NOT NULL AND
			GLFinancialOpenPeriods.IsCurrent = 1 and GLFinancialOpenPeriods.FromDate IS NOT NULL
			AND GLFinancialOpenPeriods.ToDate IS NOT NULL
			AND ( #BookDepreciationsMappedWithTarget.ReversalPostDate < GLFinancialOpenPeriods.FromDate OR
					#BookDepreciationsMappedWithTarget.ReversalPostDate >GLFinancialOpenPeriods.ToDate)
		INSERT INTO #ErrorLogs
		SELECT
		   BookDepreciationId
		  ,'Error'
		  ,('Begin Date should be within financial open period :' +CAST(GLFinancialOpenPeriods.FromDate AS VARCHAR(50))+' and '+ CAST(GLFinancialOpenPeriods.ToDate AS VARCHAR(50)) ) AS Message
		FROM 
			#BookDepreciationsMappedWithTarget
		LEFT JOIN Assets ON #BookDepreciationsMappedWithTarget.AssetAlias = Assets.Alias
		LEFT JOIN LegalEntities ON Assets.LegalEntityId = LegalEntities.Id
		LEFT JOIN GLFinancialOpenPeriods ON LegalEntities.Id = GLFinancialOpenPeriods.LegalEntityId
		WHERE
			GLFinancialOpenPeriods.IsCurrent = 1 and GLFinancialOpenPeriods.FromDate IS NOT NULL
			AND GLFinancialOpenPeriods.ToDate IS NOT NULL
			AND #BookDepreciationsMappedWithTarget.LastAmortRunDate IS NULL
			AND (#BookDepreciationsMappedWithTarget.BeginDate < GLFinancialOpenPeriods.FromDate OR #BookDepreciationsMappedWithTarget.BeginDate > GLFinancialOpenPeriods.ToDate)
		INSERT INTO #ErrorLogs
		SELECT
		   BookDepreciationId
		  ,'Error'
		  ,('An Active Book Depreciation record exists for the Asset { '+AssetAlias+' }. Enter a Begin Date after Termination Date of Previous Book Dep record') AS Message
		FROM
			(SELECT * FROM #BookDepreciationsMappedWithTarget
			JOIN (Select AssetId previousBookDepAssetId,TerminatedDate As previousTerminationDate, Id As PreviousBookDepId from  BookDepreciations B
					where B.Id IN (SELECT TOP(1) Id  FROM BookDepreciations where BookDepreciations.AssetId = B.AssetId AND IsActive=1
					 ORDER By BookDepreciations.BeginDate DESC)) t on #BookDepreciationsMappedWithTarget.AssetId = t.previousBookDepAssetId) as finalTable		
		WHERE
		PreviousBookDepId IS NOT NULL AND
		previousTerminationDate IS NOT NULL
		AND BeginDate < previousTerminationDate
		INSERT INTO #ErrorLogs
		SELECT
		   BookDepreciationId
		  ,'Error'
		  ,('An Active Book Depreciation record exists for the Asset { '+AssetAlias+' }. Enter a Begin Date after the Begin Date of Previous Book Dep record') AS Message
		FROM
			(SELECT TOP(1) * FROM #BookDepreciationsMappedWithTarget
			JOIN (Select AssetId previousBookDepAssetId,BeginDate As previousBegindate, Id As PreviousBookDepId from  BookDepreciations B
					where B.Id IN (SELECT TOP(1) Id  FROM BookDepreciations where BookDepreciations.AssetId = B.AssetId AND IsActive=1
					 ORDER By BookDepreciations.BeginDate DESC)) t on #BookDepreciationsMappedWithTarget.AssetId = t.previousBookDepAssetId) as finalTable		
		WHERE
		PreviousBookDepId IS NOT NULL AND
		BeginDate < previousBegindate
		INSERT INTO #ErrorLogs
		SELECT
		   BookDepreciationId
		  ,'Error'
		  ,('Remaining Life in Months must be greater than 0') AS Message
		FROM 
			#BookDepreciationsMappedWithTarget
		WHERE
		EndDate IS NOT NULL AND
		RemainingLifeInMonths < 0
		INSERT INTO #ErrorLogs
		SELECT
		   BookDepreciationId
		  ,'Error'
		  ,('Cost Basis must not be equal to 0') AS Message
		FROM 
			#BookDepreciationsMappedWithTarget
		WHERE		
		CostBasis_Amount = 0.0
		INSERT INTO #ErrorLogs
		SELECT
		   BookDepreciationId
		  ,'Error'
		  ,('Termination Date must be between the Begin Date and End Date') AS Message
		FROM 
			#BookDepreciationsMappedWithTarget
		WHERE
		TerminatedDate IS NOT NULL AND
		TerminatedDate < BeginDate AND TerminatedDate > EndDate
		--INSERT INTO #ErrorLogs
		--SELECT
		--   BookDepreciationId
		--  ,'Error'
		--  ,('Termination Date is required to clear Accumulated Book Depreciation') AS Message
		--FROM 
		--	#BookDepreciationsMappedWithTarget
		--WHERE		
		--TerminatedDate IS NULL
		--INSERT INTO #ErrorLogs
		--SELECT
		--   BookDepreciationId
		--  ,'Error'
		--  ,('Book Depreciation Update has not been run for this record') AS Message
		--FROM 
		--	#BookDepreciationsMappedWithTarget
		--WHERE		
		--LastAmortRunDate IS NULL
		INSERT INTO #ErrorLogs
		SELECT
		   BookDepreciationId
		  ,'Error'
		  ,('GL Template selected should have GL Transaction type as Book Depreciation') AS Message
		FROM 
			#BookDepreciationsMappedWithTarget
			LEFT JOIN GLTemplates on #BookDepreciationsMappedWithTarget.GLTemplateId = GLTemplates.Id
			LEFT JOIN GLTransactionTypes on GLTemplates.GLTransactionTypeId = GLTransactionTypes.Id			
		WHERE		
		GLTransactionTypes.Name != 'BookDepreciation' 
		INSERT INTO #ErrorLogs
		SELECT
		   BookDepreciationId
		  ,'Error'
		  ,('GL Template selected should be Active') AS Message
		FROM 
			#BookDepreciationsMappedWithTarget
			LEFT JOIN GLTemplates on #BookDepreciationsMappedWithTarget.GLTemplateId = GLTemplates.Id
		WHERE		
		GLTemplates.IsActive = 0
		INSERT INTO #ErrorLogs
		SELECT
		   BookDepreciationId
		  ,'Error'
		  ,('GL configuration of the GL Template should match the GL Configuration of the Legal Entity of Asset') AS Message
		FROM 
			#BookDepreciationsMappedWithTarget
			LEFT JOIN GLTemplates on #BookDepreciationsMappedWithTarget.GLTemplateId = GLTemplates.Id			
			LEFT JOIN Assets on #BookDepreciationsMappedWithTarget.AssetId = Assets.Id
			LEFT JOIN LegalEntities on Assets.LegalEntityId = LegalEntities.Id
		WHERE		
		LegalEntities.GLConfigurationId != GLTemplates.GLConfigurationId
		INSERT INTO #ErrorLogs
		SELECT
		   BookDepreciationId
		  ,'Error'
		  ,('Asset status must be Inventory') AS Message
		FROM 
			#BookDepreciationsMappedWithTarget			
			LEFT JOIN Assets on #BookDepreciationsMappedWithTarget.AssetId = Assets.Id			
		WHERE
		Assets.Status != 'Inventory'
		INSERT INTO #ErrorLogs
		SELECT
		   BookDepreciationId
		  ,'Error'
		  ,('Asset financial type must be Real') AS Message
		FROM 
			#BookDepreciationsMappedWithTarget			
			LEFT JOIN Assets on #BookDepreciationsMappedWithTarget.AssetId = Assets.Id			
		WHERE
		Assets.FinancialType != 'Real'
		INSERT INTO #ErrorLogs
		SELECT
		   BookDepreciationId
		  ,'Error'
		  ,('Asset net value should not be 0') AS Message
		FROM 
			#BookDepreciationsMappedWithTarget
			LEFT JOIN AssetValueHistories on #BookDepreciationsMappedWithTarget.AssetId = AssetValueHistories.AssetId
		WHERE
		AssetValueHistories.IsLessorOwned = 1
		AND AssetValueHistories.NetValue_Amount = 0		
		--INSERT INTO #ErrorLogs
		--SELECT
		--   BookDepreciationId
		--  ,'Error'
		--  ,('Asset should be GL Posted') AS Message
		--FROM 
		--	(Select  * From #BookDepreciationsMappedWithTarget 
		--	join (Select AssetId avhAsset, GLJournalId from  AssetValueHistories A 
		--			where A.Id IN (select TOP(1) Id  from AssetValueHistories where AssetValueHistories.AssetId = A.AssetId
		--			 ORDER By AssetValueHistories.id asc)) t on #BookDepreciationsMappedWithTarget.AssetId = t.avhAsset) as finalTable
		--WHERE
		--finalTable.GLJournalId IS NULL
		INSERT INTO #ErrorLogs
		SELECT
		   BookDepreciationId
		  ,'Error'
		  ,('Begin date should be greater than or equal to Income date of the Asset') AS Message
		FROM 
			(SELECT * FROM #BookDepreciationsMappedWithTarget
			JOIN (Select AssetId avhAsset, IncomeDate from  AssetValueHistories A 
					where A.Id IN (select TOP(1) Id  from AssetValueHistories where AssetValueHistories.AssetId = A.AssetId
					 ORDER By AssetValueHistories.id asc) AND IsCleared=1) t on #BookDepreciationsMappedWithTarget.AssetId = t.avhAsset) as finalTable			
		WHERE
		finalTable.BeginDate < finalTable.IncomeDate
		INSERT INTO #ErrorLogs
		SELECT
		   BookDepreciationId
		  ,'Error'
		  ,('The Salvage value for the book depreciation should be equal to the Salvage value in asset') AS Message
		FROM 
			#BookDepreciationsMappedWithTarget			
			LEFT JOIN Assets on #BookDepreciationsMappedWithTarget.AssetId = Assets.Id			
		WHERE
		#BookDepreciationsMappedWithTarget.Salvage_Amount != Assets.Salvage_Amount
		INSERT INTO #ErrorLogs
		SELECT
		   BookDepreciationId
		  ,'Error'
		  ,('Legal Entity Associated with Asset :'+ISNULL(AssetAlias,'NULL')+' should be active') AS Message
		FROM 
			#BookDepreciationsMappedWithTarget			
			JOIN Assets on #BookDepreciationsMappedWithTarget.AssetId = Assets.Id
			JOIN LegalEntities on LegalEntities.Id = Assets.LegalEntityId
		WHERE
		LegalEntities.Status !='Active'
		INSERT INTO #ErrorLogs
		SELECT
		   BookDepreciationId
		  ,'Error'
		  ,('Matching Line of Business not found for :'+ISNULL(LineofBusinessName,'NULL')) AS Message
		FROM 
			#BookDepreciationsMappedWithTarget			
		WHERE
			LineOfBusinessId IS NULL
		INSERT INTO #ErrorLogs
		SELECT
		   BookDepreciationId
		  ,'Error'
		  ,(' Line of Business <'+ISNULL(LineofBusinessName,'NULL')+'> must be associated with Legal Entity Number' + ISNULL(LegalEntityNumber,'NULL')) AS Message
		FROM 
			#BookDepreciationsMappedWithTarget			
		WHERE
			LineOfBusinessId IS NOT NULL AND
			GlOrgStructureConfigId IS NULL
		--INSERT INTO #ErrorLogs
		--SELECT
		--   BookDepreciationId
		--  ,'Error'
		--  ,('Book Depreciation Amort has not been run till the Termination Date') AS Message
		--FROM 
		--	#BookDepreciationsMappedWithTarget
		--WHERE		
		--LastAmortRunDate < TerminatedDate
		--INSERT INTO #ErrorLogs
		--SELECT
		--   BookDepreciationId
		--  ,'Error'
		--  ,('Book Depreciation Amort has not been run till the End Date') AS Message
		--FROM 
		--	#BookDepreciationsMappedWithTarget
		--WHERE		
		--LastAmortRunDate != EndDate
		INSERT INTO #ErrorLogs
		SELECT
		   BookDepreciationId
		  ,'Error'
		  ,('Matching Book Depreciation Template not found for : '+BookDepreciationTemplateName) AS Message
		FROM 
			#BookDepreciationsMappedWithTarget			
		WHERE
			BookDepreciationTemplateId IS NULL AND BookDepreciationTemplateName IS NOT NULL
		INSERT INTO #ErrorLogs
		SELECT
		   BookDepreciationId
		  ,'Error'
		  ,('Matching Branch Name not found for : '+ BranchName) AS Message
		FROM 
			#BookDepreciationsMappedWithTarget			
		WHERE
			BranchId IS NULL AND BranchName IS NOT NULL
		MERGE BookDepreciations AS BookDepreciation
		USING (SELECT
				#BookDepreciationsMappedWithTarget.* ,#ErrorLogs.StagingRootEntityId
			   FROM
				#BookDepreciationsMappedWithTarget 
			   LEFT JOIN #ErrorLogs
					  ON #BookDepreciationsMappedWithTarget.BookDepreciationId = #ErrorLogs.StagingRootEntityId) AS BookDepreciationToMigrate
	    ON (1=0)
		WHEN MATCHED AND BookDepreciationToMigrate.StagingRootEntityId IS NULL THEN
			UPDATE SET BookDepreciation.CostBasis_Amount = BookDepreciationToMigrate.CostBasis_Amount ,UpdatedTime=SYSDATETIMEOFFSET()
		WHEN NOT MATCHED  AND BookDepreciationToMigrate.StagingRootEntityId IS NULL
		THEN
			INSERT
			   ([CostBasis_Amount]
				,[CostBasis_Currency]
				,[Salvage_Amount]
				,[Salvage_Currency]
				,[BeginDate]
				,[EndDate]
				,[RemainingLifeInMonths]
				,[PerDayDepreciationFactor]
				,[TerminatedDate]
				,[IsActive]
				,[IsInOTP]
				,[LastAmortRunDate]
				,[ReversalPostDate]
				,[CreatedById]
				,[CreatedTime]
				,[UpdatedById]
				,[UpdatedTime]
				,[AssetId]
				,[GLTemplateId]
				,[ClearAccumulatedGLJournalId]
				,[InstrumentTypeId]
				,[LineofBusinessId]				
				,[ContractId]
				,[BookDepreciationTemplateId]
				,[BranchId]
				,[CostCenterId]
				,[IsLessorOwned]
				,[IsLeaseComponent])
     VALUES
		   (BookDepreciationToMigrate.[CostBasis_Amount]
			,BookDepreciationToMigrate.[CostBasis_Currency]
			,BookDepreciationToMigrate.[Salvage_Amount]
			,BookDepreciationToMigrate.[Salvage_Currency]
			,BookDepreciationToMigrate.[BeginDate]
			,BookDepreciationToMigrate.[EndDate]
			,BookDepreciationToMigrate.[RemainingLifeInMonths]
			,(BookDepreciationToMigrate.CostBasis_Amount- BookDepreciationToMigrate.[Salvage_Amount]) / (DATEDIFF(day,BookDepreciationToMigrate.Begindate,BookDepreciationToMigrate.EndDate))
			,NULL
			,1
			,0
			,NULL
			,BookDepreciationToMigrate.[ReversalPostDate]
			,@UserId
			,@CreatedTime
			,NULL
			,NULL
			,BookDepreciationToMigrate.[AssetId]
			,BookDepreciationToMigrate.[GLTemplateId]
			,NULL
			,BookDepreciationToMigrate.[InstrumentTypeId]
			,BookDepreciationToMigrate.[LineofBusinessId]			
			,BookDepreciationToMigrate.[ContractId]
			,BookDepreciationToMigrate.[BookDepreciationTemplateId]
			,BookDepreciationToMigrate.[BranchId]
			,BookDepreciationToMigrate.[CostCenterId]
			,BookDepreciationToMigrate.IsLessorOwned
			,BookDepreciationToMigrate.[IsLeaseComponent])
		  
		  
		OUTPUT $action, Inserted.Id, BookDepreciationToMigrate.BookDepreciationId INTO #CreatedBookDepreciationIds;
		UPDATE  stgBookDepreciation SET IsMigrated = 1 
			WHERE Id in ( SELECT BookDepreciationId FROM #CreatedBookDepreciationIds);
		MERGE stgProcessingLog AS ProcessingLog
		USING (SELECT
				distinct BookDepreciationId
			   FROM
				#CreatedBookDepreciationIds
			  ) AS ProcessedBookDepreciations
		ON (ProcessingLog.StagingRootEntityId = ProcessedBookDepreciations.BookDepreciationId AND ProcessingLog.ModuleIterationStatusId = @ModuleIterationStatusId)
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
				ProcessedBookDepreciations.BookDepreciationId
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
		   ,Id
		FROM
			#CreatedProcessingLogs	
	DROP TABLE #BookDepreciationSubset
	DROP TABLE #BookDepreciationsMappedWithTarget
	DROP TABLE #CreatedBookDepreciationIds
	DROP TABLE #CreatedProcessingLogs	
	SET @SkipCount = @SkipCount + @TakeCount
	MERGE stgProcessingLog AS ProcessingLog
		USING (SELECT
				DISTINCT StagingRootEntityId
			   FROM
				#ErrorLogs 
			  ) AS ErrorBookDepreciations
		ON (ProcessingLog.StagingRootEntityId = ErrorBookDepreciations.StagingRootEntityId AND ProcessingLog.ModuleIterationStatusId = @ModuleIterationStatusId)
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
				ErrorBookDepreciations.StagingRootEntityId
			   ,@UserId
			   ,@CreatedTime
			   ,@ModuleIterationStatusId
			)
		OUTPUT $action, Inserted.Id,ErrorBookDepreciations.StagingRootEntityId INTO #FailedProcessingLogs;	
		DECLARE @TotalRecordsFailed INT = (SELECT  COUNT( DISTINCT Id) FROM #FailedProcessingLogs)
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
		   ,#FailedProcessingLogs.Id
		FROM
			#ErrorLogs
		INNER JOIN #FailedProcessingLogs
				ON #ErrorLogs.StagingRootEntityId = #FailedProcessingLogs.BookDepreciationId
SET @FailedRecords = @FailedRecords+(SELECT COUNT(DISTINCT StagingRootEntityId) FROM #ErrorLogs)
 DELETE #FailedProcessingLogs
 DELETE #ErrorLogs
COMMIT TRANSACTION
END TRY
BEGIN CATCH
	SET @SkipCount = @SkipCount  + @TakeCount;
	DECLARE @ErrorMessage Nvarchar(max);
	DECLARE @ErrorLine Nvarchar(max);
	DECLARE @ErrorSeverity INT;
	DECLARE @ErrorState INT;
	DECLARE @ErrorLogs ErrorMessageList;
	DECLARE @ModuleName Nvarchar(max) = 'MigrateBookDepreciations'
	Insert into @ErrorLogs(StagingRootEntityId, ModuleIterationStatusId, Message,Type) VALUES (0,@ModuleIterationStatusId,ERROR_MESSAGE(),'Error')
	SELECT  @ErrorSeverity = ERROR_SEVERITY(), @ErrorState = ERROR_STATE(),@ErrorLine=ERROR_LINE(),@ErrorMessage=ERROR_MESSAGE()
	IF (XACT_STATE()) = -1  
	BEGIN  
		ROLLBACK TRANSACTION;
		EXEC [dbo].[ExceptionLog] @ErrorLogs,@ErrorLine,@UserId,@CreatedTime,@ModuleName
		set @FailedRecords = @FailedRecords+@BatchCount;
	END  
	IF (XACT_STATE()) = 1  
	BEGIN
		COMMIT TRANSACTION;
		RAISERROR (@ErrorMessage,@ErrorSeverity, @ErrorState);     
	END;  
END CATCH	
END
	
SET @ProcessedRecords = @ProcessedRecords + @TotalRecordsCount
	DROP TABLE #ErrorLogs	
	DROP TABLE #FailedProcessingLogs
END
SET NOCOUNT OFF
SET XACT_ABORT OFF;
END

GO
