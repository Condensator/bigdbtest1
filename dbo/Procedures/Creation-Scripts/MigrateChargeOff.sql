SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE  PROCEDURE [dbo].[MigrateChargeOff]
(
	@UserId BIGINT ,
	@ModuleIterationStatusId BIGINT,
	@CreatedTime DATETIME,
	@ProcessedRecords BIGINT OUTPUT,
	@FailedRecords BIGINT OUTPUT,
    @ToolIdentifier INT
)
AS
--DECLARE @UserId BIGINT;
--DECLARE @FailedRecords BIGINT;
--DECLARE @ProcessedRecords BIGINT;
--DECLARE @CreatedTime DATETIMEOFFSET;
--DECLARE @ModuleIterationStatusId BIGINT;
--SET @UserId = 1;
--SET @CreatedTime = SYSDATETIMEOFFSET();	
--SELECT @ModuleIterationStatusId=91151;
BEGIN
SET XACT_ABORT ON;
SET NOCOUNT ON;
SET @FailedRecords = 0;
Create Table #ErrorLogs 
(
	Id BIGINT NOT NULL IDENTITY PRIMARY KEY,
	StagingRootEntityId BIGINT,
	Result NVARCHAR(10),
	Message NVARCHAR(MAX)
);	
CREATE TABLE #CreatedChargeoffs
(
	[Action] NVARCHAR(10) NOT NULL
	,[Id] BIGINT NOT NULL
	,ChargeoffId BIGINT NOT NULL
);
CREATE TABLE #FailedProcessingLogs 
(
			[Action] NVARCHAR(10) NOT NULL,
			[Id] BIGINT NOT NULL,
			[SecurityDepositId] BIGINT NOT NULL
);
CREATE TABLE #CreatedProcessingLogs 
(
			[Id] bigint NOT NULL
);
DECLARE @Module VARCHAR(50) = NULL
SET @Module = (SELECT StgModule.Name FROM StgModule INNER JOIN StgModuleIterationStatus ON StgModule.Id = StgModuleIterationStatus.ModuleId WHERE StgModuleIterationStatus.Id = @ModuleIterationStatusId)
EXEC ResetStagingTempFields @Module , @ToolIdentifier
BEGIN TRY
BEGIN TRANSACTION
Set @ProcessedRecords = 0;
DECLARE @TotalRecordsCount INT = (SELECT ISNULL(COUNT(Id),0) FROM stgChargeoffContract WHERE IsMigrated = 0 AND (ToolIdentifier IS NULL OR ToolIdentifier = @ToolIdentifier) AND IsFailed=0);
Update stgChargeoffContract Set R_ContractId = Contracts.Id
From stgChargeoffContract As CC
Inner Join Contracts On Contracts.SequenceNumber = CC.SequenceNumber
Where CC.IsMigrated=0 AND (CC.ToolIdentifier IS NULL OR CC.ToolIdentifier = @ToolIdentifier) AND CC.IsFailed=0 And CC.SequenceNumber Is NOT Null;
Insert Into #ErrorLogs
Select 
	CC.Id
	,'Error'
	,('Invalid Contract SequenceNumber {'+CC.SequenceNumber+'} for ChargeOff Id {'+CONVERT(nvarchar(MAX),CC.Id)+'}')
From stgChargeoffContract CC
Where IsMigrated = 0 AND (CC.ToolIdentifier IS NULL OR CC.ToolIdentifier = @ToolIdentifier) AND CC.IsFailed=0 AND CC.SequenceNumber IS NOT NULL AND CC.R_ContractId IS NULL;
Insert Into #ErrorLogs
Select 
	CC.Id
	,'Error'
	,('Only Non-Accrual Contracts can be Charged-Off -Invalid Contract SequenceNumber {'+CC.SequenceNumber+'}')
