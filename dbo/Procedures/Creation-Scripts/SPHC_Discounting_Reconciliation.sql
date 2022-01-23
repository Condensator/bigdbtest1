SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SPHC_Discounting_Reconciliation]
(
	@ResultOption NVARCHAR(20),
	@DiscountingIds ReconciliationId READONLY,
	@LegalEntityIds ReconciliationId READONLY,
	@FunderIds ReconciliationId READONLY
)
AS
BEGIN
	SET NOCOUNT ON
	SET ANSI_WARNINGS OFF
IF OBJECT_ID('tempdb..#EligibleContracts') IS NOT NULL
    DROP TABLE #EligibleContracts;
	
IF OBJECT_ID('tempdb..#NonAccrualDetails') IS NOT NULL
    DROP TABLE #NonAccrualDetails;
	
IF OBJECT_ID('tempdb..#ReAccrualDetails') IS NOT NULL
    DROP TABLE #ReAccrualDetails;
	
IF OBJECT_ID('tempdb..#GLDetails') IS NOT NULL
    DROP TABLE #GLDetails;
	
IF OBJECT_ID('tempdb..#GLPostingDetails') IS NOT NULL
    DROP TABLE #GLPostingDetails;
	
IF OBJECT_ID('tempdb..#PrincipalGLDetails') IS NOT NULL
    DROP TABLE #PrincipalGLDetails;

	
IF OBJECT_ID('tempdb..#DiscountingAmortizationSchedules') IS NOT NULL
    DROP TABLE #DiscountingAmortizationSchedules;
	
IF OBJECT_ID('tempdb..#PayableDetails') IS NOT NULL
    DROP TABLE #PayableDetails;
	
IF OBJECT_ID('tempdb..#FullPaidOffDiscountings') IS NOT NULL
    DROP TABLE #FullPaidOffDiscountings;
	
IF OBJECT_ID('tempdb..#DiscountingPaydowns') IS NOT NULL
    DROP TABLE #DiscountingPaydowns;
	
IF OBJECT_ID('tempdb..#DistinctEligibleContracts') IS NOT NULL
    DROP TABLE #DistinctEligibleContracts;
	
IF OBJECT_ID('tempdb..#DiscountingCapitalizedInterests') IS NOT NULL
    DROP TABLE #DiscountingCapitalizedInterests;
	
IF OBJECT_ID('tempdb..#DiscountingServicingDetails') IS NOT NULL
    DROP TABLE #DiscountingServicingDetails;
	
IF OBJECT_ID('tempdb..#PayableGLJournalsDetails') IS NOT NULL
    DROP TABLE #PayableGLJournalsDetails;
	
IF OBJECT_ID('tempdb..#DiscountingPaydownAtInceptionDetails') IS NOT NULL
    DROP TABLE #DiscountingPaydownAtInceptionDetails;
	
IF OBJECT_ID('tempdb..#SundryReceivablesDetails') IS NOT NULL
    DROP TABLE #SundryReceivablesDetails;

IF OBJECT_ID('tempdb..#DiscountingPaydownNotAtInceptionDetails') IS NOT NULL
    DROP TABLE #DiscountingPaydownNotAtInceptionDetails;
	
IF OBJECT_ID('tempdb..#PaydownDetails') IS NOT NULL
    DROP TABLE #PaydownDetails;
	
IF OBJECT_ID('tempdb..#DiscountingPaydownContractDetails') IS NOT NULL
    DROP TABLE #DiscountingPaydownContractDetails;
	
IF OBJECT_ID('tempdb..#DiscountingSummary') IS NOT NULL
	DROP TABLE #DiscountingSummary;
	
IF OBJECT_ID('tempdb..#Resultlist') IS NOT NULL
	DROP TABLE #Resultlist;
	
DECLARE @u_ConversionSource nvarchar(50); 
SELECT @u_ConversionSource = Value FROM GlobalParameters WHERE Category ='Migration' AND Name = 'ConversionSource'
DECLARE @True BIT= 1;
DECLARE @False BIT= 0;
DECLARE @LegalEntitiesCount BIGINT = ISNULL((SELECT COUNT(*) FROM @LegalEntityIds), 0)
DECLARE @DiscountingCount BIGINT = ISNULL((SELECT COUNT(*) FROM @DiscountingIds), 0)
DECLARE @FundersCount BIGINT = ISNULL((SELECT COUNT(*) FROM @FunderIds), 0)
	
SELECT DISTINCT 
        d.Id AS DiscountingId
	  , c.Id AS ContractId
	  , d.Alias
	  , CAST(c.sequencenumber AS VARCHAR(150)) AS [sequencenumber]
	  , df.LegalEntityId
	  , f.PartyNumber AS FunderPartyNumber
	  , f.PartyName AS FunderName
	  , df.FunderId
	  , c.ContractType
	  , CAST('_' AS VARCHAR(150)) AS [CustomerName]
	  , CAST('_' AS VARCHAR(50)) AS [InstrumentType]
	  , df.Recourse
	  , df.EffectiveDate
	  , df.BookingStatus
	  , df.CommencementDate
	  , df.MaturityDate
	  , df.Tied
	  , df.Advance
	  , df.IsRegularPaymentStream
	  , df.Term
	  , CAST (0.00 AS DECIMAL (16,2)) AS PaymentAmount
	  , df.PaymentAllocation
	  , df.DiscountRate
	  , df.TotalPaymentSold_Amount
	  , CASE
               WHEN dc.IncludeResidual = 1
               THEN CAST('Yes' AS Varchar(20))
               ELSE CAST('No' AS Varchar(20))
           END [IncludeResidual]
	  , df.BookedResidual_Amount
	  , df.DiscountingProceedsAmount_Amount
	  , d.IsNonAccrual
	  , df.NumberOfPayments
	  , df.SharedPercentage
	  , df.IsOnHold
	  , c.u_ConversionSource
INTO #EligibleContracts
FROM Discountings d
     JOIN DiscountingFinances df ON df.DiscountingId = d.Id
	 JOIN DiscountingContracts dc ON df.Id = dc.DiscountingFinanceId
	 JOIN Contracts c ON c.Id = dc.ContractId
	 JOIN Parties f ON f.Id = df.FunderId
WHERE df.IsCurrent = 1
AND (df.BookingStatus = 'Approved'
           OR df.BookingStatus = 'FullyPaidOff')
		   AND @True = (CASE 
						   WHEN @LegalEntitiesCount > 0 AND EXISTS (SELECT Id FROM @LegalEntityIds WHERE Id = df.LegalEntityId) THEN @True
						   WHEN @LegalEntitiesCount = 0 THEN @True ELSE @False END)
		   AND @True = (CASE 
						   WHEN @DiscountingCount > 0 AND EXISTS (SELECT Id FROM @DiscountingIds WHERE Id = df.DiscountingId) THEN @True
						   WHEN @DiscountingCount = 0 THEN @True ELSE @False END)
		   AND @True = (CASE 
						   WHEN @FundersCount > 0 AND EXISTS (SELECT Id FROM @FunderIds WHERE Id = df.FunderId) THEN @True
						   WHEN @FundersCount = 0 THEN @True ELSE @False END)

CREATE NONCLUSTERED INDEX IX_Id ON #EligibleContracts(DiscountingId);
	   
SELECT 
		DISTINCT ec.DiscountingId
		INTO #DistinctEligibleContracts
		FROM #EligibleContracts ec
	
