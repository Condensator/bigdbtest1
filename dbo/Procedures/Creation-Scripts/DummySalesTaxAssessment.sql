SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[DummySalesTaxAssessment]
(	
    @UserId BIGINT ,
	@ModuleIterationStatusId BIGINT , 
	@CreatedTime DATETIMEOFFSET = NULL,
	@ProcessedRecords BIGINT OUT,
	@FailedRecords BIGINT OUT,
	@ToolIdentifier INT
)
AS
BEGIN	
SET XACT_ABORT ON
SET NOCOUNT ON
SET ANSI_WARNINGS ON
--DECLARE @CreatedTime DATETIMEOFFSET = NULL;
--DECLARE	@ProcessedRecords BIGINT = 0;
--DECLARE	@FailedRecords BIGINT =0;
--DECLARE @UserId BIGINT= 1; 
--DECLARE @ModuleIterationStatusId  BIGINT= 1;
IF(@CreatedTime IS NULL)
SET @CreatedTime = SYSDATETIMEOFFSET();
SET @FailedRecords = 0
SET @ProcessedRecords = 0
DECLARE @MaxReceivableId INT = 0
DECLARE @TotalRecordsCount INT;
Declare @count INT = 1;
Declare @BatchCount INT = 1;
Select @TotalRecordsCount = ISNULL(COUNT(Id), 0) FROM stgSalesTaxAssessment WHERE IsMigrated = 0 AND IsFailed = 0 AND (@ToolIdentifier = ToolIdentifier OR @ToolIdentifier IS NULL  )
DECLARE @Module VARCHAR(50) = NULL
SET @Module = (SELECT StgModule.Name FROM StgModule INNER JOIN StgModuleIterationStatus ON StgModule.Id = StgModuleIterationStatus.ModuleId WHERE StgModuleIterationStatus.Id = @ModuleIterationStatusId)
EXEC ResetStagingTempFields @Module,@ToolIdentifier

SELECT EntityId ,MAX(LegalEntityId) AS LegalEntityId ,EntityType 
INTO #ReceivableTemp FROM Receivables GROUP BY EntityId , EntityType 

CREATE TABLE #ErrorLogs
(
	 [Msg] Nvarchar(MAX)
	,[EntityId] BigInt
);	
CREATE TABLE #FailedProcessingLogs
(
	 [Action] NVARCHAR(10) NOT NULL
	,[Id] BIGINT NOT NULL
	,[SalesTaxId] BIGINT NOT NULL
);
Create Table #EligibleReceivableCount
(
SalesTaxId BIGINT,
ReceivableCount BIGINT
);
CREATE TABLE #SalesTaxAssessmentSubset
(
Id BIGINT ,
SequenceNumber nvarchar(80),
ProcessThroughDate date,
GLTemplateName nvarchar(80),
R_ContractId BigInt,
R_GLTemplateId BigInt,
CustomerPartyNumber nvarchar(80),
EntityType nvarchar(4),
R_CustomerId BigInt)

CREATE NONCLUSTERED INDEX [IX_DummySalesTaxAssessmentSubsetId] ON #SalesTaxAssessmentSubset ([ID]) 

IF(@TotalRecordsCount > 0)
BEGIN
	WHILE(@count > 0)
	BEGIN	
	BEGIN TRY
	
DELETE FROM #SalesTaxAssessmentSubset;
--SET IDENTITY_INSERT #SalesTaxAssessmentSubset ON;
INSERT INTO #SalesTaxAssessmentSubset 
(Id,SequenceNumber,ProcessThroughDate,GLTemplateName,R_ContractId,R_GLTemplateId,CustomerPartyNumber,EntityType,R_CustomerId)
SELECT DISTINCT TOP 10000
Id,SequenceNumber,ProcessThroughDate,GLTemplateName,R_ContractId,R_GLTemplateId,CustomerPartyNumber,EntityType,R_CustomerId
FROM 
	stgSalesTaxAssessment SalesTax WITH(NOLOCK)
