SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SPHC_FunderReceivable_Reconciliation]
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

IF OBJECT_ID('tempdb..#ReceivableGLPostingInfo') IS NOT NULL 
BEGIN
DROP TABLE #ReceivableGLPostingInfo
END
IF OBJECT_ID('tempdb..#ExpectedEntryItemDetails') IS NOT NULL 
BEGIN
DROP TABLE #ExpectedEntryItemDetails
END
IF OBJECT_ID('tempdb..#ChargeOff') IS NOT NULL 
BEGIN
DROP TABLE #ChargeOff
END
IF OBJECT_ID('tempdb..#Syndications') IS NOT NULL 
BEGIN
DROP TABLE #Syndications
END
IF OBJECT_ID('tempdb..#DistinctContracts') IS NOT NULL 
BEGIN
DROP TABLE #DistinctContracts
END
IF OBJECT_ID('tempdb..#RecievableEntryItems') IS NOT NULL 
BEGIN
DROP TABLE #RecievableEntryItems
END
IF OBJECT_ID('tempdb..#RecievableTaxDetails') IS NOT NULL 
BEGIN
DROP TABLE #RecievableTaxDetails
END
IF OBJECT_ID('tempdb..#FunderReceivableAmount') IS NOT NULL 
BEGIN
DROP TABLE #FunderReceivableAmount
END
IF OBJECT_ID('tempdb..#SyndicationFunderRemitting') IS NOT NULL 
BEGIN
DROP TABLE #SyndicationFunderRemitting
END
IF OBJECT_ID('tempdb..#GLTrialBalance') IS NOT NULL 
BEGIN
DROP TABLE #GLTrialBalance
END
IF OBJECT_ID('tempdb..#FunderReceivableGLPostedAmount') IS NOT NULL 
BEGIN
DROP TABLE #FunderReceivableGLPostedAmount
END
IF OBJECT_ID('tempdb..#ReceiptDetails') IS NOT NULL 
BEGIN
DROP TABLE #ReceiptDetails
END
IF OBJECT_ID('tempdb..#ReceiptGLPosting') IS NOT NULL 
BEGIN
DROP TABLE #ReceiptGLPosting
END
IF OBJECT_ID('tempdb..#ResultList') IS NOT NULL 
BEGIN
DROP TABLE #ResultList
END
IF OBJECT_ID('tempdb..#FunderReceivableSummary') IS NOT NULL 
BEGIN
DROP TABLE #FunderReceivableSummary
END
IF OBJECT_ID('tempdb..#NonCashSalesTax') IS NOT NULL 
BEGIN
DROP TABLE #NonCashSalesTax
END


DECLARE @Migration nvarchar(50); 
DECLARE @True BIT= 1;
DECLARE @False BIT= 0;
DECLARE @LegalEntitiesCount BIGINT= ISNULL((SELECT COUNT(*) FROM @LegalEntityIds), 0);
DECLARE @ContractsCount BIGINT= ISNULL((SELECT COUNT(*) FROM @ContractIds), 0);
DECLARE @CustomersCount BIGINT= ISNULL((SELECT COUNT(*) FROM @CustomerIds), 0);
DECLARE @DiscountingsCount BIGINT= ISNULL((SELECT COUNT(*) FROM @DiscountingIds), 0);
SELECT @Migration = Value FROM GlobalParameters WHERE Category ='Migration' AND Name = 'ConversionSource'

CREATE TABLE #FunderReceivableAmount
(EntityId           BIGINT, 
 EntityType         NVARCHAR(20), 
 GLTemplateId       BIGINT, 
 LegalEntityId	    BIGINT,
 TotalAmount        DECIMAL(16, 2), 
 GLPosted           DECIMAL(16, 2), 
 OSAR               DECIMAL(16, 2), 
 Prepaid            DECIMAL(16, 2), 
 BalanceAmount      DECIMAL(16, 2), 
 BookBalanceAmount  DECIMAL(16, 2)
);

CREATE TABLE #NonCashSalesTax
(FunderPortionNonCash DECIMAL(16, 2), 
 EntityId             BIGINT, 
 GLContractType       NVARCHAR(15), 
 GLTemplateId         BIGINT,
 LegalEntityId		  BIGINT
);


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

CREATE NONCLUSTERED INDEX IX_Id ON #ExpectedEntryItemDetails(GLTransactionType);

CREATE NONCLUSTERED INDEX IX_EntryItemName ON #ExpectedEntryItemDetails(EntryItemName);


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

SELECT DISTINCT R.Id AS ReceivableId
     , R.EntityId
     , R.EntityType
	 , R.IsCollected
     , R.IsGLPosted
     , R.DueDate
     , RT.Name AS ReceivableType
	 , RC.AccountingTreatment
     , GTT.Name AS GLTransactionType
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
		  WHEN BI.Id IS NOT NULL
		  THEN BI.StartDate
          ELSE R.DueDate
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
	 END AS [IsMigrated?]
   , CASE
		 WHEN lf.Id IS NOT NULL
		 THEN lf.IsAdvance
		 WHEN lfd.Id IS NOT NULL
		 THEN lfd.IsAdvance
		 ELSE CAST (0 AS BIT)
	  END AS IsAdvance
   , OriginalGTT.Name OriginalGLTransactionType
   , BI.IsFAS91
   , S.InvoiceComment	
   , CASE WHEN OriginalGTT.Name IN ('AssetSaleAR', 'PropertyTaxAR' , 'PropertyTaxEscrow', 'SecurityDeposit', 'NonRentalAR')
		  THEN R.TotalBalance_Amount
		  WHEN IsFAS91 = 0
		  THEN r.TotalBalance_Amount
		  WHEN s.InvoiceComment IN ('Syndication Actual Proceeds','Syndication Scrape Receivable')
		  THEN r.TotalBalance_Amount
		  ELSE 0.00
	 END ChargeoffBalance
   , R.TotalBookBalance_Amount AS BookBalanceAmount
