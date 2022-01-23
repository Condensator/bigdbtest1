SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROC [dbo].[PopulateReceiptLockBoxOtherDataForRHT]
(
	@JobStepInstanceId								BIGINT,
	@ReceiptEntityTypeValues_Loan					NVARCHAR(10),
	@ReceiptEntityTypeValues_Customer				NVARCHAR(30),
	@ReceiptEntityTypeValues_UnKnown				NVARCHAR(30),
	@ReceiptClassificationValues_NonAccrualNonDSL	NVARCHAR(20),
	@ReceivableTypeValues_LoanInterest				NVARCHAR(20),
	@ReceivableTypeValues_LoanPrincipal				NVARCHAR(20),
	@LoanStatusValues_Cancelled						NVARCHAR(20),
	@ReceivableEntityTypeValues_CT					NVARCHAR(2)
)
AS
BEGIN

	SET NOCOUNT ON;

	CREATE TABLE #InvoiceDetails
	(
	 Id                              BIGINT,
	 EntityId                        BIGINT,
	 EntityType                      NVARCHAR(4),
	 ReceivableInvoiceDetailId       BIGINT,
	 ReceivableAmount                DECIMAL(16,2)
	 )

	---- Is Full Posting

	DECLARE @AtleastOneStatementInvoiceExists BIT

	SELECT TOP 1 @AtleastOneStatementInvoiceExists = IsStatementInvoice FROM ReceiptPostByLockBox_Extract WHERE JobStepInstanceId = @JobStepInstanceId AND IsStatementInvoice = 1

	INSERT INTO #InvoiceDetails
		SELECT 
			RI.Id
			,RID.EntityId
			,RID.EntityType
			,RID.Id ReceivableInvoiceDetailId
			,RID.EffectiveBalance_Amount + RID.EffectiveTaxBalance_Amount AS ReceivableAmount
		FROM ReceiptPostByLockBox_Extract RPBL 
		INNER JOIN ReceivableInvoices RI ON RPBL.ReceivableInvoiceId = RI.Id AND RPBL.IsStatementInvoice = 0
		INNER JOIN ReceivableInvoiceDetails RID
		ON RI.Id = RID.ReceivableInvoiceId 
		AND RPBL.JobStepInstanceId = @JobStepInstanceId
		GROUP BY 
			RI.Id, RID.EntityId, RID.EntityType, RID.EffectiveBalance_Amount, RID.EffectiveTaxBalance_Amount, RID.IsActive ,RID.Id
		HAVING RID.IsActive=1
	
	 IF (@AtleastOneStatementInvoiceExists = 1)
	 BEGIN
     INSERT INTO #InvoiceDetails
		SELECT SA.StatementInvoiceId AS Id
			,RID.EntityId 
			,RID.EntityType 
			,RID.Id ReceivableInvoiceDetailId
			,RID.EffectiveBalance_Amount + RID.EffectiveTaxBalance_Amount AS ReceivableAmount
		FROM ReceiptPostByLockBox_Extract RPBL 
		JOIN ReceivableInvoiceStatementAssociations SA ON RPBL.ReceivableInvoiceId = SA.StatementInvoiceId
		JOIN ReceivableInvoiceDetails RID ON SA.ReceivableInvoiceId = RID.ReceivableInvoiceId AND RPBL.JobStepInstanceId = @JobStepInstanceId
		GROUP BY 
			SA.StatementInvoiceId, RID.EntityId, RID.EntityType, RID.EffectiveBalance_Amount, RID.EffectiveTaxBalance_Amount, RID.IsActive ,RID.Id
		HAVING RID.IsActive=1
     END
	
	SELECT 
		Id AS ReceivableInvoiceId, EntityId, EntityType, SUM(ReceivableAmount) AS TotalBalance
	INTO #InvoiceDetailsTable
	FROM #InvoiceDetails INV 
	GROUP BY 
		Id, EntityId, EntityType;
	;

	UPDATE ReceiptPostByLockBox_Extract
		SET IsFullPosting = 1
	WHERE ReceivableInvoiceId IS NULL
	AND IsValid = 1
	AND JobStepInstanceId = @JobStepInstanceId
	;

	UPDATE RPBL  
		SET RPBL.IsFullPosting =
			CASE
				WHEN RPBL.ReceivedAmount - TotalBalance >= 0 THEN 1
				ELSE 0
			END
	FROM ReceiptPostByLockBox_Extract RPBL
	INNER JOIN 
		( 
			SELECT 
				INV.ReceivableInvoiceId, 
				SUM(TotalBalance) AS TotalBalance
			FROM #InvoiceDetailsTable INV
			GROUP BY INV.ReceivableInvoiceId ) AS INV
	ON RPBL.ReceivableInvoiceId = INV.ReceivableInvoiceId
	WHERE (RPBL.EntityType= @ReceiptEntityTypeValues_Customer OR RPBL.EntityType= @ReceiptEntityTypeValues_UnKnown) 
		AND RPBL.IsValid = 1  AND RPBL.JobStepInstanceId = @JobStepInstanceId

	--For Contract Based Records set ComputedIsFullPosting

	UPDATE RPBL 
		SET RPBL.IsFullPosting =
			CASE
				WHEN RPBL.ReceivedAmount - TotalBalance >= 0 THEN 1
				ELSE 0
			END
	FROM ReceiptPostByLockBox_Extract RPBL 
	INNER JOIN #InvoiceDetailsTable INV 
	ON RPBL.ReceivableInvoiceId = INV.ReceivableInvoiceId AND RPBL.ContractId = INV.EntityId
	WHERE RPBL.EntityType != @ReceiptEntityTypeValues_Customer AND RPBL.EntityType != @ReceiptEntityTypeValues_UnKnown 
		AND RPBL.JobStepInstanceId = @JobStepInstanceId AND RPBL.IsValid = 1 
	;

	-- HasMoreInvoice

	WITH CTE_HasMoreInvoice AS
	(
		SELECT 
			ReceivableInvoiceId 
		FROM ReceiptPostByLockBox_Extract
		WHERE ReceivableInvoiceId IS NOT NULL
		AND JobStepInstanceId = @JobStepInstanceId
		GROUP BY ReceivableInvoiceId
		HAVING COUNT(Id) > 1
	)
	UPDATE RPBL
		SET HasMoreInvoice = CASE WHEN HM.ReceivableInvoiceId IS NULL THEN 0 ELSE 1 END
	FROM ReceiptPostByLockBox_Extract RPBL
	LEFT JOIN CTE_HasMoreInvoice HM ON RPBL.ReceivableInvoiceId = HM.ReceivableInvoiceId
	WHERE RPBL.JobStepInstanceId = @JobStepInstanceId
	;

	IF (@AtleastOneStatementInvoiceExists = 1)
	BEGIN
	UPDATE RPBL
              SET HasMoreInvoice = 1, IsFullPosting = 0
       FROM ReceiptPostByLockBox_Extract RPBL
       WHERE RPBL.JobStepInstanceId = @JobStepInstanceId
	END 

	DROP TABLE #InvoiceDetails
END

GO