WHERE 
	SalesTax.IsMigrated=0 AND SalesTax.IsFailed=0 AND (@ToolIdentifier = ToolIdentifier OR @ToolIdentifier IS NULL );
--SET IDENTITY_INSERT #SalesTaxAssessmentSubset OFF;
SELECT @BatchCount = Count(*) from #SalesTaxAssessmentSubset

--select * from #SalesTaxAssessmentSubset
--========================================Validations==========================================================	
UPDATE #SalesTaxAssessmentSubset SET R_ContractId = Contracts.Id
FROM 
	stgSalesTaxAssessment SalesTaxAssessment WITH(NOLOCK)
	INNER JOIN #SalesTaxAssessmentSubset WITH(NOLOCK) 
		ON #SalesTaxAssessmentSubset.Id = SalesTaxAssessment.Id
	INNER JOIN Contracts WITH(NOLOCK)
		ON SalesTaxAssessment.SequenceNumber = Contracts.SequenceNumber
WHERE 
	SalesTaxAssessment.IsMigrated = 0 AND SalesTaxAssessment.EntityType = 'CT'
INSERT INTO #ErrorLogs
SELECT 
'Invalid SequenceNumber {'+ISNULL(STA.SequenceNumber,'NULL')+'} for SalesTaxAssessment Id { '+ CONVERT(VARCHAR,STA.Id) +' }'
,STA.Id 
FROM stgSalesTaxAssessment STA
INNER JOIN #SalesTaxAssessmentSubset WITH (NOLOCK) ON #SalesTaxAssessmentSubset.Id = STA.Id
WHERE STA.IsMigrated = 0 AND #SalesTaxAssessmentSubset.R_ContractId IS NULL AND STA.SequenceNumber IS NOT NULL AND STA.EntityType = 'CT'
UPDATE #SalesTaxAssessmentSubset SET R_CustomerId = Customers.Id
FROM 
	stgSalesTaxAssessment SalesTaxAssessment WITH(NOLOCK)
	INNER JOIN #SalesTaxAssessmentSubset WITH (NOLOCK) 
		ON #SalesTaxAssessmentSubset.Id = SalesTaxAssessment.Id
	INNER JOIN Parties WITH(NOLOCK)
		ON SalesTaxAssessment.CustomerPartyNumber = Parties.PartyNumber
	INNER JOIN Customers WITH(NOLOCK)
		ON Parties.Id = Customers.Id
WHERE 
	SalesTaxAssessment.IsMigrated = 0 AND SalesTaxAssessment.EntityType = 'CU'
INSERT INTO #ErrorLogs
SELECT 
'Invalid Customer Number {'+ISNULL(STA.CustomerPartyNumber,'NULL')+'} for SalesTaxAssessment Id { '+ CONVERT(VARCHAR,STA.Id) +' }'
,STA.Id 
FROM stgSalesTaxAssessment STA WITH (NOLOCK)
INNER JOIN #SalesTaxAssessmentSubset WITH (NOLOCK) ON #SalesTaxAssessmentSubset.Id = STA.Id
WHERE STA.IsMigrated = 0 AND #SalesTaxAssessmentSubset.R_Customerid IS NULL AND STA.CustomerPartyNumber IS NOT NULL AND STA.EntityType = 'CU'
UPDATE #SalesTaxAssessmentSubset SET R_GLTemplateId = GLTemplates.Id
FROM stgSalesTaxAssessment ST WITH(NOLOCK)
INNER JOIN #SalesTaxAssessmentSubset WITH (NOLOCK) ON #SalesTaxAssessmentSubset.Id = ST.Id
INNER JOIN GLTemplates WITH(NOLOCK) ON GLTemplates.Name = ST.GLTemplateName
INNER JOIN GLTransactionTypes WITH(NOLOCK) ON GLTemplates.GLTransactionTypeId = GLTransactionTypes.Id
WHERE GLTransactionTypes.IsActive = 1 AND GLTemplates.IsActive = 1 AND ST.IsMigrated = 0 AND ST.GLTemplateName IS NOT NULL