INTO #ReceivableGLPostingInfo
FROM Receivables R
     JOIN ReceivableCodes RC ON R.ReceivableCodeId = RC.Id
     JOIN ReceivableTypes RT ON RC.ReceivableTypeId = RT.Id
     JOIN GLTemplates GT ON RC.SyndicationGLTemplateId = GT.Id
     JOIN GLTransactionTypes GTT ON GT.GLTransactionTypeId = GTT.Id
	 JOIN GLTemplates OriginalGT ON RC.GLTemplateId = OriginalGT.Id
     JOIN GLTransactionTypes OriginalGTT ON OriginalGT.GLTransactionTypeId = OriginalGTT.Id
     JOIN Parties P ON R.CustomerId = P.Id
     LEFT JOIN Contracts C ON R.EntityId = C.Id
                              AND R.EntityType = 'CT'
	 LEFT JOIN Sundries S ON R.SourceId = S.Id AND R.SourceTable = 'Sundry'
     LEFT JOIN BlendedItemDetails BID ON S.Id = BID.SundryId AND S.Id IS NOT NULL
     LEFT JOIN BlendedItems BI ON BID.BlendedItemId = BI.Id AND BID.Id IS NOT NULL
	 LEFT JOIN LoanFinances lf ON lf.ContractId = C.Id AND C.ContractType IN ('Loan', 'ProgressLoan') AND lf.IsCurrent = 1
	 LEFT JOIN LeaseFinances lease ON lease.ContractId = C.Id AND C.ContractType NOT IN ('Loan', 'ProgressLoan') AND lease.IsCurrent = 1
	 LEFT JOIN LeaseFinanceDetails lfd ON lfd.Id = lease.Id
     LEFT JOIN LeasePaymentSchedules LEPS ON R.PaymentScheduleId = LEPS.Id
                                             AND C.ContractType = 'Lease'  AND R.SourceTable NOT IN ('CPUSchedule', 'SundryRecurring')
     LEFT JOIN LoanPaymentSchedules LOPS ON R.PaymentScheduleId = LOPS.Id
                                            AND C.ContractType = 'Loan'  AND R.SourceTable NOT IN ('CPUSchedule', 'SundryRecurring')
	 LEFT JOIN TiedContractPaymentDetails payment ON payment.PaymentScheduleId = R.PaymentScheduleId
												     AND payment.ContractId = R.EntityId AND R.SourceTable NOT IN ('CPUSchedule', 'SundryRecurring')
													 AND R.EntityType = 'CT' AND Payment.IsActive = 1
WHERE R.IsActive = 1
      AND R.IsDummy = 0
	  AND R.FunderId IS NOT NULL
	  AND (R.IsCollected = 1 OR payment.Id IS NOT NULL)
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
	 , R.[IsMigrated?]
	 , R.ChargeOffStatus
	 , R.GLTransactionType
INTO #DistinctContracts
FROM #ReceivableGLPostingInfo R;

CREATE NONCLUSTERED INDEX IX_Id ON #DistinctContracts(EntityId, GLContractType, GLTemplateId);

UPDATE dc SET ContractType = lfd.LeaseContractType
FROM #DistinctContracts dc
INNER JOIN LeaseFinances lf ON dc.EntityId = lf.ContractId
INNER JOIN LeaseFinanceDetails lfd ON lfd.Id = lf.Id
WHERE dc.GLContractType = 'Contract'

UPDATE dc SET SequenceNumber = ds.SequenceNumber, ContractType = 'Discounting',
ContractAlias = ds.Alias
FROM #DistinctContracts dc
INNER JOIN Discountings ds ON dc.EntityId = ds.Id AND dc.GLContractType = 'Discounting'


DECLARE @IsSku BIT = 0
DECLARE @FilterCondition nvarchar(max) = ''
DECLARE @Sql nvarchar(max) ='';

SELECT ContractId, rft.Id AS SyndicationId
INTO #SyndicationFunderRemitting
FROM #Syndications syndication
INNER JOIN ReceivableForTransfers rft ON rft.ContractId = syndication.Id
WHERE rft.ApprovalStatus = 'Approved'
AND rft.Id IN (SELECT ReceivableForTransferId FROM ReceivableForTransferFundingSources WHERE SalesTaxResponsibility ='RemitOnly');

CREATE NONCLUSTERED INDEX IX_Id ON #SyndicationFunderRemitting(ContractId)


