SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SPHC_SalesTaxReceivable_Reconciliation]
(
	@ResultOption NVARCHAR(20),
	@ExpectedEntryItemDetail ExpectedEntryItemDetail READONLY,
	@LegalEntityIds ReconciliationId READONLY,
	@ContractIds ReconciliationId READONLY,  
	@CustomerIds ReconciliationId READONLY,  
	@DiscountingIds ReconciliationId READONLY
)
AS
    BEGIN
	SET NOCOUNT ON
	SET ANSI_WARNINGS OFF

IF OBJECT_ID('tempdb..#ChargeOff') IS NOT NULL 
BEGIN
DROP TABLE #ChargeOff
END
IF OBJECT_ID('tempdb..#RecievableEntryItems') IS NOT NULL 
BEGIN
DROP TABLE #RecievableEntryItems
END
IF OBJECT_ID('tempdb..#ExpectedEntryItemDetails') IS NOT NULL 
BEGIN
DROP TABLE #ExpectedEntryItemDetails
END
IF OBJECT_ID('tempdb..#Syndications') IS NOT NULL 
BEGIN
DROP TABLE #Syndications
END
IF OBJECT_ID('tempdb..#Syndications') IS NOT NULL 
BEGIN
DROP TABLE #ReceivableGLPostingInfo
END
IF OBJECT_ID('tempdb..#SyndicationFunderRemitting') IS NOT NULL 
BEGIN
DROP TABLE #SyndicationFunderRemitting
END
IF OBJECT_ID('tempdb..#DistinctContracts') IS NOT NULL 
BEGIN
DROP TABLE #DistinctContracts
END
IF OBJECT_ID('tempdb..#ReceivableGLPostingInfo') IS NOT NULL 
BEGIN
DROP TABLE #ReceivableGLPostingInfo
END
IF OBJECT_ID('tempdb..#RecievableTaxDetails') IS NOT NULL 
BEGIN
DROP TABLE #RecievableTaxDetails
END
IF OBJECT_ID('tempdb..#ReceiptDetails') IS NOT NULL 
BEGIN
DROP TABLE #ReceiptDetails
END
IF OBJECT_ID('tempdb..#GLTrialBalance') IS NOT NULL 
BEGIN
DROP TABLE #GLTrialBalance
END
IF OBJECT_ID('tempdb..#SalesTaxGLPostedAmount') IS NOT NULL 
BEGIN
DROP TABLE #SalesTaxGLPostedAmount
END
IF OBJECT_ID('tempdb..#ReceiptGLPosting') IS NOT NULL 
BEGIN
DROP TABLE #ReceiptGLPosting
END
IF OBJECT_ID('tempdb..#ResultList') IS NOT NULL 
BEGIN
DROP TABLE #ResultList
END
IF OBJECT_ID('tempdb..#NonCashSalesTax') IS NOT NULL
    BEGIN
        DROP TABLE #NonCashSalesTax;
END;

IF OBJECT_ID('tempdb..#SalesTaxReceivableSummary') IS NOT NULL
    BEGIN
        DROP TABLE #SalesTaxReceivableSummary;
END;



CREATE TABLE #NonCashSalesTax
(LessorPortionNonCash DECIMAL(16, 2), 
 FunderPortionNonCash DECIMAL(16, 2), 
 EntityId             BIGINT, 
 GLContractType       NVARCHAR(15), 
 GLTemplateId         BIGINT,
 LegalEntityId		  BIGINT
);

DECLARE @Migration nvarchar(50); 
DECLARE @True BIT= 1;
DECLARE @False BIT= 0;
DECLARE @LegalEntitiesCount BIGINT= ISNULL((SELECT COUNT(*) FROM @LegalEntityIds), 0);
DECLARE @ContractsCount BIGINT= ISNULL((SELECT COUNT(*) FROM @ContractIds), 0);
DECLARE @CustomersCount BIGINT= ISNULL((SELECT COUNT(*) FROM @CustomerIds), 0);
DECLARE @DiscountingsCount BIGINT= ISNULL((SELECT COUNT(*) FROM @DiscountingIds), 0);
SELECT @Migration = Value FROM GlobalParameters WHERE Category ='Migration' AND Name = 'ConversionSource'

SELECT DISTINCT 
       gt.Id
INTO #RecievableEntryItems
FROM GLEntryItems ge
     INNER JOIN GLTemplateDetails gtd ON ge.Id = gtd.EntryItemId
										 AND ge.IsActive = 1
										 AND gtd.IsActive = 1
     INNER JOIN GLTemplates gt ON gt.Id = gtd.GLTemplateId
							      AND gt.IsReadyToUse = 1
WHERE ge.Name = 'Receivable';

CREATE NONCLUSTERED INDEX IX_Id ON #RecievableEntryItems(Id)

SELECT 
	GLTransactionType, 
	EntryItemName,
	CASE WHEN IsDebit = 'True' THEN 1 ELSE 0 END AS IsDebit,
	CASE WHEN IsCashBased = 'True' THEN 1 ELSE 0 END AS IsCashBased,
	CASE WHEN IsAccrualBased = 'True' THEN 1 ELSE 0 END AS IsAccrualBased,
	CASE WHEN IsMemoBased = 'True' THEN 1 ELSE 0 END AS IsMemoBased,
	CASE WHEN IsPrepaidApplicable = 'True' THEN 1 ELSE 0 END AS IsPrepaidApplicable,
	AssetComponent,
	CASE WHEN IsInterCompany = 'True' THEN 1 ELSE 0 END AS IsInterCompany,
	CASE WHEN IsFunderOwnedTax = 'True' THEN 1 ELSE 0 END AS IsFunderOwnedTax,
	CASE WHEN IsOTP = 'True' THEN 1 ELSE 0 END AS IsOTP,
	CASE WHEN IsSupplemental = 'True' THEN 1 ELSE 0 END AS IsSupplemental,
	CASE WHEN IsBlendedItem = 'True' THEN 1 ELSE 0 END AS IsBlendedItem,
	CASE WHEN IsVendorOwned = 'True' THEN 1 ELSE 0 END AS IsVendorOwned
INTO #ExpectedEntryItemDetails 
FROM @ExpectedEntryItemDetail

SELECT c.Id
     , co.ChargeOffDate
INTO #ChargeOff
FROM Contracts c
     INNER JOIN ChargeOffs co ON co.ContractId = c.Id
WHERE co.IsActive = 1
      AND co.Status = 'Approved'
      AND co.IsRecovery = 0
	  AND co.ReceiptId IS NULL;
	  
CREATE NONCLUSTERED INDEX IX_Id ON #ChargeOff(Id)

SELECT Contracts.Id
     , rft.EffectiveDate
	 , Contracts.SyndicationType
