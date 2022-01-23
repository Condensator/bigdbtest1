SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
 

CREATE PROC [dbo].[SPHC_LoanGLPosting_HealthCheck]
(
	@ResultOption NVARCHAR(20),
	@LegalEntityIds ReconciliationId READONLY,
	@ContractIds ReconciliationId READONLY,  
	@CustomerIds ReconciliationId READONLY
)
AS
BEGIN

	SET NOCOUNT ON;
	SET ANSI_WARNINGS OFF;
	
	IF OBJECT_ID('tempdb..#InvoiceAmount') IS NOT NULL
	BEGIN
		 DROP TABLE #InvoiceAmount;
	END;
	IF OBJECT_ID('tempdb..#LoanDetails') IS NOT NULL
	BEGIN
		 DROP TABLE #LoanDetails;
	END;
	IF OBJECT_ID('tempdb..#MaxPaydownDate') IS NOT NULL
	BEGIN
		 DROP TABLE #MaxPaydownDate;
	END;
	IF OBJECT_ID('tempdb..#PrincipalRepaymentAmount') IS NOT NULL
	BEGIN
		 DROP TABLE #PrincipalRepaymentAmount;
	END;
	IF OBJECT_ID('tempdb..#MinNonServicingDate') IS NOT NULL
	BEGIN
		 DROP TABLE #MinNonServicingDate;
	END;
	IF OBJECT_ID('tempdb..#IncomeSchedules') IS NOT NULL
	BEGIN
		 DROP TABLE #IncomeSchedules;
	END;
	IF OBJECT_ID('tempdb..#TotalGainAmount') IS NOT NULL
	BEGIN
		 DROP TABLE #TotalGainAmount;
	END;
	IF OBJECT_ID('tempdb..#MigratedTotalFinancedAmount') IS NOT NULL
	BEGIN
		 DROP TABLE #MigratedTotalFinancedAmount;
	END;
	IF OBJECT_ID('tempdb..#TotalFinancedAmount') IS NOT NULL
	BEGIN
		 DROP TABLE #TotalFinancedAmount;
	END;
	IF OBJECT_ID('tempdb..#CapitalizedInterests') IS NOT NULL
	BEGIN
		 DROP TABLE #CapitalizedInterests;
	END;
	IF OBJECT_ID('tempdb..#LoanPaydownTemp') IS NOT NULL
	BEGIN
		 DROP TABLE #LoanPaydownTemp;
	END;
	IF OBJECT_ID('tempdb..#RePossessionAmount') IS NOT NULL
	BEGIN
		 DROP TABLE #RePossessionAmount;
	END;
	IF OBJECT_ID('tempdb..#CumulativeInterestAppliedToPrincipal') IS NOT NULL
	BEGIN
		 DROP TABLE #CumulativeInterestAppliedToPrincipal;
	END;
	IF OBJECT_ID('tempdb..#LoanTableValues') IS NOT NULL
	BEGIN
		 DROP TABLE #LoanTableValues;
	END;
	IF OBJECT_ID('tempdb..#LoanFinanceBasicTemp') IS NOT NULL
	BEGIN
		 DROP TABLE #LoanFinanceBasicTemp;
	END;
	IF OBJECT_ID('tempdb..#NBVDifferenceAmount') IS NOT NULL
	BEGIN
		 DROP TABLE #NBVDifferenceAmount;
	END;
	IF OBJECT_ID('tempdb..#TotalGainAmount') IS NOT NULL
	BEGIN
		 DROP TABLE #TotalGainAmount;
	END;
	IF OBJECT_ID('tempdb..#PaymentScheduleAmount') IS NOT NULL
	BEGIN
		 DROP TABLE #PaymentScheduleAmount;
	END;
	IF OBJECT_ID('tempdb..#ReceivableDetailsTemp') IS NOT NULL
	BEGIN
		 DROP TABLE #ReceivableDetailsTemp;
	END;
	IF OBJECT_ID('tempdb..#CasualtyLoanPayments') IS NOT NULL
	BEGIN
		 DROP TABLE #CasualtyLoanPayments;
	END;
	IF OBJECT_ID('tempdb..#ReceivablesPosted') IS NOT NULL
	BEGIN
		 DROP TABLE #ReceivablesPosted;
	END;
	IF OBJECT_ID('tempdb..#IncomeScheduleRepaymentAmount') IS NOT NULL
	BEGIN
		 DROP TABLE #IncomeScheduleRepaymentAmount;
	END;
	IF OBJECT_ID('tempdb..#ReceivablesAmountForIncome') IS NOT NULL
	BEGIN
		 DROP TABLE #ReceivablesAmountForIncome;
	END;
	IF OBJECT_ID('tempdb..#ReceivablesAmountForPayment') IS NOT NULL
	BEGIN
		 DROP TABLE #ReceivablesAmountForPayment;
	END;
	IF OBJECT_ID('tempdb..#ReceivableSumAmount') IS NOT NULL
	BEGIN
		 DROP TABLE #ReceivableSumAmount;
	END;
	IF OBJECT_ID('tempdb..#ReceivableTaxDetails') IS NOT NULL
	BEGIN
		 DROP TABLE #ReceivableTaxDetails;
	END;
	IF OBJECT_ID('tempdb..#SplitAmountForPaydown') IS NOT NULL
	BEGIN
		 DROP TABLE #SplitAmountForPaydown;
	END;
	IF OBJECT_ID('tempdb..#ResultList') IS NOT NULL
	BEGIN
		 DROP TABLE #ResultList;
	END;
	IF OBJECT_ID('tempdb..#LoanSummary') IS NOT NULL
	BEGIN
		 DROP TABLE #LoanSummary;
	END;
	IF OBJECT_ID('tempdb..#LoanPaydownAssetDetails') IS NOT NULL
	BEGIN
		 DROP TABLE #LoanPaydownAssetDetails;
	END;
	IF OBJECT_ID('tempdb..#LoanAssetDetails') IS NOT NULL
	BEGIN
		 DROP TABLE #LoanAssetDetails;
	END;
	IF OBJECT_ID('tempdb..#MaxPaydownDateForRepossession') IS NOT NULL
	BEGIN
		 DROP TABLE #MaxPaydownDateForRepossession;
	END;
	IF OBJECT_ID('tempdb..#ContractsToIgnoreForRepossesion') IS NOT NULL
	BEGIN
		 DROP TABLE #ContractsToIgnoreForRepossesion;
	END;
	IF OBJECT_ID('tempdb..#RepossesionMaxDate') IS NOT NULL
	BEGIN
		 DROP TABLE #RepossesionMaxDate;
	END;


	CREATE TABLE #LoanDetails
	(ContractId               BIGINT, 
	 SequenceNumber           NVARCHAR(80),
	 ContractAlias			  NVARCHAR(80),
	 LoanFinanceId            BIGINT, 
	 MaxIncomeDateFromIncome  DATE, 
	 SyndicationEffectiveDate DATE, 
	 SyndicationType          NVARCHAR(30),
	 LegalEntityId			  BIGINT,
	 CustomerId				  BIGINT, 
	 RetainedPortion          DECIMAL(16, 2), 
	 SyndicationCreatedTIme   DATETIMEOFFSET, 
	 IsChargedOff             BIT, 
	 CommencementDate         DATE, 
	 IsProgressLoan           BIT, 
	 IsMigratedContract       BIT, 
	 ChargeOffDate            DATE, 
	 IsInInterim              BIT
	);
	
	DECLARE @u_ConversionSource NVARCHAR(50);
	DECLARE @True BIT= 1;
    DECLARE @False BIT= 0;
	DECLARE @LegalEntitiesCount BIGINT = ISNULL((SELECT COUNT(*) FROM @LegalEntityIds), 0);
	DECLARE @ContractsCount BIGINT = ISNULL((SELECT COUNT(*) FROM @ContractIds), 0);
	DECLARE @CustomersCount BIGINT = ISNULL((SELECT COUNT(*) FROM @CustomerIds), 0);
	SELECT @u_ConversionSource = Value FROM GlobalParameters WHERE Category = 'Migration' AND Name = 'ConversionSource';
	
	INSERT INTO #LoanDetails
	SELECT Contract.Id AS ContractId
	     , Contract.SequenceNumber
		 , Contract.Alias AS ContractAlias
	     , Loan.Id AS LoanFinanceId
	     , NULL AS MaxIncomeDateFromIncome
	     , Syndication.EffectiveDate
	     , Contract.SyndicationType
		 , Loan.LegalEntityId AS LegalEntityId
         , Loan.CustomerId AS CustomerId 
	     , ISNULL(Syndication.RetainedPercentage / 100, 1) AS RetainedPortion
	     , Syndication.CreatedTime
	     , CASE
	           WHEN Contract.ChargeOffStatus = '_'
	           THEN CAST(0 AS BIT)
	           ELSE CAST(1 AS BIT)
	       END AS IsChargedOff
	     , Loan.CommencementDate
	     , CASE
	           WHEN Contract.ContractType = 'ProgressLoan'
	           THEN CAST(1 AS BIT)
	           ELSE CAST(0 AS BIT)
	       END AS IsProgressLoan
	     , CASE
	           WHEN Contract.u_ConversionSource = @u_ConversionSource
	           THEN CAST(1 AS BIT)
	           ELSE CAST(0 AS BIT)
	       END AS IsMigratedContract
	     , NULL
	     , CASE
	           WHEN Loan.InterimBillingType != '_'
	           THEN CAST(1 AS BIT)
	           ELSE CAST(0 AS BIT)
	       END AS IsInInterim
	FROM Contracts Contract
	     JOIN LoanFinances Loan ON Contract.Id = Loan.ContractId
	     LEFT JOIN ReceivableForTransfers Syndication ON Syndication.ContractId = Contract.Id
	                                                     AND Syndication.ApprovalStatus = 'Approved'
	WHERE Loan.IsCurrent = 1
		  AND Contract.ContractType != 'ProgressLoan'
		  AND Loan.IsDailySensitive = 0
	      AND Loan.Status NOT IN('Cancelled', 'Uncommenced')
		  AND @True = (CASE 
						   WHEN @LegalEntitiesCount > 0 AND EXISTS (SELECT Id FROM @LegalEntityIds WHERE Id = Loan.LegalEntityId) THEN @True
						   WHEN @LegalEntitiesCount = 0 THEN @True ELSE @False END)
		  AND @True = (CASE 
						   WHEN @CustomersCount > 0 AND EXISTS (SELECT Id FROM @CustomerIds WHERE Id = Loan.CustomerId) THEN @True
						   WHEN @CustomersCount = 0 THEN @True ELSE @False END)
		  AND @True = (CASE 
						   WHEN @ContractsCount > 0 AND EXISTS (SELECT Id FROM @ContractIds WHERE Id = Loan.ContractId) THEN @True
						   WHEN @ContractsCount = 0 THEN @True ELSE @False END);
	
	CREATE NONCLUSTERED INDEX IX_Id ON #LoanDetails(ContractId);


	UPDATE #LoanDetails SET 
	                        ChargeOffDate = ChargeOff.ChargeOffDate
	FROM #LoanDetails Contract
	     JOIN ChargeOffs ChargeOff ON Contract.ContractId = ChargeOff.ContractId
	                                  AND ChargeOff.IsActive = 1
	                                  AND ChargeOff.IsRecovery = 0;
	
	SELECT *
	INTO #MinNonServicingDate
	FROM
	(
	    SELECT Contract.ContractId
	         , MIN(ServicingDetail.EffectiveDate) AS EffectiveDate
	    FROM #LoanDetails Contract
	         JOIN ReceivableForTransfers ReceivableForTransfer ON Contract.ContractId = ReceivableForTransfer.ContractId
	                                                              AND ReceivableForTransfer.ApprovalStatus = 'Approved'
	         JOIN ReceivableForTransferServicings ServicingDetail ON ReceivableForTransfer.Id = ServicingDetail.ReceivableForTransferId
	                                                                 AND ServicingDetail.IsActive = 1
	    WHERE ServicingDetail.IsServiced = 0
	    GROUP BY Contract.ContractId
	) AS t;
	
	CREATE NONCLUSTERED INDEX IX_Id ON #MinNonServicingDate(ContractId);
	
	SELECT Contract.ContractId
	     , Loan.IsDailySensitive
	     , LoanPaydown.PaydownDate
	     , LoanPaydown.PaydownReason
	     , LoanPaydown.PrincipalBalance_Amount
	     , LoanPaydown.PrincipalPaydown_Amount
	     , LoanPaydown.AccruedInterest_Amount
	     , LoanPaydown.InterestPaydown_Amount
		 , LoanPaydown.PaydownAtInception
	     , LoanPaydown.Id
	     , LoanPaydown.CreatedTime
	INTO #LoanPaydownTemp
	FROM #LoanDetails Contract
	     JOIN LoanFinances Loan ON Contract.ContractId = Loan.ContractId
	     JOIN LoanPaydowns LoanPaydown ON Loan.Id = LoanPaydown.LoanFinanceId
	                                      AND LoanPaydown.Status = 'Active';
	
	CREATE NONCLUSTERED INDEX IX_Id ON #LoanPaydownTemp(ContractId);
	
	SELECT temp.ContractId
	     , SUM(CASE
	               WHEN lp.PaydownDate = Contract.SyndicationEffectiveDate
	                    AND lp.CreatedTime < Contract.SyndicationCreatedTIme
	               THEN GainLoss_Amount
	               WHEN lp.PaydownDate < Contract.SyndicationEffectiveDate
	                    OR Contract.SyndicationEffectiveDate IS NULL
	               THEN GainLoss_Amount
	               ELSE GainLoss_Amount * Contract.RetainedPortion
	           END) AS TotalGainAmount
	INTO #TotalGainAmount
	FROM #LoanPaydownTemp temp
	     INNER JOIN LoanPaydowns lp ON temp.Id = lp.Id
	     INNER JOIN #LoanDetails Contract ON Contract.ContractId = temp.ContractId
	GROUP BY temp.ContractId;


	CREATE NONCLUSTERED INDEX IX_Id ON #TotalGainAmount(ContractId);
	
	SELECT detail.ContractId
	     , MAX(LoanPaydown.PaydownDate) AS PaydownDate
	INTO #MaxPaydownDate
	FROM #LoanDetails detail
	     INNER JOIN #LoanPaydownTemp LoanPaydown ON detail.ContractId = LoanPaydown.ContractId
	WHERE LoanPaydown.PaydownReason IN ('FullyPaidOff', 'FullPaydown')
	GROUP BY detail.ContractId;
	
	CREATE NONCLUSTERED INDEX IX_Id ON #MaxPaydownDate(ContractId);
	

	SELECT detail.ContractId
	     , MAX(LoanPaydown.PaydownDate) AS PaydownDate
	INTO #MaxPaydownDateForRepossession
	FROM #LoanDetails detail
	     INNER JOIN #LoanPaydownTemp LoanPaydown ON detail.ContractId = LoanPaydown.ContractId
	WHERE LoanPaydown.PaydownReason IN ('Repossession')
	GROUP BY detail.ContractId;


	SELECT detail.ContractId
			, asset.AssetId AS AssetId
			, LoanPaydown.Id AS LoanPaydownId
			, LoanPaydown.PaydownDate
			, LoanPaydown.PaydownReason
	INTO #LoanPaydownAssetDetails
	FROM #LoanDetails detail
			INNER JOIN #LoanPaydownTemp LoanPaydown ON detail.ContractId = LoanPaydown.ContractId
			INNER JOIN LoanPaydownAssetDetails asset ON asset.LoanPaydownId = LoanPaydown.Id
	WHERE asset.IsActive = 1
		  AND asset.AssetPaydownStatus != 'CollateralOnLoan';


	SELECT detail.ContractId
			, ca.AssetId AS AssetId
	INTO #LoanAssetDetails
	FROM #LoanDetails detail
		 INNER JOIN CollateralAssets ca ON ca.LoanFinanceId = detail.LoanFinanceId
	WHERE ca.IsActive = 1 OR (ca.IsActive = 0 AND ca.TerminationDate IS NOT NULL);

	
	SELECT asset.ContractId
	INTO #ContractsToIgnoreForRepossesion
	FROM #LoanAssetDetails asset
	LEFT JOIN #LoanPaydownAssetDetails paidAsset ON paidAsset.ContractId = asset.ContractId
												    AND paidasset.AssetId = asset.AssetId
	WHERE paidAsset.ContractId IS NULL
 

	SELECT ld.ContractId
	     , SUM(pf.InvoiceTotal_Amount) AS Amount
	INTO #InvoiceAmount
	FROM #LoanDetails ld
	     INNER JOIN LoanFundings lf ON lf.LoanFinanceId = ld.LoanFinanceId
	     INNER JOIN PayableInvoices pf ON pf.Id = lf.FundingId
	WHERE pf.Status = 'Completed'
	GROUP BY ld.ContractId;

	SELECT detail.ContractId, maxDate.PaydownDate
	INTO #RepossesionMaxDate
	FROM #LoanDetails detail
			INNER JOIN #MaxPaydownDateForRepossession maxDate ON detail.ContractId = maxDate.ContractId
			INNER JOIN (
						SELECT ContractId
								, MAX(PaydownDate) AS PaydownDate
						FROM #LoanPaydownTemp
						GROUP BY ContractId
					) AS t ON t.ContractId = detail.ContractId
			LEFT JOIN #ContractsToIgnoreForRepossesion ignore ON detail.ContractId = ignore.ContractId
	WHERE ignore.ContractId IS NULL
			AND maxDate.PaydownDate = t.PaydownDate;


	
	SELECT Contract.ContractId
	     , IncomeSched.BeginNetBookValue_Amount
	     , IncomeSched.EndNetBookValue_Amount
	     , IncomeSched.PrincipalRepayment_Amount
	     , IncomeSched.PrincipalAdded_Amount
	     , CASE
	           WHEN IncomeSched.IsAccounting = 1
	                AND IncomeSched.IsLessorOwned = 1
	                AND IncomeSched.IsSchedule = 1
	           THEN ISNULL(IncomeSched.PrincipalAdded_Amount, 0.000) + ISNULL(IncomeSched.BeginNetBookValue_Amount, 0.000) + ISNULL(IncomeSched.CapitalizedInterest_Amount,		0.00)
	                --IIF(IncomeSched.CompoundDate IS NULL, ISNULL(IncomeSched.CapitalizedInterest_Amount, 0.00), 0.00) 
	                - ISNULL(IncomeSched.EndNetBookValue_Amount, 0.000) - ISNULL(IncomeSched.PrincipalRepayment_Amount, 0.000)
	           ELSE 0.00
	       END NBVDifference_Amount
	     , IncomeSched.IncomeDate
	     , IncomeSched.IsNonAccrual
	     , IncomeSched.IsLessorOwned
	     , IncomeSched.IsAccounting
	     , IncomeSched.IsSchedule
	     , IncomeSched.InterestAccrued_Amount
	     , IncomeSched.InterestPayment_Amount
	     , IncomeSched.IsGLPosted
	     , Loan.CommencementDate
	INTO #IncomeSchedules
	FROM #LoanDetails Contract
	     JOIN LoanFinances Loan ON Contract.ContractId = Loan.ContractId
	     JOIN LoanIncomeSchedules IncomeSched ON Loan.Id = IncomeSched.LoanFinanceId
	WHERE IncomeSched.IsSchedule = 1
	      OR IncomeSched.IsAccounting = 1;
	
	SELECT Contract.ContractId
	     , Receivable.IncomeType
	     , Receivable.Id AS ReceivableId
	     , Type.Name AS ReceivableType
	     , Receivable.TotalBalance_Amount
	     , Receivable.TotalAmount_Amount
	     , Receivable.DueDate
	     , Receivable.FunderId
	     , Receivable.IsGLPosted
	     , Code.AccountingTreatment
	     , Receivable.IsDummy
	     , Receivable.TotalBookBalance_Amount
	     , PaymentSched.StartDate AS PaymentStartDate
	     , PaymentSched.EndDate AS PaymentEndDate
	     , PaymentSched.DueDate AS PaymentDueDate
	     , PaymentSched.PaymentType AS PaymentType
	     , Receivable.PaymentScheduleId AS PaymentScheduleId
	     , Receivable.IsCollected
	     , Receivable.InvoiceComment
	     , Receivable.SourceId
	     , Receivable.SourceTable
	INTO #ReceivableDetailsTemp
	FROM #LoanDetails Contract
	     JOIN Receivables Receivable ON Contract.ContractId = Receivable.EntityId
	                                    AND Receivable.EntityType = 'CT'
	                                    AND Receivable.IsActive = 1
	     JOIN ReceivableCodes Code ON Receivable.ReceivableCodeId = Code.Id
	     JOIN ReceivableTypes Type ON Code.ReceivableTypeId = Type.Id
	     LEFT JOIN LoanPaymentSchedules PaymentSched ON Receivable.PaymentScheduleId = PaymentSched.Id
	                                                    AND Receivable.SourceTable != 'SundryRecurring'
	                                                    AND PaymentSched.IsActive = 1;
	
	CREATE NONCLUSTERED INDEX IX_Id ON #ReceivableDetailsTemp(ContractId);
	
	UPDATE #LoanDetails SET 
	                        MaxIncomeDateFromIncome = MaxIncomeDateTemp.MaxIncomeDate
	FROM #LoanDetails Contract
	     JOIN
	(
	    SELECT IncomeSched.ContractId
	         , MAX(IncomeSched.IncomeDate) AS MaxIncomeDate
	    FROM #IncomeSchedules IncomeSched
	         INNER JOIN #LoanDetails ld ON ld.ContractId = IncomeSched.ContractId
	    WHERE((IncomeSched.IsAccounting = 1
	           AND ld.SyndicationEffectiveDate IS NULL)
	          OR (IncomeSched.IsSchedule = 1
	              AND ld.SyndicationEffectiveDate IS NOT NULL))
	    GROUP BY IncomeSched.ContractId
	) AS MaxIncomeDateTemp ON Contract.ContractId = MaxIncomeDateTemp.ContractId;
	
	SELECT Loan.ContractId
	     , SUM(CASE
	               WHEN PaymentSchedule.Amount_Amount != 0.00
						AND (repossesionMaxDate.PaydownDate IS NULL OR  PaymentSchedule.EndDate <= repossesionMaxDate.PaydownDate OR PaymentSchedule.EndDate IS NULL)
	               THEN PaymentSchedule.Principal_Amount
	               ELSE 0.00
	           END) AS TotalPrincipalPaymentAmount
	     , SUM(CASE
	               WHEN PaymentSchedule.Amount_Amount != 0.00
	                    AND PaymentSchedule.EndDate <= Loan.MaxIncomeDateFromIncome
	                    AND PaymentSchedule.PaymentType != 'DownPayment'
	                    AND ((date.EffectiveDate IS NOT NULL
	                          AND PaymentSchedule.EndDate < date.EffectiveDate)
	                         OR date.EffectiveDate IS NULL)
	               THEN PaymentSchedule.Interest_Amount
	               ELSE 0.00
	           END) AS TotalInterestPaymentAmount
	     , SUM(CASE
	               WHEN PaymentSchedule.Amount_Amount != 0.00
	                    AND PaymentSchedule.EndDate <= Loan.MaxIncomeDateFromIncome
	                    AND PaymentSchedule.PaymentType != 'DownPayment'
	                    AND ((date.EffectiveDate IS NOT NULL
	                          AND PaymentSchedule.EndDate < date.EffectiveDate)
	                         OR date.EffectiveDate IS NULL)
	               THEN PaymentSchedule.Principal_Amount
	               ELSE 0.00
	           END) AS PrincipalPaymentAmount
	INTO #PrincipalRepaymentAmount
	FROM #LoanDetails Loan
	     JOIN LoanPaymentSchedules PaymentSchedule ON PaymentSchedule.LoanFinanceId = Loan.LoanFinanceId
	     LEFT JOIN #MaxPaydownDate AS paydownDate ON paydownDate.ContractId = Loan.ContractId
	     LEFT JOIN #MinNonServicingDate date ON date.ContractId = Loan.ContractId
		 LEFT JOIN #RepossesionMaxDate repossesionMaxDate ON Loan.ContractId = repossesionMaxDate.ContractId
	WHERE PaymentSchedule.IsActive = 1
	      AND (paydownDate.ContractId IS NULL
	           OR PaymentSchedule.EndDate <= paydownDate.PaydownDate
	           OR PaymentSchedule.EndDate IS NULL)
	GROUP BY Loan.ContractId;
	

	SELECT lps.Id
	INTO #CasualtyLoanPayments
	FROM #LoanDetails ld
	     INNER JOIN LoanPaymentSchedules lps ON lps.LoanFinanceId = ld.LoanFinanceId
	     INNER JOIN #LoanPaydownTemp paydown ON paydown.ContractId = ld.ContractId
	                                            AND paydown.PaydownReason IN('Casualty', 'Repossession')
	WHERE lps.StartDate = paydown.PaydownDate
	      AND lps.EndDate = paydown.PaydownDate
	      AND PaymentType IN('Paydown', 'PaydownAtInception');
	
	CREATE NONCLUSTERED INDEX IX_Id ON #CasualtyLoanPayments(Id);
	
	SELECT ContractId AS ContractId
	     , MAX(DueDate) AS DueDate
	INTO #ReceivablesPosted
	FROM #ReceivableDetailsTemp
	WHERE IsDummy = 0
	      AND IsCollected = 1
	      AND ReceivableType IN('LoanPrincipal', 'LoanInterest')
	GROUP BY ContractId;
	
	CREATE NONCLUSTERED INDEX IX_Id ON #ReceivablesPosted(ContractId);
	
	SELECT lf.ContractId
	     , SUM(CASE
	               WHEN lps.Amount_Amount != 0.00
						AND lps.paymentType != 'Downpayment'
						AND (repossesionMaxDate.PaydownDate IS NULL OR  lps.EndDate <= repossesionMaxDate.PaydownDate OR lps.EndDate IS NULL)
	               THEN Principal_Amount
	               ELSE 0.00
	           END) AS PrincipalAmount
	     , SUM(CASE
	               WHEN lps.Amount_Amount != 0.00
					    AND (repossesionMaxDate.PaydownDate IS NULL OR  lps.EndDate <= repossesionMaxDate.PaydownDate OR lps.EndDate IS NULL)
	               THEN Interest_Amount
	               ELSE 0.00
	           END) AS InterestAmount
	INTO #PaymentScheduleAmount
	FROM LoanFinances lf
	     INNER JOIN LoanPaymentSchedules lps ON lps.LoanFinanceId = lf.Id
	     INNER JOIN #ReceivablesPosted receivables ON receivables.ContractId = lf.ContractId
	     LEFT JOIN #MaxPaydownDate AS paydownDate ON paydownDate.ContractId = lf.ContractId
	     LEFT JOIN #CasualtyLoanPayments payment ON payment.Id = lps.Id
		 LEFT JOIN #RepossesionMaxDate repossesionMaxDate ON lf.ContractId = repossesionMaxDate.ContractId
	WHERE lf.IsCurrent = 1
	      AND lps.DueDate <= receivables.DueDate
	      AND lps.IsActive = 1
	      AND (paydownDate.ContractId IS NULL
	           OR lps.EndDate <= paydownDate.PaydownDate
	           OR lps.EndDate IS NULL)
	      AND payment.Id IS NULL
	GROUP BY lf.ContractId;
	

	CREATE NONCLUSTERED INDEX IX_Id ON #PaymentScheduleAmount(ContractId);
	
	
	UPDATE psa SET 
	               PrincipalAmount = t.Principal
	             , InterestAmount = t.Interest
	FROM #PaymentScheduleAmount psa
	     INNER JOIN
	(
	    SELECT ld.ContractId
	         , SUM(Interest_Amount) AS Interest
	         , SUM(Principal_Amount) AS Principal
	    FROM #MinNonServicingDate nonServicing
	         INNER JOIN #LoanDetails ld ON ld.ContractId = nonServicing.ContractId
	         INNER JOIN LoanFinances lf ON lf.Id = ld.LoanFinanceId
	         INNER JOIN LoanPaymentSchedules ls ON ls.LoanFinanceId = lf.Id
	         INNER JOIN #ReceivableDetailsTemp rd ON rd.ContractId = ld.ContractId
	                                                 AND ls.Id = rd.PaymentScheduleId
	    WHERE lf.BillInterimAsOf IN('FirstFixedTermPaymentDueDate', 'FirstFixedTermNonZeroPaymentDueDate')
	         AND ls.PaymentType = 'Interim'
	         AND ls.EndDate <= ld.SyndicationEffectiveDate
	         AND ls.IsActive = 1
	         AND lf.IsCurrent = 1
	         AND rd.IncomeType = 'InterimInterest'
	         AND ld.IsInInterim = 1
	    GROUP BY ld.ContractId
	) AS t ON t.ContractId = psa.ContractId;
	
	SELECT PaydownTemp.ContractId
	     , SUM(PrePaymentAmount_Amount) AS PrePaymentAmount
	INTO #RePossessionAmount
	FROM #LoanPaydownTemp PaydownTemp
	     JOIN #LoanDetails Contract ON Contract.ContractId = PaydownTemp.ContractId
	     JOIN LoanPaydownAssetDetails lpad ON lpad.LoanPayDownId = PaydownTemp.Id
	WHERE lpad.IsActive = 1
	      AND AssetPaydownStatus != 'CollateralOnLoan'
	      AND PaydownTemp.PaydownReason IN('RePossession')
	     AND Contract.SyndicationType != 'FullSale'
	     AND Contract.IsChargedOff = 0
	GROUP BY PaydownTemp.ContractId;
	
	CREATE NONCLUSTERED INDEX IX_Id ON #RePossessionAmount(ContractId);
	
	SELECT t.ContractId
	     , lis.CumulativeInterestAppliedToPrincipal_Amount AS CumulativeInterestAppliedToPrincipal
	INTO #CumulativeInterestAppliedToPrincipal
	FROM
	(
	    SELECT PaydownTemp.ContractId
	         , MAX(lis.Id) AS Id
	    FROM #LoanPaydownTemp PaydownTemp
	         JOIN LoanFinances lf ON lf.ContractId = PaydownTemp.ContractId
	         JOIN LoanIncomeSchedules lis ON lis.LoanFinanceId = lf.Id
	    WHERE lis.IsSchedule = 1
	          AND lis.IncomeDate = PaydownTemp.PaydownDate
	    GROUP BY PaydownTemp.ContractId
	) AS t
	INNER JOIN LoanIncomeSchedules lis ON t.Id = lis.Id;
	
	CREATE NONCLUSTERED INDEX IX_Id ON #CumulativeInterestAppliedToPrincipal(ContractId);
	
	SELECT PaydownTemp.ContractId
	     , SUM(CASE
	               WHEN PaydownTemp.PaydownReason = 'FullPaydown'
	                    AND PaydownTemp.IsDailySensitive = 0
	                    AND Contract.SyndicationType != 'FullSale'
	               THEN CASE
	                        WHEN PaydownTemp.PaydownDate = Contract.SyndicationEffectiveDate
	                             AND PaydownTemp.CreatedTime < Contract.SyndicationCreatedTIme
	                        THEN-(ISNULL(PaydownTemp.PrincipalBalance_Amount, 0) - ISNULL(PaydownTemp.PrincipalPaydown_Amount, 0))
	                        WHEN Contract.SyndicationEffectiveDate < PaydownTemp.PaydownDate
	                             OR Contract.SyndicationEffectiveDate IS NULL
	                        THEN-(ISNULL(PaydownTemp.PrincipalBalance_Amount, 0) - ISNULL(PaydownTemp.PrincipalPaydown_Amount, 0))
	                        ELSE-(ISNULL(PaydownTemp.PrincipalBalance_Amount, 0) - ISNULL(PaydownTemp.PrincipalPaydown_Amount, 0)) * RetainedPortion
	                    END
	               WHEN PaydownTemp.PaydownReason = 'Casualty'
	               THEN CASE
	                        WHEN PaydownTemp.PaydownDate = Contract.SyndicationEffectiveDate
	                             AND PaydownTemp.CreatedTime < Contract.SyndicationCreatedTIme
	                        THEN-(ISNULL(PaydownTemp.PrincipalPaydown_Amount, 0) - ISNULL(interest.CumulativeInterestAppliedToPrincipal, 0))
	                        WHEN Contract.SyndicationEffectiveDate < PaydownTemp.PaydownDate
	                             OR Contract.SyndicationEffectiveDate IS NULL
	                        THEN-(ISNULL(PaydownTemp.PrincipalPaydown_Amount, 0) - ISNULL(interest.CumulativeInterestAppliedToPrincipal, 0))
	                        ELSE-(ISNULL(PaydownTemp.PrincipalPaydown_Amount, 0) - ISNULL(interest.CumulativeInterestAppliedToPrincipal, 0)) * RetainedPortion
	                    END
	               WHEN PaydownTemp.PaydownReason = 'RePossession'
	               THEN CASE
	                        WHEN PaydownTemp.PaydownDate = Contract.SyndicationEffectiveDate
	                             AND PaydownTemp.CreatedTime < Contract.SyndicationCreatedTIme
	                        THEN-(ISNULL(RePossession.PrePaymentAmount, 0))
	                        WHEN Contract.SyndicationEffectiveDate < PaydownTemp.PaydownDate
	                             OR Contract.SyndicationEffectiveDate IS NULL
	                        THEN-(ISNULL(RePossession.PrePaymentAmount, 0))
	                        ELSE-(ISNULL(RePossession.PrePaymentAmount, 0)) * RetainedPortion
	                    END
	               ELSE 0
	           END) AS SyndicatedGainAmount
	     , SUM(CASE
	               WHEN PaydownTemp.PaydownReason = 'FullPaydown'
	                    AND PaydownTemp.IsDailySensitive = 0
	               THEN-(ISNULL(PaydownTemp.PrincipalBalance_Amount, 0) - ISNULL(PaydownTemp.PrincipalPaydown_Amount, 0))
	               WHEN PaydownTemp.PaydownReason = 'Casualty'
	               THEN-(ISNULL(PaydownTemp.PrincipalPaydown_Amount, 0) - ISNULL(interest.CumulativeInterestAppliedToPrincipal, 0))
	               WHEN PaydownTemp.PaydownReason = 'RePossession'
	               THEN-(ISNULL(RePossession.PrePaymentAmount, 0))
	               ELSE 0
	           END) AS GainAmount
	     , SUM(CASE
	               WHEN PaydownTemp.PaydownReason = 'FullPaydown'
	                    AND PaydownTemp.IsDailySensitive = 0
	               THEN-(ISNULL(PaydownTemp.PrincipalBalance_Amount, 0) - ISNULL(PaydownTemp.PrincipalPaydown_Amount, 0))
	               WHEN PaydownTemp.PaydownReason = 'RePossession'
	               THEN-(ISNULL(RePossession.PrePaymentAmount, 0))
	               ELSE 0
	           END) AS InvestmentGainAmount
	     , CAST (0.00 AS DECIMAL(16,2)) AS Disbursement_Amount
	     , SUM(CASE
	               WHEN PaydownTemp.PaydownReason = 'FullPaydown'
	                    AND PaydownTemp.IsDailySensitive = 0
	                    AND Contract.SyndicationType != 'FullSale'
	               THEN CASE
	                        WHEN PaydownTemp.PaydownDate = Contract.SyndicationEffectiveDate
	                             AND PaydownTemp.CreatedTime < Contract.SyndicationCreatedTIme
	                        THEN-(ISNULL(PaydownTemp.PrincipalBalance_Amount, 0) - ISNULL(PaydownTemp.PrincipalPaydown_Amount, 0))
	                        WHEN Contract.SyndicationEffectiveDate < PaydownTemp.PaydownDate
	                             OR Contract.SyndicationEffectiveDate IS NULL
	                        THEN-(ISNULL(PaydownTemp.PrincipalBalance_Amount, 0) - ISNULL(PaydownTemp.PrincipalPaydown_Amount, 0))
	                        ELSE-(ISNULL(PaydownTemp.PrincipalBalance_Amount, 0) - ISNULL(PaydownTemp.PrincipalPaydown_Amount, 0)) * RetainedPortion
	                    END
	               ELSE 0
	           END) AS FullPaydownGainAmount
	INTO #LoanTableValues
	FROM #LoanPaydownTemp PaydownTemp
	     INNER JOIN #LoanDetails Contract ON PaydownTemp.ContractId = Contract.ContractId
	     LEFT JOIN #RePossessionAmount RePossession ON PaydownTemp.ContractId = RePossession.ContractId
	     LEFT JOIN #CumulativeInterestAppliedToPrincipal interest ON interest.ContractId = PaydownTemp.ContractId
	GROUP BY PaydownTemp.ContractId;
	
	CREATE NONCLUSTERED INDEX IX_Id ON #LoanTableValues(ContractId);
	
	SELECT IncomeSched.ContractId
	     , SUM(NBVDifference_Amount) AS NBVDifferenceAmount
	INTO #NBVDifferenceAmount
	FROM #IncomeSchedules IncomeSched
	     INNER JOIN #LoanDetails ld ON ld.ContractId = IncomeSched.ContractId
	WHERE IncomeDate <= ld.ChargeoffDate
	      OR ld.ChargeoffDate IS NULL
	GROUP BY IncomeSched.ContractId;
	
	SELECT DISTINCT 
	       Contract.ContractId
	     , InvoiceOtherCost.Amount_Amount AS Amount
	     , Funding.FundingId
	     , Funding.Type
	     , Invoice.Id AS PayableInvoiceId
	     , Invoice.Status
	     , InvoiceOtherCost.Id AS OtherCostId
	     , InvoiceOtherCost.AllocationMethod AS AllocationMethod
	     , Invoice.IsForeignCurrency
	     , Invoice.InitialExchangeRate
	     , Invoice.InvoiceDate
	     , Invoice.SourceTransaction
	     , DR.Id AS DisbursementRequestId
	     , DR.Status AS DisbursementRequestStatus
	     , CASE
	           WHEN Funding.Type = 'Origination'
	           THEN 1
	           ELSE 0
	       END AS IsOrigination
	     , Payables.Id AS PayableId
	     , Payables.SourceTable AS PayableSourceTable
	     , Payables.Status AS PayableStatus
	     , DRPayable.IsActive AS DRPayableIsActive
	     , Payables.SourceId AS PayableSourceId
	     , Invoice.InvoiceTotal_Amount
	INTO #LoanFinanceBasicTemp
	FROM #LoanDetails Contract
	     JOIN LoanFundings Funding ON Contract.LoanFinanceId = Funding.LoanFinanceId
	                                  AND Funding.IsActive = 1
	     JOIN PayableInvoices Invoice ON Funding.FundingId = Invoice.Id
	     JOIN PayableInvoiceOtherCosts InvoiceOtherCost ON Invoice.Id = InvoiceOtherCost.PayableInvoiceId
	                                                       AND InvoiceOtherCost.IsActive = 1
	     LEFT JOIN Payables ON InvoiceOtherCost.Id = Payables.SourceId
	                           AND Payables.SourceTable = 'PayableInvoiceOtherCost'
	     LEFT JOIN DisbursementRequestInvoices DRInvoice ON DRInvoice.InvoiceId = Invoice.Id
	     LEFT JOIN DisbursementRequests DR ON DRInvoice.DisbursementRequestId = DR.Id
	     LEFT JOIN DisbursementRequestPayables DRPayable ON DR.Id = DRPayable.DisbursementRequestId
	WHERE InvoiceOtherCost.AllocationMethod = 'LoanDisbursement';
	
	CREATE NONCLUSTERED INDEX IX_Id ON #LoanFinanceBasicTemp(ContractId);
	
	SELECT LoanTemp.ContractId
	     , SUM(CASE
	               WHEN LoanTemp.IsForeignCurrency = 0
	               THEN payables.AmountToPay_Amount
	               ELSE payables.AmountToPay_Amount * LoanTemp.InitialExchangeRate
	           END) AS TotalFinancedAmount
	INTO #TotalFinancedAmount
	FROM
	(
	    SELECT DISTINCT 
	           IsForeignCurrency
	         , DisbursementRequestId
	         , ContractId
	         , PayableSourceTable
	         , PayableStatus
	         , DRPayableIsActive
	         , DisbursementRequestStatus
	         , InitialExchangeRate
	         , PayableId
	         , PayableSourceId
	    FROM #LoanFinanceBasicTemp
	    WHERE DRPayableIsActive = 1
	) loanTemp
	INNER JOIN DIsbursementRequests dr ON loanTemp.DisbursementRequestId = dr.Id
	                                      AND dr.Status != 'InactiveStatus'
	INNER JOIN DisbursementRequestPaymentDetails drp ON drp.DisbursementRequestId = dr.Id
	INNER JOIN DisbursementRequestPayables payables ON dr.Id = payables.DisbursementRequestId
	                                                   AND loanTemp.PayableId = payables.PayableId
	WHERE LoanTemp.PayableSourceTable = 'PayableInvoiceOtherCost'
	      AND LoanTemp.PayableStatus != 'InActive'
	GROUP BY LoanTemp.ContractId;
	
	SELECT ld.ContractId
	     , SUM(CASE
	               WHEN LoanTemp.IsForeignCurrency = 0
	               THEN LoanTemp.Amount
	               ELSE LoanTemp.Amount * LoanTemp.InitialExchangeRate
	           END) AS TotalFinancedAmount
	INTO #MigratedTotalFinancedAmount
	FROM #LoanDetails ld
	     JOIN #LoanFinanceBasicTemp LoanTemp ON ld.ContractId = LoanTemp.ContractId
	                                            AND LoanTemp.IsOrigination = 1
	                                            AND LoanTemp.PayableSourceTable = 'PayableInvoiceOtherCost'
	WHERE IsProgressLoan = 0
	      AND IsMigratedContract = 1
	GROUP BY ld.ContractId;
	
	CREATE NONCLUSTERED INDEX IX_Id ON #TotalFinancedAmount(ContractId);
	
	UPDATE #LoanTableValues SET 
	                            Disbursement_Amount = ISNULL(financed.TotalFinancedAmount, 0.00) + ISNULL(migrated.TotalFinancedAmount, 0.00)
	FROM #LoanTableValues ltv
	     LEFT JOIN #MigratedTotalFinancedAmount migrated ON migrated.ContractId = ltv.ContractId
	     LEFT JOIN #TotalFinancedAmount financed ON financed.ContractId = ltv.ContractId;
	
	UPDATE #LoanTableValues SET 
	                            Disbursement_Amount = t.Amount
	FROM #LoanTableValues value
	     INNER JOIN
	(
	    SELECT ld.ContractId
	         , SUM(pf.InvoiceTotal_Amount) AS Amount
	    FROM #LoanDetails ld
	         INNER JOIN LoanFundings lf ON lf.LoanFinanceId = ld.LoanFinanceId
	         INNER JOIN PayableInvoices pf ON pf.Id = lf.FundingId
	    WHERE ld.SyndicationType = 'FullSale'
	          AND ld.CommencementDate = ld.SyndicationEffectiveDate
	          AND pf.Status = 'CompletedStatus'
	    GROUP BY ld.ContractId
	) AS t ON t.ContractId = value.ContractId;
	
	SELECT ld.ContractId
	     , SUM(lci.Amount_Amount) TotalCapitalizedInterest_Amount
	INTO #CapitalizedInterests
	FROM #LoanDetails ld
	     JOIN LoanCapitalizedInterests lci ON ld.LoanFinanceId = lci.LoanFinanceId
	WHERE lci.IsActive = 1
	      AND lci.Source != 'ProgressLoan'
	GROUP BY ld.ContractId;
	
	CREATE NONCLUSTERED INDEX IX_Id ON #CapitalizedInterests(ContractId);
	
	SELECT Loan.ContractId
	     , SUM(CASE
	               WHEN(IncomeSchedule.IncomeDate < Loan.syndicationEffectiveDate OR Loan.syndicationEffectiveDate IS NULL)
	                   AND IncomeSchedule.IsAccounting = 1
	                   AND IncomeSchedule.IsLessorOwned = 1
	                   AND IncomeSchedule.IsSchedule = 1
	               THEN IncomeSchedule.InterestPayment_Amount
	               WHEN IncomeSchedule.IncomeDate >= Loan.syndicationEffectiveDate
	                    AND IncomeSchedule.IsSchedule = 1
	                    AND IncomeSchedule.IsLessorOwned = 0
	               THEN IncomeSchedule.InterestPayment_Amount
	               ELSE 0.00
	           END) AS InterestRepayment_Amount
	     , SUM(CASE
	               WHEN(IncomeSchedule.IncomeDate < Loan.syndicationEffectiveDate OR Loan.syndicationEffectiveDate IS NULL)
	                   AND IncomeSchedule.IsAccounting = 1
	                   AND IncomeSchedule.IsLessorOwned = 1
	                   AND IncomeSchedule.IsSchedule = 1
	               THEN IncomeSchedule.PrincipalRepayment_Amount
	               WHEN IncomeSchedule.IncomeDate >= Loan.syndicationEffectiveDate
	                    AND IncomeSchedule.IsSchedule = 1
	                    AND IncomeSchedule.IsLessorOwned = 0
	               THEN IncomeSchedule.PrincipalRepayment_Amount
	               ELSE 0.00
	           END) AS PrincipalRepayment_Amount
	INTO #IncomeScheduleRepaymentAmount
	FROM #LoanDetails Loan
	     JOIN #IncomeSchedules IncomeSchedule ON Loan.ContractId = IncomeSchedule.ContractId
	GROUP BY Loan.ContractId;

	CREATE NONCLUSTERED INDEX IX_Id ON #IncomeScheduleRepaymentAmount(ContractId);
	SELECT temp.ContractId
	     , SUM(CASE
					 WHEN temp.SourceTable = 'LoanPaydown' AND Temp.SourceId = lpd.Id AND lpd.PaydownReason = 'FullPaydown' AND lpd.PaydownAtInception = 1 
					 THEN 0.00
					 WHEN temp.SourceTable = 'LoanPaydown' 
							 AND temp.ReceivableType in ('SundrySeparate','Sundry') 
							 AND lpd.PaydownReason = 'Casualty'
					 THEN temp.TotalAmount_Amount
					 WHEN temp.ReceivableType = 'LoanPrincipal'
							and temp.IncomeType != 'FixedTerm'
					 THEN temp.TotalAmount_Amount
					 ELSE 0.00
	           END) PrincipalReceivableAmount
	     , SUM(CASE
		 			WHEN temp.SourceTable = 'LoanPaydown' AND Temp.SourceId = lpd.Id AND lpd.PaydownReason = 'FullPaydown' AND lpd.PaydownAtInception = 1 
					THEN 0.00
					WHEN temp.SourceTable = 'LoanPaydown' 
						 AND temp.ReceivableType in ('SundrySeparate','Sundry') 
						 AND lpd.PaydownReason = 'Casualty'
					THEN temp.TotalAmount_Amount
					WHEN temp.ReceivableType = 'LoanInterest'
	                    AND temp.IncomeType != 'TakeDownInterest'
	               THEN temp.TotalAmount_Amount
	               ELSE 0.00
	               END) InterestReceivableAmount
	INTO #ReceivablesAmountForIncome
	FROM #ReceivableDetailsTemp temp
	JOIN #LoanDetails LD ON temp.ContractId = LD.ContractId
	JOIN LoanPaymentSchedules lps ON temp.PaymentScheduleId = lps.Id 
	LEFT JOIN #LoanPaydownTemp lpd ON LD.ContractId = lpd.ContractId AND temp.SourceId = lpd.Id
	LEFT JOIN ChargeOffs C ON temp.ContractId = C.ContractId
								   AND C.IsActive = 1 AND C.Status = 'Approved' AND C.IsRecovery = 0 AND C.ReceiptId IS NULL
	WHERE temp.IsDummy = 0
	      AND temp.IsCollected = 1
		  AND ((C.ContractId IS NULL OR LD.SyndicationType != 'None') OR (C.ChargeOffDate IS NOT NULL AND LD.SyndicationType = 'None'
		       AND temp.PaymentStartDate < C.ChargeOffDate))
		  AND LPS.IsActive = 1
	GROUP BY temp.ContractId;

	 
	 SELECT DISTINCT temp.ContractId, lps.Id, lps.Principal_Amount, lps.Interest_Amount
	 INTO #SplitAmountForPaydown
	 FROM #ReceivableDetailsTemp temp
	JOIN #LoanDetails LD ON temp.ContractId = LD.ContractId
	JOIN LoanPaymentSchedules lps ON temp.PaymentScheduleId = lps.Id 
	LEFT JOIN #LoanPaydownTemp lpd ON LD.ContractId = lpd.ContractId AND temp.SourceId = lpd.Id
	LEFT JOIN ChargeOffs C ON temp.ContractId = C.ContractId
								   AND C.IsActive = 1 AND C.Status = 'Approved' AND C.IsRecovery = 0 AND C.ReceiptId IS NULL
	WHERE temp.IsDummy = 0
	      AND temp.IsCollected = 1
		  AND ((C.ContractId IS NULL OR LD.SyndicationType != 'None') OR (C.ChargeOffDate IS NOT NULL AND LD.SyndicationType = 'None'
		       AND temp.PaymentStartDate < C.ChargeOffDate))
		  AND LPS.IsActive = 1
		  AND temp.SourceTable = 'LoanPaydown' 
						 AND temp.ReceivableType in ('SundrySeparate','Sundry') 
						 AND lpd.PaydownReason = 'Casualty'
 
	CREATE NONCLUSTERED INDEX IX_Id ON #ReceivablesAmountForIncome(ContractId);
	
	CREATE NONCLUSTERED INDEX IX_Id ON #SplitAmountForPaydown(ContractId);

	UPDATE #ReceivablesAmountForIncome SET PrincipalReceivableAmount = PrincipalReceivableAmount - t.InterestAmount , InterestReceivableAmount = InterestReceivableAmount - t.PrincipalAmount
	FROM #ReceivablesAmountForIncome income
	INNER JOIN (SELECT ContractId, SUM(Principal_Amount) as PrincipalAmount, SUM(Interest_Amount) AS InterestAmount
			    FROM #SplitAmountForPaydown GROUP BY ContractId) as t ON t.ContractId = income.ContractId

	SELECT temp.ContractId
	     , SUM(CASE
	               WHEN temp.ReceivableType = 'LoanPrincipal'
						AND temp.IncomeType != 'FixedTerm'
	               THEN temp.TotalAmount_Amount
	               ELSE 0.00
	           END) PrincipalReceivableAmount
	     , SUM(CASE
	               WHEN temp.ReceivableType = 'LoanInterest'
	                    AND temp.IncomeType != 'TakeDownInterest'
	               THEN temp.TotalAmount_Amount
	               ELSE 0.00
	           END) InterestReceivableAmount
	INTO #ReceivablesAmountForPayment
	FROM #ReceivableDetailsTemp temp
	WHERE temp.IsDummy = 0
	      AND temp.IsCollected = 1
	GROUP BY temp.ContractId;

	CREATE NONCLUSTERED INDEX X_Id ON #ReceivablesAmountForPayment(ContractId);

	
	SELECT ContractId
	     , SUM(InterestReceivableSum) AS InterestReceivableSum
	     , SUM(PrincipalReceivableSum) AS PrincipalReceivableSum
	     , SUM(PostedPrincipalReceivableSum) AS PostedPrincipalReceivableSum
	     , SUM(NotPostedPrincipalReceivableSum) AS NotPostedPrincipalReceivableSum
	     , SUM(NotPostedInterestReceivableSum) AS NotPostedInterestReceivableSum
	     , SUM(PostedInterestReceivableSum) AS PostedInterestReceivableSum
	INTO #ReceivableSumAmount
	FROM
	(
	    SELECT Loan.ContractId
	         , CASE
	               WHEN Receivable.ReceivableType = 'LoanInterest'
	               THEN Receivable.TotalAmount_Amount
	               ELSE 0.00
	           END AS InterestReceivableSum
	         , CASE
	               WHEN ld.IsChargedOff = 0
	                    AND Receivable.ReceivableType = 'LoanInterest'
	                    AND Receivable.IsGLPosted = 1
	               THEN Receivable.TotalAmount_Amount
	               WHEN Ld.IsChargedOff = 1
	                    AND Receivable.ReceivableType = 'LoanInterest'
	                    AND Receivable.TotalAmount_Amount != Receivable.TotalBalance_Amount
	                    AND Receivable.IsGLPosted = 1
	               THEN Receivable.TotalAmount_Amount
	               WHEN Ld.IsChargedOff = 1
	                    AND Receivable.ReceivableType = 'LoanInterest'
	                    AND Receivable.TotalAmount_Amount = Receivable.TotalBalance_Amount
	                    AND Receivable.IsGLPosted = 1
	               THEN 0.00
	               ELSE 0.00
	           END AS PostedInterestReceivableSum
	         , CASE
	               WHEN Receivable.ReceivableType = 'LoanInterest'
	                    AND Receivable.IsGLPosted = 0
	               THEN Receivable.TotalAmount_Amount
	               ELSE 0.00
	           END AS NotPostedInterestReceivableSum
	         , CASE
	               WHEN Receivable.ReceivableType = 'LoanPrincipal'
	               THEN Receivable.TotalAmount_Amount
	               ELSE 0.00
	           END AS PrincipalReceivableSum
	         , CASE
	               WHEN ld.IsChargedOff = 0
	                    AND Receivable.ReceivableType = 'LoanPrincipal'
	                    AND Receivable.IsGLPosted = 1
	               THEN Receivable.TotalAmount_Amount
	               WHEN Ld.IsChargedOff = 1
	                    AND Receivable.ReceivableType = 'LoanPrincipal'
	                    AND Receivable.IsGLPosted = 1
	                    AND Receivable.TotalAmount_Amount != Receivable.TotalBalance_Amount
	               THEN Receivable.TotalAmount_Amount
	               WHEN Ld.IsChargedOff = 1
	                    AND Receivable.ReceivableType = 'LoanPrincipal'
	                    AND Receivable.IsGLPosted = 1
	                    AND Receivable.TotalAmount_Amount = Receivable.TotalBalance_Amount
	               THEN 0.00
	               ELSE 0.00
	           END AS PostedPrincipalReceivableSum
	         , CASE
	               WHEN Receivable.ReceivableType = 'LoanPrincipal'
	                    AND Receivable.IsGLPosted = 0
	               THEN Receivable.TotalAmount_Amount
	               ELSE 0.00
	           END AS NotPostedPrincipalReceivableSum
	    FROM #LoanDetails Loan
	         INNER JOIN #LoanDetails ld ON Loan.ContractId = ld.ContractId
	         JOIN #ReceivableDetailsTemp Receivable ON Loan.ContractId = Receivable.ContractId
	    WHERE Receivable.IsDummy = 0
	          AND Receivable.FunderId IS NULL
	) AS t
	GROUP BY ContractId;
	
	CREATE NONCLUSTERED INDEX IX_Id ON #ReceivableSumAmount(ContractId);
	
	SELECT temp.ContractId
	     , SUM(rt.Amount_Amount) AS SalesTaxAmount
	     , SUM(CASE
	               WHEN rt.IsGLPosted = 0
	               THEN rt.Amount_Amount
	               ELSE 0.00
	           END) AS SalesTaxNotGLPosted
	     , SUM(CASE
	               WHEN rt.IsGLPosted = 1
	               THEN rt.Amount_Amount
	               ELSE 0.00
	           END) AS SalesTaxGLPosted
	INTO #ReceivableTaxDetails
	FROM #ReceivableDetailsTemp temp
	     INNER JOIN ReceivableTaxes rt ON rt.ReceivableId = temp.ReceivableId
	     INNER JOIN #LoanDetails contract ON temp.ContractId = Contract.ContractId
	WHERE rt.IsActive = 1
	      AND rt.IsDummy = 0
	      AND temp.IsCollected = 1
	GROUP BY temp.ContractId;
	
	CREATE NONCLUSTERED INDEX IX_Id ON #ReceivableTaxDetails(ContractId);

	SELECT *
	     , CASE
	           WHEN [Interest_IncomeScheduleVsReceivableAmount] != 0.00
	                OR [TotalGainVsPrincipalGainAndInterestGain_Difference] != 0.00
	                OR [PrincipalInvestmentVsRepayment] != 0.00
	                OR [LoanNBVRoundingBalance] != 0.00
	                OR [Principal_IncomeVsPaymentSchedule] != 0.00
	                OR [Principal_PaymentScheduleVsReceivableAmount] != 0.00
	                OR [PrincipalReceivable_TotalVsGLPostedAndNonGLPosted] != 0.00
	                OR [Interest_IncomeVsPaymentSchedule] != 0.00
	                OR [Interest_PaymentScheduleVsReceivableAmount] != 0.00
	                OR [InterestReceivable_TotalVsGLPostedAndNonGLPosted] != 0.00
	                OR [Principal_IncomeScheduleVsReceivableAmount] != 0.00
					OR [SalesTaxReceivable_TotalVsGLPostedAndNonGLPosted] != 0.00
	           THEN 'Problem Record'
	           ELSE 'Not Problem Record'
	       END AS Result
	INTO #ResultList
	FROM 
	(SELECT ld.ContractId
	      , ld.SequenceNumber
		  , ld.ContractAlias
		  , le.Name AS LegalEntityName
		  , p.PartyName AS CustomerName
	      , ISNULL(ia.Amount, 0.00) AS [Total_Investment_Amount]
	      , ISNULL(pr.TotalPrincipalPaymentAmount, 0.00) [Total_Principal_Repayment_Amount_Payment]
	      , ISNULL(tv.SyndicatedGainAmount, 0.00) AS PrincipalGainOrLossAmount
	      , ISNULL(GainAmount.TotalGainAmount, 0.00) - (ISNULL(tv.SyndicatedGainAmount, 0.00) + (ISNULL(GainAmount.TotalGainAmount, 0.00) - ISNULL(tv.SyndicatedGainAmount,	0.00))) TotalGainVsPrincipalGainAndInterestGain_Difference
	      , CASE
	           WHEN ISNULL(tv.Disbursement_Amount, 0.00) = 0.00
	           THEN 0
	           WHEN ISNULL(tv.GainAmount, 0.00) < 0.00
	           THEN ISNULL(tv.Disbursement_Amount, 0.00) + ISNULL(ci.TotalCapitalizedInterest_Amount, 0.00) - (ABS(ISNULL(pr.TotalPrincipalPaymentAmount, 0.00)) - ISNULL   (tv.InvestmentGainAmount, 0.00))
	           ELSE ISNULL(tv.Disbursement_Amount, 0.00) + ISNULL(ci.TotalCapitalizedInterest_Amount, 0.00) - ABS(ISNULL(pr.TotalPrincipalPaymentAmount, 0.00)) - ISNULL	(tv.GainAmount, 0.00)
	       END AS PrincipalInvestmentVsRepayment
	     , CASE
	           WHEN ld.IsChargedOff = 0
	           THEN ABS(ISNULL(nbv.NBVDifferenceAmount, 0.00)) - ABS(ISNULL(tv.FullPaydownGainAmount, 0.00))
	           ELSE ISNULL(nbv.NBVDifferenceAmount, 0.00)
	       END AS LoanNBVRoundingBalance
	     , ISNULL(InterestIncomeRepayment.PrincipalRepayment_Amount, 0.00) - ISNULL(pr.PrincipalPaymentAmount, 0.00) [Principal_IncomeVsPaymentSchedule]
	     , ISNULL(psa.PrincipalAmount, 0.00) - ISNULL(rp.PrincipalReceivableAmount, 0.00)  AS [Principal_PaymentScheduleVsReceivableAmount]
		 , ISNULL(InterestIncomeRepayment.PrincipalRepayment_Amount, 0.00) - ISNULL(rps.PrincipalReceivableAmount, 0.00)  AS [Principal_IncomeScheduleVsReceivableAmount]
		 , ISNULL(ReceivableSum.PrincipalReceivableSum, 0.00) [TotalPrincipalReceivableGenerated]
	     , ISNULL(ReceivableSum.PostedPrincipalReceivableSum, 0.00) [PrincipalReceivable_GLPosted]
	     , ISNULL(ReceivableSum.NotPostedPrincipalReceivableSum, 0.00) [PrincipalReceivable_NotGLPosted]
	     , CASE 
	           WHEN ld.IsChargedOff = 1
	           THEN 0
	           ELSE ISNULL(ReceivableSum.PrincipalReceivableSum, 0.00) - (ISNULL(ReceivableSum.PostedPrincipalReceivableSum, 0.00) + ISNULL (ReceivableSum.NotPostedPrincipalReceivableSum, 0.00))
	       END [PrincipalReceivable_TotalVsGLPostedAndNonGLPosted]
	     , ISNULL(GainAmount.TotalGainAmount, 0.00) - ISNULL(tv.SyndicatedGainAmount, 0.00) AS InterestGainOrLossAmount
	     , ISNULL(InterestIncomeRepayment.InterestRepayment_Amount, 0.00) - ISNULL(pr.ToTalInterestPaymentAmount, 0.00) [Interest_IncomeVsPaymentSchedule]
	     , ISNULL(psa.InterestAmount, 0.00) - ISNULL(rp.InterestReceivableAmount, 0.00) AS [Interest_PaymentScheduleVsReceivableAmount]
		 , ISNULL(InterestIncomeRepayment.InterestRepayment_Amount, 0.00) - ISNULL(rps.InterestReceivableAmount, 0.00) [Interest_IncomeScheduleVsReceivableAmount]
	     , ISNULL(ReceivableSum.InterestReceivableSum, 0.00) [TotalInterestReceivableGenerated]
	     , ISNULL(ReceivableSum.PostedInterestReceivableSum, 0.00) [InterestReceivables_GLPosted]
		 , ISNULL(ReceivableSum.NotPostedInterestReceivableSum, 0.00) [InterestReceivables_NotGLPosted]
	     , CASE
	           WHEN ld.IsChargedOff = 1
	           THEN 0
	           ELSE ISNULL(ReceivableSum.InterestReceivableSum, 0.00) - (ISNULL(ReceivableSum.NotPostedInterestReceivableSum, 0.00) + ISNULL(ReceivableSum.PostedInterestReceivableSum, 0.00))
	       END [InterestReceivable_TotalVsGLPostedAndNonGLPosted]
	     , ISNULL(rtd.SalesTaxAmount, 0.00) AS [TotalSalesTaxReceivableGenerated]
		 , ISNULL(rtd.SalesTaxGLPosted, 0.00) AS [SalesTaxReceivables_GLPosted]
		 , ISNULL(rtd.SalesTaxNotGLPosted, 0.00) AS [SalesTaxReceivables_NotGLPosted]
		 , ISNULL(rtd.SalesTaxAmount, 0.00) - (ISNULL(rtd.SalesTaxGLPosted, 0.00) + ISNULL(rtd.SalesTaxNotGLPosted, 0.00)) AS [SalesTaxReceivable_TotalVsGLPostedAndNonGLPosted]
	FROM #LoanDetails ld
		 LEFT JOIN LegalEntities le ON le.Id = ld.LegalEntityId
         LEFT JOIN Parties p ON ld.CustomerId = p.Id
	     LEFT JOIN #PrincipalRepaymentAmount pr ON ld.ContractId = pr.ContractId
	     LEFT JOIN #InvoiceAmount ia ON ld.ContractId = ia.ContractId
	     LEFT JOIN #LoanTableValues tv ON ld.ContractId = tv.ContractId
	     LEFT JOIN #CapitalizedInterests ci ON ld.ContractId = ci.ContractId
	     LEFT JOIN #NBVDifferenceAmount nbv ON ld.ContractId = nbv.ContractId
	     LEFT JOIN #IncomeScheduleRepaymentAmount InterestIncomeRepayment ON ld.ContractId = InterestIncomeRepayment.ContractId
	     LEFT JOIN #TotalGainAmount GainAmount ON ld.ContractId = GainAmount.ContractId
	     LEFT JOIN #ReceivablesAmountForIncome rps ON ld.ContractId = rps.ContractId
	     LEFT JOIN #PaymentScheduleAmount psa ON ld.ContractId = psa.ContractId
	     LEFT JOIN #ReceivableSumAmount ReceivableSum ON ld.ContractId = ReceivableSum.ContractId
	     LEFT JOIN #ReceivableTaxDetails rtd ON ld.ContractId = rtd.ContractId
		 LEFT JOIN #ReceivablesAmountForPayment rp  ON ld.ContractId = rp.ContractId) AS t;
	
	CREATE NONCLUSTERED INDEX IX_Id ON #ResultList(ContractId)
	
	SELECT name AS Name, 0 AS Count, CAST (0 AS BIT) AS IsProcessed, CAST('' AS NVARCHAR(Max)) AS Label 
	INTO #LoanSummary
	FROM tempdb.sys.columns
	WHERE object_id = OBJECT_ID('tempdb..#ResultList')
	AND (Name LIKE '%Vs%' OR Name = 'LoanNBVRoundingBalance');

	DECLARE @query NVARCHAR(MAX);
	DECLARE @TableName NVARCHAR(max);
	WHILE EXISTS (SELECT 1 FROM #LoanSummary WHERE IsProcessed = 0)
	BEGIN
	SELECT TOP 1 @TableName = Name FROM #LoanSummary WHERE IsProcessed = 0

	SET @query = 'UPDATE #LoanSummary SET Count = (SELECT COUNT(*) FROM #ResultList WHERE ' + @TableName+ ' != 0.00), IsProcessed = 1
					WHERE Name = '''+ @TableName+''' ;'
	EXEC (@query)
	END

	UPDATE #LoanSummary SET Label = CASE WHEN Name = 'TotalGainVsPrincipalGainAndInterestGain_Difference'
										 THEN  '1_Total Gain Vs Principal Gain And Interest Gain_Difference'
										 WHEN Name = 'PrincipalInvestmentVsRepayment'
										 THEN '2_Principal Investment Vs Repayment'
										 WHEN Name = 'LoanNBVRoundingBalance'
										 THEN '3_Loan NBV Rounding Balance'
										 WHEN Name = 'Principal_IncomeVsPaymentSchedule'
										 THEN '4_Principal Income Vs Payment Schedule'
										 WHEN Name = 'Principal_PaymentScheduleVsReceivableAmount'
										 THEN '5_Principal Payment Schedule Vs Receivable Amount'
										 WHEN Name = 'Principal_IncomeScheduleVsReceivableAmount'
										 THEN '6_Principal Income Schedule Vs Receivable Amount'
										 WHEN Name = 'PrincipalReceivable_TotalVsGLPostedAndNonGLPosted'
										 THEN '7_Principal Receivable Total Vs GL Posted&Not GLPosted'
										 WHEN Name = 'Interest_IncomeVsPaymentSchedule'
										 THEN '8_Interest Income Vs Payment Schedule'
										 WHEN Name = 'Interest_PaymentScheduleVsReceivableAmount'
										 THEN '9_Interest Payment Schedule Vs Receivable Amount'
										 WHEN Name = 'Interest_IncomeScheduleVsReceivableAmount'
										 THEN '10_Interest Income Schedule Vs Receivable Amount'
										 WHEN Name = 'InterestReceivable_TotalVsGLPostedAndNonGLPosted'
										 THEN '11_Interest Receivable - Total Vs GL Posted&Not GLPosted'
										 WHEN Name = 'SalesTaxReceivable_TotalVsGLPostedAndNonGLPosted'
										 THEN '12_SalesTax Receivable - Total Vs GLPosted&Not GLPosted'
									END

	

	SELECT Label AS Name, Count 
	FROM #LoanSummary


	IF (@ResultOption = 'All')
	BEGIN
        SELECT *
        FROM #ResultList
		ORDER BY ContractId;
	END

	IF (@ResultOption = 'Failed')
	BEGIN
		SELECT *
		FROM #ResultList
		WHERE Result = 'Problem Record'
	ORDER BY ContractId;
	END

	IF (@ResultOption = 'Passed')
	BEGIN
		SELECT *
		FROM #ResultList
		WHERE Result = 'Not Problem Record'
	ORDER BY ContractId;
	END
	
	DECLARE @TotalCount BIGINT;
	SELECT @TotalCount = ISNULL(COUNT(*), 0) FROM #ResultList
	DECLARE @InCorrectCount BIGINT;
	SELECT @InCorrectCount = ISNULL(COUNT(*), 0) FROM #ResultList WHERE Result  = 'Problem Record' 
	DECLARE @Messages StoredProcMessage
		
	INSERT INTO @Messages(Name, ParameterValuesCsv) VALUES('TotalLoans', (Select 'Loans=' + CONVERT(nvarchar(40), @TotalCount)))
	INSERT INTO @Messages(Name, ParameterValuesCsv) VALUES('LoanSuccessful', (Select 'LoanSuccessful=' + CONVERT(nvarchar(40), (@TotalCount - @InCorrectCount))))
	INSERT INTO @Messages(Name, ParameterValuesCsv) VALUES('LoanIncorrect', (Select 'LoanIncorrect=' + CONVERT(nvarchar(40), @InCorrectCount)))
	INSERT INTO @Messages(Name, ParameterValuesCsv) VALUES('LoanResultOption', (Select 'ResultOption=' + CONVERT(nvarchar(40), @ResultOption)))

	SELECT * FROM @Messages

	DROP TABLE #LoanDetails
	DROP TABLE #PrincipalRepaymentAmount
	DROP TABLE #InvoiceAmount
	DROP TABLE #MaxPaydownDate
	DROP TABLE #MinNonServicingDate
	DROP TABLE #IncomeSchedules
	DROP TABLE #MigratedTotalFinancedAmount
	DROP TABLE #TotalFinancedAmount
	DROP TABLE #CapitalizedInterests
	DROP TABLE #LoanPaydownTemp
	DROP TABLE #RePossessionAmount
	DROP TABLE #CumulativeInterestAppliedToPrincipal
	DROP TABLE #LoanTableValues
	DROP TABLE #LoanFinanceBasicTemp
	DROP TABLE #NBVDifferenceAmount
	DROP TABLE #TotalGainAmount
	DROP TABLE #PaymentScheduleAmount
	DROP TABLE #ReceivableDetailsTemp
	DROP TABLE #CasualtyLoanPayments
	DROP TABLE #ReceivablesPosted
	DROP TABLE #IncomeScheduleRepaymentAmount
	DROP TABLE #ReceivablesAmountForIncome
	DROP TABLE #ReceivableSumAmount
	DROP TABLE #ReceivableTaxDetails
	DROP TABLE #ResultList
	DROP TABLE #LoanSummary
	DROP TABLE #ReceivablesAmountForPayment
	DROP TABLE #SplitAmountForPaydown
	DROP TABLE #LoanPaydownAssetDetails;
	DROP TABLE #LoanAssetDetails;
	DROP TABLE #MaxPaydownDateForRepossession;
	DROP TABLE #ContractsToIgnoreForRepossesion;
	DROP TABLE #RepossesionMaxDate;

	SET NOCOUNT OFF
	SET ANSI_WARNINGS ON 

END;

GO