CREATE NONCLUSTERED INDEX IX_Id ON #DistinctEligibleContracts(DiscountingId);
		   
UPDATE ec
  SET 
      sequencenumber = a.sequencenumber
FROM #EligibleContracts ec
INNER JOIN
(
SELECT discountingid, sequencenumber = 
			STUFF((SELECT DISTINCT ', ' + sequencenumber
           FROM #EligibleContracts t
		   WHERE t.DiscountingId = ec.DiscountingId
          FOR XML PATH('')), 1, 2, '')
from #EligibleContracts ec
GROUP BY discountingid
) AS a ON a.discountingid = ec.discountingid

UPDATE ec
  SET 
      ContractType = a.ContractType
FROM #EligibleContracts ec
INNER JOIN
(
SELECT discountingid, ContractType = 
			STUFF((SELECT DISTINCT ', ' + ContractType
           FROM #EligibleContracts t
		   WHERE t.DiscountingId = ec.DiscountingId
          FOR XML PATH('')), 1, 2, '')
from #EligibleContracts ec
GROUP BY discountingid
) AS a ON a.discountingid = ec.discountingid

UPDATE ec
  SET 
      IncludeResidual = a.IncludeResidual
FROM #EligibleContracts ec
INNER JOIN
(
SELECT discountingid, IncludeResidual = 
			STUFF((SELECT DISTINCT ', ' + IncludeResidual
           FROM #EligibleContracts t
		   WHERE t.DiscountingId = ec.DiscountingId
          FOR XML PATH('')), 1, 2, '')
from #EligibleContracts ec
GROUP BY discountingid
) AS a ON a.discountingid = ec.discountingid

UPDATE ec
  SET 
      InstrumentType = it.Code
FROM #EligibleContracts ec
	  JOIN Discountings d ON d.id = ec.DiscountingId
	  JOIN DiscountingFinances df ON df.DiscountingId = d.Id
	  JOIN InstrumentTypes it ON df.instrumenttypeid = it.id
	  
UPDATE ec
  SET 
      InstrumentType = a.InstrumentType
FROM #EligibleContracts ec
INNER JOIN
(
SELECT discountingid, InstrumentType = 
			STUFF((SELECT DISTINCT ', ' + InstrumentType
           FROM #EligibleContracts t
		   WHERE t.DiscountingId = ec.DiscountingId
          FOR XML PATH('')), 1, 2, '')
from #EligibleContracts ec
GROUP BY discountingid
) AS a ON a.discountingid = ec.discountingid

UPDATE ec
  SET 
      PaymentAmount = DRPS.Amount_Amount
FROM #EligibleContracts ec
     INNER JOIN
(
    SELECT MIN(DRPS.Id) DiscountingRepaymentScheduleId
         , ec.DiscountingId
    FROM DiscountingRepaymentSchedules DRPS
		 INNER JOIN DiscountingFinances df ON df.Id = DRPS.DiscountingFinanceId
		 INNER JOIN #EligibleContracts ec ON ec.DiscountingId = df.DiscountingId
    WHERE DRPS.Amount_Amount != 0.00
	AND DRPS.IsActive = 1
	AND df.IsCurrent = 1
    GROUP BY ec.DiscountingId
) AS t ON ec.DiscountingId = t.DiscountingId
     INNER JOIN DiscountingRepaymentSchedules DRPS ON t.DiscountingRepaymentScheduleId = DRPS.Id;
	 
	 
UPDATE ec
  SET 
      CustomerName = p.PartyName
FROM #EligibleContracts ec
	  LEFT JOIN Contracts c ON c.Id = ec.ContractId
	  LEFT JOIN LeaseFinances lf ON lf.ContractId = c.Id
	  LEFT JOIN LoanFinances Lof ON Lof.ContractId = c.Id
	  LEFT JOIN Parties p ON p.id = lf.CustomerId OR p.id = Lof.CustomerId
	  
UPDATE ec
  SET 
      CustomerName = a.CustomerName
FROM #EligibleContracts ec
INNER JOIN
(
SELECT discountingid, CustomerName = 
			STUFF((SELECT DISTINCT ', ' + CustomerName
           FROM #EligibleContracts t
		   WHERE t.DiscountingId = ec.DiscountingId
          FOR XML PATH('')), 1, 2, '')
from #EligibleContracts ec
GROUP BY discountingid
) AS a ON a.discountingid = ec.discountingid
	  
SELECT 
		ec.DiscountingId
		,dp.PayDownDate
	INTO #FullPaidOffDiscountings
	FROM #EligibleContracts ec
		INNER JOIN DiscountingFinances df ON df.DiscountingId = ec.DiscountingId
		INNER JOIN DiscountingPaydowns dp ON dp.DiscountingFinanceId = df.Id
			AND dp.PaydownType = 'FullPaydown' AND dp.Status = 'Active';

CREATE NONCLUSTERED INDEX IX_Id ON #FullPaidOffDiscountings(DiscountingId);


SELECT 
		ec.DiscountingId
		, CASE
               WHEN dsd.Collected = 1
               THEN CAST('Yes' AS Varchar(20))
               ELSE CAST('No' AS Varchar(20))
           END [Collected]
		, CAST(dsd.PerfectPay AS VARCHAR(50)) AS [PerfectPay]
	INTO #DiscountingServicingDetails
	FROM #EligibleContracts ec
		INNER JOIN DiscountingFinances df ON df.DiscountingId = ec.DiscountingId
		INNER JOIN DiscountingServicingDetails dsd ON dsd.DiscountingFinanceId = df.Id;

CREATE NONCLUSTERED INDEX IX_Id ON #DiscountingServicingDetails(DiscountingId);

UPDATE dsd
  SET 
      Collected = a.Collected
FROM #DiscountingServicingDetails dsd
INNER JOIN
(
SELECT discountingid, Collected = 
			STUFF((SELECT DISTINCT ', ' + Collected
           FROM #DiscountingServicingDetails t
		   WHERE t.DiscountingId = dsd.DiscountingId
          FOR XML PATH('')), 1, 2, '')
from #DiscountingServicingDetails dsd
GROUP BY discountingid
) AS a ON a.discountingid = dsd.discountingid

UPDATE dsd
  SET 
      PerfectPay = a.PerfectPay
FROM #DiscountingServicingDetails dsd
INNER JOIN
(
SELECT discountingid, PerfectPay = 
			STUFF((SELECT DISTINCT ', ' + PerfectPay
           FROM #DiscountingServicingDetails t
		   WHERE t.DiscountingId = dsd.DiscountingId
          FOR XML PATH('')), 1, 2, '')
from #DiscountingServicingDetails dsd
GROUP BY discountingid
) AS a ON a.discountingid = dsd.discountingid
		   
		   
SELECT ec.DiscountingId
     , MAX(DNAD.DiscountingNonAccrualId) AS DiscountingNonAccrualId
     , MAX(DNAD.NonAccrualDate) AS NonAccrualDate
INTO #NonAccrualDetails
FROM #EligibleContracts ec
	INNER JOIN DiscountingNonAccrualDetails DNAD ON ec.DiscountingId = DNAD.DiscountingId
	INNER JOIN DiscountingNonAccruals DNA ON DNAD.DiscountingNonAccrualId = DNA.Id
	WHERE DNAD.IsActive = 1 AND DNA.Status = 'Approved'
GROUP BY ec.DiscountingId;

SELECT ec.DiscountingId
	 , MAX(DRAD.DiscountingReAccrualId) AS DiscountingReAccrualId
	 , MAX(DRAD.ReAccrualDate) AS ReAccrualDate