UPDATE #SalesTaxAssessmentSubset SET R_GLTemplateId = GLT.Id
FROM stgSalesTaxAssessment SalesTax WITH(NOLOCK)
INNER JOIN #SalesTaxAssessmentSubset WITH (NOLOCK) ON #SalesTaxAssessmentSubset.Id = SalesTax.Id        
INNER JOIN #ReceivableTemp R WITH(NOLOCK) ON ((R.EntityId = #SalesTaxAssessmentSubset.R_ContractId AND R.EntityType ='CT') OR (R.EntityId = #SalesTaxAssessmentSubset.R_CustomerId AND R.EntityType ='CU'))--  AND R.DueDate <= SalesTax.ProcessThroughDate   
INNER JOIN LegalEntities LE WITH(NOLOCK) ON LE.Id = R.LegalEntityId AND LE.Status = 'Active'
INNER JOIN GLConfigurations GLC  WITH(NOLOCK) ON GLC.Id = LE.GLConfigurationId  
INNER JOIN GLTemplates GLT WITH(NOLOCK) ON GLC.Id = GLT.GLConfigurationId AND GLT.IsActive = 1 
INNER JOIN GLTransactionTypes GTT WITH(NOLOCK) ON GLT.GLTransactionTypeId = GTT.Id AND GTT.IsActive = 1 AND GTT.Name = 'SalesTax'
WHERE SalesTax.GLTemplateName IS NULL AND SalesTax.IsMigrated = 0
 
UPDATE #SalesTaxAssessmentSubset SET R_GLTemplateId = GLT.Id
FROM stgSalesTaxAssessment SalesTax WITH(NOLOCK)
INNER JOIN #SalesTaxAssessmentSubset WITH (NOLOCK) ON #SalesTaxAssessmentSubset.Id = SalesTax.Id       
INNER JOIN #ReceivableTemp R WITH (NOLOCK) ON ((R.EntityId = #SalesTaxAssessmentSubset.R_ContractId AND R.EntityType ='CT') OR (R.EntityId = #SalesTaxAssessmentSubset.R_CustomerId AND R.EntityType ='CU'))--  AND R.DueDate <= SalesTax.ProcessThroughDate   
INNER JOIN LegalEntities LE WITH(NOLOCK) ON LE.Id = R.LegalEntityId AND LE.Status = 'Active'
INNER JOIN GLConfigurations GLC WITH(NOLOCK) ON GLC.Id = LE.GLConfigurationId  
INNER JOIN GLTemplates GLT WITH(NOLOCK) ON GLC.Id = GLT.GLConfigurationId AND GLT.IsActive = 1 AND GLC.Name = SalesTax.GLTemplateName
INNER JOIN GLTransactionTypes GTT WITH(NOLOCK) ON GLT.GLTransactionTypeId = GTT.Id AND GTT.IsActive = 1
WHERE SalesTax.GLTemplateName IS NOT NULL AND SalesTax.IsMigrated = 0

DELETE FROM #EligibleReceivableCount;

INSERT INTO #EligibleReceivableCount
SELECT SalesTax.Id AS SalesTaxId,  Count(R.Id) ReceivableCount
FROM stgSalesTaxAssessment SalesTax WITH (NOLOCK)
INNER JOIN #SalesTaxAssessmentSubset WITH (NOLOCK) ON #SalesTaxAssessmentSubset.Id = SalesTax.Id
INNER JOIN Receivables R WITH (NOLOCK) ON R.EntityId = #SalesTaxAssessmentSubset.R_CustomerId  AND R.EntityType ='CU' AND R.DueDate <= SalesTax.ProcessThroughDate
INNER JOIN ReceivableDetails RD WITH (NOLOCK) ON R.Id = RD.ReceivableId AND RD.IsTaxAssessed = 0
GROUP BY SalesTax.Id

