SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROC [dbo].[ReceiptLockBoxCustomDataValidator]
(
	@JobStepInstanceId						BIGINT,
	@GLTemplateId							BIGINT,
	@BusinessUnitId							BIGINT,
	@ReceiptStatusValues_Pending			NVARCHAR(20),
	@ReceiptStatusValues_ReadyForPosting	NVARCHAR(20),
	@ReceiptStatusValues_Submitted			NVARCHAR(20),
	@ReceivableEntityTypeValues_CT			NVARCHAR(2),
	@ReceivableEntityTypeValues_DT			NVARCHAR(2),
	@ContractEntityTypeValues_Loan			NVARCHAR(10),
	@AllowInterCompanyTransfer				BIT,
	@DefaultLegalEntityNumber				NVARCHAR(200),
	@LockboxErrorMessages LockboxErrorMessage READONLY,
	@HasValidRecords						BIT OUT
)
AS
BEGIN
	SET NOCOUNT ON;

	----------------------------------------------
	DECLARE @SingleQuote AS CHAR = CHAR(39)
	DECLARE @ErrorDelimiter AS CHAR = ','

	----------------------------------------------	

	SELECT * INTO #LockboxErrorMessages FROM @LockboxErrorMessages
	DECLARE @InvalidAttributesMessage NVARCHAR(200)
	SELECT @InvalidAttributesMessage = ErrorMessage FROM #LockboxErrorMessages WHERE ErrorCode = 'LB500'
	----------------------------------------------
	DECLARE @PortfolioId AS BIGINT
	SELECT @PortfolioId = PortfolioId FROM BusinessUnits WHERE Id = @BusinessUnitId

	DECLARE @DefaultLegalEntityId AS BIGINT
	SELECT @DefaultLegalEntityId = Id FROM LegalEntities WHERE LegalEntityNumber = @DefaultLegalEntityNumber AND STATUS = 'Active'

	DECLARE @GLConfigurationId AS BIGINT
	SELECT @GLConfigurationId = GLConfigurationId FROM GLTemplates WHERE Id = @GLTemplateId

	----------------------------------------------
	SELECT
		LE.LegalEntityNumber,
		LDPC.LegalEntityId
	INTO #DefaultLockboxParameterInfo
	FROM LockboxDefaultParameterConfigs LDPC
	INNER JOIN LegalEntities LE ON LDPC.LegalEntityId = LE.Id
	WHERE LDPC.IsActive = 1 AND LE.Status = 'Active'
	GROUP BY 
		LE.LegalEntityNumber,
		LDPC.LegalEntityId
	
	------------------------------------------------
	-- Identify File LE/ Default LE/ Invoice LE

	UPDATE ReceiptPostByLockBox_Extract
		SET LegalEntityId = CASE WHEN LF.Id IS NULL then @DefaultLegalEntityId
		ELSE LF.Id
		END
	FROM ReceiptPostByLockBox_Extract RPBF
	LEFT JOIN LegalEntities LF ON RPBF.LegalEntityNumber = LF.LegalEntityNumber
	WHERE RPBF.JobStepInstanceId = @JobStepInstanceId	

	UPDATE ReceiptPostByLockBox_Extract
		SET LegalEntityId = CASE WHEN (RPBL.LegalEntityNumber IS NULL OR RPBL.LegalEntityNumber = '') AND @DefaultLegalEntityId IS NULL THEN
								RI.LegalEntityId
							ELSE 
								RPBL.LegalEntityId
							END
	FROM ReceivableInvoices RI
	INNER JOIN ReceiptPostByLockBox_Extract RPBL ON RI.Number = RPBL.InvoiceNumber
	WHERE InvoiceNumber IS NOT NULL AND RI.IsActive = 1 AND RPBL.JobStepInstanceId = @JobStepInstanceId

	------------------------------------------------
	-- data validations
	EXEC ReceiptLockboxFieldDataValidator @JobStepInstanceId, @LockboxErrorMessages

	--MarKing NA with the 2 Validations
	EXEC ReceiptLockBoxNonAccrualValidator @JobStepInstanceId, @LockboxErrorMessages


	EXEC ReceiptLockboxFieldAssociationValidator @JobStepInstanceId, @ReceivableEntityTypeValues_CT, @ReceivableEntityTypeValues_DT, @AllowInterCompanyTransfer, @DefaultLegalEntityNumber, @LockboxErrorMessages

	-- invalid received amount 
	UPDATE ReceiptPostByLockBox_Extract
	SET
		IsValid = 0,
		ErrorCode = CONCAT(ErrorCode, @ErrorDelimiter, 'LB003'),
		ErrorMessage = CONCAT(ErrorMessage, @ErrorDelimiter, (SELECT ErrorMessage FROM #LockboxErrorMessages WHERE ErrorCode = 'LB003'))
	WHERE 
		JobStepInstanceId = @JobStepInstanceId 
		AND ReceivedAmount <= 0

	-- no record in lockbox param configs for given LE
	UPDATE ReceiptPostByLockBox_Extract
	SET
		IsValid = 0,
		HasMandatoryFields = 0,
		ErrorCode = CONCAT(ErrorCode, @ErrorDelimiter + 'LB004'),
		ErrorMessage = CONCAT(ErrorMessage, @ErrorDelimiter + REPLACE((SELECT ErrorMessage FROM #LockboxErrorMessages WHERE ErrorCode = 'LB004'), '@LegalEntityNumber', + @SingleQuote + RPBLE.LegalEntityNumber + @SingleQuote))
	FROM ReceiptPostByLockBox_Extract RPBLE
	LEFT JOIN #DefaultLockboxParameterInfo DLEN ON RPBLE.LegalEntityNumber = DLEN.LegalEntityNumber
	WHERE 
		DLEN.LegalEntityNumber IS NULL AND
		dbo.IsStringNullOrEmpty(RPBLE.LegalEntityNumber) = 0 AND RPBLE.IsValidLegalEntity = 1 AND
		RPBLE.JobStepInstanceId = @JobStepInstanceId

	-- Common Validations for With And Without Default Legal Entity
	EXEC ReceiptLockBoxCommonCustomDataValidator @JobStepInstanceId, @AllowInterCompanyTransfer, @DefaultLegalEntityNumber, @LockboxErrorMessages
	
	-- Default LE based valiations
	IF @DefaultLegalEntityId IS NULL
	BEGIN
		EXEC ReceiptLockboxCustomDataValidatorWithoutDefaultLegalEntity @JobStepInstanceId, @AllowInterCompanyTransfer, @LockboxErrorMessages, @ReceivableEntityTypeValues_CT, @ReceivableEntityTypeValues_DT
	END
	ELSE
	BEGIN
		EXEC ReceiptLockboxCustomDataValidatorWithDefaultLegalEntity @JobStepInstanceId, @AllowInterCompanyTransfer, @DefaultLegalEntityNumber, @LockboxErrorMessages
	END

	--Association  checks
	
	UPDATE ReceiptPostByLockBox_Extract
	SET
		IsValid = 1,
		Comment = (SELECT ErrorMessage FROM #LockboxErrorMessages WHERE ErrorCode = 'LB208')
	WHERE
		JobStepInstanceId = @JobStepInstanceId AND
		HasMandatoryFields = 1
	AND IsValidInvoice = 1
	AND IsValidContract=1 AND dbo.IsStringNullOrEmpty(CustomerNumber) = 0
	AND IsContractCustomerAssociated = 0
	AND IsInvoiceCustomerAssociated = 1
	AND (IsContractLegalEntityAssociated = 1
	 OR @AllowInterCompanyTransfer = 1) AND IsNonAccrualLoan=0
	;
	UPDATE ReceiptPostByLockBox_Extract
	SET
	IsValid = 0,
	ErrorCode = CONCAT(ErrorCode, @ErrorDelimiter, 'LB407'),
	ErrorMessage = CONCAT(ErrorMessage, @ErrorDelimiter, (SELECT ErrorMessage FROM #LockboxErrorMessages WHERE ErrorCode = 'LB407'))
	WHERE 
	JobStepInstanceId = @JobStepInstanceId AND 
	IsNonAccrualLoan=0 AND 
	(IsValidLegalEntity = 1 OR @DefaultLegalEntityId IS NOT NULL) AND  
	@AllowInterCompanyTransfer = 0 AND 
	((dbo.IsStringNullOrEmpty(ContractNumber) = 0 AND IsContractLegalEntityAssociated = 0) 
		OR (dbo.IsStringNullOrEmpty(InvoiceNumber) = 0 AND IsInvoiceLegalEntityAssociated = 0 ))
	

	-- finding Legal entity 
	;WITH ContractLegalEntityInfo AS
	(	
		SELECT LF.LegalEntityId, SequenceNumber
		FROM Contracts C
		JOIN LeaseFinances LF ON C.Id = LF.ContractId
		GROUP BY LF.LegalEntityId, SequenceNumber
		UNION
		SELECT LL.LegalEntityId, SequenceNumber
		FROM Contracts C
		JOIN LeveragedLeases LL ON C.Id = LL.ContractId
		GROUP BY LL.LegalEntityId, SequenceNumber
		UNION
		SELECT LF.LegalEntityId, SequenceNumber
		FROM Contracts C
		JOIN LoanFinances LF ON C.Id = LF.ContractId
		GROUP BY LF.LegalEntityId, SequenceNumber
		UNION
		SELECT DF.LegalEntityId, D.SequenceNumber
		FROM Discountings D
		JOIN DiscountingFinances DF ON D.Id = DF.DiscountingId
		GROUP BY DF.LegalEntityId, D.SequenceNumber
	)
	UPDATE ReceiptPostByLockBox_Extract
		SET 
			LegalEntityId =
				CASE
					WHEN RPBLE.IsNonAccrualLoan=1 THEN InvoiceLE.LegalEntityId
					WHEN RPBLE.IsNonAccrualLoan=0 AND ExtractLE.LegalEntityId IS NOT NULL AND (IsValidContract = 0 OR (IsValidContract = 1 AND IsContractLegalEntityAssociated = 1)) THEN ExtractLE.LegalEntityId
					WHEN RPBLE.IsNonAccrualLoan=0 AND @DefaultLegalEntityId IS NOT NULL AND (IsValidContract = 0 OR (IsValidContract = 1 AND (CLEI.LegalEntityId = @DefaultLegalEntityId OR @AllowInterCompanyTransfer = 1))) THEN @DefaultLegalEntityId
					WHEN RPBLE.IsNonAccrualLoan=0 AND InvoiceLE.LegalEntityId IS NOT NULL THEN InvoiceLE.LegalEntityId
					WHEN RPBLE.IsNonAccrualLoan=0 AND ContractLE.LegalEntityId IS NOT NULL THEN ContractLE.LegalEntityId
				END
	FROM ReceiptPostByLockBox_Extract RPBLE
	LEFT JOIN ReceivableInvoices RI ON RPBLE.InvoiceNumber = RI.Number
	LEFT JOIN ContractLegalEntityInfo CLEI ON RPBLE.ContractNumber = CLEI.SequenceNumber
	LEFT JOIN #DefaultLockboxParameterInfo ExtractLE ON RPBLE.LegalEntityNumber = ExtractLE.LegalEntityNumber
	LEFT JOIN #DefaultLockboxParameterInfo InvoiceLE ON RI.LegalEntityId = InvoiceLE.LegalEntityId
	LEFT JOIN #DefaultLockboxParameterInfo ContractLE ON CLEI.LegalEntityId = ContractLE.LegalEntityId
	WHERE
		RPBLE.JobStepInstanceId = @JobStepInstanceId AND
		RPBLE.IsValid = 1 AND
		(
			ExtractLE.LegalEntityId IS NOT NULL OR
			InvoiceLE.LegalEntityId IS NOT NULL OR
			ContractLE.LegalEntityId IS NOT NULL OR
			@DefaultLegalEntityId IS NOT NULL
		)
		
	DROP TABLE #DefaultLockboxParameterInfo

	-- bank account and LE association 
	;WITH LEBankNameAccountNumber AS
	(
		SELECT 
			BB.BankName, 
			BA.AccountNumber_CT, 
			LegalEntityId
		FROM BankBranches BB
		JOIN BankAccounts BA ON BB.Id = Ba.BankBranchId
		JOIN LegalEntityBankAccounts LEBA ON BA.Id = LEBA.BankAccountId
		WHERE LEBA.IsActive = 1
		GROUP BY
			BB.BankName, 
			BA.AccountNumber_CT, 
			LegalEntityId
	)
	UPDATE ReceiptPostByLockBox_Extract 
	SET
		IsValid = 0,
		ErrorCode = CONCAT(ErrorCode, @ErrorDelimiter, 'LB010'),
		ErrorMessage = CONCAT(ErrorMessage, @ErrorDelimiter, (SELECT ErrorMessage FROM #LockboxErrorMessages WHERE ErrorCode = 'LB010'))
	FROM ReceiptPostByLockBox_Extract RPBLE
	LEFT JOIN LEBankNameAccountNumber LEBNAN 
	ON 
		RPBLE.BankAccountNumberEncrypted = LEBNAN.AccountNumber_CT AND 
		RPBLE.BankName = LEBNAN.BankName AND
		RPBLE.LegalEntityId = LEBNAN.LegalEntityId
	WHERE
		JobStepInstanceId = @JobStepInstanceId AND
		RPBLE.IsValidBankName = 1 AND RPBLE.BankName <> '' AND RPBLE.BankAccountNumber IS NOT NULL AND
		RPBLE.IsValidBankAccountNumber = 1 AND RPBLE.BankAccountNumberEncrypted IS NOT NULL AND
		RPBLE.IsValidLegalEntity = 1 AND
		LEBNAN.AccountNumber_CT IS NULL

	---- unposted receipt (For Non-Accrual)
	UPDATE ReceiptPostByLockBox_Extract
	SET
		IsValid = 0,
		ErrorCode = CONCAT(ErrorCode, @ErrorDelimiter, 'LB006'),
		ErrorMessage = CONCAT(ErrorMessage, @ErrorDelimiter, (SELECT ErrorMessage FROM #LockboxErrorMessages WHERE ErrorCode = 'LB006'))
	FROM ReceiptPostByLockBox_Extract RPBLE
	JOIN Contracts C ON RPBLE.ContractNumber = C.SequenceNumber
		AND C.ContractType = @ContractEntityTypeValues_Loan AND C.IsNonAccrual = 1
	JOIN Receipts R ON R.ContractId = C.Id
	WHERE 
		R.Status IN (
			@ReceiptStatusValues_Pending, 
			@ReceiptStatusValues_ReadyForPosting, 
			@ReceiptStatusValues_Submitted
		)
	AND RPBLE.JobStepInstanceId = @JobStepInstanceId
	AND RPBLE.IsNonAccrualLoan=1

	UPDATE ReceiptPostByLockBox_Extract
					SET ErrorCode = CASE WHEN LEFT(ErrorCode ,1) = @ErrorDelimiter THEN RIGHT(ErrorCode,LEN(ErrorCode)-1)
                    ELSE ErrorCode END,
					ErrorMessage = CASE WHEN LEFT(ErrorMessage ,1) = @ErrorDelimiter THEN RIGHT(ErrorMessage,LEN(ErrorMessage)-1)
                    ELSE ErrorMessage END
	WHERE JobStepInstanceId = @JobStepInstanceId

	IF EXISTS(SELECT 1 FROM ReceiptPostByLockBox_Extract WHERE IsValid = 1 AND JobStepInstanceId=@JobStepInstanceId)
	BEGIN
		SET @HasValidRecords = 1 
	END
	ELSE
	BEGIN
		SET @HasValidRecords = 0
	END

	--Update comment--

	UPDATE ReceiptPostByLockBox_Extract SET Comment = Trim(@ErrorDelimiter FROM
	CASE WHEN (dbo.IsStringNullOrEmpty(LegalEntityNumber) = 1 OR IsValidLegalEntity = 1) AND 
			(dbo.IsStringNullOrEmpty(CustomerNumber) = 1 OR IsValidCustomer = 1) AND 
			(dbo.IsStringNullOrEmpty(ContractNumber) = 1 OR IsValidContract = 1) AND 
			(dbo.IsStringNullOrEmpty(InvoiceNumber) = 1 OR IsValidInvoice = 1)
		 THEN Trim(@ErrorDelimiter FROM Replace(Comment, @InvalidAttributesMessage, ''))
	ELSE 
	Trim(@ErrorDelimiter FROM Replace(
	Replace(Comment, '@InvalidAttributes', Trim(@ErrorDelimiter FROM Concat(
	CASE WHEN dbo.IsStringNullOrEmpty(LegalEntityNumber) = 0 AND IsValidLegalEntity = 0 
		THEN Concat('Legal Entity Number',@ErrorDelimiter) ELSE '' END ,
	CASE WHEN dbo.IsStringNullOrEmpty(CustomerNumber) = 0 AND IsValidCustomer = 0 
		THEN Concat('Customer Number',@ErrorDelimiter) ELSE '' END  ,
	CASE WHEN dbo.IsStringNullOrEmpty(ContractNumber) = 0 AND IsValidContract= 0 
		THEN Concat('Contract Number',@ErrorDelimiter) ELSE '' END ,
	CASE WHEN dbo.IsStringNullOrEmpty(InvoiceNumber) = 0 AND IsValidInvoice = 0 
		THEN CONCAT('Invoice Number',@ErrorDelimiter) END 				 
	)))
	, '@ReceiptPostingType', CASE WHEN dbo.IsStringNullOrEmpty(InvoiceNumber) = 0 AND IsValidInvoice = 1 THEN 'Receipt' ELSE 'UnAllocated Receipt' END))
	END)
	WHERE JobStepInstanceId = @JobStepInstanceId


END 

GO
