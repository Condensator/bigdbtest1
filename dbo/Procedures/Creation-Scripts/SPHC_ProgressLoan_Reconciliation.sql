SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
 
CREATE PROC [dbo].[SPHC_ProgressLoan_Reconciliation]
(
	@ResultOption NVARCHAR(20),
	@LegalEntityIds ReconciliationId READONLY,
	@ContractIds ReconciliationId READONLY,  
	@CustomerIds ReconciliationId READONLY
)
AS
BEGIN
IF OBJECT_ID('tempdb..#EligibleContracts') IS NOT NULL
BEGIN
    DROP TABLE #EligibleContracts;
END;
IF OBJECT_ID('tempdb..#PayableInvoiceDetails') IS NOT NULL
BEGIN
    DROP TABLE #PayableInvoiceDetails;
END;
IF OBJECT_ID('tempdb..#TotalProgressFundingAmount') IS NOT NULL
BEGIN
    DROP TABLE #TotalProgressFundingAmount;
END;
IF OBJECT_ID('tempdb..#TakeDownPayableInvoiceDetails') IS NOT NULL
BEGIN
    DROP TABLE #TakeDownPayableInvoiceDetails;
END;
IF OBJECT_ID('tempdb..#TotalTakeDownAmount') IS NOT NULL
BEGIN
    DROP TABLE #TotalTakeDownAmount;
END;
IF OBJECT_ID('tempdb..#NoOfFundings') IS NOT NULL
BEGIN
    DROP TABLE #NoOfFundings;
END;
IF OBJECT_ID('tempdb..#NoOfTakeDowns') IS NOT NULL
BEGIN
    DROP TABLE #NoOfTakeDowns;
END;
IF OBJECT_ID('tempdb..#GLJournalDetails') IS NOT NULL
BEGIN
    DROP TABLE #GLJournalDetails;
END;
IF OBJECT_ID('tempdb..#DisbursementGL') IS NOT NULL
BEGIN
    DROP TABLE #DisbursementGL;
END;
IF OBJECT_ID('tempdb..#ProgressPaymentCredit') IS NOT NULL
BEGIN
    DROP TABLE #ProgressPaymentCredit;
END;
IF OBJECT_ID('tempdb..#ProgressPaymentCreditGL') IS NOT NULL
BEGIN
    DROP TABLE #ProgressPaymentCreditGL;
END;
IF OBJECT_ID('tempdb..#ProgressPaymentCreditGLAmount') IS NOT NULL
BEGIN
    DROP TABLE #ProgressPaymentCreditGLAmount;
END;
IF OBJECT_ID('tempdb..#GLJournalValues') IS NOT NULL
BEGIN
    DROP TABLE #GLJournalValues;
END;
IF OBJECT_ID('tempdb..#ReceiptDetails') IS NOT NULL
BEGIN
    DROP TABLE #ReceiptDetails;
END;
IF OBJECT_ID('tempdb..#Receivables') IS NOT NULL
BEGIN
    DROP TABLE #Receivables;
END;
IF OBJECT_ID('tempdb..#ReceivableDetails') IS NOT NULL
BEGIN
    DROP TABLE #ReceivableDetails;
END;
IF OBJECT_ID('tempdb..#PayableInvoiceIds') IS NOT NULL
BEGIN
    DROP TABLE #PayableInvoiceIds;
END;
IF OBJECT_ID('tempdb..#PayableInvoiceAmount') IS NOT NULL
BEGIN
    DROP TABLE #PayableInvoiceAmount;
END;
IF OBJECT_ID('tempdb..#PayableInvoiceGLJournalDetails') IS NOT NULL
BEGIN
    DROP TABLE #PayableInvoiceGLJournalDetails;
END;
IF OBJECT_ID('tempdb..#TotalPayableInvoiceTakeDownAmount') IS NOT NULL
BEGIN
    DROP TABLE #TotalPayableInvoiceTakeDownAmount;
END;
IF OBJECT_ID('tempdb..#ProgressPaymentCreditPayableInvoiceGLAmount') IS NOT NULL
BEGIN
    DROP TABLE #ProgressPaymentCreditPayableInvoiceGLAmount;
END;
IF OBJECT_ID('tempdb..#ProgressCreditDetails') IS NOT NULL
BEGIN
    DROP TABLE #ProgressCreditDetails;
END;
IF OBJECT_ID('tempdb..#LoanInterimInterestCapitalization') IS NOT NULL
BEGIN
    DROP TABLE #LoanInterimInterestCapitalization;
END;
IF OBJECT_ID('tempdb..#LeaseInterimInterestCapitalization') IS NOT NULL
BEGIN
    DROP TABLE #LeaseInterimInterestCapitalization;
END;
IF OBJECT_ID('tempdb..#RenewalDetails') IS NOT NULL
BEGIN
    DROP TABLE #RenewalDetails;
END;
IF OBJECT_ID('tempdb..#PayableGLCreditDetails') IS NOT NULL
BEGIN
    DROP TABLE #PayableGLCreditDetails;
END;
IF OBJECT_ID('tempdb..#PayableGLCreditAmount') IS NOT NULL
BEGIN
    DROP TABLE #PayableGLCreditAmount;
END;
IF OBJECT_ID('tempdb..#ProgressCreditDetailsTakeDownAmount') IS NOT NULL
BEGIN
    DROP TABLE #ProgressCreditDetailsTakeDownAmount;
END;
IF OBJECT_ID('tempdb..#ProgressCreditDetailsGLAmount') IS NOT NULL
BEGIN
    DROP TABLE #ProgressCreditDetailsGLAmount;
END;
IF OBJECT_ID('tempdb..#TotalInterimInterestCapitalization') IS NOT NULL
BEGIN
    DROP TABLE #TotalInterimInterestCapitalization;
END; 
IF OBJECT_ID('tempdb..#ProgressLoanInterimInterest') IS NOT NULL
BEGIN
    DROP TABLE #ProgressLoanInterimInterest;
END;  
IF OBJECT_ID('tempdb..#InterimInterestGL') IS NOT NULL
BEGIN
    DROP TABLE #InterimInterestGL;
END;  
IF OBJECT_ID('tempdb..#CapitalizationGLCreditAmount') IS NOT NULL
BEGIN
    DROP TABLE #CapitalizationGLCreditAmount;
END; 
IF OBJECT_ID('tempdb..#DisbursementRequestPayableDetails') IS NOT NULL
BEGIN
    DROP TABLE #DisbursementRequestPayableDetails;
END;  
IF OBJECT_ID('tempdb..#DisbursementRequestProgressPaymentCreditGLAmount') IS NOT NULL
BEGIN
    DROP TABLE #DisbursementRequestProgressPaymentCreditGLAmount;
END; 
IF OBJECT_ID('tempdb..#DisbursementTableAndGL') IS NOT NULL
BEGIN
    DROP TABLE #DisbursementTableAndGL;
END; 
IF OBJECT_ID('tempdb..#PayableInvoiceDisbursementTableAndGL') IS NOT NULL
BEGIN
    DROP TABLE #PayableInvoiceDisbursementTableAndGL;
END; 
IF OBJECT_ID('tempdb..#UpdatePayableInvoiceGLJournalDetails') IS NOT NULL
BEGIN
    DROP TABLE #UpdatePayableInvoiceGLJournalDetails;
END; 
IF OBJECT_ID('tempdb..#DisbursementRequestGLJournalDetails') IS NOT NULL
BEGIN
    DROP TABLE #DisbursementRequestGLJournalDetails;
END; 
IF OBJECT_ID('tempdb..#UpdateTakeDownGLJournalDetails') IS NOT NULL
BEGIN
    DROP TABLE #UpdateTakeDownGLJournalDetails;
END; 
IF OBJECT_ID('tempdb..#UpdatePayableInvoicePPCGLJournalDetails') IS NOT NULL
BEGIN
    DROP TABLE #UpdatePayableInvoicePPCGLJournalDetails;
END; 
IF OBJECT_ID('tempdb..#DuplicatePayableInvoiceIds') IS NOT NULL
BEGIN
    DROP TABLE #DuplicatePayableInvoiceIds;
END; 
IF OBJECT_ID('tempdb..#OriginationRestoredPayableInvoices') IS NOT NULL
BEGIN
    DROP TABLE #OriginationRestoredPayableInvoices;
END; 
IF OBJECT_ID('tempdb..#OriginationRestoredIds') IS NOT NULL
BEGIN
    DROP TABLE #OriginationRestoredIds;
END; 
IF OBJECT_ID('tempdb..#ProgressLoanLifeCycle') IS NOT NULL
BEGIN
    DROP TABLE #ProgressLoanLifeCycle;
END; 
IF OBJECT_ID('tempdb..#PayableInvoiceLifeCycle') IS NOT NULL
BEGIN
    DROP TABLE #PayableInvoiceLifeCycle;
END; 
IF OBJECT_ID('tempdb..#OriginationRestoredPayableInvoice') IS NOT NULL
BEGIN
    DROP TABLE #OriginationRestoredPayableInvoice;
END; 
IF OBJECT_ID('tempdb..#OriginationPayableInvoice') IS NOT NULL
BEGIN
    DROP TABLE #OriginationPayableInvoice;
END; 
IF OBJECT_ID('tempdb..#TakeDownLifeCycle') IS NOT NULL
BEGIN
    DROP TABLE #TakeDownLifeCycle;
END; 
IF OBJECT_ID('tempdb..#ProgressLoanSummary') IS NOT NULL
BEGIN
    DROP TABLE #ProgressLoanSummary;
END; 
IF OBJECT_ID('tempdb..#PayableInvoiceSummary') IS NOT NULL
BEGIN
    DROP TABLE #PayableInvoiceSummary;
END; 
IF OBJECT_ID('tempdb..#TakeDownSummary') IS NOT NULL
BEGIN
    DROP TABLE #TakeDownSummary;
END; 
IF OBJECT_ID('tempdb..#UnAppliedTable') IS NOT NULL
BEGIN
    DROP TABLE #UnAppliedTable;
END; 
IF OBJECT_ID('tempdb..#UnAppliedGL') IS NOT NULL
BEGIN
    DROP TABLE #UnAppliedGL;
END; 
IF OBJECT_ID('tempdb..#RefundGLJournalIds') IS NOT NULL
BEGIN
    DROP TABLE #RefundGLJournalIds;
END;
IF OBJECT_ID('tempdb..#RefundDetails') IS NOT NULL
BEGIN
    DROP TABLE #RefundDetails;
END;


DECLARE @True BIT= 1;
DECLARE @False BIT= 0;
DECLARE @MigrationSource nvarchar(50); 
DECLARE @LegalEntitiesCount BIGINT = ISNULL((SELECT COUNT(*) FROM @LegalEntityIds), 0)
DECLARE @ContractsCount BIGINT = ISNULL((SELECT COUNT(*) FROM @ContractIds), 0)
DECLARE @CustomersCount BIGINT = ISNULL((SELECT COUNT(*) FROM @CustomerIds), 0)
SELECT @MigrationSource = Value FROM GlobalParameters WHERE Category ='Migration' AND Name = 'ConversionSource'

SELECT c.Id AS ContractId
	 , c.SequenceNumber
	 , lf.CustomerId
     , lf.Id AS LoanFinanceId
     , lf.MaturityDate AS MaturityDate
     , c.ContractType AS ContractType
     , lf.Status AS Status
     , c.LineofBusinessId
     , lf.LegalEntityId
	 , lf.InterimBillingType
	 , cc.ISO AS Currency
     , CASE
		   WHEN c.u_ConversionSource = @MigrationSource
           THEN 'Yes'
           ELSE 'No'
       END AS IsMigratedContract
	, c.Alias
	, c.SyndicationType
INTO #EligibleContracts
FROM Contracts c
     INNER JOIN LoanFinances lf ON c.Id = lf.ContractId
	 INNER JOIN Currencies currency ON c.CurrencyId =  currency.Id
	 INNER JOIN CurrencyCodes cc ON cc.Id = currency.CurrencyCodeId
WHERE lf.IsCurrent = 1
	 AND lf.ApprovalStatus NOT IN ('Rejected')
	 AND lf.Status NOT IN ('Cancelled')
     AND c.ContractType = 'ProgressLoan'
     AND @True = (CASE 
					  WHEN @LegalEntitiesCount > 0 AND EXISTS (SELECT Id FROM @LegalEntityIds WHERE Id = lf.LegalEntityId) THEN @True
					  WHEN @LegalEntitiesCount = 0 THEN @True ELSE @False END)
	 AND @True = (CASE 
				      WHEN @CustomersCount > 0 AND EXISTS (SELECT Id FROM @CustomerIds WHERE Id = lf.CustomerId) THEN @True
				      WHEN @CustomersCount = 0 THEN @True ELSE @False END)
	 AND @True = (CASE 
				      WHEN @ContractsCount > 0 AND EXISTS (SELECT Id FROM @ContractIds WHERE Id = lf.ContractId) THEN @True
				      WHEN @ContractsCount = 0 THEN @True ELSE @False END)

CREATE NONCLUSTERED INDEX IX_Id ON #EligibleContracts(ContractId);
 
 SELECT DISTINCT 
       ec.ContractId
     , pi.Id AS PayableInvoiceId
	 , pioc.Amount_Amount AS InvoiceTotal_Amount
     , pioc.Id AS PayableInvoiceOtherCostId
     , pioc.Amount_Amount AS Amount_Amount
     , pioc.Amount_Currency
     , pioc.CreditBalance_Amount
	 , pi.DueDate
	 , DR.Id AS DisbursementRequestId
	 , DR.Status
	 , lf.Type
	 , Payables.Id AS PayableId
	 , DRInvoice.AmountToPay_Amount
     , CASE WHEN lf.Type = 'OriginationRestored'
			THEN pioc.Amount_Amount
			ELSE 0.00
	   END AS OriginationRestoredAmount
	, ec.IsMigratedContract
	, Payables.Status AS PayableStatus
	, Payables.IsGLPosted PayableIsGLPosted
INTO #PayableInvoiceDetails
FROM #EligibleContracts ec
	 INNER JOIN Loanfundings lf ON lf.LoanFinanceId = ec.LoanFinanceId
     INNER JOIN PayableInvoices pi ON lf.FundingId = pi.Id
     INNER JOIN PayableInvoiceOtherCosts pioc ON pioc.PayableInvoiceId = pi.Id
												  AND pioc.AllocationMethod = 'LoanDisbursement'   
     LEFT JOIN Payables ON Payables.EntityType = 'PI'
                            AND Payables.EntityId = pi.Id
							AND Payables.Status != 'Inactive'
							AND (Payables.IsGLPosted = 1 OR Payables.Status = 'Approved' OR ec.IsMigratedContract = 'Yes')
							AND Payables.SourceId = pioc.Id
     LEFT JOIN DisbursementRequestInvoices DRInvoice ON pi.Id = DRInvoice.InvoiceId	AND DRInvoice.IsActive = 1 
     LEFT JOIN DisbursementRequests DR ON DRInvoice.DisbursementRequestId = DR.Id  AND DR.Status != 'Inactive'
WHERE pi.Status = 'Completed'						
	  AND lf.IsActive = 1
	  AND lf.Type IN ('Origination', 'OriginationRestored')

CREATE NONCLUSTERED INDEX IX_Id ON #PayableInvoiceDetails(ContractId);

SELECT PayableInvoiceId, MAX(DisbursementRequestId) AS DisbursementRequestId
INTO #DuplicatePayableInvoiceIds
FROM #PayableInvoiceDetails
WHERE PayableInvoiceId IN
(
    SELECT PayableInvoiceId
    FROM #PayableInvoiceDetails pid
    GROUP BY PayableInvoiceId
    HAVING COUNT(*) > 1
)
	AND AmountToPay_Amount != 0.00
GROUP BY PayableInvoiceId;

CREATE NONCLUSTERED INDEX IX_Id ON #DuplicatePayableInvoiceIds(PayableInvoiceId, DisbursementRequestId);

UPDATE #PayableInvoiceDetails SET InvoiceTotal_Amount = 0.00,
Amount_Amount = 0.00, CreditBalance_Amount = 0.00
FROM #PayableInvoiceDetails pid
INNER JOIN #DuplicatePayableInvoiceIds duplicate ON pid.PayableInvoiceId = duplicate.PayableInvoiceId
AND pid.DisbursementRequestId != duplicate.DisbursementRequestId