INSERT INTO #EligibleReceivableCount
SELECT SalesTax.Id AS SalesTaxId,  Count(R.Id) ReceivableCount
FROM stgSalesTaxAssessment SalesTax WITH (NOLOCK)
INNER JOIN #SalesTaxAssessmentSubset WITH (NOLOCK) ON #SalesTaxAssessmentSubset.Id = SalesTax.Id
INNER JOIN Receivables R WITH (NOLOCK) ON R.EntityId = #SalesTaxAssessmentSubset.R_ContractId  AND R.EntityType ='CT' AND R.DueDate <= SalesTax.ProcessThroughDate
INNER JOIN ReceivableDetails RD WITH (NOLOCK) ON R.Id = RD.ReceivableId AND RD.IsTaxAssessed = 0
GROUP BY SalesTax.Id


INSERT INTO #ErrorLogs
SELECT 
'Invalid GL Template Name for SalesTaxAssessment Id { '+ CONVERT(VARCHAR,ST.Id) +' }' 
,ST.Id
FROM stgSalesTaxAssessment ST WITH (NOLOCK)
INNER JOIN #SalesTaxAssessmentSubset WITH (NOLOCK) ON #SalesTaxAssessmentSubset.Id = ST.Id
WHERE #SalesTaxAssessmentSubset.R_GLTemplateId IS NULL AND ST.IsMigrated = 0 AND ST.GLTemplateName IS NOT NULL

INSERT INTO #ErrorLogs
SELECT 
'GL Template of Sales Tax does not exist for SalesTaxAssessment Id { '+ CONVERT(VARCHAR,ST.Id) +' }' 
,ST.Id
FROM stgSalesTaxAssessment ST WITH (NOLOCK)
INNER JOIN #SalesTaxAssessmentSubset WITH (NOLOCK) ON #SalesTaxAssessmentSubset.Id = ST.Id
INNER JOIN #EligibleReceivableCount WITH (NOLOCK) ON #EligibleReceivableCount.SalesTaxId = #SalesTaxAssessmentSubset.Id 
WHERE #SalesTaxAssessmentSubset.R_GLTemplateId IS NULL AND ST.IsMigrated = 0 AND ST.GLTemplateName IS NULL AND #EligibleReceivableCount.ReceivableCount > 0

INSERT INTO #ErrorLogs
SELECT 
'Tax Prayer cannot be NULL for LegalEntity { '+ LE.Name +' }' +' LegalEntityNumber '+'{ '+LE.LegalEntityNumber+' }'
,SalesTax.Id
FROM 
stgSalesTaxAssessment SalesTax WITH (NOLOCK)
INNER JOIN #SalesTaxAssessmentSubset WITH (NOLOCK) ON #SalesTaxAssessmentSubset.Id = SalesTax.Id
INNER JOIN Receivables R ON #SalesTaxAssessmentSubset.R_ContractId = R.EntityId AND R.EntityType = 'CT'
INNER JOIN LegalEntities LE WITH (NOLOCK) ON LE.Id = R.LegalEntityId AND LE.Status = 'Active'
WHERE 
LE.TaxPayer IS NULL

UPDATE stgSalesTaxAssessment SET R_ContractId = SalesTaxAssessment.R_ContractId,R_CustomerId = SalesTaxAssessment.R_CustomerId, R_GLTemplateId = SalesTaxAssessment.R_GLTemplateId
FROM 
	#SalesTaxAssessmentSubset SalesTaxAssessment WITH(NOLOCK)
	INNER JOIN stgSalesTaxAssessment WITH (NOLOCK) 
		ON stgSalesTaxAssessment.Id = SalesTaxAssessment.Id

