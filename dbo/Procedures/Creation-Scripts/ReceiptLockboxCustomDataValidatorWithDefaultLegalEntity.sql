SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[ReceiptLockboxCustomDataValidatorWithDefaultLegalEntity]
(
	@JobStepInstanceId			BIGINT,
	@AllowInterCompanyTransfer	BIT,
	@DefaultLegalEntityNumber	NVARCHAR(200),
	@LockboxErrorMessages		LockboxErrorMessage READONLY
)
AS
BEGIN
	SET NOCOUNT ON;
	---------------------------------------------------
	DECLARE @SingleQuote AS CHAR = CHAR(39)
	DECLARE @ErrorDelimiter AS CHAR = ','

	----------------------------------------------------
	SELECT * INTO #LockboxErrorMessages FROM @LockboxErrorMessages
	DECLARE @InvalidAttributesMessage NVARCHAR(200)
	SELECT @InvalidAttributesMessage = ErrorMessage FROM #LockboxErrorMessages WHERE ErrorCode = 'LB500'
	----------------------------------------------------
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

	-----------------------------------------------------

	IF NOT EXISTS(SELECT 1 FROM #DefaultLockboxParameterInfo WHERE LegalEntityNumber = @DefaultLegalEntityNumber)
	BEGIN
		UPDATE ReceiptPostByLockBox_Extract
		SET
			IsValid = 0,
			HasMandatoryFields = 0,
			ErrorCode = CONCAT(ErrorCode, @ErrorDelimiter, 'LB004'),
			ErrorMessage = CONCAT(ErrorMessage, @ErrorDelimiter, REPLACE((SELECT ErrorMessage FROM #LockboxErrorMessages WHERE ErrorCode = 'LB004'), '@LegalEntityNumber', CONCAT(@SingleQuote, @DefaultLegalEntityNumber, @SingleQuote)))
		FROM ReceiptPostByLockBox_Extract RPBLE
		WHERE 
			JobStepInstanceId = @JobStepInstanceId AND
			dbo.IsStringNullOrEmpty(LegalEntityNumber) = 1
			AND RPBLE.IsNonAccrualLoan=0 
	END
	;

	UPDATE ReceiptPostByLockBox_Extract
	SET 
		IsValid = 1,
		Comment = @InvalidAttributesMessage
	WHERE
		JobStepInstanceId = @JobStepInstanceId AND
		HasMandatoryFields = 1 AND
		IsValidLegalEntity = 0 AND
		(InvoiceNumber IS NULL OR InvoiceNumber = '') AND
		(ContractNumber IS NULL OR ContractNumber = '') AND
		(CustomerNumber IS NULL OR CustomerNumber = '') AND 
		IsNonAccrualLoan=0
	;

	UPDATE ReceiptPostByLockBox_Extract
	SET 
		IsValid = 1,
		Comment = @InvalidAttributesMessage
	WHERE
		JobStepInstanceId = @JobStepInstanceId AND
		HasMandatoryFields = 1 AND  IsValidLegalEntity = 0 AND 
		LegalEntityNumber IS NOT NULL AND LegalEntityNumber <> '' AND
		 (((InvoiceNumber IS NOT NULL AND InvoiceNumber <> '' AND IsValidInvoice = 0) OR IsInvoiceLegalEntityAssociated = 1) OR
		((ContractNumber IS NOT NULL AND ContractNumber <> '' AND IsValidContract = 0) OR IsInvoiceContractAssociated = 1)) --AND
		AND IsNonAccrualLoan=0 AND IsValid = 0
	;

	UPDATE ReceiptPostByLockBox_Extract
	SET 
		IsValid = 1,
		Comment = @InvalidAttributesMessage
	WHERE
		JobStepInstanceId = @JobStepInstanceId AND
		HasMandatoryFields = 1 AND
		IsValidLegalEntity = 0 AND IsValidCustomer = 0 AND
		LegalEntityNumber IS NOT NULL AND
		(InvoiceNumber IS NULL OR InvoiceNumber = '') AND
		(ContractNumber IS NULL OR ContractNumber = '') AND
		(CustomerNumber IS NOT NULL AND CustomerNumber <> '') AND IsNonAccrualLoan=0
	;

	UPDATE ReceiptPostByLockBox_Extract
	SET
		IsValid = 1,
		Comment = @InvalidAttributesMessage
	WHERE
		JobStepInstanceId = @JobStepInstanceId AND
		HasMandatoryFields = 1 AND
	(InvoiceNumber IS NOT NULL AND IsValidInvoice = 0) AND
	(LegalEntityNumber IS NULL OR LegalEntityNumber = '') AND
	(ContractNumber IS NULL OR ContractNumber = '') AND
	(CustomerNumber IS NULL AND CustomerNumber = '') AND IsNonAccrualLoan=0
	;	

	-------------------------------------------------
	-- Association Log Message
	UPDATE ReceiptPostByLockBox_Extract
	SET
		IsValid = 1,
		Comment = @InvalidAttributesMessage
	WHERE
		JobStepInstanceId = @JobStepInstanceId AND
		HasMandatoryFields = 1
		AND	IsValidCustomer = 0 
		AND IsValidContract = 1 AND dbo.IsStringNullOrEmpty(CustomerNumber) = 0 
		AND (InvoiceNumber IS NULL OR InvoiceNumber = '')
		AND (IsContractLegalEntityAssociated = 1
		 OR @AllowInterCompanyTransfer = 1) AND IsNonAccrualLoan=0
	;

	UPDATE ReceiptPostByLockBox_Extract
	SET
		IsValid = 1,
		Comment = @InvalidAttributesMessage
	WHERE
		JobStepInstanceId = @JobStepInstanceId 
		AND HasMandatoryFields = 1
		AND IsValidContract = 1
		AND	IsContractCustomerAssociated = 0 AND IsValidCustomer = 1
		AND (InvoiceNumber IS NULL OR InvoiceNumber = '')
		AND (IsContractLegalEntityAssociated = 1
		 OR @AllowInterCompanyTransfer = 1) AND IsNonAccrualLoan=0
	;

	UPDATE ReceiptPostByLockBox_Extract
	SET
		IsValid = 1,
		Comment = @InvalidAttributesMessage
	WHERE
		JobStepInstanceId = @JobStepInstanceId 
		AND HasMandatoryFields = 1
	AND	IsValidContract = 1 AND IsValidLegalEntity = 0
	AND (InvoiceNumber IS NULL OR InvoiceNumber = '')
	AND (CustomerNumber IS NULL OR CustomerNumber = '')
	AND (IsContractLegalEntityAssociated = 1
	 OR @AllowInterCompanyTransfer = 1) AND IsNonAccrualLoan=0

	;

	UPDATE ReceiptPostByLockBox_Extract
	SET IsValid = 1,
		Comment = (SELECT ErrorMessage FROM #LockboxErrorMessages WHERE ErrorCode = 'LB412')
	WHERE HasMandatoryFields = 1 AND JobStepInstanceId = @JobStepInstanceId 
		AND dbo.IsStringNullOrEmpty(CustomerNumber) = 0 
		AND (dbo.IsStringNullOrEmpty(ContractNumber) = 0 AND IsValidContract = 1)
		AND (dbo.IsStringNullOrEmpty(InvoiceNumber) = 0 AND IsValidInvoice = 1)
		AND IsInvoiceContractAssociated = 0
		AND IsInvoiceCustomerAssociated = 0
		AND IsContractCustomerAssociated = 0
		AND IsNonAccrualLoan=0

		UPDATE ReceiptPostByLockBox_Extract
	SET
		IsValid = 1,
		Comment = (SELECT ErrorMessage FROM #LockboxErrorMessages WHERE ErrorCode = 'LB410')
	WHERE
		HasMandatoryFields = 1 AND
		JobStepInstanceId = @JobStepInstanceId 
	AND IsValidInvoice=1
	AND IsValidCustomer=1
	AND IsInvoiceCustomerAssociated = 0
	AND IsInvoiceLegalEntityAssociated = 1 AND IsNonAccrualLoan=0
	;

	SELECT SequenceNumber, CustomerId INTO #ContractCustomerDetails
	FROM
	(
		SELECT
			C.SequenceNumber, LOF.CustomerId
		FROM Contracts C
		INNER JOIN LoanFinances LOF ON C.Id = LOF.ContractId
		UNION
		SELECT
			C.SequenceNumber, LEF.CustomerId
		FROM Contracts C
		INNER JOIN LeaseFinances LEF ON C.Id = LEF.ContractId
		UNION
		SELECT
			C.SequenceNumber, LEL.CustomerId
		FROM Contracts C
		INNER JOIN LeveragedLeases LEL on C.Id = LEL.ContractId
		UNION
		SELECT
			D.SequenceNumber, DF.FunderId AS CustomerId
		FROM Discountings D
		INNER JOIN DiscountingFinances DF ON D.Id = DF.DiscountingId
	) AS ContractDetails
	;

	UPDATE ReceiptPostByLockBox_Extract
	SET IsValid = 1,
		Comment = @InvalidAttributesMessage
	FROM ReceiptPostByLockBox_Extract RPBLE
	INNER JOIN ReceivableInvoices RI ON RPBLE.InvoiceNumber = RI.Number
	INNER JOIN #ContractCustomerDetails C ON RPBLE.ContractNumber = C.SequenceNumber
		AND RI.CustomerId <> C.CustomerId
	WHERE HasMandatoryFields = 1 AND RPBLE.JobStepInstanceId = @JobStepInstanceId
		AND (RPBLE.CustomerNumber IS NULL OR RPBLE.CustomerNumber = '')
		AND (RPBLE.LegalEntityNumber IS NULL OR RPBLE.LegalEntityNumber = '')
		AND IsValidInvoice = 1 AND IsValidContract = 1
		AND IsInvoiceContractAssociated = 0 AND RPBLE.IsNonAccrualLoan=0
	;

	UPDATE ReceiptPostByLockBox_Extract
	SET IsValid = 1,
		Comment = (SELECT ErrorMessage FROM #LockboxErrorMessages WHERE ErrorCode = 'LB411')
	WHERE JobStepInstanceId = @JobStepInstanceId AND
		HasMandatoryFields = 1 AND
		IsValidInvoice = 1 AND
		IsValidContract = 1 AND
		IsInvoiceContractAssociated = 0 AND 	
		(IsInvoiceLegalEntityAssociated = 1 OR IsContractLegalEntityAssociated = 1 ) AND
		IsNonAccrualLoan=0
	;

	UPDATE ReceiptPostByLockBox_Extract
	SET IsValid = 1
	WHERE HasMandatoryFields = 1 AND JobStepInstanceId = @JobStepInstanceId 
		AND ((LegalEntityNumber IS NOT NULL AND IsValidLegalEntity = 0)
			OR (LegalEntityNumber IS NULL OR LegalEntityNumber = ''))
		AND ((InvoiceNumber IS NOT NULL AND IsValidInvoice = 0)
			OR (InvoiceNumber IS NULL OR InvoiceNumber = ''))
		AND ((ContractNumber IS NOT NULL AND IsValidContract = 0)
			OR (ContractNumber IS NULL OR ContractNumber = ''))
		AND ((CustomerNumber IS NOT NULL AND IsValidContract = 0)
			OR (CustomerNumber IS NULL OR CustomerNumber = ''))
			AND IsNonAccrualLoan=0
	;

END

GO