INTO #Syndications
FROM Contracts
     INNER JOIN ReceivableForTransfers rft ON rft.ContractId = Contracts.Id
WHERE rft.ApprovalStatus = 'Approved';	  

CREATE NONCLUSTERED INDEX IX_Id ON #Syndications(Id)

SELECT ContractId, rft.Id AS SyndicationId
INTO #SyndicationFunderRemitting
FROM #Syndications syndication
INNER JOIN ReceivableForTransfers rft ON rft.ContractId = syndication.Id
WHERE rft.ApprovalStatus = 'Approved'
AND rft.Id IN (SELECT ReceivableForTransferId FROM ReceivableForTransferFundingSources WHERE SalesTaxResponsibility ='RemitOnly');


CREATE NONCLUSTERED INDEX IX_Id ON #SyndicationFunderRemitting(ContractId)


SELECT DISTINCT R.Id AS ReceivableId
     , R.EntityId
     , R.EntityType
	 , R.IsCollected
     , R.IsGLPosted
     , R.DueDate
     , RT.Name AS ReceivableType
     , RC.AccountingTreatment
     , GTT.Name AS GLTransactionType
     , 'SyndicatedAR' AS SyndicationGLTransactionType
     , R.TotalAmount_Amount
     , R.TotalBalance_Amount
     , R.FunderId
     , R.PaymentScheduleId
     , R.SourceId
     , R.SourceTable
     , P.IsInterCompany
     , CASE
           WHEN C.ChargeOffStatus IS NOT NULL
           THEN C.ChargeOffStatus
           ELSE '_'
       END AS ChargeOffStatus
     , CASE
           WHEN C.SyndicationType = 'None'
           THEN '_'
           WHEN C.SyndicationType != 'None'
                AND C.SyndicationType IS NOT NULL
           THEN C.SyndicationType
           ELSE '_'
       END AS SyndicationType
     , R.IncomeType
	 , RC.Name AS ReceivableCodeName
	 , GT.Name AS GLTemplateName
	 , GT.Id AS GLTemplateId
	 , CASE 
		   WHEN c.IsNonAccrual IS NULL 
		   THEN 0 
		   ELSE c.IsNonAccrual 
	   END AS IsNonAccrual 
	, CASE
		  WHEN c.ContractType IS NULL OR R.EntityType != 'CT'
		  THEN '_'
		  ELSE c.ContractType
	  END AS ContractType
	, CASE 
		  WHEN R.EntityType = 'CT'
		  THEN 'Contract'
		  WHEN R.EntityType = 'CU'
		  THEN 'Customer'
		  WHEN R.EntityType = 'DT'
		  THEN 'Discounting'
	  END AS GLContractType
	, CASE
          WHEN C.ContractType = 'Lease'
          THEN LEPS.StartDate
          WHEN C.ContractType = 'Loan'
          THEN LOPS.StartDate
          ELSE NULL
      END AS StartDate
   , R.LegalEntityId
   , CASE WHEN r.EntityType ='CU' 
		  THEN P.PartyName 
		  ELSE NULL
	  END AS PartyName
   ,  CASE WHEN r.EntityType ='CU' 
		  THEN P.Alias 
		  ELSE NULL
	  END AS PartyAlias
   , c.SequenceNumber
   , c.Alias AS ContractAlias
  , CASE WHEN C.u_ConversionSource = @Migration
		  THEN 'Yes'
		  ELSE 'No'
	 END AS [IsMigrated]
INTO #ReceivableGLPostingInfo
FROM Receivables R
	 JOIN ReceivableTaxes taxes ON taxes.ReceivableId = R.Id
	 JOIN ReceivableCodes RC ON R.ReceivableCodeId = RC.Id
     JOIN ReceivableTypes RT ON RC.ReceivableTypeId = RT.Id
     JOIN GLTemplates GT ON taxes.GLTemplateId = GT.Id
     JOIN GLTransactionTypes GTT ON GT.GLTransactionTypeId = GTT.Id
     JOIN Parties P ON R.CustomerId = P.Id
     LEFT JOIN Contracts C ON R.EntityId = C.Id
                              AND R.EntityType = 'CT'
	 LEFT JOIN #SyndicationFunderRemitting funderRemitting ON funderRemitting.ContractId = c.Id
     LEFT JOIN LeasePaymentSchedules LEPS ON R.PaymentScheduleId = LEPS.Id
                                             AND C.ContractType = 'Lease'  AND R.SourceTable NOT IN ('CPUSchedule', 'SundryRecurring')
     LEFT JOIN LoanPaymentSchedules LOPS ON R.PaymentScheduleId = LOPS.Id
                                            AND C.ContractType = 'Loan'  AND R.SourceTable NOT IN ('CPUSchedule', 'SundryRecurring')
	 LEFT JOIN TiedContractPaymentDetails payment ON payment.PaymentScheduleId = R.PaymentScheduleId
												     AND payment.ContractId = R.EntityId  AND R.SourceTable NOT IN ('CPUSchedule', 'SundryRecurring')
													 AND R.EntityType = 'CT' AND Payment.IsActive = 1
WHERE R.IsActive = 1
      AND R.IsDummy = 0
	  AND (R.IsCollected = 1 OR payment.Id IS NOT NULL)
	  AND NOT(R.FunderId IS NOT NULL AND funderRemitting.ContractId IS NOT NULL)
	  AND GTT.Name = 'SalesTax'
	  AND @True = (CASE 
					   WHEN @LegalEntitiesCount > 0 AND EXISTS (SELECT Id FROM @LegalEntityIds WHERE Id = R.LegalEntityId) THEN @True
					   WHEN @LegalEntitiesCount = 0 THEN @True ELSE @False END)
	  AND @True = (CASE 
					   WHEN @CustomersCount > 0 AND EXISTS (SELECT Id FROM @CustomerIds WHERE Id = R.CustomerId) THEN @True
					   WHEN @CustomersCount = 0 THEN @True ELSE @False END)
	  AND (@True = (CASE 
					    WHEN @ContractsCount > 0 AND EXISTS (SELECT Id FROM @ContractIds WHERE Id = R.EntityId AND R.EntityType = 'CT') THEN @True
						WHEN @ContractsCount = 0 AND @DiscountingsCount = 0 THEN @True ELSE @False END)
						  OR @True = (CASE 
										  WHEN @DiscountingsCount > 0 AND EXISTS (SELECT Id FROM @DiscountingIds WHERE Id = R.EntityId AND R.EntityType = 'DT') THEN @True
										  WHEN @DiscountingsCount = 0 AND @ContractsCount = 0 THEN @True ELSE @False END))
 
 CREATE NONCLUSTERED INDEX IX_Id ON #ReceivableGLPostingInfo(ReceivableId);