INTO #ReAccrualDetails
FROM #EligibleContracts ec
	INNER JOIN DiscountingReAccrualDetails DRAD ON ec.DiscountingId = DRAD.DiscountingId
	INNER JOIN DiscountingReAccruals DRA ON DRAD.DiscountingReAccrualId = DRA.Id
	WHERE DRAD.IsActive = 1 AND DRA.Status = 'Approved'
GROUP BY ec.DiscountingId;

SELECT decc.DiscountingId
		, dp.PaydownAtInception
		, dp.PaydownType
INTO #PaydownDetails
		FROM #DistinctEligibleContracts decc
			 INNER JOIN DiscountingFinances df on df.DiscountingId = decc.DiscountingId
			 INNER JOIN DiscountingPaydowns dp ON dp.DiscountingFinanceId = df.Id
		WHERE dp.status = 'Active'

CREATE NONCLUSTERED INDEX IX_Id ON #PaydownDetails(DiscountingId);

SELECT decc.DiscountingId
	 , SUM(CASE
               WHEN dis.IsNonAccrual = 0
			   AND dis.IsGLPosted = 1
			   AND dis.IsAccounting = 1
               THEN dis.InterestAccrued_Amount
               ELSE 0
           END) AS InterestExpenseAmount
	 , SUM(CASE
               WHEN dis.IsNonAccrual = 1
			   AND dis.IsGLPosted = 1
			   AND dis.IsAccounting = 1
               THEN dis.InterestAccrued_Amount
               ELSE 0
           END) AS SuspendedInterestExpenseAmount
	 , SUM(CASE
               WHEN dis.IsSchedule = 1
               THEN dis.PrincipalAdded_Amount
               ELSE 0
           END) AS PrincipalAddedAmount
	 , SUM(CASE
               WHEN dis.IsNonAccrual = 0
			   AND dis.IsGLPosted = 1
			   AND dis.IsAccounting = 1
               THEN dis.InterestAccrued_Amount
               ELSE 0
           END) AS AccruedInterestExpense_Amount
INTO #DiscountingAmortizationSchedules
FROM #DistinctEligibleContracts decc
     INNER JOIN DiscountingFinances df ON df.DiscountingId = decc.DiscountingId
     INNER JOIN DiscountingAmortizationSchedules dis ON dis.DiscountingFinanceId = df.Id
GROUP BY decc.DiscountingId;

CREATE NONCLUSTERED INDEX IX_Id ON #DiscountingAmortizationSchedules(DiscountingId);


SELECT decc.DiscountingId
	 , SUM(CASE
               WHEN dci.IsActive = 1
               THEN dci.Amount_Amount
               ELSE 0
           END) AS CapitalizedInterestAmount
INTO #DiscountingCapitalizedInterests
FROM #DistinctEligibleContracts decc
     INNER JOIN DiscountingFinances df ON df.DiscountingId = decc.DiscountingId
     INNER JOIN DiscountingCapitalizedInterests dci ON dci.DiscountingFinanceId = df.Id
	 WHERE GLJournalId IS NOT NULL
	 AND df.IsCurrent = 1
GROUP BY decc.DiscountingId;

CREATE NONCLUSTERED INDEX IX_Id ON #DiscountingCapitalizedInterests(DiscountingId);

SELECT decc.DiscountingId
	 , SUM(CASE
               WHEN dp.Status = 'Active'
			   AND dp.PaydownAtInception = 1
               THEN dp.PrincipalPaydown_Amount
               ELSE 0
           END) AS PrincipalPaydownAmount
	 , SUM(CASE
               WHEN dp.Status = 'Active'
			   AND dp.PaydownType='FullPaydown'
               THEN dp.InterestPaydown_Amount
               ELSE 0
           END) AS InterestPaydown_Amount
	 , SUM(CASE
               WHEN dp.Status = 'Active'
			   AND dp.PaydownType='FullPaydown'
               THEN dp.AccruedInterest_Amount
               ELSE 0
           END) AS AccruedInterest_Amount
INTO #DiscountingPaydowns
FROM #DistinctEligibleContracts decc
     INNER JOIN DiscountingFinances df ON df.DiscountingId = decc.DiscountingId
	 INNER JOIN DiscountingPaydowns dp ON dp.DiscountingFinanceId = df.Id
GROUP BY decc.DiscountingId;

CREATE NONCLUSTERED INDEX IX_Id ON #DiscountingPaydowns(DiscountingId);

SELECT decc.DiscountingId
	   , dp.paydowntype
	   , SUM(CASE
               WHEN dp.PaydownAtInception = 1
			   AND dp.paydowntype = 'FullPaydown'
               THEN dp.PrincipalPaydown_Amount
               ELSE 0
           END) AS PrincipalPaydownAtInception_Amount
		, SUM(CASE
               WHEN dp.PaydownAtInception = 1
			   AND dp.paydowntype = 'FullPaydown'
               THEN dp.PrincipalBalance_Amount
               ELSE 0
           END) AS PrincipalBalanceAtInception_Amount
	   , SUM(CASE
               WHEN dp.PaydownAtInception = 1
			   AND dp.paydowntype = 'PartialPaydown'
               THEN dp.PrincipalPaydown_Amount
               ELSE 0
           END) AS PrincipalPaydown_Partial_Amount
		, SUM(CASE
               WHEN dp.PaydownAtInception = 1
			   AND dp.paydowntype = 'PartialPaydown'
               THEN dp.PrincipalBalance_Amount
               ELSE 0
           END) AS PrincipalBalance_Partial_Amount
INTO #DiscountingPaydownAtInceptionDetails
		FROM #DistinctEligibleContracts decc
			 INNER JOIN DiscountingFinances df on df.DiscountingId = decc.DiscountingId
			 INNER JOIN DiscountingPaydowns dp ON dp.DiscountingFinanceId = df.Id
		WHERE dp.status = 'Active' AND dp.PaydownAtInception = 1
		GROUP BY decc.DiscountingId, dp.paydowntype;

CREATE NONCLUSTERED INDEX IX_Id ON #DiscountingPaydownAtInceptionDetails(DiscountingId);

SELECT decc.DiscountingId
		, SUM(CASE
               WHEN dp.PaydownAtInception = 0
               THEN dp.PrincipalPaydown_Amount
               ELSE 0
           END) AS PrincipalPaydown_Amount
		, SUM(CASE
               WHEN dp.PaydownAtInception = 0
               THEN dp.PrincipalBalance_Amount
               ELSE 0
           END) AS PrincipalBalance_Amount
INTO #DiscountingPaydownNotAtInceptionDetails
		FROM #DistinctEligibleContracts decc
			 INNER JOIN DiscountingFinances df on df.DiscountingId = decc.DiscountingId
			 INNER JOIN DiscountingPaydowns dp ON dp.DiscountingFinanceId = df.Id
		WHERE dp.status = 'Active' and dp.paydowntype = 'FullPaydown'
		GROUP BY decc.DiscountingId;

CREATE NONCLUSTERED INDEX IX_Id ON #DiscountingPaydownNotAtInceptionDetails(DiscountingId);

SELECT decc.DiscountingId
	 , SUM(CASE
               WHEN Sundries.SundryType = 'ReceivableOnly'
               THEN Receivables.TotalAmount_Amount
               ELSE 0
           END) AS SundryReceivableAmount
