SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[ValidatePostByFileExcelExtract] 
(
	@JobStepInstanceId			BIGINT,
	@AllowInterCompanyTransfer  BIT,
	@IsWithHoldingTaxApplicable BIT,
	@DefaultLegalEntityId		BIGINT, 
	@ReceiptBatchId      		BIGINT, 
	@ErrorMessages				ReceiptPostByFileErrorMessages READONLY,
	@GLTemplateId				BIGINT,
	@HasOnlyFailedRecords		BIT OUT,

	@LegalEntityStatusInactive	NVARCHAR(8),	
	@ContractStatusCancelled	NVARCHAR(9),
	@ContractStatusInactive	NVARCHAR(8),
	@ContractTypeLease	NVARCHAR(5),
	@ContractTypeLeveragedLease	NVARCHAR(14),
	@ContractTypeLoan	NVARCHAR(4),
	@ContractTypeProgressLoan	NVARCHAR(12),
	@ReceiptEntityTypeLease	NVARCHAR(5),
	@ReceiptEntityTypeLeveragedLease	NVARCHAR(14),
	@ReceiptEntityTypeLoan	NVARCHAR(4),
	@ReceiptEntityTypeDiscounting	NVARCHAR(11),
	@ReceiptEntityTypeCustomer	NVARCHAR(8),
	@ReceiptEntityTypeBlank	NVARCHAR(1),
	@DiscountingBookingStatusApproved	NVARCHAR(8),
	@DiscountingBookingStatusFullyPaidOff	NVARCHAR(12),
	@CustomerStatusActive	NVARCHAR(6),
	@ReceiptModeMoneyOrder	NVARCHAR(10),
	@AssumptionApprovalStatusApproved	NVARCHAR(8),
	@ReceivableEntityTypeDT	NVARCHAR(2),
	@ReceivableEntityTypeCT	NVARCHAR(2),
	@LoanStatusCancelled	NVARCHAR(9),
	@ReceivableTypeLoanInterest	NVARCHAR(12),
	@ReceivableTypeLoanPrincipal	NVARCHAR(13),
	@NonAccrualFromInvoice NVARCHAR(21),
	@NonAccrualFromContract NVARCHAR(22),
	@NonAccrualFromBoth NVARCHAR(18),
	@NonAccrualSingleWithOnlyNonRentals NVARCHAR(24),
	@NonAccrualSingleWithRentals NVARCHAR(17),
	@NonAccrualSingleUnAllocated NVARCHAR(17),
	@PaydownStatusSubmitted NVARCHAR(17),
	@ActivatePartialPaydownOrPayoff BIT
)
AS
BEGIN
	SET NOCOUNT OFF;
	DECLARE @errorMessage NVARCHAR(4000)
	SELECT * INTO #ErrorMessages FROM @ErrorMessages

	SELECT 
	Id,
	LegalEntity,
	EntityType,
	Entity,
	Currency,
	ReceiptType,
	InvoiceNumber,
	ReceiptAmount,
	BankAccount,
	BankName,
	IsApplyCredit,
	CashType,
	LineOfBusiness,
	InstrumentType,
	BankBranchName,
	CostCenter,
	ErrorMessage,
	ComputedInvoiceCustomerId,
	ComputedCustomerId,
	ComputedReceiptEntityType,
	ComputedReceiptTypeId,
	ComputedBankAccountId,
	ComputedCashTypeId,
    ComputedLegalEntityId,
	ComputedLineOfBusinessId,
	ComputedCostCenterId,
	ComputedInstrumentTypeId,
	ComputedPortfolioId,
	ComputedContractId,
	ComputedCurrencyId,
	ComputedBankAccountCurrencyId,
	ComputedContractCurrencyId,
	ComputedInvoiceCurrencyId,
	ComputedCurrencyCodeISO,
	ComputedIsDSL,
	ComputedGLTemplateId,
	ComputedReceivableInvoiceId,
	ComputedDiscountingId,
	NonAccrualCategory,
	ComputedContractLegalEntityId,
	ComputedIsFullPosting,
	ComputedIsGrouped,
	GroupNumber,
	IsInvoiceInMultipleReceipts,
	IsStatementInvoice,
	CreateUnallocatedReceipt,
	Comment,
	ReceivableTaxType
	INTO #ReceiptPostByFileExcel_Extract
	FROM ReceiptPostByFileExcel_Extract WHERE JobStepInstanceId=@JobStepInstanceId;

	CREATE NONCLUSTERED INDEX IX_PostByFileId
    ON #ReceiptPostByFileExcel_Extract (Id);

	-- Validating if ReceiptBatch Currency is equal to Extract's currency
	IF @ReceiptBatchId IS NOT NULL
	BEGIN
		SELECT  @errorMessage = ErrorMessage FROM @ErrorMessages WHERE Code='RBCURR'

		DECLARE @ReceiptBatchCurrency AS NVARCHAR(10)
		SELECT @ReceiptBatchCurrency = CC.ISO
		FROM ReceiptBatches RB
		JOIN Currencies C ON RB.CurrencyId = C.Id
		JOIN CurrencyCodes CC ON C.CurrencyCodeId = CC.Id
		WHERE RB.Id = @ReceiptBatchId

		UPDATE #ReceiptPostByFileExcel_Extract
		SET ErrorMessage = @errorMessage
		WHERE @ReceiptBatchCurrency <> Currency
	END

	--Both File/Job Level LE Calculation
	-- Validating If Legal Entity exists and Calculating Legal Entity Id for both File and Job Level
	SELECT  @errorMessage = ErrorMessage FROM #ErrorMessages WHERE Code='LE1'

	UPDATE RPBF SET
	RPBF.ComputedLegalEntityId=
	CASE 
		WHEN (RPBF.LegalEntity IS NULL) THEN @DefaultLegalEntityId 
		ELSE LE.Id
	END,
	ErrorMessage=
	CASE 
		WHEN (RPBF.LegalEntity IS NOT NULL AND (LE.LegalEntityNumber IS NULL OR LE.[Status]=@LegalEntityStatusInactive)) THEN @errorMessage
		ELSE ErrorMessage
		END
	FROM #ReceiptPostByFileExcel_Extract AS RPBF LEFT OUTER JOIN LegalEntities AS LE
    ON RPBF.LegalEntity = LE.LegalEntityNumber

	-- Compute PortfolioId 
	UPDATE RPBF SET 
	RPBF.ComputedPortfolioId=P.Id
	FROM #ReceiptPostByFileExcel_Extract RPBF INNER JOIN LegalEntities LE 
	ON RPBF.ComputedLegalEntityId=LE.Id INNER JOIN BusinessUnits BU 
	ON LE.BusinessUnitId=BU.Id INNER JOIN Portfolios P 
	ON BU.PortfolioId=P.Id
	WHERE (BU.IsActive=1 AND P.IsActive=1) 
	AND RPBF.ComputedLegalEntityId IS NOT NULL 


	--Validating whether Entity given is a valid Lease For EntityType Lease and Computing ContractId, ContractCurrencyId, LineOfBusinessId, InstrumentTypeId, and CostCenterId
	SELECT  @errorMessage = ErrorMessage FROM #ErrorMessages WHERE Code='CTR1'

	UPDATE RPBF SET 
	RPBF.ComputedCustomerId=LF.CustomerId, 
	RPBF.ComputedContractLegalEntityId=LF.LegalEntityId,
	RPBF.ComputedContractId=CTR.Id,
	RPBF.ComputedContractCurrencyId=CTR.CurrencyId,
	RPBF.ComputedLineOfBusinessId = LF.LineOfBusinessId,
	RPBF.ComputedInstrumentTypeId = LF.InstrumentTypeId,
	RPBF.ComputedCostCenterId = LF.CostCenterId,
	RPBF.ErrorMessage=
	CASE 
		WHEN (CTR.[Status]=@ContractStatusCancelled OR CTR.[Status]=@ContractStatusInactive OR CTR.SequenceNumber IS NULL OR CTR.ContractType!=@ContractTypeLease) THEN CONCAT(ISNULL(RPBF.ErrorMessage, ''), @errorMessage)
		ELSE RPBF.ErrorMessage
	END
	FROM #ReceiptPostByFileExcel_Extract AS RPBF 
	LEFT OUTER JOIN Contracts AS CTR ON RPBF.Entity=CTR.SequenceNumber
	LEFT OUTER JOIN LeaseFinances AS LF ON LF.ContractId = CTR.Id AND LF.IsCurrent=1
	WHERE RPBF.EntityType=@ReceiptEntityTypeLease 

	--Validating whether Entity given is a valid Leveraged Lease For EntityType Leveraged Lease and Computing ContractId, ContractCurrencyId, LineOfBusinessId, InstrumentTypeId, and CostCenterId

	UPDATE RPBF SET 
	RPBF.ComputedCustomerId=LL.CustomerId, 
	RPBF.ComputedContractLegalEntityId=LL.LegalEntityId,
	RPBF.ComputedContractId=CTR.Id,
	RPBF.ComputedContractCurrencyId=CTR.CurrencyId,
	RPBF.ComputedLineOfBusinessId = LL.LineOfBusinessId,
	RPBF.ComputedInstrumentTypeId = LL.InstrumentTypeId,
	RPBF.ComputedCostCenterId = LL.CostCenterId,
	RPBF.ErrorMessage=
	CASE 
		WHEN (CTR.[Status]=@ContractStatusCancelled OR CTR.[Status]=@ContractStatusInactive OR CTR.SequenceNumber IS NULL OR CTR.ContractType!=@ContractTypeLeveragedLease) THEN CONCAT(ISNULL(RPBF.ErrorMessage, ''), @errorMessage)
		ELSE RPBF.ErrorMessage
	END
	FROM #ReceiptPostByFileExcel_Extract AS RPBF 
	LEFT OUTER JOIN Contracts AS CTR ON RPBF.Entity=CTR.SequenceNumber
	LEFT OUTER JOIN LeveragedLeases AS LL ON LL.ContractId = CTR.Id AND LL.IsCurrent=1
	WHERE RPBF.EntityType=@ReceiptEntityTypeLeveragedLease

	--Validating whether Entity given is a valid Loan/ProgressLoan for EntityType Loan and Computing ContractId, ContractCurrencyId, LineOfBusinessId, InstrumentTypeId, and CostCenterId

	UPDATE RPBF 
	SET RPBF.ComputedCustomerId = LF.CustomerId,
		RPBF.ComputedContractLegalEntityId = LF.LegalEntityId,
		RPBF.ComputedContractId = CTR.Id,
		RPBF.ComputedContractCurrencyId = CTR.CurrencyId,
		RPBF.ComputedLineOfBusinessId = LF.LineOfBusinessId,
		RPBF.ComputedInstrumentTypeId = LF.InstrumentTypeId,
		RPBF.ComputedCostCenterId = LF.CostCenterId,
		RPBF.ErrorMessage=
		CASE 
			WHEN (CTR.[Status]=@ContractStatusCancelled OR CTR.[Status]=@ContractStatusInactive OR CTR.SequenceNumber IS NULL OR (CTR.ContractType!=@ContractTypeLoan AND CTR.ContractType != @ContractTypeProgressLoan) ) THEN CONCAT(ISNULL(RPBF.ErrorMessage, ''), @errorMessage)
			ELSE RPBF.ErrorMessage
		END
	FROM #ReceiptPostByFileExcel_Extract AS RPBF LEFT OUTER JOIN Contracts as CTR
	ON RPBF.Entity=CTR.SequenceNumber
	LEFT OUTER JOIN LoanFinances AS LF ON LF.ContractId = CTR.Id AND LF.IsCurrent=1
	WHERE RPBF.EntityType=@ReceiptEntityTypeLoan

	--Validating whether Entity given is a valid Discounting Loan and Computing DiscountingId, ContractCurrencyId, LineOfBusinessId, InstrumentTypeId, and CostCenterId

	UPDATE RPBF 
	SET RPBF.ComputedContractId = D.Id,
		RPBF.ComputedCustomerId = DF.FunderId,
		RPBF.ComputedContractLegalEntityId = DF.LegalEntityId,
		RPBF.ComputedDiscountingId = D.Id,
		RPBF.ComputedContractCurrencyId = D.CurrencyId,
		RPBF.ComputedLineOfBusinessId = DF.LineOfBusinessId,
		RPBF.ComputedInstrumentTypeId = DF.InstrumentTypeId,
		RPBF.ComputedCostCenterId = DF.CostCenterId,
		RPBF.ErrorMessage=
		CASE 
			WHEN (D.SequenceNumber IS NULL OR (DF.BookingStatus!=@DiscountingBookingStatusApproved AND DF.BookingStatus!=@DiscountingBookingStatusFullyPaidOff)) THEN CONCAT(ISNULL(RPBF.ErrorMessage, ''), @errorMessage)
			ELSE RPBF.ErrorMessage
		END
	FROM #ReceiptPostByFileExcel_Extract AS RPBF 
	LEFT OUTER JOIN Discountings as D ON RPBF.Entity = D.SequenceNumber 
	LEFT OUTER JOIN DiscountingFinances DF ON D.Id = DF.DiscountingId AND DF.IsCurrent = 1 
	WHERE RPBF.EntityType=@ReceiptEntityTypeDiscounting

	--Validating whether Entity given is a valid Customer for EntityType Customer

	UPDATE RPBF SET 
	RPBF.ComputedCustomerId = C.Id,
	RPBF.ErrorMessage=
	CASE 
		WHEN (C.[Status]!=@CustomerStatusActive OR P.PartyNumber IS NULL) THEN CONCAT(ISNULL(RPBF.ErrorMessage, ''), @errorMessage)
		ELSE RPBF.ErrorMessage
	END
	FROM #ReceiptPostByFileExcel_Extract RPBF LEFT OUTER JOIN Parties P
	ON RPBF.Entity=P.PartyNumber LEFT OUTER JOIN Customers C
	ON P.Id=C.Id
	WHERE RPBF.EntityType=@ReceiptEntityTypeCustomer

	-- Checking If Valid Invoice Number and Compute InvoiceCurrencyId and InvoiceCustomerId
	SELECT  @errorMessage = ErrorMessage FROM #ErrorMessages WHERE Code = 'INV1'

	UPDATE RPBF 
	SET RPBF.ComputedReceivableInvoiceId = RI.Id,
		RPBF.ComputedInvoiceCurrencyId = RI.CurrencyId,
		RPBF.ComputedInvoiceCustomerId = RI.CustomerId,
		RPBF.IsStatementInvoice = ISNULL(RI.IsStatementInvoice,0),
		RPBF.ErrorMessage=
		CASE 
			WHEN RID.IsActive=0 OR RI.Number IS NULL THEN CONCAT(ISNULL(RPBF.ErrorMessage, ''), @errorMessage)
			ELSE RPBF.ErrorMessage
		END,
		RPBF.ReceivableTaxType = RI.ReceivableTaxType
	FROM #ReceiptPostByFileExcel_Extract RPBF 
	LEFT OUTER JOIN ReceivableInvoices RI ON RPBF.InvoiceNumber = RI.Number  
	LEFT OUTER JOIN ReceivableInvoiceDetails RID ON RI.Id = RID.ReceivableInvoiceId
	WHERE RPBF.InvoiceNumber IS NOT NULL  

	UPDATE RPBF 
	SET RPBF.ComputedReceivableInvoiceId = RI.Id,
		RPBF.ComputedInvoiceCurrencyId = RI.CurrencyId,
		RPBF.ComputedInvoiceCustomerId = RI.CustomerId,
		RPBF.IsStatementInvoice = RI.IsStatementInvoice,
		RPBF.ErrorMessage=
		CASE 
			WHEN (RID.IsActive=0 OR RI.Number IS NULL) THEN CONCAT(ISNULL(RPBF.ErrorMessage, ''), @errorMessage)
			ELSE RPBF.ErrorMessage
		END,
		RPBF.ReceivableTaxType = RI.ReceivableTaxType
	FROM #ReceiptPostByFileExcel_Extract RPBF 
	INNER JOIN ReceivableInvoices RI ON RPBF.InvoiceNumber = RI.Number 
	INNER JOIN ReceivableInvoiceStatementAssociations SI ON SI.StatementInvoiceId = RI.Id
	INNER JOIN ReceivableInvoiceDetails RID ON SI.ReceivableInvoiceId = RID.ReceivableInvoiceId
	WHERE RPBF.InvoiceNumber IS NOT NULL 

	-- Update IsApplyCredit To TRUE for VAT

	UPDATE #ReceiptPostByFileExcel_Extract
		SET IsApplyCredit = 1
	WHERE IsApplyCredit = 0 AND ReceivableTaxType = 'VAT'

	-- Checking for Mandatory Entity if it is DSL Invoice 
	SELECT  @errorMessage = ErrorMessage FROM #ErrorMessages WHERE Code = 'DSL1'

	UPDATE RPBF 
	SET RPBF.ComputedIsDSL = R.IsDSL,
		RPBF.ErrorMessage =
		CASE 
			WHEN (RPBF.Entity IS NULL OR RPBF.EntityType IS NULL) THEN @errorMessage
			ELSE RPBF.ErrorMessage
		END
	FROM #ReceiptPostByFileExcel_Extract RPBF 
	JOIN ReceivableInvoices RI ON RPBF.InvoiceNumber = RI.Number AND RI.IsStatementInvoice = 0 
	JOIN ReceivableInvoiceDetails RID ON RI.Id = RID.ReceivableInvoiceId
	JOIN ReceivableDetails RD ON RD.Id = RID.ReceivableDetailId
	JOIN Receivables R ON R.Id = RD.ReceivableId AND R.IsDSL = 1
	WHERE RPBF.ErrorMessage IS NULL 

	UPDATE RPBF 
	SET RPBF.ComputedIsDSL = ISNULL(R.IsDSL,0),
		RPBF.ErrorMessage =
		CASE 
			WHEN (R.IsDSL = 1 AND (RPBF.Entity IS NULL OR RPBF.EntityType IS NULL)) THEN @errorMessage
			ELSE RPBF.ErrorMessage
		END
	FROM #ReceiptPostByFileExcel_Extract RPBF 
	INNER JOIN ReceivableInvoiceStatementAssociations SI ON RPBF.ComputedReceivableInvoiceId = SI.StatementInvoiceId 
	INNER JOIN ReceivableInvoiceDetails RID ON SI.ReceivableInvoiceId = RID.ReceivableInvoiceId
	INNER JOIN ReceivableDetails RD ON RD.Id = RID.ReceivableDetailId
	INNER JOIN Receivables R ON R.Id = RD.ReceivableId
	WHERE RPBF.ErrorMessage IS NULL AND RPBF.InvoiceNumber IS NOT NULL  

	UPDATE RPBF 
	SET RPBF.ComputedIsDSL = LF.IsDailySensitive,
		RPBF.ErrorMessage =
		CASE 
			WHEN (LF.IsDailySensitive = 1 AND (RPBF.Entity IS NULL OR RPBF.EntityType IS NULL)) THEN @errorMessage
			ELSE RPBF.ErrorMessage
		END
	FROM #ReceiptPostByFileExcel_Extract RPBF 
	INNER JOIN Contracts CTR
	ON RPBF.ComputedContractId=CTR.Id INNER JOIN LoanFinances LF
	ON CTR.Id=LF.ContractId AND LF.IsCurrent=1
	WHERE RPBF.ErrorMessage IS NULL AND RPBF.InvoiceNumber IS NULL 

	--Validate whether Customer-based records are within the LE's portfolio
	SELECT  @errorMessage = ErrorMessage FROM #ErrorMessages WHERE Code='CSTMRLE'

	UPDATE RPBF SET 
	RPBF.ErrorMessage=
	CASE 
		WHEN (RPBF.ComputedPortfolioId!=P.PortfolioId) THEN @errorMessage
	END
	FROM #ReceiptPostByFileExcel_Extract RPBF LEFT OUTER JOIN Parties P
	ON (RPBF.ComputedCustomerId=P.Id) 
	WHERE RPBF.EntityType=@ReceiptEntityTypeCustomer AND RPBF.ErrorMessage IS NULL
	AND RPBF.ComputedPortfolioId IS NOT NULL AND RPBF.ComputedCustomerId IS NOT NULL

	--Validating BankAccountNumber if exists in DB
	SELECT  @errorMessage = ErrorMessage FROM #ErrorMessages WHERE Code='BANKACC'

	UPDATE RPBF SET
	RPBF.ErrorMessage = 
	CASE
		WHEN (BA.Id IS NULL) THEN @errorMessage
	END
	FROM #ReceiptPostByFileExcel_Extract RPBF LEFT OUTER JOIN BankAccounts BA
	ON RPBF.BankAccount=BA.LegalEntityAccountNumber
	WHERE RPBF.ErrorMessage IS NULL 

	--Validating BankBranchName if exists in DB
	SELECT  @errorMessage = ErrorMessage FROM #ErrorMessages WHERE Code='BANKBRNCH'

	UPDATE RPBF SET
	RPBF.ErrorMessage = 
	CASE
		WHEN (BB.Id IS NULL) THEN @errorMessage
	END
	FROM #ReceiptPostByFileExcel_Extract RPBF LEFT OUTER JOIN BankBranches BB
	ON RPBF.BankBranchName=BB.[Name]
	WHERE RPBF.ErrorMessage IS NULL 

	--Validating BankName if exists in DB
	SELECT  @errorMessage = ErrorMessage FROM #ErrorMessages WHERE Code='BANKNAME'

	UPDATE RPBF SET
	RPBF.ErrorMessage = 
	CASE
		WHEN (BB.Id IS NULL) THEN @errorMessage
	END
	FROM #ReceiptPostByFileExcel_Extract RPBF LEFT OUTER JOIN BankBranches BB
	ON RPBF.BankName=BB.BankName
	WHERE RPBF.ErrorMessage IS NULL

	--Validating Bank Association
	SELECT  @errorMessage = ErrorMessage FROM #ErrorMessages WHERE Code='BANKLE'

	SELECT 
		RPBF.Id AS ExtractId, BA.Id AS BankAccountId, BA.CurrencyId AS BankCurrencyId
	INTO #ValidBankInfoFileRecordIds 
	FROM #ReceiptPostByFileExcel_Extract AS RPBF INNER JOIN LegalEntityBankAccounts LEBA
	ON RPBF.ComputedLegalEntityId=LEBA.LegalEntityId INNER JOIN BankAccounts BA
	ON (LEBA.BankAccountId=BA.Id AND RPBF.BankAccount=BA.LegalEntityAccountNumber) INNER JOIN BankBranches BB
	ON (BA.BankBranchId=BB.Id AND RPBF.BankBranchName=BB.[Name] AND RPBF.BankName=BB.BankName)
	WHERE RPBF.ErrorMessage IS NULL AND (BA.IsActive=1 AND BA.LegalEntityAccountNumber IS NOT NULL AND BB.[Name] IS NOT NULL AND  BB.BankName IS NOT NULL)
	
	UPDATE RPBF SET
	RPBF.ComputedBankAccountId = VR.BankAccountId,
	RPBF.ComputedBankAccountCurrencyId = VR.BankCurrencyId, 
	RPBF.ErrorMessage = CASE WHEN VR.ExtractId IS NULL THEN @errorMessage ELSE RPBF.ErrorMessage END
	FROM #ReceiptPostByFileExcel_Extract RPBF LEFT OUTER JOIN #ValidBankInfoFileRecordIds VR on RPBF.Id=VR.ExtractId
	WHERE RPBF.ErrorMessage IS NULL
	
	-- Preliminary File CurrencyISO Validation and Computing CurrencyId and CurrencyCodeISO
	SELECT  @errorMessage = ErrorMessage FROM #ErrorMessages WHERE Code='CC1'

	UPDATE RPBF SET 
	RPBF.ComputedCurrencyId=C.Id,
	RPBF.ComputedCurrencyCodeISO=CC.ISO,
	RPBF.ErrorMessage = 
	CASE 
		WHEN (CC.ISO IS NULL OR CC.IsActive=0 OR C.Id IS NULL OR C.IsActive=0) THEN @errorMessage
	END
	FROM #ReceiptPostByFileExcel_Extract AS RPBF LEFT OUTER JOIN CurrencyCodes AS CC
    ON RPBF.Currency = CC.ISO LEFT OUTER JOIN Currencies AS C
	ON CC.Id=C.CurrencyCodeId
	WHERE RPBF.ErrorMessage IS NULL


	-- Validating if File | Invoice | Contract | Bank Account CurrencyIds match
	SELECT  @errorMessage = ErrorMessage FROM #ErrorMessages WHERE Code='CC2'

	UPDATE RPBF SET
	RPBF.ErrorMessage=
	CASE
		WHEN (RPBF.ComputedInvoiceCurrencyId IS NOT NULL AND (RPBF.ComputedInvoiceCurrencyId != RPBF.ComputedCurrencyId)) THEN @errorMessage
		WHEN (RPBF.ComputedContractCurrencyId IS NOT NULL AND (RPBF.ComputedContractCurrencyId != RPBF.ComputedCurrencyId)) THEN @errorMessage
		WHEN (RPBF.ComputedBankAccountCurrencyId IS NOT NULL AND (RPBF.ComputedBankAccountCurrencyId != RPBF.ComputedCurrencyId)) THEN @errorMessage
	END
	FROM #ReceiptPostByFileExcel_Extract RPBF 
	WHERE RPBF.ErrorMessage IS NULL


	-- #InvoiceDetailsTable will hold for each EntityId and will be used for Invoice Validations and Non-Accrual validations
	CREATE TABLE #InvoiceDetailsTable (
		ReceivableInvoiceId BIGINT,
		EntityId BIGINT,
		EntityType NVARCHAR(4),
		TotalPositiveBalance DECIMAL(16,2),
		TotalNegativeBalance DECIMAL(16,2)
	)
	
	INSERT INTO #InvoiceDetailsTable
	SELECT RI.Id, RID.EntityId, RID.EntityType,
	PositiveBalance=
	SUM(
	CASE 
		WHEN (RID.EffectiveBalance_Amount+RID.EffectiveTaxBalance_Amount-ISNULL(RDWTH.EffectiveBalance_Amount, 0.00))>0 THEN 
			(RID.EffectiveBalance_Amount+RID.EffectiveTaxBalance_Amount-ISNULL(RDWTH.EffectiveBalance_Amount, 0.00))
		ELSE 0
	END
	),
	NegativeBalance=
	SUM(
	CASE 
		WHEN (RID.EffectiveBalance_Amount+RID.EffectiveTaxBalance_Amount-ISNULL(RDWTH.EffectiveBalance_Amount, 0.00))<0 THEN 
			(RID.EffectiveBalance_Amount+RID.EffectiveTaxBalance_Amount-ISNULL(RDWTH.EffectiveBalance_Amount, 0.00)) 
		ELSE 0
	END
	)
	FROM #ReceiptPostByFileExcel_Extract RPBF 
	INNER JOIN ReceivableInvoices RI ON RPBF.ComputedReceivableInvoiceId = RI.Id AND RI.IsStatementInvoice = 0 
	INNER JOIN ReceivableInvoiceDetails RID ON RI.Id=RID.ReceivableInvoiceId AND RI.IsStatementInvoice = 0 AND RID.IsActive=1
	LEFT JOIN ReceivableDetailsWithholdingTaxDetails RDWTH ON RID.ReceivableDetailId = RDWTH.ReceivableDetailId AND RDWTH.IsActive = 1
	GROUP BY RI.Id, RID.EntityId, RID.EntityType
	
	INSERT INTO #InvoiceDetailsTable
	SELECT RI.StatementInvoiceId AS Id, RID.EntityId, RID.EntityType,
	PositiveBalance=
	SUM(
	CASE 
		WHEN (RID.EffectiveBalance_Amount+RID.EffectiveTaxBalance_Amount-ISNULL(RDWTH.EffectiveBalance_Amount, 0.00))>0 THEN 
			(RID.EffectiveBalance_Amount+RID.EffectiveTaxBalance_Amount-ISNULL(RDWTH.EffectiveBalance_Amount, 0.00))
		ELSE 0
	END
	),
	NegativeBalance=
	SUM(
	CASE 
		WHEN (RID.EffectiveBalance_Amount+RID.EffectiveTaxBalance_Amount-ISNULL(RDWTH.EffectiveBalance_Amount, 0.00))<0 THEN 
			(RID.EffectiveBalance_Amount+RID.EffectiveTaxBalance_Amount-ISNULL(RDWTH.EffectiveBalance_Amount, 0.00)) 
		ELSE 0
	END
	)
	FROM #ReceiptPostByFileExcel_Extract RPBF 
	INNER JOIN ReceivableInvoiceStatementAssociations RI ON RPBF.ComputedReceivableInvoiceId = RI.StatementInvoiceId 
	INNER JOIN ReceivableInvoiceDetails RID ON RI.ReceivableInvoiceId = RID.ReceivableInvoiceId AND RID.IsActive=1
	LEFT JOIN ReceivableDetailsWithholdingTaxDetails RDWTH ON RID.ReceivableDetailId = RDWTH.ReceivableDetailId AND RDWTH.IsActive = 1
	GROUP BY RI.StatementInvoiceId, RID.EntityId, RID.EntityType 
	
	--Compute whether Invoice/Contract is Non-Accrual Loan
	UPDATE RPBF SET
	RPBF.NonAccrualCategory=
	CASE
		WHEN (INVCTR.IsNonAccrual=1 AND (CTR.IsNonAccrual=0 OR CTR.IsNonAccrual IS NULL) AND RPBF.ComputedReceivableInvoiceId IS NOT NULL) THEN @NonAccrualFromInvoice
		WHEN ((INVCTR.IsNonAccrual=0 OR INVCTR.IsNonAccrual IS NULL) AND CTR.IsNonAccrual=1 AND RPBF.ComputedReceivableInvoiceId IS NULL) THEN @NonAccrualFromContract
		WHEN (INVCTR.IsNonAccrual=1 AND CTR.IsNonAccrual=1) THEN @NonAccrualFromBoth
	END
	FROM #ReceiptPostByFileExcel_Extract RPBF LEFT OUTER JOIN
	#InvoiceDetailsTable INV ON 
		RPBF.ComputedReceivableInvoiceId = INV.ReceivableInvoiceId AND 
		INV.EntityType=@ReceivableEntityTypeCT
	LEFT OUTER JOIN Contracts INVCTR ON 
		INV.EntityId=INVCTR.Id AND 
		INVCTR.ContractType=@ContractTypeLoan
	LEFT OUTER JOIN Contracts CTR ON
		RPBF.ComputedContractId=CTR.Id AND 
		CTR.ContractType=@ContractTypeLoan
	WHERE RPBF.ErrorMessage IS NULL AND RPBF.ComputedIsDSL=0

	--Check Distinct Invoices in File for Non-Accrual Loans
	SELECT  @errorMessage = ErrorMessage FROM #ErrorMessages WHERE Code = 'NONACCINV'
	
	;WITH NonAccrualInvoiceCount AS(
		SELECT RPBF.ComputedReceivableInvoiceId AS InvoiceId
		FROM #ReceiptPostByFileExcel_Extract RPBF
		WHERE RPBF.ErrorMessage IS NULL AND RPBF.ComputedReceivableInvoiceId IS NOT NULL AND RPBF.NonAccrualCategory IS NOT NULL
		GROUP BY RPBF.ComputedReceivableInvoiceId
		HAVING COUNT(1)>1
	)
	UPDATE RPBF SET
	RPBF.ErrorMessage=@errorMessage
	FROM #ReceiptPostByFileExcel_Extract RPBF INNER JOIN NonAccrualInvoiceCount NA
	ON RPBF.ComputedReceivableInvoiceId=NA.InvoiceId
	WHERE RPBF.ErrorMessage IS NULL AND RPBF.ComputedReceivableInvoiceId IS NOT NULL AND RPBF.NonAccrualCategory IS NOT NULL

	--Check Invoice LegalEntity with Contract LegalEntity for Non-Accrual
	SELECT  @errorMessage = ErrorMessage FROM #ErrorMessages WHERE Code = 'NONACCLE'

	UPDATE RPBF SET
	RPBF.ErrorMessage=@errorMessage
	FROM #ReceiptPostByFileExcel_Extract RPBF INNER JOIN ReceivableInvoices RI
	ON RPBF.ComputedReceivableInvoiceId=RI.Id AND RI.IsStatementInvoice = 0 AND RPBF.ComputedReceivableInvoiceId IS NOT NULL
	WHERE RPBF.ComputedLegalEntityId!=RI.LegalEntityId AND RPBF.NonAccrualCategory IS NOT NULL
	AND RPBF.ErrorMessage IS NULL
	 

	CREATE TABLE #NonAccrualInvoiceInfo (
	InvoiceId BIGINT,
	ContractId BIGINT,
	CountOfRentals BIGINT,
	NonAccrualPayDownId BIGINT
	)
	--Making Temporary Table with Non-Accrual Information
	;WITH DumpExtractInvoiceIds AS (
		SELECT distinct RPBF.ComputedReceivableInvoiceId AS InvoiceId,LP.Id AS NonAccrualPayDownId 
		FROM #ReceiptPostByFileExcel_Extract RPBF
		LEFT JOIN LoanPaydowns LP ON RPBF.ComputedReceivableInvoiceId=LP.InvoiceId AND LP.[Status] = @PaydownStatusSubmitted
		WHERE ErrorMessage IS NULL AND ComputedReceivableInvoiceId IS NOT NULL AND NonAccrualCategory IS NOT NULL
	)
	INSERT INTO #NonAccrualInvoiceInfo
	SELECT 
	RI.Id AS InvoiceId,  
	R.EntityId AS ContractId,
	CountOfRentals=
	SUM(
	CASE
		WHEN (RI.IsStatementInvoice = 0 AND (RT.[Name]=@ReceivableTypeLoanInterest OR RT.[Name]=@ReceivableTypeLoanPrincipal)) THEN 1
		ELSE 0
	END
	),
	INV.NonAccrualPayDownId AS NonAccrualPayDownId	
	FROM DumpExtractInvoiceIds INV LEFT JOIN ReceivableInvoices RI
	ON INV.InvoiceId=RI.Id AND RI.IsStatementInvoice = 0 LEFT JOIN ReceivableInvoiceDetails RID
	ON RI.Id=RID.ReceivableInvoiceId LEFT JOIN ReceivableDetails RD
	ON RID.ReceivableDetailId=RD.Id AND RD.IsActive=1 LEFT JOIN Receivables R
	ON RD.ReceivableId=R.Id AND R.EntityType=@ReceivableEntityTypeCT LEFT JOIN ReceivableCodes RC
	ON R.ReceivableCodeId=RC.Id LEFT JOIN ReceivableTypes RT 
	ON RC.ReceivableTypeId=RT.Id 
	WHERE R.IsActive=1 AND (R.IsDummy=0 OR INV.NonAccrualPayDownId IS NOT NULL) AND R.IsCollected=1 AND (RD.EffectiveBookBalance_Amount+RD.EffectiveBalance_Amount)!=0
	GROUP BY RI.Id, R.EntityId,INV.NonAccrualPayDownId


	SELECT DISTINCT ComputedReceivableInvoiceId AS InvoiceId 
	INTO #DumpExtractInvoiceIds 
	FROM #ReceiptPostByFileExcel_Extract 
	WHERE ErrorMessage IS NULL AND ComputedReceivableInvoiceId IS NOT NULL AND NonAccrualCategory IS NOT NULL
	
	INSERT INTO #NonAccrualInvoiceInfo
	SELECT 
	RI.StatementInvoiceId AS InvoiceId,  
	R.EntityId AS ContractId,
	CountOfRentals=
	SUM(
	CASE
		WHEN (RT.[Name]=@ReceivableTypeLoanInterest OR RT.[Name]=@ReceivableTypeLoanPrincipal) THEN 1
		ELSE 0
	END
	),
	null AS NonAccrualPayDownId
	FROM #DumpExtractInvoiceIds INV INNER JOIN ReceivableInvoiceStatementAssociations RI
	ON INV.InvoiceId=RI.StatementInvoiceId INNER JOIN ReceivableInvoiceDetails RID
	ON RI.ReceivableInvoiceId=RID.ReceivableInvoiceId INNER JOIN ReceivableDetails RD
	ON RID.ReceivableDetailId=RD.Id AND RD.IsActive=1 INNER JOIN Receivables R
	ON RD.ReceivableId=R.Id AND R.EntityType=@ReceivableEntityTypeCT INNER JOIN ReceivableCodes RC
	ON R.ReceivableCodeId=RC.Id INNER JOIN ReceivableTypes RT 
	ON RC.ReceivableTypeId=RT.Id 
	WHERE R.IsActive=1 AND R.IsDummy=0 AND R.IsCollected=1 AND (RD.EffectiveBookBalance_Amount+RD.EffectiveBalance_Amount)!=0
	GROUP BY RI.StatementInvoiceId, R.EntityId

	--Non-Accrual Validations
	DECLARE @errorMessage2 NVARCHAR(4000)
	DECLARE @errorMessage3 NVARCHAR(4000)
	DECLARE @errorMessage4 NVARCHAR(4000)

	SELECT  @errorMessage = ErrorMessage FROM #ErrorMessages WHERE Code = 'NONACCR1' --Contract number needs to be specified for posting Non accrual loan receipt
	SELECT  @errorMessage2 = ErrorMessage FROM #ErrorMessages WHERE Code = 'INV2' --Provided Receipt Entity doesnt match Invoice Entity
	SELECT  @errorMessage3 = ErrorMessage FROM #ErrorMessages WHERE Code = 'NONACCR2' --Receipt Amount should not be greater than the outstanding balance
	SELECT  @errorMessage4 = ErrorMessage FROM #ErrorMessages WHERE Code = 'CSHTYPMAN' --Cash Type Should Be mandatory for Unallocated 

	;WITH DumpContractIds AS(
		SELECT ComputedContractId AS ContractId, Max(IsNull(InvoiceNumber, -1)) AS InvoiceNumber FROM #ReceiptPostByFileExcel_Extract RPBF
		WHERE RPBF.ErrorMessage IS NULL AND RPBF.ComputedContractId IS NOT NULL AND RPBF.NonAccrualCategory IS NOT NULL 
		group by ComputedContractId
	), OutstandingBalanceOfRentalReceivables AS (
		SELECT DumpContractIds.ContractId, SUM(R.TotalEffectiveBalance_Amount) AS RentalBalanceOfContract FROM DumpContractIds INNER JOIN Receivables R
		ON DumpContractIds.ContractId=R.EntityId AND R.EntityType=@ReceivableEntityTypeCT INNER JOIN ReceivableCodes RC
		ON R.ReceivableCodeId=RC.Id INNER JOIN ReceivableTypes RT 
		ON RC.ReceivableTypeId=RT.Id AND (RT.[Name]=@ReceivableTypeLoanInterest OR RT.[Name]=@ReceivableTypeLoanPrincipal)
		GROUP BY DumpContractIds.ContractId
	), OutstandingTaxBalanceOfNonRentalReceivables AS (
		SELECT DumpContractIds.ContractId, ReceivableId = R.Id, SUM(ReceivableTaxes.EffectiveBalance_Amount) AS RentalTaxBalanceOfContract 
		FROM DumpContractIds INNER JOIN Receivables R ON DumpContractIds.ContractId=R.EntityId AND R.EntityType=@ReceivableEntityTypeCT 
		INNER JOIN ReceivableTaxes ON R.Id = ReceivableTaxes.ReceivableId
		INNER JOIN ReceivableCodes RC ON R.ReceivableCodeId=RC.Id 
		INNER JOIN ReceivableTypes RT ON RC.ReceivableTypeId=RT.Id 
			AND (RT.[Name]!=@ReceivableTypeLoanInterest AND RT.[Name]!=@ReceivableTypeLoanPrincipal) 
		INNER JOIN LoanFinances ON DumpContractIds.ContractId = LoanFinances.ContractId AND LoanFinances.IsCurrent = 1
		INNER JOIN LoanPaydowns ON LoanFinances.Id = LoanPaydowns.LoanFinanceId AND LoanPaydowns.[Status] = @PaydownStatusSubmitted
		INNER JOIN ReceivableInvoices ON ReceivableInvoices.Number = DumpContractIds.InvoiceNumber AND ReceivableInvoices.Id = LoanPaydowns.InvoiceId		GROUP BY DumpContractIds.ContractId, R.Id
	), OutstandingBalanceOfNonRentalReceivables AS (
		SELECT DumpContractIds.ContractId, SUM(R.TotalEffectiveBalance_Amount + IsNull(TaxDetails.RentalTaxBalanceOfContract, 0.00)) AS RentalBalanceOfContract 
		FROM DumpContractIds
		INNER JOIN Receivables R ON DumpContractIds.ContractId=R.EntityId AND R.EntityType=@ReceivableEntityTypeCT 		
		INNER JOIN ReceivableCodes RC ON R.ReceivableCodeId=RC.Id 
		INNER JOIN ReceivableTypes RT 
		ON RC.ReceivableTypeId=RT.Id AND (RT.[Name]!=@ReceivableTypeLoanInterest AND RT.[Name]!=@ReceivableTypeLoanPrincipal) 
		INNER JOIN LoanFinances ON DumpContractIds.ContractId = LoanFinances.ContractId AND LoanFinances.IsCurrent = 1
		INNER JOIN LoanPaydowns ON LoanFinances.Id = LoanPaydowns.LoanFinanceId AND LoanPaydowns.[Status] = @PaydownStatusSubmitted
		INNER JOIN ReceivableInvoices ON ReceivableInvoices.Number = DumpContractIds.InvoiceNumber AND ReceivableInvoices.Id = LoanPaydowns.InvoiceId
		LEFT JOIN OutstandingTaxBalanceOfNonRentalReceivables As TaxDetails ON TaxDetails.ReceivableId = R.Id
		GROUP BY DumpContractIds.ContractId
	)
	UPDATE RPBF SET 
	RPBF.ErrorMessage=
	CASE 
		WHEN (RPBF.NonAccrualCategory=@NonAccrualFromInvoice) THEN CASE
			WHEN (RPBF.EntityType!=@ReceiptEntityTypeLoan AND NonAccFromInv.CountOfRentals>0) THEN @errorMessage
		END
		WHEN (RPBF.NonAccrualCategory=@NonAccrualFromContract) THEN CASE 
			WHEN (RPBF.EntityType!=@ReceiptEntityTypeLoan)	THEN @errorMessage
			WHEN (RPBF.CashType IS NULL)	THEN @errorMessage4
		END
		WHEN (RPBF.NonAccrualCategory=@NonAccrualFromBoth) THEN CASE
			WHEN (RPBF.EntityType!=@ReceiptEntityTypeLoan)	THEN @errorMessage
			WHEN (NonAccFromBoth.ContractId IS NULL)		THEN @errorMessage2
			WHEN (RPBF.ReceiptAmount>(IsNull(OB.RentalBalanceOfContract, 0.00)+ISNULL(OBNONRental.RentalBalanceOfContract, 0))) THEN @errorMessage3
		END
	END
	FROM #ReceiptPostByFileExcel_Extract RPBF  
	LEFT OUTER JOIN	(SELECT InvoiceId, Sum(CountOfRentals) AS CountOfRentals FROM 
					#NonAccrualInvoiceInfo NA GROUP BY InvoiceId) NonAccFromInv 
	ON RPBF.ComputedReceivableInvoiceId=NonAccFromInv.InvoiceId
	LEFT OUTER JOIN #NonAccrualInvoiceInfo NonAccFromBoth
	ON RPBF.ComputedContractId=NonAccFromBoth.ContractId AND RPBF.ComputedReceivableInvoiceId=NonAccFromBoth.InvoiceId
	LEFT OUTER JOIN OutstandingBalanceOfRentalReceivables OB
	ON RPBF.ComputedContractId=OB.ContractId
	LEFT OUTER JOIN OutstandingBalanceOfNonRentalReceivables OBNONRental
	ON RPBF.ComputedContractId=OBNONRental.ContractId
	WHERE RPBF.ErrorMessage IS NULL AND RPBF.NonAccrualCategory IS NOT NULL

	--Converting Non-Accrual LineItems to their respective code-flow identifiers
	UPDATE RPBF SET
	RPBF.NonAccrualCategory=
	CASE 
		WHEN (RPBF.NonAccrualCategory=@NonAccrualFromInvoice) THEN @NonAccrualSingleWithOnlyNonRentals
		WHEN (RPBF.NonAccrualCategory=@NonAccrualFromContract) THEN @NonAccrualSingleUnAllocated
		ELSE RPBF.NonAccrualCategory
	END
	FROM #ReceiptPostByFileExcel_Extract RPBF 
	WHERE RPBF.ErrorMessage IS NULL AND RPBF.NonAccrualCategory IS NOT NULL

	UPDATE RPBF SET
	RPBF.NonAccrualCategory=
	CASE 	
		WHEN (NonAccFromBoth.CountOfRentals>0) THEN @NonAccrualSingleWithRentals
		WHEN (NonAccFromBoth.CountOfRentals=0) THEN @NonAccrualSingleWithOnlyNonRentals
		--Setting NULL for UnIdentified scenarios in the future
	END
	FROM #ReceiptPostByFileExcel_Extract RPBF 
	LEFT OUTER JOIN #NonAccrualInvoiceInfo NonAccFromBoth
	ON RPBF.ComputedContractId=NonAccFromBoth.ContractId AND RPBF.ComputedReceivableInvoiceId=NonAccFromBoth.InvoiceId
	WHERE RPBF.ErrorMessage IS NULL AND RPBF.NonAccrualCategory=@NonAccrualFromBoth

	--Validate Non-Accrual Paydowm Activation	
	DECLARE @errorMessage5 NVARCHAR(4000)
	SELECT  @errorMessage5 = ErrorMessage FROM @ErrorMessages WHERE Code = 'NONACCPAYDOWN' --Amount is not applied towards the payoff/paydown invoice as the Global Parameter ActivatePartialPaydownOrPayoff is set to false 
	DECLARE @errorMessage6 NVARCHAR(4000)
	SELECT  @errorMessage6 = ErrorMessage FROM @ErrorMessages WHERE Code = 'NONACCPAYDOWNAMOUNTNOTAPPLIED' --PayDown quote was not activated as no posting was done towards paydown receivables
	IF @IsWithHoldingTaxApplicable = 1
	BEGIN
		SELECT  @errorMessage = ErrorMessage FROM @ErrorMessages WHERE Code = 'NONACCWHT'

		UPDATE RPBF SET
		RPBF.ErrorMessage=@errorMessage
		FROM #ReceiptPostByFileExcel_Extract RPBF 
		INNER JOIN Receivables R ON RPBF.ComputedContractId=R.EntityId AND R.EntityType=@ReceivableEntityTypeCT
		INNER JOIN ReceivableCodes RC ON R.ReceivableCodeId=RC.Id AND RC.IsActive=1
		INNER JOIN ReceivableTypes RT ON RC.ReceivableTypeId=RT.Id AND RT.IsActive=1
		LEFT JOIN ReceivableWithholdingTaxDetails RWHT ON R.Id=RWHT.ReceivableId AND RWHT.IsActive=1
		WHERE RWHT.Id IS NULL AND RPBF.ErrorMessage IS NULL AND RPBF.NonAccrualCategory=@NonAccrualSingleWithRentals AND R.IsActive=1 
				AND R.IsDummy=0 AND R.IsCollected=1 AND (RT.[Name]=@ReceivableTypeLoanInterest OR RT.[Name]=@ReceivableTypeLoanPrincipal)
	END


	;WITH TaxDetails AS
	(
		SELECT 
			ReceivableDetailId = ReceivableDetails.Id,
			ReceivableTaxBalance = SUM(ReceivableTaxDetails.EffectiveBalance_Amount)
		FROM #ReceiptPostByFileExcel_Extract RPBF
		JOIN #NonAccrualInvoiceInfo NAINV ON RPBF.ComputedReceivableInvoiceId = NAINV.InvoiceId
		INNER JOIN ReceivableInvoiceDetails ON RPBF.ComputedReceivableInvoiceid = ReceivableInvoiceDetails.ReceivableInvoiceId AND ReceivableInvoiceDetails.IsActive = 1
		INNER JOIN ReceivableDetails ON ReceivableInvoiceDetails.ReceivableDetailId = ReceivableDetails.Id AND ReceivableDetails.IsActive = 1
		Inner JOIN ReceivableTaxDetails on ReceivableDetails.Id = ReceivableTaxDetails.ReceivableDetailId AND ReceivableTaxDetails.IsActive = 1
		INNER JOIN Receivables ON Receivables.Id = ReceivableDetails.ReceivableId AND Receivables.IsActive = 1
		INNER JOIN ReceivableCodes ON Receivables.ReceivableCodeId = ReceivableCodes.Id	AND ReceivableCodes.IsActive = 1  
		INNER JOIN ReceivableTypes ON ReceivableCodes.ReceivableTypeId = ReceivableTypes.Id AND ReceivableTypes.IsActive = 1
		WHERE NAINV.NonAccrualPayDownId IS NOT NULL
			AND Receivables.IsCollected = 1
			AND (Receivables.IncomeType!='InterimInterest' AND Receivables.IncomeType!='TakeDownInterest')
		GROUP BY ReceivableDetails.Id
	)
	,ValidateNonAccrualPaydown AS(		
		SELECT 
			RPBF.Id AS RPBF_Id,
			SUM(CASE WHEN Receivables.IsDummy = 0 THEN ReceivableDetails.EffectiveBalance_Amount ELSE 0 END) AS PendingReceivableAmount,
			SUM(CASE WHEN Receivables.IsDummy = 1 THEN ReceivableDetails.EffectiveBalance_Amount + IsNull(TaxDetails.ReceivableTaxBalance ,0.00) ELSE 0 END) AS DummyReceivableAmount	
		FROM #ReceiptPostByFileExcel_Extract RPBF
		JOIN #NonAccrualInvoiceInfo NAINV ON RPBF.ComputedReceivableInvoiceId = NAINV.InvoiceId
		INNER JOIN ReceivableInvoices ON RPBF.ComputedReceivableInvoiceId = ReceivableInvoices.Id
		INNER JOIN Receivables ON Receivables.EntityId = RPBF.ComputedContractId and Receivables.EntityType = 'CT' AND Receivables.IsActive = 1
		INNER JOIN ReceivableDetails ON Receivables.Id = ReceivableDetails.ReceivableId AND ReceivableDetails.IsActive = 1
		INNER JOIN ReceivableCodes ON Receivables.ReceivableCodeId = ReceivableCodes.Id	AND ReceivableCodes.IsActive = 1  
		INNER JOIN ReceivableTypes ON ReceivableCodes.ReceivableTypeId = ReceivableTypes.Id AND ReceivableTypes.IsActive = 1
		LEFT JOIN TaxDetails ON ReceivableDetails.Id = TaxDetails.ReceivableDetailId
		LEFT JOIN ReceivableInvoiceDetails ON ReceivableDetails.Id = ReceivableInvoiceDetails.ReceivableDetailId AND ReceivableInvoiceDetails.IsActive = 1
		WHERE NAINV.NonAccrualPayDownId IS NOT NULL
			AND (Receivables.IsDummy = 0 OR RPBF.ComputedReceivableInvoiceId = ReceivableInvoiceDetails.ReceivableInvoiceId)
			AND Receivables.IsCollected = 1
			AND (ReceivableDetails.EffectiveBookBalance_Amount + ReceivableDetails.EffectiveBalance_Amount + IsNull(TaxDetails.ReceivableTaxBalance, 0.00)) != 0.00
			AND (ReceivableTypes.[Name]='LoanInterest' OR ReceivableTypes.[Name]='LoanPrincipal' OR RPBF.ComputedReceivableInvoiceId = ReceivableInvoiceDetails.ReceivableInvoiceId)
			AND (Receivables.IncomeType!='InterimInterest' AND Receivables.IncomeType!='TakeDownInterest')
			AND Receivables.DueDate <= ReceivableInvoices.DueDate
		GROUP BY RPBF.Id
	)
	UPDATE RPBF SET
	RPBF.CreateUnallocatedReceipt = 
	CASE
	WHEN RPBF.ReceiptAmount > ValidateNonAccrualPaydown.PendingReceivableAmount THEN
		CASE 
			WHEN RPBF.ReceiptAmount < (ValidateNonAccrualPaydown.PendingReceivableAmount + ValidateNonAccrualPaydown.DummyReceivableAmount) AND @ActivatePartialPaydownOrPayoff = 0 THEN CAST(1 AS BIT)
			ELSE CAST(0 AS BIT)
		END
	ELSE CAST(0 AS BIT)
	END,
	RPBF.Comment = 
	CASE
	WHEN RPBF.ReceiptAmount > ValidateNonAccrualPaydown.PendingReceivableAmount THEN
		CASE 
			WHEN RPBF.ReceiptAmount < (ValidateNonAccrualPaydown.PendingReceivableAmount + ValidateNonAccrualPaydown.DummyReceivableAmount) AND @ActivatePartialPaydownOrPayoff = 0 THEN @errorMessage5
			ELSE RPBF.Comment
		END
	WHEN RPBF.ReceiptAmount <= ValidateNonAccrualPaydown.PendingReceivableAmount THEN @errorMessage6
	END,
	RPBF.NonAccrualCategory = 
	CASE
	WHEN RPBF.ReceiptAmount > ValidateNonAccrualPaydown.PendingReceivableAmount THEN
		CASE 
			WHEN RPBF.ReceiptAmount < (ValidateNonAccrualPaydown.PendingReceivableAmount + ValidateNonAccrualPaydown.DummyReceivableAmount) AND @ActivatePartialPaydownOrPayoff = 0 THEN @NonAccrualSingleUnAllocated
			ELSE RPBF.NonAccrualCategory
		END
	ELSE RPBF.NonAccrualCategory
	END
	FROM #ReceiptPostByFileExcel_Extract RPBF 
	JOIN ValidateNonAccrualPaydown ValidateNonAccrualPaydown
	ON RPBF.Id=ValidateNonAccrualPaydown.RPBF_Id 
	WHERE RPBF.ErrorMessage IS NULL AND RPBF.NonAccrualCategory=@NonAccrualSingleWithRentals



	IF @IsWithHoldingTaxApplicable = 1
	BEGIN
		SELECT  @errorMessage = ErrorMessage FROM @ErrorMessages WHERE Code = 'NONACCWHT'

		UPDATE RPBF SET
		RPBF.ErrorMessage=@errorMessage
		FROM #ReceiptPostByFileExcel_Extract RPBF 
		INNER JOIN Receivables R ON RPBF.ComputedContractId=R.EntityId AND R.EntityType=@ReceivableEntityTypeCT
		INNER JOIN ReceivableCodes RC ON R.ReceivableCodeId=RC.Id AND RC.IsActive=1
		INNER JOIN ReceivableTypes RT ON RC.ReceivableTypeId=RT.Id AND RT.IsActive=1
		LEFT JOIN ReceivableWithholdingTaxDetails RWHT ON R.Id=RWHT.ReceivableId AND RWHT.IsActive=1
		WHERE RWHT.Id IS NULL AND RPBF.ErrorMessage IS NULL AND RPBF.NonAccrualCategory=@NonAccrualSingleWithRentals AND R.IsActive=1 
				AND R.IsDummy=0 AND R.IsCollected=1 AND (RT.[Name]=@ReceivableTypeLoanInterest OR RT.[Name]=@ReceivableTypeLoanPrincipal)
	END


	IF OBJECT_ID('tempdb..#NonAccrualInvoiceInfo') IS NOT NULL DROP TABLE #NonAccrualInvoiceInfo;


	--Validating whether Contract Based Entity's LE matches with File level LE for AllowInterCompanyTransfer false
	--For Lease, LeveragedLease, Loan, Discounting
	SELECT  @errorMessage = ErrorMessage FROM #ErrorMessages WHERE Code='LE2'

	UPDATE RPBF SET RPBF.ErrorMessage=@errorMessage
	FROM #ReceiptPostByFileExcel_Extract AS RPBF 
	WHERE @AllowInterCompanyTransfer=0 AND (RPBF.ComputedLegalEntityId!=RPBF.ComputedContractLegalEntityId) AND RPBF.ErrorMessage IS NULL 
	AND (RPBF.EntityType=@ReceiptEntityTypeLease OR RPBF.EntityType=@ReceiptEntityTypeLeveragedLease OR RPBF.EntityType=@ReceiptEntityTypeLoan OR RPBF.EntityType=@ReceiptEntityTypeDiscounting)
	AND RPBF.NonAccrualCategory IS NULL

	--Validate Cash Type and Compute CashTypeId
	SELECT  @errorMessage = ErrorMessage FROM #ErrorMessages WHERE Code='CSHTYPE1'

	UPDATE RPBF SET	
	RPBF.ComputedCashTypeId = CT.Id,
	RPBF.ErrorMessage=
	CASE 
		WHEN (CT.[Type] IS NULL OR CT.IsActive=0 OR RPBF.ComputedPortfolioId!=CT.PortfolioId) THEN @errorMessage
	END
	FROM #ReceiptPostByFileExcel_Extract AS RPBF LEFT OUTER JOIN 
	CashTypes CT ON RPBF.CashType=CT.[Type]
	WHERE RPBF.CashType IS NOT NULL AND RPBF.ErrorMessage IS NULL


	--Validate Given Instrument Type and Compute InstrumentTypeId
	SELECT  @errorMessage = ErrorMessage FROM #ErrorMessages WHERE Code='IT1'

	UPDATE RPBF SET 
	RPBF.ComputedInstrumentTypeId =
	CASE 
		WHEN ((RPBF.EntityType=@ReceiptEntityTypeCustomer OR RPBF.EntityType=@ReceiptEntityTypeBlank) AND RPBF.ComputedInstrumentTypeId IS NULL) THEN IT.Id 
		WHEN ((RPBF.EntityType!=@ReceiptEntityTypeCustomer AND RPBF.EntityType!=@ReceiptEntityTypeBlank) AND RPBF.InstrumentType IS NOT NULL) THEN IT.Id 
		ELSE ComputedInstrumentTypeId
	END, 
	RPBF.ErrorMessage=
	CASE 
		WHEN (RPBF.InstrumentType IS NOT NULL AND (IT.IsActive=0 OR IT.Code IS NULL or IT.PortfolioId IS NULL)) THEN @errorMessage
		END
	FROM #ReceiptPostByFileExcel_Extract AS RPBF LEFT OUTER JOIN 
	InstrumentTypes AS IT ON (RPBF.InstrumentType=IT.Code AND RPBF.ComputedPortfolioId=IT.PortfolioId)
	WHERE RPBF.ErrorMessage IS NULL


	--Validate Given Line of Business and Compute LineOfBusinessId
	SELECT  @errorMessage = ErrorMessage FROM #ErrorMessages WHERE Code='LOB1'

	UPDATE RPBF SET 
	RPBF.ComputedLineOfBusinessId = 
	CASE 
		WHEN ((RPBF.EntityType=@ReceiptEntityTypeCustomer OR RPBF.EntityType=@ReceiptEntityTypeBlank) AND RPBF.ComputedLineOfBusinessId IS NULL) THEN LOB.Id 
		WHEN ((RPBF.EntityType!=@ReceiptEntityTypeCustomer AND RPBF.EntityType!=@ReceiptEntityTypeBlank) AND RPBF.LineOfBusiness IS NOT NULL) THEN LOB.Id 
		ELSE ComputedLineOfBusinessId
	END,
	RPBF.ErrorMessage=
	CASE 
		WHEN (RPBF.LineOfBusiness IS NOT NULL AND (LOB.IsActive=0 OR LOB.Code IS NULL OR LOB.PortfolioId IS NULL)) THEN @errorMessage
		END
	FROM #ReceiptPostByFileExcel_Extract AS RPBF LEFT OUTER JOIN 
	LineofBusinesses AS LOB ON (RPBF.LineOfBusiness=LOB.Code AND RPBF.ComputedPortfolioId=LOB.PortfolioId)
	WHERE RPBF.ErrorMessage IS NULL


	--Validate Cost Center and Compute CostCenterId
	SELECT  @errorMessage = ErrorMessage FROM #ErrorMessages WHERE Code='CSTCNTR1'

	UPDATE RPBF SET 
	RPBF.ComputedCostCenterId =
	CASE 
		WHEN ((RPBF.EntityType=@ReceiptEntityTypeCustomer OR RPBF.EntityType=@ReceiptEntityTypeBlank) AND RPBF.ComputedCostCenterId IS NULL) THEN CCC.Id 
		WHEN ((RPBF.EntityType!=@ReceiptEntityTypeCustomer AND RPBF.EntityType!=@ReceiptEntityTypeBlank) AND RPBF.CostCenter IS NOT NULL) THEN CCC.Id 
		ELSE ComputedCostCenterId
	END,
	RPBF.ErrorMessage=
	CASE 
		WHEN (RPBF.CostCenter IS NOT NULL AND (CCC.IsActive=0 OR CCC.CostCenter IS NULL OR CCC.PortfolioId IS NULL)) THEN @errorMessage
		END
	FROM #ReceiptPostByFileExcel_Extract AS RPBF LEFT OUTER JOIN 
	CostCenterConfigs AS CCC ON (RPBF.CostCenter=CCC.CostCenter AND RPBF.ComputedPortfolioId=CCC.PortfolioId)
	WHERE RPBF.ErrorMessage IS NULL


	-- Validate Receipt Type and Compute ReceiptTypeId
	SELECT  @errorMessage = ErrorMessage FROM #ErrorMessages WHERE Code='RT1'

	UPDATE RPBF	SET 
	ComputedReceiptTypeId = RT.Id,
	ErrorMessage = 
	CASE 
		WHEN (RT.IsActive = 0 OR RT.Id IS NULL OR RT.ReceiptMode!=@ReceiptModeMoneyOrder) THEN @errorMessage 
	END
	FROM #ReceiptPostByFileExcel_Extract AS RPBF 
	LEFT OUTER JOIN ReceiptTypes RT ON RPBF.ReceiptType = RT.ReceiptTypeName
	WHERE RPBF.ErrorMessage IS NULL

	-- Validate GLTemplate
	SELECT  @errorMessage = ErrorMessage FROM #ErrorMessages WHERE Code='GL1'

	DECLARE @GLConfigurationId AS BIGINT
	SELECT @GLConfigurationId = GLConfigurationId
	FROM GLTemplates
	WHERE Id = @GLTemplateId

	UPDATE RPBF
	SET RPBF.ComputedGLTemplateId = 
	CASE 
		WHEN LE.GLConfigurationId IS NULL THEN NULL 
		ELSE @GLTemplateId 
	END,
	RPBF.ErrorMessage = 
	CASE 
		WHEN LE.GLConfigurationId IS NULL THEN @errorMessage 
	END
	FROM #ReceiptPostByFileExcel_Extract AS RPBF 
	LEFT OUTER JOIN LegalEntities LE ON (RPBF.ComputedLegalEntityId = LE.Id AND LE.GLConfigurationId = @GLConfigurationId)
	WHERE RPBF.ErrorMessage IS NULL

	--Validating if Receipt LE GL Configuration and Contract / Invoice LE GL Configuration are same
	SELECT  @errorMessage = ErrorMessage FROM #ErrorMessages WHERE Code='LEGLCONFIG'

	UPDATE RPBF
	SET RPBF.ErrorMessage = @errorMessage
	FROM #ReceiptPostByFileExcel_Extract AS RPBF
	JOIN LegalEntities LE ON RPBF.ComputedLegalEntityId = LE.Id
	JOIN LegalEntities LE2 ON RPBF.ComputedContractLegalEntityId = LE2.Id
	WHERE LE.GLConfigurationId != LE2.GLConfigurationId AND (RPBF.EntityType != @ReceiptEntityTypeBlank OR RPBF.EntityType != @ReceiptEntityTypeCustomer) AND RPBF.ComputedContractId IS NOT NULL AND RPBF.ErrorMessage IS NULL

	UPDATE RPBF
	SET RPBF.ErrorMessage = @errorMessage
	FROM #ReceiptPostByFileExcel_Extract AS RPBF
	JOIN LegalEntities LE ON RPBF.ComputedLegalEntityId = LE.Id
	JOIN ReceivableInvoices RI ON RPBF.InvoiceNumber = RI.Number
	JOIN LegalEntities LE2 ON RI.LegalEntityId = LE2.Id
	WHERE LE.GLConfigurationId != LE2.GLConfigurationId AND (RPBF.EntityType = @ReceiptEntityTypeBlank OR RPBF.EntityType = @ReceiptEntityTypeCustomer) AND RPBF.ComputedContractId IS NULL AND RPBF.ErrorMessage IS NULL

	--For Assumptions, Validating if CustomerId of Contract and Invoice are same
	SELECT  @errorMessage = ErrorMessage FROM #ErrorMessages WHERE Code='INV2'

	UPDATE RPBF SET 
	RPBF.ErrorMessage=
	CASE 
		WHEN (LF.CustomerId!=RPBF.ComputedInvoiceCustomerId) THEN @errorMessage
	END
	FROM #ReceiptPostByFileExcel_Extract RPBF LEFT OUTER JOIN 
	Assumptions A ON (RPBF.ComputedContractId=A.ContractId AND A.[Status]=@AssumptionApprovalStatusApproved)
	LEFT OUTER JOIN LeaseFinances LF ON (A.ContractId=LF.ContractId) 
	WHERE (A.Id IS NOT NULL) AND RPBF.EntityType!=@ReceiptEntityTypeBlank AND RPBF.EntityType!=@ReceiptEntityTypeCustomer
	AND RPBF.ErrorMessage IS NULL AND RPBF.NonAccrualCategory IS NULL

	--Invoice Validations Begin

	-- Validate whether Invoice's Customer matches Given Customer For Customer Based Records
	SELECT  @errorMessage = ErrorMessage FROM #ErrorMessages WHERE Code='INV2'

	UPDATE RPBF SET RPBF.ErrorMessage=@errorMessage
	FROM #ReceiptPostByFileExcel_Extract RPBF WHERE (RPBF.ComputedCustomerId!=RPBF.ComputedInvoiceCustomerId) 
	AND RPBF.EntityType=@ReceiptEntityTypeCustomer AND RPBF.ErrorMessage IS NULL

	--Validate whether Invoice's Receivable Invoice Details have atleast one active receivable to which the file entity belongs for Contract Based Records

	UPDATE RPBF SET
	RPBF.ErrorMessage=
	CASE
		WHEN (RPBF.EntityType=@ReceiptEntityTypeDiscounting AND (INV.EntityId IS NULL OR INV.EntityType!=@ReceivableEntityTypeDT)) THEN @errorMessage
		WHEN (INV.EntityId IS NULL) THEN @errorMessage
	END
	FROM #ReceiptPostByFileExcel_Extract RPBF 
	LEFT OUTER JOIN #InvoiceDetailsTable INV 
	ON (RPBF.ComputedReceivableInvoiceId=INV.ReceivableInvoiceId AND RPBF.ComputedContractId=INV.EntityId)
	AND 
	(
		(RPBF.EntityType=@ReceiptEntityTypeDiscounting AND INV.EntityType = @ReceivableEntityTypeDT)
			OR
		(RPBF.EntityType!=@ReceiptEntityTypeDiscounting AND INV.EntityType = @ReceivableEntityTypeCT)
	)
	WHERE RPBF.EntityType!=@ReceiptEntityTypeCustomer AND RPBF.EntityType!=@ReceiptEntityTypeBlank AND RPBF.InvoiceNumber IS NOT NULL 
	AND RPBF.ErrorMessage IS NULL AND RPBF.NonAccrualCategory IS NULL

	--Throw error if IsApplyCredit=TRUE, ReceiptAmount=0 and No Negative Receivables for Customer based Records
	SELECT  @errorMessage = ErrorMessage FROM #ErrorMessages WHERE Code='INVAPPLY'

	UPDATE RPBF SET
	RPBF.ErrorMessage=
	CASE
		WHEN ( SumOfNegativeBalance=0 ) THEN @errorMessage
	END
	FROM #ReceiptPostByFileExcel_Extract RPBF INNER JOIN ( SELECT ReceivableInvoiceId, SUM(TotalNegativeBalance) AS SumOfNegativeBalance FROM #InvoiceDetailsTable GROUP BY ReceivableInvoiceId ) AS INV
	ON RPBF.ComputedReceivableInvoiceId=INV.ReceivableInvoiceId
	WHERE (RPBF.EntityType=@ReceiptEntityTypeCustomer OR RPBF.EntityType=@ReceiptEntityTypeBlank) AND RPBF.ReceiptAmount=0 AND RPBF.IsApplyCredit=1 AND RPBF.InvoiceNumber IS NOT NULL 
	AND RPBF.ErrorMessage IS NULL AND RPBF.NonAccrualCategory IS NULL

	--Throw error if IsApplyCredit=TRUE, ReceiptAmount=0 and No Negative Receivables for Contract based Records

	UPDATE RPBF SET
	RPBF.ErrorMessage=
	CASE
		WHEN ( INV.TotalNegativeBalance=0 ) THEN @errorMessage
	END
	FROM #ReceiptPostByFileExcel_Extract RPBF INNER JOIN #InvoiceDetailsTable INV ON (RPBF.ComputedReceivableInvoiceId=INV.ReceivableInvoiceId AND RPBF.ComputedContractId=INV.EntityId)
	WHERE RPBF.EntityType!=@ReceiptEntityTypeCustomer AND RPBF.EntityType!=@ReceiptEntityTypeBlank AND RPBF.ReceiptAmount=0 AND RPBF.IsApplyCredit=1 AND RPBF.InvoiceNumber IS NOT NULL 
	AND RPBF.ErrorMessage IS NULL AND RPBF.NonAccrualCategory IS NULL

	--Validate whether Invoice LE matches with Given LE
	--For all Invoices
	SELECT  @errorMessage = ErrorMessage FROM #ErrorMessages WHERE Code='INV3LE'

	UPDATE RPBF SET RPBF.ErrorMessage=@errorMessage
	FROM #ReceiptPostByFileExcel_Extract RPBF INNER JOIN ReceivableInvoices RI
	ON RPBF.ComputedReceivableInvoiceId=RI.Id 
	WHERE @AllowInterCompanyTransfer=0 AND (RPBF.ComputedLegalEntityId!=RI.LegalEntityId) AND RPBF.InvoiceNumber IS NOT NULL 
	AND RPBF.ErrorMessage IS NULL AND RPBF.NonAccrualCategory IS NULL

	--Validating Mandatory CashType If Receipt Balance>0 (or use IsFullPosting for Validating CashType logic) For Customer Based Records
	SELECT  @errorMessage = ErrorMessage FROM #ErrorMessages WHERE Code='CSHTYPMAN'

	UPDATE RPBF SET 
	RPBF.ComputedIsFullPosting=
	CASE
		WHEN (RPBF.NonAccrualCategory IS NULL AND RPBF.IsApplyCredit=0 AND (RPBF.ReceiptAmount-INV.SumOfPositiveBalance)>=0) THEN 1
		WHEN (RPBF.NonAccrualCategory IS NULL AND RPBF.IsApplyCredit=1 AND (RPBF.ReceiptAmount-INV.SumOfNegativeBalance-INV.SumOfPositiveBalance)>=0) THEN 1
		ELSE 0
	END,
	RPBF.ErrorMessage=
	CASE
		WHEN (RPBF.CashType IS NULL AND RPBF.IsApplyCredit=0 AND (RPBF.ReceiptAmount-INV.SumOfPositiveBalance)>0) THEN @errorMessage
		WHEN (RPBF.CashType IS NULL AND RPBF.IsApplyCredit=1 AND (RPBF.ReceiptAmount-INV.SumOfNegativeBalance-INV.SumOfPositiveBalance)>0) THEN @errorMessage
	END
	FROM #ReceiptPostByFileExcel_Extract RPBF INNER JOIN 
		(SELECT ReceivableInvoiceId, SUM(TotalNegativeBalance) AS SumOfNegativeBalance, SUM(TotalPositiveBalance) AS SumOfPositiveBalance 
		FROM #InvoiceDetailsTable GROUP BY ReceivableInvoiceId ) AS INV
	ON RPBF.ComputedReceivableInvoiceId=INV.ReceivableInvoiceId
	WHERE (RPBF.EntityType=@ReceiptEntityTypeCustomer OR RPBF.EntityType=@ReceiptEntityTypeBlank) 
	AND RPBF.InvoiceNumber IS NOT NULL AND RPBF.ErrorMessage IS NULL AND (RPBF.NonAccrualCategory IS NULL OR RPBF.NonAccrualCategory='SingleWithOnlyNonRentals')

	--Validating Mandatory CashType If Receipt Balance>0 For Contract Based Records and simultaneously set ComputedIsFullPosting

	UPDATE RPBF SET
	RPBF.ComputedIsFullPosting=
	CASE
		WHEN (RPBF.NonAccrualCategory IS NULL AND RPBF.IsApplyCredit=0 AND (RPBF.ReceiptAmount-INV.TotalPositiveBalance)>=0) THEN 1
		WHEN (RPBF.NonAccrualCategory IS NULL AND RPBF.IsApplyCredit=1 AND (RPBF.ReceiptAmount-INV.TotalNegativeBalance-INV.TotalPositiveBalance)>=0) THEN 1
		ELSE 0
	END,
	RPBF.ErrorMessage=
	CASE
		WHEN (RPBF.CashType IS NULL AND RPBF.IsApplyCredit=0 AND (RPBF.ReceiptAmount-INV.TotalPositiveBalance)>0) THEN @errorMessage
		WHEN (RPBF.CashType IS NULL AND RPBF.IsApplyCredit=1 AND (RPBF.ReceiptAmount-INV.TotalNegativeBalance-INV.TotalPositiveBalance)>0) THEN @errorMessage
	END
	FROM #ReceiptPostByFileExcel_Extract RPBF INNER JOIN #InvoiceDetailsTable INV 
	ON (RPBF.ComputedReceivableInvoiceId=INV.ReceivableInvoiceId AND RPBF.ComputedContractId=INV.EntityId)
	WHERE RPBF.EntityType!=@ReceiptEntityTypeCustomer AND RPBF.EntityType!=@ReceiptEntityTypeBlank 
	AND RPBF.InvoiceNumber IS NOT NULL AND RPBF.ErrorMessage IS NULL AND (RPBF.NonAccrualCategory IS NULL OR RPBF.NonAccrualCategory='SingleWithOnlyNonRentals')


	--Validate GLOrgStructureCombination
	SELECT  @errorMessage = ErrorMessage FROM #ErrorMessages WHERE Code='GLORG1'

	UPDATE RPBF SET 
	RPBF.ErrorMessage=
	CASE 
		WHEN (GL.Id IS NULL) THEN @errorMessage
	END
	FROM #ReceiptPostByFileExcel_Extract RPBF LEFT OUTER JOIN GLOrgStructureConfigs GL
	ON (RPBF.ComputedLegalEntityId=GL.LegalEntityId AND RPBF.ComputedLineOfBusinessId=GL.LineofBusinessId AND RPBF.ComputedCostCenterId=GL.CostCenterId AND GL.IsActive=1)
	WHERE RPBF.ComputedLegalEntityId IS NOT NULL AND RPBF.ComputedCostCenterId IS NOT NULL AND RPBF.ComputedLineOfBusinessId IS NOT NULL
	AND RPBF.ErrorMessage IS NULL

	--Validate All Receivable for that Invoice is getting selected for VAT

	SELECT  @errorMessage = ErrorMessage FROM #ErrorMessages WHERE Code='AllVATReceivableImported'



	-- Identify Receipts with repeated invoice 
	;WITH RepeatedInvoiceCte AS 
	(
		SELECT ComputedReceivableInvoiceId 
		FROM #ReceiptPostByFileExcel_Extract 
		WHERE ErrorMessage IS NULL AND ComputedReceivableInvoiceId IS NOT NULL
		GROUP BY ComputedReceivableInvoiceId HAVING COUNT(1) > 1 		
	)
	UPDATE RPBF 
	SET RPBF.IsInvoiceInMultipleReceipts = CASE WHEN RepeatedInvoiceCte.ComputedReceivableInvoiceId IS NULL THEN 0 ELSE 1 END
	FROM #ReceiptPostByFileExcel_Extract RPBF 
	LEFT JOIN RepeatedInvoiceCte ON RPBF.ComputedReceivableInvoiceId = RepeatedInvoiceCte.ComputedReceivableInvoiceId
	WHERE RPBF.NonAccrualCategory IS NULL 

	
	--Setting Unallocated Receipts to FullPosting
	UPDATE RPBF SET
	RPBF.ComputedIsFullPosting = 1
	FROM #ReceiptPostByFileExcel_Extract RPBF
	WHERE RPBF.InvoiceNumber IS NULL AND RPBF.NonAccrualCategory IS NULL AND RPBF.ComputedIsDSL=0 AND RPBF.ErrorMessage IS NULL 


	--Setting IsStatementInvoice to false for Unallocated 
	UPDATE RPBF SET
	IsStatementInvoice = 0
	FROM #ReceiptPostByFileExcel_Extract RPBF
	WHERE RPBF.IsStatementInvoice IS NULL
	 
	-- Updating ReceiptPostByFileExcel_Extract with values from #ReceiptPostByFileExcel_Extract
	UPDATE RPBF SET   
    RPBF.ErrorMessage=Temp.ErrorMessage,
    RPBF.ComputedInvoiceCustomerId=Temp.ComputedInvoiceCustomerId,
    RPBF.ComputedCustomerId=Temp.ComputedCustomerId,
    RPBF.ComputedReceiptEntityType=Temp.ComputedReceiptEntityType,
    RPBF.ComputedReceiptTypeId=Temp.ComputedReceiptTypeId,
    RPBF.ComputedBankAccountId=Temp.ComputedBankAccountId,
    RPBF.ComputedCashTypeId=Temp.ComputedCashTypeId,    
    RPBF.ComputedLegalEntityId=Temp.ComputedLegalEntityId,
    RPBF.ComputedLineOfBusinessId=Temp.ComputedLineOfBusinessId,
    RPBF.ComputedCostCenterId=Temp.ComputedCostCenterId,
    RPBF.ComputedInstrumentTypeId=Temp.ComputedInstrumentTypeId,
    RPBF.ComputedPortfolioId=Temp.ComputedPortfolioId,
    RPBF.ComputedContractId=Temp.ComputedContractId,
    RPBF.ComputedCurrencyId=Temp.ComputedCurrencyId,
    RPBF.ComputedBankAccountCurrencyId=Temp.ComputedBankAccountCurrencyId,
    RPBF.ComputedContractCurrencyId=Temp.ComputedContractCurrencyId,
    RPBF.ComputedInvoiceCurrencyId=Temp.ComputedInvoiceCurrencyId,
    RPBF.ComputedCurrencyCodeISO=Temp.ComputedCurrencyCodeISO,
    RPBF.ComputedIsDSL=Temp.ComputedIsDSL,
    RPBF.ComputedGLTemplateId=Temp.ComputedGLTemplateId,
    RPBF.ComputedReceivableInvoiceId=Temp.ComputedReceivableInvoiceId,
    RPBF.ComputedDiscountingId=Temp.ComputedDiscountingId,
    RPBF.NonAccrualCategory=Temp.NonAccrualCategory,
    RPBF.ComputedContractLegalEntityId=Temp.ComputedContractLegalEntityId,
    RPBF.ComputedIsFullPosting=Temp.ComputedIsFullPosting,
    RPBF.ComputedIsGrouped=Temp.ComputedIsGrouped,
    RPBF.GroupNumber=Temp.GroupNumber,
    RPBF.IsInvoiceInMultipleReceipts=Temp.IsInvoiceInMultipleReceipts,
	RPBF.IsStatementInvoice = Temp.IsStatementInvoice,
	RPBF.CreateUnallocatedReceipt = Temp.CreateUnallocatedReceipt,
	RPBF.Comment = Temp.Comment,
	RPBF.HasError=
	CASE
		WHEN Temp.ErrorMessage IS NULL THEN 0
		ELSE 1
	END,
	RPBF.ReceivableTaxType = Temp.ReceivableTaxType,
	RPBF.IsApplyCredit = Temp.IsApplyCredit
	FROM ReceiptPostByFileExcel_Extract RPBF INNER JOIN #ReceiptPostByFileExcel_Extract Temp
	ON RPBF.Id=Temp.Id

	IF OBJECT_ID('tempdb..#ReceiptPostByFileExcel_Extract') IS NOT NULL DROP TABLE #ReceiptPostByFileExcel_Extract;

	--Returning whether all records for that JobStepInstanceId failed
	IF EXISTS(SELECT 1 FROM ReceiptPostByFileExcel_Extract WHERE HasError=0 AND JobStepInstanceId=@JobStepInstanceId)
	BEGIN
		SET @HasOnlyFailedRecords=0 
	END
	ELSE
	BEGIN
		SET @HasOnlyFailedRecords=1
	END
END

GO