SELECT r.EntityId
     , r.GLContractType
     , r.GLTemplateId
	 , CASE WHEN r.GLContractType ='Customer' THEN r.LegalEntityId ELSE NULL END AS LegalEntityId
     , SUM(rt.Amount_Amount) AS FunderRemittingSalesTax
     , SUM(CASE
               WHEN rt.IsGLPosted = 1
               THEN rt.Amount_Amount
               ELSE 0.00
           END) AS FunderRemittingSalesTaxGLPosted
     , SUM(CASE
               WHEN rt.IsGLPosted = 1
               THEN rt.Balance_Amount
               ELSE 0.00
           END) AS FunderRemittingSalesTaxOSAR
     , SUM(CASE
               WHEN rt.IsGLPosted = 0
               THEN rt.Amount_Amount - rt.Balance_Amount
               ELSE 0.00
           END) AS FunderRemittingSalesTaxPrepaid
     , SUM(CASE
               WHEN rt.IsGLPosted = 0
               THEN rt.Balance_Amount
               ELSE 0.00
           END) AS FunderRemittingSalesTaxBalance
INTO #RecievableTaxDetails
FROM #ReceivableGLPostingInfo r
     INNER JOIN ReceivableTaxes rt ON r.ReceivableId = rt.ReceivableId
     INNER JOIN #SyndicationFunderRemitting funder ON funder.ContractId = r.EntityId
                                                     AND r.GLContractType = 'Contract'
WHERE rt.IsActive = 1
GROUP BY r.EntityId
       , r.GLContractType
       , r.GLTemplateId
	   , CASE WHEN r.GLContractType ='Customer' THEN r.LegalEntityId ELSE NULL END;	  

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'ReceivableTaxes' AND COLUMN_NAME = 'IsCashBased')
BEGIN
SET @Sql = '
SELECT  SUM(rard.TaxApplied_Amount) AS FunderPortionNonCash
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
INNER JOIN #SyndicationFunderRemitting funder ON funder.ContractId = temp.EntityId
                                                     AND temp.GLContractType = ''Contract''
WHERE rt.IsActive = 1
		AND rt.IsCashBased = 1
		AND rt.IsDummy = 0
		AND temp.FunderId IS NOT NULL
		AND temp.IsCollected = 1
		AND receipt.ReceiptClassification = ''NonCash''
		AND receipt.Status IN (''Completed'', ''Posted'')
		AND rard.IsActive = 1
GROUP BY temp.EntityId
       , temp.GLContractType
       , temp.GLTemplateId
	   , CASE WHEN temp.EntityType =''CU'' THEN temp.LegalEntityId ELSE NULL END'


INSERT INTO #NonCashSalesTax(FunderPortionNonCash, EntityId, GLContractType, GLTemplateId, LegalEntityId)
EXEC (@Sql)

END

CREATE NONCLUSTERED INDEX IX_Id ON #RecievableTaxDetails(EntityId, GLContractType, GLTemplateId)
	
IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'Assets' AND COLUMN_NAME = 'IsSku')
BEGIN
SET @IsSku = 1
END

IF @IsSku = 0
BEGIN
INSERT INTO #FunderReceivableAmount
SELECT r.EntityId,
	   r.GLContractType ,
	   r.GLTemplateId,
	   CASE WHEN r.GLContractType ='Customer' THEN r.LegalEntityId ELSE NULL END AS LegalEntityId,
	   SUM(r.TotalAmount_Amount) AS TotalAmount,
	   SUM(CASE WHEN r.IsGLPosted = 1
				THEN r.TotalAmount_Amount
			    ELSE 0.00 
			END) AS GLPosted,
	   SUM(CASE WHEN r.IsGLPosted = 1 AND r.ReceivableType IN ('LoanPrincipal', 'LoanInterest')
					 AND r.IsNonAccrual = 1
				THEN r.BookBalanceAmount
				WHEN r.IsGLPosted = 1
				THEN r.TotalBalance_Amount
			    ELSE 0.00 
			END) AS OSAR,
	   SUM(CASE WHEN r.IsGLPosted = 0 AND r.ReceivableType IN ('LoanPrincipal', 'LoanInterest')
					 AND r.IsNonAccrual = 1
				THEN r.TotalAmount_Amount - r.BookBalanceAmount
				WHEN r.IsGLPosted = 0
				THEN r.TotalAmount_Amount - r.TotalBalance_Amount
				ELSE 0.00 
			END) AS Prepaid,
	   SUM(r.TotalBalance_Amount) AS BalanceAmount,
	   SUM(CASE 
			   WHEN r.IsNonAccrual = 1 AND r.ReceivableType IN ('LoanPrincipal', 'LoanInterest') 
			   THEN r.BookBalanceAmount
			   ELSE 0.00
		   END) AS BookBalanceAmount
FROM #ReceivableGLPostingInfo r
LEFT JOIN #ChargeOff co ON co.Id = r.EntityId AND r.EntityType ='CT'
WHERE r.FunderId IS NOT NULL
GROUP BY EntityId,
		 r.GLContractType, 
		 r.GLTemplateId,
		 CASE WHEN r.GLContractType ='Customer' THEN r.LegalEntityId ELSE NULL END
END