INTO #SundryReceivablesDetails
FROM #DistinctEligibleContracts decc
     INNER JOIN Receivables ON Receivables.EntityId  = decc.DiscountingId
	 INNER JOIN Sundries ON Sundries.Id = Receivables.SourceId
	 WHERE Receivables.Entitytype = 'DT'
	 AND Receivables.IsGLPosted = 1
	 AND Receivables.IsActive = 1
	 AND Receivables.SourceTable='Sundry'
GROUP BY decc.DiscountingId;

CREATE NONCLUSTERED INDEX IX_Id ON #SundryReceivablesDetails(DiscountingId);

SELECT decc.DiscountingId
	 , SUM(CASE
               WHEN dpcd.IsActive = 1
               THEN dpcd.ResidualGainLoss_Amount
               ELSE 0
           END) AS ResidualGainLoss_Amount
INTO #DiscountingPaydownContractDetails
FROM #DistinctEligibleContracts decc
     INNER JOIN DiscountingFinances df on df.DiscountingId = decc.DiscountingId
	 INNER JOIN DiscountingPaydowns dp ON dp.DiscountingFinanceId = df.Id
	 INNER JOIN DiscountingPaydownContractDetails dpcd ON dpcd.DiscountingPaydownId = dp.Id
	 WHERE dp.status = 'Active'
GROUP BY decc.DiscountingId;

CREATE NONCLUSTERED INDEX IX_Id ON #DiscountingPaydownContractDetails(DiscountingId);


SELECT decc.DiscountingId
	 , SUM(CASE
               WHEN p.IsGLPosted = 1
			   AND pt.Name = 'DiscountingInterest'
               THEN p.Amount_Amount
               ELSE 0
           END) AS InterestPayablePosted_Amount
	 , SUM(CASE
               WHEN p.IsGLPosted = 1
			   AND pt.Name = 'DiscountingPrincipal'
               THEN p.Amount_Amount
               ELSE 0
           END) AS PrincipalPayablePosted_Amount
	 , SUM(CASE
               WHEN pt.Name = 'DiscountingInterest'
               THEN p.Amount_Amount
               ELSE 0
           END) AS CashPaid_InterestPayable_Amount
	 , SUM(CASE
               WHEN pt.Name = 'DiscountingPrincipal'
               THEN p.Amount_Amount
               ELSE 0
           END) AS CashPaid_PrincipalPayable_Amount
	 , SUM(CASE
               WHEN pt.Name = 'DiscountingInterest' 
               THEN p.Balance_Amount
               ELSE 0
           END) AS CashPaid_InterestPayable_Balance
	 , SUM(CASE
               WHEN pt.Name = 'DiscountingPrincipal'
               THEN p.Balance_Amount
               ELSE 0
           END) AS CashPaid_PrincipalPayable_Balance
INTO #PayableDetails
FROM #DistinctEligibleContracts decc
     INNER JOIN Payables p ON p.EntityId = decc.DiscountingId
	 INNER JOIN PayableCodes pc ON pc.Id = p.PayableCodeId
	 INNER JOIN PayableTypes pt ON pt.Id = pc.PayableTypeId
GROUP BY decc.DiscountingId;

CREATE NONCLUSTERED INDEX IX_Id ON #PayableDetails(DiscountingId);


SELECT decc.DiscountingId
     , SUM(CASE
               WHEN gld.IsDebit = 0
			   AND gle.Name = 'InterestExpense'
			   AND gtt.Name = 'DiscountingExpenseRecognition'
               THEN gld.Amount_Amount
               ELSE 0
           END) AS InterestExpense_CreditAmount
	 , SUM(CASE
               WHEN gld.IsDebit = 1
			   AND gle.Name = 'InterestExpense'
			   AND gtt.Name = 'DiscountingExpenseRecognition'
               THEN gld.Amount_Amount
               ELSE 0
           END) AS InterestExpense_DebitAmount
	 , SUM(CASE
               WHEN gld.IsDebit = 0
			   AND gle.Name = 'SuspendedInterestExpense'
			   AND gtt.Name = 'DiscountingExpenseRecognition'
               THEN gld.Amount_Amount
               ELSE 0
           END) AS SuspendedInterestExpense_CreditAmount
	 , SUM(CASE
               WHEN gld.IsDebit = 1
			   AND gle.Name = 'SuspendedInterestExpense'
			   AND gtt.Name = 'DiscountingExpenseRecognition'
               THEN gld.Amount_Amount
               ELSE 0
           END) AS SuspendedInterestExpense_DebitAmount
	 , SUM(CASE
               WHEN gld.IsDebit = 0
			   AND gle.Name = 'NotePayable'
			   AND gtt.Name = 'Discounting'
               THEN gld.Amount_Amount
               ELSE 0
           END) AS Principal_CreditAmount
	 , SUM(CASE
               WHEN gld.IsDebit = 1
			   AND gle.Name = 'NotePayable'
			   AND gtt.Name = 'Discounting'
               THEN gld.Amount_Amount
               ELSE 0
           END) AS Principal_DebitAmount
	 , SUM(CASE
               WHEN gld.IsDebit = 0
			   AND gle.Name = 'AccruedInterestExpenseCapitalized'
			   AND gtt.Name = 'Discounting'
               THEN gld.Amount_Amount
               ELSE 0
           END) AS TotalCapitalizedInterest_CreditAmount
	 , SUM(CASE
               WHEN gld.IsDebit = 1
			   AND gle.Name = 'AccruedInterestExpenseCapitalized'
			   AND gtt.Name = 'Discounting'
               THEN gld.Amount_Amount
               ELSE 0
           END) AS TotalCapitalizedInterest_DebitAmount
INTO #GLDetails
FROM #DistinctEligibleContracts decc
     INNER JOIN GLJournalDetails gld ON gld.EntityId = decc.DiscountingId
     INNER JOIN GLTemplateDetails gtd ON gld.GLTemplateDetailId = gtd.Id
     INNER JOIN GLEntryItems gle ON gtd.EntryItemId = gle.Id
     INNER JOIN GLTransactionTypes gtt ON gle.GLTransactionTypeId = gtt.Id
GROUP BY decc.DiscountingId;

CREATE NONCLUSTERED INDEX IX_Id ON #GLDetails(DiscountingId);

SELECT decc.DiscountingId
	 , SUM(CASE
               WHEN gld.IsDebit = 0
			   AND gle.Name = 'NotePayable'
               THEN gld.Amount_Amount
               ELSE 0
           END) AS TotalPrincipal_CreditAmount
	 , SUM(CASE
               WHEN gld.IsDebit = 1
			  AND gle.Name = 'NotePayable'
               THEN gld.Amount_Amount
               ELSE 0
           END) AS TotalPrincipal_DebitAmount
	 , SUM(CASE
               WHEN gld.IsDebit = 0
			   AND gle.Name = 'AccruedInterestExpense'
               THEN gld.Amount_Amount
               ELSE 0
           END) AS AccruedInterestExpense_CreditAmount
	 , SUM(CASE
               WHEN gld.IsDebit = 1
			  AND gle.Name = 'AccruedInterestExpense'
               THEN gld.Amount_Amount
               ELSE 0
           END) AS AccruedInterestExpense_DebitAmount
	 , SUM(CASE
               WHEN gld.IsDebit = 0
			   AND gle.Name IN('NonRentalReceivable','PrepaidNonRentalReceivable','PrePaidDueFromInterCompanyReceivable','DueFromInterCompanyReceivable') 
			   AND gtt.Name = 'NonRentalAR'
               THEN gld.Amount_Amount
               ELSE 0
           END) AS SundryReceivables_CreditAmount
	 , SUM(CASE
               WHEN gld.IsDebit = 1
			   AND gle.Name IN('NonRentalReceivable','PrepaidNonRentalReceivable','PrePaidDueFromInterCompanyReceivable','DueFromInterCompanyReceivable') 
			   AND gtt.Name = 'NonRentalAR'
               THEN gld.Amount_Amount
               ELSE 0
           END) AS SundryReceivables_DebitAmount
