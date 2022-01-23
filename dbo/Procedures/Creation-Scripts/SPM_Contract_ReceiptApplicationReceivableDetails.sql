SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

 
CREATE   PROC [dbo].[SPM_Contract_ReceiptApplicationReceivableDetails]
AS
BEGIN
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
IF OBJECT_ID('tempdb..#ChargeoffRecoveryReceiptIds') IS NOT NULL DROP TABLE #ChargeoffRecoveryReceiptIds
IF OBJECT_ID('tempdb..#ChargeoffExpenseReceiptIds') IS NOT NULL DROP TABLE #ChargeoffExpenseReceiptIds

DECLARE @IsSku BIT = 0
DECLARE @FilterCondition nvarchar(max) = '
DECLARE @Sql nvarchar(max) =';

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'Assets' AND COLUMN_NAME = 'IsSku')
BEGIN

SET @FilterCondition =' AND a.IsSKU = 0';
SET @IsSku = 1;
END
-------------  SKU = 1  ---------------------------------
IF @IsSku=1
BEGIN
SELECT DISTINCT
			   r.EntityId
			 , ReceiptClassification
			 , rt.ReceiptTypeName
			 , rd.AssetComponentType
			 --, CASE WHEN AccrualStatus = 'Accrual'
				--	THEN CAST(1 AS BIT)
				--	ELSE CAST(0 AS BIT)
			 --  END AS IsNonAccrual
			 , receivableTypes.Name AS ReceivableType
			 , lps.StartDate
			 , rard.BookAmountApplied_Amount
			 , rard.LeaseComponentAmountApplied_Amount
			 , rard.NonLeaseComponentAmountApplied_Amount
			 , rard.GainAmount_Amount
			 , rard.RecoveryAmount_Amount
			 , IIF(rard.RecoveryAmount_Amount != 0.00, CAST(NULL AS DECIMAL(16, 2)), CAST(0 AS DECIMAL(16, 2))) AS RecoveryAmount_LC
			 , IIF(rard.RecoveryAmount_Amount != 0.00, CAST(NULL AS DECIMAL(16, 2)), CAST(0 AS DECIMAL(16, 2))) AS RecoveryAmount_NLC
			 , IIF(rard.GainAmount_Amount != 0.00, CAST(NULL AS DECIMAL(16, 2)), CAST(0 AS DECIMAL(16, 2))) AS GainAmount_LC
			 , IIF(rard.GainAmount_Amount != 0.00, CAST(NULL AS DECIMAL(16, 2)), CAST(0 AS DECIMAL(16, 2))) AS GainAmount_NLC
			 , CAST (0.00 AS DECIMAL(16, 2)) AS ChargeoffExpenseAmount
			 , CAST (0.00 AS DECIMAL(16, 2)) AS ChargeoffExpenseAmount_LC
			 , CAST (0.00 AS DECIMAL(16, 2)) AS ChargeoffExpenseAmount_NLC
			 , rard.AmountApplied_Amount
			 , Receipt.Id AS ReceiptId
			 , Receipt.Status AS ReceiptStatus
			 , r.IsGLPosted
			 , rc.AccountingTreatment
			 , rard.Id AS RardId
			 , GTT.Name AS GLTransactionType
			 , r.DueDate
			 , NULL AS IsRecovery											INTO ##Contract_ReceiptApplicationReceivableDetails
		FROM ##Contract_EligibleContracts
			 JOIN Receivables r ON ##Contract_EligibleContracts.ContractId = r.EntityId AND r.EntityType = 'CT'
			 JOIN ReceivableDetails rd ON rd.ReceivableId = r.Id
			 JOIN ReceivableCodes rc ON rc.id = r.ReceivableCodeId
			 JOIN ReceivableTypes receivableTypes ON receivableTypes.id = rc.ReceivableTypeId
			 JOIN GLTemplates GT ON RC.GLTemplateId = GT.Id
		     JOIN GLTransactionTypes GTT ON GT.GLTransactionTypeId = GTT.Id
			 JOIN ReceiptApplicationReceivableDetails rard ON rard.ReceivableDetailId = rd.Id
			 JOIN ReceiptApplications ra ON ra.Id = rard.ReceiptApplicationId
			 JOIN Receipts Receipt ON ra.ReceiptId = Receipt.Id
			 JOIN ReceiptTypes rt ON rt.Id = receipt.TypeId
			 LEFT JOIN ##Contract_ChargeOff co ON r.EntityId = co.ContractId
			 LEFT JOIN LeasePaymentSchedules lps ON lps.Id = r.PaymentScheduleId
		WHERE rd.IsActive = 1
			 AND rard.IsActive = 1
			 AND rt.IsActive = 1
			 AND r.FunderId IS NULL
		 	 AND (receivableTypes.Name IN('CapitalLeaseRental', 'LeaseFloatRateAdj', 'OperatingLeaseRental', 'OverTermRental', 'Supplemental', 'LoanInterest', 'LoanPrincipal')
			 	  OR (r.IsGLPosted = 0 AND receivableTypes.Name NOT IN('CapitalLeaseRental', 'LeaseFloatRateAdj', 'OperatingLeaseRental', 'OverTermRental', 'Supplemental', 'LoanInterest', 'LoanPrincipal', 'PropertyTax', 'PropertyTaxEscrow', 'AssetSale'))
				  OR (rc.AccountingTreatment= 'CashBased' AND receivableTypes.Name = 'AssetSale'));

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'ChargeOffs' AND COLUMN_NAME = 'LeaseComponentGain_Amount')
BEGIN    	
	SELECT c.Id
			 , co.ReceiptId
			 , SUM(co.LeaseComponentAmount_Amount) AS LeaseComponentAmount_Amount
			 , SUM(co.NonLeaseComponentAmount_Amount) AS NonLeaseComponentAmount_Amount
			 , SUM(co.LeaseComponentGain_Amount) AS LeaseComponentGain_Amount
			 , SUM(co.NonLeaseComponentGain_Amount) AS NonLeaseComponentGain_Amount      INTO #ChargeoffRecoveryReceiptIds
		FROM Contracts c
			 INNER JOIN ChargeOffs co ON co.ContractId = c.Id
		WHERE co.IsActive = 1
			  AND co.Status = 'Approved'
			  AND co.IsRecovery = 1
			  AND co.ReceiptId IS NOT NULL
			  AND co.ContractId IN (SELECT Distinct c.ContractId FROM ##Contract_EligibleContracts c) 
		GROUP BY co.ReceiptId
			   , c.Id ;	    
END

IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'ChargeOffs' AND COLUMN_NAME = 'LeaseComponentGain_Amount')
BEGIN
		INSERT INTO #ChargeoffRecoveryReceiptIds
		SELECT c.Id
			 , co.ReceiptId
			 , 0.00 AS LeaseComponentAmount_Amount
			 , 0.00 AS NonLeaseComponentAmount_Amount
			 , 0.00 AS LeaseComponentGain_Amount
			 , 0.00 AS NonLeaseComponentGain_Amount				
		FROM Contracts c
			 INNER JOIN ChargeOffs co ON co.ContractId = c.Id
		WHERE co.IsActive = 1
			  AND co.Status = 'Approved'
			  AND co.IsRecovery = 1
			  AND co.ReceiptId IS NOT NULL
			  AND co.ContractId IN (SELECT Distinct c.ContractId FROM ##Contract_EligibleContracts c) 
		GROUP BY co.ReceiptId, c.Id 
END

CREATE NONCLUSTERED INDEX IX_ReceiptId ON #ChargeoffRecoveryReceiptIds(Id, ReceiptId);

SELECT DISTINCT 
	   r.EntityId
	 , rt.ReceiptTypeName
	 , receipt.Id
	 , r.LeaseComponentAmountApplied_Amount
	 , r.NonLeaseComponentAmountApplied_Amount
	 , r.RecoveryAmount_Amount
	 , r.GainAmount_Amount
	 , r.StartDate
	 , IIF(r.RecoveryAmount_Amount != 0.00, CAST(NULL AS DECIMAL(16, 2)), CAST(0 AS DECIMAL(16, 2))) AS RecoveryAmount_LC
	 , IIF(r.RecoveryAmount_Amount != 0.00, CAST(NULL AS DECIMAL(16, 2)), CAST(0 AS DECIMAL(16, 2))) AS RecoveryAmount_NLC
	 , IIF(r.GainAmount_Amount != 0.00, CAST(NULL AS DECIMAL(16, 2)), CAST(0 AS DECIMAL(16, 2))) AS GainAmount_LC
	 , IIF(r.GainAmount_Amount != 0.00, CAST(NULL AS DECIMAL(16, 2)), CAST(0 AS DECIMAL(16, 2))) AS GainAmount_NLC
	 , r.AmountApplied_Amount AS AmountApplied
	 , r.RardId																					INTO #ChargeoffRecoveryRecords
FROM ##Contract_ReceiptApplicationReceivableDetails r
	 JOIN Receipts receipt ON r.ReceiptId = Receipt.Id
	 JOIN ReceiptTypes rt ON rt.Id = receipt.TypeId
	 JOIN #ChargeoffRecoveryReceiptIds co ON r.EntityId = co.Id
											AND co.ReceiptId = receipt.Id
WHERE Receipt.Status IN('Posted', 'Completed')
	 AND (r.ReceivableType IN('CapitalLeaseRental', 'LeaseFloatRateAdj', 'OperatingLeaseRental', 'OverTermRental', 'Supplemental', 'LoanInterest', 'LoanPrincipal')
		  OR (r.IsGLPosted = 0 AND r.ReceivableType NOT IN('CapitalLeaseRental', 'LeaseFloatRateAdj', 'OperatingLeaseRental', 'OverTermRental', 'Supplemental', 'LoanInterest', 'LoanPrincipal', 'PropertyTax', 'PropertyTaxEscrow', 'AssetSale'))
		  OR (r.AccountingTreatment = 'CashBased' AND r.ReceivableType = 'AssetSale'));

UPDATE #ChargeoffRecoveryRecords SET 
											GainAmount_LC = LeaseComponentAmountApplied_Amount
										  , GainAmount_NLC = NonLeaseComponentAmountApplied_Amount
		WHERE GainAmount_Amount != 0.00
			  AND GainAmount_Amount = AmountApplied;		

UPDATE #ChargeoffRecoveryRecords SET 
											GainAmount_LC = CASE
																WHEN NonLeaseComponentAmountApplied_Amount = 0.00
																THEN GainAmount_Amount
																ELSE GainAmount_LC
															END
										  , GainAmount_NLC = CASE
																 WHEN LeaseComponentAmountApplied_Amount = 0.00
																 THEN GainAmount_Amount
																 ELSE GainAmount_NLC
															 END
		WHERE GainAmount_Amount != 0.00
			  AND (GainAmount_LC IS NULL OR GainAmount_NLC IS NULL)
			  AND (NonLeaseComponentAmountApplied_Amount = 0.00 OR LeaseComponentAmountApplied_Amount = 0.00);

UPDATE #ChargeoffRecoveryRecords SET 
											GainAmount_NLC = CASE
																 WHEN NonLeaseComponentAmountApplied_Amount = 0.00
																 THEN 0.00
																 ELSE GainAmount_NLC
															 END
										  , GainAmount_LC = CASE
																WHEN LeaseComponentAmountApplied_Amount = 0.00
																THEN 0.00
																ELSE GainAmount_LC
															END
		WHERE(NonLeaseComponentAmountApplied_Amount = 0.00 OR LeaseComponentAmountApplied_Amount = 0.00);

WITH CTE_ChargeoffRecovery
			 AS (SELECT ABS(co.LeaseComponentAmount_Amount) - ABS(RecoveryAmount_LC) AS ChargeoffRecoveryAmount_LC
					  , ABS(co.NonLeaseComponentAmount_Amount) - ABS(RecoveryAmount_NLC) AS ChargeoffRecoveryAmount_NLC
					  , ABS(co.LeaseComponentGain_Amount) - ABS(GainAmount_LC) AS ChargeoffGainAmount_LC
					  , ABS(co.NonLeaseComponentGain_Amount) - ABS(GainAmount_NLC) AS ChargeoffGainAmount_NLC
					  , co.ReceiptId
				 FROM #ChargeoffRecoveryReceiptIds co
					  INNER JOIN
				 (
					 SELECT SUM(ISNULL(RecoveryAmount_LC, 0.00)) AS RecoveryAmount_LC
						  , SUM(ISNULL(RecoveryAmount_NLC, 0.00)) AS RecoveryAmount_NLC
						  , SUM(ISNULL(GainAmount_LC, 0.00)) AS GainAmount_LC
						  , SUM(ISNULL(GainAmount_NLC, 0.00)) AS GainAmount_NLC
						  , Id
					 FROM #ChargeoffRecoveryRecords
					 GROUP BY Id
				 ) AS t ON t.Id = co.ReceiptId)


			UPDATE #ChargeoffRecoveryRecords SET 
											  GainAmount_LC = CASE
																	WHEN coe.GainAmount_LC IS NULL
																	THEN cte.ChargeoffGainAmount_LC
																	ELSE coe.GainAmount_LC
																END
											, GainAmount_NLC = CASE
																	WHEN coe.GainAmount_NLC IS NULL
																	THEN cte.ChargeoffGainAmount_NLC
																	ELSE coe.GainAmount_NLC
																END
			FROM #ChargeoffRecoveryRecords coe
				INNER JOIN CTE_ChargeoffRecovery cte ON cte.ReceiptId = coe.Id
			WHERE(coe.RecoveryAmount_Amount != 0.00 OR coe.GainAmount_Amount != 0.00)
				AND (coe.RecoveryAmount_LC IS NULL OR coe.RecoveryAmount_NLC IS NULL
					OR coe.GainAmount_LC IS NULL OR coe.GainAmount_NLC IS NULL);

UPDATE rard SET 
								RecoveryAmount_LC = coe.RecoveryAmount_LC
							  , RecoveryAmount_NLC = coe.RecoveryAmount_NLC
							  , GainAmount_LC = coe.GainAmount_LC
							  , GainAmount_NLC = coe.GainAmount_NLC
							  , IsRecovery = CAST(1 AS BIT)
				FROM ##Contract_ReceiptApplicationReceivableDetails rard
					 INNER JOIN #ChargeoffRecoveryRecords coe ON coe.RardId = rard.RardId;

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'ChargeOffs' AND COLUMN_NAME = 'LeaseComponentGain_Amount')
BEGIN
   SELECT c.Id
		 , co.ReceiptId
		 , SUM(co.LeaseComponentAmount_Amount) AS LeaseComponentAmount_Amount
		 , SUM(co.NonLeaseComponentAmount_Amount) AS NonLeaseComponentAmount_Amount
		 , SUM(co.LeaseComponentGain_Amount) AS LeaseComponentGain_Amount
		 , SUM(co.NonLeaseComponentGain_Amount) AS NonLeaseComponentGain_Amount			INTO #ChargeoffExpenseReceiptIds
	FROM Contracts c
		 INNER JOIN ChargeOffs co ON co.ContractId = c.Id
	WHERE co.IsActive = 1
		  AND co.Status = 'Approved'
		  AND co.IsRecovery = 0
		  AND co.ReceiptId IS NOT NULL
		  AND co.ContractId IN (SELECT Distinct c.ContractId FROM ##Contract_EligibleContracts c) 
	GROUP BY c.Id , co.ReceiptId

END

IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'ChargeOffs' AND COLUMN_NAME = 'LeaseComponentGain_Amount')
BEGIN
INSERT INTO #ChargeoffExpenseReceiptIds
	SELECT c.Id
		 , co.ReceiptId
		 , 0.00 AS LeaseComponentAmount_Amount
		 , 0.00 AS NonLeaseComponentAmount_Amount
		 , 0.00 AS LeaseComponentGain_Amount
		 , 0.00 AS NonLeaseComponentGain_Amount            
	FROM Contracts c
		 INNER JOIN ChargeOffs co ON co.ContractId = c.Id
	WHERE co.IsActive = 1
		  AND co.Status = 'Approved'
		  AND co.IsRecovery = 0
		  AND co.ReceiptId IS NOT NULL
		  AND co.ContractId IN (SELECT Distinct c.ContractId FROM ##Contract_EligibleContracts c) 
	GROUP BY c.Id,co.ReceiptId
END

CREATE NONCLUSTERED INDEX IX_ReceiptId ON #ChargeoffExpenseReceiptIds(Id, ReceiptId);


SELECT DISTINCT 
			   r.EntityId
			 , rt.ReceiptTypeName
			 , receipt.Id
			 , r.LeaseComponentAmountApplied_Amount
			 , r.NonLeaseComponentAmountApplied_Amount
			 , r.RecoveryAmount_Amount
			 , r.GainAmount_Amount
			 , r.StartDate
			 , IIF(r.RecoveryAmount_Amount != 0.00, CAST(NULL AS DECIMAL(16, 2)), CAST(0 AS DECIMAL(16, 2))) AS RecoveryAmount_LC
			 , IIF(r.RecoveryAmount_Amount != 0.00, CAST(NULL AS DECIMAL(16, 2)), CAST(0 AS DECIMAL(16, 2))) AS RecoveryAmount_NLC
			 , IIF(r.GainAmount_Amount != 0.00, CAST(NULL AS DECIMAL(16, 2)), CAST(0 AS DECIMAL(16, 2))) AS GainAmount_LC
			 , IIF(r.GainAmount_Amount != 0.00, CAST(NULL AS DECIMAL(16, 2)), CAST(0 AS DECIMAL(16, 2))) AS GainAmount_NLC
			 , r.AmountApplied_Amount - (r.RecoveryAmount_Amount + r.GainAmount_Amount) AS ChargeoffExpenseAmount
			 , IIF(r.LeaseComponentAmountApplied_Amount != 0.00, CAST(NULL AS DECIMAL(16, 2)), CAST(0 AS DECIMAL(16, 2))) AS ChargeoffExpenseAmount_LC
			 , IIF(r.NonLeaseComponentAmountApplied_Amount != 0.00, CAST(NULL AS DECIMAL(16, 2)), CAST(0 AS DECIMAL(16, 2))) AS ChargeoffExpenseAmount_NLC
			 , r.AmountApplied_Amount AS AmountApplied
			 , r.RardId
			 , Receipt.Status AS ReceiptStatus											
		INTO #ChargeoffExpenseRecords
		FROM ##Contract_ReceiptApplicationReceivableDetails r
			 JOIN Receipts receipt ON r.ReceiptId = Receipt.Id
			 JOIN ReceiptTypes rt ON rt.Id = receipt.TypeId
			 JOIN #ChargeoffExpenseReceiptIds co ON r.EntityId = co.Id
													AND co.ReceiptId = receipt.Id
		WHERE (r.ReceivableType IN('CapitalLeaseRental', 'LeaseFloatRateAdj', 'OperatingLeaseRental', 'OverTermRental', 'Supplemental', 'LoanInterest', 'LoanPrincipal')
			   OR (r.IsGLPosted = 0 AND r.ReceivableType NOT IN('CapitalLeaseRental', 'LeaseFloatRateAdj', 'OperatingLeaseRent', 'OverTermRental', 'Supplemental', 'LoanInterest', 'LoanPrincipal', 'PropertyTax', 'PropertyTaxEscrow', 'AssetSale'))
			   OR (r.AccountingTreatment = 'CashBased' AND r.ReceivableType = 'AssetSale'));

CREATE NONCLUSTERED INDEX IX_Id ON #ChargeoffExpenseRecords(EntityId);


UPDATE #ChargeoffExpenseRecords SET 
										GainAmount_LC = LeaseComponentAmountApplied_Amount
									  , GainAmount_NLC = NonLeaseComponentAmountApplied_Amount
	WHERE GainAmount_Amount != 0.00
		  AND GainAmount_Amount = AmountApplied;

UPDATE #ChargeoffExpenseRecords SET 
											GainAmount_LC = CASE
																WHEN NonLeaseComponentAmountApplied_Amount = 0.00
																THEN GainAmount_Amount
																ELSE GainAmount_LC
															END
										  , GainAmount_NLC = CASE
																 WHEN LeaseComponentAmountApplied_Amount = 0.00
																 THEN GainAmount_Amount
																 ELSE GainAmount_NLC
															 END
		WHERE GainAmount_Amount != 0.00
			  AND (GainAmount_LC IS NULL OR GainAmount_NLC IS NULL)
			  AND (NonLeaseComponentAmountApplied_Amount = 0.00 OR LeaseComponentAmountApplied_Amount = 0.00);

UPDATE #ChargeoffExpenseRecords SET 
											GainAmount_NLC = CASE
																 WHEN NonLeaseComponentAmountApplied_Amount = 0.00
																 THEN 0.00
																 ELSE GainAmount_NLC
															 END
										  , GainAmount_LC = CASE
																WHEN LeaseComponentAmountApplied_Amount = 0.00
																THEN 0.00
																ELSE GainAmount_LC
															END
		FROM #ChargeoffExpenseRecords
		WHERE(NonLeaseComponentAmountApplied_Amount = 0.00 OR LeaseComponentAmountApplied_Amount = 0.00);

;WITH CTE_ChargeoffExpense
			 AS (SELECT ABS(ChargeoffExpenseAmount_LC) - co.LeaseComponentAmount_Amount AS ChargeoffExpenseAmount_LC
					  , ABS(ChargeoffExpenseAmount_NLC) - co.NonLeaseComponentAmount_Amount AS ChargeoffExpenseAmount_NLC
					  , ABS(GainAmount_LC) - co.LeaseComponentGain_Amount AS ChargeoffGainAmount_LC
					  , ABS(GainAmount_NLC) - co.NonLeaseComponentGain_Amount AS ChargeoffGainAmount_NLC
					  , co.ReceiptId
				 FROM #ChargeoffExpenseReceiptIds co
					  INNER JOIN
				 (
					 SELECT SUM(ISNULL(ChargeoffExpenseAmount_LC, 0.00)) AS ChargeoffExpenseAmount_LC
						  , SUM(ISNULL(ChargeoffExpenseAmount_NLC, 0.00)) AS ChargeoffExpenseAmount_NLC
						  , SUM(ISNULL(GainAmount_LC, 0.00)) AS GainAmount_LC
						  , SUM(ISNULL(GainAmount_NLC, 0.00)) AS GainAmount_NLC
						  , Id
					 FROM #ChargeoffExpenseRecords
					 GROUP BY Id
				 ) AS t ON t.Id = co.ReceiptId)

			 UPDATE #ChargeoffExpenseRecords SET 
												 GainAmount_LC = CASE
																	 WHEN coe.GainAmount_LC IS NULL
																	 THEN cte.ChargeoffGainAmount_LC
																	 ELSE coe.GainAmount_LC
																 END
											   , GainAmount_NLC = CASE
																	  WHEN coe.GainAmount_NLC IS NULL
																	  THEN cte.ChargeoffGainAmount_NLC
																	  ELSE coe.GainAmount_NLC
																  END
			 FROM #ChargeoffExpenseRecords coe
				  INNER JOIN CTE_ChargeoffExpense cte ON cte.ReceiptId = coe.Id
			 WHERE(coe.ChargeoffExpenseAmount != 0.00
				   OR coe.GainAmount_Amount != 0.00)
				  AND (coe.ChargeoffExpenseAmount_LC IS NULL OR coe.ChargeoffExpenseAmount_NLC IS NULL
					   OR coe.GainAmount_LC IS NULL OR coe.GainAmount_NLC IS NULL);

UPDATE rard SET 
						RecoveryAmount_LC = coe.RecoveryAmount_LC
					  , RecoveryAmount_NLC = coe.RecoveryAmount_NLC
					  , GainAmount_LC = coe.GainAmount_LC
					  , GainAmount_NLC = coe.GainAmount_NLC
					  , ChargeoffExpenseAmount_LC = coe.ChargeoffExpenseAmount_LC
					  , ChargeoffExpenseAmount_NLC = coe.ChargeoffExpenseAmount_NLC
					  , ChargeoffExpenseAmount = coe.ChargeoffExpenseAmount
					  , IsRecovery = CAST(0 AS BIT)
		FROM ##Contract_ReceiptApplicationReceivableDetails rard
			 INNER JOIN #ChargeoffExpenseRecords coe ON coe.RardId = rard.RardId

END

END

GO