From stgChargeoffContract CC
JOIN Contracts C on CC.R_ContractId=C.Id
Where IsMigrated = 0 AND (CC.ToolIdentifier IS NULL OR CC.ToolIdentifier = @ToolIdentifier) AND C.IsNonAccrual=0
Update stgChargeoffContract Set R_ChargeoffReasonConfigCodeId = ChargeOffReasonCodeConfigs.Id
From stgChargeoffContract As CC
Inner Join ChargeOffReasonCodeConfigs On ChargeOffReasonCodeConfigs.Code = CC.ChargeOffReasonConfigCode And ChargeOffReasonCodeConfigs.IsActive=1
Where CC.IsMigrated=0 AND (CC.ToolIdentifier IS NULL OR CC.ToolIdentifier = @ToolIdentifier) AND CC.IsFailed=0 And CC.ChargeOffReasonConfigCode Is NOT Null;
Insert Into #ErrorLogs
Select 
	CC.Id
	,'Error'
	,('Invalid ChargeoffReasonConfigCode {'+CC.ChargeOffReasonConfigCode+'} for ChargeOff Id {'+CONVERT(nvarchar(MAX),CC.Id)+'}')
From stgChargeoffContract CC
Where CC.IsMigrated=0 AND (CC.ToolIdentifier IS NULL OR CC.ToolIdentifier = @ToolIdentifier) AND CC.IsFailed=0 And CC.ChargeOffReasonConfigCode Is NOT Null And CC.R_ChargeoffReasonConfigCodeId Is Null;

Insert Into #ErrorLogs
Select 
	CC.Id
	,'Error'
	,('Post Date {'+ CONVERT(nvarchar(MAX),CC.PostDate) +'} must fall in its GLFinancialOpenPeriods range associated with Legal Entity')
From stgChargeoffContract CC
JOIN LeaseFinances LF on LF.ContractId = CC.R_ContractId
JOIN GLFinancialOpenPeriods GLOP on GLOP.LegalEntityId = LF.LegalEntityId
Where CC.IsMigrated=0 AND (CC.ToolIdentifier IS NULL OR CC.ToolIdentifier = @ToolIdentifier) AND CC.IsFailed=0 And (CC.PostDate NOT BETWEEN GLOP.FromDate AND GLOP.ToDate)
AND GLOP.IsCurrent = 1 AND LF.IsCurrent = 1;