SELECT DISTINCT 
       pid.ContractId
	 , pid.PayableInvoiceId AS OriginalPayableInvoiceId
     , pioc.Id
     , p.Amount_Amount AS Amount_Amount
	 , p.Balance_Amount
     , p.Amount_Currency
	 , PIOC.PayableInvoiceId
	 , DR.Status
	 , DR.Id AS DisbursementRequestId
	 , pioc.InterimInterestStartDate
	 , pioc.AllocationMethod
	 , pioc.Amount_Amount AS PayableInvoiceOtherCostAmount
	 , pid.Type
	 , p.Id AS Payableid
	 , p.Status as PayableStatus
	 , pid.IsMigratedContract
	 , p.IsGLposted AS PayableIsGLPosted
INTO #TakeDownPayableInvoiceDetails
FROM #PayableInvoiceDetails pid
     INNER JOIN PayableInvoiceOtherCosts pioc ON pioc.ProgressFundingId = pid.PayableInvoiceOtherCostId
												 AND pioc.IsActive = 1	
     LEFT JOIN DisbursementRequestInvoices DRInvoice ON pioc.PayableInvoiceId = DRInvoice.InvoiceId
													    AND DRInvoice.IsActive = 1
     LEFT JOIN DisbursementRequests dr ON DRInvoice.DisbursementRequestId = dr.Id
	 LEFT JOIN Payables p ON p.EntityId = pioc.PayableInvoiceId  
							 AND p.SourceId = pioc.Id AND p.EntityType = 'PI'
							 AND p.Status != 'InActive'
	 LEFT JOIN DisbursementRequestPayables drp ON drp.PayableId = p.Id AND drp.DisbursementRequestId = dr.Id
WHERE pioc.AllocationMethod = 'ProgressPaymentCredit'
	  AND ((dr.Id IS NOT NULL AND dr.Status != 'InActive') OR dr.Id IS NULL);


CREATE NONCLUSTERED INDEX IX_Id ON #TakeDownPayableInvoiceDetails(ContractId);

SELECT ContractId
     , SUM(CASE WHEN Status = 'Completed' AND IsMigratedContract = 'No' 
				THEN ABS(Amount_Amount)
				WHEN IsMigratedContract = 'Yes' AND (DisbursementRequestId IS NULL AND (PayableStatus =' Approved' OR PayableIsGLPosted = 1))
				THEN ABS(InvoiceTotal_Amount)
				ELSE 0.00 
		   END) AS TotalProgressFundingAmount
	 , SUM(ABS(CreditBalance_Amount)) AS TotalCreditBalance
	 , SUM(ABS(CreditBalance_Amount)) AS FullCreditBalance
	 , SUM(ABS(OriginationRestoredAmount)) AS OriginationRestored
INTO #TotalProgressFundingAmount
FROM #PayableInvoiceDetails
GROUP BY ContractId;


CREATE NONCLUSTERED INDEX IX_Id ON #TotalProgressFundingAmount(ContractId);

SELECT ec.ContractId
	 , SUM(lis.InterestAccrued_Amount) AS Amount
INTO #ProgressLoanInterimInterest
FROM #EligibleContracts ec
     INNER JOIN LoanFinances lf ON lf.ContractId = ec.ContractId
     INNER JOIN LoanIncomeSchedules lis ON lis.LoanFinanceId = lf.Id
WHERE lis.IsGLPosted = 1
      AND lis.IsLessorOwned = 1
      AND lis.IsAccounting = 1
      AND lis.IsNonAccrual = 0
GROUP BY ec.ContractId;

SELECT t.ContractId
     , SUM(InterimInterestDebit - InterimInterestCredit) AS InterimInterestGL
     , SUM(AccruedInterimInterestDebit - AccruedInterimInterestCredit) AS AccruedInterimInterestGL
INTO #InterimInterestGL
FROM
(
    SELECT ec.ContractId
         , CASE
               WHEN gld.IsDebit = 0
                    AND gltt.Name = 'LoanIncomeRecognition'
                    AND gle.Name = 'AccruedInterest'
               THEN gld.Amount_Amount
               ELSE 0.00
           END AS InterimInterestCredit
         , CASE
               WHEN gld.IsDebit = 1
                    AND gltt.Name = 'LoanIncomeRecognition'
                    AND gle.Name = 'AccruedInterest'
               THEN gld.Amount_Amount
               ELSE 0.00
           END AS InterimInterestDebit
         , CASE
               WHEN gld.IsDebit = 0
                    AND gle.Name IN('AccruedInterest', 'AccruedInterestCapitalized')
               THEN gld.Amount_Amount
               ELSE 0.00
           END AS AccruedInterimInterestCredit
         , CASE
               WHEN gld.IsDebit = 1
                    AND gle.Name IN('AccruedInterest', 'AccruedInterestCapitalized')
               THEN gld.Amount_Amount
               ELSE 0.00
           END AS AccruedInterimInterestDebit
    FROM #EligibleContracts ec
         INNER JOIN GLJournalDetails gld ON gld.EntityId = ec.ContractId
                                            AND gld.EntityType = 'Contract'
         INNER JOIN GLTemplateDetails gltd ON gltd.Id = gld.GLTemplateDetailId
         INNER JOIN GLEntryItems gle ON gle.Id = gltd.EntryItemId
         INNER JOIN GLTransactionTypes gltt ON gle.GLTransactionTypeId = gltt.Id
) AS t
GROUP BY t.ContractId;

SELECT DISTINCT 
       takeDown.PayableInvoiceId
     , c.SequenceNumber
	 , c.Id AS ContractId
	 , c.ContractType
	 , IIF(c.Id IS NOT NULL, Contractcc.ISO, NULL) AS ContractCurrency
	 , cc.ISO AS Currency
	 , c.SyndicationType
	 , pi.InvoiceNumber
INTO #ProgressCreditDetails
FROM #TakeDownPayableInvoiceDetails takeDown
     INNER JOIN PayableInvoiceOtherCosts pioc ON takeDown.Id = pioc.Id
     INNER JOIN PayableInvoices pi ON pioc.PayableInvoiceId = pi.Id
	 LEFT JOIN Contracts c ON c.Id = pi.ContractId
	 LEFT JOIN Currencies Contractcurrency ON c.CurrencyId =  Contractcurrency.Id
	 LEFT JOIN CurrencyCodes Contractcc ON Contractcc.Id = Contractcurrency.CurrencyCodeId
	 LEFT JOIN Currencies currency ON pi.CurrencyId =  currency.Id
	 LEFT JOIN CurrencyCodes cc ON cc.Id = currency.CurrencyCodeId;

CREATE NONCLUSTERED INDEX IX_Id ON #ProgressCreditDetails(PayableInvoiceId);

SELECT takeDown.ContractId
	 , SUM(CASE WHEN Status = 'Completed' AND Status IS NOT NULL AND takeDown.IsMigratedContract = 'No'
			    THEN ABS(Amount_Amount) - ABS(Balance_Amount) 
				WHEN takeDown.IsMigratedContract = 'Yes' AND takeDown.PayableStatus != 'InActive' AND (takeDown.PayableIsGLPosted = 1 or takeDown.PayableStatus = 'Approved')
				THEN ABS(PayableInvoiceOtherCostAmount)
				ELSE 0.00 END) AS [ProgressPaymentCreditsAmountApplied]
	 , SUM(CASE WHEN Status != 'InActive' AND Status IS NOT NULL THEN ABS(Amount_Amount) ELSE 0.00 END) AS [ProgressPaymentCreditsAmount]
	 , SUM(CASE WHEN ((pioc.SyndicationType = 'FullSale' AND DisbursementRequestId IS NOT NULL) OR pioc.SyndicationType != 'FullSale' OR pioc.SyndicationType IS NULL) AND (Status = 'Pending' OR Status IS NULL) 
					 AND takeDown.IsMigratedContract = 'No'
			    THEN ABS(PayableInvoiceOtherCostAmount) 
			    WHEN (pioc.SyndicationType != 'FullSale' OR pioc.SyndicationType IS NULL) AND Status IS NULL 
					 AND takeDown.IsMigratedContract = 'Yes'
					 AND takeDown.PayableStatus != 'InActive'
					 AND (takeDown.PayableIsGLPosted = 0 OR takeDown.PayableStatus NOT IN ('Approved'))
				THEN ABS(PayableInvoiceOtherCostAmount) 
				ELSE 0.00 
			END) AS [PendingProgressPaymentCreditsAmount]
     , SUM(CASE WHEN pioc.SyndicationType IS NULL AND Status IS NULL AND takeDown.DisbursementRequestId IS NULL THEN ABS(Balance_Amount) ELSE 0.00 END) AS [NoContractBalance]
	 , DATEADD(DAY, -1, MAX(InterimInterestStartDate)) AS InterimInterestStartDate
INTO #TotalTakeDownAmount 
FROM #TakeDownPayableInvoiceDetails takeDown
LEFT JOIN #ProgressCreditDetails pioc ON takeDown.PayableInvoiceId = pioc.PayableInvoiceId
GROUP BY takeDown.ContractId


UPDATE #TotalProgressFundingAmount SET FullCreditBalance = ABS(FullCreditBalance) + ABS([NoContractBalance])
FROM #TotalProgressFundingAmount funding
INNER JOIN #TotalTakeDownAmount takeDownAmount ON funding.ContractId = takeDownAmount.ContractId

UPDATE #TotalProgressFundingAmount SET FullCreditBalance = ABS(FullCreditBalance) + t.Amount
FROM #TotalProgressFundingAmount funding
INNER JOIN
(
    SELECT pid.ContractId
         , ABS(SUM(pid.Amount_Amount)) AS Amount
    FROM #PayableInvoiceDetails pid
         LEFT JOIN #TakeDownPayableInvoiceDetails takeDown ON pid.PayableInvoiceId = takeDown.PayableInvoiceId
    WHERE takeDown.OriginalPayableInvoiceId IS NULL
          AND (pid.Status = 'Pending' AND pid.IsMigratedContract = 'No') 
	GROUP BY pid.ContractId
) AS t ON funding.ContractId = t.ContractId;


SELECT DisbursementRequestId
	 , SUM(ABS(Amount_Amount)) AS [ProgressPaymentCreditsAmountApplied]
	 , MAX(PayableId) AS Sourceid
INTO #DisbursementRequestPayableDetails 
FROM #TakeDownPayableInvoiceDetails
WHERE Status = 'Completed'
GROUP BY DisbursementRequestId



CREATE NONCLUSTERED INDEX IX_Id ON #TotalTakeDownAmount(ContractId);

UPDATE funding SET TotalCreditBalance = TotalCreditBalance + [PendingProgressPaymentCreditsAmount]
FROM #TotalProgressFundingAmount funding
INNER JOIN #TotalTakeDownAmount takeDown ON funding.ContractId = takeDown.ContractId


SELECT ContractId
     , COUNT(PayableInvoiceId) AS [NoOfFundings]
     , MIN(DueDate) AS DueDate
	 , SUM(InvoiceTotal_Amount) AS InvoiceTotal_Amount
INTO #NoOfFundings
FROM
(
SELECT ContractId
     , PayableInvoiceId
     , DueDate
	 , InvoiceTotal_Amount
FROM #PayableInvoiceDetails
) AS t
GROUP BY ContractId;

CREATE NONCLUSTERED INDEX IX_Id ON #NoOfFundings(ContractId);

SELECT ContractId
     , COUNT(DISTINCT PayableInvoiceId) AS [NoOfTakeDowns]
INTO #NoOfTakeDowns
FROM #TakeDownPayableInvoiceDetails
GROUP BY ContractId;

CREATE NONCLUSTERED INDEX IX_Id ON #NoOfTakeDowns(ContractId);

SELECT ContractId
     , EntryItemId
     , SUM(DebitAmount) DebitAmount
     , SUM(CreditAmount) CreditAmount
     , SourceId
     , GLJournalId
	 , DisbursementRequestId
INTO #DisbursementGL
FROM
(
    SELECT DISTINCT glei.Id AS EntryItemId
         , CASE
               WHEN gljd.IsDebit = 1
               THEN gljd.Amount_Amount
               ELSE 0.00
           END DebitAmount
         , CASE
               WHEN gljd.IsDebit = 0
               THEN gljd.Amount_Amount
               ELSE 0.00
           END CreditAmount
         , gljd.SourceId
         , gljd.GLJournalId
         , pid.ContractId
		 , pid.DisbursementRequestId
    FROM GLJournalDetails gljd
         INNER JOIN GLTemplateDetails gltd ON gltd.Id = gljd.GLTemplateDetailId
         INNER JOIN GLEntryItems glei ON glei.Id = gltd.EntryItemId
         INNER JOIN GLTransactionTypes gltt ON glei.GLTransactionTypeId = gltt.Id
         INNER JOIN #PayableInvoiceDetails pid ON pid.DisbursementRequestId = gljd.EntityId
                                                  AND EntityType = 'DisbursementRequest'
) AS T
GROUP BY ContractId
       , EntryItemId
       , SourceId
       , GLJournalId
	   , DisbursementRequestId;

CREATE NONCLUSTERED INDEX IX_Id ON #DisbursementGL(ContractId);

SELECT t.ContractId
     , SUM(ProgressFundingAmount_Credit - ProgressFundingAmount_Debit) AS ProgressFundingAmount_GL
INTO #GLJournalDetails
FROM
(
    SELECT gltb.ContractId
         , gltb.DebitAmount AS ProgressFundingAmount_Debit
         , gltb.CreditAmount AS ProgressFundingAmount_Credit
		, gltb.SourceId
    FROM #DisbursementGL gltb
         INNER JOIN GLEntryItems gle ON gltb.EntryItemId = gle.Id
         INNER JOIN GLTransactionTypes gltt ON gle.GLTransactionTypeId = gltt.Id
	WHERE gle.Name IN('DisbursementPayable')
		  AND gltt.Name IN ('Disbursement')
) AS T
GROUP BY t.ContractId;


CREATE NONCLUSTERED INDEX IX_Id ON #GLJournalDetails(ContractId);

MERGE #GLJournalDetails AS target
USING (SELECT DISTINCT 
              funding.ContractId
            , funding.TotalProgressFundingAmount AS Amount
       FROM #TotalProgressFundingAmount funding
            INNER JOIN #EligibleContracts ec ON ec.ContractId = funding.ContractId
            LEFT JOIN #GLJournalDetails gl ON funding.ContractId = gl.ContractId
       WHERE ec.IsMigratedContract = 'Yes') AS source
ON (target.ContractId = source.ContractId)
	WHEN MATCHED 
	THEN UPDATE SET target.ProgressFundingAmount_GL = Amount
	WHEN NOT MATCHED 
	THEN INSERT (ContractId, ProgressFundingAmount_GL)
	     VALUES(source.ContractId, source.Amount);
			

SELECT t.DisbursementRequestId
     , SUM(ProgressFundingAmount_Credit - ProgressFundingAmount_Debit) AS ProgressFundingAmount_GL
	 , MAX(t.SourceId) AS SourceId
INTO #DisbursementRequestGLJournalDetails
FROM
(
    SELECT gltb.ContractId
         , gltb.DebitAmount AS ProgressFundingAmount_Debit
         , gltb.CreditAmount AS ProgressFundingAmount_Credit
		 , gltb.DisbursementRequestId
		 , gltb.SourceId
    FROM #DisbursementGL gltb
         INNER JOIN GLEntryItems gle ON gltb.EntryItemId = gle.Id
         INNER JOIN GLTransactionTypes gltt ON gle.GLTransactionTypeId = gltt.Id
	WHERE gle.Name IN('DisbursementPayable')
		  AND gltt.Name IN ('Disbursement')
) AS T
GROUP BY t.DisbursementRequestId;

SELECT DISTINCT 
       ec.ContractId
     , dr.Id AS DisbursementRequestId
     , p.Id AS PayableId
     , takeDown.Amount_Amount
     , CAST(0 AS BIT) IsSyndicated
	 , takeDown.OriginalPayableInvoiceId
	 , takeDown.PayableInvoiceId
INTO #ProgressPaymentCredit
FROM #EligibleContracts ec
     INNER JOIN #TakeDownPayableInvoiceDetails takeDown ON ec.ContractId  = takeDown.ContractId
     INNER JOIN DisbursementRequestInvoices invoice ON invoice.InvoiceId = takeDown.PayableInvoiceId
                                                       AND invoice.IsActive = 1
     INNER JOIN DisbursementRequests dr ON dr.Id = invoice.DisbursementRequestId
                                           AND dr.Status = 'Completed'
     INNER JOIN DisbursementRequestPayables drp ON drp.DisbursementRequestId = dr.Id
     INNER JOIN Payables p ON p.Id = drp.PayableId
                              AND p.SourceTable = 'PayableInvoiceOtherCost'
                              AND p.SourceId = takeDown.Id
							  AND p.Status != 'InActive';