IF @IsSku = 1
BEGIN
SET @SQL =
'SELECT r.EntityId,
	   r.GLContractType ,
	   r.GLTemplateId,
	   CASE WHEN r.GLContractType = ''Customer'' THEN r.LegalEntityId ELSE NULL END AS LegalEntityId,
	   SUM(r.TotalAmount_Amount) AS TotalAmount,
	   SUM(CASE WHEN r.IsGLPosted = 1
				THEN r.TotalAmount_Amount 
			    ELSE 0.00 
			END) AS GLPosted,
	   SUM(CASE WHEN r.IsGLPosted = 1 AND r.ReceivableType IN (''LoanPrincipal'', ''LoanInterest'')
					 AND r.IsNonAccrual = 1
				THEN r.BookBalanceAmount
				WHEN r.IsGLPosted = 1
				THEN r.TotalBalance_Amount
			    ELSE 0.00 
			END) AS OSAR,
	   SUM(CASE WHEN r.IsGLPosted = 0 AND r.ReceivableType IN (''LoanPrincipal'', ''LoanInterest'')
					 AND r.IsNonAccrual = 1
				THEN r.TotalAmount_Amount - r.BookBalanceAmount
				WHEN r.IsGLPosted = 0
				THEN r.TotalAmount_Amount - r.TotalBalance_Amount
				ELSE 0.00 
			END) AS Prepaid,
	   SUM(r.TotalBalance_Amount) AS BalanceAmount,
	   SUM(CASE 
			   WHEN r.IsNonAccrual = 1 AND r.ReceivableType IN (''LoanPrincipal'', ''LoanInterest'') 
			   THEN r.BookBalanceAmount
			   ELSE 0.00
		   END) AS BookBalanceAmount
FROM #ReceivableGLPostingInfo r
LEFT JOIN #ChargeOff co ON co.Id = r.EntityId AND r.EntityType =''CT''
WHERE r.FunderId IS NOT NULL
GROUP BY EntityId,
		 r.GLContractType, 
		 r.GLTemplateId,
		 CASE WHEN r.GLContractType = ''Customer'' THEN r.LegalEntityId ELSE NULL END'

INSERT INTO #FunderReceivableAmount
EXEC (@Sql)  
END

CREATE NONCLUSTERED INDEX IX_Id ON #FunderReceivableAmount(EntityId, EntityType,  GLTemplateId);

SELECT  r.EntityId
       , r.GLContractType
       , r.GLTemplateId
	   , CASE WHEN r.GLContractType ='Customer' THEN r.LegalEntityId ELSE NULL END AS LegalEntityId
	   , SUM(CASE
				  WHEN ReceiptClassification IN('Cash', 'NonAccrualNonDSL', 'DSL') AND rt.ReceiptTypeName NOT IN ('PayableOffset', 'SecurityDeposit',  'EscrowRefund')
				  	   AND r.IsNonAccrual = 1 AND r.ReceivableType IN ('LoanPrincipal', 'LoanInterest')
				  	   AND rard.RecoveryAmount_Amount = 0.00 AND rard.GainAmount_Amount = 0.00
				  THEN rard.BookAmountApplied_Amount
				  WHEN ReceiptClassification IN('Cash', 'NonAccrualNonDSL', 'DSL') AND rt.ReceiptTypeName NOT IN ('PayableOffset', 'SecurityDeposit',  'EscrowRefund')
					    AND rard.GainAmount_Amount = 0.00 AND rard.RecoveryAmount_Amount = 0.00
				  THEN rard.AmountApplied_Amount
				  ELSE 0.00 
			 END) AS CashPosted
	   , SUM(CASE
				 WHEN (ReceiptClassification NOT IN('Cash', 'NonAccrualNonDSL', 'DSL') OR rt.ReceiptTypeName IN ('PayableOffset', 'SecurityDeposit',  'EscrowRefund'))
				 	  AND r.IsNonAccrual = 1 AND r.ReceivableType IN ('LoanPrincipal', 'LoanInterest')
				 	  AND rard.RecoveryAmount_Amount = 0.00 AND rard.GainAmount_Amount = 0.00
				 THEN rard.BookAmountApplied_Amount
				 WHEN (ReceiptClassification NOT IN('Cash', 'NonAccrualNonDSL', 'DSL') OR rt.ReceiptTypeName IN ('PayableOffset', 'SecurityDeposit',  'EscrowRefund'))
					  AND rard.GainAmount_Amount = 0.00 AND rard.RecoveryAmount_Amount = 0.00
				 THEN rard.AmountApplied_Amount
				 ELSE 0.00 
			 END) AS NonCashPosted
		, SUM(CASE
			WHEN rard.RecoveryAmount_Amount != 0.00
				 AND (r.OriginalGLTransactionType NOT IN ('AssetSaleAR', 'PropertyTaxAR' , 'PropertyTaxEscrow', 'SecurityDeposit') OR (r.IsFas91 IS NOT NULL AND r.IsFas91 = 0)
					OR (r.ReceivableType = 'Sundry' AND r.InvoiceComment NOT IN ('Syndication Actual Proceeds','Syndication Scrape Receivable')))
			THEN rard.RecoveryAmount_Amount
			ELSE 0.00
		END) AS RecoveryAmount
		, SUM(CASE
			WHEN  rard.GainAmount_Amount != 0.00
				 AND (r.OriginalGLTransactionType NOT IN ('AssetSaleAR', 'PropertyTaxAR' , 'PropertyTaxEscrow', 'SecurityDeposit') OR (r.IsFas91 IS NOT NULL AND r.IsFas91 = 0)
					OR (r.ReceivableType = 'Sundry' AND r.InvoiceComment NOT IN ('Syndication Actual Proceeds','Syndication Scrape Receivable')))
			THEN rard.GainAmount_Amount
			ELSE 0.00
		END) AS GainAmount
		, SUM(CASE
				  WHEN ReceiptClassification IN('Cash', 'NonAccrualNonDSL', 'DSL') AND rt.ReceiptTypeName NOT IN ('PayableOffset', 'SecurityDeposit',  'EscrowRefund')
					   AND funder.ContractId IS NOT NULL
					    AND rard.RecoveryAmount_Amount = 0.00 AND rard.GainAmount_Amount = 0.00
				  THEN rard.TaxApplied_Amount
			  END) AS CashTaxAmountApplied
	   , SUM(CASE
				 WHEN (ReceiptClassification NOT IN('Cash', 'NonAccrualNonDSL', 'DSL') OR rt.ReceiptTypeName IN ('PayableOffset', 'SecurityDeposit',  'EscrowRefund'))
				 	  AND rard.RecoveryAmount_Amount = 0.00 AND rard.GainAmount_Amount = 0.00
					  AND funder.ContractId IS NOT NULL
				 THEN rard.TaxApplied_Amount
				 ELSE 0.00 
			 END) AS NonCashTaxAmountApplied
		, SUM(CASE
				  WHEN co.Id IS NOT NULL
					   AND r.ReceivableType IN ('LoanPrincipal', 'LoanInterest')
						AND rard.RecoveryAmount_Amount = 0.00 AND rard.GainAmount_Amount = 0.00
				  THEN rard.BookAmountApplied_Amount
				  ELSE 0.00
			   END) AS LoanBookAmountApplied
			, SUM(CASE
					  WHEN r.accountingTreatment IN('CashBased', 'MemoBased')
						   AND (ReceiptClassification NOT IN('Cash', 'NonAccrualNonDSL', 'DSL') AND rt.ReceiptTypeName NOT IN ('PayableOffset', 'SecurityDeposit', 'EscrowRefund'))
						   AND rard.GainAmount_Amount = 0.00 AND rard.RecoveryAmount_Amount = 0.00 AND ((co.Id IS NOT NULL AND (r.GLTransactionType IN ('AssetSaleAR', 'PropertyTaxAR' , 'PropertyTaxEscrow', 'SecurityDeposit') OR r.IsFAS91 = 0 OR r.InvoiceComment IN ('Syndication Actual Proceeds','Syndication Scrape Receivable'))))
					  THEN rard.AmountApplied_Amount
				      ELSE 0.00
					END) AS LeaseComponentNonCashAmount