UPDATE stgChargeoffContract SET IsFailed = 1 WHERE Id IN(SELECT p.StagingRootEntityId FROM #ErrorLogs AS p);
Select 
	ContractId = Contracts.Id
	,AssetId = Case When CC.ContractType = 'Lease' Then LeaseAssets.AssetId
					Else CollateralAssets.AssetId
			   End
	,ChargeoffId = CC.Id
	,CurrencyId = Contracts.CurrencyId
	,CurrencyCode = Currencies.Name
Into #ChargeOffAssetDetails
From stgChargeoffContract As CC
Inner Join Contracts On Contracts.SequenceNumber = CC.SequenceNumber
Left Join LeaseFinances On LeaseFinances.ContractId = Contracts.Id And LeaseFinances.IsCurrent=1
Left Join LoanFinances On LoanFinances.ContractId = Contracts.Id And LoanFinances.IsCurrent=1
Left Join LeaseAssets On LeaseAssets.LeaseFinanceId = LeaseFinances.Id And LeaseAssets.IsActive=1
Left Join CollateralAssets On CollateralAssets.LoanFinanceId = LoanFinances.Id And CollateralAssets.IsActive=1
Left Join ChargeOffReasonCodeConfigs On ChargeOffReasonCodeConfigs.Code = CC.ChargeOffReasonConfigCode
Left Join Currencies On Currencies.Id = Contracts.CurrencyId
Where IsMigrated=0 AND (ToolIdentifier IS NULL OR ToolIdentifier = @ToolIdentifier) And IsFailed=0
Select 
	ContractId
	,GLTransactionType
	,GLConfigurationId
Into #ContractsWithGLConfigIds
From
(
	Select 
		ContractId
		,GLTransactionType = Case When LeaseFinanceDetails.LeaseContractType = 'Operating' Then 'OperatingLeaseChargeoff' Else 'CapitalLeaseChargeoff' End
		,GLConfigurationId
		,ConfigOrder = Row_Number() Over(Partition By ContractId Order By GLConfigurationId)
	From 
	Contracts
	Inner Join LeaseFinances On LeaseFinances.ContractId = Contracts.Id 
		And LeaseFinances.IsCurrent=1
	Inner Join LeaseFinanceDetails On LeaseFinanceDetails.Id = LeaseFinances.Id
	Inner Join LegalEntities On LegalEntities.Id = LeaseFinances.LegalEntityId
	Inner Join GLConfigurations On GLConfigurations.Id = LegalEntities.GLConfigurationId
	Union All
	Select 
		ContractId
		,GLTransactionType = 'LoanChargeoff'
		,GLConfigurationId
		,ConfigOrder = Row_Number() Over(Partition By ContractId Order By GLConfigurationId)
	From 
	Contracts
	Inner Join LoanFinances On LoanFinances.ContractId = Contracts.Id 
		And LoanFinances.IsCurrent=1
	Inner Join LegalEntities On LegalEntities.Id = LoanFinances.LegalEntityId
	Inner Join GLConfigurations On GLConfigurations.Id = LegalEntities.GLConfigurationId
) As Temp_ContractsWithGLConfigurations 
Where ConfigOrder = 1
Select 
	ContractId
	,GLTemplateId
Into #ContractsWithGLTemplates
From
(
	Select 
		ContractId	
		,GLTemplateId = GLTemplates.Id
		,TemplateOrder = Row_Number() Over(Partition By #ContractsWithGLConfigIds.ContractId Order By GLTemplates.Id)
	From #ContractsWithGLConfigIds
	Inner Join GLTemplates On GLTemplates.GLConfigurationId = #ContractsWithGLConfigIds.GLConfigurationId
			And GLTemplates.IsActive=1
	Inner Join GLTransactionTypes On GLTransactionTypes.Name = #ContractsWithGLConfigIds.GLTransactionType
			And GLTransactionTypes.Id = GLTemplates.GLTransactionTypeId
			And GLTransactionTypes.IsActive=1
) As Temp_ContractsWithGlTemplates Where TemplateOrder = 1 
MERGE Chargeoffs 
USING(
		Select CC.*, Currencies.Name As CurrencyCode, #ContractsWithGlTemplates.GLTemplateId As GLTemplateId 
		From stgChargeoffContract As CC 
		Inner Join Contracts On Contracts.SequenceNumber = CC.SequenceNumber
		Left Join Currencies On Currencies.Id = Contracts.CurrencyId
		Left Join #ContractsWithGlTemplates On #ContractsWithGlTemplates.ContractId = Contracts.Id
		where CC.IsMigrated=0 AND (CC.ToolIdentifier IS NULL OR CC.ToolIdentifier = @ToolIdentifier) and CC.IsFailed=0) AS ChargeoffToMigrate
ON 1=0
WHEN NOT MATCHED
THEN
	INSERT
	(
		ChargeOffAmount_Amount ,
		ChargeOffAmount_Currency,
		PostDate,
		ContractType,
		IsActive,
		Status,
		Comment,
		ContractId,
		IsRecovery,
		ReceiptId,
		NetWritedown_Amount,
		NetWritedown_Currency,
		GrossWritedown_Amount,
		GrossWritedown_Currency,
		NetInvestmentWithBlended_Amount,
		NetInvestmentWithBlended_Currency,
		CreatedById,
		CreatedTime,
		ChargeOffReasonCodeConfigId,
		GLTemplateId
	)
	Values
	(
		0.0 ,
		CurrencyCode,
		PostDate,
		ContractType,
		1,
		'SubmittedForApproval',
		Null,
		R_ContractId,
		0,
		Null,
		0.0,
		CurrencyCode,
		0.0,
		CurrencyCode,
		0.0,
		CurrencyCode,
		@UserId
		,@CreatedTime
		,R_ChargeoffReasonConfigCodeId
		,GLTemplateId
	)
	OUTPUT $action, Inserted.Id, ChargeoffToMigrate.Id INTO #CreatedChargeoffs;	
Merge ChargeOffAssetDetails 
USING (
		SELECT CAD.*, #CreatedChargeoffs.Id As ChargedOffId
		FROM #ChargeoffAssetDetails As CAD
		INNER JOIN #CreatedChargeoffs ON #CreatedChargeoffs.ChargeoffId = CAD.ChargeoffId
	  ) AS CustomerContactToMigrate
ON 1=0
WHEN NOT MATCHED
THEN
	INSERT
	(
		IsActive
		,NetWriteDown_Amount
		,NetWriteDown_Currency
		,NetInvestmentWithBlended_Amount
		,NetInvestmentWithBlended_Currency
		,AssetId
		,ChargeOffId
		,CreatedById
		,CreatedTime
	)
	Values
	(
		1
		,0.0
		,CurrencyCode
		,0.0
		,CurrencyCode
		,AssetId
		,ChargedOffId
		,@UserId
		,@CreatedTime
	);
	        MERGE stgProcessingLog AS ProcessingLog
			USING 
			(SELECT ChargeoffId FROM #CreatedChargeoffs) AS ProcessedChargeoffs
			ON (ProcessingLog.StagingRootEntityId = ProcessedChargeoffs.ChargeoffId AND ProcessingLog.ModuleIterationStatusId = @ModuleIterationStatusId)
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
					ProcessedChargeoffs.ChargeoffId
				   ,@UserId
				   ,@CreatedTime
				   ,@ModuleIterationStatusId
				)
				OUTPUT  Inserted.Id INTO #CreatedProcessingLogs;
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
			FROM
				#CreatedProcessingLogs
MERGE stgProcessingLog AS ProcessingLog
USING (SELECT DISTINCT StagingRootEntityId FROM #ErrorLogs ) AS ErrorChargeOff
		ON (ProcessingLog.StagingRootEntityId = ErrorChargeOff.StagingRootEntityId AND ProcessingLog.ModuleIterationStatusId = @ModuleIterationStatusId)
		WHEN MATCHED THEN
			UPDATE SET UpdatedTime = @CreatedTime,UpdatedById = @UserId
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
				ErrorChargeOff.StagingRootEntityId
				,@UserId
				,@CreatedTime
				,@ModuleIterationStatusId
			)
		OUTPUT $action, Inserted.Id, ErrorChargeOff.StagingRootEntityId INTO #FailedProcessingLogs;
		INSERT INTO stgProcessingLogDetail
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
		FROM #ErrorLogs
		JOIN #FailedProcessingLogs ON #ErrorLogs.StagingRootEntityId = #FailedProcessingLogs.SecurityDepositId;	
		UPDATE stgChargeoffContract SET R_ChargeoffId = #CreatedChargeoffs.Id
		From stgChargeoffContract As CC
		Inner Join #CreatedChargeoffs On #CreatedChargeoffs.ChargeoffId = CC.Id;
		DROP TABLE #ChargeOffAssetDetails;
		DROP TABLE #ContractsWithGLConfigIds;
        DROP TABLE #ContractsWithGLTemplates;		
COMMIT TRANSACTION
END TRY
BEGIN CATCH
	DECLARE @ErrorMessage Nvarchar(max);
	DECLARE @ErrorLine Nvarchar(max);
	DECLARE @ErrorSeverity INT;
	DECLARE @ErrorState INT;
	DECLARE @ErrorLogs ErrorMessageList;
	DECLARE @ModuleName Nvarchar(max) = 'MigrateChargeOff'
	Insert into @ErrorLogs(StagingRootEntityId, ModuleIterationStatusId, Message,Type) VALUES (0,@ModuleIterationStatusId,ERROR_MESSAGE(),'Error')
	SELECT  @ErrorSeverity = ERROR_SEVERITY(), @ErrorState = ERROR_STATE(),@ErrorLine=ERROR_LINE(),@ErrorMessage=ERROR_MESSAGE()
	IF (XACT_STATE()) = -1  
	BEGIN  
		ROLLBACK TRANSACTION;
		EXEC [dbo].[ExceptionLog] @ErrorLogs,@ErrorLine,@UserId,@CreatedTime,@ModuleName
		set @FailedRecords = @FailedRecords+@TotalRecordsCount;
	END;  
	ELSE IF (XACT_STATE()) = 1  
	BEGIN
		COMMIT TRANSACTION;
		RAISERROR (@ErrorMessage,@ErrorSeverity, @ErrorState);     
	END;
	ELSE
	BEGIN
		EXEC [dbo].[ExceptionLog] @ErrorLogs,@ErrorLine,@UserId,@CreatedTime,@ModuleName
        SET @FailedRecords = @FailedRecords+@TotalRecordsCount;
	END;
END CATCH
SET @FailedRecords = @FailedRecords+(SELECT COUNT(DISTINCT StagingRootEntityId) FROM #ErrorLogs)
SET @ProcessedRecords = @ProcessedRecords + @TotalRecordsCount;	
DROP TABLE #ErrorLogs;
DROP TABLE #CreatedChargeoffs;
DROP TABLE #FailedProcessingLogs;
DROP TABLE #CreatedProcessingLogs;
SET NOCOUNT OFF;
SET XACT_ABORT OFF;
END

GO
