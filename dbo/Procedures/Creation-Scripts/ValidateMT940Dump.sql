SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

	
	CREATE PROC [dbo].[ValidateMT940Dump]  
	(  
		@JobStepInstanceId   BIGINT,
		@DecryptionKey NVARCHAR(MAX)
	)  
	AS  
	BEGIN  
		SET NOCOUNT OFF;  
		SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
		DECLARE @errorMessage NVARCHAR(400)  
	  
		BEGIN TRY
	
			SELECT   
			Id  
			,TransactionReferenceNumber
			,AccountIdentification
			,Trans_DC
			,TransactionAmount_Currency
			,TransCustomerReference
			,FileName
			,IsValid 
			INTO #MT940File_Dump  
			FROM MT940File_Dump WHERE JobStepInstanceId=@JobStepInstanceId;  
	
			DECLARE @legalEntityCount BIGINT
			,@dumpTableId BIGINT
			,@isCurrencyNotFound BIT
			,@isTransactionAmountTypeInvalid BIGINT
			,@bankAccountNumber NVARCHAR(35)
			,@transactionReferenceNumber NVARCHAR(16)
			,@currency NVARCHAR(3)
			
			CREATE TABLE #TempErrors(Id BIGINT,ErrorMessage NVARCHAR(400),BankAccountNumber NVARCHAR(35))
				
			DECLARE dumpTableCursor CURSOR FOR
			SELECT Id FROM #MT940File_Dump
			OPEN dumpTableCursor
			FETCH NEXT FROM dumpTableCursor INTO @dumpTableId
			WHILE @@FETCH_STATUS = 0
			BEGIN
		 
				--Validate Bank Account Number
				SELECT @bankAccountNumber = Temp.AccountIdentification,@transactionReferenceNumber = Temp.TransactionReferenceNumber FROM #MT940File_Dump Temp WHERE Temp.Id = @dumpTableId
				
				SELECT @legalEntityCount = COUNT(LE.Id) from #MT940File_Dump Temp 
				JOIN BankAccounts BA ON Temp.AccountIdentification = BA.IBAN OR Temp.AccountIdentification = dbo.Decrypt('varchar',BA.AccountNumber_CT,@DecryptionKey)
				JOIN LegalEntityBankAccounts LEBA ON LEBA.BankAccountId = BA.Id
				JOIN LegalEntities LE ON LE.Id = LEBA.LegalEntityId
				WHERE Temp.Id = @dumpTableId
				
				IF @legalEntityCount = 0 AND NOT EXISTS (SELECT 1 FROM ReceiptFileHandlerErrorMessages WHERE JobStepInstanceId = @JobStepInstanceId AND CHARINDEX(@bankAccountNumber,ErrorMessage)>0 AND CHARINDEX(@transactionReferenceNumber,ErrorMessage)>0)
				BEGIN
					SELECT  @errorMessage = CONCAT('In file ',Temp.FileName,', Transaction Reference Number :',Temp.TransactionReferenceNumber,', Tag :25: Lessor Account Number <',Temp.AccountIdentification,'> is not available in the system')
					FROM #MT940File_Dump Temp WHERE Temp.Id = @dumpTableId
	
					UPDATE Temp SET IsValid = 0 FROM #MT940File_Dump Temp WHERE  Temp.Id = @dumpTableId
	
					INSERT INTO ReceiptFileHandlerErrorMessages(RowId,ErrorMessage,SourceTable,SourceId,JobStepInstanceId,CreatedById,CreatedTime) SELECT null,@errorMessage,'MT940File_Dump',@dumpTableId,@JobStepInstanceId,1,GETDATE() FROM #MT940File_Dump Temp
					WHERE Temp.Id = @dumpTableId
	
					INSERT INTO JobStepInstanceLogs(Message,MessageType,CreatedById,CreatedTime,JobStepInstanceId) VALUES (@errorMessage,'Error',1,GETDATE(),@JobStepInstanceId)
	
				END
				ELSE IF @legalEntityCount > 1 AND NOT EXISTS (SELECT 1 FROM ReceiptFileHandlerErrorMessages WHERE JobStepInstanceId = @JobStepInstanceId AND CHARINDEX(@bankAccountNumber,ErrorMessage)>0 AND CHARINDEX(@transactionReferenceNumber,ErrorMessage)>0)
				BEGIN
					SELECT  @errorMessage = CONCAT('In file ',Temp.FileName,', Transaction Reference Number :',Temp.TransactionReferenceNumber,', Tag :25: Lessor Account Number <',Temp.AccountIdentification,'> is available in the system for multiple legal entities')
					FROM #MT940File_Dump Temp WHERE Temp.Id = @dumpTableId
	
					UPDATE Temp SET IsValid = 0 FROM #MT940File_Dump Temp WHERE  Temp.Id = @dumpTableId
	
					INSERT INTO ReceiptFileHandlerErrorMessages(RowId,ErrorMessage,SourceTable,SourceId,JobStepInstanceId,CreatedById,CreatedTime) SELECT null,@errorMessage,'MT940File_Dump',@dumpTableId,@JobStepInstanceId,1,GETDATE() FROM #MT940File_Dump Temp
					WHERE Temp.Id = @dumpTableId
	
					INSERT INTO JobStepInstanceLogs(Message,MessageType,CreatedById,CreatedTime,JobStepInstanceId) VALUES (@errorMessage,'Error',1,GETDATE(),@JobStepInstanceId)
				END
				ELSE IF EXISTS (SELECT 1 FROM ReceiptFileHandlerErrorMessages WHERE JobStepInstanceId = @JobStepInstanceId AND CHARINDEX(@bankAccountNumber,ErrorMessage)>0 AND CHARINDEX(@transactionReferenceNumber,ErrorMessage)>0)
				BEGIN
					UPDATE Temp SET IsValid = 0 FROM #MT940File_Dump Temp WHERE  Temp.Id = @dumpTableId
				END
	  
				--Validating the Currency check in DB
				UPDATE Temp SET IsValid = 0,@isCurrencyNotFound = 1,@currency = Temp.TransactionAmount_Currency
				FROM #MT940File_Dump Temp
				WHERE Temp.Id = @dumpTableId AND Temp.TransactionAmount_Currency not in (SELECT ISO FROM CurrencyCodes)
				
				IF @isCurrencyNotFound = 1 AND NOT EXISTS(SELECT 1 FROM #TempErrors WHERE BankAccountNumber = @bankAccountNumber AND CHARINDEX(@currency,ErrorMessage)>0 AND CHARINDEX(@transactionReferenceNumber,ErrorMessage)>0)
				BEGIN
	
					SELECT  @errorMessage = CONCAT('In file ',Temp.FileName,', Transaction Reference Number :',Temp.TransactionReferenceNumber,',Tag :60F: Currency <',Temp.TransactionAmount_Currency,'> is not available in the system')
					FROM #MT940File_Dump Temp WHERE Temp.Id = @dumpTableId
	
					INSERT INTO ReceiptFileHandlerErrorMessages(RowId,ErrorMessage,SourceTable,SourceId,JobStepInstanceId,CreatedById,CreatedTime) SELECT null,@errorMessage,'MT940File_Dump',@dumpTableId,@JobStepInstanceId,1,GETDATE() FROM #MT940File_Dump Temp
					WHERE Temp.Id = @dumpTableId
	
					INSERT INTO JobStepInstanceLogs(Message,MessageType,CreatedById,CreatedTime,JobStepInstanceId) VALUES (@errorMessage,'Error',1,GETDATE(),@JobStepInstanceId)

					INSERT INTO #TempErrors(Id,ErrorMessage,BankAccountNumber) SELECT Id,@errorMessage 'ErrorMessage',@bankAccountNumber 'BankAccountNumber' 
					FROM #MT940File_Dump Temp WHERE Temp.Id = @dumpTableId
				END		
				--Valilate the TransactionAmountType
				UPDATE Temp SET IsValid = 0,@isTransactionAmountTypeInvalid = 1 
				FROM #MT940File_Dump Temp
				WHERE Temp.Id = @dumpTableId AND Temp.Trans_DC = '_'
	
				IF @isTransactionAmountTypeInvalid = 1
				BEGIN
					SELECT  @errorMessage = CONCAT('In file ',Temp.FileName,', Transaction Reference Number :',Temp.TransactionReferenceNumber,', CustomerReferenceNumber :',Temp.TransCustomerReference,',Tag :61: Type of Transaction is not valid')
					FROM #MT940File_Dump Temp WHERE Temp.Id = @dumpTableId
	
					INSERT INTO ReceiptFileHandlerErrorMessages(RowId,ErrorMessage,SourceTable,SourceId,JobStepInstanceId,CreatedById,CreatedTime) SELECT null,@errorMessage,'MT940File_Dump',@dumpTableId,@JobStepInstanceId,1,GETDATE() FROM #MT940File_Dump Temp
					WHERE Temp.Id = @dumpTableId
	
					INSERT INTO JobStepInstanceLogs(Message,MessageType,CreatedById,CreatedTime,JobStepInstanceId) VALUES (@errorMessage,'Error',1,GETDATE(),@JobStepInstanceId)
				END
	
				SET @isCurrencyNotFound = 0
				SET @isTransactionAmountTypeInvalid = 0
	
			FETCH NEXT FROM dumpTableCursor INTO @dumpTableId
			END
			CLOSE dumpTableCursor
			DEALLOCATE dumpTableCursor   
	
			--Updating RowId in ReceiptFileHandlerErrorMessages
			;WITH CTE_UpdateTable AS
			(
				SELECT ErrorTable.Id 'Id', ROW_NUMBER() OVER(ORDER BY ErrorTable.SourceId) 'RowId' FROM #MT940File_Dump Temp
				JOIN ReceiptFileHandlerErrorMessages ErrorTable ON ErrorTable.SourceId = Temp.Id
				WHERE ErrorTable.RowId is null
			)
	
			UPDATE ReceiptFileHandlerErrorMessages SET RowId = Temp.RowId
			FROM ReceiptFileHandlerErrorMessages ErrorTable JOIN CTE_UpdateTable Temp ON ErrorTable.Id = Temp.Id
			
			--Updating Dump table from Temp table
			UPDATE Dump SET
			IsValid = Temp.IsValid 
			FROM #MT940File_Dump Temp
			JOIN MT940File_Dump Dump ON Temp.Id = Dump.Id

			DROP TABLE #TempErrors
		END TRY
		BEGIN CATCH
			SELECT ERROR_MESSAGE()
		END CATCH
	END

GO