INTO #PrincipalGLDetails
FROM #DistinctEligibleContracts decc
	 INNER JOIN GLJournalDetails gld ON gld.EntityId = decc.DiscountingId
     INNER JOIN GLTemplateDetails gtd ON gld.GLTemplateDetailId = gtd.Id
     INNER JOIN GLEntryItems gle ON gtd.EntryItemId = gle.Id
     INNER JOIN GLTransactionTypes gtt ON gle.GLTransactionTypeId = gtt.Id
	 WHERE Entitytype = 'Discounting'
GROUP BY decc.DiscountingId;

CREATE NONCLUSTERED INDEX IX_Id ON #PrincipalGLDetails(DiscountingId);

SELECT DISTINCT 
	  decc.DiscountingId
	 , pgl.GLJournalId
INTO #PayableGLJournalsDetails
FROM #DistinctEligibleContracts decc
	 JOIN Payables p on p.EntityId = decc.DiscountingId
	 JOIN DisbursementRequestPayables drp ON drp.PayableId = p.id
	 JOIN disbursementrequests dr ON drp.DisbursementRequestId = dr.Id 
	 JOIN PayableGLJournals pgl ON pgl.PayableId = drp.PayableId
	 WHERE dr.OriginationType = 'Discounting';

CREATE NONCLUSTERED INDEX IX_Id ON #PayableGLJournalsDetails(DiscountingId);


SELECT decc.DiscountingId
	 , SUM(CASE
               WHEN gld.IsDebit = 0
			   AND gle.Name = 'NotePayable'
               THEN gld.Amount_Amount
               ELSE 0
           END) AS RemainingPrincipalBalance_CreditAmount
	 , SUM(CASE
               WHEN gld.IsDebit = 1
			  AND gle.Name = 'NotePayable'
               THEN gld.Amount_Amount
               ELSE 0
           END) AS RemainingPrincipalBalance_DebitAmount
	 , SUM(CASE
               WHEN gld.IsDebit = 0
			   AND gle.Name = 'DiscountingPayableInterest' 
			   AND gtt.Name = 'DiscountingInterestPayable'
               THEN gld.Amount_Amount
               ELSE 0
           END) AS InterestPayablePosted_CreditAmount
	 , SUM(CASE
               WHEN gld.IsDebit = 1
			   AND gle.Name = 'DiscountingPayableInterest'
			  AND gtt.Name = 'DiscountingInterestPayable'
               THEN gld.Amount_Amount
               ELSE 0
           END) AS InterestPayablePosted_DebitAmount
	 , SUM(CASE
               WHEN gld.IsDebit = 0
			   AND gle.Name = 'DiscountingPayablePrincipal' 
			   AND gtt.Name = 'DiscountingPrincipalPayable'
               THEN gld.Amount_Amount
               ELSE 0
           END) AS PrincipalPayablePosted_CreditAmount
	 , SUM(CASE
               WHEN gld.IsDebit = 1
			   AND gle.Name = 'DiscountingPayablePrincipal'
			  AND gtt.Name = 'DiscountingPrincipalPayable'
               THEN gld.Amount_Amount
               ELSE 0
           END) AS PrincipalPayablePosted_DebitAmount
	 , SUM(CASE
               WHEN gld.IsDebit = 0
			   AND gle.Name = 'AccruedInterestExpense'
               THEN gld.Amount_Amount
               ELSE 0
           END) AS AccruedInterestExpense_DR_CreditAmount
	 , SUM(CASE
               WHEN gld.IsDebit = 1
			  AND gle.Name = 'AccruedInterestExpense'
               THEN gld.Amount_Amount
               ELSE 0
           END) AS AccruedInterestExpense_DR_DebitAmount
INTO #GLPostingDetails
FROM #DistinctEligibleContracts decc
	 INNER JOIN #PayableGLJournalsDetails pgld ON pgld.DiscountingId = decc.DiscountingId
	 INNER JOIN GLJournalDetails gld ON gld.gljournalid = pgld.gljournalid
	 INNER JOIN GLTemplateDetails gtd ON gld.GLTemplateDetailId = gtd.Id
     INNER JOIN GLEntryItems gle ON gtd.EntryItemId = gle.Id
     INNER JOIN GLTransactionTypes gtt ON gle.GLTransactionTypeId = gtt.Id
GROUP BY decc.DiscountingId;

CREATE NONCLUSTERED INDEX IX_Id ON #GLPostingDetails(DiscountingId);
		   
SELECT *	   
	, CASE
			   WHEN [InterestExpense_Difference] != 0.00
					OR [SuspendedInterestExpense_Difference] != 0.00
					OR [TotalNoteAmount_Difference] != 0.00
					OR [TotalCapitalizedInterestAmount_Difference] != 0.00
					OR [NotePayableBalance_Difference] != 0.00
					OR [InterestPayablePosted_Difference] != 0.00
					OR [PrincipalPayablePosted_Difference] != 0.00
					OR [SundryReceivables_Difference] != 0.00
					OR [AccruedInterestExpense_Difference] != 0.00
			   THEN 'Problem Record'
			   ELSE 'Not Problem Record'
		   END [Result]