SELECT DISTINCT 
       R.EntityId
     , R.GLContractType
	 , R.GLTemplateId
	 , Convert(nvarchar(25), R.ContractType) AS ContractType
	 , R.LegalEntityId
	 , R.PartyName
	 , R.SequenceNumber
	 , R.ContractAlias
	 , R.PartyAlias
	 , R.[IsMigrated]
	 , R.ChargeOffStatus
	 , R.GLTransactionType
INTO #DistinctContracts
FROM #ReceivableGLPostingInfo R;

CREATE NONCLUSTERED INDEX IX_Id ON #DistinctContracts(EntityId, GLContractType, GLTemplateId, LegalEntityId);

UPDATE dc SET ContractType = lfd.LeaseContractType
FROM #DistinctContracts dc
INNER JOIN LeaseFinances lf ON dc.EntityId = lf.ContractId
INNER JOIN LeaseFinanceDetails lfd ON lfd.Id = lf.Id
WHERE dc.GLContractType = 'Contract'


UPDATE dc SET SequenceNumber = ds.SequenceNumber,
ContractAlias = ds.Alias
FROM #DistinctContracts dc
INNER JOIN Discountings ds ON dc.EntityId = ds.Id AND dc.GLContractType = 'Discounting'

SELECT r.EntityId
     , r.GLContractType
     , r.GLTemplateId
	 , CASE WHEN r.EntityType ='CU' THEN r.LegalEntityId ELSE NULL END AS LegalEntityId
     , SUM(CASE 
			   WHEN r.FunderId IS NULL
			   THEN rt.Amount_Amount
			   ELSE 0.00
			END) AS SalesTaxAmount
     , SUM(CASE
               WHEN rt.IsGLPosted = 1
					AND r.FunderId IS NULL
               THEN rt.Amount_Amount
               ELSE 0.00
           END) AS SalesTaxGLPosted
     , SUM(CASE
               WHEN rt.IsGLPosted = 1
			        AND r.FunderId IS NULL
               THEN rt.Balance_Amount
               ELSE 0.00
           END) AS SalesTaxOSAR
     , SUM(CASE
               WHEN rt.IsGLPosted = 0
			        AND r.FunderId IS NULL
               THEN rt.Amount_Amount - rt.Balance_Amount
               ELSE 0.00
           END) AS SalesTaxPrepaid
     , SUM(CASE
               WHEN --rt.IsGLPosted = 0 -
			        r.FunderId IS NULL
               THEN rt.Balance_Amount
               ELSE 0.00
           END) AS SalesTaxBalance
     , SUM(CASE 
			   WHEN r.FunderId IS NOT NULL
			   THEN rt.Amount_Amount
			   ELSE 0.00
			END) AS FunderSalesTaxAmount
     , SUM(CASE 
			   WHEN r.FunderId IS NOT NULL
					AND rt.IsGLPosted = 1
			   THEN rt.Amount_Amount
			   ELSE 0.00
			END) AS FunderSalesTaxGLPosted
     , SUM(CASE
               WHEN rt.IsGLPosted = 1
					AND r.FunderId IS NOT NULL
               THEN rt.Balance_Amount
               ELSE 0.00
           END) AS FunderSalesTaxOSAR
     , SUM(CASE
               WHEN rt.IsGLPosted = 0
					AND r.FunderId IS NOT NULL
               THEN rt.Amount_Amount - rt.Balance_Amount
               ELSE 0.00
           END) AS FunderSalesTaxPrepaid
     , SUM(CASE
               WHEN --rt.IsGLPosted = 0-
					r.FunderId IS NOT NULL
               THEN rt.Balance_Amount
               ELSE 0.00
           END) AS FunderSalesTaxBalance
INTO #RecievableTaxDetails
FROM #ReceivableGLPostingInfo r
     INNER JOIN ReceivableTaxes rt ON r.ReceivableId = rt.ReceivableId
WHERE rt.IsActive = 1
GROUP BY r.EntityId
       , r.GLContractType
       , r.GLTemplateId
	   , CASE WHEN r.EntityType ='CU' THEN r.LegalEntityId ELSE NULL END;


CREATE NONCLUSTERED INDEX IX_Id ON #RecievableTaxDetails(EntityId, GLContractType, GLTemplateId, LegalEntityId)

DECLARE @Sql nvarchar(max) ='';

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'ReceivableTaxes' AND COLUMN_NAME = 'IsCashBased')
BEGIN
SET @Sql = '
SELECT SUM(CASE WHEN temp.FunderId IS NULL THEN rard.TaxApplied_Amount ELSE 0.00 END) AS LessorPortionNonCash
		, SUM(CASE WHEN temp.FunderId IS NOT NULL THEN rard.TaxApplied_Amount ELSE 0.00 END) AS FunderPortionNonCash
		, temp.EntityId
		, temp.GLContractType
		, temp.GLTemplateId
		, CASE WHEN temp.EntityType =''CU'' THEN temp.LegalEntityId ELSE NULL END
FROM #ReceivableGLPostingInfo temp
INNER JOIN ReceivableTaxes rt ON rt.ReceivableId = temp.ReceivableId
INNER JOIN ReceivableDetails rd on rd.ReceivableId = temp.ReceivableId
INNER JOIN ReceiptApplicationReceivableDetails rard on rard.ReceivableDetailId = rd.Id
INNER JOIN ReceiptApplications ra on rard.ReceiptApplicationId = ra.Id
INNER JOIN Receipts receipt ON receipt.Id = ra.ReceiptId
WHERE rt.IsActive = 1
		AND rt.IsCashBased = 1
		AND rt.IsDummy = 0
		AND temp.IsCollected = 1
		AND receipt.ReceiptClassification = ''NonCash''
		AND receipt.Status IN (''Completed'', ''Posted'')
		AND rard.IsActive = 1
GROUP BY temp.EntityId
       , temp.GLContractType
       , temp.GLTemplateId
	   , CASE WHEN temp.EntityType =''CU'' THEN temp.LegalEntityId ELSE NULL END'


INSERT INTO #NonCashSalesTax(LessorPortionNonCash, FunderPortionNonCash, EntityId, GLContractType, GLTemplateId, LegalEntityId)
EXEC (@Sql)

CREATE NONCLUSTERED INDEX IX_Id ON #NonCashSalesTax(EntityId, GLContractType, GLTemplateId, LegalEntityId);

END