--========================================End Validations=====================================================
--========================================Log Errors==========================================================			
	MERGE stgProcessingLog As ProcessingLog
	USING (SELECT DISTINCT EntityId StagingRootEntityId
			FROM
			#ErrorLogs WITH (NOLOCK)
			) As ErrorReceipts
	ON (ProcessingLog.StagingRootEntityId = ErrorReceipts.StagingRootEntityId AND ProcessingLog.ModuleIterationStatusId = @ModuleIterationStatusId)
	WHEN MATCHED Then
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
			Errorreceipts.StagingRootEntityId
			,@UserId
			,@CreatedTime
			,@ModuleIterationStatusId
		)
	OUTPUT $action, Inserted.Id,ErrorReceipts.StagingRootEntityId INTO #FailedProcessingLogs;	
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
		#ErrorLogs.Msg
		,'Error'
		,@UserId
		,@CreatedTime
		,#FailedProcessingLogs.Id
	FROM #ErrorLogs
	INNER JOIN #FailedProcessingLogs WITH (NOLOCK) ON #ErrorLogs.EntityId = #FailedProcessingLogs.SalesTaxId;	
	UPDATE stgSalesTaxAssessment Set IsFailed = 1 FROM stgSalesTaxAssessment WITH(NOLOCK)
	JOIN #ErrorLogs p WITH(NOLOCK) on stgSalesTaxAssessment.Id = p.EntityId  
			
					--========================================End ErrorLogs==========================================================
BEGIN TRANSACTION
CREATE TABLE #CreatedProcessingLogs
(
	 [MergeAction] NVARCHAR(20)
	,[InsertedId] BIGINT
	,[SalesTaxId] BIGINT
)

SELECT  
	 DISTINCT Receivables.Id
	,SalesTax.Id AS SalesTaxID
	,Receivables.EntityId
	,SalesTaxRemittanceMethod
	,Receivables.TotalAmount_Currency Currency 
	,Receivables.EntityType
INTO #ReceivableIds
FROM 
	#SalesTaxAssessmentSubset SalesTax
	INNER JOIN Contracts 
		ON SalesTax.R_ContractId = Contracts.Id
	INNER JOIN Receivables  
		ON SalesTax.R_ContractId = Receivables.EntityId 
		AND Receivables.EntityType = 'CT'
		AND SalesTax.EntityType = 'CT'
	INNER JOIN ReceivableDetails 
		ON ReceivableDetails.ReceivableId = Receivables.Id AND ReceivableDetails.IsTaxAssessed = 0  AND ReceivableDetails.IsActive = 1
WHERE 
	Receivables.DueDate <= SalesTax.ProcessThroughDate AND Receivables.IsActive = 1 
INSERT INTO #ReceivableIds
SELECT  
	DISTINCT Receivables.Id
	,SalesTax.Id AS SalesTaxID
	,Receivables.EntityId
	,'CashBased' SalesTaxRemittanceMethod 
	,Receivables.TotalAmount_Currency Currency 
	,Receivables.EntityType
FROM 
	#SalesTaxAssessmentSubset SalesTax
	INNER JOIN Customers 
		ON SalesTax.R_CustomerId = Customers.Id
	INNER JOIN Receivables 
		ON SalesTax.R_CustomerId = Receivables.EntityId 
		AND Receivables.EntityType = 'CU'
		AND SalesTax.EntityType = 'CU'
	INNER JOIN ReceivableDetails 
		ON ReceivableDetails.ReceivableId = Receivables.Id AND ReceivableDetails.IsTaxAssessed = 0  AND ReceivableDetails.IsActive = 1
WHERE 
	Receivables.DueDate <= SalesTax.ProcessThroughDate AND Receivables.IsActive = 1


UPDATE ReceivableDetails SET IsTaxAssessed = 1 
FROM
ReceivableDetails JOIN #ReceivableIds ReceivableIds ON ReceivableIds.Id = ReceivableDetails.ReceivableId

