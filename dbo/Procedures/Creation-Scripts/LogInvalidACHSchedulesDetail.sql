SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[LogInvalidACHSchedulesDetail]
(@JobStepInstanceId      BIGINT,
 @UpdatedById            BIGINT,
 @UpdatedTime            DATETIMEOFFSET,
 @ErrorCodeInfo          ERRORCODEINFO READONLY,
 @ReceipleGLTemplateName NVARCHAR(50),
 @ErrorMessageType       NVARCHAR(30),
 @WarningMessageType     NVARCHAR(30),
 @ErrorCodeAU01          NVARCHAR(4),
 @ErrorCodeAU02          NVARCHAR(4),
 @ErrorCodeAU03          NVARCHAR(4),
 @ErrorCodeAU04          NVARCHAR(4),
 @ErrorCodeAU05          NVARCHAR(4),
 @ErrorCodeAU06          NVARCHAR(4),
 @ErrorCodeAU07          NVARCHAR(4),
 @ErrorCodeAU08          NVARCHAR(4),
 @ErrorCodeAU09          NVARCHAR(4),
 @ErrorCodeAU10          NVARCHAR(4),
 @ErrorCodeAU11          NVARCHAR(4),
 @ErrorCodeAU12          NVARCHAR(4),
 @ErrorCodeAU13          NVARCHAR(4),
 @ErrorCodeAU14          NVARCHAR(4),
 @ErrorCodeAU15          NVARCHAR(4),
 @ErrorCodeAU16          NVARCHAR(4),
 @ErrorCodeAU17          NVARCHAR(4),
 @ErrorCodeAU18          NVARCHAR(4),
 @ErrorCodeAU19			 NVARCHAR(4),
 @ErrorCodeAU20			 NVARCHAR(4),
 @ErrorCodeAU21			 NVARCHAR(4),
 @ErrorCodeAU22			 NVARCHAR(4)
)
AS
  BEGIN

    SELECT *
    INTO #ErrorCodeInfo
    FROM @ErrorCodeInfo;

    SELECT DISTINCT
           InvalidACHSchedule.InvalidOpenPeriodFromDate,
           InvalidACHSchedule.InvalidOpenPerionToDate,
           InvalidACHSchedule.ReceiptLegalEntityName,
           InvalidACHSchedule.SequenceNumber,
           InvalidACHSchedule.OneTimeACHId,
           InvalidACHSchedule.ReceivableId,
           InvalidACHSchedule.ACHPaymentNumber,
           InvalidACHSchedule.ErrorCode,
		   InvalidACHSchedule.ErrorMessage,
		   InvalidACHSchedule.CustomerNumber,
           PendingReceiptIds,
		   LineofBusinessId,
		   CostCenterId,
		   LateFeeReceiptIds,
		   LateFeeInvoiceNumbers,
		   ACHScheduleId
    INTO #InvalidACHDetails
    FROM dbo.ACHSchedule_Extract AS InvalidACHSchedule
    INNER JOIN #ErrorCodeInfo ON #ErrorCodeInfo.ErrorCode = InvalidACHSchedule.ErrorCode
    WHERE InvalidACHSchedule.JobStepInstanceId = @JobStepInstanceId;

    WITH CTE_DistinctLegalEntityName
         AS (SELECT #ErrorCodeInfo.ErrorCodeMessage,
                    #InvalidACHDetails.ReceiptLegalEntityName
             FROM #InvalidACHDetails
             JOIN #ErrorCodeInfo ON #InvalidACHDetails.ErrorCode = #ErrorCodeInfo.ErrorCode
             WHERE #InvalidACHDetails.ErrorCode = @ErrorCodeAU01
             GROUP BY #ErrorCodeInfo.ErrorCodeMessage,
                      #InvalidACHDetails.ReceiptLegalEntityName)
         INSERT INTO dbo.JobStepInstanceLogs
           (Message,
            MessageType,
            CreatedById,
            CreatedTime,
            JobStepInstanceId
           )
         SELECT REPLACE(CTE_DistinctLegalEntityName.ErrorCodeMessage, '@LegalEntityName', STRING_AGG(CAST(CTE_DistinctLegalEntityName.ReceiptLegalEntityName AS NVARCHAR(MAX)), ',')),
                @ErrorMessageType,
                @UpdatedById,
                @UpdatedTime,
                @JobStepInstanceId
         FROM CTE_DistinctLegalEntityName
         GROUP BY CTE_DistinctLegalEntityName.ErrorCodeMessage;

    WITH CTE_InvalidPostDateDetail
         AS (SELECT #InvalidACHDetails.ReceiptLegalEntityName,
                    MAX(#InvalidACHDetails.InvalidOpenPerionToDate) AS InvalidOpenPerionToDate,
                    MAX(#InvalidACHDetails.InvalidOpenPeriodFromDate) AS InvalidOpenPeriodFromDate,
                    #ErrorCodeInfo.ErrorCodeMessage
             FROM #InvalidACHDetails
             JOIN #ErrorCodeInfo ON #InvalidACHDetails.ErrorCode = #ErrorCodeInfo.ErrorCode
             WHERE #InvalidACHDetails.ErrorCode = @ErrorCodeAU02
             GROUP BY #ErrorCodeInfo.ErrorCodeMessage,
                      #InvalidACHDetails.ReceiptLegalEntityName)
         INSERT INTO dbo.JobStepInstanceLogs
           (Message,
            MessageType,
            CreatedById,
            CreatedTime,
            JobStepInstanceId
           )
         SELECT REPLACE(REPLACE(REPLACE(CTE_InvalidPostDateDetail.ErrorCodeMessage, '@LegalEntityName', CTE_InvalidPostDateDetail.ReceiptLegalEntityName), '@FromDate', CTE_InvalidPostDateDetail.InvalidOpenPeriodFromDate), '@ToDate', CTE_InvalidPostDateDetail.InvalidOpenPerionToDate),
                @ErrorMessageType,
                @UpdatedById,
                @UpdatedTime,
                @JobStepInstanceId
         FROM CTE_InvalidPostDateDetail;

    WITH CTE_InvalidReceiptLegalEntityIds
         AS (SELECT #InvalidACHDetails.ReceiptLegalEntityName,
                    #ErrorCodeInfo.ErrorCodeMessage,
                    #InvalidACHDetails.ReceivableId
             FROM #InvalidACHDetails
             JOIN #ErrorCodeInfo ON #InvalidACHDetails.ErrorCode = #ErrorCodeInfo.ErrorCode
             WHERE #InvalidACHDetails.ErrorCode = @ErrorCodeAU03
             GROUP BY #InvalidACHDetails.ReceiptLegalEntityName,
                      #ErrorCodeInfo.ErrorCodeMessage,
                      #InvalidACHDetails.ReceivableId)
         INSERT INTO dbo.JobStepInstanceLogs
           (Message,
            MessageType,
            CreatedById,
            CreatedTime,
            JobStepInstanceId
           )
         SELECT REPLACE(REPLACE(CTE_InvalidReceiptLegalEntityIds.ErrorCodeMessage, '@ReceiptLegalEntityName', CTE_InvalidReceiptLegalEntityIds.ReceiptLegalEntityName), '@ReceivableId', STRING_AGG(CAST(CTE_InvalidReceiptLegalEntityIds.ReceivableId AS NVARCHAR(MAX)), ',')),
                @ErrorMessageType,
                @UpdatedById,
                @UpdatedTime,
                @JobStepInstanceId
         FROM CTE_InvalidReceiptLegalEntityIds
         GROUP BY CTE_InvalidReceiptLegalEntityIds.ReceiptLegalEntityName,
                  CTE_InvalidReceiptLegalEntityIds.ErrorCodeMessage;

    WITH CTE_InvalidGLConfigContracts
         AS (SELECT #InvalidACHDetails.SequenceNumber,
                    #InvalidACHDetails.ReceiptLegalEntityName,
                    #ErrorCodeInfo.ErrorCodeMessage
             FROM #InvalidACHDetails
             JOIN #ErrorCodeInfo ON #InvalidACHDetails.ErrorCode = #ErrorCodeInfo.ErrorCode
             WHERE #InvalidACHDetails.ErrorCode = @ErrorCodeAU04
             GROUP BY #InvalidACHDetails.SequenceNumber,
                      #InvalidACHDetails.ReceiptLegalEntityName,
                      #ErrorCodeInfo.ErrorCodeMessage)
         INSERT INTO dbo.JobStepInstanceLogs
           (Message,
            MessageType,
            CreatedById,
            CreatedTime,
            JobStepInstanceId
           )
         SELECT REPLACE(REPLACE(REPLACE(CTE_InvalidGLConfigContracts.ErrorCodeMessage, '@SequenceNumber', STRING_AGG(CAST(CTE_InvalidGLConfigContracts.SequenceNumber AS NVARCHAR(MAX)), ',')), '@ReceiptLegalEntityName', CTE_InvalidGLConfigContracts.ReceiptLegalEntityName), '@ReceiptGLName', @ReceipleGLTemplateName),
                @ErrorMessageType,
                @UpdatedById,
                @UpdatedTime,
                @JobStepInstanceId
         FROM CTE_InvalidGLConfigContracts
         GROUP BY CTE_InvalidGLConfigContracts.ReceiptLegalEntityName,
                  CTE_InvalidGLConfigContracts.ErrorCodeMessage;

    WITH CTE_ACHScheduleNotAssessedTaxIds
         AS (SELECT #InvalidACHDetails.SequenceNumber,
                    #InvalidACHDetails.ACHPaymentNumber,
                    #ErrorCodeInfo.ErrorCodeMessage
             FROM #InvalidACHDetails
             JOIN #ErrorCodeInfo ON #InvalidACHDetails.ErrorCode = #ErrorCodeInfo.ErrorCode
             WHERE #InvalidACHDetails.ErrorCode = @ErrorCodeAU05
             GROUP BY #InvalidACHDetails.SequenceNumber,
                      #ErrorCodeInfo.ErrorCodeMessage,
                      #InvalidACHDetails.ACHPaymentNumber)
         INSERT INTO dbo.JobStepInstanceLogs
           (Message,
            MessageType,
            CreatedById,
            CreatedTime,
            JobStepInstanceId
           )
         SELECT REPLACE(REPLACE(CTE_ACHScheduleNotAssessedTaxIds.ErrorCodeMessage, '@SequenceNumber', CTE_ACHScheduleNotAssessedTaxIds.SequenceNumber), '@ACHPaymentNumber', STRING_AGG(CAST(CTE_ACHScheduleNotAssessedTaxIds.ACHPaymentNumber AS NVARCHAR(MAX)), ',')),
                @ErrorMessageType,
                @UpdatedById,
                @UpdatedTime,
                @JobStepInstanceId
         FROM CTE_ACHScheduleNotAssessedTaxIds
         GROUP BY CTE_ACHScheduleNotAssessedTaxIds.SequenceNumber,
                  CTE_ACHScheduleNotAssessedTaxIds.ErrorCodeMessage;

    WITH CTE_InvalidOneTimeACHIds
         AS (SELECT #InvalidACHDetails.OneTimeACHId,
                    #ErrorCodeInfo.ErrorCodeMessage
             FROM #InvalidACHDetails
             JOIN #ErrorCodeInfo ON #InvalidACHDetails.ErrorCode = #ErrorCodeInfo.ErrorCode
             WHERE #InvalidACHDetails.ErrorCode = @ErrorCodeAU06
             GROUP BY #InvalidACHDetails.OneTimeACHId,
                      #ErrorCodeInfo.ErrorCodeMessage)
         INSERT INTO dbo.JobStepInstanceLogs
           (Message,
            MessageType,
            CreatedById,
            CreatedTime,
            JobStepInstanceId
           )
         SELECT REPLACE(CTE_InvalidOneTimeACHIds.ErrorCodeMessage, '@OneTimeACHId', STRING_AGG(CAST(CTE_InvalidOneTimeACHIds.OneTimeACHId AS NVARCHAR(MAX)), ',')),
                @ErrorMessageType,
                @UpdatedById,
                @UpdatedTime,
                @JobStepInstanceId
         FROM CTE_InvalidOneTimeACHIds
         GROUP BY CTE_InvalidOneTimeACHIds.ErrorCodeMessage;

    WITH CTE_InvalidACHOperator
         AS (SELECT #InvalidACHDetails.ReceiptLegalEntityName,
                    #ErrorCodeInfo.ErrorCodeMessage
             FROM #InvalidACHDetails
             JOIN #ErrorCodeInfo ON #InvalidACHDetails.ErrorCode = #ErrorCodeInfo.ErrorCode
             WHERE #InvalidACHDetails.ErrorCode = @ErrorCodeAU07
             GROUP BY #ErrorCodeInfo.ErrorCodeMessage,
                      #InvalidACHDetails.ReceiptLegalEntityName)
         INSERT INTO dbo.JobStepInstanceLogs
           (Message,
            MessageType,
            CreatedById,
            CreatedTime,
            JobStepInstanceId
           )
         SELECT REPLACE(CTE_InvalidACHOperator.ErrorCodeMessage, '@ReceiptLegalEntityName', STRING_AGG(CAST(CTE_InvalidACHOperator.ReceiptLegalEntityName AS NVARCHAR(MAX)), ',')),
                @ErrorMessageType,
                @UpdatedById,
                @UpdatedTime,
                @JobStepInstanceId
         FROM CTE_InvalidACHOperator
         GROUP BY CTE_InvalidACHOperator.ErrorCodeMessage;

    WITH CTE_InvalidBankAccount
         AS (SELECT #InvalidACHDetails.ReceiptLegalEntityName,
                    #ErrorCodeInfo.ErrorCodeMessage
             FROM #InvalidACHDetails
             JOIN #ErrorCodeInfo ON #InvalidACHDetails.ErrorCode = #ErrorCodeInfo.ErrorCode
             WHERE #InvalidACHDetails.ErrorCode = @ErrorCodeAU08
             GROUP BY #ErrorCodeInfo.ErrorCodeMessage,
                      #InvalidACHDetails.ReceiptLegalEntityName)
         INSERT INTO dbo.JobStepInstanceLogs
           (Message,
            MessageType,
            CreatedById,
            CreatedTime,
            JobStepInstanceId
           )
         SELECT REPLACE(CTE_InvalidBankAccount.ErrorCodeMessage, '@ReceiptLegalEntityName', STRING_AGG(CAST(CTE_InvalidBankAccount.ReceiptLegalEntityName AS NVARCHAR(MAX)), ',')),
                @ErrorMessageType,
                @UpdatedById,
                @UpdatedTime,
                @JobStepInstanceId
         FROM CTE_InvalidBankAccount
         GROUP BY CTE_InvalidBankAccount.ErrorCodeMessage;

    WITH CTE_DSLAndNDSLPendingReceipt
         AS (SELECT #InvalidACHDetails.SequenceNumber,
                    MAX(#InvalidACHDetails.PendingReceiptIds) AS PendingReceiptIds,
                    #ErrorCodeInfo.ErrorCodeMessage
             FROM #InvalidACHDetails
             JOIN #ErrorCodeInfo ON #InvalidACHDetails.ErrorCode = #ErrorCodeInfo.ErrorCode
             WHERE #InvalidACHDetails.ErrorCode = @ErrorCodeAU09
			 AND #InvalidACHDetails.SequenceNumber IS NOT NULL
             GROUP BY #ErrorCodeInfo.ErrorCodeMessage,
                      #InvalidACHDetails.SequenceNumber)
         INSERT INTO dbo.JobStepInstanceLogs
           (Message,
            MessageType,
            CreatedById,
            CreatedTime,
            JobStepInstanceId
           )
         SELECT REPLACE(REPLACE(CTE_DSLAndNDSLPendingReceipt.ErrorCodeMessage, '@SequenceNumber', CTE_DSLAndNDSLPendingReceipt.SequenceNumber), '@ReceiptId', CTE_DSLAndNDSLPendingReceipt.PendingReceiptIds),
                @WarningMessageType,
                @UpdatedById,
                @UpdatedTime,
                @JobStepInstanceId
         FROM CTE_DSLAndNDSLPendingReceipt;

    WITH CTE_ThresholdExceededSequenceNumber
         AS (SELECT #InvalidACHDetails.SequenceNumber,
                    #InvalidACHDetails.ACHPaymentNumber,
                    #ErrorCodeInfo.ErrorCodeMessage
             FROM #InvalidACHDetails
             JOIN #ErrorCodeInfo ON #InvalidACHDetails.ErrorCode = #ErrorCodeInfo.ErrorCode
             WHERE #InvalidACHDetails.ErrorCode = @ErrorCodeAU10
             GROUP BY #InvalidACHDetails.SequenceNumber,
                      #ErrorCodeInfo.ErrorCodeMessage,
                      #InvalidACHDetails.ACHPaymentNumber)
         INSERT INTO dbo.JobStepInstanceLogs
           (Message,
            MessageType,
            CreatedById,
            CreatedTime,
            JobStepInstanceId
           )
         SELECT REPLACE(REPLACE(CTE_ThresholdExceededSequenceNumber.ErrorCodeMessage, '@SequenceNumber', CTE_ThresholdExceededSequenceNumber.SequenceNumber), '@ACHPaymentNumber', STRING_AGG(CAST(CTE_ThresholdExceededSequenceNumber.ACHPaymentNumber AS NVARCHAR(MAX)), ',')),
                @ErrorMessageType,
                @UpdatedById,
                @UpdatedTime,
                @JobStepInstanceId
         FROM CTE_ThresholdExceededSequenceNumber
         GROUP BY CTE_ThresholdExceededSequenceNumber.SequenceNumber,
                  CTE_ThresholdExceededSequenceNumber.ErrorCodeMessage;

    ;WITH CTE_InvalidGLOrgStructure
         AS (SELECT #InvalidACHDetails.ReceiptLegalEntityName,
                    #InvalidACHDetails.LineofBusinessId,
                    #InvalidACHDetails.CostCenterId,
                    #ErrorCodeInfo.ErrorCodeMessage
             FROM #InvalidACHDetails
             JOIN #ErrorCodeInfo ON #InvalidACHDetails.ErrorCode = #ErrorCodeInfo.ErrorCode
             WHERE #InvalidACHDetails.ErrorCode = @ErrorCodeAU11
             GROUP BY #ErrorCodeInfo.ErrorCodeMessage,
					  #InvalidACHDetails.LineofBusinessId,
					  #InvalidACHDetails.CostCenterId,
                      #InvalidACHDetails.ReceiptLegalEntityName)
         INSERT INTO dbo.JobStepInstanceLogs
           (Message,
            MessageType,
            CreatedById,
            CreatedTime,
            JobStepInstanceId
           )
         SELECT REPLACE(REPLACE(REPLACE(CTE_InvalidGLOrgStructure.ErrorCodeMessage, '@LineOfBuisness', LOB.Name), '@CostCenter', CC.CostCenter),'@LegalEntity',CTE_InvalidGLOrgStructure.ReceiptLegalEntityName),
                @ErrorMessageType,
                @UpdatedById,
                @UpdatedTime,
                @JobStepInstanceId
         FROM CTE_InvalidGLOrgStructure
		 JOIN LineofBusinesses LOB ON LOB.Id = CTE_InvalidGLOrgStructure.LineofBusinessId
		 JOIN CostCenterConfigs CC ON CC.Id = CTE_InvalidGLOrgStructure.CostCenterId
         GROUP BY LOB.Name,
		          CC.CostCenter,
				  CTE_InvalidGLOrgStructure.ReceiptLegalEntityName,
                  CTE_InvalidGLOrgStructure.ErrorCodeMessage;


    ;WITH CTE_SettlementDateWithIncomeDateForDSL
         AS (SELECT #InvalidACHDetails.SequenceNumber,
                    #ErrorCodeInfo.ErrorCodeMessage
             FROM #InvalidACHDetails
             JOIN #ErrorCodeInfo ON #InvalidACHDetails.ErrorCode = #ErrorCodeInfo.ErrorCode
             WHERE #InvalidACHDetails.ErrorCode = @ErrorCodeAU12
			 AND #InvalidACHDetails.SequenceNumber IS NOT NULL
             GROUP BY #ErrorCodeInfo.ErrorCodeMessage,
					  #InvalidACHDetails.SequenceNumber)
         INSERT INTO dbo.JobStepInstanceLogs
           (Message,
            MessageType,
            CreatedById,
            CreatedTime,
            JobStepInstanceId
           )
         SELECT REPLACE(CTE_SettlementDateWithIncomeDateForDSL.ErrorCodeMessage, '@ContractSequenceNumber', CTE_SettlementDateWithIncomeDateForDSL.SequenceNumber),
                @ErrorMessageType,
                @UpdatedById,
                @UpdatedTime,
                @JobStepInstanceId
         FROM CTE_SettlementDateWithIncomeDateForDSL
         GROUP BY 
				  CTE_SettlementDateWithIncomeDateForDSL.SequenceNumber,
                  CTE_SettlementDateWithIncomeDateForDSL.ErrorCodeMessage;

    ;WITH CTE_SettlementDateWithCommencementDateForDSL
         AS (SELECT #InvalidACHDetails.SequenceNumber,
                    #ErrorCodeInfo.ErrorCodeMessage
             FROM #InvalidACHDetails
             JOIN #ErrorCodeInfo ON #InvalidACHDetails.ErrorCode = #ErrorCodeInfo.ErrorCode
             WHERE #InvalidACHDetails.ErrorCode = @ErrorCodeAU13
			 AND #InvalidACHDetails.SequenceNumber IS NOT NULL
             GROUP BY #ErrorCodeInfo.ErrorCodeMessage,
					  #InvalidACHDetails.SequenceNumber)
         INSERT INTO dbo.JobStepInstanceLogs
           (Message,
            MessageType,
            CreatedById,
            CreatedTime,
            JobStepInstanceId
           )
         SELECT REPLACE(CTE_SettlementDateWithCommencementDateForDSL.ErrorCodeMessage, '@ContractSequenceNumber', CTE_SettlementDateWithCommencementDateForDSL.SequenceNumber),
                @ErrorMessageType,
                @UpdatedById,
                @UpdatedTime,
                @JobStepInstanceId
         FROM CTE_SettlementDateWithCommencementDateForDSL
         GROUP BY 
				  CTE_SettlementDateWithCommencementDateForDSL.SequenceNumber,
                  CTE_SettlementDateWithCommencementDateForDSL.ErrorCodeMessage;

    ;WITH CTE_SettlementDateWithPaydownDateForDSL
         AS (SELECT #InvalidACHDetails.SequenceNumber,
                    #ErrorCodeInfo.ErrorCodeMessage
             FROM #InvalidACHDetails
             JOIN #ErrorCodeInfo ON #InvalidACHDetails.ErrorCode = #ErrorCodeInfo.ErrorCode
             WHERE #InvalidACHDetails.ErrorCode = @ErrorCodeAU14
			 AND #InvalidACHDetails.SequenceNumber IS NOT NULL
             GROUP BY #ErrorCodeInfo.ErrorCodeMessage,
					  #InvalidACHDetails.SequenceNumber)
         INSERT INTO dbo.JobStepInstanceLogs
           (Message,
            MessageType,
            CreatedById,
            CreatedTime,
            JobStepInstanceId
           )
         SELECT REPLACE(CTE_SettlementDateWithPaydownDateForDSL.ErrorCodeMessage, '@ContractSequenceNumber',CTE_SettlementDateWithPaydownDateForDSL.SequenceNumber),
                @ErrorMessageType,
                @UpdatedById,
                @UpdatedTime,
                @JobStepInstanceId
         FROM CTE_SettlementDateWithPaydownDateForDSL
         GROUP BY 
				  CTE_SettlementDateWithPaydownDateForDSL.SequenceNumber,
                  CTE_SettlementDateWithPaydownDateForDSL.ErrorCodeMessage;

    ;WITH CTE_SettlementDateWithReceivaedDateForDSL
         AS (SELECT #InvalidACHDetails.SequenceNumber,
                    #ErrorCodeInfo.ErrorCodeMessage
             FROM #InvalidACHDetails
             JOIN #ErrorCodeInfo ON #InvalidACHDetails.ErrorCode = #ErrorCodeInfo.ErrorCode
             WHERE #InvalidACHDetails.ErrorCode = @ErrorCodeAU15
			 AND #InvalidACHDetails.SequenceNumber IS NOT NULL
             GROUP BY #ErrorCodeInfo.ErrorCodeMessage,
					  #InvalidACHDetails.SequenceNumber)
         INSERT INTO dbo.JobStepInstanceLogs
           (Message,
            MessageType,
            CreatedById,
            CreatedTime,
            JobStepInstanceId
           )
         SELECT REPLACE(CTE_SettlementDateWithReceivaedDateForDSL.ErrorCodeMessage, '@ContractSequenceNumber', CTE_SettlementDateWithReceivaedDateForDSL.SequenceNumber),
                @ErrorMessageType,
                @UpdatedById,
                @UpdatedTime,
                @JobStepInstanceId
         FROM CTE_SettlementDateWithReceivaedDateForDSL
         GROUP BY 
				  CTE_SettlementDateWithReceivaedDateForDSL.SequenceNumber,
                  CTE_SettlementDateWithReceivaedDateForDSL.ErrorCodeMessage;

    ;WITH CTE_LateFeeInvoicesToReverse
         AS (SELECT #InvalidACHDetails.LateFeeInvoiceNumbers,
                    #ErrorCodeInfo.ErrorCodeMessage
             FROM #InvalidACHDetails
             JOIN #ErrorCodeInfo ON #InvalidACHDetails.ErrorCode = #ErrorCodeInfo.ErrorCode
             WHERE #InvalidACHDetails.ErrorCode = @ErrorCodeAU16
             GROUP BY #ErrorCodeInfo.ErrorCodeMessage,
					  #InvalidACHDetails.LateFeeInvoiceNumbers)
         INSERT INTO dbo.JobStepInstanceLogs
           (Message,
            MessageType,
            CreatedById,
            CreatedTime,
            JobStepInstanceId
           )
         SELECT REPLACE(CTE_LateFeeInvoicesToReverse.ErrorCodeMessage, '@InvoiceNumber', STRING_AGG(CAST(CTE_LateFeeInvoicesToReverse.LateFeeInvoiceNumbers AS NVARCHAR(MAX)), ',')),
                @ErrorMessageType,
                @UpdatedById,
                @UpdatedTime,
                @JobStepInstanceId
         FROM CTE_LateFeeInvoicesToReverse
         GROUP BY 
                  CTE_LateFeeInvoicesToReverse.ErrorCodeMessage;

		;WITH CTE_LateFeeReceiptsToReverse
         AS (SELECT #InvalidACHDetails.LateFeeReceiptIds,
                    #ErrorCodeInfo.ErrorCodeMessage
             FROM #InvalidACHDetails
             JOIN #ErrorCodeInfo ON #InvalidACHDetails.ErrorCode = #ErrorCodeInfo.ErrorCode
             WHERE #InvalidACHDetails.ErrorCode = @ErrorCodeAU17
             GROUP BY #ErrorCodeInfo.ErrorCodeMessage,
					  #InvalidACHDetails.LateFeeReceiptIds)
         INSERT INTO dbo.JobStepInstanceLogs
           (Message,
            MessageType,
            CreatedById,
            CreatedTime,
            JobStepInstanceId
           )
         SELECT REPLACE(CTE_LateFeeReceiptsToReverse.ErrorCodeMessage, '@ReceiptNumber', STRING_AGG(CAST(CTE_LateFeeReceiptsToReverse.LateFeeReceiptIds AS NVARCHAR(MAX)), ',')),
                @ErrorMessageType,
                @UpdatedById,
                @UpdatedTime,
                @JobStepInstanceId
         FROM CTE_LateFeeReceiptsToReverse
         GROUP BY 
                  CTE_LateFeeReceiptsToReverse.ErrorCodeMessage;

		;WITH CTE_MultipleNANDSLOrDSLReceiptDetails
         AS (SELECT #InvalidACHDetails.SequenceNumber,
		            CASE WHEN #InvalidACHDetails.ACHScheduleId IS NOT NULL THEN #InvalidACHDetails.ACHScheduleId ELSE #InvalidACHDetails.OneTimeACHId END AS ACHScheduleId,
                    #ErrorCodeInfo.ErrorCodeMessage
             FROM #InvalidACHDetails
             JOIN #ErrorCodeInfo ON #InvalidACHDetails.ErrorCode = #ErrorCodeInfo.ErrorCode
             WHERE #InvalidACHDetails.ErrorCode = @ErrorCodeAU18
			 AND #InvalidACHDetails.SequenceNumber IS NOT NULL
             GROUP BY #InvalidACHDetails.SequenceNumber,
		            #InvalidACHDetails.ACHScheduleId,
					#InvalidACHDetails.OneTimeACHId,
                    #ErrorCodeInfo.ErrorCodeMessage)
         INSERT INTO dbo.JobStepInstanceLogs
           (Message,
            MessageType,
            CreatedById,
            CreatedTime,
            JobStepInstanceId
           )
         SELECT REPLACE(REPLACE(CTE_MultipleNANDSLOrDSLReceiptDetails.ErrorCodeMessage, '@ContractSequenceNumber', SequenceNumber),'@ACHScheduleId',STRING_AGG(CAST(ACHScheduleId AS NVARCHAR(MAX)), ',')),
                @WarningMessageType,
                @UpdatedById,
                @UpdatedTime,
                @JobStepInstanceId
         FROM CTE_MultipleNANDSLOrDSLReceiptDetails
         GROUP BY 
                  CTE_MultipleNANDSLOrDSLReceiptDetails.ErrorCodeMessage,
				  CTE_MultipleNANDSLOrDSLReceiptDetails.SequenceNumber;

	;WITH CTE_InvalidLateFeeReceivables
	AS
	(
	 SELECT ReceivableId,
	 #ErrorCodeInfo.ErrorCodeMessage
	 FROM #InvalidACHDetails
	 JOIN #ErrorCodeInfo ON #InvalidACHDetails.ErrorCode = #ErrorCodeInfo.ErrorCode
	 WHERE #InvalidACHDetails.ErrorCode = @ErrorCodeAU19
	 GROUP BY ReceivableId,
	 #ErrorCodeInfo.ErrorCodeMessage
	)
	INSERT INTO dbo.JobStepInstanceLogs
           (Message,
            MessageType,
            CreatedById,
            CreatedTime,
            JobStepInstanceId
           )
         SELECT REPLACE(CTE_InvalidLateFeeReceivables.ErrorCodeMessage,'@ReceivableIds',STRING_AGG(CAST(ReceivableId AS NVARCHAR(MAX)), ',')),
                @WarningMessageType,
                @UpdatedById,
                @UpdatedTime,
                @JobStepInstanceId
         FROM CTE_InvalidLateFeeReceivables
         GROUP BY 
                  CTE_InvalidLateFeeReceivables.ErrorCodeMessage;

		WITH CTE_BankAccountsOnHold
         AS (SELECT #InvalidACHDetails.SequenceNumber,
                    #InvalidACHDetails.ACHPaymentNumber,
                    #ErrorCodeInfo.ErrorCodeMessage
             FROM #InvalidACHDetails
             JOIN #ErrorCodeInfo ON #InvalidACHDetails.ErrorCode = #ErrorCodeInfo.ErrorCode
             WHERE #InvalidACHDetails.ErrorCode = @ErrorCodeAU20
             GROUP BY #InvalidACHDetails.SequenceNumber,
					  #InvalidACHDetails.ACHPaymentNumber,
                      #ErrorCodeInfo.ErrorCodeMessage)
         INSERT INTO dbo.JobStepInstanceLogs
           (Message,
            MessageType,
            CreatedById,
            CreatedTime,
            JobStepInstanceId
           )
         SELECT REPLACE(REPLACE(CTE_BankAccountsOnHold.ErrorCodeMessage, '@ContractSequenceNumber', SequenceNumber),'@ACHPaymentNumber',STRING_AGG(CAST(ACHPaymentNumber AS NVARCHAR(MAX)), ',')),
                @ErrorMessageType,
                @UpdatedById,
                @UpdatedTime,
                @JobStepInstanceId
         FROM CTE_BankAccountsOnHold
         GROUP BY CTE_BankAccountsOnHold.SequenceNumber,
				  CTE_BankAccountsOnHold.ErrorCodeMessage;

		WITH CTE_OTACHBankAccountsOnHold
         AS (SELECT #InvalidACHDetails.OneTimeACHId,
                    #ErrorCodeInfo.ErrorCodeMessage
             FROM #InvalidACHDetails
             JOIN #ErrorCodeInfo ON #InvalidACHDetails.ErrorCode = #ErrorCodeInfo.ErrorCode
             WHERE #InvalidACHDetails.ErrorCode = @ErrorCodeAU21
             GROUP BY #InvalidACHDetails.OneTimeACHId,
                      #ErrorCodeInfo.ErrorCodeMessage)
         INSERT INTO dbo.JobStepInstanceLogs
           (Message,
            MessageType,
            CreatedById,
            CreatedTime,
            JobStepInstanceId
           )
         SELECT REPLACE(CTE_OTACHBankAccountsOnHold.ErrorCodeMessage, '@OneTimeACHId', STRING_AGG(CAST(CTE_OTACHBankAccountsOnHold.OneTimeACHId AS NVARCHAR(MAX)), ',')),
                @ErrorMessageType,
                @UpdatedById,
                @UpdatedTime,
                @JobStepInstanceId
         FROM CTE_OTACHBankAccountsOnHold
         GROUP BY CTE_OTACHBankAccountsOnHold.OneTimeACHId,
				  CTE_OTACHBankAccountsOnHold.ErrorCodeMessage;

		
		WITH CTE_OTACHBankAccountsInvalid
         AS (SELECT #InvalidACHDetails.CustomerNumber,
                    #InvalidACHDetails.ErrorMessage AS ErrorCodeMessage
             FROM #InvalidACHDetails
             WHERE #InvalidACHDetails.ErrorCode = @ErrorCodeAU22
             GROUP BY #InvalidACHDetails.CustomerNumber,
                      #InvalidACHDetails.ErrorMessage)
         INSERT INTO dbo.JobStepInstanceLogs
           (Message,
            MessageType,
            CreatedById,
            CreatedTime,
            JobStepInstanceId
           )
         SELECT STRING_AGG(CAST(CTE_OTACHBankAccountsInvalid.ErrorCodeMessage AS NVARCHAR(MAX)), ','),
                @ErrorMessageType,
                @UpdatedById,
                @UpdatedTime,
                @JobStepInstanceId
         FROM CTE_OTACHBankAccountsInvalid
         GROUP BY CTE_OTACHBankAccountsInvalid.CustomerNumber,
				  CTE_OTACHBankAccountsInvalid.ErrorCodeMessage;

  END;

GO
