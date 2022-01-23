SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[ExtractACHFileGrouping]
(@UpdatedById                          BIGINT,
 @UpdatedTime                          DATETIMEOFFSET,
 @JobStepInstanceId                    BIGINT,
 @GenerateSeparateFiles                BIT,
 @VendorNachaFileFormatType            NVARCHAR(20),
 @DSLReceiptClassification             NVARCHAR(20),
 @NANDSLReceiptClassification          NVARCHAR(20),
 @FileHeaderNachaFileRecordType        NVARCHAR(20),
 @FileControlNachaFileRecordType       NVARCHAR(20),
 @BathcHeaderNachaFileRecordType       NVARCHAR(20),
 @BatchControlNachaFileRecordType      NVARCHAR(20),
 @EntryDetailRecordNachaFileRecordType NVARCHAR(20),
 @CustomerEntityType                   NVARCHAR(20),
 @ReceiptModule                        NVARCHAR(20)
)
AS
  BEGIN
    SET ANSI_WARNINGS OFF;

    CREATE TABLE #PersistedFileHeaders
    (Id           BIGINT,
     FileHeaderId BIGINT
    );

	CREATE TABLE #PersistedEntryDetails
    (Id            BIGINT,
     EntryDetailId BIGINT,
	 TraceNumber BIGINT
    );

    CREATE TABLE #PersistedACHReceiptDetails
    (Id             BIGINT,
     ExtractReceiptId BIGINT
    );

    CREATE TABLE #PersistedBatchHeaders
    (Id            BIGINT,
     FileHeaderId  BIGINT,
     BatchHeaderId BIGINT
    );

    SELECT * INTO #NACHAFileconfigInfo
    FROM
    (SELECT NachaFileFormatConfigs.FileRecordType,
               NachaFileFormatConfigs.FileType,
               NachaFileFormatConfigs.FieldName,
               NachaFileFormatConfigs.[Value]
        FROM dbo.NachaFileFormatConfigs
        WHERE NachaFileFormatConfigs.FileType <> @VendorNachaFileFormatType
    ) AS N PIVOT(MAX(Value) FOR FieldName IN(RecordTypeCode,
                                             AddendaRecordIndicator,
                                             BlockingFactor,
                                             ClientShortName,
                                             CompanyEntryDescription,
                                             DestinationCountry,
                                             FileIDModifier,
                                             FormatCode,
                                             InputType,
                                             LanguageCode,
                                             OptionalRecordIndicator,
                                             OriginatorStatusCode,
                                             PAPFileRoutingRecord,
                                             PaymentNumber,
                                             PriorityCode,
                                             RecordSize,
                                             ServiceClassCode,
                                             TransactionCode)) PVT;

    SELECT Id,
		   ISNULL(CASE WHEN ReceiptClassificationType = @DSLReceiptClassification OR ReceiptClassificationType = @NANDSLReceiptClassification THEN ContractId ELSE NULL END ,
				  CASE WHEN ACHSchedule_Extract.IsConsolidated = 0 AND ACHSchedule_Extract.IsOneTimeACH = 0 THEN  ACHSchedule_Extract.ContractId ELSE ACHSchedule_Extract.CustomerId END) EntityId,
           DENSE_RANK() OVER(ORDER BY CurrencyId, IsPrivateLabel, RemitToId, ReceiptBankAccountId,CASE WHEN @GenerateSeparateFiles = 1 THEN IsOnetimeACH ELSE 0 END) AS FileHeaderId,
           DENSE_RANK() OVER(PARTITION BY CurrencyId, IsPrivateLabel, RemitToId, ReceiptBankAccountId,CASE WHEN @GenerateSeparateFiles = 1 THEN IsOnetimeACH ELSE 0 END ORDER BY PrivateLabelName, SettlementDate) AS BatchHeaderId,
           DENSE_RANK() OVER(ORDER BY CurrencyId,
									  IsPrivateLabel,
									  RemitToId,
									  ReceiptBankAccountId,
									  CASE WHEN @GenerateSeparateFiles = 1 THEN IsOnetimeACH ELSE 0 END,
									  PrivateLabelName,
									  SettlementDate,
									  CASE WHEN ReceiptClassificationType = @DSLReceiptClassification
									  				OR ReceiptClassificationType = @NANDSLReceiptClassification
									  	THEN ContractId ELSE 1 END,
									  OneTimeACHId,
									  CASE WHEN IsConsolidated = 0 AND IsOneTimeACH = 0 THEN  ContractId ELSE CustomerId END,
									  CustomerBankAccountId,
									  CostCenterId,
									  OneTimeBankAccount) AS EntryDetailId,
		 DENSE_RANK() OVER(ORDER BY ACHSchedule_Extract.CurrencyId,
									ACHSchedule_Extract.IsPrivateLabel,
									ACHSchedule_Extract.RemitToId,
									ACHSchedule_Extract.ReceiptBankAccountId,
									CASE WHEN @GenerateSeparateFiles = 1 THEN ACHSchedule_Extract.IsOnetimeACH ELSE 0 END,
									ACHSchedule_Extract.PrivateLabelName,
									ACHSchedule_Extract.SettlementDate,
									CASE WHEN ACHSchedule_Extract.ReceiptClassificationType = @DSLReceiptClassification OR ACHSchedule_Extract.ReceiptClassificationType = @NANDSLReceiptClassification THEN ACHSchedule_Extract.ContractId ELSE NULL END,
									ACHSchedule_Extract.OneTimeACHId,
									CASE WHEN ACHSchedule_Extract.IsConsolidated = 0 AND ACHSchedule_Extract.IsOneTimeACH = 0 THEN  ACHSchedule_Extract.ContractId ELSE ACHSchedule_Extract.CustomerId END,
									ACHSchedule_Extract.CustomerBankAccountId,
									CostCenterId,
									OneTimeBankAccount,
									ISNULL(CASE WHEN ReceiptClassificationType = @DSLReceiptClassification OR ReceiptClassificationType = @NANDSLReceiptClassification THEN ContractId ELSE NULL END ,
										   CASE WHEN ACHSchedule_Extract.IsConsolidated = 0 AND ACHSchedule_Extract.IsOneTimeACH = 0 THEN  ACHSchedule_Extract.ContractId ELSE ACHSchedule_Extract.CustomerId END),
									IsOneTimeACH,
									CurrencyCode,
									ReceiptClassificationType,
									ReceiptLegalEntityId,
									LineOfBusinessId,
									InstrumentTypeId,
									BranchId,
									GLTemplateId,
									ReceiptTypeName,
									CheckNumber,
									IsConsolidated,
									ReceiptTypeId) AS ReceiptId,
		   CASE WHEN ReceiptClassificationType = @DSLReceiptClassification OR ReceiptClassificationType = @NANDSLReceiptClassification
					THEN ContractType
				WHEN IsOneTimeACH = 0 AND IsConsolidated = 0
					THEN ContractType ELSE @CustomerEntityType END AS EntityType,
		   CASE WHEN IsOneTimeACH = 1 THEN OneTimeACHScheduleId ELSE ACHScheduleId END ScheduleId,
		   CurrencyCode,
           ReceiptClassificationType,
		   ContractType,
		   ACHScheduleId,
		   UnAllocatedAmount,
		   OneTimeBankAccount,
           ReceiptLegalEntityId,
           LineOfBusinessId,
           InstrumentTypeId,
           BranchId,
           GLTemplateId,
           ReceiptBankAccountId,
           ReceiptTypeName,
           CheckNumber,
           IsConsolidated,
           CustomerBankAccountId,
		   CurrencyName,
		   OneTimeACHId,
		   ReceiptTypeId,
		   CustomerId,
		   ReceivableDetailId,
		   ReceivableDetailTaxAmount,
           ReceivableInvoiceId,
           ReceivableId,
		   ContractId,
	       DiscountingId,
		   ReceivableDetailAmount,
           CurrencyId AS CurrencyId,
           CAST(IsPrivateLabel AS TINYINT) AS IsPrivateLabel,
           RemitToId AS RemitToId,
           RemitToName AS RemitToName,
           ReceiptBankAccountId AS LegalEntityBankAccountId,
           CAST(IsOneTimeACH AS TINYINT) IsOneTimeACH,
           ReceiptBankAccountACHOperatorConfigId AS ACHOperatorConfigId,
           FileFormat,
           ACHAmount AS TotalDebitAmount,
           NACHAFilePaddingOption AS NACHAFilePaddingOption,
           CAST(ReceiptBankGenerateControlFile AS TINYINT) AS ReceiptBankGenerateControlFile,
           ReceiptBankACISCustomerNumber,
           ReceiptBankSourceofInput,
           CurrencySymbol,
           ReceiptLegalEntityNumber,
           ReceiptBankBranchName,
		   PrivateLabelName,
           Settlementdate AS Settlementdate,
           CAST(ReceiptBankGenerateBalancedACH AS TINYINT) ReceiptBankGenerateBalancedACH,
           ReceiptBankAccountCreditCode,
           ReceiptBankAccountNumber_CT,
           ReceiptBankACHRoutingNumber,
		   CustomerBankAccountDebitCode,
           CustomerBankAccountACHRoutingNumber,
           CustomerBankAccountNumber_CT,
           CustomerName,
           CostCenterId,
		   ACHAmount,
		   CashTypeId
    INTO #InitialGrouping
    FROM dbo.ACHSchedule_Extract
    WHERE ACHSchedule_Extract.JobStepInstanceId = @JobStepInstanceId
          AND ACHSchedule_Extract.ErrorCode = '_';

	SELECT *,
	DENSE_RANK() OVER(PARTITION BY FileHeaderId ORDER BY BatchHeaderId,EntryDetailId) TraceNumber
	INTO #FinalGrouping
	FROM #InitialGrouping;

	CREATE NONCLUSTERED INDEX IX_FileHeaderId ON #FinalGrouping(FileHeaderId);
	CREATE NONCLUSTERED INDEX IX_BatchHeaderId ON #FinalGrouping(BatchHeaderId);
	CREATE NONCLUSTERED INDEX IX_EntryDetailId ON #FinalGrouping(EntryDetailId);
	CREATE NONCLUSTERED INDEX IX_ReceiptId ON #FinalGrouping(ReceiptId);

    INSERT INTO dbo.ACHFileHeaders
      (ACHFileHeaderRecordTypeCode,
       ACHFileHeaderPriorityCode,
       Destination,
       Origin,
       ACHFileHeaderFileIDModifier,
       ACHFileHeaderRecordSize,
       ACHFileHeaderBlockingFactor,
       ACHFileHeaderFormatCode,
       DestName,
       OriginName,
       ACHFileControlRecordTypeCode,
       PAPFileHeaderRecordTypeCode,
       PAPFileHeaderTransactionCode,
       CurrencyName,
       PAPFileHeaderInputType,
       PAPFileControlRecordTypeCode,
       PAPFileControlTransactionCode,
       CurrencyId,
       IsPrivateLabel,
       RemitToId,
       RemitToName,
       LegalEntityBankAccountId,
       GenerateSeparateOneTimeACH,
       ACHOperatorConfigId,
       FileFormat,
       TotalDebitAmount,
       NACHAFilePaddingOption,
       GenerateControlFile,
       ACISCustomerNumber,
       SourceOfInput,
       CurrenySymbol,
       LegalEntityNumber,
       BankBranchName,
       JobStepInstanceId,
       FileHeaderId,
       CreatedById,
       CreatedTime
      )
    OUTPUT INSERTED.Id, INSERTED.FileHeaderId INTO #PersistedFileHeaders
    SELECT MAX(NACHHeaderConfig.RecordTypeCode),
           MAX(NACHHeaderConfig.PriorityCode),
           MAX(ACHOperatorConfigs.Destination),
           MAX(ACHOperatorConfigs.Origin),
           MAX(NACHHeaderConfig.FileIDModifier),
           MAX(NACHHeaderConfig.RecordSize),
           MAX(NACHHeaderConfig.BlockingFactor),
           MAX(NACHHeaderConfig.FormatCode),
           MAX(ACHOperatorConfigs.DestName),
           MAX(ACHOperatorConfigs.OriginName),
           MAX(NACHHeaderControlConfig.RecordTypeCode),
           MAX(NACHHeaderConfig.RecordTypeCode),
           MAX(NACHHeaderConfig.TransactionCode),
           MAX(FG.CurrencyName) AS Currencyname,
           MAX(NACHHeaderConfig.InputType),
           MAX(NACHHeaderControlConfig.RecordTypeCode),
           MAX(NACHHeaderControlConfig.TransactionCode),
           MAX(FG.CurrencyId) AS CurrencyId,
           MAX(CAST(FG.IsPrivateLabel AS TINYINT)) AS IsPrivateLabel,
           MAX(FG.RemitToId) AS RemitToId,
           MAX(FG.RemitToName) AS RemitToName,
           MAX(FG.LegalEntityBankAccountId) AS LegalEntityBankAccountId,
           MAX(CAST(FG.IsOneTimeACH AS TINYINT)),
           MAX(FG.ACHOperatorConfigId) AS ACHOperatorConfigId,
           MAX(FG.FileFormat),
           SUM(FG.TotalDebitAmount) AS TotalDebitAmount,
           MAX(FG.NACHAFilePaddingOption) AS NACHAFilePaddingOption,
           MAX(CAST(FG.ReceiptBankGenerateControlFile AS TINYINT)) AS GenerateControlFile,
           MAX(FG.ReceiptBankACISCustomerNumber) AS ACISCustomerNumber,
           MAX(FG.ReceiptBankSourceofInput) AS SourceOfInput,
           MAX(FG.CurrencySymbol) AS CurrencySymbol,
           MAX(FG.ReceiptLegalEntityNumber) AS ReceiptLegalEntityNumber,
           MAX(FG.ReceiptBankBranchName) AS ReceiptBankBranchName,
           @JobStepInstanceId,
           FG.FileHeaderId,
           @UpdatedById,
           @UpdatedTime
    FROM #FinalGrouping AS FG
    JOIN #NACHAFileconfigInfo AS NACHHeaderConfig ON NACHHeaderConfig.FileType = FG.FileFormat
                                                     AND NACHHeaderConfig.FileRecordType = @FileHeaderNachaFileRecordType
    JOIN #NACHAFileconfigInfo AS NACHHeaderControlConfig ON NACHHeaderControlConfig.FileType = FG.FileFormat
                                                            AND NACHHeaderControlConfig.FileRecordType = @FileControlNachaFileRecordType
    JOIN dbo.ACHOperatorConfigs ON ACHOperatorConfigs.Id = FG.ACHOperatorConfigId
    GROUP BY FG.FileHeaderId;

    INSERT INTO dbo.ACHBatchHeaders
      (ACHBatchHeaderRecordTypeCode,
       ACHBatchHeaderServiceClassCode,
       PrivateLableName,
       TaxID,
       SEC,
       ACHBatchHeaderCompanyEntryDescription,
       Settlementdate,
       ACHBatchHeaderOriginatorStatusCode,
       OrigDFIID,
       JobStepInstanceId,
       ACHBatchControlRecordTypeCode,
       ACHBatchControlServiceClassCode,
       GenerateBalancedACH,
       ReceiptLegalEntityBankAccountId,
       ReceiptLegalEntityBankAccountCreditCode,
       ReceiptLegalEntityBankAccountNumber_CT,
       ReceiptLegalEntityBankAccountACHRoutingNumber,
       Origin,
       OriginName,
       FileHeaderId,
       BatchHeaderId,
       ACHFileHeaderId,
       CreatedById,
       CreatedTime
      )
    OUTPUT INSERTED.Id, INSERTED.FileHeaderId, INSERTED.BatchHeaderId INTO #PersistedBatchHeaders
    SELECT MAX(NACHBatchConfig.RecordTypeCode),
           MAX(NACHBatchConfig.ServiceClassCode),
           MAX(FG.PrivateLabelName),
           MAX(ACHOperatorConfigs.TaxID),
           MAX(ACHOperatorConfigs.SEC),
           MAX(NACHBatchConfig.CompanyEntryDescription),
           MAX(FG.Settlementdate) AS Settlementdate,
           MAX(NACHBatchConfig.OriginatorStatusCode),
           MAX(ACHOperatorConfigs.OrigDFIID),
           @JobStepInstanceId,
           MAX(NACHBatchControlConfig.RecordTypeCode),
           MAX(NACHBatchControlConfig.ServiceClassCode),
           MAX(CAST(FG.ReceiptBankGenerateBalancedACH AS TINYINT)),
           MAX(FG.ReceiptBankAccountId),
           MAX(FG.ReceiptBankAccountCreditCode),
           MAX(FG.ReceiptBankAccountNumber_CT),
           MAX(FG.ReceiptBankACHRoutingNumber),
           MAX(ACHOperatorConfigs.Origin),
           MAX(ACHOperatorConfigs.OriginName),
           FG.FileHeaderId,
           FG.BatchHeaderId,
           PFH.Id,
           @UpdatedById,
           @UpdatedTime
    FROM #FinalGrouping AS FG
    JOIN dbo.ACHOperatorConfigs ON ACHOperatorConfigs.Id = FG.ACHOperatorConfigId
    JOIN #PersistedFileHeaders AS PFH ON FG.FileHeaderId = PFH.FileHeaderId
    LEFT JOIN #NACHAFileconfigInfo AS NACHBatchConfig ON NACHBatchConfig.FileType = FG.FileFormat
                                                    AND NACHBatchConfig.FileRecordType = @BathcHeaderNachaFileRecordType
    LEFT JOIN #NACHAFileconfigInfo AS NACHBatchControlConfig ON NACHBatchControlConfig.FileType = FG.FileFormat
                                                           AND NACHBatchControlConfig.FileRecordType = @BatchControlNachaFileRecordType
    GROUP BY FG.FileHeaderId, FG.BatchHeaderId, PFH.Id;

    INSERT INTO dbo.ACHEntryDetails
      (ACHEntryDetailRecordTypeCode,
       ACHEntryDetailTransactionCode,
       CustomerBankDebitCode,
       CustomerBankAccountACHRoutingNumber,
       ACHAmount,
       CustomerBankAccountNumber_CT,
       EntityId,
       PartyName,
       ACHEntryDetailAddendaRecordIndicator,
       TraceNumber,
       PAPEntryDetailRecordTypeCode,
       PAPEntryDetailPaymentNumber,
       PAPEntryDetailLanguageCode,
       PAPEntryDetailDestinationCountry,
       PAPEntryDetailOptionalRecordIndicator,
       PAPEntryDetailClientShortName,
       OrigDFIID,
       Currency,
       CustomerBankAccountId,
       CostCenterId,
       JobStepInstanceId,
       ACHBatchHeaderId,
	   EntryDetailId,
       CreatedTime,
       CreatedById,
	   ACHScheduleExtractIds
      )
    OUTPUT INSERTED.Id, INSERTED.EntryDetailId,INSERTED.TraceNumber INTO #PersistedEntryDetails
    SELECT MAX(NACHConfig.RecordTypeCode),
           MAX(NACHConfig.TransactionCode),
           MAX(FG.CustomerBankAccountDebitCode),
           MAX(FG.CustomerBankAccountACHRoutingNumber),
           SUM(FG.TotalDebitAmount),
           MAX(FG.CustomerBankAccountNumber_CT),
           MAX(FG.EntityId),
           MAX(FG.CustomerName),
           MAX(NACHConfig.AddendaRecordIndicator),
           FG.TraceNumber,
           MAX(NACHConfig.RecordTypeCode),
           MAX(NACHConfig.PaymentNumber),
           MAX(NACHConfig.LanguageCode),
           MAX(NACHConfig.DestinationCountry),
           MAX(NACHConfig.OptionalRecordIndicator),
           MAX(NACHConfig.ClientShortName),
           MAX(ACHOperatorConfigs.OrigDFIID),
           MAX(FG.CurrencyName),
           MAX(FG.CustomerBankAccountId),
           MAX(FG.CostCenterId),
           @JobStepInstanceId,
           MAX(PBH.Id),
		   FG.EntryDetailId,
           @UpdatedTime,
           @UpdatedById,
		   STRING_AGG(CAST(FG.Id AS NVARCHAR(MAX)),',')
    FROM #FinalGrouping AS FG
    JOIN #PersistedBatchHeaders AS PBH ON FG.FileHeaderId = PBH.FileHeaderId AND FG.BatchHeaderId = PBH.BatchHeaderId
    JOIN #NACHAFileconfigInfo AS NACHConfig ON NACHConfig.FileType = FG.FileFormat AND NACHConfig.FileRecordType = @EntryDetailRecordNachaFileRecordType
    JOIN dbo.ACHOperatorConfigs ON ACHOperatorConfigs.Id = FG.ACHOperatorConfigId
    GROUP BY FG.EntryDetailId, FG.TraceNumber, PBH.Id;

    INSERT INTO dbo.ACHReceipts
      (CreatedById,
       CreatedTime,
       TraceNumber,
       Currency,
       ReceiptClassification,
       LegalEntityId,
       LineOfBusinessId,
       CostCenterId,
       InstrumentTypeId,
       BranchId,
       ContractId,
       EntityType,
       ReceiptGLTemplateId,
       CustomerId,
       ReceiptAmount,
       BankAccountId,
       CurrencyId,
       ReceiptType,
       CheckNumber,
       SettlementDate,
       Status,
       UnallocatedAmount,
       ExtractReceiptId,
       IsOneTimeACH,
       InactivateBankAccountId,
	   ACHEntryDetailId,
	   IsActive,
	   ReceiptTypeId,
	   OneTimeACHId,
	   UpdateJobStepInstanceId,
	   CashTypeId
      )
    OUTPUT INSERTED.Id, INSERTED.ExtractReceiptId INTO #PersistedACHReceiptDetails
    SELECT @UpdatedById,
           @UpdatedTime,
           RIGHT(REPLICATE('0',7)+ CAST(MAX(FG.TraceNumber) AS NVARCHAR(MAX)),7),
           MAX(CurrencyCode),
           MAX(ReceiptClassificationType),
           MAX(ReceiptLegalEntityId),
           MAX(LineofBusinessId),
           MAX(CostCenterId),
           MAX(InstrumentTypeId),
           MAX(BranchId),
           MAX(ContractId),
           CASE WHEN MAX(EntityType) = 'ProgressLoan' THEN 'Loan' ELSE MAX(EntityType) END,
           MAX(GLTemplateId),
           MAX(CustomerId),
           CASE WHEN SUM(TotalDebitAmount) < 0.00 THEN 0.00 ELSE SUM(TotalDebitAmount) END,
           MAX(ReceiptBankAccountId),
           MAX(CurrencyId),
           MAX(ReceiptTypeName),
           MAX(CheckNumber),
           MAX(SettlementDate),
           '_',
           SUM(UnallocatedAmount),
           ReceiptId,
           MAX(IsOneTimeACH),
           CASE WHEN MAX( CAST(FG.OneTimeBankAccount as INT)) = 1 THEN MAX(CustomerBankAccountId) ELSE NULL END,
		   MAX(ED.Id) ACHEntryDetailId,
		   1,
		   MAX(ReceiptTypeId),
		   MAX(FG.OneTimeACHId),
		   @JobStepInstanceId,
		   MAX(FG.CashTypeId)
    FROM #FinalGrouping AS FG
	JOIN #PersistedEntryDetails ED ON FG.EntryDetailId = ED.EntryDetailId AND FG.TraceNumber = ED.TraceNumber
	GROUP BY ReceiptId;

    INSERT INTO dbo.ACHReceiptApplicationReceivableDetails
      (AmountApplied,
       CreatedById,
       CreatedTime,
       TaxApplied,
       ReceivableDetailId,
       InvoiceId,
       ReceivableId,
       ACHReceiptId,
	   ContractId,
	   DiscountingId,
       ScheduleId,
	   IsActive,
	   LeaseComponentAmountApplied,
	   NonLeaseComponentAmountApplied,
      BookAmountApplied
      )
    SELECT ReceivableDetailAmount,
           @UpdatedById,
           @UpdatedTime,
           ReceivableDetailTaxAmount,
           ReceivableDetailId,
           ReceivableInvoiceId,
           ReceivableId,
		   RRD.Id,
		   ContractId,
	       DiscountingId,
           ScheduleId,
		   1,
		   0.00,
		   0.00,
                   0.00
    FROM #PersistedACHReceiptDetails AS RRD
	JOIN #FinalGrouping AS FG ON RRD.ExtractReceiptId = FG.ReceiptId
	JOIN #PersistedEntryDetails ED ON FG.EntryDetailId = ED.EntryDetailId AND FG.TraceNumber = ED.TraceNumber
	WHERE FG.ReceivableDetailId IS NOT NULL AND FG.ACHAmount <> 0.0

    INSERT INTO dbo.ACHReceiptAssociatedStatementInvoices
      (CreatedById,
       CreatedTime,
       StatementInvoiceId,
       ACHReceiptId
      )
    SELECT DISTINCT
           @UpdatedById,
           @UpdatedTime,
           OTACHSI.ReceivableInvoiceId,
           RRD.Id
    FROM #PersistedACHReceiptDetails AS RRD
    JOIN #FinalGrouping AS ACHE ON RRD.ExtractReceiptId = ACHE.ReceiptId
    INNER JOIN dbo.OneTimeACHes AS OTACH ON ACHE.OneTimeACHId = OTACH.Id
    INNER JOIN dbo.OneTimeACHInvoices AS OTACHI ON OTACHI.OneTimeACHId = OTACH.Id AND OTACHI.IsActive = 1
    INNER JOIN dbo.OneTimeACHStatementInvoiceAssociations AS OTACHSI ON OTACHI.Id = OTACHSI.OneTimeACHInvoiceId AND OTACHSI.ReceivableInvoiceId = ACHE.ReceivableInvoiceId AND OTACHSI.IsActive = 1 AND OTACHI.IsStatementInvoice = 1;

    DROP TABLE #FinalGrouping;
    DROP TABLE #NACHAFileconfigInfo;

    SET ANSI_WARNINGS ON;
  END;

GO