SELECT r.EntityId
     , r.GLContractType
     , r.GLTemplateId
	 , CASE WHEN r.EntityType ='CU' THEN r.LegalEntityId ELSE NULL END AS LegalEntityId
     , SUM(CASE
               WHEN ReceiptClassification IN('Cash', 'NonAccrualNonDSL', 'DSL') AND rt.ReceiptTypeName NOT IN('PayableOffset', 'SecurityDeposit',  'EscrowRefund')
                    --AND rard.RecoveryAmount_Amount = 0.00	
                    AND r.FunderId IS NULL
               THEN rard.TaxApplied_Amount
           END) AS CashTaxAmountApplied
     , SUM(CASE
               WHEN (ReceiptClassification NOT IN('Cash', 'NonAccrualNonDSL', 'DSL') OR rt.ReceiptTypeName IN('PayableOffset', 'SecurityDeposit',  'EscrowRefund'))
                    --AND rard.RecoveryAmount_Amount = 0.00 
                    AND r.FunderId IS NULL
               THEN rard.TaxApplied_Amount
               ELSE 0.00
           END) AS NonCashTaxAmountApplied
     , SUM(CASE
               WHEN ReceiptClassification IN('Cash', 'NonAccrualNonDSL', 'DSL') AND rt.ReceiptTypeName NOT IN('PayableOffset', 'SecurityDeposit',  'EscrowRefund')
                    --AND rard.RecoveryAmount_Amount = 0.00 
                    AND r.FunderId IS NOT NULL
               THEN rard.TaxApplied_Amount
           END) AS FunderCashTaxAmountApplied
     , SUM(CASE
               WHEN (ReceiptClassification NOT IN('Cash', 'NonAccrualNonDSL', 'DSL') OR rt.ReceiptTypeName IN('PayableOffset', 'SecurityDeposit',  'EscrowRefund'))
                    --AND rard.RecoveryAmount_Amount = 0.00	
                    AND r.FunderId IS NOT NULL
               THEN rard.TaxApplied_Amount
               ELSE 0.00
           END) AS FunderNonCashTaxAmountApplied
INTO #ReceiptDetails
FROM #ReceivableGLPostingInfo r
     JOIN ReceivableDetails rd ON rd.ReceivableId = r.ReceivableId
     JOIN ReceiptApplicationReceivableDetails rard ON rard.ReceivableDetailId = rd.Id
     JOIN ReceiptApplications ra ON ra.Id = rard.ReceiptApplicationId
     JOIN Receipts Receipt ON ra.ReceiptId = Receipt.Id
     JOIN ReceiptTypes rt ON rt.Id = receipt.TypeId
WHERE Receipt.Status IN('Posted', 'Completed')
     AND rd.IsActive = 1
     AND rard.IsActive = 1
     AND rt.IsActive = 1
GROUP BY r.EntityId
       , r.GLContractType
       , r.GLTemplateId
	   , CASE WHEN r.EntityType ='CU' THEN r.LegalEntityId ELSE NULL END;

