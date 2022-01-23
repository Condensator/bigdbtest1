SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SPHC_RelatedEntityGLAccounts_Reconciliation]
(
	@ContractId BIGINT,
	@DiscountingId BIGINT
)
AS
BEGIN
	SET NOCOUNT ON
	SET ANSI_WARNINGS OFF
	
	IF OBJECT_ID('tempdb..#EligibleContracts') IS NOT NULL
    DROP TABLE #EligibleContracts;

	IF OBJECT_ID('tempdb..#EligiblePayables') IS NOT NULL
    DROP TABLE #EligiblePayables;
	
	IF OBJECT_ID('tempdb..#EligibleReceivables') IS NOT NULL
    DROP TABLE #EligibleReceivables
	
	IF OBJECT_ID('tempdb..#ContractInfo') IS NOT NULL
    DROP TABLE #ContractInfo

	IF OBJECT_ID('tempdb..#GLDetails') IS NOT NULL
    DROP TABLE #GLDetails;
	
	IF OBJECT_ID('tempdb..#DRContractTemp') IS NOT NULL
    DROP TABLE #DRContractTemp

	IF OBJECT_ID('tempdb..#DRContractDetails') IS NOT NULL
	DROP TABLE #DRContractDetails

	IF OBJECT_ID('tempdb..#DRPaymentDetails') IS NOT NULL
	DROP TABLE #DRPaymentDetails

	IF OBJECT_ID('tempdb..#DRContractRelation') IS NOT NULL
	DROP TABLE #DRContractRelation
	
	IF OBJECT_ID('tempdb..#InvalidDRs') IS NOT NULL
	DROP TABLE #InvalidDRs
	
	IF OBJECT_ID('tempdb..#InvalidGLs') IS NOT NULL
	DROP TABLE #InvalidGLs

	IF OBJECT_ID('tempdb..#InvalidDRGLTransactions') IS NOT NULL
	DROP TABLE #InvalidDRGLTransactions

	IF OBJECT_ID('tempdb..#DRPAmountInfo') IS NOT NULL
	DROP TABLE #DRPAmountInfo

	IF OBJECT_ID('tempdb..#GLValueInfo') IS NOT NULL
	DROP TABLE #GLValueInfo

	IF OBJECT_ID('tempdb..#DRReceivableAmountDetails') IS NOT NULL
	DROP TABLE #DRReceivableAmountDetails
	IF OBJECT_ID('tempdb..#DRRPayableEntryInfo') IS NOT NULL
	DROP TABLE #DRRPayableEntryInfo
	IF OBJECT_ID('tempdb..#DRRTemp') IS NOT NULL
	DROP TABLE #DRRTemp
	IF OBJECT_ID('tempdb..#DRRUpdatePayableEntryInfo') IS NOT NULL
	DROP TABLE #DRRUpdatePayableEntryInfo
	IF OBJECT_ID('tempdb..#DRRReceivableEntryInfo') IS NOT NULL
	DROP TABLE #DRRReceivableEntryInfo
	
	IF OBJECT_ID('tempdb..#ValidGLsForClearing') IS NOT NULL
	DROP TABLE #ValidGLsForClearing

	IF OBJECT_ID('tempdb..#DRPayableAmountDetails') IS NOT NULL
	DROP TABLE #DRPayableAmountDetails

	IF OBJECT_ID('tempdb..#EligibleDiscountings') IS NOT NULL
	DROP TABLE #EligibleDiscountings
	
	IF OBJECT_ID('tempdb..#SuccesfullClearing') IS NOT NULL
	DROP TABLE #SuccesfullClearing

	IF OBJECT_ID('tempdb..#ResultList') IS NOT NULL
    DROP TABLE #ResultList;

	CREATE TABLE #EligiblePayables
	(
		PayableId BIGINT,
		ContractId BIGINT,
		Amount_Amount DECIMAL(16, 2)
	);
	CREATE TABLE #EligibleReceivables
	(
		ReceivableId BIGINT,
		ContractId BIGINT,
		Amount_Amount DECIMAL(16, 2)
	)
	CREATE TABLE #DRContractDetails
	(
		ContractId BIGINT,
		DisbursementRequestId BIGINT,
		ReceiptId BIGINT,
		SundryId BIGINT ,
		Status NVARCHAR(15),
		IsFromReceivables BIT
	)
	
	CREATE TABLE #InvalidDRs
	(
		DisbursementRequestId BIGINT
	)
	CREATE TABLE #InvalidGLs
	(
		GLJournalId BIGINT,
		IsMultipleContractDR BIT
	)
	CREATE TABLE #ValidGLsForClearing
	(
		GLJournalId BIGINT
	)
	CREATE TABLE #InvalidDRGLTransactions
	(
		DisbursementRequestId BIGINT,
		GLTransactionTypeName NVARCHAR(50)
	)
	
	CREATE TABLE #DRContractTemp
	(
		DisbursementRequestId BIGINT,
		ContractId BIGINT
	)

	CREATE TABLE #DRRTemp
	(
		DisbursementRequestId BIGINT,
		DRRAmount DECIMAL(16, 2)
	)
	
	CREATE TABLE  #DRRPayableEntryInfo
	(
		GLJournalId BIGINT,
		GLEntryItemName NVARCHAR(15)
	)
	CREATE TABLE #DRRUpdatePayableEntryInfo
	(
		GLJournalId BIGINT,
		DRRAmount DECIMAL(16, 2),
		GLEntryItemName NVARCHAR(15)
	)
	CREATE TABLE #DRRReceivableEntryInfo 
	(
		GLJournalId BIGINT,
		GLEntryItemName NVARCHAR(15)
	)
	CREATE TABLE #DRPaymentDetails
	(
		DisbursementRequestId BIGINT,
		ContractId BIGINT,
		PaymentType NVARCHAR(15),
		IsRevisedDR BIT,
		SequenceNumber  NVARCHAR(100),
		CustomerName  NVARCHAR(50),
		ReceiptId BIGINT,
		SundryId BIGINT,
		Status NVARCHAR(15),
		IsFromReceivables BIT
	)

	CREATE TABLE #GLDetails
	(

		GLJournalId BIGINT,
		PostDate DATE,
		EntityType NVARCHAR(20),
		EntityId BIGINT,
		ContractType NVARCHAR(20),
		SequenceNumber  NVARCHAR(50),
		ContractId BIGINT,
		CustomerName  NVARCHAR(250),
		GLTransactionType  NVARCHAR(100),
		EntryItem  NVARCHAR(50),
		GLAccountNumber  NVARCHAR(150) ,
		Debit DECIMAL(16, 2),
		Credit DECIMAL(16, 2),
		[Debit/Credit] NVARCHAR(10),
		Currency NVARCHAR(10),
		Description NVARCHAR(250),
		IsManualEntry NVARCHAR(10),
		IsReversalEntry NVARCHAR(10) ,
		MatchingGLTransactionType NVARCHAR(50),
		MatchingEntryItem NVARCHAR(50) ,
		Amount_Amount  DECIMAL(16, 2),
		LegalEntityId  BIGINT,
		LegalEntityName NVARCHAR(100) ,
		GLAccountName NVARCHAR(50) ,
		AccountType NVARCHAR(100) ,
		Classification NVARCHAR(50) ,
		GLUserBooksName NVARCHAR(50) ,
		ExportJobId BIGINT,
		CreatedTime DATETIMEOFFSET,
		Processed NVARCHAR(100)
	)

	SELECT 
		ContractId = c.Id,
		SequenceNumber = C.SequenceNumber,
		LegalEntityId = CASE WHEN lease.Id IS NOT NULL THEN lease.LegalEntityId ELSE loan.LegalEntityId END,
		CustomerId = CASE WHEN lease.Id IS NOT NULL THEN lease.CustomerId ELSE loan.CustomerId END,
		ContractType = c.ContractType
	INTO #ContractInfo
	FROM Contracts c
	LEFT JOIN LeaseFinances lease ON c.Id = lease.ContractId AND lease.IsCurrent = 1
	LEFT JOIN LoanFinances loan ON c.Id = loan.ContractId AND loan.IsCurrent = 1 
	WHERE (lease.Id IS NOT NULL OR loan.Id IS NOT NULL)
	AND C.Id = @ContractId

	SELECT 
		ContractId = cf.ContractId,
		SequenceNumber = cf.SequenceNumber,
		LegalEntityId = cf.LegalEntityId,
		CustomerName = p.PartyName,
		ContractType = cf.ContractType
	INTO #EligibleContracts
	FROM #ContractInfo cf
	INNER JOIN Parties p ON cf.CustomerId = p.Id

	SELECT 
		DiscountingId = discounting.Id,
		SequenceNumber = discounting.SequenceNumber,
		LegalEntityId = df.LegalEntityId,
		ContractType = 'Discounting'
	INTO #EligibleDiscountings
	FROM Discountings discounting
	INNER JOIN DiscountingFinances df ON discounting.Id = df.DiscountingId AND df.IsCurrent = 1
	WHERE discounting.Id = @DiscountingId
	
	INSERT INTO #EligiblePayables 
	SELECT 
	PayableId = t.Id,
	ContractId = disc.DiscountingId,
	Amount_Amount = t.Amount_Amount
	FROM #EligibleDiscountings disc
	JOIN Payables t ON disc.DiscountingId = t.EntityId
	WHERE t.EntityType = 'DT' 

	INSERT INTO #EligiblePayables 
	SELECT 
	PayableId = t.Id,
	ContractId = ec.ContractId,
	Amount_Amount = t.Amount_Amount
	FROM #EligibleContracts ec
	JOIN PayableInvoices pin ON ec.ContractId = pin.ContractId
	JOIN Payables t ON pin.Id = t.EntityId
	WHERE t.EntityType = 'PI' AND pin.ContractId IS NOT NULL

	INSERT INTO #EligiblePayables
	SELECT 
	PayableId = p.Id,
	ContractId = ec.ContractId,
	Amount_Amount = p.Amount_Amount
	FROM #EligibleContracts ec
	--JOIN Receipts r ON ec.ContractId = r.ContractId
	JOIN UnallocatedRefunds ur ON ur.ContractId = ec.ContractId
	JOIN Payables p ON ur.Id = p.EntityId
	WHERE p.EntityType = 'RR'   

	INSERT INTO #EligiblePayables 
	SELECT 
	PayableId = t.Id,
	ContractId = ec.ContractId,
	Amount_Amount = t.Amount_Amount
	FROM #EligibleContracts ec
	JOIN Payables t ON ec.ContractId = t.EntityId
	WHERE t.EntityType = 'CT' 

	INSERT INTO #EligibleReceivables
	SELECT
	Receivable = r.Id,
	ContractId = ec.ContractId,
	Amount_Amount = r.TotalAmount_Amount
	FROM #EligibleContracts ec
	JOIN Receivables r ON ec.ContractId = r.EntityId
	WHERE r.EntityType = 'CT' 

	INSERT INTO #DRContractDetails
	SELECT DISTINCT
		ContractId = ep.ContractId,
		DisbursementRequestId = dr.Id,
		ReceiptId,
		SundryId,
		dr.Status,
		IsFromReceivables = 0
	FROM #EligiblePayables ep
	INNER JOIN DisbursementRequestPayables drp ON ep.PayableId = drp.PayableId
	INNER JOIN DisbursementRequests dr ON drp.DisbursementRequestId = dr.Id
	LEFT JOIN #EligibleContracts ec ON ec.ContractId = ep.ContractId
	LEFT JOIN #EligibleDiscountings discounting ON discounting.DiscountingId = ep.ContractId
	WHERE drp.IsActive=1 AND (ec.ContractId IS NOT NULL OR discounting.DiscountingId IS NOT NULL)

	INSERT INTO #DRContractDetails
	SELECT DISTINCT
		ContractId = er.ContractId,
		DisbursementRequestId = dr.Id,
		ReceiptId,
		SundryId,
		dr.Status,
		IsFromReceivables = 1
	FROM #EligibleReceivables er
	INNER JOIN DisbursementRequestReceivables drr ON er.ReceivableId = drr.ReceivableId
	INNER JOIN DisbursementRequests dr ON drr.DisbursementRequestId = dr.Id
	LEFT JOIN #EligibleContracts ec ON ec.ContractId = er.ContractId
	LEFT JOIN #EligibleDiscountings discounting ON discounting.DiscountingId = er.ContractId
	WHERE drr.IsActive=1 AND (ec.ContractId IS NOT NULL OR discounting.DiscountingId IS NOT NULL)

	INSERT INTO #DRPaymentDetails
	SELECT  DISTINCT
	DisbursementRequestId = dr.DisbursementRequestId,
	ContractId = dr.Contractid,
	PaymentType = CASE 	WHEN dr.ReceiptId IS NOT NULL THEN 'Offset'
						WHEN dr.SundryId IS NOT NULL THEN 'Clearing'
						ELSE 'TruePayment' END ,
	IsRevisedDR = 0,
	SequenceNumber =ec.SequenceNumber ,
	CustomerName = ec.CustomerName,
	dr.ReceiptId,
	dr.SundryId,
	dr.Status,
	IsFromReceivables
	FROM #DRContractDetails dr
	JOIN #EligibleContracts ec ON ec.ContractId = dr.ContractId
	LEFT JOIN DisbursementRequestReceivables drr on dr.DisbursementRequestId =drr.DisbursementRequestId
	
	INSERT INTO #DRPaymentDetails
	SELECT DISTINCT 
	DisbursementRequestId = dr.DisbursementRequestId,
	ContractId = dr.Contractid,
	PaymentType = CASE 	WHEN dr.ReceiptId IS NOT NULL THEN 'Offset'
						WHEN dr.SundryId IS NOT NULL THEN 'Clearing'
						ELSE 'TruePayment' END ,
	IsRevisedDR = 0,
	SequenceNumber =discounting.SequenceNumber ,
	CustomerName = NULL,
	dr.ReceiptId,
	dr.SundryId,
	dr.Status,
	IsFromReceivables
	FROM #DRContractDetails dr
	JOIN #EligibleDiscountings discounting ON discounting.DiscountingId = dr.ContractId
	LEFT JOIN DisbursementRequestReceivables drr on dr.DisbursementRequestId =drr.DisbursementRequestId

	INSERT INTO  #DRContractTemp
	SELECT
		DISTINCT 
		DisbursementRequestId = dc.DisbursementRequestId,
		Contractid = CASE WHEN pi.Id IS NOT NULL THEN pi.Contractid ELSE uc.ContractId END
	FROM #DRPaymentDetails dc 
	JOIN DisbursementRequestPayables drp ON dc.DisbursementRequestId = drp.DisbursementRequestId
	JOIN payables p ON drp.PayableId = p.Id 
	LEFT JOIN PayableInvoices pi ON p.EntityId = pi.Id AND p.EntityType = 'PI'
	LEFT JOIN UnallocatedRefunds uc ON p.EntityId = uc.Id AND p.EntityType = 'RR'
	WHERE pi.Id IS NOT NULL OR uc.Id IS NOT NULL

	INSERT INTO  #DRContractTemp
	SELECT
		DISTINCT 
		DisbursementRequestId = dc.DisbursementRequestId,
		Contractid = p.EntityId
	FROM #DRPaymentDetails dc 
	JOIN DisbursementRequestPayables drp ON dc.DisbursementRequestId = drp.DisbursementRequestId
	JOIN payables p ON drp.PayableId = p.Id AND (p.EntityType = 'CT' OR p.EntityType = 'DT')
	
	SELECT 
	DisbursementRequestId = dct.DisbursementRequestId , 
	CountOfContract = COUNT(dct.ContractId)
	INTO #DRContractRelation
	FROM #DRContractTemp dct
	GROUP BY dct.DisbursementRequestId

	SELECT
	DisbursementRequestId = drc.DisbursementRequestId ,
	DRPAmount = Sum(drp.AmountToPay_Amount),
	GlTransactionTypeName = glt.Name
	INTO #DRPAmountInfo
	FROM #DRContractRelation drc
	JOIN DisbursementRequestPayables drp ON drc.DisbursementRequestId = drp.DisbursementRequestId AND drc.CountOfContract = 1
	JOIN Payables p ON drp.PayableId = p.Id
	JOIN PayableCodes pc ON p.PayableCodeId = pc.Id
	JOIN PayableTypes pt ON pc.PayableTypeId = pt.Id
	JOIN GLTransactionTypes glt ON pt.GLTransactionTypeId = glt.Id
	GROUP BY drc.DisbursementRequestId,glt.Name

	IF EXISTS ( SELECT DisbursementRequestId FROM #DRPaymentDetails WHERE PaymentType ='Offset' )
	BEGIN
	SELECT 
		DisbursementRequestId = dr.DisbursementRequestId,
		TotalAmountToPay = SUM(drr.AmountToApply_Amount)
	INTO #DRReceivableAmountDetails
	FROM #DRPaymentDetails dr
	JOIN DisbursementRequestReceivables drr ON drr.DisbursementRequestId = dr.DisbursementRequestId AND dr.IsFromReceivables = 0
	WHERE drr.IsActive = 1 AND dr.PaymentType = 'Offset'
	GROUP BY dr.DisbursementRequestId

	INSERT INTO #InvalidGLs
	SELECT gld.GLJournalId , IsMultipleContractDR = 0 
	FROM  GLJournalDetails gld
			 JOIN GLTemplateDetails ON gld.GLTemplateDetailId = GLTemplateDetails.Id
			 JOIN GLEntryItems ON GLTemplateDetails.EntryItemId = GLEntryItems.Id AND GLEntryItems.Name = 'Payable'
			JOIN (
					SELECT DISTINCT rgl.GLJournalId,d.TotalAmountToPay 
					FROM #DRPaymentDetails dr 
					JOIN #DRContractRelation drc ON drc.DisbursementRequestId = dr.DisbursementRequestId  AND PaymentType ='Offset' AND drc.CountOfContract = 1
					JOIN #DRReceivableAmountDetails d ON d.DisbursementRequestId = dr.DisbursementRequestId
					JOIN ReceiptGLJournals rgl ON dr.ReceiptId = rgl.ReceiptId
				 ) AS t ON t.GLJournalId = gld.GLJournalId 
			WHERE gld.Amount_Amount != t.TotalAmountToPay
		
		INSERT INTO #InvalidGLs
		SELECT rgl.GLJournalId, IsMultipleContractDR = 1
		FROM #DRPaymentDetails dr 
		JOIN #DRContractRelation drc ON drc.DisbursementRequestId = dr.DisbursementRequestId  AND PaymentType ='Offset' AND drc.CountOfContract > 1
		JOIN #DRReceivableAmountDetails d ON d.DisbursementRequestId = dr.DisbursementRequestId
		JOIN ReceiptGLJournals rgl ON dr.ReceiptId = rgl.ReceiptId
		

		IF EXISTS (SELECT DisbursementRequestId FROM #DRContractRelation drc WHERE drc.CountOfContract = 1)
		BEGIN
		INSERT INTO #DRRPayableEntryInfo
		SELECT gld.GLJournalId , GLEntryItemName = GLEntryItems.Name
			FROM #DRPaymentDetails dr 
			JOIN #DRContractRelation drc ON drc.DisbursementRequestId = dr.DisbursementRequestId  AND PaymentType ='Offset' AND drc.CountOfContract = 1
			JOIN ReceiptGLJournals rg ON dr.ReceiptId = rg.ReceiptId 
			JOIN GLJournalDetails gld ON rg.GLJournalId = gld.GLJournalId
			JOIN GLTemplateDetails ON gld.GLTemplateDetailId = GLTemplateDetails.Id
			JOIN GLEntryItems ON GLTemplateDetails.EntryItemId = GLEntryItems.Id AND GLEntryItems.Name = 'Payable'
			WHERE dr.IsFromReceivables = 0

			INSERT INTO #DRRTemp
			SELECT 
			DisbursementRequestId =  dr.id,
			DRRAmount = Sum(drr.AmountToApply_Amount)
			FROM #EligibleContracts ec 
			JOIN Receivables r ON r.EntityId =  ec.ContractId AND (r.EntityType = 'CT') 
			JOIN DisbursementRequestReceivables drr ON drr.ReceivableId = r.Id
			JOIN DisbursementRequests dr ON drr.DisbursementRequestId = dr.Id
			GROUP BY dr.Id,ec.ContractId 

			INSERT INTO #DRRTemp
			SELECT 
			DisbursementRequestId =  dr.id,
			DRRAmount = Sum(drr.AmountToApply_Amount)
			FROM #EligibleDiscountings discounting 
			JOIN Receivables r ON r.EntityId =  discounting.DiscountingId AND (r.EntityType = 'DT') 
			JOIN DisbursementRequestReceivables drr ON drr.ReceivableId = r.Id
			JOIN DisbursementRequests dr ON drr.DisbursementRequestId = dr.Id
			GROUP BY dr.Id
			
			INSERT INTO #DRRUpdatePayableEntryInfo 
			SELECT
			gld.GLJournalId,
			DRRAmount,
			GLEntryItemName = GLEntryItems.Name
			FROM #DRRTemp drr
			JOIN DisbursementRequests dr ON drr.DisbursementRequestId = dr.Id
			JOIN ReceiptGLJournals rg ON dr.ReceiptId = rg.ReceiptId
			JOIN GLJournalDetails gld ON rg.GLJournalId = gld.GLJournalId
			JOIN GLTemplateDetails ON gld.GLTemplateDetailId = GLTemplateDetails.Id
			JOIN GLEntryItems ON GLTemplateDetails.EntryItemId = GLEntryItems.Id AND GLEntryItems.Name = 'Payable'
			WHERE gld.GLJournalId NOT IN (Select GLJournalId from #DRRPayableEntryInfo WHERE #DRRPayableEntryInfo.GLEntryItemName = 'Payable')

			INSERT INTO #DRRReceivableEntryInfo
			SELECT
			gld.GLJournalId,
			GLEntryItemName = GLEntryItems.Name
			FROM #DRPaymentDetails dr 
			JOIN #DRContractRelation drc ON drc.DisbursementRequestId = dr.DisbursementRequestId  AND PaymentType ='Offset' AND drc.CountOfContract = 1
			JOIN ReceiptGLJournals rg ON dr.ReceiptId = rg.ReceiptId 
			JOIN GLJournalDetails gld ON rg.GLJournalId = gld.GLJournalId AND gld.EntityId != (dr.ContractId) AND gld.EntityType = 'Cntract'
		    JOIN GLTemplateDetails ON gld.GLTemplateDetailId = GLTemplateDetails.Id
			JOIN GLEntryItems ON GLTemplateDetails.EntryItemId = GLEntryItems.Id AND GLEntryItems.Name = 'Receivable'
			WHERE dr.IsFromReceivables = 0

		END
	END

	IF EXISTS ( SELECT DisbursementRequestId FROM #DRPaymentDetails WHERE PaymentType ='Clearing' )
	BEGIN
		SELECT 
		DisbursementRequestId = dr.DisbursementRequestId,
		TotalAmountToPay = SUM(drp.AmountToPay_Amount)
		INTO #DRPayableAmountDetails
		FROM #DRPaymentDetails dr
		JOIN #DRContractRelation drc ON drc.DisbursementRequestId = dr.DisbursementRequestId AND PaymentType ='Clearing' AND drc.CountOfContract = 1 AND dr.IsFromReceivables = 0
		JOIN DisbursementRequestPayables drp ON drp.DisbursementRequestId = dr.DisbursementRequestId
		WHERE drp.IsActive = 1
		GROUP BY dr.DisbursementRequestId 

		SELECT 
		DisbursementRequestId = t.DisbursementRequestId,
		IsSuccessfulClearing = CASE WHEN gld.GLJournalId IS NOT NULL THEN 0 ELSE 1 END,
		t.TotalAmountToPay,gld.Amount_Amount
		INTO #SuccesfullClearing 
		FROM  GLJournalDetails gld 
			 JOIN GLTemplateDetails ON gld.GLTemplateDetailId = GLTemplateDetails.Id
			 JOIN GLEntryItems ON GLTemplateDetails.EntryItemId = GLEntryItems.Id AND GLEntryItems.Name = 'Clearing'
			 JOIN (
					SELECT DISTINCT rg.GLJournalId,d.DisbursementRequestId,d.TotalAmountToPay 
					FROM #DRPaymentDetails dr
					JOIN #DRPayableAmountDetails d ON d.DisbursementRequestId = dr.DisbursementRequestId
					JOIN Receivables r ON dr.SundryId = r.SourceId AND r.SourceTable = 'Sundry'
					JOIN ReceivableGLJournals rg ON r.Id = rg.ReceivableId
				 ) AS t ON t.GLJournalId = gld.GLJournalId 
			WHERE gld.Amount_Amount != ABS(t.TotalAmountToPay)

		INSERT INTO #InvalidGLs
		SELECT DISTINCT
			gld.GLJournalId , 
			IsMultipleContractDR = CASE WHEN drc.DisbursementRequestId IS NOT NULL THEN 1 ELSE 0 END
		FROM #DRPaymentDetails ed
		LEFT JOIN #DRContractRelation drc ON drc.DisbursementRequestId = ed.DisbursementRequestId AND PaymentType ='Clearing' AND drc.CountOfContract > 1
		LEFT JOIN #SuccesfullClearing t ON ed.DisbursementRequestId = t.DisbursementRequestId AND t.IsSuccessfulClearing = 0
		JOIN GLJournalDetails gld ON ed.DisbursementRequestId = gld.EntityId AND gld.EntityType = 'DisbursementRequest' 
		JOIN GLTemplateDetails ON gld.GLTemplateDetailId = GLTemplateDetails.Id
		JOIN GLEntryItems ON GLTemplateDetails.EntryItemId = GLEntryItems.Id
		JOIN GLTransactionTypes ON GLEntryItems.GLTransactionTypeId = GLTransactionTypes.Id AND GLTransactionTypes.Name = 'AccountsPayable'
		WHERE drc.DisbursementRequestId IS NOT NULL OR t.DisbursementRequestId IS NOT NULL

		INSERT INTO #InvalidGLs
		SELECT DISTINCT rg.GLJournalId, IsMultipleContractDR = CASE WHEN drc.DisbursementRequestId IS NOT NULL THEN 1 ELSE 0 END
		FROM #DRPaymentDetails ed
		LEFT JOIN #DRContractRelation drc ON drc.DisbursementRequestId = ed.DisbursementRequestId AND PaymentType ='Clearing' AND drc.CountOfContract > 1
		LEFT JOIN #SuccesfullClearing t ON ed.DisbursementRequestId = t.DisbursementRequestId AND t.IsSuccessfulClearing = 0
		JOIN Receivables r ON ed.SundryId = r.SourceId AND r.SourceTable = 'Sundry'
		JOIN ReceivableGLJournals rg ON r.Id = rg.ReceivableId
		WHERE drc.DisbursementRequestId IS NOT NULL OR t.DisbursementRequestId IS NOT NULL

		INSERT INTO #ValidGLsForClearing
		SELECT gld.GLJournalId 
		FROM #DRPaymentDetails ed
		JOIN #DRContractRelation drc ON drc.DisbursementRequestId = ed.DisbursementRequestId AND PaymentType ='Clearing' AND drc.CountOfContract = 1
		JOIN GLJournalDetails gld ON ed.DisbursementRequestId = gld.EntityId AND gld.EntityType = 'DisbursementRequest' 
		JOIN GLTemplateDetails ON gld.GLTemplateDetailId = GLTemplateDetails.Id
		JOIN GLEntryItems ON GLTemplateDetails.EntryItemId = GLEntryItems.Id
		JOIN GLTransactionTypes ON GLEntryItems.GLTransactionTypeId = GLTransactionTypes.Id AND GLTransactionTypes.Name = 'AccountsPayable'

		INSERT INTO #ValidGLsForClearing
		SELECT rg.GLJournalId
		FROM #DRPaymentDetails ed
		JOIN #DRContractRelation drc ON drc.DisbursementRequestId = ed.DisbursementRequestId AND PaymentType ='Clearing' AND drc.CountOfContract = 1
		JOIN Receivables r ON ed.SundryId = r.SourceId AND r.SourceTable = 'Sundry'
		JOIN ReceivableGLJournals rg ON r.Id = rg.ReceivableId

	END
	--------------

	INSERT INTO #GLDetails
	SELECT DISTINCT
		GLJournalId = gld.GLJournalId,
		PostDate = gl.PostDate,
		EntityType = gld.EntityType,
		EntityId = gld.EntityId,
		SequenceNumber = NULL,
		ContractId = NULL,
		ContractType = NULL,
		CustomerName = NULL,
		GLTransactionType = GLTransactionTypes.Name,
		EntryItem = GLEntryItems.Name,
		GLAccountNumber = gld.GLAccountNumber,
		Debit = CASE WHEN gld.IsDebit = 1 THEN gld.Amount_Amount ELSE 0 END,
		Credit = CASE WHEN gld.IsDebit = 0 THEN gld.Amount_Amount ELSE 0 END,
		[Debit/Credit] = CASE WHEN gld.IsDebit = 1 THEN 'Debit' ELSE 'Credit' End,
		Currency  = gld.Amount_Currency,
		Description = gld.Description,
		IsManualEntry = CASE WHEN gl.IsManualEntry = 1 THEN 'YES' ELSE 'NO' END,
		IsReversalEntry =CASE WHEN gl.IsReversalEntry = 1 THEN 'YES' ELSE 'NO' END ,
		MatchingGLTransactionType = M2.Name,
		MatchingEntryItem = M1.Name,
		Amount_Amount = gld.Amount_Amount,
		LegalEntityId= LegalEntities.Id,
		LegalEntityName = LegalEntities.Name,
		GLAccountName = GLAccounts.Name ,
		AccountType = GLAccountTypes.AccountType,
		Classification = GLAccountTypes.Classification,
		GLUserBooksName = GLUserBooks.Name,
		ExportJobId = gld.ExportJobId,
		CreatedTime = gld.CreatedTime,
		Processed = 'Successful'
	FROM GLJournalDetails gld
	JOIN GLJournals gl ON gl.Id = gld.GLJournalId AND gld.IsActive = 1
	JOIN GLAccounts ON gld.GLAccountId = GLAccounts.Id
	JOIN LegalEntities ON gl.LegalEntityId = LegalEntities.Id
	JOIN GLAccountTypes ON GLAccounts.GLAccountTypeId = GLAccountTypes.Id
	LEFT JOIN GLTemplateDetails ON gld.GLTemplateDetailId = GLTemplateDetails.Id
	LEFT JOIN GLUserBooks ON GLAccounts.GLUserBookId = GLUserBooks.Id
	LEFT JOIN GLEntryItems ON GLTemplateDetails.EntryItemId = GLEntryItems.Id
	LEFT JOIN GLTransactionTypes ON GLEntryItems.GLTransactionTypeId = GLTransactionTypes.Id
	LEFT JOIN GLTemplateDetails M ON gld.MatchingGLTemplateDetailId = M.Id
	LEFT JOIN GLEntryItems M1 ON M.EntryItemId = M1.Id
	LEFT JOIN GLTransactionTypes M2 ON M1.GLTransactionTypeId = M2.Id
	LEFT JOIN #EligibleContracts ec ON ec.ContractId = gld.EntityId AND gld.EntityType = 'Contract'
	LEFT JOIN #DRPaymentDetails ed ON ed.DisbursementRequestId = gld.EntityId AND gld.EntityType = 'DisbursementRequest' AND ed.IsFromReceivables = 0
	LEFT JOIN #InvalidGLs ig ON ig.GLJournalId = gld.GLJournalId
	LEFT JOIN #DRRPayableEntryInfo t ON t.GLJournalId = gld.GLJournalId AND GLEntryItems.Name = 'Payable'
	LEFT JOIN #DRRUpdatePayableEntryInfo t2 ON t2.GLJournalId = gld.GLJournalId AND GLEntryItems.Name = 'Payable'
	LEFT JOIN #DRRReceivableEntryInfo t3 ON t3.GLJournalId = gld.GLJournalId AND GLEntryItems.Name = 'Receivable'
	LEFT JOIN #ValidGLsForClearing vc ON vc.GLJournalId = gld.GLJournalId
	LEFT JOIN #EligibleDiscountings discounting ON discounting.DiscountingId = gld.EntityId AND gld.EntityType = 'Discounting'
	WHERE (ec.ContractId IS NOT NULL OR ed.DisbursementRequestId IS NOT NULL
	 OR ig.GLJournalId IS NOT NULL OR t.GLJournalId IS NOT NULL OR t2.GLJournalId IS NOT NULL OR t3.GLJournalId IS NOT NULL OR vc.GLJournalId IS NOT NULL
		   OR discounting.DiscountingId IS NOT NULL
		   )

	SELECT
	DisbursementRequestId = glInfo.EntityId,
	GLTransactionType = glInfo.GLTransactionType,
	GLValue = SUM(glInfo.Credit) - SUM(glInfo.Debit)
	INTO #GLValueInfo
	FROM #GLDetails glInfo
	INNER JOIN #DRPaymentDetails ed ON glInfo.ContractId = ed.ContractId AND ed.DisbursementRequestId = glinfo.EntityId AND glInfo.EntityType = 'DisbursementRequest'
	AND ed.PaymentType = 'TruePayment'
	WHERE glInfo.GLTransactionType IN  ( 'AssetPurchaseAP','MiscellaneousAccountsPayable','PayableCash','DiscountingPrincipalPayable','DiscountingInterestPayable','Disbursement','DueToInvestorAP')
	AND glInfo.EntryItem IN ('AssetPurchasePayable','DuetoInterCompanyPayable','MiscellaneousPayable' ,'PrepaidMiscellaneousPayable','PrePaidDuetoInterCompanyPayable','BlendedExpensePayable','CashPayable','DiscountingPayablePrincipal','DiscountingPayableInterest','DisbursementPayable','RentDueToInvestorAP') 
	GROUP BY glInfo.EntityId,glInfo.GLTransactionType

	INSERT INTO #InvalidDRs
	SELECT
	DisbursementRequestId = drc.DisbursementRequestId
	FROM #GLDetails glInfo
	INNER JOIN #DRPaymentDetails ed ON glInfo.ContractId = ed.ContractId AND ed.DisbursementRequestId = glinfo.EntityId AND glInfo.EntityType = 'DisbursementRequest' AND ed.PaymentType = 'TruePayment'
	INNER JOIN #DRContractRelation drc ON drc.DisbursementRequestId = ed.DisbursementRequestId AND drc.CountOfContract >1

	INSERT INTO #InvalidDRGLTransactions
	SELECT
	DisbursementRequestId = #GLValueInfo.DisbursementRequestId,
	GLTransactionTypeName = #GLValueInfo.GLTransactionType
	FROM #DRPaymentDetails ed 
	INNER JOIN  #GLValueInfo ON ed.DisbursementRequestId = #GLValueInfo.DisbursementRequestId AND ed.Status NOT IN ('Pending' , 'Inactive') AND ed.PaymentType = 'TruePayment'
	INNER JOIN #DRContractRelation drc ON drc.DisbursementRequestId = ed.DisbursementRequestId AND drc.CountOfContract =1
	INNER JOIN #DRPAmountInfo drp ON #GLValueInfo.DisbursementRequestId = drp.DisbursementRequestId AND #GLValueInfo.GLTransactionType = drp.GlTransactionTypeName AND drp.DRPAmount != #GLValueInfo.GLValue

	INSERT INTO #InvalidDRGLTransactions
	SELECT
	DisbursementRequestId = #GLValueInfo.DisbursementRequestId,
	GLTransactionTypeName = #GLValueInfo.GLTransactionType
	FROM #DRPaymentDetails ed 
	INNER JOIN  #GLValueInfo ON ed.DisbursementRequestId = #GLValueInfo.DisbursementRequestId AND ed.Status IN ('Pending' , 'Inactive') AND ed.PaymentType = 'TruePayment'
	INNER JOIN #DRContractRelation drc ON drc.DisbursementRequestId = ed.DisbursementRequestId AND drc.CountOfContract =1
	WHERE #GLValueInfo.GLValue != 0

	IF EXISTS ( SELECT DisbursementRequestId FROM #InvalidDRs )
	BEGIN
	UPDATE #GLDetails
	SET Processed = 'Disbursement Request could not be processed. Payable of Multiple contracts associated'
	FROM #GLDetails glinfo
	JOIN #InvalidDRs dr ON  dr.DisbursementRequestId = glinfo.EntityId AND glInfo.EntityType = 'DisbursementRequest'
	END

	IF EXISTS ( SELECT DisbursementRequestId FROM #InvalidDRGLTransactions )
	BEGIN
	UPDATE #GLDetails
	SET Processed = 'Unsuccessful'
	FROM #GLDetails glinfo
	JOIN #InvalidDRGLTransactions dr ON  dr.DisbursementRequestId = glinfo.EntityId AND glInfo.EntityType = 'DisbursementRequest'
	AND glinfo.GLTransactionType = dr.GLTransactionTypeName
	END

	IF EXISTS ( SELECT GLJournalId FROM #InvalidGLs )
	BEGIN
	UPDATE #GLDetails
	SET Processed = CASE WHEN ig.IsMultipleContractDR = 1 THEN 'Disbursement Request could not be processed. Payable of Multiple contracts associated'  ELSE 'Unsuccessful' END 
	FROM #GLDetails glinfo
	JOIN #InvalidGLs ig ON glinfo.GLJournalId = ig.GLJournalId
	END

	IF EXISTS ( SELECT DisbursementRequestId FROM #DRContractRelation WHERE CountOfContract >1 )
	BEGIN
	UPDATE #GLDetails
	SET Processed =  'Disbursement Request could not be processed. Payable of Multiple contracts associated' 
	FROM #GLDetails glinfo
	JOIN #DRContractRelation dr ON glinfo.EntityId = dr.DisbursementRequestId  AND dr.CountOfContract>1
	END

	IF EXISTS ( SELECT GLJournalId FROM #DRRUpdatePayableEntryInfo )
	BEGIN
	UPDATE #GLDetails
	SET Amount_Amount = ig.DRRAmount
	FROM #GLDetails glinfo
	JOIN #DRRUpdatePayableEntryInfo ig ON glinfo.GLJournalId = ig.GLJournalId AND glinfo.EntryItem = 'Payable'
		
	UPDATE #GLDetails
	SET 
	Debit = CASE WHEN [Debit/Credit] = 'Debit' THEN Amount_Amount ELSE Debit END,
	Credit = CASE WHEN [Debit/Credit] = 'Credit' THEN Amount_Amount ELSE Credit END
	FROM #GLDetails glinfo
	JOIN #DRRUpdatePayableEntryInfo ig ON glinfo.GLJournalId = ig.GLJournalId AND glinfo.EntryItem = 'Payable'
	END

	UPDATE #GLDetails
	SET SequenceNumber = ec.SequenceNumber,
	ContractId = ec.ContractId,
	CustomerName = ec.CustomerName
	FROM #EligibleContracts ec
	where #GLDetails.SequenceNumber IS NULL AND #GLDetails.ContractId IS NULL AND #GLDetails.CustomerName IS NULL

	UPDATE #GLDetails
	SET SequenceNumber = discounting.SequenceNumber,
	ContractId = discounting.DiscountingId
	FROM #EligibleDiscountings discounting
	where #GLDetails.SequenceNumber IS NULL AND #GLDetails.ContractId IS NULL

	IF EXISTS(select ContractId from #GLDetails WHERE EntityType = 'Contract') 
	BEGIN
	UPDATE #GLDetails SET ContractType =  ec.ContractType,
	SequenceNumber = ec.SequenceNumber,
	CustomerName = ec.CustomerName,
	ContractId = ec.ContractId
	FROM #EligibleContracts ec
	END

	IF EXISTS(select ContractId from #GLDetails WHERE EntityType = 'Discounting') 
	BEGIN
	UPDATE #GLDetails SET ContractType =  ed.ContractType,
	SequenceNumber = ed.SequenceNumber,
	ContractId = ed.DiscountingId
	FROM #EligibleDiscountings ed	
	END
	
	SELECT 
	 ContractType
	,ContractId
	,SequenceNumber
	,CustomerName
	,LegalEntityId
	,LegalEntityName
	,GLJournalId
	,PostDate
	,EntityType
	,EntityId
	,GLTransactionType
	,EntryItem
	,GLAccountNumber
	,Debit
	,Credit
	,Currency
	,Description
	,IsManualEntry
	,IsReversalEntry
	,MatchingGLTransactionType
	,MatchingEntryItem
	,Amount_Amount
	,GLAccountName
	,AccountType
	,Classification
	,GLUserBooksName
	,ExportJobId
	,CreatedTime
	,Processed
	INTO #ResultList
	FROM #GLDetails glInfo

	SELECT * FROM #ResultList ORDER BY ContractId,GLJournalId 

	--------------
	DROP TABLE #EligibleContracts;
	DROP TABLE #EligiblePayables;
	DROP TABLE #GLDetails;
	DROP TABLE #DRContractTemp
	DROP TABLE #DRContractDetails
	DROP TABLE #DRPaymentDetails
	DROP TABLE #DRPAmountInfo
	DROP TABLE #GLValueInfo
	DROP TABLE #ResultList;
	DROP TABLE #DRContractRelation
	DROP TABLE #DRRTemp
	DROP TABLE #EligibleDiscountings
	DROP TABLE #ContractInfo
	DROP TABLE #EligibleReceivables
	IF OBJECT_ID('tempdb..#InvalidDRs') IS NOT NULL
	BEGIN
	DROP TABLE #InvalidDRs
	END
	IF OBJECT_ID('tempdb..#InvalidDRGLTransactions') IS NOT NULL
	BEGIN
	DROP TABLE #InvalidDRGLTransactions
	END
	IF OBJECT_ID('tempdb..#DRReceivableAmountDetails') IS NOT NULL
	BEGIN
	DROP TABLE #DRReceivableAmountDetails
	END
	IF OBJECT_ID('tempdb..#DRPayableAmountDetails') IS NOT NULL
	BEGIN
	DROP TABLE #DRPayableAmountDetails
	END
	IF OBJECT_ID('tempdb..#SuccesfullClearing') IS NOT NULL
	BEGIN
	DROP TABLE #SuccesfullClearing
	END
	IF OBJECT_ID('tempdb..#ValidGLsForClearing') IS NOT NULL
	BEGIN
	DROP TABLE #ValidGLsForClearing
	END
	IF OBJECT_ID('tempdb..#InvalidGLs') IS NOT NULL
	BEGIN
	DROP TABLE #InvalidGLs
	END
	IF OBJECT_ID('tempdb..#DRRPayableEntryInfo') IS NOT NULL
	BEGIN
	DROP TABLE #DRRPayableEntryInfo
	END
	IF OBJECT_ID('tempdb..#DRRUpdatePayableEntryInfo') IS NOT NULL
	BEGIN
	DROP TABLE #DRRUpdatePayableEntryInfo
	END
	IF OBJECT_ID('tempdb..#DRRReceivableEntryInfo') IS NOT NULL
	BEGIN
	DROP TABLE #DRRReceivableEntryInfo
	END
	---------------
	
	SET NOCOUNT OFF
	SET ANSI_WARNINGS ON 
END

GO
