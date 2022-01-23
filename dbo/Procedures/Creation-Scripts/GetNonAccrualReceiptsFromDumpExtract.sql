SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROC [dbo].[GetNonAccrualReceiptsFromDumpExtract]
(
	@JobStepInstanceId						BIGINT
)
AS
BEGIN

	SET NOCOUNT ON;

	SELECT 
	RPBL.LockBoxReceiptId,
	PrevLockBoxReceiptId = null,
	ReceivedAmount = RPBL.ReceivedAmount,
	IsContractBasedNonAccrual= 
	CASE
		WHEN RPBL.ContractId IS NOT NULL AND RPBL.ContractNumber IS NOT NULL THEN RPBL.ContractId
		ELSE NULL
	END,
	RPBL.ReceivableInvoiceId AS InvoiceId,
	RI.LegalEntityId AS InvoiceLegalEntityId,
	IsPayDownNonRental = 0,
	RPBL.PayDownId
	INTO #ReceiptsExtract
	FROM ReceiptPostByLockBox_Extract RPBL 
	INNER JOIN ReceivableInvoices RI ON RPBL.ReceivableInvoiceId=RI.Id
	WHERE RPBL.JobStepInstanceId = @JobStepInstanceId
	AND RPBL.IsNonAccrualLoan=1 AND RPBL.IsValid = 1
	AND RPBL.ReceiptClassification='NonAccrualNonDSL'
	AND RPBL.CreateUnallocatedReceipt=0
	
	;WITH InvoiceIds AS(
		SELECT LockBoxReceiptId, InvoiceId from #ReceiptsExtract
	)
	SELECT * INTO #InvoiceIds FROM InvoiceIds
	
	SELECT 
	I.LockBoxReceiptId, 
	I.InvoiceId, 
	R.EntityId,
	R.EntityType,
	IsRentalDetail=
	CASE 
		WHEN (ReceivableTypes.[Name] = 'LoanInterest' OR ReceivableTypes.[Name] = 'LoanPrincipal') AND CTR.IsNonAccrual=1 THEN 1
		ELSE 0
	END,
	R.Id AS ReceivableId,
	RID.Id AS ReceivableInvoiceDetailId,
	CTR.IsNonAccrual AS IsNonAccrual,
	RID.ReceivableInvoiceId AS ReceivableInvoiceId,
	IsPayDownNonAccrual = 
	CASE
		WHEN LoanPaydowns.Id IS NULL THEN CAST(0 AS BIT)
		ELSE CAST(1 AS BIT)
	END,
	RD.LeaseComponentBalance_Amount AS LeaseComponentBalance,
    RD.NonLeaseComponentBalance_Amount AS NonLeaseComponentBalance,
    RD.LeaseComponentAmount_Currency AS Currency,
	RD.Id AS ReceivableDetailId
	INTO #NonAccrualInvoiceInfo 
	FROM #InvoiceIds I 
	INNER JOIN ReceivableInvoices RI ON I.InvoiceId = RI.Id AND RI.isactive = 1 AND RI.IsStatementInvoice = 0
	INNER JOIN ReceivableInvoiceDetails RID ON RID.receivableInvoiceid = RI.id
	INNER JOIN ReceivableDetails RD ON RID.ReceivableDetailId = RD.id and RD.isactive = 1
	INNER JOIN Receivables R ON RD.ReceivableId = R.id and R.isactive = 1
	INNER JOIN ReceivableCodes ON ReceivableCodes.id = R.ReceivableCodeId and ReceivableCodes.isactive = 1
	INNER JOIN ReceivableTypes ON ReceivableCodes.ReceivableTypeId = ReceivableTypes.Id and ReceivableTypes.isactive = 1
	INNER JOIN Contracts CTR ON R.EntityId=CTR.Id
	LEFT JOIN LoanPaydowns ON LoanPaydowns.InvoiceId = RI.Id AND LoanPaydowns.[Status] = 'Submitted'
		
	INSERT INTO #NonAccrualInvoiceInfo
	SELECT 
	I.LockBoxReceiptId, 
	I.InvoiceId, 
	R.EntityId,
	R.EntityType,
	IsRentalDetail=
	CASE 
		WHEN (ReceivableTypes.[Name] = 'LoanInterest' OR ReceivableTypes.[Name] = 'LoanPrincipal') AND CTR.IsNonAccrual=1 THEN 1
		ELSE 0
	END,
	R.Id AS ReceivableId,
	RID.Id AS ReceivableInvoiceDetailId,
	CTR.IsNonAccrual AS IsNonAccrual,
	SA.ReceivableInvoiceId AS ReceivableInvoiceId,
	IsPayDownNonAccrual = CAST(0 AS BIT),
	RD.LeaseComponentBalance_Amount AS LeaseComponentBalance,
    RD.NonLeaseComponentBalance_Amount AS NonLeaseComponentBalance,
    RD.LeaseComponentAmount_Currency AS Currency,
	RD.Id AS ReceivableDetailId
	FROM #InvoiceIds I 
	INNER JOIN ReceivableInvoices RI ON I.InvoiceId = RI.Id AND RI.isactive = 1 AND RI.IsStatementInvoice = 1
	INNER JOIN ReceivableInvoiceStatementAssociations SA ON RI.Id = SA.StatementInvoiceId
	INNER JOIN ReceivableInvoiceDetails RID ON RID.receivableInvoiceid = SA.ReceivableInvoiceId
	INNER JOIN ReceivableDetails RD ON RID.ReceivableDetailId = RD.id and RD.isactive = 1
	INNER JOIN Receivables R ON RD.ReceivableId = R.id and R.isactive = 1
	INNER JOIN ReceivableCodes ON ReceivableCodes.id = R.ReceivableCodeId and ReceivableCodes.isactive = 1
	INNER JOIN ReceivableTypes ON ReceivableCodes.ReceivableTypeId = ReceivableTypes.Id and ReceivableTypes.isactive = 1
	INNER JOIN Contracts CTR ON R.EntityId=CTR.Id

	--Finding out the Receipts's Rental ReceivableDetails
	;WITH ContractIdsFromInvoicesHavingRentals AS (
		SELECT distinct LockBoxReceiptId, EntityId AS ContractId,ReceivableInvoiceId,IsPayDownNonAccrual from #NonAccrualInvoiceInfo
		WHERE IsRentalDetail=1 AND EntityType='CT' AND IsNonAccrual=1
	)
	SELECT 
	RCTR.LockBoxReceiptId as ReceiptId,
	ReceivableDetails.EffectiveBalance_Amount as EffectiveBalance,
	0.00 as EffectiveTaxBalance,
	ReceivableDetails.EffectiveBookBalance_Amount AS EffectiveBookBalance,
	ReceivableDetails.Id as ReceivableDetailId,
	InvoiceId=ReceivableInvoiceDetails.ReceivableInvoiceId,
	Receivables.CustomerId as CustomerId,
	case when Receivables.entitytype = 'CT' then Receivables.EntityId else null end as ContractId,
	null as DiscountingId,
	ReceivableTypes.Id as ReceivableTypeId,
	ReceivableTypes.[Name] as ReceivableType,
	Receivables.PaymentScheduleId,
	Receivables.Id as ReceivableId,
	ReceivableDetails.IsActive as IsReceivableDetailActive,
	Receivables.EntityType as ReceivableEntityType,
	Receivables.EntityId as ReceivableEntityId,
	Receivables.DueDate as DueDate,
	Receivables.IncomeType as IncomeType,
	RCTR.ReceivableInvoiceId,
	ReceivableDetails.LeaseComponentBalance_Amount AS LeaseComponentBalance,
	ReceivableDetails.NonLeaseComponentBalance_Amount AS NonLeaseComponentBalance,
	ReceivableDetails.LeaseComponentAmount_Currency AS Currency
	INTO #RentalContractReceivableDetails
	FROM ContractIdsFromInvoicesHavingRentals RCTR
	INNER JOIN Receivables ON RCTR.ContractId = Receivables.EntityId and Receivables.EntityType = 'CT' AND Receivables.IsActive = 1
	INNER JOIN ReceivableDetails ON Receivables.Id = ReceivableDetails.ReceivableId AND ReceivableDetails.IsActive = 1
	INNER JOIN ReceivableCodes ON Receivables.ReceivableCodeId = ReceivableCodes.Id	AND ReceivableCodes.IsActive = 1  
	INNER JOIN ReceivableTypes ON ReceivableCodes.ReceivableTypeId = ReceivableTypes.Id AND ReceivableTypes.IsActive = 1
	LEFT JOIN ReceivableInvoiceDetails ON ReceivableDetails.Id = ReceivableInvoiceDetails.ReceivableDetailId AND ReceivableInvoiceDetails.IsActive=1
	WHERE (Receivables.IsDummy = 0 OR IsPayDownNonAccrual = 1)
		AND Receivables.IsCollected = 1
		AND ReceivableDetails.EffectiveBookBalance_Amount + ReceivableDetails.EffectiveBalance_Amount != 0.00
		AND (ReceivableTypes.[Name]='LoanInterest' or ReceivableTypes.[Name]='LoanPrincipal')
		AND (Receivables.IncomeType!='InterimInterest' AND Receivables.IncomeType!='TakeDownInterest')
		
	--Finding out the Receipts's Non-Rental ReceivableDetails
	;WITH NonRentalsInfo AS(
		SELECT distinct LockBoxReceiptId, InvoiceId, ReceivableId, ReceivableInvoiceDetailId from #NonAccrualInvoiceInfo
		WHERE (IsNonAccrual=0 OR IsRentalDetail=0) AND IsPayDownNonAccrual = 0
	)
	SELECT * INTO #NonRentalsInfo FROM NonRentalsInfo

	 IF EXISTS(SELECT 1 FROM #NonAccrualInvoiceInfo WHERE IsNonAccrual = 1 AND IsPayDownNonAccrual = 1 AND IsRentalDetail=0) 
	 BEGIN

	 ;WITH TaxDetails AS (
	  SELECT ReceivableDetailId = ReceivableDetails.Id, EffectiveTaxBalance = Sum(ReceivableTaxDetails.EffectiveBalance_Amount)
	  FROM ReceiptPostByLockBox_Extract RPBL
		INNER JOIN ReceivableInvoiceDetails ON RPBL.ReceivableInvoiceId = ReceivableInvoiceDetails.ReceivableInvoiceId AND ReceivableInvoiceDetails.IsActive = 1
		INNER JOIN ReceivableDetails ON ReceivableInvoiceDetails.ReceivableDetailId = ReceivableDetails.Id AND ReceivableDetails.IsActive = 1
		INNER JOIN Receivables ON ReceivableDetails.ReceivableId = Receivables.Id and Receivables.IsActive = 1 
		INNER JOIN ReceivableTaxDetails ON ReceivableDetails.Id = ReceivableTaxDetails.ReceivableDetailId AND ReceivableTaxDetails.IsActive = 1
		INNER JOIN ReceivableCodes ON Receivables.ReceivableCodeId = ReceivableCodes.Id	AND ReceivableCodes.IsActive = 1  
		INNER JOIN ReceivableTypes ON ReceivableCodes.ReceivableTypeId = ReceivableTypes.Id AND ReceivableTypes.IsActive = 1
		WHERE RPBL.JobStepInstanceId=@JobStepInstanceId
			AND RPBL.IsNonAccrualLoan = 1
			AND Receivables.IsCollected = 1
			AND (Receivables.IncomeType!='InterimInterest' AND Receivables.IncomeType!='TakeDownInterest')
		GROUP BY ReceivableDetails.Id
	  ),
	  ContractInfo AS
		(
		SELECT DISTINCT RPBL.ReceivableInvoiceId,ReceivableInvoiceDetails.EntityId AS ContractId FROM ReceiptPostByLockBox_Extract RPBL  
			INNER JOIN ReceivableInvoiceDetails ON RPBL.ReceivableInvoiceId = ReceivableInvoiceDetails.ReceivableInvoiceId AND ReceivableInvoiceDetails.IsActive = 1
			WHERE RPBL.JobStepInstanceId=@JobStepInstanceId
		)
		SELECT
		RPBL.Id,
		RentalBalance = SUM(
		CASE
			WHEN (ReceivableTypes.Name = 'LoanInterest' OR ReceivableTypes.Name = 'LoanPrincipal') 
			THEN ISNULL(ReceivableDetails.EffectiveBalance_Amount,0)
		END),
		NonRentalBalance = SUM(
		CASE
			WHEN (ReceivableTypes.Name != 'LoanInterest' AND ReceivableTypes.Name != 'LoanPrincipal') 
			THEN ISNULL(ReceivableDetails.EffectiveBalance_Amount,0) + IsNull(TaxDetails.EffectiveTaxBalance, 0.00)
		END)
		INTO #NAPayDownAmount
		FROM ReceiptPostByLockBox_Extract RPBL
		INNER JOIN ReceivableInvoices ON RPBL.ReceivableInvoiceId = ReceivableInvoices.Id
		INNER JOIN ContractInfo ON ContractInfo.ReceivableInvoiceId = RPBL.ReceivableInvoiceId
		INNER JOIN Receivables ON Receivables.EntityId = ContractInfo.ContractId and Receivables.EntityType = 'CT' AND Receivables.IsActive = 1 AND Receivables.DueDate <= ReceivableInvoices.DueDate
		INNER JOIN ReceivableDetails ON Receivables.Id = ReceivableDetails.ReceivableId AND ReceivableDetails.IsActive = 1
		INNER JOIN ReceivableCodes ON Receivables.ReceivableCodeId = ReceivableCodes.Id	AND ReceivableCodes.IsActive = 1  
		INNER JOIN ReceivableTypes ON ReceivableCodes.ReceivableTypeId = ReceivableTypes.Id AND ReceivableTypes.IsActive = 1
		LEFT JOIN TaxDetails ON ReceivableDetails.Id = TaxDetails.ReceivableDetailId
		LEFT JOIN ReceivableInvoiceDetails ON ReceivableDetails.Id = ReceivableInvoiceDetails.ReceivableDetailId AND ReceivableInvoiceDetails.IsActive = 1
		WHERE RPBL.JobStepInstanceId=@JobStepInstanceId
			AND RPBL.IsNonAccrualLoan = 1
			AND Receivables.IsCollected = 1
			AND (ReceivableDetails.EffectiveBookBalance_Amount + ReceivableDetails.EffectiveBalance_Amount + IsNull(TaxDetails.EffectiveTaxBalance, 0.00)) != 0.00
			AND (ReceivableTypes.[Name]='LoanInterest' OR ReceivableTypes.[Name]='LoanPrincipal' OR ReceivableInvoiceDetails.ReceivableInvoiceId = RPBL.ReceivableInvoiceId)
			AND (Receivables.IncomeType!='InterimInterest' AND Receivables.IncomeType!='TakeDownInterest')
		GROUP BY RPBL.Id,RPBL.ReceivedAmount
		Having RPBL.ReceivedAmount > 
			SUM(CASE WHEN (ReceivableTypes.Name = 'LoanInterest' OR ReceivableTypes.Name = 'LoanPrincipal') THEN ReceivableDetails.EffectiveBalance_Amount END)
	

		DECLARE @MINReceiptId BIGINT 
		set @MINReceiptId = (select Min(LockBoxReceiptId) from #ReceiptsExtract)
		
		INSERT INTO #ReceiptsExtract
		SELECT 
			LockBoxReceiptId = @MINReceiptId - RANK() OVER (ORDER BY RPBL.LockBoxReceiptId DESC),
			PrevLockBoxReceiptId = RPBL.LockBoxReceiptId,
			ReceivedAmount = 
			CASE
				WHEN RPBL.ReceivedAmount <= (NAPaydown.RentalBalance + NAPaydown.NonRentalBalance) THEN RPBL.ReceivedAmount - NAPaydown.RentalBalance
				WHEN RPBL.ReceivedAmount > (NAPaydown.RentalBalance + NAPaydown.NonRentalBalance) THEN NAPaydown.NonRentalBalance
			END,
			IsContractBasedNonAccrual= 
			CASE
				WHEN RPBL.ContractId IS NOT NULL AND RPBL.ContractNumber IS NOT NULL THEN RPBL.ContractId
				ELSE NULL
			END,
			RPBL.ReceivableInvoiceId AS InvoiceId,
			RI.LegalEntityId AS InvoiceLegalEntityId,
			IsPayDownNonRental = 1,
			RPBL.PayDownId
		FROM ReceiptPostByLockBox_Extract RPBL 
		INNER JOIN ReceivableInvoices RI ON RPBL.ReceivableInvoiceId=RI.Id
		JOIN #NAPayDownAmount NAPaydown ON NAPaydown.Id = RPBL.Id
		WHERE RPBL.JobStepInstanceId = @JobStepInstanceId
		AND RPBL.IsNonAccrualLoan=1 AND RPBL.IsValid = 1
		AND RPBL.ReceiptClassification='NonAccrualNonDSL'
		AND RPBL.CreateUnallocatedReceipt=0

		--Update #ReceiptExtract ReceivedAmount
		UPDATE PrevReceipt
		SET ReceivedAmount = PrevReceipt.ReceivedAmount - NewReceipt.ReceivedAmount
		FROM #ReceiptsExtract PrevReceipt
		JOIN #ReceiptsExtract NewReceipt ON PrevReceipt.LockBoxReceiptId = NewReceipt.PrevLockBoxReceiptId


		INSERT INTO #NonRentalsInfo
		SELECT distinct #ReceiptsExtract.LockBoxReceiptId, #NonAccrualInvoiceInfo.InvoiceId, ReceivableId, ReceivableInvoiceDetailId 
		from #NonAccrualInvoiceInfo
		JOIN #ReceiptsExtract ON #NonAccrualInvoiceInfo.LockBoxReceiptId = #ReceiptsExtract.PrevLockBoxReceiptId
		WHERE IsNonAccrual = 1 AND IsPayDownNonAccrual = 1 AND IsRentalDetail=0

	 END
	
	SELECT 
		NRI.LockBoxReceiptId AS ReceiptId
		,RID.EffectiveBalance_Amount AS EffectiveBalance
		,RID.EffectiveTaxBalance_Amount AS EffectiveTaxBalance
		,0.00 AS EffectiveBookBalance
	    ,RID.ReceivableDetailId
	    ,NRI.InvoiceId AS InvoiceId
	    ,R.CustomerId
		,CASE WHEN R.entitytype = 'CT' THEN R.EntityId ELSE NULL END AS ContractId
		,CASE WHEN R.entitytype = 'DT' THEN R.EntityId ELSE NULL END AS DiscountingId
		,ReceivableTypes.Id AS ReceivableTypeId
		,ReceivableTypes.Name AS ReceivableType
		,R.PaymentScheduleId
		,R.Id AS ReceivableId
		,CAST(1 AS BIT) AS IsReceivableDetailActive
		,R.EntityType AS ReceivableEntityType
		,R.EntityId AS ReceivableEntityId
		,R.DueDate
		,R.IncomeType
		,RID.ReceivableInvoiceId AS ReceivableInvoiceId
		,NAI.LeaseComponentBalance
	    ,NAI.NonLeaseComponentBalance
	    ,NAI.Currency
	INTO #NonRentalReceivableDetails
	FROM #NonRentalsInfo NRI
	INNER JOIN ReceivableInvoices RI ON NRI.InvoiceId = RI.Id AND RI.isactive = 1 AND RI.IsStatementInvoice = 0
	INNER JOIN ReceivableInvoiceDetails RID ON RI.Id = RID.receivableInvoiceid AND NRI.ReceivableInvoiceDetailId=RID.Id
	INNER JOIN Receivables R ON NRI.ReceivableId = R.Id
	INNER JOIN #NonAccrualInvoiceInfo NAI on RID.ReceivableDetailId = NAI.ReceivableDetailId
	INNER JOIN ReceivableCodes ON ReceivableCodes.id = R.ReceivableCodeId and ReceivableCodes.isactive = 1
	INNER JOIN ReceivableTypes ON ReceivableCodes.ReceivableTypeId = ReceivableTypes.Id and ReceivableTypes.isactive = 1
	WHERE (rid.EffectiveBalance_Amount + rid.EffectiveTaxBalance_Amount !=0)

	INSERT INTO #NonRentalReceivableDetails
	SELECT 
		NRI.LockBoxReceiptId AS ReceiptId
		,RID.EffectiveBalance_Amount AS EffectiveBalance
		,RID.EffectiveTaxBalance_Amount AS EffectiveTaxBalance
		,0.00 AS EffectiveBookBalance
	    ,RID.ReceivableDetailId
	    ,NRI.InvoiceId AS InvoiceId
	    ,R.CustomerId
		,CASE WHEN R.entitytype = 'CT' THEN R.EntityId ELSE NULL END AS ContractId
		,CASE WHEN R.entitytype = 'DT' THEN R.EntityId ELSE NULL END AS DiscountingId
		,ReceivableCodes.Id AS ReceivableTypeId
		,ReceivableTypes.Name AS ReceivableType
		,R.PaymentScheduleId
		,R.Id AS ReceivableId
		,CAST(1 AS BIT) AS IsReceivableDetailActive
		,R.EntityType AS ReceivableEntityType
		,R.EntityId AS ReceivableEntityId
		,R.DueDate
		,R.IncomeType
		,SA.ReceivableInvoiceId AS ReceivableInvoiceId
		,NAI.LeaseComponentBalance
	    ,NAI.NonLeaseComponentBalance
	    ,NAI.Currency
	FROM #NonRentalsInfo NRI
	INNER JOIN ReceivableInvoices RI ON NRI.InvoiceId = RI.Id AND RI.isactive = 1 AND RI.IsStatementInvoice = 1
	INNER JOIN ReceivableInvoiceStatementAssociations SA ON RI.Id = SA.StatementInvoiceId
	INNER JOIN ReceivableInvoiceDetails RID ON SA.ReceivableInvoiceId = RID.receivableInvoiceid AND NRI.ReceivableInvoiceDetailId=RID.Id
	INNER JOIN Receivables R ON NRI.ReceivableId = R.Id
	INNER JOIN #NonAccrualInvoiceInfo NAI on RID.ReceivableDetailId = NAI.ReceivableDetailId
	INNER JOIN ReceivableCodes ON ReceivableCodes.id = R.ReceivableCodeId and ReceivableCodes.isactive = 1
	INNER JOIN ReceivableTypes ON ReceivableCodes.ReceivableTypeId = ReceivableTypes.Id and ReceivableTypes.isactive = 1
	WHERE (rid.EffectiveBalance_Amount + rid.EffectiveTaxBalance_Amount !=0)

	--Has Future Receivables Calculation for each contract
	;WITH MaxReceivableDetailDueDatesOfContract AS(
		SELECT RRD.ContractId, MAX(RRD.DueDate) AS MaxDueDate 
		FROM #RentalContractReceivableDetails RRD WHERE RRD.ReceivableType='LoanPrincipal' AND (RRD.EffectiveBalance+RRD.EffectiveTaxBalance)>=0
		GROUP BY RRD.ContractId
	), FutureReceivablesInfo AS(
		SELECT 
			MRD.ContractId,
			CTR.NonAccrualDate,
			CountOfPaymentSchedules=
			SUM(
			CASE
				WHEN (PS.DueDate > MRD.MaxDueDate) THEN 1
				ELSE 0
			END
			)
		FROM MaxReceivableDetailDueDatesOfContract MRD 
		INNER JOIN Contracts CTR ON MRD.ContractId=CTR.Id
		INNER JOIN LoanFinances LF ON CTR.Id=LF.ContractId AND LF.IsCurrent=1
		INNER JOIN LoanPaymentSchedules PS ON LF.Id=PS.LoanFinanceId
		GROUP BY MRD.ContractId, CTR.NonAccrualDate
	)
	SELECT 
	FRI.ContractId,
	FRI.NonAccrualDate,
	HasFutureReceivables=
	CASE
		WHEN (FRI.CountOfPaymentSchedules>0) THEN CAST(1 AS BIT) 
		ELSE CAST(0 AS BIT) 
	END
	INTO #NonAccrualContractInfo
	FROM FutureReceivablesInfo FRI

	--Add Unallocated NA Receipt from PayDown

	INSERT INTO #ReceiptsExtract
	SELECT 
	RPBL.LockBoxReceiptId,
	PrevLockBoxReceiptId = null,
	ReceivedAmount = RPBL.ReceivedAmount,
	IsContractBasedNonAccrual= 
	CASE
		WHEN RPBL.ContractId IS NOT NULL AND RPBL.ContractNumber IS NOT NULL THEN RPBL.ContractId
		ELSE NULL
	END,
	RPBL.ReceivableInvoiceId AS InvoiceId,
	RI.LegalEntityId AS InvoiceLegalEntityId,
	IsPayDownNonRental = 0,
	PayDownId = null
	FROM ReceiptPostByLockBox_Extract RPBL 
	INNER JOIN ReceivableInvoices RI ON RPBL.ReceivableInvoiceId=RI.Id
	WHERE RPBL.JobStepInstanceId = @JobStepInstanceId
	AND RPBL.IsNonAccrualLoan=1 AND RPBL.IsValid = 1
	AND RPBL.ReceiptClassification='NonAccrualNonDSL'
	AND RPBL.CreateUnallocatedReceipt=1

	--Returning Data---------------

	SELECT
		#ReceiptsExtract.LockBoxReceiptId AS ReceiptId,
		RPBL.Currency,
		RPBL.ReceivedDate,
		RPBL.ReceiptClassification,
		#ReceiptsExtract.IsContractBasedNonAccrual AS ContractId,
		RPBL.EntityType,
		RPBL.CustomerId,
		#ReceiptsExtract.ReceivedAmount AS ReceiptAmount,
		RPBL.LegalEntityId,
		#ReceiptsExtract.InvoiceLegalEntityId,
		RPBL.CostCenterId,
		RPBL.LineOfBusinessId,
		RPBL.InstrumentTypeId,
		RPBL.CurrencyId,
		RPBL.BankAccountId,
		RPBL.Id AS DumpId,
		RPBL.IsValid,
		CAST(1 AS BIT) AS IsNewReceipt,
		RPBL.ReceiptBatchId,
		CAST(1 AS BIT) AS IsNonAccrualLoan,
		RPBL.ReceivableInvoiceId AS InvoiceId,
		ComputedEntityType=
		CASE
			WHEN (RPBL.ContractNumber IS NOT NULL AND RPBL.ContractNumber!='') THEN 'Loan'
			WHEN (RPBL.CustomerNumber IS NOT NULL AND RPBL.CustomerNumber!='') THEN 'Customer'
			WHEN (RPBL.LegalEntityNumber IS NOT NULL AND RPBL.LegalEntityNumber!='') THEN '_'
			ELSE '_'
		END,
		RPBL.IsStatementInvoice,
		RPBL.CashTypeId,
		RPBL.ReceiptTypeId,
		RPBL.Comment,
		RPBL.CheckNumber,
		#ReceiptsExtract.PayDownId
	FROM ReceiptPostByLockBox_Extract RPBL INNER JOIN #ReceiptsExtract ON
	((RPBL.LockBoxReceiptId = #ReceiptsExtract.LockBoxReceiptId AND #ReceiptsExtract.IsPayDownNonRental = 0) 
	OR (RPBL.LockBoxReceiptId = #ReceiptsExtract.PrevLockBoxReceiptId AND #ReceiptsExtract.IsPayDownNonRental = 1))
	AND RPBL.JobStepInstanceId=@JobStepInstanceId AND (RPBL.CreateUnallocatedReceipt=0 OR (RPBL.IsValid = 1 AND RPBL.PayDownId IS NOT NULL))

	--Returning Rental ReceivableDetails
	SELECT 
		R.ReceiptId,
		R.EffectiveBalance,
		R.EffectiveTaxBalance,
		R.EffectiveBookBalance,
		R.ReceivableDetailId,
		R.InvoiceId,
		R.CustomerId,
		R.ContractId,
		R.DiscountingId,
		R.ReceivableTypeId,
		R.ReceivableType,
		R.PaymentScheduleId,
		R.ReceivableId,
		R.IsReceivableDetailActive,
		R.ReceivableEntityType,
		R.ReceivableEntityId,
		R.DueDate,
		R.IncomeType,
		R.ReceivableInvoiceId,
		R.LeaseComponentBalance,
		R.NonLeaseComponentBalance,
		R.Currency
	FROM #RentalContractReceivableDetails R
		
	--Returning Non-Rental ReceivableDetails
	SELECT
		NR.ReceiptId,
		NR.EffectiveBalance,
		NR.EffectiveTaxBalance,
		NR.EffectiveBookBalance,
		NR.ReceivableDetailId,
		NR.InvoiceId,
		NR.CustomerId,
		NR.ContractId,
		NR.DiscountingId,
		NR.ReceivableTypeId,
		NR.ReceivableType,
		NR.PaymentScheduleId,
		NR.ReceivableId,
		NR.IsReceivableDetailActive,
		NR.ReceivableEntityType,
		NR.ReceivableEntityId,
		NR.DueDate,
		NR.IncomeType,
		NR.ReceivableInvoiceId,
		NR.LeaseComponentBalance,
		NR.NonLeaseComponentBalance,
		NR.Currency
	FROM #NonRentalReceivableDetails NR

	--Returning Contract Info
	SELECT 
	N.ContractId,
	N.NonAccrualDate,
	N.HasFutureReceivables
	FROM #NonAccrualContractInfo N

	;WITH InvoiceDetailsInfo AS(
		SELECT InvoiceId, EntityId AS ContractId, MIN(ReceivableInvoiceDetailId) AS MinimumReceivableDetailIdInInvoiceForContract
		FROM #NonAccrualInvoiceInfo WHERE IsRentalDetail=1 AND IsNonAccrual=1 AND EntityType='CT'
		GROUP BY InvoiceId, EntityId
	)
	SELECT 
	I.InvoiceId,
	I.ContractId,
	I.MinimumReceivableDetailIdInInvoiceForContract
	FROM InvoiceDetailsInfo I


	DROP TABLE #ReceiptsExtract
	DROP TABLE #NonAccrualContractInfo
	DROP TABLE #NonAccrualInvoiceInfo
	DROP TABLE #NonRentalReceivableDetails
	DROP TABLE #RentalContractReceivableDetails
	DROP TABLE #InvoiceIds
	DROP TABLE #NonRentalsInfo
END

GO