SELECT
	ROW_NUMBER() OVER (PARTITION BY Receivables.EntityId,ReceivableDetails.AssetId ORDER BY Receivables.DueDate,LeasePaymentSchedules.Id) RowNumber,
	ReceivableDetails.Id [ReceivableDetailId],
	Receivables.EntityId,
	CASE WHEN LeasePaymentSchedules.PaymentType NOT IN ('DownPayment') THEN ReceivableDetails.Amount_Amount 
		ELSE 0.00 
		END [Amount_Amount],
	ReceivableDetails.Amount_Currency,
	ReceivableDetails.AssetId,
	LeasePaymentSchedules.PaymentType,
	LeasePaymentSchedules.PaymentNumber,
	Locations.StateId
INTO #ReceivableDetails_Temp 
FROM 
	Receivables
	INNER JOIN #ReceivableIds
		ON #ReceivableIds.Id = Receivables.Id
		AND Receivables.EntityType = 'CT'
	INNER JOIN ReceivableDetails 
		ON ReceivableDetails.ReceivableId = Receivables.Id
		AND ReceivableDetails.IsActive = 1 
		AND ReceivableDetails.IsTaxAssessed = 1
	INNER JOIN Contracts 
		ON Contracts.Id = Receivables.EntityId
	INNER JOIN LeaseFinances 
		ON LeaseFinances.ContractId = Contracts.Id 
		AND LeaseFinances.IsCurrent = 1 
	INNER JOIN  LeasePaymentSchedules 
		ON LeasePaymentSchedules.Id = Receivables.PaymentScheduleId
	INNER JOIN AssetLocations
		ON AssetLocations.AssetId = ReceivableDetails.AssetId
		AND AssetLocations.IsActive =1 
		AND AssetLocations.IsCurrent =1
	INNER JOIN Locations
		ON Locations.Id = AssetLocations.LocationId
	INNER JOIN States
		ON States.Id = Locations.StateId
Where States.IsMaxTaxApplicable = 1
ORDER BY 
	Receivables.EntityId
	,Receivables.DueDate
	,Receivables.PaymentScheduleId
	,Receivables.Id
	,ReceivableDetails.Id;
SELECT 
	RD.Amount_Amount AS RevenueBilledToDate_Amount
	,RD.Amount_Currency AS RevenueBilledToDate_Currency
	,CASE WHEN ((RD.RowNumber = 1 AND RD.PaymentNumber = 1) OR  (RD.PaymentType = 'DownPayment')) THEN 0.00   
		  ELSE ISNULL((SELECT SUM(CRD.Amount_Amount) FROM #ReceivableDetails_Temp CRD   
		 WHERE RD.AssetId = CRD.AssetId AND RD.StateId = CRD.StateId AND CRD.RowNumber < RD.RowNumber),0.00) END CumulativeAmount_Amount
	,RD.Amount_Currency  AS CumulativeAmount_Currency
	,RD.EntityId AS ContractId 
	,RD.ReceivableDetailId
	,RD.AssetId
	,RD.StateId
INTO #AmountBilledRentalReceivableDetail
FROM 
	#ReceivableDetails_Temp RD;
INSERT INTO VertexBilledRentalReceivables
(
    RevenueBilledToDate_Amount
    ,RevenueBilledToDate_Currency
    ,CumulativeAmount_Amount
    ,CumulativeAmount_Currency
    ,IsActive
    ,CreatedById
    ,CreatedTime
    ,ContractId
    ,ReceivableDetailId
    ,AssetId
    ,StateId
)
SELECT
    RevenueBilledToDate_Amount
    ,RevenueBilledToDate_Currency
    ,CumulativeAmount_Amount
    ,CumulativeAmount_Currency
    ,1 AS [IsActive]
    ,1 AS [CreatedById]
    ,SYSDATETIMEOFFSET() AS [CreatedTime]
    ,ContractId
    ,ReceivableDetailId
    ,AssetId
    ,StateId
FROM
#AmountBilledRentalReceivableDetail	


