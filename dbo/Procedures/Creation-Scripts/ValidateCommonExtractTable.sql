SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROC [dbo].[ValidateCommonExtractTable]  
(  
	@JobStepInstanceId   BIGINT,
	@GLConfigurationId BIGINT,
	@Filename NVARCHAR(200),
	@ReceiptBatchId BIGINT NULL, 
	@CreateUnallocatedReceipt BIT
)  
AS  
BEGIN  
	SET NOCOUNT OFF;  
	DECLARE @errorMessage NVARCHAR(400)  
	
	BEGIN TRY
		SELECT   
		CRE.Id 
		,LegalEntityId
		,EntityType
		,LineOfBusinessId
		,CostCenterId
		,ReceiptAmount 
		,CashType
		,CurrencyId
		,EntityId
		,CRE.IsValid 
		,LegalEntityNumber
		,BankAccountId
		INTO #CommonExternalReceipt_Extract  
		FROM MT940File_Dump MFD
		JOIN CommonExternalReceipt_Extract CRE
				ON MFD.Id = CRE.DumpId
		WHERE MFD.JobStepInstanceId =@JobStepInstanceId 
		AND CRE.JobStepInstanceId=@JobStepInstanceId
		AND MFD.FileName = @Filename; 

		DECLARE 
		@BatchLegalEntityNumber NVARCHAR(20)
		,@OutstandingInvoiceAmt DECIMAL(16,2)
		,@BatchCurrency NVARCHAR(3)
		,@date DATE = GETDATE()

		--Validate for LockBox Params when there is no record			
			INSERT INTO ReceiptFileHandlerErrorMessages(RowId,ErrorMessage,SourceTable,SourceId,JobStepInstanceId,CreatedById,CreatedTime)
			SELECT
			NULL 
			,CONCAT('Legal Entity',#Extract.LegalEntityNumber,' is not configured in the LockboxDefaultParameterConfigs table.Please configure the legal entity in order to create the receipt') 
			,'CommonExternalReceipt_Extract' 
			,#Extract.Id 
			,@JobStepInstanceId 
			,1 
			,@date
			FROM #CommonExternalReceipt_Extract #Extract 
			LEFT JOIN LockboxDefaultParameterConfigs LDPC ON LDPC.LegalEntityId = #Extract.LegalEntityId
			WHERE (#Extract.EntityType = 'Customer' OR #Extract.EntityType IS NULL) 
			AND LDPC.LegalEntityId IS NULL

			UPDATE #Extract SET IsValid = 0
			FROM #CommonExternalReceipt_Extract #Extract 
			LEFT JOIN LockboxDefaultParameterConfigs LDPC ON LDPC.LegalEntityId = #Extract.LegalEntityId
			WHERE (#Extract.EntityType = 'Customer' OR #Extract.EntityType IS NULL) 
			AND LDPC.LegalEntityId IS NULL

		--Validate for CC, LOC and IT (Scenario 2)
			INSERT INTO ReceiptFileHandlerErrorMessages(RowId,ErrorMessage,SourceTable,SourceId,JobStepInstanceId,CreatedById,CreatedTime)
			SELECT
			NULL 
			,CONCAT('For the legal entity ',#Extract.LegalEntityNumber,', there doesn''t exist a combination of cost center,Line of Business and Instrument Type in the LockboxDefaultParameterConfigs table.Please configure the combination in order to create a receipt') 
			,'CommonExternalReceipt_Extract' 
			,#Extract.Id 
			,@JobStepInstanceId 
			,1 
			,@date 
			FROM #CommonExternalReceipt_Extract #Extract
			LEFT JOIN 
			(
				SELECT RANK() OVER (PARTITION BY LegalEntityId ORDER BY Id DESC) R, *
				FROM LockBoxDefaultParameterConfigs
				WHERE IsActive = 1
			) LBC ON LBC.R =1  AND #Extract.LegalEntityId = LBC.LegalEntityId
			WHERE (#Extract.EntityType = 'Customer' OR #Extract.EntityType IS NULL)
			AND (LBC.CostCenterId IS NULL OR LBC.LineOfBusinessId IS NULL OR LBC.InstrumentTypeId IS NULL)

			UPDATE #Extract SET IsValid = 0
			FROM #CommonExternalReceipt_Extract #Extract
			LEFT JOIN 
			(
				SELECT RANK() OVER (PARTITION BY LegalEntityId ORDER BY Id DESC) R, *
				FROM LockBoxDefaultParameterConfigs
				WHERE IsActive = 1
			) LBC ON LBC.R =1  AND #Extract.LegalEntityId = LBC.LegalEntityId
			WHERE (#Extract.EntityType = 'Customer' OR #Extract.EntityType IS NULL)
			AND (LBC.CostCenterId IS NULL OR LBC.LineOfBusinessId IS NULL OR LBC.InstrumentTypeId IS NULL)

		--Valilate CashTypeNotConfiguredLEBasedReceipt
			INSERT INTO ReceiptFileHandlerErrorMessages(RowId,ErrorMessage,SourceTable,SourceId,JobStepInstanceId,CreatedById,CreatedTime)
			SELECT
			NULL 
			,CONCAT('Please define CashType for the legal entity ',#Extract.LegalEntityNumber,' in the LockboxDefaultParameterConfigs table') 
			,'CommonExternalReceipt_Extract' 
			,#Extract.Id 
			,@JobStepInstanceId 
			,1 
			,@date 
			FROM #CommonExternalReceipt_Extract #Extract
			JOIN LegalEntities LE ON LE.Id = #Extract.LegalEntityId
			LEFT JOIN 
			(
				SELECT RANK() OVER (PARTITION BY LegalEntityId ORDER BY Id DESC) R, *
				FROM LockBoxDefaultParameterConfigs
				WHERE IsActive = 1
			) LBC ON LBC.R =1  AND #Extract.LegalEntityId = LBC.LegalEntityId
			WHERE #Extract.EntityType IS NULL AND LBC.CashTypeId IS NULL AND #Extract.ReceiptAmount > 0
			
			UPDATE #Extract SET IsValid = 0
			FROM #CommonExternalReceipt_Extract #Extract
			JOIN LegalEntities LE ON LE.Id = #Extract.LegalEntityId
			LEFT JOIN 
			(
				SELECT RANK() OVER (PARTITION BY LegalEntityId ORDER BY Id DESC) R, *
				FROM LockBoxDefaultParameterConfigs
				WHERE IsActive = 1
			) LBC ON LBC.R =1  AND #Extract.LegalEntityId = LBC.LegalEntityId
			WHERE #Extract.EntityType IS NULL AND LBC.CashTypeId IS NULL AND #Extract.ReceiptAmount > 0

		--PART 2
		--Validate Batch LE			
			SELECT @BatchLegalEntityNumber = LE.LegalEntityNumber
			FROM ReceiptBatches RB
			JOIN LegalEntities LE ON LE.Id = RB.LegalEntityId
			WHERE @ReceiptBatchId IS NOT NULL AND RB.Id = @ReceiptBatchId

			INSERT INTO ReceiptFileHandlerErrorMessages(RowId,ErrorMessage,SourceTable,SourceId,JobStepInstanceId,CreatedById,CreatedTime)
			SELECT
			NULL 
			,CONCAT('Legal Entity ',#Extract.LegalEntityNumber,' does not match with the Legal Entity' ,@BatchLegalEntityNumber,' associated with the Receipt Batch') 
			,'CommonExternalReceipt_Extract' 
			,#Extract.Id 
			,@JobStepInstanceId 
			,1 
			,@date
			FROM #CommonExternalReceipt_Extract #Extract
			JOIN LegalEntities LE ON #Extract.LegalEntityId = LE.Id
			JOIN ReceiptBatches RB ON @ReceiptBatchId IS NOT NULL AND RB.Id = @ReceiptBatchId
			WHERE LE.Id != RB.LegalEntityId

			UPDATE #Extract SET IsValid = 0
			FROM #CommonExternalReceipt_Extract #Extract
			JOIN LegalEntities LE ON #Extract.LegalEntityId = LE.Id
			JOIN ReceiptBatches RB ON @ReceiptBatchId IS NOT NULL AND RB.Id = @ReceiptBatchId
			WHERE LE.Id != RB.LegalEntityId

		--Validate Batch Currency
			SELECT @BatchCurrency = C.Name 
			FROM ReceiptBatches RB
			JOIN Currencies C ON RB.CurrencyId = C.Id
			WHERE @ReceiptBatchId IS NOT NULL AND RB.Id = @ReceiptBatchId

			INSERT INTO ReceiptFileHandlerErrorMessages(RowId,ErrorMessage,SourceTable,SourceId,JobStepInstanceId,CreatedById,CreatedTime)
			SELECT
			NULL 
			,CONCAT('Currency ',C.Name,' does not match with the Currency ',@BatchCurrency,' associated with the Receipt Batch') 
			,'CommonExternalReceipt_Extract' 
			,#Extract.Id 
			,@JobStepInstanceId 
			,1 
			,@date
			FROM #CommonExternalReceipt_Extract #Extract
			JOIN LegalEntities LE ON LE.Id = #Extract.LegalEntityId
			JOIN Currencies C ON #Extract.CurrencyId = C.Id
			JOIN ReceiptBatches RB ON @ReceiptBatchId IS NOT NULL AND RB.Id = @ReceiptBatchId
			WHERE C.Name != @BatchCurrency

			UPDATE #Extract SET IsValid = 0
			FROM #CommonExternalReceipt_Extract #Extract
			JOIN LegalEntities LE ON LE.Id = #Extract.LegalEntityId
			JOIN Currencies C ON #Extract.CurrencyId = C.Id
			JOIN ReceiptBatches RB ON @ReceiptBatchId IS NOT NULL AND RB.Id = @ReceiptBatchId
			WHERE C.Name != @BatchCurrency

		--Validate ReceiptAmount
			INSERT INTO ReceiptFileHandlerErrorMessages(RowId,ErrorMessage,SourceTable,SourceId,JobStepInstanceId,CreatedById,CreatedTime)
			SELECT
			NULL 
			,'Receipt Amount must be greater than zero' 
			,'CommonExternalReceipt_Extract' 
			,#Extract.Id 
			,@JobStepInstanceId 
			,1 
			,@date
			FROM #CommonExternalReceipt_Extract #Extract
			WHERE ReceiptAmount = 0

			UPDATE #CommonExternalReceipt_Extract SET IsValid = 0 WHERE ReceiptAmount = 0


		--ValidateGLConfig
			INSERT INTO ReceiptFileHandlerErrorMessages(RowId,ErrorMessage,SourceTable,SourceId,JobStepInstanceId,CreatedById,CreatedTime)
			SELECT
			NULL 
			,'GL Configuration of Receipt GL Template selected at Job Parameters must match the GL Configuration of the selected Legal Entity' 
			,'CommonExternalReceipt_Extract' 
			,#Extract.Id 
			,@JobStepInstanceId 
			,1 
			,@date
			FROM #CommonExternalReceipt_Extract #Extract
			JOIN LegalEntities LE ON LE.Id = #Extract.LegalEntityId 
			JOIN GLTemplates GLT ON @GLConfigurationId = GLT.Id
			JOIN GLConfigurations GLC ON GLT.GLConfigurationId = GLC.Id 
			WHERE LE.GLConfigurationId != GLC.Id

			UPDATE #CommonExternalReceipt_Extract SET IsValid = 0 
			FROM #CommonExternalReceipt_Extract #Extract
			JOIN LegalEntities LE ON LE.Id = #Extract.LegalEntityId 
			JOIN GLTemplates GLT ON @GLConfigurationId = GLT.Id
			JOIN GLConfigurations GLC ON GLT.GLConfigurationId = GLC.Id 
			WHERE LE.GLConfigurationId != GLC.Id

		--Validate LE BankAccount Currency
			INSERT INTO ReceiptFileHandlerErrorMessages(RowId,ErrorMessage,SourceTable,SourceId,JobStepInstanceId,CreatedById,CreatedTime)
			SELECT
			NULL 
			,'Legal Entity Bank Account Currency does not match with the File Currency' 
			,'CommonExternalReceipt_Extract' 
			,#Extract.Id 
			,@JobStepInstanceId 
			,1 
			,@date
			FROM #CommonExternalReceipt_Extract #Extract 
			JOIN LegalEntities LE ON LE.Id = #Extract.LegalEntityId 
			JOIN BankAccounts BA ON BA.Id = #Extract.BankAccountId
			WHERE #Extract.CurrencyId != BA.CurrencyId 

			UPDATE #Extract SET IsValid = 0
			FROM #CommonExternalReceipt_Extract #Extract 
			JOIN LegalEntities LE ON LE.Id = #Extract.LegalEntityId 
			JOIN BankAccounts BA ON BA.Id = #Extract.BankAccountId
			WHERE #Extract.CurrencyId != BA.CurrencyId 

		--Updating RowId in ReceiptFileHandlerErrorMessages
		;WITH CTE_UpdateTable AS
		(
			SELECT ErrorTable.Id 'Id', ROW_NUMBER() OVER(PARTITION BY ErrorTable.SourceId ORDER BY ErrorTable.SourceId) 'RowId' FROM #CommonExternalReceipt_Extract #Extract
			JOIN ReceiptFileHandlerErrorMessages ErrorTable ON ErrorTable.SourceId = #Extract.Id
			WHERE ErrorTable.RowId is NULL
		)
		UPDATE ReceiptFileHandlerErrorMessages SET RowId = Temp.RowId
		FROM ReceiptFileHandlerErrorMessages ErrorTable JOIN CTE_UpdateTable Temp ON ErrorTable.Id = Temp.Id		
		--Updating Extract table from Temp table
		UPDATE #Extract SET
		IsValid = Temp.IsValid 
		FROM #CommonExternalReceipt_Extract Temp
		JOIN CommonExternalReceipt_Extract #Extract ON Temp.Id = #Extract.Id

		--Updating CreateUnallocatedReceipt in Extract Table
		UPDATE Extract SET CreateUnallocatedReceipt = 1
		FROM CommonExternalReceipt_Extract Extract 
		WHERE Extract.JobStepInstanceId = @JobStepInstanceId 
		AND(EntityType IS NULL OR @CreateUnallocatedReceipt = 1) 

		UPDATE Extract SET CreateUnallocatedReceipt = 1
		FROM CommonExternalReceipt_Extract Extract
		JOIN ReceivableInvoices RI ON Extract.EntityType = 'Customer' AND RI.CustomerId = Extract.EntityId 
		WHERE Extract.JobStepInstanceId = @JobStepInstanceId 
		AND Extract.CurrencyId != RI.CurrencyId 

	END TRY
	BEGIN CATCH
		SELECT ERROR_MESSAGE()
	END CATCH
END

GO