INTO #Resultlist
FROM
(
	SELECT  DISTINCT 
			d.SequenceNumber AS [DiscountingSequenceNumber]
		   , d.Alias AS [DiscountingAlias]
		   , d.Id AS [DiscountingId]
		   , CASE
               WHEN ec.u_conversionsource = ISNULL(@u_ConversionSource, 'PMS')
               THEN 'Migrated'
               ELSE 'Not Migrated'
           END AS 'IsMigrated'
		   , ec.SequenceNumber AS [ContractSequenceNumber]
		   , le.Name [LegalEntityName]
		   , ec.FunderPartyNumber [FunderPartyNumber] 
		   , ec.FunderName [FunderName]
		   , ec.ContractType
		   , ec.CustomerName
		   , ec.InstrumentType [InstrumentTypeCode]
		   , ec.Recourse
		   , ec.EffectiveDate
		   , ec.BookingStatus
		   , ec.CommencementDate [CommencementDate]
		   , ec.MaturityDate [MaturityDate]
		   , fpod.PayDownDate [FullPayOffEffectiveDate]
		   , CASE 
			   WHEN ec.Tied = 1
			   THEN 'Tied'
			   ELSE 'UnTied' 
		   END [TiedUntiedDiscounting]
		   , ec.SharedPercentage
		   , CASE 
			   WHEN ec.Advance = 1
			   THEN 'Advance'
			   ELSE 'Arrear' 
		   END [ArrearORAdvance]
		   , CASE 
			   WHEN ec.IsRegularPaymentStream = 0 
			   THEN 'Irregular'
			   ELSE 'Regular' 
		   END [RegularOrIrregularPayment]
		   , ec.Term
		   , ec.PaymentAmount [PaymentAmount]
		   , ec.PaymentAllocation
		   , ec.NumberOfPayments
		   , ec.DiscountRate
		   , ec.TotalPaymentSold_Amount [TotalPaymentSoldAmount]
		   , ec.IncludeResidual [IsResidualIncluded]
		   , ec.BookedResidual_Amount [ResidualBookedAmount]
		   , dsd.PerfectPay [IsPerfectPay]
		   , dsd.Collected [IsCollected]
		   , CASE 
			   WHEN ec.IsOnHold = 1
			   THEN 'Yes'
			   ELSE 'No' 
		   END [OnHold]
		   , ec.DiscountingProceedsAmount_Amount [DiscountingProceedsAmount]
		   , CASE
               WHEN ec.IsNonAccrual = 0
               THEN 'Accrual'
               ELSE 'Non-Accrual'
           END [AccrualStatus]
		   , CASE
               WHEN nad.DiscountingNonAccrualId IS NOT NULL
               THEN 'Was Non-Accrual'
               ELSE 'Was Not Non-Accrual'
           END AS [WasNonAccrualAnytime]
		 , nad.NonAccrualDate [NonAccrualDate]
         , CASE
               WHEN rad.DiscountingReAccrualId IS NOT NULL
               THEN 'Yes'
               ELSE 'No'
           END AS [IsReAccrualDone]
         , rad.ReAccrualDate [ReAccrualDate]
		 , CASE
               WHEN dpdat.DiscountingId IS NOT NULL
			   THEN CASE
			   WHEN ec.BookingStatus = 'FullyPaidOff'
               THEN ISNULL(dis.PrincipalAddedAmount, 0.00) + ISNULL(dci.CapitalizedInterestAmount, 0.00) + ISNULL(dpdat.PrincipalBalanceAtInception_Amount, 0.00)
               ELSE ISNULL(dis.PrincipalAddedAmount, 0.00) + ISNULL(dci.CapitalizedInterestAmount, 0.00) + ISNULL(dpdat.PrincipalPaydown_Partial_Amount, 0.00)
			   END
			   ELSE ISNULL(dis.PrincipalAddedAmount, 0.00) + ISNULL(dci.CapitalizedInterestAmount, 0.00)
		   END AS [TotalNoteAmount_Table]
		 , ISNULL(gld.Principal_CreditAmount, 0.00) - ISNULL(gld.Principal_DebitAmount, 0.00) AS [TotalNoteAmount_GL]
		 , CASE
               WHEN dpdat.DiscountingId IS NOT NULL
			   THEN CASE
			   WHEN ec.BookingStatus = 'FullyPaidOff'
               THEN ISNULL(dis.PrincipalAddedAmount, 0.00) + ISNULL(dci.CapitalizedInterestAmount, 0.00) + ISNULL(dpdat.PrincipalBalanceAtInception_Amount, 0.00) - (ISNULL(gld.Principal_CreditAmount, 0.00) - ISNULL(gld.Principal_DebitAmount, 0.00))
               ELSE ISNULL(dis.PrincipalAddedAmount, 0.00) + ISNULL(dci.CapitalizedInterestAmount, 0.00) + ISNULL(dpdat.PrincipalPaydown_Partial_Amount, 0.00) - (ISNULL(gld.Principal_CreditAmount, 0.00) - ISNULL(gld.Principal_DebitAmount, 0.00))
			   END
			   ELSE ISNULL(dis.PrincipalAddedAmount, 0.00) + ISNULL(dci.CapitalizedInterestAmount, 0.00) - (ISNULL(gld.Principal_CreditAmount, 0.00) - ISNULL(gld.Principal_DebitAmount, 0.00))
		   END AS [TotalNoteAmount_Difference]
		 , ISNULL(srd.SundryReceivableAmount, 0.00) [SundryReceivables_Table]
		 , ISNULL(pgd.SundryReceivables_DebitAmount, 0.00) - ISNULL(pgd.SundryReceivables_CreditAmount, 0.00) [SundryReceivables_GL]
		 , ISNULL(srd.SundryReceivableAmount, 0.00) - (ISNULL(pgd.SundryReceivables_DebitAmount, 0.00) - ISNULL(pgd.SundryReceivables_CreditAmount, 0.00)) [SundryReceivables_Difference]
		 , ISNULL(dis.InterestExpenseAmount, 0.00) [InterestExpense_Schedule]
		 , ISNULL(gld.InterestExpense_DebitAmount, 0.00) - ISNULL(gld.InterestExpense_CreditAmount, 0.00) AS [InterestExpense_GL]
		 , ISNULL(dis.InterestExpenseAmount, 0.00) - (ISNULL(gld.InterestExpense_DebitAmount, 0.00) - ISNULL(gld.InterestExpense_CreditAmount, 0.00)) AS [InterestExpense_Difference]
		 , ISNULL(dis.SuspendedInterestExpenseAmount, 0.00) [SuspendedInterestExpense_Schedule]
		 , ISNULL(gld.SuspendedInterestExpense_DebitAmount, 0.00) - ISNULL(gld.SuspendedInterestExpense_CreditAmount, 0.00) AS [SuspendedInterestExpense_GL]
		 , ISNULL(dis.SuspendedInterestExpenseAmount, 0.00) - (ISNULL(gld.SuspendedInterestExpense_DebitAmount, 0.00) - ISNULL(gld.SuspendedInterestExpense_CreditAmount, 0.00)) AS [SuspendedInterestExpense_Difference]
		 , ISNULL(dci.CapitalizedInterestAmount, 0.00) [TotalCapitalizedInterestAmount_Table]
		 , ISNULL(gld.TotalCapitalizedInterest_DebitAmount, 0.00) - ISNULL(gld.TotalCapitalizedInterest_CreditAmount, 0.00) AS [TotalCapitalizedInterestAmount_GL]
		 , ISNULL(dci.CapitalizedInterestAmount, 0.00) - (ISNULL(gld.TotalCapitalizedInterest_DebitAmount, 0.00) - ISNULL(gld.TotalCapitalizedInterest_CreditAmount, 0.00)) [TotalCapitalizedInterestAmount_Difference] 
		 , CASE
               WHEN dpdat.DiscountingId IS NOT NULL
			   THEN CASE
			   WHEN ec.BookingStatus = 'FullyPaidOff'
               THEN ISNULL(dis.PrincipalAddedAmount, 0.00) + ISNULL(dci.CapitalizedInterestAmount, 0.00) + ISNULL(dpdat.PrincipalBalanceAtInception_Amount, 0.00) - ABS(ISNULL(pd.PrincipalPayablePosted_Amount, 0.00)) - (ISNULL(dpdat.PrincipalBalanceAtInception_Amount, 0.00) - ISNULL(dpdat.PrincipalPaydownAtInception_Amount, 0.00)) 
               ELSE ISNULL(dis.PrincipalAddedAmount, 0.00) + ISNULL(dci.CapitalizedInterestAmount, 0.00) + ISNULL(dpdat.PrincipalBalance_Partial_Amount, 0.00) - ABS(ISNULL(pd.PrincipalPayablePosted_Amount, 0.00)) - (ISNULL(dpdat.PrincipalBalance_Partial_Amount, 0.00) - ISNULL(dpdat.PrincipalPaydown_Partial_Amount, 0.00)) 
			   END
			   ELSE ISNULL(dis.PrincipalAddedAmount, 0.00) + ISNULL(dci.CapitalizedInterestAmount, 0.00) - ABS(ISNULL(pd.PrincipalPayablePosted_Amount, 0.00)) - (ISNULL(dpdnat.PrincipalBalance_Amount, 0.00) - ISNULL(dpdnat.PrincipalPaydown_Amount, 0.00)) - ISNULL(dpcd.ResidualGainLoss_Amount, 0.00)
		   END AS [NotePayableBalance_Table]
		 , ABS(ISNULL(pgd.TotalPrincipal_CreditAmount, 0.00) - ISNULL(pgd.TotalPrincipal_DebitAmount, 0.00)) - ABS(ISNULL(gpd.RemainingPrincipalBalance_CreditAmount, 0.00) - ISNULL(gpd.RemainingPrincipalBalance_DebitAmount, 0.00)) [NotePayableBalance_GL]
		 , CASE
               WHEN dpdat.DiscountingId IS NOT NULL
			   THEN CASE
			   WHEN ec.BookingStatus = 'FullyPaidOff'
               THEN ISNULL(dis.PrincipalAddedAmount, 0.00) + ISNULL(dci.CapitalizedInterestAmount, 0.00) + ISNULL(dpdat.PrincipalBalanceAtInception_Amount, 0.00) - ABS(ISNULL(pd.PrincipalPayablePosted_Amount, 0.00)) - (ISNULL(dpdat.PrincipalBalanceAtInception_Amount, 0.00) - ISNULL(dpdat.PrincipalPaydownAtInception_Amount, 0.00)) - (ABS(ISNULL(pgd.TotalPrincipal_CreditAmount, 0.00) - ISNULL(pgd.TotalPrincipal_DebitAmount, 0.00)) - ABS(ISNULL(gpd.RemainingPrincipalBalance_CreditAmount, 0.00) - ISNULL(gpd.RemainingPrincipalBalance_DebitAmount, 0.00)))
               ELSE ISNULL(dis.PrincipalAddedAmount, 0.00) + ISNULL(dci.CapitalizedInterestAmount, 0.00) + ISNULL(dpdat.PrincipalBalance_Partial_Amount, 0.00) - ABS(ISNULL(pd.PrincipalPayablePosted_Amount, 0.00)) - (ISNULL(dpdat.PrincipalBalance_Partial_Amount, 0.00) - ISNULL(dpdat.PrincipalPaydown_Partial_Amount, 0.00)) - (ABS(ISNULL(pgd.TotalPrincipal_CreditAmount, 0.00) - ISNULL(pgd.TotalPrincipal_DebitAmount, 0.00)) - ABS(ISNULL(gpd.RemainingPrincipalBalance_CreditAmount, 0.00) - ISNULL(gpd.RemainingPrincipalBalance_DebitAmount, 0.00)))
			   END
			   ELSE ISNULL(dis.PrincipalAddedAmount, 0.00) + ISNULL(dci.CapitalizedInterestAmount, 0.00) - ABS(ISNULL(pd.PrincipalPayablePosted_Amount, 0.00)) - (ISNULL(dpdnat.PrincipalBalance_Amount, 0.00) - ISNULL(dpdnat.PrincipalPaydown_Amount, 0.00)) - ISNULL(dpcd.ResidualGainLoss_Amount, 0.00) - (ABS(ISNULL(pgd.TotalPrincipal_CreditAmount, 0.00) - ISNULL(pgd.TotalPrincipal_DebitAmount, 0.00)) - ABS(ISNULL(gpd.RemainingPrincipalBalance_CreditAmount, 0.00) - ISNULL(gpd.RemainingPrincipalBalance_DebitAmount, 0.00)))
		   END AS [NotePayableBalance_Difference]
		 , CASE
               WHEN ec.BookingStatus = 'FullyPaidOff'
               THEN ISNULL(dis.AccruedInterestExpense_Amount, 0.00) - ISNULL(pd.InterestPayablePosted_Amount, 0.00) - (ISNULL(dp.AccruedInterest_Amount, 0.00) - ISNULL(dp.InterestPaydown_Amount, 0.00))
               ELSE ISNULL(dis.AccruedInterestExpense_Amount, 0.00) - ISNULL(pd.InterestPayablePosted_Amount, 0.00)
           END AS [AccruedInterestExpense_Table]
		 , ISNULL(pgd.AccruedInterestExpense_CreditAmount, 0.00) - ISNULL(pgd.AccruedInterestExpense_DebitAmount, 0.00) - (ISNULL(gpd.AccruedInterestExpense_DR_DebitAmount, 0.00) - ISNULL(gpd.AccruedInterestExpense_DR_CreditAmount, 0.00)) [AccruedInterestExpense_GL]
		 , CASE
               WHEN ec.BookingStatus = 'FullyPaidOff'
               THEN ISNULL(dis.AccruedInterestExpense_Amount, 0.00) - ISNULL(pd.InterestPayablePosted_Amount, 0.00) - (ISNULL(dp.AccruedInterest_Amount, 0.00) - ISNULL(dp.InterestPaydown_Amount, 0.00)) - (ISNULL(pgd.AccruedInterestExpense_CreditAmount, 0.00) - ISNULL(pgd.AccruedInterestExpense_DebitAmount, 0.00) - (ISNULL(gpd.AccruedInterestExpense_DR_DebitAmount, 0.00) - ISNULL(gpd.AccruedInterestExpense_DR_CreditAmount, 0.00)))
               ELSE ISNULL(dis.AccruedInterestExpense_Amount, 0.00) - ISNULL(pd.InterestPayablePosted_Amount, 0.00) - (ISNULL(pgd.AccruedInterestExpense_CreditAmount, 0.00) - ISNULL(pgd.AccruedInterestExpense_DebitAmount, 0.00) - (ISNULL(gpd.AccruedInterestExpense_DR_DebitAmount, 0.00) - ISNULL(gpd.AccruedInterestExpense_DR_CreditAmount, 0.00)))
           END AS [AccruedInterestExpense_Difference]
		 , ISNULL(pd.InterestPayablePosted_Amount, 0.00) [InterestPayablePosted_Payables]
		 , ISNULL(gpd.InterestPayablePosted_CreditAmount, 0.00) - ISNULL(gpd.InterestPayablePosted_DebitAmount, 0.00) [InterestPayablePosted_GL]
		 , ISNULL(pd.InterestPayablePosted_Amount, 0.00) - (ISNULL(gpd.InterestPayablePosted_CreditAmount, 0.00) - ISNULL(gpd.InterestPayablePosted_DebitAmount, 0.00)) [InterestPayablePosted_Difference]
		 , ISNULL(pd.PrincipalPayablePosted_Amount, 0.00) [PrincipalPayablePosted_Payables]
		 , ISNULL(gpd.PrincipalPayablePosted_CreditAmount, 0.00) - ISNULL(gpd.PrincipalPayablePosted_DebitAmount, 0.00) [PrincipalPayablePosted_GL]
		 , ISNULL(pd.PrincipalPayablePosted_Amount, 0.00) - (ISNULL(gpd.PrincipalPayablePosted_CreditAmount, 0.00) - ISNULL(gpd.PrincipalPayablePosted_DebitAmount, 0.00)) [PrincipalPayablePosted_Difference]
		 , ISNULL(pd.CashPaid_InterestPayable_Amount, 0.00) - ISNULL(pd.CashPaid_InterestPayable_Balance, 0.00) [CashPaid_InterestPayable_Payables]
		 , ISNULL(pd.CashPaid_PrincipalPayable_Amount, 0.00) - ISNULL(pd.CashPaid_PrincipalPayable_Balance, 0.00) [CashPaid_PrincipalPayable_Payables]
	FROM #EligibleContracts ec 
		 INNER JOIN Discountings d ON ec.DiscountingId = d.Id
		 INNER JOIN LegalEntities le ON le.Id = ec.LegalEntityId
		 LEFT JOIN #NonAccrualDetails nad ON nad.DiscountingId = ec.DiscountingId
		 LEFT JOIN #ReAccrualDetails rad ON rad.DiscountingId = ec.DiscountingId
		 LEFT JOIN #PaydownDetails pdd ON pdd.DiscountingId = ec.DiscountingId
		 LEFT JOIN #GLDetails gld ON gld.DiscountingId = ec.DiscountingId
		 LEFT JOIN #GLPostingDetails gpd ON gpd.DiscountingId = ec.DiscountingId
		 LEFT JOIN #DiscountingAmortizationSchedules dis ON dis.DiscountingId = ec.DiscountingId
		 LEFT JOIN #PrincipalGLDetails pgd ON pgd.DiscountingId = ec.DiscountingId
		 LEFT JOIN #PayableDetails pd ON pd.DiscountingId = ec.DiscountingId
		 LEFT JOIN #FullPaidOffDiscountings fpod ON fpod.DiscountingId = ec.DiscountingId
		 LEFT JOIN #DiscountingPaydowns dp ON dp.DiscountingId = ec.DiscountingId
		 LEFT JOIN #DiscountingCapitalizedInterests dci ON dci.DiscountingId = ec.DiscountingId
		 LEFT JOIN #DiscountingServicingDetails dsd ON dsd.DiscountingId = ec.DiscountingId
		 LEFT JOIN #DiscountingPaydownAtInceptionDetails dpdat ON dpdat.DiscountingId = ec.DiscountingId
		 LEFT JOIN #DiscountingPaydownNotAtInceptionDetails dpdnat ON dpdnat.DiscountingId = ec.DiscountingId
		 LEFT JOIN #SundryReceivablesDetails srd ON srd.DiscountingId = ec.DiscountingId
		 LEFT JOIN #DiscountingPaydownContractDetails dpcd ON dpcd.DiscountingId = ec.DiscountingId
	) AS T;
	
