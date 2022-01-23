SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROC [dbo].[PopulateReceiptLockBoxOtherData]
(
	@JobStepInstanceId								BIGINT,
	@ReceiptEntityTypeValues_Lease					NVARCHAR(10),
	@ReceiptEntityTypeValues_Loan					NVARCHAR(10),
	@ReceiptEntityTypeValues_Customer				NVARCHAR(30),
	@ReceiptEntityTypeValues_UnKnown				NVARCHAR(30),
	@ReceiptEntityTypeValues_LeveragedLease			NVARCHAR(30),
	@ReceiptEntityTypeValues_Discounting			NVARCHAR(30),
	@ReceiptClassificationValues_Cash				NVARCHAR(10),
	@ReceiptClassificationValues_DSL				NVARCHAR(10),
	@RemitToReceiptTypeValues_Check					NVARCHAR(5),
	@RemitToReceiptTypeValues_All					NVARCHAR(3),
	@ReceiptTypeValues_Lockbox						NVARCHAR(7),
	@ReceivableEntityTypeValues_CT					NVARCHAR(2),
	@ReceivableEntityTypeValues_DT					NVARCHAR(2),
	@ReceiptLockBoxErrorCodeValues_LB209			NVARCHAR(5),
    @ReceiptLockBoxErrorCodeValues_LB007            NVARCHAR(5),
	@ReceiptLockBoxErrorMessage_LB007				NVARCHAR(200),
	@ReceiptLockBoxComment_LB416					NVARCHAR(200),
	@GLTemplateId									BIGINT,
	@DefaultLegalEntityNumber						NVARCHAR(200),
	@DefaultCashType								NVARCHAR(200)
)
AS
BEGIN
	
	SET NOCOUNT ON;

	CREATE TABLE #ReceiptContractDetails
	(
	ExtractId        BIGINT,
	ContractId         BIGINT,
	LegalEntityId    BIGINT,
	EntityType       NVARCHAR(4),
	CustomerId       BIGINT	    
	)

	DECLARE @PortfolioId AS BIGINT
	SELECT @PortfolioId = PortfolioId FROM BusinessUnits WHERE Id = 1

	DECLARE @DefaultLegalEntityId AS BIGINT
	SELECT @DefaultLegalEntityId = Id FROM LegalEntities WHERE LegalEntityNumber = @DefaultLegalEntityNumber AND Status = 'Active'

	DECLARE @ReceiptTypeId AS BIGINT
	SELECT @ReceiptTypeId = Id FROM ReceiptTypes WHERE ReceiptTypeName = @ReceiptTypeValues_Lockbox AND IsActive = 1

	DECLARE @ErrorDelimiter AS CHAR = ','
	DECLARE @GLConfigurationId AS BIGINT
	SELECT @GLConfigurationId = GLConfigurationId FROM GLTemplates WHERE Id = @GLTemplateId

	UPDATE ReceiptPostByLockBox_Extract
		SET LegalEntityId = LF.Id
	FROM ReceiptPostByLockBox_Extract RPBF
	JOIN LegalEntities LF ON RPBF.LegalEntityNumber = LF.LegalEntityNumber
	WHERE IsValid = 1 AND RPBF.JobStepInstanceId = @JobStepInstanceId
	AND (IsValidContract = 0 OR IsContractLegalEntityAssociated = 1)
	AND (IsValidInvoice = 0 OR IsInvoiceLegalEntityAssociated = 1)
	
	UPDATE ReceiptPostByLockBox_Extract
		SET LegalEntityId = @DefaultLegalEntityId
	WHERE LegalEntityId IS NULL AND IsValid = 1 AND JobStepInstanceId = @JobStepInstanceId

	UPDATE ReceiptPostByLockBox_Extract
		SET CustomerId = P.Id
	FROM ReceiptPostByLockBox_Extract RPBL
	JOIN Parties P ON RPBL.CustomerNumber = P.PartyNumber
	WHERE IsValid = 1 AND RPBL.JobStepInstanceId = @JobStepInstanceId

	UPDATE ReceiptPostByLockBox_Extract
	    SET IsStatementInvoice = 0
    FROM ReceiptPostByLockBox_Extract  
	WHERE JobStepInstanceId = @JobStepInstanceId AND IsStatementInvoice IS NULL

	SELECT 
		LegalEntityId, CurrencyId, MAX(Id) MaxId 
	INTO #MaxCurrencyLockboxDefaultParameterConfigs
	FROM LockboxDefaultParameterConfigs WHERE IsActive = 1 
	GROUP BY LegalEntityId, CurrencyId

	SELECT 
		LegalEntityId, MAX(MaxId) MaxId 
	INTO #MaxLockboxDefaultParameterConfigs
	FROM #MaxCurrencyLockboxDefaultParameterConfigs 
	GROUP BY LegalEntityId

		---- Invoice

	SELECT 
		 RPBL.Id
		,RI.CurrencyId
		,RI.InvoiceAmount_Currency AS Currency
		,RI.Id InvoiceId
		,RI.LegalEntityId
		,RPBL.CustomerNumber
		,RPBL.LegalEntityNumber
		,RI.IsStatementInvoice
	INTO #InvoiceLockBoxExtractData
	FROM ReceivableInvoices RI
	INNER JOIN ReceiptPostByLockBox_Extract RPBL ON RI.Number = RPBL.InvoiceNumber
	WHERE InvoiceNumber IS NOT NULL AND RPBL.IsValid = 1
		AND RI.IsActive = 1 AND RPBL.JobStepInstanceId = @JobStepInstanceId

	-- Identify File LE/ Default LE/ Invoice LE

	UPDATE ReceiptPostByLockBox_Extract
		SET Currency = ID.Currency, CurrencyId = ID.CurrencyId, ReceivableInvoiceId = ID.InvoiceId, IsStatementInvoice = ID.IsStatementInvoice,
		    LegalEntityId = CASE WHEN (RPBL.LegalEntityNumber IS NULL OR RPBL.LegalEntityNumber = '') AND @DefaultLegalEntityId IS NULL THEN
								ID.LegalEntityId
							ELSE 
								RPBL.LegalEntityId 
							END
	FROM 
		ReceiptPostByLockBox_Extract RPBL
	INNER JOIN 
		#InvoiceLockBoxExtractData ID 
	ON RPBL.Id = ID.Id
		AND RPBL.JobStepInstanceId = @JobStepInstanceId
		AND RPBL.IsValid = 1 

	--- Inv ET Identification
	INSERT INTO #ReceiptContractDetails
	SELECT 
		RPBLE.Id AS ExtractId, R.EntityId AS ContractId, RI.LegalEntityId, R.EntityType, RI.CustomerId
	FROM ReceiptPostByLockBox_Extract RPBLE
	JOIN ReceivableInvoices RI ON RPBLE.InvoiceNumber = RI.Number AND RPBLE.IsStatementInvoice = 0 AND RI.IsActive = 1
	JOIN ReceivableInvoiceDetails RID ON RI.Id = RID.ReceivableInvoiceId  AND RID.IsActive = 1
	JOIN ReceivableDetails RD ON RID.ReceivableDetailId = RD.Id  AND RD.IsActive = 1
	JOIN Receivables R ON RD.ReceivableId = R.Id AND R.IsActive = 1
	WHERE 
		RPBLE.JobStepInstanceId = @JobStepInstanceId 
	GROUP BY RPBLE.Id, R.EntityId, RI.LegalEntityId, R.EntityType, RI.CustomerId
		
	IF EXISTS (SELECT TOP 1 * FROM ReceiptPostByLockBox_Extract WHERE JobStepInstanceId = @JobStepInstanceId AND IsStatementInvoice = 1)
	BEGIN
    INSERT INTO #ReceiptContractDetails
	SELECT RPBLE.Id AS ExtractId,R.EntityId AS ContractId,RI.LegalEntityId, R.EntityType, RI.CustomerId
	FROM ReceiptPostByLockBox_Extract RPBLE
	JOIN ReceivableInvoices RI ON RPBLE.InvoiceNumber = RI.Number AND RPBLE.IsStatementInvoice = 1  AND RI.IsActive = 1
	JOIN ReceivableInvoiceStatementAssociations SA ON RI.Id = SA.StatementInvoiceId
	JOIN ReceivableInvoiceDetails RID ON SA.ReceivableInvoiceId = RID.ReceivableInvoiceId AND RID.IsActive = 1
	JOIN ReceivableDetails RD ON RID.ReceivableDetailId = RD.Id AND RD.IsActive = 1
	JOIN Receivables R ON RD.ReceivableId = R.Id AND R.IsActive = 1
	WHERE RPBLE.JobStepInstanceId = @JobStepInstanceId 
	GROUP BY RPBLE.Id, R.EntityId, RI.LegalEntityId, R.EntityType, RI.CustomerId
	END
	
	-- Inv ET as CU

	SELECT * INTO #ReceiptContractGroupedDetails FROM
	(
		SELECT 
			ICI.ExtractId, LegalEntityId, @ReceiptEntityTypeValues_Customer AS EntityType, CustomerId
		FROM #ReceiptContractDetails ICI
		GROUP BY ICI.ExtractId, LegalEntityId, CustomerId
		HAVING  COUNT(ICI.ContractId) > 1

		UNION

		SELECT 
			Id As ExtractId, LegalEntityId, 
			CASE WHEN IsValidCustomer = 1 THEN 
				CASE WHEN IsInvoiceCustomerAssociated = 0 AND IsValidInvoice = 1 AND IsValidCustomer = 1 THEN
					@ReceiptEntityTypeValues_UnKnown
				ELSE
					@ReceiptEntityTypeValues_Customer
				END
			ELSE @ReceiptEntityTypeValues_UnKnown END AS EntityType,

			CASE WHEN IsValidCustomer = 1 THEN 
				CASE WHEN IsInvoiceCustomerAssociated = 0 AND IsValidInvoice = 1 AND IsValidCustomer = 1 THEN
					NULL
				ELSE
					CustomerId
				END
			ELSE NULL END AS CustomerId
		FROM ReceiptPostByLockBox_Extract
		WHERE 
			JobStepInstanceId = @JobStepInstanceId AND
			LegalEntityId IS NOT NULL AND 
			(IsValidInvoice = 0 OR IsInvoiceCustomerAssociated = 1 OR IsValidLegalEntity = 1 OR @DefaultLegalEntityId IS NOT NULL)
			
	) AS TMP
	;

	UPDATE ReceiptPostByLockBox_Extract
	SET 
		EntityType = ICCI.EntityType, LineOfBusinessId = LDPC.LineofBusinessId, Currency = CC.ISO,
		InstrumentTypeId = LDPC.InstrumentTypeId, CashTypeId = LDPC.CashTypeId, CurrencyId = LDPC.CurrencyId, 
		CostCenterId = LDPC.CostCenterId, ReceiptClassification = @ReceiptClassificationValues_Cash, CustomerId = ICCI.CustomerId
	FROM ReceiptPostByLockBox_Extract RPBL
	INNER JOIN #ReceiptContractGroupedDetails ICCI ON RPBL.Id = ICCI.ExtractId
	INNER JOIN LegalEntities LE ON ICCI.LegalEntityId = LE.Id
	INNER JOIN #MaxCurrencyLockboxDefaultParameterConfigs MLDPC ON LE.Id = MLDPC.LegalEntityId 
		AND RPBL.CurrencyId = MLDPC.CurrencyId
	INNER JOIN LockboxDefaultParameterConfigs LDPC ON MLDPC.MaxId = LDPC.Id
		AND MLDPC.CurrencyId = LDPC.CurrencyId
	INNER JOIN Currencies CR ON LDPC.CurrencyId = CR.Id
	INNER JOIN CurrencyCodes CC ON CR.CurrencyCodeId = CC.Id
	WHERE IsValid = 1 AND RPBL.CurrencyId IS NOT NULL
	;

	UPDATE ReceiptPostByLockBox_Extract
	SET 
		EntityType = ICCI.EntityType, LineOfBusinessId = LDPC.LineofBusinessId, Currency = CC.ISO,
		InstrumentTypeId = LDPC.InstrumentTypeId, CashTypeId = LDPC.CashTypeId, CurrencyId = LDPC.CurrencyId, 
		CostCenterId = LDPC.CostCenterId, ReceiptClassification = @ReceiptClassificationValues_Cash, CustomerId = ICCI.CustomerId
	FROM ReceiptPostByLockBox_Extract RPBL
	INNER JOIN #ReceiptContractGroupedDetails ICCI ON RPBL.Id = ICCI.ExtractId
	INNER JOIN LegalEntities LE ON ICCI.LegalEntityId = LE.Id
	INNER JOIN #MaxLockboxDefaultParameterConfigs MLDPC ON LE.Id = MLDPC.LegalEntityId
	INNER JOIN LockboxDefaultParameterConfigs LDPC ON MLDPC.MaxId = LDPC.Id
	INNER JOIN Currencies CR ON LDPC.CurrencyId = CR.Id
	INNER JOIN CurrencyCodes CC ON CR.CurrencyCodeId = CC.Id
	WHERE IsValid = 1 AND RPBL.CurrencyId IS  NULL
	;

	---Inv CT Type & CT

	;WITH CTE_ReceiptContractGroupedDetails AS
	(
		SELECT ICI.ExtractId, COUNT(ICI.ContractId) AS ContractCount
		FROM #ReceiptContractDetails ICI
		GROUP BY ICI.ExtractId
	),
	CTE_ContractNumber AS
	(
		SELECT Id, @ReceivableEntityTypeValues_CT AS EntityType, SequenceNumber FROM Contracts
		UNION
		SELECT Id, @ReceivableEntityTypeValues_DT AS EntityType, SequenceNumber FROM Discountings
	)
	UPDATE ReceiptPostByLockBox_Extract
	SET 
		ContractNumber = CC.SequenceNumber, 
		ContractId = CASE WHEN CC.EntityType = @ReceivableEntityTypeValues_CT THEN CC.Id ELSE NULL END,
		DiscountingId = CASE WHEN CC.EntityType = @ReceivableEntityTypeValues_DT THEN CC.Id ELSE NULL END
	FROM ReceiptPostByLockBox_Extract RPBL
	INNER JOIN CTE_ReceiptContractGroupedDetails ICCI ON RPBL.Id = ICCI.ExtractId
	INNER JOIN #ReceiptContractDetails ICD ON ICCI.ExtractId = ICD.ExtractId
	INNER JOIN CTE_ContractNumber CC ON ICD.ContractId = CC.Id AND ICD.EntityType = CC.EntityType
	WHERE RPBL.Id NOT IN (SELECT Id FROM ReceiptPostByLockBox_Extract
						WHERE (IsValidContract = 0 AND IsValidInvoice = 1 
						AND IsValidLegalEntity = 1 AND IsValidCustomer = 0)
						AND JobStepInstanceId = @JobStepInstanceId
		) 
		AND
		RPBL.JobStepInstanceId = @JobStepInstanceId	AND 
		RPBL.IsValid = 1 AND ICCI.ContractCount <= 1 AND
		(ContractNumber IS NULL OR ContractNumber = ''
		 OR (ContractNumber IS NOT NULL AND IsValidContract = 0)) AND
		(CustomerNumber IS NULL OR CustomerNumber = '' OR IsValidCustomer = 0)
		

	--CT Entity Type

	SELECT Id, LineofBusinessId, InstrumentTypeId, CostCenterId, ReceiptClassification, CustomerId, ContractId, CurrencyId, Currency, LegalEntityId, EntityType, DiscountingId, SequenceNumber  INTO #ReceiptPostByLockBoxExtractContractDetails
	FROM
	(
		SELECT
			RPBL.Id, C.LineofBusinessId, LF.InstrumentTypeId, LF.CostCenterId, 
			@ReceiptClassificationValues_Cash AS ReceiptClassification, LF.CustomerId, 
			C.Id AS ContractId, C.CurrencyId, CC.ISO AS Currency, LF.LegalEntityId, 
			@ReceiptEntityTypeValues_Lease AS EntityType, NULL AS DiscountingId, C.SequenceNumber
		FROM 
			ReceiptPostByLockBox_Extract RPBL
		INNER JOIN Contracts C ON RPBL.ContractNumber = C.SequenceNumber
		INNER JOIN LeaseFinances LF ON C.Id = LF.ContractId
		INNER JOIN Currencies CR ON C.CurrencyId = CR.Id
		INNER JOIN CurrencyCodes CC ON CR.CurrencyCodeId = CC.Id
		LEFT JOIN #ReceiptContractDetails InvEntityInfo ON RPBL.Id = InvEntityInfo.ExtractId
		WHERE 
			RPBL.JobStepInstanceId = @JobStepInstanceId AND LF.IsCurrent = 1 AND RPBL.IsValid = 1 
			AND ((IsValidInvoice = 0 OR (IsValidInvoice = 1 AND IsInvoiceContractAssociated = 1)) OR IsValidContract = 0)
			AND (InvEntityInfo.ExtractId IS NULL OR InvEntityInfo.EntityType = @ReceivableEntityTypeValues_CT)

		UNION ALL

		SELECT
			RPBL.Id, C.LineofBusinessId, LF.InstrumentTypeId, LF.CostCenterId,  
			CASE WHEN LF.IsDailySensitive = 1 THEN @ReceiptClassificationValues_DSL ELSE @ReceiptClassificationValues_Cash END AS ReceiptClassification, 
			LF.CustomerId, C.Id AS ContractId, C.CurrencyId, CC.ISO AS Currency, 
			LF.LegalEntityId, @ReceiptEntityTypeValues_Loan AS EntityType, NULL AS DiscountingId, C.SequenceNumber
		FROM 
			ReceiptPostByLockBox_Extract RPBL
		INNER JOIN Contracts C ON RPBL.ContractNumber = C.SequenceNumber
		INNER JOIN LoanFinances LF ON C.Id = LF.ContractId
		INNER JOIN Currencies CR ON C.CurrencyId = CR.Id
		INNER JOIN CurrencyCodes CC ON CR.CurrencyCodeId = CC.Id
		LEFT JOIN #ReceiptContractDetails InvEntityInfo ON RPBL.Id = InvEntityInfo.ExtractId
		WHERE 
			RPBL.JobStepInstanceId = @JobStepInstanceId AND LF.IsCurrent = 1 AND RPBL.IsValid = 1 
			AND ((IsValidInvoice = 0 OR (IsValidInvoice = 1 AND IsInvoiceContractAssociated = 1)) OR IsValidContract = 0)
			AND (InvEntityInfo.ExtractId IS NULL OR InvEntityInfo.EntityType = @ReceivableEntityTypeValues_CT)

		UNION ALL

		SELECT
			RPBL.Id, C.LineofBusinessId, LF.InstrumentTypeId, LF.CostCenterId, 
			@ReceiptClassificationValues_Cash AS ReceiptClassification, LF.CustomerId, 
			C.Id AS ContractId, C.CurrencyId, CC.ISO AS Currency, LF.LegalEntityId, 
			@ReceiptEntityTypeValues_LeveragedLease AS EntityType, NULL AS DiscountingId, C.SequenceNumber
		FROM 
			ReceiptPostByLockBox_Extract RPBL
		INNER JOIN Contracts C ON RPBL.ContractNumber = C.SequenceNumber
		INNER JOIN LeveragedLeases LF ON C.Id = LF.ContractId
		INNER JOIN Currencies CR ON C.CurrencyId = CR.Id
		INNER JOIN CurrencyCodes CC ON CR.CurrencyCodeId = CC.Id
		LEFT JOIN #ReceiptContractDetails InvEntityInfo ON RPBL.Id = InvEntityInfo.ExtractId
		WHERE 
			RPBL.JobStepInstanceId = @JobStepInstanceId AND LF.IsCurrent = 1 AND RPBL.IsValid = 1 
			AND ((IsValidInvoice = 0 OR (IsValidInvoice = 1 AND IsInvoiceContractAssociated = 1)) OR IsValidContract = 0)
			AND (InvEntityInfo.ExtractId IS NULL OR InvEntityInfo.EntityType = @ReceivableEntityTypeValues_CT)

		UNION ALL

		SELECT
			RPBL.Id, LF.LineofBusinessId, LF.InstrumentTypeId, LF.CostCenterId, 
			@ReceiptClassificationValues_Cash AS ReceiptClassification, 
			LF.FunderId AS CustomerId, NULL AS ContractId, C.CurrencyId, CC.ISO AS Currency, 
			LF.LegalEntityId, @ReceiptEntityTypeValues_Discounting AS EntityType, C.Id AS DiscountingId, C.SequenceNumber
		FROM 
			ReceiptPostByLockBox_Extract RPBL
		INNER JOIN Discountings C ON RPBL.ContractNumber = C.SequenceNumber
		INNER JOIN DiscountingFinances LF ON C.Id = LF.DiscountingId
		INNER JOIN Currencies CR ON C.CurrencyId = CR.Id
		INNER JOIN CurrencyCodes CC ON CR.CurrencyCodeId = CC.Id
		LEFT JOIN #ReceiptContractDetails InvEntityInfo ON RPBL.Id = InvEntityInfo.ExtractId
		WHERE 
			RPBL.JobStepInstanceId = @JobStepInstanceId AND LF.IsCurrent = 1 AND RPBL.IsValid = 1 
			AND ((IsValidInvoice = 0 OR (IsValidInvoice = 1 AND IsInvoiceContractAssociated = 1)) OR IsValidContract = 0)
			AND (InvEntityInfo.ExtractId IS NULL OR InvEntityInfo.EntityType = @ReceivableEntityTypeValues_DT)
	) As ContractDetails
	
	UPDATE ReceiptPostByLockBox_Extract
		SET LineOfBusinessId = CD.LineofBusinessId, InstrumentTypeId = CD.InstrumentTypeId, CostCenterId = CD.CostCenterId,
			ReceiptClassification = CD.ReceiptClassification, CurrencyId = CD.CurrencyId, 
			Currency = CD.Currency, ContractId = CD.ContractId, DiscountingId = CD.DiscountingId, CashTypeId = NULL, 
			LegalEntityId = CASE WHEN RPBL.LegalEntityId IS NOT NULL THEN RPBL.LegalEntityId ELSE CD.LegalEntityId END, 
			EntityType = CASE WHEN (RPBL.ErrorCode LIKE '%'+ @ReceiptLockBoxErrorCodeValues_LB209 + '%' AND RPBL.IsValidLegalEntity = 1 
							AND @DefaultLegalEntityId IS NOT NULL) THEN 
								@ReceiptEntityTypeValues_UnKnown 
						 ELSE CD.EntityType END,
			CustomerId = CASE WHEN (RPBL.ErrorCode LIKE '%'+ @ReceiptLockBoxErrorCodeValues_LB209 + '%' AND RPBL.IsValidLegalEntity = 1 
							AND @DefaultLegalEntityId IS NOT NULL) THEN 
								NULL 
						 ELSE CD.CustomerId END
	FROM 
		ReceiptPostByLockBox_Extract RPBL
	INNER JOIN #ReceiptPostByLockBoxExtractContractDetails CD ON RPBL.Id = CD.Id
	;

	UPDATE ReceiptPostByLockBox_Extract
	SET
		IsValid = 0,
		ErrorCode = CONCAT(ErrorCode, @ErrorDelimiter, @ReceiptLockBoxErrorCodeValues_LB007),
		ErrorMessage = CONCAT(ErrorMessage, @ErrorDelimiter, @ReceiptLockBoxErrorMessage_LB007)
	FROM ReceiptPostByLockBox_Extract RPBLE
	INNER JOIN LegalEntities LE ON RPBLE.LegalEntityId = LE.Id
	WHERE LE.GLConfigurationId <> @GLConfigurationId
	 AND JobStepInstanceId = @JobStepInstanceId AND IsValid = 1

	
	UPDATE ReceiptPostByLockBox_Extract
	SET CreateUnallocatedReceipt = 1,
		Comment = CASE WHEN Comment IS NULL THEN @ReceiptLockBoxComment_LB416 ELSE CONCAT(Comment, @ErrorDelimiter, @ReceiptLockBoxComment_LB416) END
	FROM ReceiptPostByLockBox_Extract RPBLE
	INNER JOIN LegalEntities LE ON RPBLE.LegalEntityId = LE.Id
	INNER JOIN #ReceiptContractDetails C ON RPBLE.Id = C.ExtractId
	INNER JOIN LegalEntities LEC ON C.LegalEntityId = LEC.Id 
	WHERE LE.GLConfigurationId <> LEC.GLConfigurationId 
		AND RPBLE.JobStepInstanceId = @JobStepInstanceId AND IsValid = 1 AND (RPBLE.ContractNumber IS NULL OR RPBLE.ContractNumber = '')


	UPDATE ReceiptPostByLockBox_Extract
	SET CreateUnallocatedReceipt = 1,
		EntityType = @ReceiptEntityTypeValues_UnKnown,
		ContractId = NULL,
		DiscountingId = NULL,
		ContractNumber = NULL,
		CustomerId = NULL,
		Comment = CASE WHEN Comment IS NULL THEN @ReceiptLockBoxComment_LB416 ELSE CONCAT(Comment, @ErrorDelimiter, @ReceiptLockBoxComment_LB416) END
	FROM ReceiptPostByLockBox_Extract RPBLE
	INNER JOIN LegalEntities LE ON RPBLE.LegalEntityId = LE.Id
	INNER JOIN #ReceiptPostByLockBoxExtractContractDetails C ON RPBLE.Id = C.Id AND RPBLE.ContractNumber = C.SequenceNumber
	INNER JOIN LegalEntities LEC ON C.LegalEntityId = LEC.Id 
	WHERE LE.GLConfigurationId <> LEC.GLConfigurationId 
		AND RPBLE.JobStepInstanceId = @JobStepInstanceId AND IsValid = 1 AND (RPBLE.ContractNumber IS NOT NULL OR RPBLE.ContractNumber != '')

	-- CashType

	UPDATE ReceiptPostByLockBox_Extract
	SET
		CashTypeId = LDPC.CashTypeId
	FROM ReceiptPostByLockBox_Extract RPBLE
	JOIN LockboxDefaultParameterConfigs LDPC ON RPBLE.LegalEntityId = LDPC.LegalEntityId AND
		RPBLE.LineOfBusinessId = LDPC.LineOfBusinessId AND RPBLE.CostCenterId = LDPC.CostCenterId AND
		RPBLE.InstrumentTypeId = LDPC.InstrumentTypeId AND RPBLE.CurrencyId = LDPC.CurrencyId
	WHERE RPBLE.JobStepInstanceId = @JobStepInstanceId
	--

	UPDATE ReceiptPostByLockBox_Extract 
		SET CashTypeId = CT.Id
	FROM 
		ReceiptPostByLockBox_Extract RPBL
	INNER JOIN LegalEntities LE ON RPBL.LegalEntityId = LE.Id
	INNER JOIN BusinessTypes BT ON LE.BusinessTypeId = BT.Id
	INNER JOIN CashTypes CT ON BT.PortfolioId = CT.PortfolioId
	WHERE 
		CT.Type = @DefaultCashType AND RPBL.CashTypeId IS NULL AND
		RPBL.JobStepInstanceId = @JobStepInstanceId


	--Bank Account

	UPDATE ReceiptPostByLockBox_Extract
		SET BankAccountId = BA.Id
	FROM 
		ReceiptPostByLockBox_Extract RPBL
	INNER JOIN BankAccounts BA ON RPBL.BankAccountNumberEncrypted = BA.AccountNumber_CT
	INNER JOIN BankBranches BB ON BA.BankBranchId = BB.Id AND BB.BankName = RPBL.BankName
	WHERE 
		RPBL.BankAccountNumber IS NOT NULL AND RPBL.IsValid = 1 
	AND RPBL.JobStepInstanceId = @JobStepInstanceId
	;

	-- Bank Account Population

	UPDATE ReceiptPostByLockBox_Extract
		SET BankAccountId = LE.BankAccountId
	FROM ReceiptPostByLockBox_Extract RPBL
	INNER JOIN (
		SELECT 
			LE.Id, LE.LegalEntityNumber, BA.Id BankAccountId, BA.AccountName, BA.RemittanceType, 
			ROW_NUMBER() OVER(PARTITION BY LegalEntityNumber ORDER BY BA.RemittanceType DESC, BA.Id DESC) RowNumber
		FROM LegalEntities LE 
		INNER JOIN LegalEntityBankAccounts LEBA ON LE.Id = LEBA.LegalEntityId
		INNER JOIN BankAccounts BA ON LEBA.BankAccountId = BA.Id
		WHERE 
			BA.RemittanceType IN (@RemitToReceiptTypeValues_Check, @RemitToReceiptTypeValues_All) 
			AND	BA.IsActive = 1 AND LEBA.IsActive = 1
	) AS LE 
	ON RPBL.LegalEntityId = LE.Id AND LE.RowNumber = 1
	WHERE RPBL.JobStepInstanceId = @JobStepInstanceId
	AND RPBL.IsValid = 1 AND RPBL.BankAccountId IS NULL


	UPDATE RPBL SET 
	RPBL.ReceiptTypeId = @ReceiptTypeId,
	RPBL.ReceiptClassification = 
	CASE 
		WHEN RPBL.IsNonAccrualLoan=1 THEN 'NonAccrualNonDSL'
		ELSE RPBL.ReceiptClassification
	END
	FROM ReceiptPostByLockBox_Extract RPBL
	WHERE RPBL.JobStepInstanceId = @JobStepInstanceId AND RPBL.IsValid = 1 
	;
	UPDATE ReceiptPostByLockBox_Extract
					SET ErrorCode = CASE WHEN LEFT(ErrorCode ,1) = @ErrorDelimiter THEN RIGHT(ErrorCode,LEN(ErrorCode)-1)
                    ELSE ErrorCode END,
					ErrorMessage = CASE WHEN LEFT(ErrorMessage ,1) = @ErrorDelimiter THEN RIGHT(ErrorMessage,LEN(ErrorMessage)-1)
                    ELSE ErrorMessage END,
					LockBoxReceiptId = LockBoxReceiptId * -1
	WHERE JobStepInstanceId = @JobStepInstanceId

	--Update Comment

	UPDATE ReceiptPostByLockBox_Extract
	SET Comment = Replace(Comment, '@Entity', 
				CASE WHEN EntityType = @ReceiptEntityTypeValues_Lease 
							OR EntityType = @ReceiptEntityTypeValues_Loan 
							OR EntityType = @ReceiptEntityTypeValues_LeveragedLease 
							OR EntityType = @ReceiptEntityTypeValues_Discounting
					 THEN 'Contract'  
					 WHEN EntityType = @ReceiptEntityTypeValues_UnKnown AND IsValidLegalEntity = 0 AND @DefaultLegalEntityId IS NOT NULL 
					 THEN 'Default Legal Entity' 
					 WHEN EntityType = @ReceiptEntityTypeValues_UnKnown AND IsValidLegalEntity = 1	
					 THEN 'Legal Entity'
					 ELSE 'Customer' END)
	WHERE JobStepInstanceId = @JobStepInstanceId
		
	DROP TABLE #ReceiptContractDetails
	DROP TABLE #ReceiptPostByLockBoxExtractContractDetails
END

GO