CREATE NONCLUSTERED INDEX IX_Id ON #ReceiptDetails(EntityId, GLContractType, GLTemplateId, LegalEntityId)

   SELECT EntityId
		     , EntityType
			 , LegalEntityId
             , EntryItemId
             , SUM(DebitAmount) DebitAmount
             , SUM(CreditAmount) CreditAmount
             , MatchingEntryName
             , SourceId
			 , GLJournalId
			 , GLTemplateId
			 , MatchingGLTemplateId
			 , MatchingTransactionTypeName
        INTO #GLTrialBalance
        FROM
        (
            SELECT DISTINCT gljd.EntityId AS EntityId
				 , gljd.EntityType AS EntityType
				 , CASE WHEN gljd.EntityType ='Customer' THEN gl.LegalEntityId ELSE NULL END AS LegalEntityId
                 , glei.Id AS EntryItemId
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
                 , mglei.Name MatchingEntryName
                 , gljd.SourceId
				 , gljd.GLJournalId
				 , gltd.GLTemplateId
				 , mgltd.GLTemplateId AS MatchingGLTemplateId
				 , mgltt.Name AS MatchingTransactionTypeName
				 , gljd.Id
            FROM GLJournalDetails gljd
                 INNER JOIN GLjournals gl ON gljd.GLJournalId = gl.Id
				 INNER JOIN GLTemplateDetails gltd ON gltd.Id = gljd.GLTemplateDetailId
                 INNER JOIN GLEntryItems glei ON glei.Id = gltd.EntryItemId AND glei.IsActive = 1
                 INNER JOIN GLTransactionTypes gltt ON glei.GLTransactionTypeId = gltt.Id AND gltt.IsActive = 1
                 INNER JOIN #DistinctContracts contracts ON gljd.EntityId = contracts.EntityId
															AND gljd.EntityType = contracts.GLContractType
															AND (gltd.GLTemplateId = contracts.GLTemplateId OR gltd.GLTemplateId IN (SELECT Id FROM #RecievableEntryItems))
				 INNER JOIN #ExpectedEntryItemDetails eetd ON (eetd.EntryItemName = glei.Name OR glei.Name = 'Receivable')
                 LEFT JOIN GLTemplateDetails mgltd ON gljd.MatchingGLTemplateDetailId = mgltd.Id
                 LEFT JOIN GLEntryItems mglei ON mglei.Id = mgltd.EntryItemId AND mglei.IsActive = 1
												 AND eetd.EntryItemName = mglei.Name 
                 LEFT JOIN GLTransactionTypes mgltt ON mgltt.Id = mglei.GLTransactionTypeId AND mgltt.IsActive = 1

        ) AS T
        GROUP BY EntityId
			   , EntityType
               , EntryItemId
			   , LegalEntityId
               , MatchingEntryName
               , SourceId
			   , GLJournalId
			   , GLTemplateId
			   , MatchingGLTemplateId
			   , MatchingTransactionTypeName;

CREATE NONCLUSTERED INDEX IX_Id ON #GLTrialBalance(EntryItemId);


SELECT gld.EntityId
     , gld.EntityType
     , gld.GLTemplateId
	 , CASE WHEN gld.EntityType ='Customer' THEN gld.LegalEntityId ELSE NULL END AS LegalEntityId
     ,SUM(CASE WHEN eetd.IsFunderOwnedTax = 0
			   THEN gld.DebitAmount - gld.CreditAmount
			   ELSE 0.00
		  END) AS GLPosted
     , SUM(CASE
               WHEN eetd.IsPrepaidApplicable = 0
					AND eetd.IsFunderOwnedTax = 0
					AND gld.MatchingEntryName IS NULL
               THEN gld.DebitAmount
               ELSE 0.00
           END) -
		SUM(CASE
               WHEN eetd.IsPrepaidApplicable = 0
					AND eetd.IsFunderOwnedTax = 0
					AND gld.MatchingEntryName IS NULL
               THEN gld.CreditAmount 
               ELSE 0.00
           END) AS OSAR
		, SUM(CASE
               WHEN eetd.IsPrepaidApplicable = 1
					AND eetd.IsFunderOwnedTax = 0
               THEN gld.CreditAmount
               ELSE 0.00
           END) -
		SUM(CASE
               WHEN eetd.IsPrepaidApplicable = 1
					AND eetd.IsFunderOwnedTax = 0
               THEN gld.DebitAmount
               ELSE 0.00
           END)AS Prepaid
     ,SUM(CASE WHEN eetd.IsFunderOwnedTax = 1
			   THEN gld.DebitAmount - gld.CreditAmount
			   ELSE 0.00
		  END) AS FunderGLPosted
     , SUM(CASE
               WHEN eetd.IsPrepaidApplicable = 0
					AND eetd.IsFunderOwnedTax = 1
					AND gld.MatchingEntryName IS NULL
               THEN gld.DebitAmount
               ELSE 0.00
           END) -
		SUM(CASE
               WHEN eetd.IsPrepaidApplicable = 0
					AND eetd.IsFunderOwnedTax = 1
					AND gld.MatchingEntryName IS NULL
               THEN gld.CreditAmount 
               ELSE 0.00
           END) AS FunderOSAR
		, SUM(CASE
               WHEN eetd.IsPrepaidApplicable = 1
					AND eetd.IsFunderOwnedTax = 1
               THEN gld.CreditAmount
               ELSE 0.00
           END) -
		SUM(CASE
               WHEN eetd.IsPrepaidApplicable = 1
					AND eetd.IsFunderOwnedTax = 1
               THEN gld.DebitAmount
               ELSE 0.00
           END)AS FunderPrepaid
INTO #SalesTaxGLPostedAmount
FROM #GLTrialBalance gld
     INNER JOIN GLEntryItems glei ON gld.EntryItemId = glei.Id
                                     AND glei.IsActive = 1
     INNER JOIN GLTransactionTypes gltt ON GLEI.GLTransactionTypeId = GLTT.Id
										   AND gltt.IsActive = 1
     INNER JOIN #ExpectedEntryItemDetails eetd ON eetd.GLTransactionType = gltt.Name 
												  AND glei.Name = eetd.EntryItemName  
WHERE eetd.IsDebit = 1
AND eetd.IsBlendedItem = 0
AND gltt.Name = 'SalesTax'
AND eetd.IsVendorOwned = 0
GROUP BY gld.EntityId
       , gld.EntityType
       , gld.GLTemplateId
	   , CASE WHEN gld.EntityType ='Customer' THEN gld.LegalEntityId ELSE NULL END;


CREATE NONCLUSTERED INDEX IX_Id ON #SalesTaxGLPostedAmount(EntityId, EntityType, GLTemplateId, LegalEntityId)

SELECT gld.EntityId
     , gld.EntityType
     , gld.MatchingGLTemplateId
	 , CASE WHEN gld.EntityType ='Customer' THEN gld.LegalEntityId ELSE NULL END AS LegalEntityId
     , SUM(CASE 
			  WHEN eetd.IsPrepaidApplicable = 0
				   AND eetd.IsDebit = 1
				   AND eetd.IsFunderOwnedTax = 0
			  THEN gld.CreditAmount - gld.DebitAmount
			  ELSE 0.00
		   END) OSARAmount
     , SUM(CASE
               WHEN eetd.IsPrepaidApplicable = 1
				    AND eetd.IsDebit = 1
					AND eetd.IsFunderOwnedTax = 0
               THEN gld.DebitAmount
               ELSE 0.00
           END) - 
	   SUM(CASE
                WHEN eetd.IsPrepaidApplicable = 1
					 AND eetd.IsDebit = 1
					 AND eetd.IsFunderOwnedTax = 0
                THEN gld.CreditAmount
                ELSE 0.00
            END) Prepaid
     , SUM(CASE
               WHEN types.Name ='ReceiptCash'
					AND eetd.IsDebit = 1
					AND eetd.IsFunderOwnedTax = 0
               THEN gld.CreditAmount
               ELSE 0.00
           END) - 
	   SUM(CASE
                WHEN eetd.IsDebit = 1
					 AND types.Name ='ReceiptCash'
					 AND eetd.IsFunderOwnedTax = 0
                THEN gld.DebitAmount
                ELSE 0.00
            END) CashPosted
     , SUM(CASE
               WHEN types.Name ='ReceiptNonCash'
					AND eetd.IsDebit = 1
					AND eetd.IsFunderOwnedTax = 0
               THEN gld.CreditAmount
               ELSE 0.00
           END) - 
	   SUM(CASE
                WHEN eetd.IsDebit = 1
					 AND types.Name ='ReceiptNonCash'
					 AND eetd.IsFunderOwnedTax = 0
                THEN gld.DebitAmount
                ELSE 0.00
            END) NonCashPosted
     , SUM(CASE 
			  WHEN eetd.IsPrepaidApplicable = 0
				   AND eetd.IsDebit = 1
				   AND eetd.IsFunderOwnedTax = 1
			  THEN gld.CreditAmount - gld.DebitAmount
			  ELSE 0.00
		   END) FunderOSARAmount
     , SUM(CASE
               WHEN eetd.IsPrepaidApplicable = 1
				    AND eetd.IsDebit = 1
					AND eetd.IsFunderOwnedTax = 1
               THEN gld.DebitAmount
               ELSE 0.00
           END) - 
	   SUM(CASE
                WHEN eetd.IsPrepaidApplicable = 1
					 AND eetd.IsDebit = 1
					 AND eetd.IsFunderOwnedTax = 1
                THEN gld.CreditAmount
                ELSE 0.00
            END) FunderPrepaid
     , SUM(CASE
               WHEN types.Name ='ReceiptCash'
					AND eetd.IsDebit = 1
					AND eetd.IsFunderOwnedTax = 1
               THEN gld.CreditAmount
               ELSE 0.00
           END) - 
	   SUM(CASE
                WHEN eetd.IsDebit = 1
					 AND types.Name ='ReceiptCash'
					 AND eetd.IsFunderOwnedTax = 1
                THEN gld.DebitAmount
                ELSE 0.00
            END) FunderCashPosted
     , SUM(CASE
               WHEN types.Name ='ReceiptNonCash'
					AND eetd.IsDebit = 1
					AND eetd.IsFunderOwnedTax = 1
               THEN gld.CreditAmount
               ELSE 0.00
           END) - 
	   SUM(CASE
                WHEN eetd.IsDebit = 1
					 AND types.Name ='ReceiptNonCash'
					 AND eetd.IsFunderOwnedTax = 1
                THEN gld.DebitAmount
                ELSE 0.00
            END) FunderNonCashPosted
INTO #ReceiptGLPosting
FROM #GLTrialBalance gld
     INNER JOIN GLEntryItems glei ON gld.MatchingEntryName = glei.Name
                                     AND glei.IsActive = 1
     INNER JOIN GLTransactionTypes gltt ON GLEI.GLTransactionTypeId = GLTT.Id
                                           AND gltt.IsActive = 1
										   AND gltt.Name = gld.MatchingTransactionTypeName
     INNER JOIN #ExpectedEntryItemDetails eetd ON eetd.GLTransactionType = gltt.Name
                                                  AND glei.Name = eetd.EntryItemName
     INNER JOIN GLEntryItems gl ON gl.Id = gld.EntryItemId AND gl.IsActive = 1
	 INNER JOIN GLTransactionTypes types ON types.Id = gl.GLTransactionTypeId AND types.IsActive = 1
WHERE gltt.Name IN ('SalesTax')
      AND gl.Name IN ('OTPReceivable','Receivable')
	  AND eetd.IsBlendedItem = 0
	  AND eetd.IsVendorOwned = 0
GROUP BY gld.EntityId
       , gld.EntityType
       , gld.MatchingGLTemplateId
	   , CASE WHEN gld.EntityType ='Customer' THEN gld.LegalEntityId ELSE NULL END;


CREATE NONCLUSTERED INDEX IX_Id ON #ReceiptGLPosting(EntityId, EntityType, MatchingGLTemplateId, LegalEntityId)

MERGE #SalesTaxGLPostedAmount AS receivable
USING (SELECT * FROM #ReceiptGLPosting) AS receipt
ON(receivable.GLTemplateId = receipt.MatchingGLTemplateId
	AND receivable.EntityId = receipt.EntityId
	AND receivable.EntityType = receipt.EntityType
	AND (receivable.LegalEntityId = receipt.LegalEntityId AND receivable.EntityType = 'Customer' OR receivable.EntityType != 'Customer'))
WHEN MATCHED
	THEN UPDATE SET 
					OSAR-=receipt.OSARAmount
					, Prepaid = ABS(receipt.Prepaid - receivable.Prepaid)
					, FunderOSAR -=  receipt.FunderOSARAmount
					, FunderPrepaid = ABS(receipt.FunderPrepaid - receivable.FunderPrepaid)
WHEN NOT MATCHED
		THEN
		INSERT(EntityId, EntityType, GLTemplateId,LegalEntityId,  GLPosted, OSAR, Prepaid, FunderGLPosted, FunderOSAR, FunderPrepaid)
		VALUES(receipt.EntityId, receipt.EntityType, receipt.MatchingGLTemplateId, receipt.LegalEntityId, 0.00, receipt.OSARAmount, receipt.Prepaid, 0.00, receipt.FunderOSARAmount, receipt.FunderPrepaid);
		

SELECT *
     , CASE
           WHEN [TaxReceivableGLPosted_Difference] != 0.00
                OR [CashPaidSalesTaxReceivable_Difference] != 0.00
                OR [NonCashPaidSalesTaxReceivable_Difference] != 0.00
                OR [SalesTaxOSAR_Difference] != 0.00
                OR [SalesTaxPrepaid_Difference] != 0.00
                OR [SalesTaxReceivableBalance_Difference] != 0.00
                OR [FunderOwned_LessorRemitting_SalesTax_GLPosted_ReceivableAmount_Difference] != 0.00
                OR [FunderOwned_LessorRemitting_CashPaidSalesTaxReceivable_Difference] != 0.00
                OR [FunderOwned_LessorRemitting_NonCashPaidSalesTaxReceivable_Difference] != 0.00
                OR [FunderOwned_LessorRemitting_SalesTaxPrepaid_Difference] != 0.00
                OR [FunderOwned_LessorRemitting_Balance_Difference] != 0.00
				OR [FunderOwned_LessorRemitting_SalesTaxOSAR_Difference] != 0.00
           THEN 'Problem Record'
           ELSE 'Not A Problem Record'
       END AS Result
INTO #ResultList
FROM 
	(SELECT dc.GLContractType AS [EntityType]
		 , dc.EntityId
		 , le.Name AS LegalEntityName
		 , dc.PartyName AS CustomerName
		 , dc.PartyAlias AS CustomerAlias
		 , dc.SequenceNumber AS SequenceNumber
		 , dc.[IsMigrated] AS [IsMigrated]
		 , dc.ContractAlias AS ContractAlias
		 , dc.ContractType
		 , CASE 
			   WHEN sy.Id IS NULL 
			   THEN 'NA'
			   ELSE sy.SyndicationType
			END AS SyndicationType
		 , dc.ChargeOffStatus
		 , gtt.Name AS GLTemplateName
		 , dc.GLTransactionType
		 , ISNULL(amount.SalesTaxAmount, 0.00) AS [TaxReceivableAmount_Table]
		 , ISNULL(amount.SalesTaxGLPosted, 0.00) - ISNULL(nonCash.LessorPortionNonCash , 0.00) AS [TaxReceivableGLPosted_Table]
		 , ISNULL(gl.GLPosted, 0.00) AS  [TaxReceivableGLPosted_GL]
		 , ISNULL(amount.SalesTaxGLPosted, 0.00) - ISNULL(nonCash.LessorPortionNonCash , 0.00) - ISNULL(gl.GLPosted, 0.00) as [TaxReceivableGLPosted_Difference]
		 , ISNULL(rd.CashTaxAmountApplied, 0.00) AS [CashPaidSalesTaxReceivable_Table]
		 , ISNULL(rgp.CashPosted, 0.00) AS [CashPaidSalesTaxReceivable_GL]
		 , ISNULL(rd.CashTaxAmountApplied, 0.00) - ISNULL(rgp.CashPosted, 0.00) AS [CashPaidSalesTaxReceivable_Difference]
		 , ISNULL(rd.NonCashTaxAmountApplied, 0.00) - ISNULL(nonCash.LessorPortionNonCash, 0.00) AS [NonCashPaidSalesTaxReceivable_Table]
		 , ISNULL(rgp.NonCashPosted, 0.00) AS [NonCashPaidSalesTaxReceivable_GL]
		 , ISNULL(rd.NonCashTaxAmountApplied, 0.00) - ISNULL(nonCash.LessorPortionNonCash, 0.00) - ISNULL(rgp.NonCashPosted, 0.00) AS [NonCashPaidSalesTaxReceivable_Difference]
		 , ISNULL(amount.SalesTaxOSAR, 0.00)  AS [SalesTaxOSAR_Table]
		 , ISNULL(gl.OSAR, 0.00) AS [SalesTaxOSAR_GL]
		 , ISNULL(amount.SalesTaxOSAR, 0.00) -  ISNULL(gl.OSAR, 0.00) AS [SalesTaxOSAR_Difference]
		 , ABS(ISNULL(amount.SalesTaxPrepaid, 0.00))  AS [SalesTaxPrepaid_Table]
		 , ABS(ISNULL(gl.Prepaid, 0.00)) AS [SalesTaxPrepaid_GL]
		 , ABS(ISNULL(amount.SalesTaxPrepaid, 0.00)) -  ABS(ISNULL(gl.Prepaid, 0.00)) AS [SalesTaxPrepaid_Difference]
		 , ISNULL(amount.SalesTaxBalance, 0.00) AS [SalesTaxReceivableBalance]
		 , ISNULL(amount.SalesTaxAmount, 0.00) - ISNULL(rd.CashTaxAmountApplied, 0.00) - ISNULL(rd.NonCashTaxAmountApplied, 0.00) AS [SalesTaxReceivableBalance_Calculation] 
		 , ISNULL(amount.SalesTaxBalance, 0.00) - (ISNULL(amount.SalesTaxAmount, 0.00) - ISNULL(rd.CashTaxAmountApplied, 0.00) - ISNULL(rd.NonCashTaxAmountApplied, 0.00)) AS [SalesTaxReceivableBalance_Difference]
		 , ISNULL(amount.FunderSalesTaxAmount, 0.00) AS [FunderOwned_LessorRemitting_SalesTax_ReceivableAmount_Table]
		 , ISNULL(amount.FunderSalesTaxGLPosted, 0.00) - ISNULL(nonCash.FunderPortionNonCash, 0.00) AS [FunderOwned_LessorRemitting_SalesTax_GLPosted_ReceivableAmount_Table]
		 , ISNULL(gl.FunderGLPosted, 0.00) AS  [FunderOwned_LessorRemitting_SalesTax_GLPosted_ReceivableAmount_GL]
		 , ISNULL(amount.FunderSalesTaxGLPosted, 0.00) - ISNULL(nonCash.FunderPortionNonCash, 0.00) - ISNULL(gl.FunderGLPosted, 0.00) as [FunderOwned_LessorRemitting_SalesTax_GLPosted_ReceivableAmount_Difference]
		 , ISNULL(rd.FunderCashTaxAmountApplied, 0.00) AS [FunderOwned_LessorRemitting_CashPaidSalesTaxReceivable_Table]
		 , ISNULL(rgp.FunderCashPosted, 0.00) AS [FunderOwned_LessorRemitting_CashPaidSalesTaxReceivable_GL]
		 , ISNULL(rd.FunderCashTaxAmountApplied, 0.00) - ISNULL(rgp.FunderCashPosted, 0.00) AS [FunderOwned_LessorRemitting_CashPaidSalesTaxReceivable_Difference]
		 , ISNULL(rd.FunderNonCashTaxAmountApplied, 0.00) - ISNULL(nonCash.FunderPortionNonCash, 0.00) AS [FunderOwned_LessorRemitting_NonCashPaidSalesTaxReceivable_Table]
		 , ISNULL(rgp.FunderNonCashPosted, 0.00) AS [FunderOwned_LessorRemitting_NonCashPaidSalesTaxReceivable_GL]
		 , ISNULL(rd.FunderNonCashTaxAmountApplied, 0.00) - ISNULL(rgp.FunderNonCashPosted, 0.00) - ISNULL(nonCash.FunderPortionNonCash, 0.00)  AS [FunderOwned_LessorRemitting_NonCashPaidSalesTaxReceivable_Difference]
		 , ISNULL(amount.FunderSalesTaxOSAR, 0.00) AS [FunderOwned_LessorRemitting_SalesTaxOSAR_Table]
		 , ISNULL(gl.FunderOSAR, 0.00) AS [FunderOwned_LessorRemitting_SalesTaxOSAR_GL]
		 , ISNULL(amount.FunderSalesTaxOSAR, 0.00) -  ISNULL(gl.FunderOSAR, 0.00) AS [FunderOwned_LessorRemitting_SalesTaxOSAR_Difference]
		 , ABS(ISNULL(amount.FunderSalesTaxPrepaid, 0.00))  AS [FunderOwned_LessorRemitting_SalesTaxPrepaid_Table]
		 , ABS(ISNULL(gl.FunderPrepaid, 0.00)) AS [FunderOwned_LessorRemitting_SalesTaxPrepaid_GL]
		 , ABS(ISNULL(amount.FunderSalesTaxPrepaid, 0.00)) -  ABS(ISNULL(gl.FunderPrepaid, 0.00)) AS [FunderOwned_LessorRemitting_SalesTaxPrepaid_Difference]
		 , ISNULL(amount.FunderSalesTaxBalance, 0.00) AS [FunderOwned_LessorRemitting_Balance_Table]
		 , ISNULL(amount.FunderSalesTaxAmount, 0.00) - ISNULL(rd.FunderCashTaxAmountApplied, 0.00) -  ISNULL(rd.FunderNonCashTaxAmountApplied, 0.00) as [FunderOwned_LessorRemitting_Balance_Calculation]  
		 , ISNULL(amount.FunderSalesTaxBalance, 0.00) - (ISNULL(amount.FunderSalesTaxAmount, 0.00) - ISNULL(rd.FunderCashTaxAmountApplied, 0.00) -  ISNULL(rd.FunderNonCashTaxAmountApplied, 0.00)) AS [FunderOwned_LessorRemitting_Balance_Difference]	
	FROM #DistinctContracts dc
	LEFT JOIN LegalEntities le ON le.Id = dc.LegalEntityId
	LEFT JOIN #ChargeOff co ON co.Id = dc.EntityId AND dc.GLContractType ='Contract'
	LEFT JOIN #Syndications sy ON sy.Id = dc.EntityId AND dc.GLContractType = 'Contract'
	LEFT JOIN #RecievableTaxDetails amount ON dc.EntityId = amount.EntityId
													 AND dc.GLContractType = amount.GLContractType
													 AND dc.GLTemplateId = amount.GLTemplateId
													 AND (dc.GLContractType = 'Customer' AND dc.LegalEntityId = amount.LegalEntityId OR dc.GLContractType != 'Customer')
	LEFT JOIN #SalesTaxGLPostedAmount gl ON dc.EntityId = gl.EntityId
													 AND dc.GLContractType = gl.EntityType
													 AND dc.GLTemplateId = gl.GLTemplateId
													  AND (dc.GLContractType = 'Customer' AND dc.LegalEntityId = gl.LegalEntityId OR dc.GLContractType != 'Customer')
	LEFT JOIN #ReceiptDetails rd ON dc.EntityId = rd.EntityId
													 AND dc.GLContractType = rd.GLContractType
													 AND dc.GLTemplateId = rd.GLTemplateId
													  AND (dc.GLContractType = 'Customer' AND dc.LegalEntityId = rd.LegalEntityId OR dc.GLContractType != 'Customer')
	LEFT JOIN #ReceiptGLPosting rgp ON dc.EntityId = rgp.EntityId
													 AND dc.GLContractType = rgp.EntityType
													 AND dc.GLTemplateId = rgp.MatchingGLTemplateId
													  AND (dc.GLContractType = 'Customer' AND dc.LegalEntityId = rgp.LegalEntityId OR dc.GLContractType != 'Customer')
	LEFT JOIN GLTemplates gtt ON gtt.Id = amount.GLTemplateId
	LEFT JOIN #NonCashSalesTax nonCash ON dc.EntityId = nonCash.EntityId
										  AND dc.GLContractType = nonCash.GLContractType
										  AND dc.GLTemplateId = nonCash.GLTemplateId
										   AND (dc.GLContractType = 'Customer' AND dc.LegalEntityId = nonCash.LegalEntityId OR dc.GLContractType != 'Customer')) AS T;

CREATE NONCLUSTERED INDEX IX_Id ON #ResultList(EntityId, EntityType)


	SELECT name AS Name, 0 AS Count, CAST (0 AS BIT) AS IsProcessed, CAST('' AS NVARCHAR(max)) AS Label
	INTO #SalesTaxReceivableSummary
	FROM tempdb.sys.columns
	WHERE object_id = OBJECT_ID('tempdb..#ResultList')
	AND Name LIKE '%Difference';

	DECLARE @query NVARCHAR(MAX);
	DECLARE @TableName NVARCHAR(max);
	WHILE EXISTS (SELECT 1 FROM #SalesTaxReceivableSummary WHERE IsProcessed = 0)
	BEGIN
	SELECT TOP 1 @TableName = Name FROM #SalesTaxReceivableSummary WHERE IsProcessed = 0

	SET @query = 'UPDATE #SalesTaxReceivableSummary SET Count = (SELECT COUNT(*) FROM #ResultList WHERE ' + @TableName+ ' != 0.00), IsProcessed = 1
					WHERE Name = '''+ @TableName+''' ;'
	EXEC (@query)
	END


	UPDATE #SalesTaxReceivableSummary SET Label = CASE
												    WHEN Name ='TaxReceivableGLPosted_Difference'
													THEN '1_Lessor Owned : Sales Tax Receivable GL Posted_Difference'
												    WHEN Name ='CashPaidSalesTaxReceivable_Difference'
													THEN '3_Lessor Owned : Sales Tax Receivable Total Cash_Difference'
												    WHEN Name ='NonCashPaidSalesTaxReceivable_Difference'
													THEN '3_Lessor Owned : Sales Tax Receivable Total Non Cash_Difference'
												    WHEN Name ='SalesTaxOSAR_Difference'
													THEN '4_Lessor Owned : Sales Tax Receivable OSAR_Difference'
												    WHEN Name ='SalesTaxPrepaid_Difference'
													THEN '5_Lessor Owned : Sales Tax Receivable Prepaid _Difference'
												    WHEN Name ='SalesTaxReceivableBalance_Difference'
													THEN '6_Lessor Owned: Sales Tax Receivable - Total Amount Vs Total Paid & Total Non Cash_Difference'
												    WHEN Name ='FunderOwned_LessorRemitting_SalesTax_GLPosted_ReceivableAmount_Difference'
													THEN '7_Funder Owned: Lessor Remitting Sales Tax Receivable - GL Posted_Difference'
												    WHEN Name ='FunderOwned_LessorRemitting_CashPaidSalesTaxReceivable_Difference'
													THEN '8_Funder Owned: Lessor Remitting Sales Tax Receivable - Total Paid_Difference'
												    WHEN Name ='FunderOwned_LessorRemitting_NonCashPaidSalesTaxReceivable_Difference'
													THEN '9_Funder Owned: Lessor Remitting Sales Tax Receivable - Total Non-Cash_Difference'
													WHEN Name ='FunderOwned_LessorRemitting_SalesTaxOSAR_Difference'
													THEN '10_Funder Owned: Lessor Remitting Sales Tax Receivable - OSAR_Difference'
												    WHEN Name ='FunderOwned_LessorRemitting_SalesTaxPrepaid_Difference'
													THEN '11_Funder Owned: Lessor Remitting Sales Tax Receivable - Prepaid_Difference'
												    WHEN Name ='FunderOwned_LessorRemitting_Balance_Difference'
													THEN '12_Funder Owned: Lessor Remitting Sales Tax Receivable - Total Amount vs Total Paid & Total Non Cash_Difference'
												END

	SELECT Label AS Name, Count
	FROM #SalesTaxReceivableSummary

	IF (@ResultOption = 'All')
	BEGIN
    SELECT *
    FROM #ResultList
	ORDER BY EntityType, EntityId;
	END

	IF (@ResultOption = 'Failed')
	BEGIN
	SELECT *
	FROM #ResultList
	WHERE Result = 'Problem Record'
	ORDER BY EntityType, EntityId;
	END

	IF (@ResultOption = 'Passed')
	BEGIN
	SELECT *
	FROM #ResultList
	WHERE Result = 'Not Problem Record'
	ORDER BY EntityType, EntityId;
	END

	DECLARE @TotalCount BIGINT;
	SELECT @TotalCount = ISNULL(COUNT(*), 0) FROM #ResultList
	DECLARE @InCorrectCount BIGINT;
	SELECT @InCorrectCount = ISNULL(COUNT(*), 0) FROM #ResultList WHERE Result  = 'Problem Record' 
	DECLARE @Messages StoredProcMessage
		
	INSERT INTO @Messages(Name, ParameterValuesCsv) VALUES('TotalReceivables', (Select 'Receivables=' + CONVERT(nvarchar(40), @TotalCount)))
	INSERT INTO @Messages(Name, ParameterValuesCsv) VALUES('ReceivableSuccessful', (Select 'ReceivableSuccessful=' + CONVERT(nvarchar(40), (@TotalCount - @InCorrectCount))))
	INSERT INTO @Messages(Name, ParameterValuesCsv) VALUES('ReceivableIncorrect', (Select 'ReceivableIncorrect=' + CONVERT(nvarchar(40), @InCorrectCount)))

	INSERT INTO @Messages(Name, ParameterValuesCsv) VALUES('ReceivableResultOption', (Select 'ResultOption=' + CONVERT(nvarchar(40), @ResultOption)))

	SELECT * FROM @Messages

DROP TABLE #ChargeOff
DROP TABLE #RecievableEntryItems
DROP TABLE #ExpectedEntryItemDetails
DROP TABLE #Syndications
DROP TABLE #ReceivableGLPostingInfo
DROP TABLE #SyndicationFunderRemitting
DROP TABLE #DistinctContracts
DROP TABLE #RecievableTaxDetails
DROP TABLE #ReceiptDetails
DROP TABLE #GLTrialBalance
DROP TABLE #SalesTaxGLPostedAmount
DROP TABLE #ReceiptGLPosting
DROP TABLE #ResultList
DROP TABLE #NonCashSalesTax;
DROP TABLE #SalesTaxReceivableSummary;

	SET NOCOUNT OFF
	SET ANSI_WARNINGS ON 
END

GO