CREATE NONCLUSTERED INDEX IX_Id ON #ResultList(DiscountingId);

SELECT name AS Name, 0 AS Count, CAST (0 AS BIT) AS IsProcessed, CAST('' AS NVARCHAR(max)) AS Label, column_Id AS ColumnId
INTO #DiscountingSummary
FROM tempdb.sys.columns
WHERE object_id = OBJECT_ID('tempdb..#ResultList')
	AND Name LIKE '%Difference';
		
DECLARE @query NVARCHAR(MAX);
DECLARE @TableName NVARCHAR(max);
WHILE EXISTS (SELECT 1 FROM #DiscountingSummary WHERE IsProcessed = 0)
BEGIN
SELECT TOP 1 @TableName = Name FROM #DiscountingSummary WHERE IsProcessed = 0

SET @query = 'UPDATE #DiscountingSummary SET Count = (SELECT COUNT(*) FROM #ResultList WHERE ' + @TableName+ ' != 0.00), IsProcessed = 1
			  WHERE Name = '''+ @TableName+''' ;'
EXEC (@query)
END

UPDATE #DiscountingSummary SET 
                        Label = CASE
									WHEN Name ='TotalNoteAmount_Difference'
									THEN '1_Total Note Amount_Difference'
									WHEN Name ='SundryReceivables_Difference'
									THEN '2_Sundry Receivables_Difference'
                                    WHEN Name = 'InterestExpense_Difference'
                                    THEN '3_Interest Expense_Difference'
                                    WHEN Name ='SuspendedInterestExpense_Difference'
									THEN '4_Suspended Interest Expense_Difference'
                                    WHEN Name ='TotalCapitalizedInterestAmount_Difference'
									THEN '5_Total Capitalized Interest Amount_Difference'
                                    WHEN Name ='NotePayableBalance_Difference'
									THEN '6_Note Payable Balance_Difference'
									WHEN Name ='AccruedInterestExpense_Difference'
									THEN '7_Accrued Interest Expense_Difference'
                                    WHEN Name ='InterestPayablePosted_Difference'
									THEN '8_Interest Payable Posted_Difference'
                                    WHEN Name ='PrincipalPayablePosted_Difference'
									THEN '9_Principal Payable Posted_Difference' 
                                END;
								
		SELECT Label AS Name, Count
		FROM #DiscountingSummary
		ORDER BY ColumnId

		IF (@ResultOption = 'All')
		BEGIN
        SELECT *
        FROM #ResultList
		ORDER BY DiscountingId;
		END
		
		IF (@ResultOption = 'Failed')
		BEGIN
		SELECT *
		FROM #ResultList
		WHERE Result = 'Problem Record'
		ORDER BY DiscountingId;
		END

		IF (@ResultOption = 'Passed')
		BEGIN
		SELECT *
		FROM #ResultList
		WHERE Result = 'Not Problem Record'
		ORDER BY DiscountingId;
		END
		
		DECLARE @TotalCount BIGINT;
		SELECT @TotalCount = ISNULL(COUNT(*), 0) FROM #ResultList
		DECLARE @InCorrectCount BIGINT;
		SELECT @InCorrectCount = ISNULL(COUNT(*), 0) FROM #ResultList WHERE Result  = 'Problem Record' 
		DECLARE @Messages StoredProcMessage
		
		INSERT INTO @Messages(Name, ParameterValuesCsv) VALUES('TotalDiscountings', (Select 'Discounting=' + CONVERT(nvarchar(40), @TotalCount)))
		INSERT INTO @Messages(Name, ParameterValuesCsv) VALUES('DiscountingSuccessful', (Select 'DiscountingSuccessful=' + CONVERT(nvarchar(40), (@TotalCount - @InCorrectCount))))
		INSERT INTO @Messages(Name, ParameterValuesCsv) VALUES('DiscountingIncorrect', (Select 'DiscountingIncorrect=' + CONVERT(nvarchar(40), @InCorrectCount)))

		INSERT INTO @Messages(Name, ParameterValuesCsv) VALUES('DiscountingResultOption', (Select 'ResultOption=' + CONVERT(nvarchar(40), @ResultOption)))

		SELECT * FROM @Messages
		
	SET NOCOUNT OFF
	SET ANSI_WARNINGS ON 
	
DROP TABLE #EligibleContracts;
DROP TABLE #NonAccrualDetails;
DROP TABLE #ReAccrualDetails;
DROP TABLE #GLDetails;
DROP TABLE #DiscountingAmortizationSchedules;
DROP TABLE #GLPostingDetails;
DROP TABLE #PrincipalGLDetails;
DROP TABLE #PayableDetails;
DROP TABLE #FullPaidOffDiscountings;
DROP TABLE #DiscountingPaydowns;
DROP TABLE #DistinctEligibleContracts;
DROP TABLE #DiscountingCapitalizedInterests;
DROP TABLE #DiscountingServicingDetails;
DROP TABLE #PayableGLJournalsDetails;
DROP TABLE #DiscountingPaydownAtInceptionDetails;
DROP TABLE #DiscountingPaydownNotAtInceptionDetails;
DROP TABLE #SundryReceivablesDetails;
DROP TABLE #PaydownDetails;
DROP TABLE #DiscountingPaydownContractDetails;
DROP TABLE #Resultlist;
DROP TABLE #DiscountingSummary;

END

GO