MERGE stgProcessingLog AS ProcessingLog
USING (SELECT DISTINCT SalesTaxID AS Id FROM #ReceivableIDs) AS Processed
ON (ProcessingLog.StagingRootEntityId = Processed.Id AND ProcessingLog.ModuleIterationStatusId = @ModuleIterationStatusId)
WHEN MATCHED THEN
UPDATE SET UpdatedTime = @CreatedTime
WHEN NOT MATCHED THEN
INSERT
	(StagingRootEntityId
	,CreatedById
	,CreatedTime
	,ModuleIterationStatusId)
VALUES
	(Processed.Id
	,@UserId
	,@CreatedTime
	,@ModuleIterationStatusId)
OUTPUT $action, Inserted.Id, Processed.Id INTO #CreatedProcessingLogs;
INSERT INTO stgProcessingLogDetail
	(Message
	,Type
	,CreatedById
	,CreatedTime	
	,ProcessingLogId)
SELECT
	'Sales Tax assessed till ' + Convert(nvarchar(50),ISNULL(ProcessthroughDate,@CreatedTime)) + ', Total '+ Convert(nvarchar(50),ISNULL(TotalReceivablesProcessed,0)) +' Receivable(s) assessed' + ' for Entity: ' + Entity + ' Entity Type: ' + EntityType
	,'Information'
	,@UserId
	,@CreatedTime
	,InsertedId
FROM
#CreatedProcessingLogs CreatedProcessingLogs
LEFT JOIN 
(SELECT SalesTaxId, COUNT(*) TotalReceivablesProcessed, salesTax.ProcessthroughDate, ISNULL(salesTax.SequenceNumber,salesTax.CustomerPartyNumber) Entity,salesTax.EntityType
    FROM #ReceivableIds 
	LEFT JOIN stgSalesTaxAssessment salesTax ON #ReceivableIds.SalesTaxId = salesTax.Id
	GROUP BY SalesTaxId, salesTax.ProcessthroughDate, salesTax.SequenceNumber,salesTax.CustomerPartyNumber,salestax.EntityType
)AS ReceivablesProcessed
ON CreatedProcessingLogs.SalesTaxId = ReceivablesProcessed.SalesTaxId
DELETE FROM #CreatedProcessingLogs;
MERGE stgProcessingLog AS ProcessingLog
USING (SELECT Id from #SalesTaxAssessmentSubset Where Id not in (SELECT DISTINCT SalesTaxId AS Id FROM #ReceivableIds) AND ID NOt in (Select DISTINCT p.EntityId ID FROM #errorLogs As p)) AS Processed
ON (ProcessingLog.StagingRootEntityId = Processed.Id AND ProcessingLog.ModuleIterationStatusId = @ModuleIterationStatusId)
WHEN MATCHED THEN
UPDATE SET UpdatedTime = @CreatedTime
WHEN NOT MATCHED THEN
INSERT
	(StagingRootEntityId
	,CreatedById
	,CreatedTime
	,ModuleIterationStatusId)
VALUES
	(Processed.Id
	,@UserId
	,@CreatedTime
	,@ModuleIterationStatusId)
OUTPUT $action, Inserted.Id, Processed.Id INTO #CreatedProcessingLogs;
INSERT INTO stgProcessingLogDetail
	(Message
	,Type
	,CreatedById
	,CreatedTime	
	,ProcessingLogId)
SELECT
	'No receivable(s) found as of ' + Convert(nvarchar(50),ISNULL(ProcessThroughDate,@CreatedTime)) + ' for Entity: ' + ISNULL(SequenceNumber,CustomerPartyNumber) + ' Entity Type: ' + salesTax.EntityType
	,'Warning'
	,@UserId
	,@CreatedTime
	,InsertedId
FROM
#CreatedProcessingLogs CreatedProcessingLogs
LEFT JOIN stgSalesTaxAssessment salesTax ON CreatedProcessingLogs.SalesTaxId = salesTax.Id
WHERE
salesTax.IsMigrated = 0 AND salesTax.IsFailed = 0 AND (@ToolIdentifier = salesTax.ToolIdentifier OR @ToolIdentifier IS NULL  );
UPDATE stgSalesTaxAssessment SET IsMigrated = 1
FROM
	stgSalesTaxAssessment WITH(NOLOCK)
	INNER JOIN #SalesTaxAssessmentSubset  WITH(NOLOCK)
		ON stgSalesTaxAssessment.Id = #SalesTaxAssessmentSubset.Id
WHERE 
	stgSalesTaxAssessment.IsMigrated = 0 AND stgSalesTaxAssessment.IsFailed = 0
SET @count = (select count(*) FROM stgSalesTaxAssessment Where IsMigrated =0 AND IsFailed = 0 AND (@ToolIdentifier = ToolIdentifier OR @ToolIdentifier IS NULL  ));	
DROP TABLE #CreatedProcessingLogs
DROP TABLE #ReceivableIds
DROP TABLE #AmountBilledRentalReceivableDetail
DROP TABLE #ReceivableDetails_Temp
COMMIT TRANSACTION
END TRY
BEGIN CATCH
	DECLARE @ErrorMessage Nvarchar(max);
	DECLARE @ErrorLine Nvarchar(max);
	DECLARE @ErrorSeverity INT;
	DECLARE @ErrorState INT;
	DECLARE @ErrorLogs ErrorMessageList;
	DECLARE @ModuleName Nvarchar(max) = 'DummySalesTaxAssessment'
	Insert into @ErrorLogs(StagingRootEntityId, ModuleIterationStatusId, Message,Type) VALUES (0,@ModuleIterationStatusId,ERROR_MESSAGE(),'Error')
	SELECT  @ErrorSeverity = ERROR_SEVERITY(), @ErrorState = ERROR_STATE(),@ErrorLine=ERROR_LINE(),@ErrorMessage=ERROR_MESSAGE()
	IF (XACT_STATE()) = -1  
	BEGIN  
		ROLLBACK TRANSACTION;
		EXEC [dbo].[ExceptionLog] @ErrorLogs,@ErrorLine,@UserId,@CreatedTime,@ModuleName
		SET @FailedRecords = @FailedRecords+@BatchCount;
	END;  
	ELSE IF (XACT_STATE()) = 1  
	BEGIN
		COMMIT TRANSACTION;
		RAISERROR (@ErrorMessage,@ErrorSeverity, @ErrorState);     
	END; 
	ELSE
	BEGIN
		EXEC [dbo].[ExceptionLog] @ErrorLogs,@ErrorLine,@UserId,@CreatedTime,@ModuleName
        SET @FailedRecords = @FailedRecords+@BatchCount;
	END;
	UPDATE stgSalesTaxAssessment SET IsFailed = 1 
	FROM stgSalesTaxAssessment WITH(NOLOCK)
	INNER JOIN #SalesTaxAssessmentSubset WITH(NOLOCK) ON stgSalesTaxAssessment.Id = #SalesTaxAssessmentSubset.Id
    WHERE stgSalesTaxAssessment.IsMigrated = 0 AND stgSalesTaxAssessment.IsFailed = 0
    SET @count = (select count(*) FROM stgSalesTaxAssessment Where IsMigrated =0 AND IsFailed = 0 AND (@ToolIdentifier = ToolIdentifier OR @ToolIdentifier IS NULL));
END CATCH		
END
SET @FailedRecords = @FailedRecords + ISNULL((SELECT COUNT(DISTINCT EntityId) FROM #ErrorLogs),0);
SET @ProcessedRecords = @ProcessedRecords + @TotalRecordsCount;
END
DROP TABLE #ErrorLogs
DROP TABLE #FailedProcessingLogs
DROP TABLE #ReceivableTemp
DROP TABLE #EligibleReceivableCount
DROP TABLE #SalesTaxAssessmentSubset
SET NOCOUNT OFF
SET XACT_ABORT OFF
SET ANSI_WARNINGS OFF
END

GO