INTO #ReceiptDetails
FROM #ReceivableGLPostingInfo r
     JOIN ReceivableDetails rd ON rd.ReceivableId = r.ReceivableId
     JOIN ReceiptApplicationReceivableDetails rard ON rard.ReceivableDetailId = rd.Id
     JOIN ReceiptApplications ra ON ra.Id = rard.ReceiptApplicationId
     JOIN Receipts Receipt ON ra.ReceiptId = Receipt.Id
	 JOIN ReceiptTypes rt ON rt.Id = receipt.TypeId
	 LEFT JOIN #ChargeOff co ON r.EntityId = co.Id AND r.EntityType = 'CT'
     LEFT JOIN #SyndicationFunderRemitting funder ON funder.ContractId = r.EntityId
                                                     AND r.GLContractType = 'Contract'
WHERE Receipt.Status IN('Posted', 'Completed')
     AND rd.IsActive = 1
     AND rard.IsActive = 1
	 AND rt.IsActive = 1
	 AND r.FunderId IS NOT NULL
GROUP BY r.EntityId
       , r.GLContractType
       , r.GLTemplateId
	   , CASE WHEN r.GLContractType ='Customer' THEN r.LegalEntityId ELSE NULL END;

CREATE NONCLUSTERED INDEX IX_Id ON #ReceiptDetails(EntityId, GLContractType, GLTemplateId, LegalEntityId)
 
UPDATE #ReceiptDetails SET RecoveryAmount += LoanBookAmountApplied
WHERE LoanBookAmountApplied != 0.00

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
			   , LegalEntityId
               , EntryItemId
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
     , SUM(gld.DebitAmount - gld.CreditAmount) AS GLPosted
     , SUM(CASE
               WHEN eetd.IsPrepaidApplicable = 0
					AND gld.MatchingEntryName IS NULL
               THEN gld.DebitAmount
               ELSE 0.00
           END) -
		SUM(CASE
               WHEN eetd.IsPrepaidApplicable = 0
					AND gld.MatchingEntryName IS NULL
               THEN gld.CreditAmount 
               ELSE 0.00
           END) AS OSAR
		, SUM(CASE
               WHEN eetd.IsPrepaidApplicable = 1
               THEN gld.DebitAmount
               ELSE 0.00
           END) -
		SUM(CASE
               WHEN eetd.IsPrepaidApplicable = 1
               THEN gld.CreditAmount
               ELSE 0.00
           END)AS Prepaid
INTO #FunderReceivableGLPostedAmount
FROM #GLTrialBalance gld
     INNER JOIN GLEntryItems glei ON gld.EntryItemId = glei.Id
                                     AND glei.IsActive = 1
     INNER JOIN GLTransactionTypes gltt ON GLEI.GLTransactionTypeId = GLTT.Id
										   AND gltt.IsActive = 1
     INNER JOIN #ExpectedEntryItemDetails eetd ON eetd.GLTransactionType = gltt.Name 
												  AND glei.Name = eetd.EntryItemName  
