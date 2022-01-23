SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROC [dbo].[ReceiptLockboxFieldAssociationValidator]
(
	@JobStepInstanceId			BIGINT,
	@ReceivableEntityTypeValues_CT NVARCHAR(2),
	@ReceivableEntityTypeValues_DT NVARCHAR(2),
	@AllowInterCompanyTransfer	BIT,
	@DefaultLegalEntityNumber	NVARCHAR(200),
	@LockboxErrorMessages LockboxErrorMessage READONLY
)
AS
BEGIN
	SET NOCOUNT ON;

	
	CREATE TABLE #InvoiceContractExtractInfo
	(
	 ExtractId BIGINT,
	 EntityId BIGINT,
	 EntityType NVARCHAR(4) 
	)
	-----------------------------------------------

	DECLARE @ErrorDelimiter AS CHAR = ','

	DECLARE @DefaultLegalEntityId AS BIGINT
	SELECT @DefaultLegalEntityId = Id FROM LegalEntities WHERE LegalEntityNumber = @DefaultLegalEntityNumber

	DECLARE @ErrorMessage_LB209 AS NVARCHAR(200)
	SELECT @ErrorMessage_LB209 = LEM.ErrorMessage FROM @LockboxErrorMessages LEM WHERE LEM.ErrorCode = 'LB209'

	DECLARE @ErrorMessage_LB210 AS NVARCHAR(200)
	SELECT @ErrorMessage_LB210 = LEM.ErrorMessage FROM @LockboxErrorMessages LEM WHERE LEM.ErrorCode = 'LB210'	

	-----------------------------------------------
	-- Contract AND Customer
	;WITH DiscountingInfo AS
	(
		SELECT D.SequenceNumber AS DiscountingNumber, P.PartyNumber AS FunderNumber
		FROM Discountings D
		JOIN DiscountingFinances DF ON D.Id = DF.DiscountingId
		JOIN Parties P ON P.Id = DF.FunderId
	),
	ContractIdCustomerIdMap AS
	(
		SELECT ContractId, CustomerId FROM LeaseFinances
		UNION
		SELECT ContractId, CustomerId FROM LoanFinances
		UNION
		SELECT ContractId, CustomerId FROM LeveragedLeases
	),
	ContractCustomerInfo AS
	(
		SELECT C.SequenceNumber AS ContractNumber, P.PartyNumber AS CustomerNumber
		FROM ContractIdCustomerIdMap CICIM
		JOIN Contracts C ON CICIM.ContractId = C.Id
		JOIN Parties P ON CICIM.CustomerId = P.Id
	)
	UPDATE ReceiptPostByLockBox_Extract
	SET
		IsContractCustomerAssociated = 
			CASE
				WHEN DI.DiscountingNumber IS NULL AND CCI.ContractNumber IS NULL THEN 0
				ELSE 1 
			END
	FROM ReceiptPostByLockBox_Extract RPBLE
	LEFT JOIN DiscountingInfo DI ON RPBLE.ContractNumber = DI.DiscountingNumber AND RPBLE.CustomerNumber = DI.FunderNumber
	LEFT JOIN ContractCustomerInfo CCI ON RPBLE.ContractNumber = CCI.ContractNumber AND RPBLE.CustomerNumber = CCI.CustomerNumber
	WHERE
		JobStepInstanceId = @JobStepInstanceId
	;

	UPDATE ReceiptPostByLockBox_Extract
	SET
		IsValid = 0,
		ErrorMessage = CONCAT(ErrorMessage, @ErrorDelimiter, @ErrorMessage_LB209),
		ErrorCode = CONCAT(ErrorCode, @ErrorDelimiter, 'LB209')
	WHERE
		JobStepInstanceId = @JobStepInstanceId AND 
		IsContractCustomerAssociated = 0 AND
		IsValidContract = 1 AND
		IsValidCustomer = 1

	--Contract AND Legal Entity

	;WITH ContractLegalEntityInfo AS
	(
		SELECT
			RPBLE.Id AS ExtractId,
			CASE
				WHEN Lease.Id IS NOT NULL THEN Lease.LegalEntityId
				WHEN Loan.Id IS NOT NULL THEN Loan.LegalEntityId
				WHEN LL.Id IS NOT NULL THEN LL.LegalEntityId
				ELSE NULL
			END AS LegalEntityId
		FROM ReceiptPostByLockBox_Extract RPBLE
		LEFT JOIN Contracts C ON RPBLE.ContractNumber = C.SequenceNumber
		LEFT JOIN LeaseFinances Lease ON C.Id = Lease.ContractId
		LEFT JOIN LoanFinances Loan ON C.Id = Loan.ContractId
		LEFT JOIN LeveragedLeases LL ON C.Id = LL.Id
		WHERE RPBLE.JobStepInstanceId = @JobStepInstanceId
		UNION
		SELECT
			RPBLE.Id AS ExtractId,
			Lease.LegalEntityId
		FROM ReceiptPostByLockBox_Extract RPBLE
		LEFT JOIN Discountings C ON RPBLE.ContractNumber = C.SequenceNumber
		JOIN DiscountingFinances Lease ON C.Id = Lease.DiscountingId AND Lease.IsCurrent = 1
	)	
	UPDATE ReceiptPostByLockBox_Extract
	SET 
		IsContractLegalEntityAssociated =
			CASE
				WHEN (CLEI.LegalEntityId = @DefaultLegalEntityId AND IsValidLegalEntity = 0) OR RPBLE.LegalEntityNumber = LE.LegalEntityNumber OR (@AllowInterCompanyTransfer = 1 AND IsValidContract = 1 AND (IsValidLegalEntity = 1 OR  @DefaultLegalEntityId IS NOT NULL)) THEN 1
				ELSE 0
			END
	FROM ReceiptPostByLockBox_Extract RPBLE
	JOIN ContractLegalEntityInfo CLEI ON RPBLE.Id = CLEI.ExtractId
	LEFT JOIN LegalEntities LE ON CLEI.LegalEntityId = LE.Id

	UPDATE ReceiptPostByLockBox_Extract
	SET 
		IsValid = 0,
		ErrorCode = CONCAT(ErrorCode, @ErrorDelimiter, 'LB210'),
		ErrorMessage = CONCAT(ErrorMessage, @ErrorDelimiter, @ErrorMessage_LB210)
	WHERE
		JobStepInstanceId = @JobStepInstanceId AND
		(IsValidLegalEntity = 1 OR @DefaultLegalEntityId IS NOT NULL) AND 
		IsValidContract = 1 AND
		IsContractLegalEntityAssociated = 0 AND
		dbo.IsStringNullOrEmpty(InvoiceNumber) = 1

	--Customer AND Invoice 
	UPDATE ReceiptPostByLockBox_Extract
	SET IsInvoiceCustomerAssociated =
			CASE
				WHEN RPBLE.CustomerNumber = P.PartyNumber THEN 1
				ELSE 0
			END
	FROM ReceiptPostByLockBox_Extract RPBLE
	LEFT JOIN ReceivableInvoices RI ON RPBLE.InvoiceNumber = RI.Number AND RI.IsActive = 1
	LEFT JOIN Parties P ON RI.CustomerId = P.Id
	WHERE RPBLE.JobStepInstanceId = @JobStepInstanceId
	AND RPBLE.IsNonAccrualLoan=0

	-- LegalEntity And Invoice 
	UPDATE ReceiptPostByLockBox_Extract
	SET IsInvoiceLegalEntityAssociated =
			CASE
				WHEN (IsValidLegalEntity = 0 AND @DefaultLegalEntityId = RI.LegalEntityId) OR RI.LegalEntityId = LE.Id OR (@AllowInterCompanyTransfer = 1 AND (RPBLE.IsValidLegalEntity = 1 OR @DefaultLegalEntityId IS NOT NULL) 
				AND RPBLE.IsValidInvoice = 1) 
				THEN 1
				ELSE 0
			END
	FROM ReceiptPostByLockBox_Extract RPBLE
	LEFT JOIN ReceivableInvoices RI ON RPBLE.InvoiceNumber = RI.Number AND RI.IsActive = 1
	LEFT JOIN LegalEntities LE ON RPBLE.LegalEntityNumber = LE.LegalEntityNumber
	WHERE RPBLE.JobStepInstanceId = @JobStepInstanceId
	AND RPBLE.IsNonAccrualLoan=0

	-- Invoice and contract 
	INSERT INTO #InvoiceContractExtractInfo
		SELECT RPBLE.Id AS ExtractId, RID.EntityId, RID.EntityType
		FROM ReceiptPostByLockBox_Extract RPBLE
		JOIN ReceivableInvoices RI ON RPBLE.InvoiceNumber = RI.Number AND RI.IsStatementInvoice = 0 AND RI.IsActive = 1
		JOIN ReceivableInvoiceDetails RID ON RI.Id = RID.ReceivableInvoiceId
		WHERE
			RPBLE.JobStepInstanceId = @JobStepInstanceId AND
			RID.EntityType IN (@ReceivableEntityTypeValues_CT, @ReceivableEntityTypeValues_DT)
		GROUP BY RPBLE.Id, RID.EntityId, RID.EntityType


	INSERT INTO #InvoiceContractExtractInfo
	SELECT RPBLE.Id AS ExtractId, RID.EntityId, RID.EntityType
	FROM ReceiptPostByLockBox_Extract RPBLE
	JOIN ReceivableInvoices RI ON RPBLE.InvoiceNumber = RI.Number AND RI.IsStatementInvoice = 1 AND RI.IsActive = 1
	JOIN ReceivableInvoiceStatementAssociations SA ON RI.Id = SA.StatementInvoiceId
	JOIN ReceivableInvoiceDetails RID ON SA.ReceivableInvoiceId = RID.ReceivableInvoiceId
	WHERE
		RPBLE.JobStepInstanceId = @JobStepInstanceId AND
		RID.EntityType IN (@ReceivableEntityTypeValues_CT, @ReceivableEntityTypeValues_DT)
	GROUP BY RPBLE.Id, RID.EntityId, RID.EntityType
	

	;WITH InvoiceDetailContractAssociationInfo AS
	(
		SELECT 
			ICEI.ExtractId, 
			CASE
				WHEN (ICEI.EntityId = C.Id AND ICEI.EntityType = @ReceivableEntityTypeValues_CT)
					OR (ICEI.EntityId = D.Id AND ICEI.EntityType = @ReceivableEntityTypeValues_DT) THEN 1
				ELSE 0
			END AS IsInvoiceDetailContractAssociated
		FROM #InvoiceContractExtractInfo ICEI
		JOIN ReceiptPostByLockBox_Extract RPBLE ON ICEI.ExtractId = RPBLE.Id 
		LEFT JOIN Contracts C ON RPBLE.ContractNumber = C.SequenceNumber
		LEFT JOIN Discountings D ON RPBLE.ContractNumber = D.SequenceNumber
	),
	InvoiceContractAssociationInfo AS
	(
		SELECT 
			IDCAI.ExtractId, 
			CASE 
				WHEN SUM(IDCAI.IsInvoiceDetailContractAssociated) > 0 THEN 1
				ELSE 0
			END AS IsInvoiceContractAssociated
		FROM InvoiceDetailContractAssociationInfo IDCAI
		GROUP BY IDCAI.ExtractId
	)
	UPDATE ReceiptPostByLockBox_Extract
	SET 
		IsInvoiceContractAssociated = 
		CASE
			WHEN ICAI.IsInvoiceContractAssociated IS NULL THEN 0
			ELSE ICAI.IsInvoiceContractAssociated
		END
	FROM ReceiptPostByLockBox_Extract RPBLE
	LEFT JOIN InvoiceContractAssociationInfo ICAI ON RPBLE.Id = ICAI.ExtractId
	WHERE JobStepInstanceId = @JobStepInstanceId
	AND RPBLE.IsNonAccrualLoan=0

	DROP TABLE #InvoiceContractExtractInfo
END

GO