CREATE NONCLUSTERED INDEX IX_Id ON #ProgressPaymentCredit(DisbursementRequestId, PayableId);
CREATE NONCLUSTERED INDEX IX_ContractId ON #ProgressPaymentCredit(ContractId);

SELECT ppc.ContractId
     , CASE
           WHEN gl.IsDebit = 1
           THEN gl.Amount_Amount
           ELSE 0
       END AS DRDebitAmount
     , CASE
           WHEN gl.IsDebit = 0
           THEN gl.Amount_Amount
           ELSE 0
       END DRCreditAmount
     , gl.SourceId
	 , PPC.DisbursementRequestId
	 , ppc.PayableInvoiceId
INTO #ProgressPaymentCreditGL
FROM GLJournalDetails gl
     INNER JOIN GLTemplateDetails gtd ON gl.GLTemplateDetailId = gtd.Id
     INNER JOIN GLEntryItems gle ON gtd.EntryItemId = gle.Id
     INNER JOIN GLTransactionTypes gtt ON gle.GLTransactionTypeId = gtt.Id
     INNER JOIN #ProgressPaymentCredit ppc ON ppc.DisbursementRequestId = gl.EntityId
                                              AND GL.EntityType = 'DisbursementRequest'
											  AND ppc.PayableId = gl.SourceId
 WHERE gle.Name IN('DisbursementPayable')
		  AND gtt.Name IN ('Disbursement');

SELECT DisbursementRequestId
     , ABS(SUM(DRCreditAmount - DRDebitAmount)) AS DRAmount
	 , MAX(SourceId) AS SourceId
INTO #DisbursementRequestProgressPaymentCreditGLAmount
FROM #ProgressPaymentCreditGL
GROUP BY DisbursementRequestId;

CREATE NONCLUSTERED INDEX IX_Id ON #DisbursementRequestProgressPaymentCreditGLAmount(DisbursementRequestId);

SELECT ContractId
     , SUM(DRCreditAmount - DRDebitAmount) AS DRAmount
INTO #ProgressPaymentCreditGLAmount
FROM #ProgressPaymentCreditGL
GROUP BY ContractId;


CREATE NONCLUSTERED INDEX IX_ContractId ON #ProgressPaymentCreditGLAmount(ContractId);

SELECT ContractId
     , ABS(SUM(details.Amount_Amount)) AS Amount
INTO #DisbursementTableAndGL
FROM #DisbursementRequestProgressPaymentCreditGLAmount gl
     INNER JOIN #DisbursementRequestPayableDetails dr ON dr.DisbursementRequestId = gl.DisbursementRequestId
     INNER JOIN #TakeDownPayableInvoiceDetails details ON details.DisbursementRequestId = dr.DisbursementRequestId
WHERE gl.DRAmount = DR.ProgressPaymentCreditsAmountApplied
GROUP BY ContractId;
																																						