WHERE eetd.IsDebit = 1
AND eetd.IsBlendedItem = 0
AND gltt.Name = 'SyndicatedAR'
AND eetd.IsVendorOwned = 0
GROUP BY gld.EntityId
       , gld.EntityType
       , gld.GLTemplateId
	   , CASE WHEN gld.EntityType ='Customer' THEN gld.LegalEntityId ELSE NULL END;

CREATE NONCLUSTERED INDEX IX_Id ON #FunderReceivableGLPostedAmount(EntityId, EntityType, GLTemplateId)

SELECT gld.EntityId
     , gld.EntityType
     , gld.MatchingGLTemplateId
	 , CASE WHEN gld.EntityType ='Customer' THEN gld.LegalEntityId ELSE NULL END AS LegalEntityId
     , SUM(CASE 
			  WHEN eetd.IsPrepaidApplicable = 0
			  THEN gld.CreditAmount
			  ELSE 0.00
		   END) - 
      SUM(CASE 
			  WHEN eetd.IsPrepaidApplicable = 0
			  THEN gld.DebitAmount 
			  ELSE 0.00
		   END) AS OSARAmount
     , SUM(CASE
               WHEN eetd.IsPrepaidApplicable = 1
               THEN gld.CreditAmount
               ELSE 0.00
           END) - 
	   SUM(CASE
                WHEN eetd.IsPrepaidApplicable = 1
                THEN gld.DebitAmount
                ELSE 0.00
            END) Prepaid
     , SUM(CASE
               WHEN types.Name ='ReceiptCash'
               THEN gld.CreditAmount
               ELSE 0.00
           END) - 
	   SUM(CASE
                WHEN types.Name ='ReceiptCash'
                THEN gld.DebitAmount
                ELSE 0.00
            END) CashPosted
     , SUM(CASE
               WHEN types.Name ='ReceiptNonCash'
               THEN gld.CreditAmount
               ELSE 0.00
           END) - 
	   SUM(CASE
                WHEN types.Name ='ReceiptNonCash'
                THEN gld.DebitAmount
                ELSE 0.00
            END) NonCashPosted
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
WHERE gltt.Name IN ('SyndicatedAR', 'SalesTax')
      AND gl.Name IN ('OTPReceivable','Receivable')
      AND MatchingEntryName IN ('DueToThirdPartyAR', 'PrePaidDueToThirdPartyAR')
	  AND eetd.IsBlendedItem = 0
	  AND eetd.IsVendorOwned = 0
GROUP BY gld.EntityId
       , gld.EntityType
       , gld.MatchingGLTemplateId
	   , CASE WHEN gld.EntityType ='Customer' THEN gld.LegalEntityId ELSE NULL END;

CREATE NONCLUSTERED INDEX IX_Id ON #ReceiptGLPosting(EntityId, EntityType, MatchingGLTemplateId)

