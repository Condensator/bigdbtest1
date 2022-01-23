SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROC [dbo].[ReceiptLockBoxCommonCustomDataValidator]
(
	@JobStepInstanceId						BIGINT,
	@AllowInterCompanyTransfer				BIT,
	@DefaultLegalEntityNumber				NVARCHAR(200),
	@LockboxErrorMessages LockboxErrorMessage READONLY
)
AS
BEGIN
	SET NOCOUNT ON;

	----------------------------------------------	

	SELECT * INTO #LockboxErrorMessages FROM @LockboxErrorMessages
	DECLARE @InvalidAttributesMessage NVARCHAR(200)
	SELECT @InvalidAttributesMessage = ErrorMessage FROM #LockboxErrorMessages WHERE ErrorCode = 'LB500'

	DECLARE @DefaultLegalEntityId AS BIGINT
	SELECT @DefaultLegalEntityId = Id FROM LegalEntities WHERE LegalEntityNumber = @DefaultLegalEntityNumber AND STATUS = 'Active'
	----------------------------------------------

	UPDATE ReceiptPostByLockBox_Extract
	SET
		IsValid = 1
	WHERE
		JobStepInstanceId = @JobStepInstanceId 
	AND HasMandatoryFields = 1
	AND IsValidInvoice = 1
	AND	IsValidContract = 1 	
	AND IsValidLegalEntity = 1
	AND IsContractLegalEntityAssociated = 1
	AND (IsInvoiceLegalEntityAssociated = 1 OR @AllowInterCompanyTransfer = 1) 
	AND IsNonAccrualLoan=0	

	UPDATE ReceiptPostByLockBox_Extract
	SET
		IsValid = 1,
		Comment = @InvalidAttributesMessage
	WHERE
		JobStepInstanceId = @JobStepInstanceId 
	AND HasMandatoryFields = 1
	AND IsValidInvoice = 0
	AND	IsValidContract = 1 	
	AND IsValidLegalEntity = 0
	AND IsValidCustomer = 0
	AND @DefaultLegalEntityId IS NULL 
	AND IsNonAccrualLoan=0	

	UPDATE ReceiptPostByLockBox_Extract
	SET
		IsValid = 1,
		Comment = @InvalidAttributesMessage
	WHERE
		JobStepInstanceId = @JobStepInstanceId 
	AND HasMandatoryFields = 1
	AND IsValidInvoice = 0
	AND	IsValidContract = 0 	
	AND IsValidLegalEntity = 0
	AND IsValidCustomer = 0
	AND @DefaultLegalEntityId IS NOT NULL 
	AND IsNonAccrualLoan=0	

	UPDATE ReceiptPostByLockBox_Extract
	SET
		IsValid = 1,
		Comment = @InvalidAttributesMessage
	WHERE
		JobStepInstanceId = @JobStepInstanceId 
	AND HasMandatoryFields = 1
	AND IsValidInvoice = 1
	AND	dbo.IsStringNullOrEmpty(ContractNumber) = 0 AND IsValidContract = 0 
	AND IsValidCustomer = 0
	AND IsValidLegalEntity = 0
	AND (IsInvoiceLegalEntityAssociated = 1 OR @AllowInterCompanyTransfer = 1) 
	AND IsNonAccrualLoan=0	

	UPDATE ReceiptPostByLockBox_Extract
	SET
		IsValid = 1,
		Comment = @InvalidAttributesMessage
	WHERE
		JobStepInstanceId = @JobStepInstanceId 
	AND HasMandatoryFields = 1
	AND IsValidInvoice = 1
	AND (dbo.IsStringNullOrEmpty(ContractNumber) = 1 OR IsInvoiceContractAssociated = 1)
	AND	dbo.IsStringNullOrEmpty(CustomerNumber) = 0 AND IsValidCustomer = 0 
	AND LegalEntityId IS NOT NULL 
	AND (IsInvoiceLegalEntityAssociated = 1 OR @AllowInterCompanyTransfer = 1) 
	AND IsNonAccrualLoan=0	

	UPDATE ReceiptPostByLockBox_Extract
	SET
		IsValid = 1,
		Comment = @InvalidAttributesMessage
	WHERE
		JobStepInstanceId = @JobStepInstanceId 
	AND HasMandatoryFields = 1
	AND IsValidInvoice = 1
	AND	dbo.IsStringNullOrEmpty(ContractNumber) = 0 AND IsValidContract = 0 
	AND IsValidCustomer = 1
	AND LegalEntityId IS NOT NULL 
	AND IsInvoiceCustomerAssociated = 1
	AND (IsInvoiceLegalEntityAssociated = 1 OR @AllowInterCompanyTransfer = 1) 
	AND IsNonAccrualLoan=0	

	UPDATE ReceiptPostByLockBox_Extract
	SET
		IsValid = 1,
		Comment = @InvalidAttributesMessage
	WHERE
		JobStepInstanceId = @JobStepInstanceId 
	AND HasMandatoryFields = 1
	AND IsValidInvoice = 1
	AND	dbo.IsStringNullOrEmpty(ContractNumber) = 0 AND IsValidContract = 0 
	AND IsValidCustomer = 0
	AND IsValidLegalEntity = 1	
	AND (IsInvoiceLegalEntityAssociated = 1 OR @AllowInterCompanyTransfer = 1) 
	AND IsNonAccrualLoan=0	

	UPDATE ReceiptPostByLockBox_Extract
	SET
		IsValid = 1,
		Comment = @InvalidAttributesMessage
	WHERE
		JobStepInstanceId = @JobStepInstanceId 
	AND HasMandatoryFields = 1
	AND IsValidInvoice = 1
	AND	dbo.IsStringNullOrEmpty(ContractNumber) = 0 AND IsValidContract = 0 
	AND	dbo.IsStringNullOrEmpty(CustomerNumber	) = 0 AND IsValidCustomer = 0
	AND IsValidLegalEntity = 1	
	AND (IsInvoiceLegalEntityAssociated = 1 OR @AllowInterCompanyTransfer = 1) 
	AND IsNonAccrualLoan=0

	UPDATE ReceiptPostByLockBox_Extract
	SET
		IsValid = 1,
		Comment = @InvalidAttributesMessage
	WHERE
		JobStepInstanceId = @JobStepInstanceId 
		AND HasMandatoryFields = 1
		AND IsValidInvoice = 1
		AND	dbo.IsStringNullOrEmpty(ContractNumber) = 1 AND IsValidContract = 0 
		AND	dbo.IsStringNullOrEmpty(CustomerNumber) = 0 AND IsValidCustomer = 0
		AND IsValidLegalEntity = 1			
		AND (IsInvoiceLegalEntityAssociated = 1 OR @AllowInterCompanyTransfer = 1) 
		AND IsNonAccrualLoan=0	
		
	UPDATE ReceiptPostByLockBox_Extract
	SET
		IsValid = 1,
		Comment = @InvalidAttributesMessage
	WHERE
		JobStepInstanceId = @JobStepInstanceId 
		AND HasMandatoryFields = 1
		AND	dbo.IsStringNullOrEmpty(InvoiceNumber) = 1 AND IsValidInvoice = 0
		AND	dbo.IsStringNullOrEmpty(ContractNumber) = 1 AND IsValidContract = 0 
		AND	dbo.IsStringNullOrEmpty(CustomerNumber) = 0 AND IsValidCustomer = 0
		AND IsValidLegalEntity = 1					
		AND IsNonAccrualLoan=0	

	UPDATE ReceiptPostByLockBox_Extract
	SET
		IsValid = 1,
		Comment = @InvalidAttributesMessage
	WHERE
		JobStepInstanceId = @JobStepInstanceId AND
		HasMandatoryFields = 1 AND
		(dbo.IsStringNullOrEmpty(InvoiceNumber) = 0 AND IsValidInvoice = 0) AND	
		IsValidContract = 1 AND
		IsNonAccrualLoan=0

	UPDATE ReceiptPostByLockBox_Extract
	SET
		IsValid = 1,
		Comment = @InvalidAttributesMessage
	WHERE
		JobStepInstanceId = @JobStepInstanceId AND
		HasMandatoryFields = 1 AND
		(dbo.IsStringNullOrEmpty(InvoiceNumber) = 0 AND IsValidInvoice = 0) AND
		IsValidContract = 0 AND
		IsValidCustomer = 1 AND
		LegalEntityId IS NOT NULL AND
		IsNonAccrualLoan=0

	UPDATE ReceiptPostByLockBox_Extract
	SET IsValid = 1,
		Comment = @InvalidAttributesMessage
	WHERE JobStepInstanceId = @JobStepInstanceId AND
		HasMandatoryFields = 1 AND
		IsValidInvoice = 1 AND
		IsValidContract = 1 AND
		LegalEntityId IS NOT NULL AND
		IsContractLegalEntityAssociated = 1 AND 
		IsInvoiceLegalEntityAssociated = 1 AND
		IsInvoiceContractAssociated = 0 AND 
		IsInvoiceCustomerAssociated = 0 AND
		IsContractCustomerAssociated = 0 AND 
		IsNonAccrualLoan=0

	UPDATE ReceiptPostByLockBox_Extract
	SET
		IsValid = 1,
		Comment = @InvalidAttributesMessage
	WHERE
		JobStepInstanceId = @JobStepInstanceId AND
		HasMandatoryFields = 1 AND
		(dbo.IsStringNullOrEmpty(InvoiceNumber) = 0 AND IsValidInvoice = 0) AND
		IsValidContract = 0 AND
		IsValidCustomer = 0 AND
		IsValidLegalEntity = 1 AND
		IsNonAccrualLoan=0	

	UPDATE ReceiptPostByLockBox_Extract
	SET 
		IsValid = 1,
		Comment = @InvalidAttributesMessage
	WHERE
		JobStepInstanceId = @JobStepInstanceId 
		AND HasMandatoryFields = 1 
		AND IsValidInvoice = 1 
		AND	dbo.IsStringNullOrEmpty(LegalEntityNumber) = 0 AND IsValidLegalEntity = 0 
		AND	dbo.IsStringNullOrEmpty(ContractNumber) = 0 AND IsValidContract = 0 
		AND	dbo.IsStringNullOrEmpty(CustomerNumber) = 0 AND IsValidCustomer = 0
		AND IsNonAccrualLoan = 0

	UPDATE ReceiptPostByLockBox_Extract
	SET
		IsValid = 1,
		Comment = @InvalidAttributesMessage
	WHERE
		HasMandatoryFields = 1 AND JobStepInstanceId = @JobStepInstanceId AND
		dbo.IsStringNullOrEmpty(InvoiceNumber) = 1 AND
		dbo.IsStringNullOrEmpty(ContractNumber) = 0 AND IsValidContract = 0 AND
		dbo.IsStringNullOrEmpty(CustomerNumber) = 1 AND
		IsValidLegalEntity = 1 AND		
		IsNonAccrualLoan=0

END 

GO