MERGE #ProgressPaymentCreditGLAmount AS GL
USING
(SELECT * FROM #DisbursementTableAndGL) AS TableAndGL
ON(GL.ContractId = TableAndGL.ContractId)
    WHEN MATCHED
    THEN UPDATE SET 
                    DRAmount = TableAndGL.Amount
    WHEN NOT MATCHED
    THEN
      INSERT(ContractId, DRAmount)
      VALUES(TableAndGL.ContractId, TableAndGL.Amount);

 CREATE NONCLUSTERED INDEX IX_Id ON #ProgressPaymentCreditGLAmount(ContractId);

SELECT ec.ContractId
     , r.TotalAmount_Amount
     , r.IsGLPosted
     , r.TotalBalance_Amount
	 , r.Id
	 , r.PaymentScheduleId
INTO #Receivables
FROM #EligibleContracts ec
     INNER JOIN Receivables r ON ec.ContractId = r.EntityId
                                 AND r.EntityType = 'CT'
     INNER JOIN ReceivableCodes rc ON r.ReceivableCodeId = rc.Id
     INNER JOIN ReceivableTypes rt ON rt.Id = rc.ReceivableTypeId
WHERE r.IsDummy = 0
      AND r.FunderId IS NULL
      AND r.IsActive = 1
      AND rt.Name = 'LoanInterest';


CREATE NONCLUSTERED INDEX IX_ContractId ON #Receivables(ContractId);


SELECT ec.ContractId
     , SUM(r.TotalAmount_Amount) AS [TotalInterestReceivableGenerated]
     , SUM(CASE
               WHEN r.IsGLPosted = 1
               THEN r.TotalAmount_Amount
               ELSE 0.00
           END) AS [InterestReceivablesGLPosted]
     , SUM(CASE
               WHEN r.IsGLPosted = 0
               THEN r.TotalAmount_Amount
               ELSE 0.00
           END) AS [InterestReceivablesNotGLPosted]
     , SUM(CASE
               WHEN r.IsGLPosted = 0
                    AND r.TotalAmount_Amount != r.TotalBalance_Amount
               THEN r.TotalAmount_Amount - r.TotalBalance_Amount
               ELSE 0.00
           END) AS [InterestReceivablesPrepaid]
     , SUM(CASE
               WHEN r.IsGLPosted = 1
               THEN r.TotalBalance_Amount
               ELSE 0.00
           END) AS [InterestReceivablesOSAR]
INTO #ReceivableDetails
FROM #EligibleContracts ec
     INNER JOIN #Receivables r ON ec.ContractId = r.ContractId
GROUP BY ec.ContractId;


CREATE NONCLUSTERED INDEX IX_ContractId ON #ReceivableDetails(ContractId);


SELECT ec.ContractId
     , SUM(CASE
           WHEN ReceiptClassification IN('Cash', 'NonAccrualNonDSL')
                AND rt.ReceiptTypeName NOT IN('PayableOffset', 'SecurityDeposit', 'EscrowRefund')
           THEN rard.AmountApplied_Amount
           ELSE 0
       END) AS CashPosted
     , SUM(CASE
           WHEN ReceiptClassification NOT IN('Cash', 'NonAccrualNonDSL')
                OR rt.ReceiptTypeName IN('PayableOffset', 'SecurityDeposit', 'EscrowRefund')
           THEN rard.AmountApplied_Amount
           ELSE 0
       END) AS NonCashPosted
INTO #ReceiptDetails
FROM #EligibleContracts ec
     JOIN #Receivables r ON r.ContractId = ec.ContractId
     JOIN ReceivableDetails rd ON rd.ReceivableId = r.Id
     JOIN ReceiptApplicationReceivableDetails rard ON rard.ReceivableDetailId = rd.Id
     JOIN ReceiptApplications ra ON ra.Id = rard.ReceiptApplicationId
     JOIN Receipts receipt ON receipt.Id = ra.ReceiptId
     JOIN ReceiptTypes rt ON rt.Id = Receipt.TypeId
     LEFT JOIN LoanPaymentSchedules lps ON r.PaymentScheduleId = lps.Id
WHERE receipt.Status IN('Posted', 'Completed')
     AND rard.IsActive = 1
GROUP BY ec.ContractId;
				
				 
SELECT t.ContractId AS ContractId
     , SUM(t.PrepaidPrincipalReceivable_Credit - t.PrepaidInterestReceivable_Debit) [GLPrepaidInterest_GL]
     , SUM(t.OSAR_Debit - t.OSAR_Credit) [OSAR_GL]
     , SUM(t.TotalCashPaid_Credit - t.TotalCashPaid_Debit) [CashPaid_GL]
     , SUM(t.TotalNonCashPaid_Credit - t.TotalNonCashPaid_Debit) [NonCashPaid_GL]
INTO #GLJournalValues
FROM
(
    SELECT ec.ContractId
         , CASE
               WHEN((gle.Name = 'PrePaidInterestReceivable' AND mgle.Name IS NULL)
                    OR (gle.Name = 'Receivable' AND mgle.Name = 'PrePaidInterestReceivable'))
                   AND gld.IsDebit = 0
               THEN gld.Amount_Amount
               ELSE 0
           END PrepaidPrincipalReceivable_Credit
         , CASE
               WHEN((gle.Name = 'PrePaidInterestReceivable' AND mgle.Name IS NULL)
                    OR (gle.Name = 'Receivable' AND mgle.Name = 'PrePaidInterestReceivable'))
                   AND gld.IsDebit = 1
               THEN gld.Amount_Amount
               ELSE 0
           END PrepaidInterestReceivable_Debit
         , CASE
               WHEN gld.IsDebit = 1
                    AND ((gle.Name = 'InterestReceivable' AND mgle.Name IS NULL)
                         OR (gle.Name = 'Receivable' AND gltt.Name IN('ReceiptCash', 'ReceiptNonCash') AND mgle.Name = 'InterestReceivable'))
               THEN gld.Amount_Amount
               ELSE 0
           END OSAR_Debit
         , CASE
               WHEN gld.IsDebit = 0
                    AND ((gle.Name = 'InterestReceivable' AND mgle.Name IS NULL)
                         OR (gle.Name = 'Receivable' AND gltt.Name IN('ReceiptCash', 'ReceiptNonCash') AND mgle.Name = 'InterestReceivable'))
               THEN gld.Amount_Amount
               ELSE 0
           END OSAR_Credit
         , CASE
               WHEN gld.IsDebit = 0
                    AND gle.Name = 'Receivable'
                    AND gltt.Name IN('ReceiptCash')
                    AND mgle.Name IN('InterestReceivable', 'PrePaidInterestReceivable')
               THEN gld.Amount_Amount
               ELSE 0
           END TotalCashPaid_Credit
         , CASE
               WHEN gld.IsDebit = 1
                    AND gle.Name = 'Receivable'
                    AND gltt.Name IN('ReceiptCash')
                    AND mgle.Name IN('InterestReceivable', 'PrePaidInterestReceivable')
               THEN gld.Amount_Amount
               ELSE 0
           END TotalCashPaid_Debit
         , CASE
               WHEN gld.IsDebit = 0
                    AND gle.Name = 'Receivable'
                    AND gltt.Name IN('ReceiptNonCash')
                    AND mgle.Name IN('InterestReceivable', 'PrePaidInterestReceivable')
               THEN gld.Amount_Amount
               ELSE 0
           END TotalNonCashPaid_Credit
         , CASE
               WHEN gld.IsDebit = 1
                    AND gle.Name = 'Receivable'
                    AND gltt.Name IN('ReceiptNonCash')
                    AND mgle.Name IN('InterestReceivable', 'PrePaidInterestReceivable')
               THEN gld.Amount_Amount
               ELSE 0
           END TotalNonCashPaid_Debit
    FROM #EligibleContracts ec
         INNER JOIN GLJournalDetails gld ON gld.EntityId = ec.ContractId
                                            AND gld.EntityType = 'Contract'
         INNER JOIN GLTemplateDetails gltd ON gltd.Id = gld.GLTemplateDetailId
         INNER JOIN GLEntryItems gle ON gle.Id = gltd.EntryItemId
         INNER JOIN GLTransactionTypes gltt ON gle.GLTransactionTypeId = gltt.Id
         LEFT JOIN GLTemplateDetails mgltd ON mgltd.Id = gld.MatchingGLTemplateDetailId
         LEFT JOIN GLEntryItems mgle ON mgle.Id = mgltd.EntryItemId
         LEFT JOIN GLTransactionTypes mgltt ON mgle.GLTransactionTypeId = mgltt.Id
) AS t
GROUP BY t.ContractId;


SELECT DISTINCT pid.ContractId, pid.PayableInvoiceId, ppc.DisbursementRequestId, pid.DisbursementRequestId AS OriginalDisbursementRequestId
INTO #PayableInvoiceIds
FROM #PayableInvoiceDetails pid 
LEFT JOIN #ProgressPaymentCredit ppc ON pid.ContractId = ppc.ContractId AND pid.PayableInvoiceId = ppc.OriginalPayableInvoiceId

CREATE NONCLUSTERED INDEX IX_Id ON #PayableInvoiceIds(PayableInvoiceId);

CREATE NONCLUSTERED INDEX IX_ContractId ON #PayableInvoiceIds(ContractId);

CREATE NONCLUSTERED INDEX IX_DisbursementRequestId ON #PayableInvoiceIds(DisbursementRequestId);

SELECT PayableInvoiceId
     , SUM(CASE WHEN Status = 'Completed' AND IsMigratedContract = 'No' 
				THEN ABS(Amount_Amount)
				WHEN IsMigratedContract = 'Yes' AND (DisbursementRequestId IS NULL AND (PayableStatus =' Approved' OR PayableIsGLPosted = 1))
				THEN ABS(InvoiceTotal_Amount)
				ELSE 0.00 
		   END) AS TotalProgressFundingAmountApplied
     , SUM(ABS(Amount_Amount)) AS ProgressFundingAmount
     , SUM(ABS(CreditBalance_Amount)) AS TotalCreditBalance
     , SUM(ABS(CreditBalance_Amount)) AS FullCreditBalance
	 , SUM(ABS(OriginationRestoredAmount)) AS OriginationRestored
INTO #PayableInvoiceAmount
FROM #PayableInvoiceDetails
GROUP BY PayableInvoiceId;

CREATE NONCLUSTERED INDEX IX_Id ON #PayableInvoiceAmount(PayableInvoiceId);

SELECT t.PayableInvoiceId
     , SUM(ProgressFundingAmount_Credit - ProgressFundingAmount_Debit) AS ProgressFundingAmount_GL
INTO #PayableInvoiceGLJournalDetails
FROM
(
    SELECT pid.PayableInvoiceId
         , gltb.DebitAmount AS ProgressFundingAmount_Debit
         , gltb.CreditAmount AS ProgressFundingAmount_Credit
    FROM #DisbursementGL gltb
		 INNER JOIN #PayableInvoiceIds pid ON gltb.DisbursementRequestId = pid.OriginalDisbursementRequestId
         INNER JOIN GLEntryItems gle ON gltb.EntryItemId = gle.Id
         INNER JOIN GLTransactionTypes gltt ON gle.GLTransactionTypeId = gltt.Id
	WHERE gle.Name IN('DisbursementPayable')
          AND gltt.Name = 'Disbursement'
) AS T
GROUP BY t.PayableInvoiceId;

CREATE NONCLUSTERED INDEX IX_Id ON #PayableInvoiceGLJournalDetails(PayableInvoiceId);


SELECT OriginalPayableInvoiceId AS PayableInvoiceId
	 , SUM(CASE WHEN Status = 'Completed' AND Status IS NOT NULL 
				THEN ABS(Amount_Amount) - ABS(Balance_Amount) 
				ELSE 0.00 
		   END) AS [ProgressPaymentCreditsAmountApplied]
	 , SUM(CASE WHEN Status != 'InActive' AND Status IS NOT NULL THEN ABS(Amount_Amount) ELSE 0.00 END) AS [ProgressPaymentCreditsAmount]
	 , SUM(CASE WHEN ((pioc.SyndicationType = 'FullSale' AND DisbursementRequestId IS NOT NULL) OR pioc.SyndicationType != 'FullSale' OR pioc.SyndicationType IS NULL) AND (Status = 'Pending' OR Status IS NULL) 
					 AND takeDown.IsMigratedContract = 'No'
			    THEN ABS(PayableInvoiceOtherCostAmount) 
			    WHEN (pioc.SyndicationType != 'FullSale' OR pioc.SyndicationType IS NULL) AND Status IS NULL 
					 AND takeDown.IsMigratedContract = 'Yes'
					 AND takeDown.PayableStatus != 'InActive'
					 AND (takeDown.PayableIsGLPosted = 0 OR takeDown.PayableStatus NOT IN ('Approved'))
				THEN ABS(PayableInvoiceOtherCostAmount) 
				ELSE 0.00 
			END) AS [PendingProgressPaymentCreditsAmount]
     , SUM(CASE WHEN pioc.SyndicationType IS NULL AND Status IS NULL AND DisbursementRequestId IS NULL THEN ABS(Balance_Amount) ELSE 0.00 END) AS [NoContractBalance]
	 , DATEADD(DAY, -1, MAX(InterimInterestStartDate)) AS InterimInterestStartDate
INTO #TotalPayableInvoiceTakeDownAmount
FROM #TakeDownPayableInvoiceDetails takeDown
LEFT JOIN #ProgressCreditDetails pioc ON takeDown.PayableInvoiceId = pioc.PayableInvoiceId
GROUP BY OriginalPayableInvoiceId



CREATE NONCLUSTERED INDEX IX_Id ON #TotalPayableInvoiceTakeDownAmount(PayableInvoiceId);

UPDATE funding SET TotalCreditBalance = TotalCreditBalance + [PendingProgressPaymentCreditsAmount] + [NoContractBalance]
FROM #PayableInvoiceAmount funding
INNER JOIN #TotalPayableInvoiceTakeDownAmount takeDown ON funding.PayableInvoiceId = takeDown.PayableInvoiceId
 
UPDATE funding SET FullCreditBalance = FullCreditBalance + ABS([NoContractBalance])
FROM #PayableInvoiceAmount funding
INNER JOIN #TotalPayableInvoiceTakeDownAmount takeDown ON funding.PayableInvoiceId = takeDown.PayableInvoiceId
  
UPDATE #PayableInvoiceAmount SET FullCreditBalance = ABS(FullCreditBalance) + t.Amount
FROM #PayableInvoiceAmount funding
INNER JOIN
(
    SELECT pid.PayableInvoiceId
         , ABS(SUM(pid.Amount_Amount)) AS Amount
    FROM #PayableInvoiceDetails pid
         LEFT JOIN #TotalPayableInvoiceTakeDownAmount takeDown ON pid.PayableInvoiceId = takeDown.PayableInvoiceId
    WHERE takeDown.PayableInvoiceId IS NULL
          AND pid.Status = 'Pending'
          AND pid.PayableId IS NULL
	GROUP BY pid.PayableInvoiceId
) AS t ON funding.PayableInvoiceId = t.PayableInvoiceId;


SELECT pid.PayableInvoiceId
     , ABS(SUM(DRDebitAmount - DRCreditAmount)) AS DRAmount
INTO #ProgressPaymentCreditPayableInvoiceGLAmount
FROM #ProgressPaymentCreditGL gl
INNER JOIN #PayableInvoiceIds pid ON gl.DisbursementRequestId = pid.DisbursementRequestId
GROUP BY pid.PayableInvoiceId;

CREATE NONCLUSTERED INDEX IX_Id ON #ProgressPaymentCreditPayableInvoiceGLAmount(PayableInvoiceId); 

SELECT pid.PayableInvoiceId
     , ABS(SUM(pid.Amount_Amount)) AS Amount
INTO #PayableInvoiceDisbursementTableAndGL
FROM #DisbursementRequestProgressPaymentCreditGLAmount gl
     INNER JOIN #DisbursementRequestPayableDetails dr ON dr.DisbursementRequestId = gl.DisbursementRequestId
	 INNER JOIN #PayableInvoiceDetails pid ON gl.DisbursementRequestId = pid.DisbursementRequestId
WHERE gl.DRAmount = DR.ProgressPaymentCreditsAmountApplied
GROUP BY pid.PayableInvoiceId;

MERGE #ProgressPaymentCreditPayableInvoiceGLAmount AS GL
USING
(SELECT * FROM #PayableInvoiceDisbursementTableAndGL) AS TableAndGL
ON(GL.PayableInvoiceId = TableAndGL.PayableInvoiceId)
    WHEN MATCHED
    THEN UPDATE SET 
                    DRAmount = TableAndGL.Amount
    WHEN NOT MATCHED
    THEN
      INSERT(PayableInvoiceId, DRAmount)
      VALUES(TableAndGL.PayableInvoiceId, TableAndGL.Amount);

SELECT pid.PayableInvoiceId
     , SUM(CASE
               WHEN la.CapitalizationType = 'CapitalizedProgressPayment'
               THEN OriginalCapitalizedAmount_Amount
			   WHEN la.CapitalizationType = '_'
               THEN CapitalizedProgressPayment_Amount
			   ELSE 0.00
           END) AS Amount
INTO #LeaseInterimInterestCapitalization
FROM #ProgressCreditDetails pid
     INNER JOIN LeaseFinances lf ON lf.ContractId = pid.ContractId
     INNER JOIN LeaseAssets la ON la.LeaseFinanceId = lf.Id
WHERE (la.IsActive = 1 OR (la.IsActive = 0 AND la.terminationdate IS NOT NULL ))
      AND la.IsApproved = 1
      AND lf.IsCurrent = 1
	  AND lf.BookingStatus IN ('Commenced', 'FullyPaidOff')
 GROUP BY pid.PayableInvoiceId;


CREATE NONCLUSTERED INDEX IX_Id ON #LeaseInterimInterestCapitalization(PayableInvoiceId);

SELECT pid.PayableInvoiceId
     , SUM(lci.Amount_Amount) AS Amount
INTO #LoanInterimInterestCapitalization
FROM #ProgressCreditDetails pid
     INNER JOIN LoanFinances lf ON lf.ContractId = pid.ContractId
	 INNER JOIN LoanCapitalizedInterests lci ON lci.LoanFinanceId = lf.Id
WHERE lci.IsActive = 1
      AND lf.IsCurrent = 1
	  AND lci.GLJournalId IS NOT NULL
	  AND lci.Source = 'ProgressLoan'
GROUP BY pid.PayableInvoiceId;

CREATE NONCLUSTERED INDEX IX_Id ON #LoanInterimInterestCapitalization(PayableInvoiceId);

SELECT takeDown.ContractId
     , SUM(ISNULL(loanci.Amount, 0.00) + ISNULL(leaseci.Amount, 0.00)) AS Amount
INTO #TotalInterimInterestCapitalization
FROM #ProgressCreditDetails details
     INNER JOIN #TakeDownPayableInvoiceDetails takeDown ON details.PayableInvoiceId = takeDown.PayableInvoiceId
     LEFT JOIN #LoanInterimInterestCapitalization loanci ON details.PayableInvoiceId = loanci.PayableInvoiceId
     LEFT JOIN #LeaseInterimInterestCapitalization leaseci ON details.PayableInvoiceId = leaseci.PayableInvoiceId
GROUP BY takeDown.ContractId;

CREATE NONCLUSTERED INDEX IX_Id ON #TotalInterimInterestCapitalization(ContractId);


SELECT PayableInvoiceId
	 , SUM(CASE WHEN Status = 'Completed' THEN ABS(Amount_Amount) - ABS(Balance_Amount) ELSE 0.00 END) AS [ProgressPaymentCreditsAmountApplied]
	 , SUM(CASE WHEN Status != 'InActive' THEN ABS(Amount_Amount) ELSE 0.00 END) AS [ProgressPaymentCreditsAmount]
	 , SUM(CASE WHEN Status = 'Pending' THEN ABS(Amount_Amount) ELSE 0.00 END) AS [PendingProgressPaymentCreditsAmount]
INTO #ProgressCreditDetailsTakeDownAmount 
FROM #TakeDownPayableInvoiceDetails
GROUP BY PayableInvoiceId
 
 
SELECT la.ContractId
     , MAX(lam.CurrentLeaseFinanceId) AS RenewalFinanceId
INTO #RenewalDetails
FROM #ProgressCreditDetails la
     INNER JOIN LeaseFinances lf ON lf.ContractId = la.ContractId
     INNER JOIN LeaseAmendments lam ON lf.Id = lam.CurrentLeaseFinanceId
                                       AND lam.AmendmentType = 'Renewal'
                                       AND lam.LeaseAmendmentStatus = 'Approved'
GROUP BY la.ContractId;


SELECT DISTINCT 
       pcd.PayableInvoiceId
     , gljd.GLJournalId
     , CASE
           WHEN gljd.IsDebit = 1
           THEN gljd.Amount_Amount
           ELSE 0.00
       END DebitAmount
     , CASE
           WHEN gljd.IsDebit = 0
           THEN gljd.Amount_Amount
           ELSE 0.00
       END CreditAmount
     , pcd.ContractId
     , glei.Name AS GLEntryItemName
     , gltt.Name AS GLTransactionName
     , mgle.Name AS MatchingGLEntryItemName
     , mgltt.Name AS MatchingGLTransactionName
	 , gljd.SourceId
INTO #PayableGLCreditDetails
FROM GLJournalDetails gljd
     INNER JOIN GLTemplateDetails gltd ON gltd.Id = gljd.GLTemplateDetailId
     INNER JOIN GLEntryItems glei ON glei.Id = gltd.EntryItemId
     INNER JOIN GLTransactionTypes gltt ON glei.GLTransactionTypeId = gltt.Id
     INNER JOIN #ProgressCreditDetails pcd ON pcd.ContractId = gljd.EntityId
     LEFT JOIN GLTemplateDetails mgltd ON mgltd.Id = gljd.MatchingGLTemplateDetailId
     LEFT JOIN GLEntryItems mgle ON mgle.Id = mgltd.EntryItemId
     LEFT JOIN GLTransactionTypes mgltt ON mgle.GLTransactionTypeId = mgltt.Id
WHERE gljd.EntityType = 'Contract';

CREATE NONCLUSTERED INDEX IX_Id ON #PayableGLCreditDetails(PayableInvoiceId);

SELECT PayableInvoiceId
     , SUM(CreditAmount - DebitAmount) AS Amount
INTO #PayableGLCreditAmount
FROM
(
    SELECT PayableInvoiceId
         , DebitAmount
         , CreditAmount
    FROM #PayableGLCreditDetails pgl
         LEFT JOIN #RenewalDetails rd ON rd.ContractId = pgl.ContractId
    WHERE MatchingGLTransactionName = 'LoanIncomeRecognition'
          AND MatchingGLEntryItemName = 'AccruedInterest'
		  AND ((GLTransactionName = 'LoanBooking' AND GLEntryItemName = 'AccruedInterestCapitalized')
				OR (GLEntryItemName = 'CapitalizedInterimInterest' AND GLTransactionName IN('CapitalLeaseBooking', 'OperatingLeaseBooking')
				AND ((rd.ContractId IS NOT NULL AND pgl.SourceId >= rd.RenewalFinanceId) OR rd.ContractId IS NULL)))
) AS t
GROUP BY t.PayableInvoiceId;
 
 CREATE NONCLUSTERED INDEX IX_Id ON #PayableGLCreditAmount(PayableInvoiceId);

SELECT ContractId
     , SUM(CreditAmount - DebitAmount) AS Amount
INTO #CapitalizationGLCreditAmount
FROM
(
    SELECT takeDown.ContractId
         , DebitAmount
         , CreditAmount
    FROM #PayableGLCreditDetails pgl
		 INNER JOIN #ProgressCreditDetails pcd ON pcd.PayableInvoiceId = pgl.PayableInvoiceId
		  INNER JOIN #TakeDownPayableInvoiceDetails takeDown ON pcd.PayableInvoiceId = takeDown.PayableInvoiceId
		 LEFT JOIN #RenewalDetails rd ON rd.ContractId = pgl.ContractId
    WHERE MatchingGLTransactionName = 'LoanIncomeRecognition'
          AND MatchingGLEntryItemName = 'AccruedInterest'
		  AND ((GLTransactionName = 'LoanBooking' AND GLEntryItemName = 'AccruedInterestCapitalized')
				OR (GLEntryItemName = 'CapitalizedInterimInterest' AND GLTransactionName IN('CapitalLeaseBooking', 'OperatingLeaseBooking')
				AND ((rd.ContractId IS NOT NULL AND pgl.SourceId >= rd.RenewalFinanceId) OR rd.ContractId IS NULL)))
) AS t
GROUP BY ContractId;

 CREATE NONCLUSTERED INDEX IX_Id ON #CapitalizationGLCreditAmount(ContractId);

SELECT PayableInvoiceId
     , SUM(DRCreditAmount - DRDebitAmount) AS DRAmount
INTO #ProgressCreditDetailsGLAmount
FROM #ProgressPaymentCreditGL gl
GROUP BY gl.PayableInvoiceId;

 CREATE NONCLUSTERED INDEX IX_Id ON #ProgressCreditDetailsGLAmount(PayableInvoiceId);

-- For Full Sale Syndication, DR is not generated
MERGE #ProgressPaymentCreditGLAmount AS GL
USING
(SELECT takeDown.ContractId
				, SUM(ABS(ISNULL(takeDown.PayableInvoiceOtherCostAmount, 0.00))) AS Amount
			FROM #TakeDownPayableInvoiceDetails takeDown
			INNER JOIN #ProgressCreditDetails pcd ON pcd.PayableInvoiceId = takeDown.PayableInvoiceId
			WHERE pcd.SyndicationType = 'FullSale'
				  AND takeDown.Amount_Amount IS NULL
			GROUP BY takeDown.ContractId) AS TableAndGL
ON(GL.ContractId = TableAndGL.ContractId)
    WHEN MATCHED
    THEN UPDATE SET 
                    DRAmount = DRAmount + TableAndGL.Amount
    WHEN NOT MATCHED
    THEN
      INSERT(ContractId, DRAmount)
      VALUES(TableAndGL.ContractId, TableAndGL.Amount);

-- Updating for takeDown amount for migration and syndication scenario
UPDATE takeDown
SET ProgressPaymentCreditsAmount = ProgressPaymentCreditsAmount + t.Amount,
	ProgressPaymentCreditsAmountApplied = ProgressPaymentCreditsAmountApplied + t.AmountApplied
FROM #TotalTakeDownAmount takeDown
INNER JOIN (SELECT takeDown.ContractId
				, SUM(ABS(ISNULL(takeDown.PayableInvoiceOtherCostAmount, 0.00))) AS Amount
				, SUM(CASE WHEN (takeDown.Status = 'Completed' AND takeDown.Status IS NOT NULL)
							    OR (pcd.SyndicationType = 'FullSale' AND takeDown.DisbursementRequestId IS NULL)
						   THEN ABS(ISNULL(takeDown.PayableInvoiceOtherCostAmount, 0.00)) 
						   ELSE 0.00 
					  END) AS AmountApplied
			FROM #TakeDownPayableInvoiceDetails takeDown
			INNER JOIN #ProgressCreditDetails pcd ON pcd.PayableInvoiceId = takeDown.PayableInvoiceId
			WHERE takeDown.Amount_Amount IS NULL
				  OR ((pcd.SyndicationType = 'FullSale' OR takeDown.IsMigratedContract = 'Yes') AND takeDown.DisbursementRequestId IS NULL)
			GROUP BY takeDown.ContractId) AS t ON t.ContractId = takeDown.ContractId;

-- Updating for takeDown amount for migration and syndication scenario
UPDATE takeDown
SET ProgressPaymentCreditsAmount = ProgressPaymentCreditsAmount + t.Amount,
	ProgressPaymentCreditsAmountApplied = ProgressPaymentCreditsAmountApplied + t.AmountApplied
FROM #TotalPayableInvoiceTakeDownAmount takeDown
INNER JOIN (SELECT takeDown.OriginalPayableInvoiceId
				, SUM(ABS(ISNULL(takeDown.PayableInvoiceOtherCostAmount, 0.00))) AS Amount
				, SUM(CASE WHEN (takeDown.Status = 'Completed' AND takeDown.Status IS NOT NULL)
								OR (pcd.SyndicationType = 'FullSale' AND takeDown.DisbursementRequestId IS NULL)
						   THEN ABS(ISNULL(takeDown.PayableInvoiceOtherCostAmount, 0.00)) 
						   ELSE 0.00 
					  END) AS AmountApplied
			FROM #TakeDownPayableInvoiceDetails takeDown
			INNER JOIN #ProgressCreditDetails pcd ON pcd.PayableInvoiceId = takeDown.PayableInvoiceId
			WHERE takeDown.Amount_Amount IS NULL
				  OR ((pcd.SyndicationType = 'FullSale' OR takeDown.IsMigratedContract = 'Yes') AND takeDown.DisbursementRequestId IS NULL)
			GROUP BY takeDown.OriginalPayableInvoiceId) AS t ON t.OriginalPayableInvoiceId = takeDown.PayableInvoiceId;

-- Updating for takeDown amount for migration and syndication scenario
MERGE #ProgressPaymentCreditPayableInvoiceGLAmount AS GL
USING
(SELECT takeDown.OriginalPayableInvoiceId
				, SUM(ABS(ISNULL(takeDown.PayableInvoiceOtherCostAmount, 0.00))) AS Amount
			FROM #TakeDownPayableInvoiceDetails takeDown
			INNER JOIN #ProgressCreditDetails pcd ON pcd.PayableInvoiceId = takeDown.PayableInvoiceId
			WHERE (takeDown.Amount_Amount IS NULL 
				  AND Status = 'Completed') OR ((pcd.SyndicationType = 'FullSale' OR takeDown.IsMigratedContract = 'Yes') AND takeDown.DisbursementRequestId IS NULL)
			GROUP BY takeDown.OriginalPayableInvoiceId) AS TableAndGL
ON(GL.PayableInvoiceId = TableAndGL.OriginalPayableInvoiceId)
    WHEN MATCHED
    THEN UPDATE SET 
                    DRAmount -= TableAndGL.Amount
    WHEN NOT MATCHED
    THEN
      INSERT(PayableInvoiceId, DRAmount)
      VALUES(TableAndGL.OriginalPayableInvoiceId, TableAndGL.Amount);

-- Updating for takeDown amount for migration and syndication scenario
UPDATE takeDown
SET ProgressPaymentCreditsAmount = ProgressPaymentCreditsAmount + t.Amount,
	ProgressPaymentCreditsAmountApplied = ProgressPaymentCreditsAmountApplied + t.AmountApplied
FROM #ProgressCreditDetailsTakeDownAmount takeDown
INNER JOIN (SELECT takeDown.PayableInvoiceId
				, SUM(ABS(ISNULL(takeDown.PayableInvoiceOtherCostAmount, 0.00))) AS Amount
				, SUM(CASE WHEN (takeDown.Status = 'Completed' AND takeDown.Status IS NOT NULL)
								OR (pcd.SyndicationType = 'FullSale' AND takeDown.DisbursementRequestId IS NULL)
						   THEN ABS(ISNULL(takeDown.PayableInvoiceOtherCostAmount, 0.00)) 
						   ELSE 0.00 
					  END) AS AmountApplied
			FROM #TakeDownPayableInvoiceDetails takeDown
			INNER JOIN #ProgressCreditDetails pcd ON pcd.PayableInvoiceId = takeDown.PayableInvoiceId
			WHERE takeDown.Amount_Amount IS NULL 
				  OR ((pcd.SyndicationType = 'FullSale' OR takeDown.IsMigratedContract = 'Yes') AND takeDown.DisbursementRequestId IS NULL)
			GROUP BY takeDown.PayableInvoiceId) AS t ON t.PayableInvoiceId = takeDown.PayableInvoiceId;

-- For Full Sale Syndication, DR is not generated

MERGE #ProgressCreditDetailsGLAmount AS GL
USING
(SELECT takeDown.PayableInvoiceId
				, SUM(ABS(ISNULL(takeDown.PayableInvoiceOtherCostAmount, 0.00))) AS Amount
			FROM #TakeDownPayableInvoiceDetails takeDown
			INNER JOIN #ProgressCreditDetails pcd ON pcd.PayableInvoiceId = takeDown.PayableInvoiceId
			WHERE (takeDown.Amount_Amount IS NULL 
				  AND Status = 'Completed') OR (pcd.SyndicationType = 'FullSale' AND takeDown.DisbursementRequestId IS NULL)
			GROUP BY takeDown.PayableInvoiceId) AS TableAndGL
ON(GL.PayableInvoiceId = TableAndGL.PayableInvoiceId)
    WHEN MATCHED
    THEN UPDATE SET 
                    DRAmount -= TableAndGL.Amount
    WHEN NOT MATCHED
    THEN
      INSERT(PayableInvoiceId, DRAmount)
      VALUES(TableAndGL.PayableInvoiceId, TableAndGL.Amount);

-- Updating GL Amount with table at payable invoice level when it is matching at contract level
UPDATE gld SET ProgressFundingAmount_GL = ISNULL(pia.TotalProgressFundingAmountApplied, 0.00)
FROM #PayableInvoiceGLJournalDetails gld
INNER JOIN #PayableInvoiceIds pid ON gld.PayableInvoiceId = pid.PayableInvoiceId
INNER JOIN(
SELECT progressFunding.ContractId
FROM #TotalProgressFundingAmount progressFunding
     LEFT JOIN #GLJournalDetails gjd ON progressFunding.ContractId = gjd.ContractId
WHERE progressFunding.TotalProgressFundingAmount = ISNULL(gjd.ProgressFundingAmount_GL, 0.00)
) as t ON t.ContractId = pid.ContractId
LEFT JOIN #PayableInvoiceAmount pia ON pia.PayableInvoiceId = pid.PayableInvoiceId

-- Find the difference amount for DR and find the amount to update for the SourceId (Max PayableId)
SELECT gl.DisbursementRequestId
     , gl.SourceId
	 , GL.ProgressFundingAmount_GL - t.Amount AS AmountToUpdate
INTO #UpdatePayableInvoiceGLJournalDetails
FROM #DisbursementRequestGLJournalDetails gl
     INNER JOIN
(
    SELECT pid.DisbursementRequestId
         , SUM(pid.AmountToPay_Amount) AS Amount
    FROM #PayableInvoiceDetails pid
	INNER JOIN #DisbursementRequestGLJournalDetails detail ON pid.DisbursementRequestId = detail.DisbursementRequestId
	WHERE detail.SourceId != pid.PayableId
    GROUP BY pid.DisbursementRequestId
) AS t ON gl.DisbursementRequestId = t.DisbursementRequestId
WHERE GL.ProgressFundingAmount_GL != t.Amount;

-- Updating the amount for the SourceId (Max PayableId)
UPDATE detail SET ProgressFundingAmount_GL = gl.AmountToUpdate
FROM #PayableInvoiceGLJournalDetails detail
INNER JOIN #PayableInvoiceDetails pid ON detail.PayableInvoiceId = pid.PayableInvoiceId
INNER JOIN #UpdatePayableInvoiceGLJournalDetails gl ON gl.SourceId = pid.PayableId
													   AND gl.DisbursementRequestId = pid.DisbursementRequestId

-- Setting Table Value as GL Value where SourceId and PayableId do not match
UPDATE gld SET ProgressFundingAmount_GL = ISNULL(pia.TotalProgressFundingAmountApplied, 0.00)
FROM #PayableInvoiceGLJournalDetails gld
INNER JOIN
(
    SELECT pid.PayableInvoiceId
    FROM #UpdatePayableInvoiceGLJournalDetails gl
         INNER JOIN #PayableInvoiceDetails pid ON gl.DisbursementRequestId = pid.DisbursementRequestId
                                                  AND gl.SourceId != pid.PayableId
) AS t ON t.PayableInvoiceId = gld.PayableInvoiceId
     LEFT JOIN #PayableInvoiceAmount pia ON pia.PayableInvoiceId = gld.PayableInvoiceId;

MERGE #ProgressCreditDetailsGLAmount AS Source
USING (SELECT DISTINCT 
			   details.PayableInvoiceId
			 , ISNULL(amount.ProgressPaymentCreditsAmountApplied, 0.00) AS Amount
FROM #TakeDownPayableInvoiceDetails details
INNER JOIN 
(
	SELECT progressFunding.ContractId
	FROM #TotalProgressFundingAmount progressFunding
		 LEFT JOIN #GLJournalDetails gjd ON progressFunding.ContractId = gjd.ContractId
	WHERE progressFunding.TotalProgressFundingAmount = ISNULL(gjd.ProgressFundingAmount_GL, 0.00)
) AS t ON t.ContractId = details.ContractId
LEFT JOIN #ProgressCreditDetailsTakeDownAmount amount ON details.PayableInvoiceId = amount.PayableInvoiceId) AS Target
ON (Source.PayableInvoiceId = target.PayableInvoiceId)
WHEN MATCHED
	THEN UPDATE SET Source.DRAmount = Target.Amount
WHEN NOT MATCHED
		THEN
		INSERT(PayableInvoiceId, DRAmount)
		VALUES (target.PayableInvoiceId, target.Amount);

-- Find the difference amount for DR and find the amount to update for the SourceId (Max PayableId)
SELECT gl.DisbursementRequestId
     , gl.SourceId
	 , GL.ProgressFundingAmount_GL - t.Amount AS AmountToUpdate
INTO #UpdateTakeDownGLJournalDetails
FROM #DisbursementRequestGLJournalDetails gl
     INNER JOIN
(
    SELECT pid.DisbursementRequestId
         , SUM(pid.AmountToPay_Amount) AS Amount
    FROM #PayableInvoiceDetails pid
	INNER JOIN #DisbursementRequestGLJournalDetails detail ON pid.DisbursementRequestId = detail.DisbursementRequestId
	WHERE detail.SourceId != pid.PayableId
    GROUP BY pid.DisbursementRequestId
) AS t ON gl.DisbursementRequestId = t.DisbursementRequestId
WHERE GL.ProgressFundingAmount_GL != t.Amount;

-- Updating the amount for the SourceId (Max PayableId)
UPDATE GL SET DRAmount = updateGL.AmountToUpdate
FROM #ProgressCreditDetailsGLAmount GL
INNER JOIN #TakeDownPayableInvoiceDetails details ON details.PayableInvoiceId = GL.PayableInvoiceId
INNER JOIN #UpdateTakeDownGLJournalDetails updateGL ON updateGL.SourceId = details.Payableid
													   AND updateGL.DisbursementRequestId = details.DisbursementRequestId

-- Setting Table Value as GL Value where SourceId and PayableId do not match
UPDATE gld SET ProgressFundingAmount_GL = ISNULL(pia.ProgressPaymentCreditsAmountApplied, 0.00)
FROM #PayableInvoiceGLJournalDetails gld
INNER JOIN
(
    SELECT pid.PayableInvoiceId
    FROM #UpdateTakeDownGLJournalDetails gl
         INNER JOIN #TakeDownPayableInvoiceDetails pid ON gl.DisbursementRequestId = pid.DisbursementRequestId
                                                  AND gl.SourceId != pid.PayableId
) AS t ON t.PayableInvoiceId = gld.PayableInvoiceId
     LEFT JOIN #ProgressCreditDetailsTakeDownAmount pia ON pia.PayableInvoiceId = gld.PayableInvoiceId;

-- For Full Sale Syndication, DR is not generated. Setting GL Value as Table value
MERGE #ProgressPaymentCreditPayableInvoiceGLAmount AS Source
USING (SELECT DISTINCT
		      gld.PayableInvoiceId,
		      pia.ProgressPaymentCreditsAmountApplied AS Amount
	   FROM #ProgressPaymentCreditPayableInvoiceGLAmount gld
	   INNER JOIN #PayableInvoiceIds pid ON gld.PayableInvoiceId = pid.PayableInvoiceId
	   INNER JOIN(
	   SELECT takeDown.ContractId
	   FROM #TotalTakeDownAmount takeDown
	   	 LEFT JOIN #ProgressPaymentCreditGLAmount gjd ON takeDown.ContractId = gjd.ContractId
	   WHERE takeDown.ProgressPaymentCreditsAmountApplied = ISNULL(gjd.DRAmount, 0.00)) as t ON t.ContractId = pid.ContractId
	   LEFT JOIN #TotalPayableInvoiceTakeDownAmount pia ON pia.PayableInvoiceId = pid.PayableInvoiceId) AS Target
ON (Source.PayableInvoiceId = target.PayableInvoiceId)
WHEN MATCHED
	THEN UPDATE SET Source.DRAmount = Target.Amount
WHEN NOT MATCHED
		THEN
		INSERT(PayableInvoiceId, DRAmount)
		VALUES (target.PayableInvoiceId, target.Amount);

-- Find the difference amount for DR and find the amount to update for the SourceId (Max PayableId)
SELECT gl.DisbursementRequestId
     , gl.SourceId
	 , GL.ProgressFundingAmount_GL - t.Amount AS AmountToUpdate
INTO #UpdatePayableInvoicePPCGLJournalDetails
FROM #DisbursementRequestGLJournalDetails gl
     INNER JOIN
(
    SELECT pid.DisbursementRequestId
         , SUM(pid.AmountToPay_Amount) AS Amount
    FROM #PayableInvoiceDetails pid
	INNER JOIN #DisbursementRequestProgressPaymentCreditGLAmount detail ON pid.DisbursementRequestId = detail.DisbursementRequestId
	WHERE detail.SourceId != pid.PayableId
    GROUP BY pid.DisbursementRequestId
) AS t ON gl.DisbursementRequestId = t.DisbursementRequestId
WHERE GL.ProgressFundingAmount_GL != t.Amount;

-- Updating the amount for the SourceId (Max PayableId)
UPDATE GL SET DRAmount = updateGL.AmountToUpdate
FROM #ProgressPaymentCreditPayableInvoiceGLAmount GL
INNER JOIN #PayableInvoiceDetails details ON details.PayableInvoiceId = GL.PayableInvoiceId
INNER JOIN #UpdatePayableInvoicePPCGLJournalDetails updateGL ON updateGL.SourceId = details.Payableid
													   AND updateGL.DisbursementRequestId = details.DisbursementRequestId

-- Setting Table Value as GL Value where SourceId and PayableId do not match
UPDATE gld SET DRAmount = ISNULL(pia.ProgressPaymentCreditsAmountApplied, 0.00)
FROM #ProgressPaymentCreditPayableInvoiceGLAmount gld
INNER JOIN
(
    SELECT pid.PayableInvoiceId
    FROM #PayableInvoiceDetails pid  
         INNER JOIN #UpdatePayableInvoicePPCGLJournalDetails gl ON gl.DisbursementRequestId = pid.DisbursementRequestId
																   AND gl.SourceId != pid.PayableId
) AS t ON t.PayableInvoiceId = gld.PayableInvoiceId
     LEFT JOIN #TotalPayableInvoiceTakeDownAmount pia ON pia.PayableInvoiceId = gld.PayableInvoiceId;

UPDATE #TotalProgressFundingAmount SET TotalCreditBalance = 0.00
FROM #TotalProgressFundingAmount funding
INNER JOIN #EligibleContracts ec ON ec.ContractId = funding.ContractId
LEFT JOIN #GLJournalDetails gjd ON gjd.ContractId = funding.ContractId
WHERE ec.IsMigratedContract = 'Yes'
      AND ISNULL(ProgressFundingAmount_GL, 0.00) = 0.00

update pia SET TotalCreditBalance = 0.00
from #PayableInvoiceAmount pia
INNER JOIN #PayableInvoiceIds pid ON pia.PayableInvoiceId = pid.PayableInvoiceId
INNER JOIN #EligibleContracts ec ON ec.ContractId = pid.ContractId
LEFT JOIN #PayableInvoiceGLJournalDetails gjd ON gjd.PayableInvoiceId = pia.PayableInvoiceId
WHERE  ec.IsMigratedContract = 'Yes'
	   AND ISNULL(gjd.ProgressFundingAmount_GL, 0.00) = 0.00


-- BEGIN of handling of Origination Restored
SELECT MAX(pid.PayableInvoiceId) AS PayableInvoiceId
     , pid.ContractId
INTO #OriginationRestoredPayableInvoices
FROM #PayableInvoiceIds pid
     INNER JOIN #EligibleContracts ec ON ec.ContractId = pid.ContractId
     INNER JOIN PayableInvoiceOtherCosts pioc ON pioc.PayableInvoiceId = pid.PayableInvoiceId
                                                 AND Pioc.AllocationMethod = 'LoanDisbursement'
     INNER JOIN #PayableInvoiceDetails invoiceDetails ON invoiceDetails.PayableInvoiceOtherCostId = pioc.Id
WHERE invoiceDetails.Type = 'OriginationRestored'
GROUP BY pid.ContractId;

CREATE NONCLUSTERED INDEX IX_Id ON #OriginationRestoredPayableInvoices(PayableInvoiceId, ContractId);

SELECT pid.PayableInvoiceId
     , pid.ContractId
INTO #OriginationRestoredIds
FROM #PayableInvoiceIds pid
     INNER JOIN #EligibleContracts ec ON ec.ContractId = pid.ContractId
     INNER JOIN PayableInvoiceOtherCosts pioc ON pioc.PayableInvoiceId = pid.PayableInvoiceId
                                                 AND Pioc.AllocationMethod = 'LoanDisbursement'
     INNER JOIN #PayableInvoiceDetails invoiceDetails ON invoiceDetails.PayableInvoiceOtherCostId = pioc.Id
WHERE invoiceDetails.Type = 'OriginationRestored';


CREATE NONCLUSTERED INDEX IX_Id ON #OriginationRestoredIds(PayableInvoiceId);


UPDATE pia SET 
               TotalProgressFundingAmountApplied = t.TotalProgressFundingAmountApplied
             , ProgressFundingAmount = t.ProgressFundingAmount
             , TotalCreditBalance = t.TotalCreditBalance
             , FullCreditBalance = t.FullCreditBalance
			 , OriginationRestored = t.OriginationRestored
FROM #PayableInvoiceAmount pia
INNER JOIN (
		SELECT MAX(originationRestored.PayableInvoiceId) AS PayableInvoiceId
			  , SUM(pia.TotalProgressFundingAmountApplied) AS TotalProgressFundingAmountApplied
			  , SUM(ProgressFundingAmount) AS ProgressFundingAmount
			  , SUM(TotalCreditBalance) AS TotalCreditBalance
			  , SUM(FullCreditBalance) AS FullCreditBalance
			  , SUM(OriginationRestored) AS OriginationRestored
		FROM #PayableInvoiceAmount pia
		INNER JOIN #OriginationRestoredIds originationRestored ON pia.PayableInvoiceId = originationRestored.PayableInvoiceId
		GROUP BY originationRestored.ContractId) AS t ON t.PayableInvoiceId = pia.PayableInvoiceId


UPDATE gl SET ProgressFundingAmount_GL = t.ProgressFundingAmount_GL
FROM #PayableInvoiceGLJournalDetails gl
INNER JOIN
	(
		SELECT MAX(pia.PayableInvoiceId) AS PayableInvoiceId
			 , SUM(pia.TotalProgressFundingAmountApplied) AS ProgressFundingAmount_GL
		FROM #PayableInvoiceAmount pia
			 INNER JOIN #OriginationRestoredIds originationRestored ON pia.PayableInvoiceId = originationRestored.PayableInvoiceId
		GROUP BY originationRestored.ContractId
	) AS t ON t.PayableInvoiceId = gl.PayableInvoiceId;
   


UPDATE gl SET ProgressPaymentCreditsAmountApplied = t.ProgressPaymentCreditsAmountApplied
			, ProgressPaymentCreditsAmount = t.ProgressPaymentCreditsAmount
			, PendingProgressPaymentCreditsAmount = t.PendingProgressPaymentCreditsAmount
			, NoContractBalance = t.NoContractBalance 
FROM #TotalPayableInvoiceTakeDownAmount gl
INNER JOIN
	(
		SELECT MAX(pia.PayableInvoiceId) AS PayableInvoiceId
			 , SUM(pia.ProgressPaymentCreditsAmountApplied) AS ProgressPaymentCreditsAmountApplied
			 , SUM(pia.ProgressPaymentCreditsAmount) AS ProgressPaymentCreditsAmount
			 , SUM(pia.PendingProgressPaymentCreditsAmount) AS PendingProgressPaymentCreditsAmount
			 , SUM(pia.NoContractBalance) AS NoContractBalance
		FROM #TotalPayableInvoiceTakeDownAmount pia
			 INNER JOIN #OriginationRestoredIds originationRestored ON pia.PayableInvoiceId = originationRestored.PayableInvoiceId
		GROUP BY originationRestored.ContractId
	) AS t ON t.PayableInvoiceId = gl.PayableInvoiceId; 

UPDATE gl SET 
              DRAmount = t.Amount
FROM #ProgressPaymentCreditPayableInvoiceGLAmount gl
     INNER JOIN
(
    SELECT MAX(gl.PayableInvoiceId) AS PayableInvoiceId
         , SUM(DRAmount) AS Amount
    FROM #ProgressPaymentCreditPayableInvoiceGLAmount gl
         INNER JOIN #OriginationRestoredIds originationRestored ON gl.PayableInvoiceId = originationRestored.PayableInvoiceId
    GROUP BY originationRestored.ContractId
) AS t ON t.PayableInvoiceId = gl.PayableInvoiceId;


-- End of handling of Origination Restored


;WITH CTE_UnappliedCashInfo
     AS (SELECT Receipt.ContractId
              , SUM(Receipt.Balance_Amount) AS UnappliedCash
         FROM #EligibleContracts Contract
              JOIN Receipts Receipt ON Contract.ContractId = Receipt.ContractId
                                       AND Receipt.Status IN('Posted')
              JOIN ReceiptAllocations Allocation ON Allocation.ReceiptId = Receipt.Id
                                                    AND Allocation.IsActive = 1
         GROUP BY Receipt.ContractId),
     CTE_PayableBalanceInfo
     AS (SELECT Contract.ContractId
              , SUM(Payable.Balance_Amount) AS PayableBalance
         FROM #EligibleContracts Contract
              JOIN Receipts Receipt ON Contract.ContractId = Receipt.ContractId
                                       AND Receipt.Status = 'Posted'
              JOIN Payables Payable ON Receipt.Id = Payable.SourceId
                                       AND Payable.SourceTable = 'Receipt'
                                       AND Payable.EntityType = 'RR'
              JOIN UnallocatedRefunds Refund ON Payable.EntityId = Refund.Id
                                                AND Refund.Status != 'Reversed'
         WHERE Payable.Status != 'InActive'
         GROUP BY Contract.ContractId)
     SELECT Contracts.ContractId
          , UnappliedCashInfo.UnappliedCash + ISNULL(PayableBalanceInfo.PayableBalance, 0.00) AS UnAppliedAmount
     INTO #UnAppliedTable
     FROM #EligibleContracts contracts
          JOIN CTE_UnappliedCashInfo UnappliedCashInfo ON contracts.ContractId = UnappliedCashInfo.ContractId
          LEFT JOIN CTE_PayableBalanceInfo PayableBalanceInfo ON contracts.ContractId = PayableBalanceInfo.ContractId;


CREATE NONCLUSTERED INDEX IX_Id ON #UnAppliedTable(ContractId);

SELECT ec.ContractId
     , SUM(CASE
               WHEN gljd.IsDebit = 0
               THEN gljd.Amount_Amount
               ELSE 0.00
           END) - SUM(CASE
                          WHEN gljd.IsDebit = 1
                          THEN gljd.Amount_Amount
                          ELSE 0.00
                      END) AS UnAppliedAR
INTO #UnAppliedGL
FROM GLJournalDetails gljd
     INNER JOIN GLTemplateDetails gltd ON gltd.Id = gljd.GLTemplateDetailId
     INNER JOIN GLEntryItems glei ON glei.Id = gltd.EntryItemId
     INNER JOIN GLTransactionTypes gltt ON glei.GLTransactionTypeId = gltt.Id
     INNER JOIN #EligibleContracts ec ON ec.ContractId = gljd.EntityId
                                         AND gljd.EntityType = 'Contract'
WHERE glei.Name = 'UnAppliedAR'
GROUP BY ec.ContractId;

CREATE NONCLUSTERED INDEX IX_Id ON #UnAppliedGL(ContractId);

SELECT DISTINCT 
       Contract.ContractId
     , pgl.GLJournalId
INTO #RefundGLJournalIds
FROM #EligibleContracts Contract
     JOIN Receipts Receipt ON Receipt.Status IN('Reversed', 'Completed', 'Posted')
                              AND Contract.ContractId = Receipt.ContractId
     INNER JOIN ReceiptAllocations ra ON Receipt.Id = ra.ReceiptId
     JOIN UnallocatedRefundDetails refundDetails ON refundDetails.ReceiptAllocationId = ra.Id
     JOIN UnallocatedRefunds refund ON refund.Id = refundDetails.UnallocatedRefundId
                                       AND refund.Status = 'Approved'
     JOIN Payables p ON p.SourceId = Receipt.Id
                        AND p.SourceTable = 'Receipt'
                        AND p.Status = 'Approved'
                        AND p.IsGLPosted = 1
     JOIN PayableGLJournals pgl ON pgl.PayableId = p.Id
WHERE ra.EntityType = 'UnAllocated'
      AND ra.IsActive = 1
      AND refund.Type = 'Refund';

INSERT INTO #RefundGLJournalIds
SELECT DISTINCT 
       Contract.ContractId
     , pvgl.GLJournalId
FROM #EligibleContracts Contract
     JOIN Receipts Receipt ON Receipt.Status IN('Reversed', 'Completed', 'Posted')
                              AND Contract.ContractId = Receipt.ContractId
     INNER JOIN ReceiptAllocations ra ON Receipt.Id = ra.ReceiptId
     INNER JOIN UnallocatedRefundDetails refundDetails ON refundDetails.ReceiptAllocationId = ra.Id
     INNER JOIN UnallocatedRefunds refund ON refund.Id = refundDetails.UnallocatedRefundId
                                             AND refund.Status = 'Approved'
     JOIN Payables p ON p.SourceId = Receipt.Id
                        AND p.SourceTable = 'Receipt'
                        AND p.Status = 'Approved'
                        AND p.IsGLPosted = 1
     INNER JOIN TreasuryPayableDetails tpd ON tpd.PayableId = P.Id
                                              AND tpd.IsActive = 1
     INNER JOIN PaymentVoucherDetails pvd ON pvd.TreasuryPayableId = tpd.TreasuryPayableId
     INNER JOIN PaymentVoucherGLJournals pvgl ON pvgl.PaymentVoucherId = pvd.PaymentVoucherId
     LEFT JOIN PayableGLJournals pgl ON pgl.PayableId = p.Id
WHERE refund.Status = 'Approved'
      AND pgl.GLJournalId IS NULL
	  AND refund.Type = 'Refund';

CREATE NONCLUSTERED INDEX IX_GLJournalId ON #RefundGLJournalIds(GLJournalId);

CREATE NONCLUSTERED INDEX IX_Id ON #RefundGLJournalIds(ContractId);

SELECT t.ContractId
     , SUM(t.Debit - t.Credit) AS Amount
INTO #RefundDetails
FROM
(
    SELECT dr.ContractId
         , CASE
               WHEN gld.IsDebit = 1
               THEN gld.Amount_Amount
               ELSE 0.00
           END AS Debit
         , CASE
               WHEN gld.IsDebit = 0
               THEN gld.Amount_Amount
               ELSE 0.00
           END AS Credit
    FROM #RefundGLJournalIds dr
         JOIN GLJournalDetails gld ON dr.GLJournalId = gld.GLJournalId
         JOIN GLTemplateDetails gltd ON gltd.Id = gld.GLTemplateDetailId
         JOIN GLEntryItems glei ON glei.Id = gltd.EntryItemId
                                   AND glei.IsActive = 1
         JOIN GLTransactionTypes gltt ON glei.GLTransactionTypeId = gltt.Id
                                         AND gltt.IsActive = 1
    WHERE(glei.Name = 'UnAppliedAR'
          AND gltt.Name = 'PayableCash')
         OR (glei.Name = 'CashPayable'
             AND gltt.Name = 'AccountsPayable')
) AS t
GROUP BY t.ContractId;

UPDATE gl SET 
              UnAppliedAR = UnAppliedAR - refund.Amount
FROM #UnAppliedGL gl
     INNER JOIN #RefundDetails refund ON gl.ContractId = refund.ContractId;


SELECT ec.ContractId
     , ec.SequenceNumber
     , ec.Alias
     , le.Name AS LegalEntityName
     , lob.Name AS [LineOfBusinessName]
     , p.PartyName AS CustomerName
     , ec.LoanFinanceId
     , ec.InterimBillingType
     , nof.DueDate AS [AnticipatedFundingDate]
     , ec.MaturityDate
     , ec.IsMigratedContract
     , ec.Currency
     , ISNULL(nof.NoOfFundings, 0) AS NoOfFundings
     , ISNULL(notd.NoOfTakeDowns, 0) AS NoOfTakeDowns
     , ec.Status
     , IIF(ec.Status IN('FullyPaid', 'FullyPaidOff'), takeDown.InterimInterestStartDate, NULL) AS [TerminationDate]
     , ISNULL(nof.InvoiceTotal_Amount, 0.00) AS [TotalPayableInvoiceAmount]
     , ISNULL(progressFunding.OriginationRestored, 0.00) AS [TransferToOriginationRestored]
     , ISNULL(nof.InvoiceTotal_Amount, 0.00) - ISNULL(progressFunding.OriginationRestored, 0.00) AS [NetPayableInvoiceAmount]
     , ABS(ISNULL(takeDown.ProgressPaymentCreditsAmount, 0.00)) AS [TotalProgressPaymentCreditsAmount]
     , ABS(ISNULL(progressFunding.FullCreditBalance, 0.00)) AS [TotalProgressFundingCreditBalance]
     , ABS(ISNULL(nof.InvoiceTotal_Amount, 0.00)) - (ABS(ISNULL(takeDown.ProgressPaymentCreditsAmount, 0.00)) + ABS(ISNULL(progressFunding.FullCreditBalance, 0.00)) + ISNULL(progressFunding.OriginationRestored, 0.00)) AS [TotalProgressFundingAmountVsTotalProgressPaymentCreditsAmount]
     , ISNULL(progressFunding.TotalProgressFundingAmount, 0.00) AS [TotalPayableInvoiceAmount_Table]
     , ISNULL(gjd.ProgressFundingAmount_GL, 0.00) AS [TotalPayableInvoiceAmount_GL]
     , ISNULL(progressFunding.TotalProgressFundingAmount, 0.00) - ISNULL(gjd.ProgressFundingAmount_GL, 0.00) AS [TotalPayableInvoiceAmount_Difference]
     , ISNULL(takeDown.ProgressPaymentCreditsAmountApplied, 0.00) AS [TotalProgressPaymentCreditsAmount_Table]
     , ISNULL(ppc.DRAmount, 0.00) AS [TotalProgressPaymentCreditsAmount_GL]
     , ISNULL(takeDown.ProgressPaymentCreditsAmountApplied, 0.00) - ISNULL(ppc.DRAmount, 0.00) AS [TotalProgressPaymentCreditsAmount_Difference]
     , ISNULL(progressFunding.TotalCreditBalance, 0.00) AS [TotalProgressFundingCreditBalance_Table]
     , IIF(ec.IsMigratedContract = 'Yes', ABS(ISNULL(progressFunding.TotalProgressFundingAmount, 0.00) - ISNULL(takeDown.ProgressPaymentCreditsAmountApplied, 0.00)), (ABS(ISNULL(gjd.ProgressFundingAmount_GL, 0.00)) - ABS(ISNULL(ppc.DRAmount, 0.00)))) AS [TotalProgressFundingCreditBalance_GL]
     , ABS(ISNULL(progressFunding.TotalCreditBalance, 0.00)) - IIF(ec.IsMigratedContract = 'Yes', ABS(ISNULL(progressFunding.TotalProgressFundingAmount, 0.00) - ISNULL(takeDown.ProgressPaymentCreditsAmountApplied, 0.00)), (ABS(ISNULL(gjd.ProgressFundingAmount_GL, 0.00)) - ABS(ISNULL(ppc.DRAmount, 0.00)))) AS [TotalProgressFundingCreditBalance_Difference]
     , ABS(ISNULL(progressFunding.TotalProgressFundingAmount, 0.00)) - (ABS(ISNULL(takeDown.ProgressPaymentCreditsAmountApplied, 0.00)) + ABS(ISNULL(progressFunding.TotalCreditBalance, 0.00))) AS [TotalProgressFundingAmountVsTotalProgressPaymentCreditsAmount_GLPosted]
     , ISNULL(interimInterest.Amount, 0.00) AS [ProgressLoanInterimInterestIncomeGLPosted_Table]
     , ISNULL(interimGL.InterimInterestGL, 0.00) AS [ProgressLoanInterimInterestIncomeGLPosted_GL]
     , ABS(ISNULL(interimInterest.Amount, 0.00)) - ABS(ISNULL(interimGL.InterimInterestGL, 0.00)) AS [ProgressLoanInterimInterestIncomeGLPosted_Difference]
     , ABS(ABS(ISNULL(interimInterest.Amount, 0.00)) - ABS(ISNULL(receivable.InterestReceivablesGLPosted, 0.00)) - ABS(ISNULL(capitalization.Amount, 0.00))) AS [ProgressLoanAccruedInterimInterestBalance_Table]
     , ABS(ABS(ISNULL(interimGL.AccruedInterimInterestGL, 0.00)) - ABS(ISNULL(capitalizationGL.Amount, 0.00))) AS [ProgressLoanAccruedInterimInterestBalance_GL]
     , ABS(ABS(ISNULL(interimInterest.Amount, 0.00)) - ABS(ISNULL(receivable.InterestReceivablesGLPosted, 0.00)) - ABS(ISNULL(capitalization.Amount, 0.00))) - ABS(ABS(ISNULL(interimGL.AccruedInterimInterestGL, 0.00)) - ABS(ISNULL(capitalizationGL.Amount, 0.00))) AS [ProgressLoanAccruedInterimInterestBalance_Difference]
     , ISNULL(capitalization.Amount, 0.00) AS [TotalInterimInterestCapitalizationOnTakedownContracts_Table]
     , ISNULL(capitalizationGL.Amount, 0.00) AS [TotalInterimInterestCapitalizationOnTakedownContracts_GL]
     , ISNULL(capitalization.Amount, 0.00) - ISNULL(capitalizationGL.Amount, 0.00) AS [TotalInterimInterestCapitalizationOnTakedownContracts_Difference]
     , ISNULL(receivable.TotalInterestReceivableGenerated, 0.00) AS [TotalInterestReceivableGenerated]
     , ISNULL(receivable.InterestReceivablesGLPosted, 0.00) AS [InterestReceivablesGLPosted]
     , ISNULL(receivable.InterestReceivablesNotGLPosted, 0.00) AS [InterestReceivablesNotGLPosted]
     , ABS(ISNULL(receivable.TotalInterestReceivableGenerated, 0.00)) - ABS(ISNULL(receivable.InterestReceivablesGLPosted, 0.00) + ISNULL(receivable.InterestReceivablesNotGLPosted, 0.00)) AS [TotalInterestReceivableGeneratedVsGLPostedAndNonGLPosted]
     , ISNULL(receivable.InterestReceivablesPrepaid, 0.00) AS [InterimInterestPrepaid_Table]
     , ISNULL(gld.GLPrepaidInterest_GL, 0.00) AS [InterimInterestPrepaid_GL]
     , ISNULL(receivable.InterestReceivablesPrepaid, 0.00) - ISNULL(gld.GLPrepaidInterest_GL, 0.00) AS [InterimInterestPrepaid_Difference]
     , ISNULL(receivable.InterestReceivablesOSAR, 0.00) AS [InterimInterestOSAR_Table]
     , ISNULL(gld.OSAR_GL, 0.00) AS [InterimInterestOSAR_GL]
     , ISNULL(receivable.InterestReceivablesOSAR, 0.00) - ISNULL(gld.OSAR_GL, 0.00) AS [InterimInterestOSAR_Difference]
     , ISNULL(rd.CashPosted, 0.00) AS [InterestCashApplication_Table]
     , ISNULL(gld.CashPaid_GL, 0.00) AS [InterestCashApplication_GL]
     , ISNULL(rd.CashPosted, 0.00) - ISNULL(gld.CashPaid_GL, 0.00) AS [InterestCashApplication_Difference]
     , ISNULL(rd.NonCashPosted, 0.00) AS [InterestNonCashApplication_Table]
     , ISNULL(gld.NonCashPaid_GL, 0.00) AS [InterestNonCashApplication_GL]
     , ISNULL(rd.NonCashPosted, 0.00) - ISNULL(gld.NonCashPaid_GL, 0.00) AS [InterestNonCashApplication_Difference]
	 , ISNULL(unAppliedTable.UnAppliedAmount,0.00) AS [UnappliedAR_Table]
	 , ISNULL(unAppliedGL.UnAppliedAR, 0.00) AS [UnappliedAR_GL] 
	 , ISNULL(unAppliedTable.UnAppliedAmount,0.00) - ISNULL(unAppliedGL.UnAppliedAR, 0.00) AS [UnappliedAR_Difference] 
     , CAST('Not Problem Record' AS NVARCHAR(30)) AS Result
INTO #ProgressLoanLifeCycle
FROM #EligibleContracts ec
     INNER JOIN LegalEntities le ON ec.LegalEntityId = le.Id
     INNER JOIN Parties p ON p.Id = ec.CustomerId
     INNER JOIN LineOfBusinesses lob ON lob.Id = ec.LineofBusinessId
     LEFT JOIN #TotalProgressFundingAmount progressFunding ON progressFunding.ContractId = ec.ContractId
     LEFT JOIN #TotalTakeDownAmount takeDown ON takeDown.ContractId = ec.ContractId
     LEFT JOIN #NoOfFundings nof ON nof.ContractId = ec.ContractId
     LEFT JOIN #NoOfTakeDowns notd ON notd.ContractId = ec.ContractId
     LEFT JOIN #GLJournalDetails gjd ON gjd.ContractId = ec.ContractId
     LEFT JOIN #ProgressPaymentCreditGLAmount ppc ON ppc.ContractId = ec.ContractId
     LEFT JOIN #ReceivableDetails receivable ON receivable.ContractId = ec.ContractId
     LEFT JOIN #GLJournalValues gld ON gld.ContractId = ec.ContractId
     LEFT JOIN #ReceiptDetails rd ON rd.ContractId = ec.ContractId
     LEFT JOIN #TotalInterimInterestCapitalization capitalization ON capitalization.ContractId = ec.ContractId
     LEFT JOIN #CapitalizationGLCreditAmount capitalizationGL ON capitalizationGL.ContractId = ec.ContractId
     LEFT JOIN #InterimInterestGL interimGL ON interimGL.ContractId = ec.ContractId
     LEFT JOIN #ProgressLoanInterimInterest interimInterest ON interimInterest.ContractId = ec.ContractId
	 LEFT JOIN #UnAppliedTable unAppliedTable ON unAppliedTable.ContractId = ec.ContractId 
	 LEFT JOIN #UnAppliedGL unAppliedGL ON unAppliedGL.ContractId = ec.ContractId;


CREATE NONCLUSTERED INDEX IX_Id ON #ProgressLoanLifeCycle(ContractId);

SELECT DISTINCT 
       pid.ContractId
     , ec.SequenceNumber
     , pi.InvoiceNumber
     , pi.DueDate
     , pi.InvoiceDate
     , p.PartyName
     , IIF(invoiceDetails.Type = 'OriginationRestored', ISNULL(pia.OriginationRestored, 0.00), ISNULL((pia.ProgressFundingAmount), 0.00)) AS [PayableInvoiceAmount]
     , invoiceDetails.Type
	 , 0.00 AS TransferToOriginationRestored
	 , IIF(invoiceDetails.Type = 'OriginationRestored', ISNULL(pia.OriginationRestored, 0.00), ISNULL((pia.ProgressFundingAmount), 0.00)) AS [NetPayableInvoiceAmount]
     , ISNULL(takeDown.ProgressPaymentCreditsAmount, 0.00) AS [ProgressPaymentCreditsAmount]
     , ISNULL(pia.FullCreditBalance, 0.00) AS [ProgressFundingCreditBalance]
     , IIF(invoiceDetails.Type = 'OriginationRestored', ABS(ISNULL(pia.OriginationRestored, 0.00)), ABS(ISNULL((pia.ProgressFundingAmount), 0.00))) - (ABS(ISNULL(takeDown.ProgressPaymentCreditsAmount, 0.00)) + ABS(ISNULL(pia.FullCreditBalance, 0.00))) AS [ProgressFundingAmountVsTotalProgressPaymentCreditsAmount]
     , ISNULL(pia.TotalProgressFundingAmountApplied, 0.00) [PayableInvoiceAmount_Table]
     , ISNULL(gld.ProgressFundingAmount_GL, 0.00) AS [PayableInvoiceAmount_GL]
     , ISNULL(pia.TotalProgressFundingAmountApplied, 0.00) - ISNULL(gld.ProgressFundingAmount_GL, 0.00) AS [PayableInvoiceAmount_Difference]
     , ISNULL(takeDown.ProgressPaymentCreditsAmountApplied, 0.00) AS [ProgressPaymentCreditsAmount_Table]
     , ISNULL(ppc.DRAmount, 0.00) AS [ProgressPaymentCreditsAmount_GL]
     , ISNULL(takeDown.ProgressPaymentCreditsAmountApplied, 0.00) - ISNULL(ppc.DRAmount, 0.00) AS [ProgressPaymentCreditsAmount_Difference]
     , ISNULL(pia.TotalCreditBalance, 0.00) AS [ProgressFundingCreditBalance_Table]
     , IIF(invoiceDetails.Type = 'OriginationRestored', ABS(ISNULL(pia.OriginationRestored, 0.00)) - ABS(ISNULL(takeDown.ProgressPaymentCreditsAmountApplied, 0.00)), ISNULL(gld.ProgressFundingAmount_GL, 0.00) - ISNULL(ppc.DRAmount, 0.00)) AS [ProgressFundingCreditBalance_GL]
     , ABS(ISNULL(pia.TotalCreditBalance, 0.00)) - ABS(IIF(invoiceDetails.Type = 'OriginationRestored', ABS(ISNULL(pia.OriginationRestored, 0.00)) - ABS(ISNULL(takeDown.ProgressPaymentCreditsAmountApplied, 0.00)), ISNULL(gld.ProgressFundingAmount_GL, 0.00) - ISNULL(ppc.DRAmount, 0.00))) AS [ProgressFundingCreditBalance_Difference]
     , IIF(invoiceDetails.Type = 'OriginationRestored', ABS(ISNULL(pia.OriginationRestored, 0.00)), ABS(ISNULL(pia.TotalProgressFundingAmountApplied, 0.00))) - (ABS(ISNULL(takeDown.ProgressPaymentCreditsAmountApplied, 0.00)) + ABS(ISNULL(pia.TotalCreditBalance, 0.00))) AS [ProgressFundingAmountVsTotalProgressPaymentCreditsAmount_GLPosted]
     , IIF(ISNULL(pia.TotalCreditBalance, 0.00) = 0.00, takeDown.InterimInterestStartDate, NULL) AS [TerminationDate]
     , CAST('Not Problem Record' AS NVARCHAR(30)) AS Result
INTO #PayableInvoiceLifeCycle
FROM #PayableInvoiceIds pid
     INNER JOIN #EligibleContracts ec ON ec.ContractId = pid.ContractId
     INNER JOIN PayableInvoices pi ON pi.Id = pid.PayableInvoiceId
     INNER JOIN PayableInvoiceOtherCosts pioc ON pioc.PayableInvoiceId = pid.PayableInvoiceId
                                                 AND Pioc.AllocationMethod = 'LoanDisbursement'
     INNER JOIN #PayableInvoiceDetails invoiceDetails ON invoiceDetails.PayableInvoiceOtherCostId = pioc.Id
     LEFT JOIN Parties p ON p.Id = pi.VendorId
     LEFT JOIN #OriginationRestoredPayableInvoices originationRestored ON originationRestored.PayableInvoiceId = pid.PayableInvoiceId
     LEFT JOIN #PayableInvoiceAmount pia ON pia.PayableInvoiceId = pid.PayableInvoiceId
     LEFT JOIN #PayableInvoiceGLJournalDetails gld ON gld.PayableInvoiceId = pid.PayableInvoiceId
     LEFT JOIN #TotalPayableInvoiceTakeDownAmount takeDown ON takeDown.PayableInvoiceId = pid.PayableInvoiceId
     LEFT JOIN #ProgressPaymentCreditPayableInvoiceGLAmount ppc ON ppc.PayableInvoiceId = pid.PayableInvoiceId
WHERE(invoiceDetails.Type = 'OriginationRestored'
      AND originationRestored.PayableInvoiceId IS NOT NULL)
     OR invoiceDetails.Type != 'OriginationRestored';


CREATE NONCLUSTERED INDEX IX_Id ON #PayableInvoiceLifeCycle(ContractId);


SELECT ContractId,
	   SUM(ABS(ProgressFundingAmountVsTotalProgressPaymentCreditsAmount)) AS CreditBalance,
	   SUM(ABS(ProgressFundingAmountVsTotalProgressPaymentCreditsAmount_GLPosted)) AS CreditBalance_GLPosted
INTO #OriginationPayableInvoice
FROM #PayableInvoiceLifeCycle
WHERE [Type] != 'OriginationRestored'
GROUP BY ContractId

CREATE NONCLUSTERED INDEX IX_Id ON #OriginationPayableInvoice(ContractId);

SELECT ContractId
     , SUM(PayableInvoiceAmount) AS OriginationRestored
INTO #OriginationRestoredPayableInvoice
FROM #PayableInvoiceLifeCycle
WHERE [Type] = 'OriginationRestored'
GROUP BY ContractId;

CREATE NONCLUSTERED INDEX IX_Id ON #OriginationRestoredPayableInvoice(ContractId);


UPDATE #PayableInvoiceLifeCycle SET 
ProgressFundingCreditBalance = CASE
                                        WHEN CreditBalance = OriginationRestored
                                        THEN ProgressFundingCreditBalance - ABS(ProgressFundingAmountVsTotalProgressPaymentCreditsAmount)
                                        ELSE ProgressFundingCreditBalance
                                    END
, ProgressFundingAmountVsTotalProgressPaymentCreditsAmount = CASE
                                                                      WHEN CreditBalance = OriginationRestored
                                                                      THEN 0.00
                                                                      ELSE ProgressFundingAmountVsTotalProgressPaymentCreditsAmount
                                                                END
, ProgressFundingCreditBalance_Table = CASE
                                                WHEN CreditBalance_GLPosted = OriginationRestored
                                                THEN ProgressFundingCreditBalance_Table - ABS(ProgressFundingCreditBalance_Difference)
                                                ELSE ProgressFundingCreditBalance_Table
                                            END
, ProgressFundingAmountVsTotalProgressPaymentCreditsAmount_GLPosted = CASE
                                                                                WHEN CreditBalance_GLPosted = OriginationRestored
                                                                                THEN 0.00
                                                                                ELSE ProgressFundingAmountVsTotalProgressPaymentCreditsAmount_GLPosted
                                                                            END
, ProgressFundingCreditBalance_Difference = CASE
                                                     WHEN CreditBalance_GLPosted = OriginationRestored
                                                     THEN 0.00
                                                     ELSE ProgressFundingCreditBalance_Difference
                                                END
FROM #PayableInvoiceLifeCycle lifeCycle
     INNER JOIN #OriginationRestoredPayableInvoice originationRestored ON originationRestored.ContractId = lifeCycle.ContractId
     INNER JOIN #OriginationPayableInvoice origination ON origination.ContractId = lifeCycle.ContractId
WHERE lifeCycle.[Type] != 'OriginationRestored'
      AND (CreditBalance = OriginationRestored
           OR CreditBalance_GLPosted = OriginationRestored);


UPDATE #PayableInvoiceLifeCycle SET 
                                    Result = 'Problem Record'
WHERE PayableInvoiceAmount_Difference != 0.00
      OR ProgressPaymentCreditsAmount_Difference != 0.00
      OR ProgressFundingCreditBalance_Difference != 0.00
      OR [ProgressFundingAmountVsTotalProgressPaymentCreditsAmount] != 0.00
      OR [ProgressFundingAmountVsTotalProgressPaymentCreditsAmount_GLPosted] != 0.00;


UPDATE lifeCycle SET 
  TotalProgressFundingCreditBalance = CASE
                                          WHEN ABS(TotalProgressFundingAmountVsTotalProgressPaymentCreditsAmount) = ABS(OriginationRestored)
                                          THEN ABS(TotalProgressFundingCreditBalance) - ABS(OriginationRestored)
                                          ELSE TotalProgressFundingCreditBalance
                                      END
, TotalProgressFundingAmountVsTotalProgressPaymentCreditsAmount = CASE
                                                                      WHEN ABS(TotalProgressFundingAmountVsTotalProgressPaymentCreditsAmount) = ABS(OriginationRestored)
                                                                      THEN 0.00
                                                                      ELSE TotalProgressFundingAmountVsTotalProgressPaymentCreditsAmount
                                                                  END
, TotalProgressFundingCreditBalance_Table = CASE
                                                WHEN ABS(TotalProgressFundingCreditBalance_Difference) = ABS(OriginationRestored)
                                                THEN ABS(TotalProgressFundingCreditBalance_Table) - ABS(OriginationRestored)
                                                ELSE TotalProgressFundingCreditBalance_Table
                                            END
, TotalProgressFundingCreditBalance_Difference = CASE
                                                     WHEN ABS(TotalProgressFundingCreditBalance_Difference) = ABS(OriginationRestored)
                                                     THEN 0.00
                                                     ELSE TotalProgressFundingCreditBalance_Difference
                                                 END
, TotalProgressFundingAmountVsTotalProgressPaymentCreditsAmount_GLPosted = CASE
                                                                                WHEN ABS(TotalProgressFundingAmountVsTotalProgressPaymentCreditsAmount_GLPosted) = ABS(OriginationRestored)
                                                                                THEN 0.00
                                                                                ELSE TotalProgressFundingAmountVsTotalProgressPaymentCreditsAmount_GLPosted
                                                                            END
FROM #ProgressLoanLifeCycle lifeCycle
     INNER JOIN #OriginationRestoredPayableInvoice originationRestored ON originationRestored.ContractId = lifeCycle.ContractId;

UPDATE #ProgressLoanLifeCycle SET 
                                  Result = 'Problem Record'
WHERE TotalPayableInvoiceAmount_Difference != 0.00
      OR TotalProgressPaymentCreditsAmount_Difference != 0.00
      OR TotalProgressFundingCreditBalance_Difference != 0.00
      OR InterimInterestPrepaid_Difference != 0.00
      OR InterimInterestOSAR_Difference != 0.00
      OR InterestCashApplication_Difference != 0.00
      OR InterestNonCashApplication_Difference != 0.00
      OR [TotalProgressFundingAmountVsTotalProgressPaymentCreditsAmount] != 0.00
      OR [TotalInterestReceivableGeneratedVsGLPostedAndNonGLPosted] != 0.00
      OR [TotalInterimInterestCapitalizationOnTakedownContracts_Difference] != 0.00
      OR [ProgressLoanInterimInterestIncomeGLPosted_Difference] != 0.00
      OR [ProgressLoanAccruedInterimInterestBalance_Difference] != 0.00
      OR [TotalProgressFundingAmountVsTotalProgressPaymentCreditsAmount_GLPosted] != 0.00
	  OR [UnappliedAR_Difference] != 0.00;

SELECT *, 
		CASE 
			 WHEN InterimInterestCapitalization_Difference != 0.00
				  OR TotalProgressPaymentCreditsAmount_Difference != 0.00
			 THEN 'Problem Record'
			 ELSE 'Not Problem Record'
		END AS Result
INTO #TakeDownLifeCycle 
FROM
(
SELECT DISTINCT 
	   ec.ContractId
	 , ec.SequenceNumber
	 , ec.Currency
	 , pcd.InvoiceNumber AS [TakedownInvoiceNumber]
	 , pcd.Currency AS [TakedownCurrency]
	 , pcd.SequenceNumber AS [TakedownSequenceNumber]
	 , pcd.ContractId AS [TakedownContractId]
	 , pcd.ContractType AS [TakedownContractType]
	 , pcd.ContractCurrency AS [TakedownContractCurrency]
	 , takeDown.InterimInterestStartDate AS [TakedownDate]
	 , IIF(pcd.ContractType = 'Lease', ISNULL(leaseCip.Amount, 0.00),  ISNULL(loanCip.Amount, 0.00)) AS [InterimInterestCapitalization_Table]
	 , ISNULL(gl.Amount, 0.00) AS [InterimInterestCapitalization_GL]
	 , ABS(IIF(pcd.ContractType = 'Lease', ISNULL(leaseCip.Amount, 0.00),  ISNULL(loanCip.Amount, 0.00))) - ISNULL(gl.Amount, 0.00) AS [InterimInterestCapitalization_Difference]
	 , ISNULL(takeDownAmount.ProgressPaymentCreditsAmount, 0.00) AS [TotalProgressPaymentCreditsAmount]
	 , ISNULL(takeDownAmount.ProgressPaymentCreditsAmountApplied, 0.00) AS [TotalProgressPaymentCreditsAmount_Table]
	 , ISNULL(ppc.DRAmount, 0.00) AS [TotalProgressPaymentCreditsAmount_GL]
	 , ISNULL(takeDownAmount.ProgressPaymentCreditsAmountApplied, 0.00) - ISNULL(ppc.DRAmount, 0.00) AS [TotalProgressPaymentCreditsAmount_Difference]
	 FROM #TakeDownPayableInvoiceDetails takeDown
	 INNER JOIN #ProgressCreditDetails pcd ON pcd.PayableInvoiceId = takeDown.PayableInvoiceId
	 LEFT JOIN #EligibleContracts ec ON ec.ContractId = takeDown.ContractId
	 LEFT JOIN #LoanInterimInterestCapitalization loanCip ON loanCip.PayableInvoiceId = takeDown.PayableInvoiceId 
	 LEFT JOIN #LeaseInterimInterestCapitalization leaseCip ON leaseCip.PayableInvoiceId = takeDown.PayableInvoiceId
	 LEFT JOIN #PayableGLCreditAmount gl ON gl.PayableInvoiceId = takeDown.PayableInvoiceId
	 LEFT JOIN #ProgressCreditDetailsTakeDownAmount takeDownAmount ON takeDownAmount.PayableInvoiceId = takeDown.PayableInvoiceId
	 LEFT JOIN #ProgressCreditDetailsGLAmount ppc ON ppc.PayableInvoiceId = takeDown.PayableInvoiceId) AS t;

	SELECT name AS Name
		 , 0 AS Count
		 , CAST(0 AS BIT) AS IsProcessed
		 , CAST('' AS NVARCHAR(MAX)) AS Label
		 , column_Id AS ColumnId
	INTO #ProgressLoanSummary
	FROM tempdb.sys.columns
	WHERE object_id = OBJECT_ID('tempdb..#ProgressLoanLifeCycle')
		  AND (Name LIKE '%Vs%' OR Name LIKE '%_difference');

	DECLARE @query NVARCHAR(MAX);
	DECLARE @TableName NVARCHAR(MAX);

	WHILE EXISTS(SELECT 1 FROM #ProgressLoanSummary WHERE IsProcessed = 0)
	BEGIN
		 SELECT TOP 1 @TableName = Name
		 FROM #ProgressLoanSummary
		 WHERE IsProcessed = 0;
		 
		 SET @query = 'UPDATE #ProgressLoanSummary SET Count = (SELECT COUNT(*) FROM #ProgressLoanLifeCycle WHERE ' + @TableName + ' != 0.00), IsProcessed = 1
		 			   WHERE Name = ''' + @TableName + ''' ;';
		 EXEC (@query);
	END;

	UPDATE #ProgressLoanSummary SET Label = CASE WHEN Name = 'TotalProgressFundingAmountVsTotalProgressPaymentCreditsAmount'
												 THEN '1_Net Progress Fundings Amount = (Total Progress Payment Credits Amount + Total Progress Funding Credit Balance)'
												 WHEN Name = 'TotalPayableInvoiceAmount_Difference'
												 THEN '2_Total Payable Invoice Amount GL Posted_Difference'
												 WHEN Name = 'TotalProgressPaymentCreditsAmount_Difference'
												 THEN '3_Total Progress Payment Credits Amount GL Posted_Difference'
												 WHEN Name = 'TotalProgressFundingCreditBalance_Difference'
												 THEN '4_Total Progress Funding Credit Balance GL Posted_Difference'
												 WHEN Name = 'TotalProgressFundingAmountVsTotalProgressPaymentCreditsAmount_GLPosted'
												 THEN '5_Total GL Posted : Progress Fundings =  (Progress Payment Credits + Progress Funding Credit Balance)'
												 WHEN Name = 'ProgressLoanInterimInterestIncomeGLPosted_Difference'
												 THEN '6_Progress Loan Interim Interest Income GL Posted_Difference'
												 WHEN Name = 'ProgressLoanAccruedInterimInterestBalance_Difference'
												 THEN '7_Progress Loan Accrued Interim Interest Balance_Difference'
												 WHEN Name = 'TotalInterimInterestCapitalizationOnTakedownContracts_Difference'
												 THEN '8_Total Interim Interest Capitalization on Takedown Contracts_Difference'
												 WHEN Name = 'TotalInterestReceivableGeneratedVsGLPostedAndNonGLPosted'
												 THEN '9_Total Interest Receivable Generated vs (GL Posted + Not GL Posted)'
												 WHEN Name = 'InterimInterestPrepaid_Difference'
												 THEN '10_Interim Interest Prepaid_Difference'
												 WHEN Name = 'InterimInterestOSAR_Difference'
												 THEN '11_Interim Interest OSAR_Difference'
												 WHEN Name = 'InterestCashApplication_Difference'
												 THEN '12_Interest Cash Application till date_Difference'
												 WHEN Name = 'InterestNonCashApplication_Difference'
												 THEN '13_Interest Non Cash Application till date_Difference'
												 WHEN Name = 'UnappliedAR_Difference'
												 THEN '14_Unapplied AR_Difference'
											END

	SELECT name AS Name
		 , 0 AS Count
		 , CAST(0 AS BIT) AS IsProcessed
		 , CAST('' AS NVARCHAR(MAX)) AS Label
		 , column_Id AS ColumnId
	INTO #PayableInvoiceSummary
	FROM tempdb.sys.columns
	WHERE object_id = OBJECT_ID('tempdb..#PayableInvoiceLifeCycle')
		  AND (Name LIKE '%Vs%'
			   OR Name LIKE '%_difference');

	WHILE EXISTS(SELECT 1 FROM #PayableInvoiceSummary WHERE IsProcessed = 0)
		 BEGIN
			  SELECT TOP 1 @TableName = Name
			  FROM #PayableInvoiceSummary
			  WHERE IsProcessed = 0;
			  
			  SET @query = 'UPDATE #PayableInvoiceSummary SET Count = (SELECT COUNT(*) FROM #PayableInvoiceLifeCycle WHERE ' + @TableName + ' != 0.00), IsProcessed = 1
		 	  			    WHERE Name = ''' + @TableName + ''' ;';
			  EXEC (@query);
		 END;

UPDATE #PayableInvoiceSummary SET Label = CASE WHEN Name = 'ProgressFundingAmountVsTotalProgressPaymentCreditsAmount'
											   THEN '1_Net Progress Fundings Amount = (Progress Payment Credits Amount + Progress Payment Credits Balance)'
											   WHEN Name = 'PayableInvoiceAmount_Difference'
											   THEN '2_Progress Fundings Amount_Difference'
											   WHEN Name = 'ProgressPaymentCreditsAmount_Difference'
											   THEN '3_Progress Payment Credits Amount_Difference'
											   WHEN Name = 'ProgressFundingCreditBalance_Difference'
											   THEN '4_Progress Funding Credit Balance_Difference'
											   WHEN Name = 'ProgressFundingAmountVsTotalProgressPaymentCreditsAmount_GLPosted'
											   THEN '5_GL Posted : Progress Fundings = (Progress Payment Credits + Progress Funding Credit Balance)'
										  END

	SELECT name AS Name
		 , 0 AS Count
		 , CAST(0 AS BIT) AS IsProcessed
		 , CAST('' AS NVARCHAR(MAX)) AS Label
		 , column_Id AS ColumnId
	INTO #TakeDownSummary
	FROM tempdb.sys.columns
	WHERE object_id = OBJECT_ID('tempdb..#TakeDownLifeCycle')
		  AND (Name LIKE '%Vs%'
			   OR Name LIKE '%_difference');

	WHILE EXISTS(SELECT 1 FROM #PayableInvoiceSummary WHERE IsProcessed = 0)
		 BEGIN
			  SELECT TOP 1 @TableName = Name
			  FROM #PayableInvoiceSummary
			  WHERE IsProcessed = 0;
			  
			  SET @query = 'UPDATE #PayableInvoiceSummary SET Count = (SELECT COUNT(*) FROM #TakeDownLifeCycle WHERE ' + @TableName + ' != 0.00), IsProcessed = 1
		 	  			    WHERE Name = ''' + @TableName + ''' ;';
			  EXEC (@query);
		 END;

UPDATE #TakeDownSummary SET Label = CASE WHEN Name = 'InterimInterestCapitalization_Difference'
											   THEN '1_Interim Interest Capitalization on Takedown Contracts_Difference'
											   WHEN Name = 'TotalProgressPaymentCreditsAmount_Difference'
											   THEN '2_Total Progress Payment Credits Amount_Difference'
									END

SELECT Label AS Name, Count
FROM #ProgressLoanSummary
ORDER BY ColumnId;

IF (@ResultOption = 'All')
BEGIN
SELECT * 
FROM #ProgressLoanLifeCycle
ORDER BY ContractId;
END

IF (@ResultOption = 'Failed')
BEGIN
SELECT *
FROM #ProgressLoanLifeCycle
WHERE Result = 'Problem Record'
ORDER BY ContractId;
END

IF (@ResultOption = 'Passed')
BEGIN
SELECT *
FROM #ProgressLoanLifeCycle
WHERE Result = 'Not Problem Record'
ORDER BY ContractId;
END

SELECT Label AS Name, Count
FROM #PayableInvoiceSummary;

IF (@ResultOption = 'All')
BEGIN
SELECT * 
FROM #PayableInvoiceLifeCycle
ORDER BY ContractId;
END

IF (@ResultOption = 'Failed')
BEGIN
SELECT *
FROM #PayableInvoiceLifeCycle
WHERE Result = 'Problem Record'
ORDER BY ContractId;
END

IF (@ResultOption = 'Passed')
BEGIN
SELECT *
FROM #PayableInvoiceLifeCycle
WHERE Result = 'Not Problem Record'
ORDER BY ContractId;
END


SELECT Label AS Name, Count
FROM #TakeDownSummary
ORDER BY ColumnId;

IF (@ResultOption = 'All')
BEGIN
SELECT * 
FROM #TakeDownLifeCycle
ORDER BY ContractId;
END

IF (@ResultOption = 'Failed')
BEGIN
SELECT *
FROM #TakeDownLifeCycle
WHERE Result = 'Problem Record'
ORDER BY ContractId;
END

IF (@ResultOption = 'Passed')
BEGIN
SELECT *
FROM #TakeDownLifeCycle
WHERE Result = 'Not Problem Record'
ORDER BY ContractId;
END


		DECLARE @TotalCount BIGINT;
		SELECT @TotalCount = ISNULL(COUNT(*), 0) FROM #ProgressLoanLifeCycle
		DECLARE @InCorrectCount BIGINT;
		SELECT @InCorrectCount = ISNULL(COUNT(*), 0) FROM #ProgressLoanLifeCycle WHERE Result  = 'Problem Record' 
		DECLARE @Messages StoredProcMessage
		
		INSERT INTO @Messages(Name, ParameterValuesCsv) VALUES('TotalLoans', (Select 'Loans=' + CONVERT(nvarchar(40), @TotalCount)))
		INSERT INTO @Messages(Name, ParameterValuesCsv) VALUES('LoanSuccessful', (Select 'LoanSuccessful=' + CONVERT(nvarchar(40), (@TotalCount - @InCorrectCount))))
		INSERT INTO @Messages(Name, ParameterValuesCsv) VALUES('LoanIncorrect', (Select 'LoanIncorrect=' + CONVERT(nvarchar(40), @InCorrectCount)))

	 	INSERT INTO @Messages(Name, ParameterValuesCsv) VALUES('LoanResultOption', (Select 'ResultOption=' + CONVERT(nvarchar(40), @ResultOption)))

		SELECT * FROM @Messages
	  
DROP TABLE #EligibleContracts
DROP TABLE #PayableInvoiceDetails
DROP TABLE #TotalProgressFundingAmount
DROP TABLE #TakeDownPayableInvoiceDetails
DROP TABLE #TotalTakeDownAmount
DROP TABLE #NoOfFundings
DROP TABLE #NoOfTakeDowns
DROP TABLE #GLJournalDetails
DROP TABLE #DisbursementGL
DROP TABLE #ProgressPaymentCreditGLAmount
DROP TABLE #ProgressPaymentCredit
DROP TABLE #GLJournalValues
DROP TABLE #ReceiptDetails
DROP TABLE #Receivables
DROP TABLE #ReceivableDetails
DROP TABLE #PayableInvoiceIds
DROP TABLE #PayableInvoiceAmount
DROP TABLE #PayableInvoiceGLJournalDetails
DROP TABLE #TotalPayableInvoiceTakeDownAmount
DROP TABLE #ProgressPaymentCreditPayableInvoiceGLAmount
DROP TABLE #ProgressCreditDetails
DROP TABLE #LoanInterimInterestCapitalization
DROP TABLE #LeaseInterimInterestCapitalization
DROP TABLE #RenewalDetails
DROP TABLE #PayableGLCreditDetails
DROP TABLE #PayableGLCreditAmount
DROP TABLE #ProgressCreditDetailsTakeDownAmount
DROP TABLE #ProgressCreditDetailsGLAmount
DROP TABLE #TotalInterimInterestCapitalization
DROP TABLE #CapitalizationGLCreditAmount
DROP TABLE #ProgressLoanInterimInterest
DROP TABLE #InterimInterestGL
DROP TABLE #DisbursementRequestPayableDetails
DROP TABLE #DisbursementRequestProgressPaymentCreditGLAmount
DROP TABLE #DisbursementTableAndGL
DROP TABLE #PayableInvoiceDisbursementTableAndGL
DROP TABLE #UpdatePayableInvoiceGLJournalDetails
DROP TABLE #DisbursementRequestGLJournalDetails
DROP TABLE #UpdateTakeDownGLJournalDetails
DROP TABLE #DuplicatePayableInvoiceIds
DROP TABLE #OriginationRestoredPayableInvoices
DROP TABLE #ProgressLoanLifeCycle
DROP TABLE #PayableInvoiceLifeCycle
DROP TABLE #OriginationRestoredPayableInvoice
DROP TABLE #OriginationPayableInvoice
DROP TABLE #TakeDownLifeCycle
DROP TABLE #ProgressLoanSummary
DROP TABLE #PayableInvoiceSummary
DROP TABLE #TakeDownSummary
DROP TABLE #UnAppliedTable;
DROP TABLE #UnAppliedGL;
DROP TABLE #RefundGLJournalIds;
DROP TABLE #RefundDetails;
END

GO