MERGE #FunderReceivableGLPostedAmount AS receivable
USING (SELECT * FROM #ReceiptGLPosting) AS receipt
ON(receivable.GLTemplateId = receipt.MatchingGLTemplateId
	AND receivable.EntityId = receipt.EntityId
	AND receivable.EntityType = receipt.EntityType)
WHEN MATCHED
	THEN UPDATE SET 
					  OSAR = ABS(receivable.OSAR) - receipt.OSARAmount
					, Prepaid = ABS(receipt.Prepaid) - receivable.Prepaid
WHEN NOT MATCHED
		THEN
		INSERT(EntityId, EntityType, GLTemplateId, GLPosted, OSAR, Prepaid)
		VALUES(receipt.EntityId, receipt.EntityType, receipt.MatchingGLTemplateId, 0.00, receipt.OSARAmount, receipt.Prepaid);

SELECT *
     , CASE
           WHEN [GLPosted_Difference] != 0.00
                OR [CashPaidReceivable_Difference] != 0.00
                OR [NonCashPaidReceivable_Difference] != 0.00
                OR [OSARReceivable_Difference] != 0.00
                OR Prepaid_Difference != 0.00
                OR [BalanceReceivable_Difference] != 0.00
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
		 , dc.[IsMigrated?] AS [IsMigrated]
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
		 , ABS(ISNULL(amount.TotalAmount, 0.00)) AS ReceivableAmount
		 , ABS(ISNULL(rtd.FunderRemittingSalesTax, 0.00)) AS FunderOwnedFunderRemittingSalesTax
		 , ABS(ABS(ISNULL(amount.GLPosted, 0.00)) - ABS(ISNULL(rd.LeaseComponentNonCashAmount, 0.00))) AS GLPostedReceivableAmount
		 , ABS(ABS(ISNULL(rtd.FunderRemittingSalesTaxGLPosted, 0.00)) - ABS(ISNULL(ncst.FunderPortionNonCash, 0.00))) AS SalesTaxGLPostedAmount
		 , ABS(ISNULL(gl.GLPosted, 0.00)) AS [GLAmount]
		 , ABS(ABS(ISNULL(amount.GLPosted, 0.00)) - ABS(ISNULL(rd.LeaseComponentNonCashAmount, 0.00))) + ABS(ABS(ISNULL(rtd.FunderRemittingSalesTaxGLPosted, 0.00)) - ABS(ISNULL(ncst.FunderPortionNonCash, 0.00))) - ABS(ISNULL(gl.GLPosted, 0.00)) as [GLPosted_Difference]
		 , ISNULL(rd.CashPosted ,0.00) AS PaidReceivableCash_Table
		 , ISNULL(rd.CashTaxAmountApplied, 0.00) AS FunderOwnedFunderRemittingSalesTaxPaidCash_Table
		 , ISNULL(rgl.CashPosted, 0.00) AS [CashPaidReceivable_GL]
		 , ISNULL(rd.CashPosted ,0.00) + ISNULL(rd.CashTaxAmountApplied, 0.00) - ISNULL(rgl.CashPosted, 0.00) [CashPaidReceivable_Difference]
		 , ABS(ISNULL(rd.NonCashPosted,0.00) - ABS(ISNULL(rd.LeaseComponentNonCashAmount, 0.00))) AS PaidReceivableNonCash_Table
		 , ABS(ISNULL(rd.NonCashTaxAmountApplied, 0.00) - ABS(ISNULL(rd.LeaseComponentNonCashAmount, 0.00))) AS FunderOwnedFunderRemittingSalesTaxPaidNonCash_Table
		 , ABS(ISNULL(rgl.NonCashPosted, 0.00)) AS [NonCashPaidReceivable_GL]
		 , ABS(ISNULL(rd.NonCashPosted,0.00) - ABS(ISNULL(rd.LeaseComponentNonCashAmount, 0.00))) + ABS(ISNULL(rd.NonCashTaxAmountApplied, 0.00) - ABS(ISNULL(rd.LeaseComponentNonCashAmount, 0.00))) - ABS(ISNULL(rgl.NonCashPosted, 0.00)) [NonCashPaidReceivable_Difference]
		 , ISNULL(amount.OSAR, 0.00) AS [OSARReceivable_Table]
		 , ISNULL(rtd.FunderRemittingSalesTaxOSAR, 0.00) AS FunderOwnedFunderRemittingSalesTaxPaid_OSAR_Table
		 , ISNULL(gl.OSAR, 0.00) AS [OSARReceivable_GL] 
		 , ABS(ISNULL(amount.OSAR, 0.00)) + ISNULL(rtd.FunderRemittingSalesTaxOSAR, 0.00) - ABS(ISNULL(gl.OSAR, 0.00)) AS [OSARReceivable_Difference]
		 , ISNULL(amount.Prepaid, 0.00) AS [PrepaidReceivable_Table]
		 , ISNULL(rtd.FunderRemittingSalesTaxPrepaid, 0.00) AS FunderOwnedFunderRemittingSalesTax_Prepaid_Table
		 , ABS(ISNULL(gl.Prepaid, 0.00)) AS [PrepaidReceivable_GL]
		 , ISNULL(amount.Prepaid, 0.00) + ISNULL(rtd.FunderRemittingSalesTaxPrepaid, 0.00) - ABS(ISNULL(gl.Prepaid, 0.00)) AS Prepaid_Difference
		 , ISNULL(rd.RecoveryAmount, 0.00) AS RecoveryAmount_Table
		 , ISNULL(rd.GainAmount, 0.00) AS [GainAmount_Table]
		 , IIF(ISNULL(amount.BookBalanceAmount, 0.00) != 0.00, ISNULL(amount.BookBalanceAmount, 0.00), ISNULL(amount.BalanceAmount, 0.00)) AS [BalanceReceivable_Table]
		 , ISNULL(rtd.FunderRemittingSalesTaxBalance, 0.00) AS FunderOwnedFunderRemittingSalesTax_Balance_Table
		 , ISNULL(amount.TotalAmount, 0.00) + ISNULL(rtd.FunderRemittingSalesTax, 0.00) - ISNULL(rd.CashPosted, 0.00) - ISNULL(rd.NonCashPosted, 0.00) - ISNULL(rd.GainAmount, 0.00) - ISNULL(rd.CashTaxAmountApplied, 0.00) - ISNULL(rd.NonCashTaxAmountApplied, 0.00) AS [BalanceReceivable_Calculation]
		 , ABS(IIF(ISNULL(amount.BookBalanceAmount, 0.00) != 0.00, ISNULL(amount.BookBalanceAmount, 0.00), ISNULL(amount.BalanceAmount, 0.00)) + ISNULL(rtd.FunderRemittingSalesTaxBalance, 0.00)) - ABS(ABS(ISNULL(amount.TotalAmount, 0.00) + ISNULL(rtd.FunderRemittingSalesTax, 0.00) - ISNULL(rd.CashPosted, 0.00) - ISNULL(rd.NonCashPosted, 0.00) - ISNULL(rd.GainAmount, 0.00) - ISNULL(rtd.FunderRemittingSalesTaxOSAR, 0.00) - ISNULL(rd.CashTaxAmountApplied, 0.00) - ISNULL(rd.NonCashTaxAmountApplied, 0.00))) [BalanceReceivable_Difference]
	FROM #DistinctContracts dc
		 LEFT JOIN #FunderReceivableAmount amount ON dc.EntityId = amount.EntityId
													 AND dc.GLContractType = amount.EntityType
													 AND dc.GLTemplateId = amount.GLTemplateId
													 AND (dc.GLContractType = 'Customer' AND dc.LegalEntityId = amount.LegalEntityId OR dc.GLContractType != 'Customer')
		 LEFT JOIN #RecievableTaxDetails rtd ON dc.EntityId = rtd.EntityId
												AND dc.GLContractType = rtd.GLContractType
												AND dc.GLTemplateId = rtd.GLTemplateId
												AND (dc.GLContractType = 'Customer' AND dc.LegalEntityId = rtd.LegalEntityId OR dc.GLContractType != 'Customer')
		 LEFT JOIN #FunderReceivableGLPostedAmount gl ON dc.EntityId = gl.EntityId
														 AND dc.GLContractType = gl.EntityType
														 AND dc.GLTemplateId = gl.GLTemplateId
														 AND (dc.GLContractType = 'Customer' AND dc.LegalEntityId = gl.LegalEntityId OR dc.GLContractType != 'Customer')
		 LEFT JOIN #ReceiptDetails rd ON dc.EntityId = rd.EntityId
										 AND dc.GLContractType = rd.GLContractType
										 AND dc.GLTemplateId = rd.GLTemplateId
										 AND (dc.GLContractType = 'Customer' AND dc.LegalEntityId = rd.LegalEntityId OR dc.GLContractType != 'Customer')
		 LEFT JOIN #ReceiptGLPosting rgl ON dc.EntityId = rgl.EntityId
										 AND dc.GLContractType = rgl.EntityType
										 AND dc.GLTemplateId = rgl.MatchingGLTemplateId
										 AND (dc.GLContractType = 'Customer' AND dc.LegalEntityId = rgl.LegalEntityId OR dc.GLContractType != 'Customer')
		LEFT JOIN #NonCashSalesTax ncst ON dc.EntityId = ncst.EntityId
										   AND dc.GLContractType = ncst.GLContractType
										   AND dc.GLTemplateId = ncst.GLTemplateId
										   AND (dc.GLContractType = 'Customer' AND dc.LegalEntityId = ncst.LegalEntityId OR dc.GLContractType != 'Customer')
		LEFT JOIN LegalEntities le ON le.Id = dc.LegalEntityId
		LEFT JOIN #ChargeOff co ON co.Id = dc.EntityId AND dc.GLContractType ='Contract'
		LEFT JOIN #Syndications sy ON sy.Id = dc.EntityId AND dc.GLContractType = 'Contract'
		LEFT JOIN GLTemplates gtt ON gtt.Id = amount.GLTemplateId) AS t;


CREATE NONCLUSTERED INDEX IX_Id ON #ResultList(EntityId, EntityType)


    SELECT name AS Name, 0 AS Count, CAST (0 AS BIT) AS IsProcessed, CAST('' AS NVARCHAR(max)) AS Label
	INTO #FunderReceivableSummary
	FROM tempdb.sys.columns
	WHERE object_id = OBJECT_ID('tempdb..#ResultList')
	AND Name LIKE '%Difference';

	DECLARE @query NVARCHAR(MAX);
	DECLARE @TableName NVARCHAR(max);
	WHILE EXISTS (SELECT 1 FROM #FunderReceivableSummary WHERE IsProcessed = 0)
	BEGIN
	SELECT TOP 1 @TableName = Name FROM #FunderReceivableSummary WHERE IsProcessed = 0

	SET @query = 'UPDATE #FunderReceivableSummary SET Count = (SELECT COUNT(*) FROM #ResultList WHERE ' + @TableName+ ' != 0.00), IsProcessed = 1
					WHERE Name = '''+ @TableName+''' ;'
	EXEC (@query)
	END


	UPDATE #FunderReceivableSummary SET Label = CASE
												    WHEN Name ='GLPosted_Difference'
													THEN '1_Funder Owned: Receivable & SalesTax GL Posted Amount_Difference'
												    WHEN Name ='CashPaidReceivable_Difference'
													THEN '2_Total Paid Receivables & Sales Tax Receivable_Difference'
												    WHEN Name ='NonCashPaidReceivable_Difference'
													THEN '3_Total Non Cash Receivables & Sales Tax Receivable_Difference'
												    WHEN Name ='OSARReceivable_Difference'
													THEN '4_Receivable & Sales Tax Receivable - OSAR_Difference'
												    WHEN Name ='Prepaid_Difference'
													THEN '5_Receivable & Sales Tax Receivable - Prepaid_Difference'
												    WHEN Name ='BalanceReceivable_Difference'
													THEN '6_Funder Owned: Funder Remitting: Balance Sales Tax Receivable_Difference'
												END

	SELECT Label AS Name, Count
	FROM #FunderReceivableSummary

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


DROP TABLE #ReceivableGLPostingInfo
DROP TABLE #ExpectedEntryItemDetails
DROP TABLE #ChargeOff
DROP TABLE #Syndications
DROP TABLE #DistinctContracts
DROP TABLE #RecievableEntryItems
DROP TABLE #RecievableTaxDetails
DROP TABLE #FunderReceivableAmount
DROP TABLE #SyndicationFunderRemitting
DROP TABLE #GLTrialBalance
DROP TABLE #FunderReceivableGLPostedAmount
DROP TABLE #ReceiptDetails
DROP TABLE #ReceiptGLPosting
DROP TABLE #ResultList
DROP TABLE #FunderReceivableSummary
DROP TABLE #NonCashSalesTax
	SET NOCOUNT OFF
	SET ANSI_WARNINGS ON 
END

GO
