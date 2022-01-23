SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SPHC_OwnedReceivable_Reconciliation]
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

IF OBJECT_ID('tempdb..#ReceivableAmount') IS NOT NULL 
BEGIN
DROP TABLE #ReceivableAmount
END

IF OBJECT_ID('tempdb..#ReceivableGLPostedAmount') IS NOT NULL 
BEGIN
DROP TABLE #ReceivableGLPostedAmount
END

IF OBJECT_ID('tempdb..#ExpectedEntryItemDetails') IS NOT NULL 
BEGIN
DROP TABLE #ExpectedEntryItemDetails
END
IF OBJECT_ID('tempdb..#GLTrialBalance') IS NOT NULL 
BEGIN
DROP TABLE #GLTrialBalance
END
IF OBJECT_ID('tempdb..#DistinctContracts') IS NOT NULL 
BEGIN
DROP TABLE #DistinctContracts
END
IF OBJECT_ID('tempdb..#RecievableEntryItems') IS NOT NULL 
BEGIN
DROP TABLE #RecievableEntryItems
END
IF OBJECT_ID('tempdb..#ReceiptGLPosting') IS NOT NULL 
BEGIN
DROP TABLE #ReceiptGLPosting
END
IF OBJECT_ID('tempdb..#ChargeOff') IS NOT NULL
BEGIN
DROP TABLE #ChargeOff;
END
IF OBJECT_ID('tempdb..#ResultList') IS NOT NULL
BEGIN
DROP TABLE #ResultList;
END
IF OBJECT_ID('tempdb..#ReceiptDetails') IS NOT NULL
BEGIN
DROP TABLE #ReceiptDetails;
END
IF OBJECT_ID('tempdb..#Syndications') IS NOT NULL
BEGIN
DROP TABLE #Syndications;
END
IF OBJECT_ID('tempdb..#NonAccrualLoanAmount') IS NOT NULL
BEGIN
DROP TABLE #NonAccrualLoanAmount;
END
IF OBJECT_ID('tempdb..#OwnedReceivableSummary') IS NOT NULL
BEGIN
DROP TABLE #OwnedReceivableSummary;
END
IF OBJECT_ID('tempdb..#ChargeoffExpenseReceiptIds') IS NOT NULL
BEGIN
DROP TABLE #ChargeoffExpenseReceiptIds;
END
IF OBJECT_ID('tempdb..#ChargeoffExpenseRecords') IS NOT NULL
BEGIN
DROP TABLE #ChargeoffExpenseRecords;
END
IF OBJECT_ID('tempdb..#ReceiptApplicationReceivableDetails') IS NOT NULL
BEGIN
DROP TABLE #ReceiptApplicationReceivableDetails;
END
IF OBJECT_ID('tempdb..#ChargeoffRecoveryReceiptIds') IS NOT NULL
BEGIN
DROP TABLE #ChargeoffRecoveryReceiptIds;
END
IF OBJECT_ID('tempdb..#ChargeoffRecoveryRecords') IS NOT NULL
BEGIN
DROP TABLE #ChargeoffRecoveryRecords;
END
IF OBJECT_ID('tempdb..#NonSKUChargeoffExpenseRecords') IS NOT NULL
BEGIN
DROP TABLE #NonSKUChargeoffExpenseRecords;
END
IF OBJECT_ID('tempdb..#NonSKUChargeoffRecoveryRecords') IS NOT NULL
BEGIN
DROP TABLE #NonSKUChargeoffRecoveryRecords;
END
IF OBJECT_ID('tempdb..#NonAccrualDetails') IS NOT NULL
BEGIN
DROP TABLE #NonAccrualDetails;
END


	CREATE TABLE #ReceivableAmount
	(EntityId                        BIGINT,
	 EntityType						 NVARCHAR(20), 
	 GLTemplateId					 BIGINT,
	 LegalEntityId				     BIGINT,
	 TotalAmount                     DECIMAL(16, 2),
	 LeaseComponentTotalAmount       DECIMAL(16, 2),
	 NonLeaseComponentTotalAmount    DECIMAL(16, 2),
	 GLPostedLeaseComponent          DECIMAL(16, 2), 
	 GLPostedFinanceComponent        DECIMAL(16, 2), 
	 GLPostedLeaseComponentOSAR      DECIMAL(16, 2), 
	 GLPostedFinanceComponentOSAR    DECIMAL(16, 2), 
	 GLPostedLeaseComponentPrepaid   DECIMAL(16, 2), 
	 GLPostedFinanceComponentPrepaid DECIMAL(16, 2),
	 BalanceAmount_LC				 DECIMAL(16, 2),
	 BalanceAmount_NLC				 DECIMAL(16, 2),
	 BookBalanceAmount               DECIMAL(16, 2)
	);

	CREATE TABLE #NonAccrualLoanAmount
	(EntityId      BIGINT, 
	 EntityType    NVARCHAR(20), 
	 GLTemplateId  BIGINT,
	 LegalEntityId BIGINT, 
	 OSARLease     DECIMAL(16, 2), 
	 OSARFinance   DECIMAL(16, 2),
	 Prepaid	   DECIMAL(16,2)
	);

	CREATE TABLE #ReceiptDetails
	(EntityId                          BIGINT, 
	 GLContractType                    NVARCHAR(20), 
	 GLTemplateId                      BIGINT, 
	 LegalEntityId                     BIGINT, 
	 LeaseComponentCashPosted          DECIMAL(16, 2), 
	 FinanceComponentCashPosted        DECIMAL(16, 2), 
	 LeaseComponentNonCashPosted       DECIMAL(16, 2), 
	 FinanceComponentNonCashPosted     DECIMAL(16, 2), 
	 LeaseCashApplicationRecovery      DECIMAL(16, 2), 
	 FinanceCashApplicationRecovery    DECIMAL(16, 2), 
	 RecoveryAmount_LC                 DECIMAL(16, 2),
	 RecoveryAmount_NLC                DECIMAL(16, 2),
	 GainAmount_LC					   DECIMAL(16, 2),
	 GainAmount_NLC					   DECIMAL(16, 2),
	 LeaseAmountApplied				   DECIMAL(16, 2),
	 FinanceAmountApplied			   DECIMAL(16, 2),
	 SundryAmount					   DECIMAL(16, 2),
	 BlendedItemAmount				   DECIMAL(16, 2),
	 LoanBookAmountApplied			   DECIMAL(16, 2),
	 LeaseComponentNonCashAmount	   DECIMAL(16, 2),
	 NonLeaseComponentNonCashAmount    DECIMAL(16, 2),
	 ChargeoffExpenseAmount            DECIMAL(16, 2),
	 ChargeoffExpenseLCAmount		   DECIMAL(16, 2),
	 ChargeoffExpenseNLCAmount		   DECIMAL(16, 2)
	);

	CREATE TABLE #ChargeoffExpenseReceiptIds
	(Id                             BIGINT, 
	 ReceiptId                      BIGINT, 
	 LeaseComponentAmount_Amount    DECIMAL(16, 2), 
	 NonLeaseComponentAmount_Amount DECIMAL(16, 2), 
	 LeaseComponentGain_Amount      DECIMAL(16, 2), 
	 NonLeaseComponentGain_Amount   DECIMAL(16, 2)
	);

	CREATE TABLE #ChargeoffRecoveryReceiptIds
	(Id                             BIGINT, 
	 ReceiptId                      BIGINT, 
	 LeaseComponentAmount_Amount    DECIMAL(16, 2), 
	 NonLeaseComponentAmount_Amount DECIMAL(16, 2), 
	 LeaseComponentGain_Amount      DECIMAL(16, 2), 
	 NonLeaseComponentGain_Amount   DECIMAL(16, 2)
	);

	CREATE TABLE #ReceiptApplicationReceivableDetails
	(EntityId                              BIGINT, 
	 GLContractType                        NVARCHAR(50), 
	 GLTemplateId                          BIGINT, 
	 EntityType                            NVARCHAR(25), 
	 LegalEntityId                         BIGINT, 
	 ReceiptClassification                 NVARCHAR(30),
	 ReceiptTypeName					   NVARCHAR(50), 
	 AssetComponentType                    NVARCHAR(10), 
	 IsNonAccrual                          BIT, 
	 ReceivableType                        NVARCHAR(50), 
	 StartDate                             DATE, 
	 BookAmountApplied_Amount              DECIMAL(16, 2), 
	 LeaseComponentAmountApplied_Amount    DECIMAL(16, 2), 
	 NonLeaseComponentAmountApplied_Amount DECIMAL(16, 2), 
	 GainAmount_Amount                     DECIMAL(16, 2), 
	 RecoveryAmount_Amount                 DECIMAL(16, 2), 
	 IsFAS91                               BIT NULL, 
	 RecoveryAmount_LC                     DECIMAL(16, 2), 
	 RecoveryAmount_NLC                    DECIMAL(16, 2), 
	 GainAmount_LC                         DECIMAL(16, 2), 
	 GainAmount_NLC                        DECIMAL(16, 2), 
	 ChargeoffExpenseAmount                DECIMAL(16, 2), 
	 ChargeoffExpenseAmount_LC             DECIMAL(16, 2), 
	 ChargeoffExpenseAmount_NLC            DECIMAL(16, 2), 
	 AmountApplied_Amount                  DECIMAL(16, 2), 
	 ReceiptId                             BIGINT, 
	 ReceiptStatus                         NVARCHAR(30), 
	 IsFas91ForExpense                     BIT NULL, 
	 IsGLPosted                            BIT, 
	 AccountingTreatment                   NVARCHAR(25), 
	 RardId                                BIGINT, 
	 GLTransactionType                     NVARCHAR(50), 
	 InvoiceComment                        NVARCHAR(200), 
	 DueDate                               DATE,
	 IsRecovery						       BIT NULL
	);

	CREATE TABLE #ChargeoffRecoveryRecords
	(EntityId                              BIGINT, 
	 GLContractType                        NVARCHAR(50), 
	 GLTemplateId                          BIGINT, 
	 ReceiptTypeName                       NVARCHAR(50), 
	 Id                                    BIGINT, 
	 LeaseComponentAmountApplied_Amount    DECIMAL(16, 2), 
	 NonLeaseComponentAmountApplied_Amount DECIMAL(16, 2), 
	 RecoveryAmount_Amount                 DECIMAL(16, 2), 
	 GainAmount_Amount                     DECIMAL(16, 2), 
	 StartDate                             DATE, 
	 RecoveryAmount_LC                     DECIMAL(16, 2), 
	 RecoveryAmount_NLC                    DECIMAL(16, 2), 
	 GainAmount_LC                         DECIMAL(16, 2), 
	 GainAmount_NLC                        DECIMAL(16, 2), 
	 AmountApplied                         DECIMAL(16, 2), 
	 RardId                                BIGINT
	);


	CREATE TABLE #ChargeoffExpenseRecords
	(EntityId                              BIGINT, 
	 GLContractType                        NVARCHAR(50), 
	 GLTemplateId                          BIGINT, 
	 ReceiptTypeName                       NVARCHAR(50), 
	 Id                                    BIGINT, 
	 LeaseComponentAmountApplied_Amount    DECIMAL(16, 2), 
	 NonLeaseComponentAmountApplied_Amount DECIMAL(16, 2), 
	 RecoveryAmount_Amount                 DECIMAL(16, 2), 
	 GainAmount_Amount                     DECIMAL(16, 2), 
	 StartDate                             DATE, 
	 RecoveryAmount_LC                     DECIMAL(16, 2) NULL, 
	 RecoveryAmount_NLC                    DECIMAL(16, 2) NULL, 
	 GainAmount_LC                         DECIMAL(16, 2) NULL,  
	 GainAmount_NLC                        DECIMAL(16, 2) NULL, 
	 ChargeoffExpenseAmount                DECIMAL(16, 2), 
	 ChargeoffExpenseAmount_LC             DECIMAL(16, 2) NULL, 
	 ChargeoffExpenseAmount_NLC            DECIMAL(16, 2) NULL, 
	 AmountApplied                         DECIMAL(16, 2), 
	 RardId                                BIGINT, 
	 ReceiptStatus                         NVARCHAR(40)
	);

	DECLARE @Migration NVARCHAR(50);
	DECLARE @True BIT= 1;
	DECLARE @False BIT= 0;
	DECLARE @LegalEntitiesCount BIGINT= ISNULL((SELECT COUNT(*) FROM @LegalEntityIds), 0);
	DECLARE @ContractsCount BIGINT= ISNULL((SELECT COUNT(*) FROM @ContractIds), 0);
	DECLARE @CustomersCount BIGINT= ISNULL((SELECT COUNT(*) FROM @CustomerIds), 0);
	DECLARE @DiscountingsCount BIGINT= ISNULL((SELECT COUNT(*) FROM @DiscountingIds), 0);
	SELECT @Migration = Value FROM GlobalParameters WHERE Category = 'Migration' AND Name = 'ConversionSource';

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
			  WHEN c.ContractType IS NULL
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
	   , BI.IsFAS91
	   , S.InvoiceComment	
	   , CASE WHEN GTT.Name IN ('AssetSaleAR', 'PropertyTaxAR' , 'PropertyTaxEscrow', 'SecurityDeposit', 'NonRentalAR', 'PayoffBuyoutAR')
			  THEN R.TotalBalance_Amount
			  WHEN IsFAS91 = 0
			  THEN r.TotalBalance_Amount
			  WHEN s.InvoiceComment IN ('Syndication Actual Proceeds','Syndication Scrape Receivable')
			  THEN r.TotalBalance_Amount
			  ELSE 0.00
		 END ChargeoffBalance
	  , IIF(BI.BookRecognitionMode IN ('Accrete', 'Amortize'), BI.IsFAS91, CAST(0 AS BIT)) IsFas91ForExpense 
	  , R.TotalBookBalance_Amount AS BookBalance
	INTO #ReceivableGLPostingInfo
	FROM Receivables R
		 JOIN ReceivableCodes RC ON R.ReceivableCodeId = RC.Id
		 JOIN ReceivableTypes RT ON RC.ReceivableTypeId = RT.Id
		 JOIN GLTemplates GT ON RC.GLTemplateId = GT.Id
		 JOIN GLTransactionTypes GTT ON GT.GLTransactionTypeId = GTT.Id
		 JOIN Parties P ON R.CustomerId = P.Id
		 LEFT JOIN Contracts C ON R.EntityId = C.Id
								  AND R.EntityType = 'CT'
		 LEFT JOIN Sundries S ON R.SourceId = S.Id AND R.SourceTable = 'Sundry'
		 LEFT JOIN BlendedItemDetails BID ON S.Id = BID.SundryId AND S.Id IS NOT NULL
		 LEFT JOIN BlendedItems BI ON BID.BlendedItemId = BI.Id AND BID.Id IS NOT NULL 
		 LEFT JOIN LeasePaymentSchedules LEPS ON R.PaymentScheduleId = LEPS.Id
												 AND C.ContractType = 'Lease' AND LEPS.IsActive = 1 AND R.SourceTable NOT IN ('CPUSchedule', 'SundryRecurring')
		 LEFT JOIN LoanPaymentSchedules LOPS ON R.PaymentScheduleId = LOPS.Id
												AND C.ContractType = 'Loan' AND LOPS.IsActive = 1 AND R.SourceTable NOT IN ('CPUSchedule', 'SundryRecurring')
		 LEFT JOIN TiedContractPaymentDetails payment ON payment.PaymentScheduleId = R.PaymentScheduleId
														 AND payment.ContractId = R.EntityId AND R.SourceTable NOT IN ('CPUSchedule', 'SundryRecurring')  
														 AND R.EntityType = 'CT' AND Payment.IsActive = 1
		 LEFT JOIN DiscountingContracts dc ON r.EntityId = dc.ContractId AND r.EntityType = 'CT'
		 LEFT JOIN DiscountingFinances DF ON dc.DiscountingFinanceId = DF.Id AND DF.IsCurrent = 1
	WHERE R.IsActive = 1
		  AND R.IsDummy = 0
		  AND R.FunderId IS NULL
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

	CREATE NONCLUSTERED INDEX IX_Id ON #DistinctContracts(EntityId, GLContractType, GLTemplateId, LegalEntityId);

	UPDATE dc SET ContractType = lfd.LeaseContractType
	FROM #DistinctContracts dc
	INNER JOIN LeaseFinances lf ON dc.EntityId = lf.ContractId AND lf.IsCurrent = 1
	INNER JOIN LeaseFinanceDetails lfd ON lfd.Id = lf.Id 
	WHERE dc.GLContractType = 'Contract'

	UPDATE dc SET SequenceNumber = ds.SequenceNumber, ContractType = 'Discounting',
	ContractAlias = ds.Alias
	FROM #DistinctContracts dc
	INNER JOIN Discountings ds ON dc.EntityId = ds.Id AND dc.GLContractType = 'Discounting'

	DECLARE @IsSku BIT = 0
	DECLARE @FilterCondition nvarchar(max) = ''
	DECLARE @Sql nvarchar(max) ='';
	
	SELECT DISTINCT 
		   t.EntityId
	     , nc.DoubtfulCollectability
	INTO #NonAccrualDetails
	FROM
	(
		SELECT ec.EntityId
				, MAX(nc.Id) AS NonAccrualId
		FROM #DistinctContracts ec
				LEFT JOIN NonAccrualContracts nc ON nc.ContractId = ec.EntityId
				LEFT JOIN NonAccruals na ON nc.NonAccrualId = na.Id
											AND nc.IsActive = 1
											AND na.Status = 'Approved'
		WHERE ec.GLContractType = 'Contract'
		GROUP BY ec.EntityId
	) AS t
	INNER JOIN NonAccrualContracts nc ON nc.Id = t.NonAccrualId
										 AND t.EntityId = nc.ContractId;
	

	CREATE NONCLUSTERED INDEX IX_Id ON #NonAccrualDetails(EntityId)

	IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'Assets' AND COLUMN_NAME = 'IsSku')
	BEGIN
	SET @IsSku = 1
	END

	
	IF @IsSku = 0
	BEGIN
	INSERT INTO #ReceivableAmount
	SELECT r.EntityId,
		   r.GLContractType ,
		   r.GLTemplateId,
		   CASE WHEN r.EntityType ='CU' THEN r.LegalEntityId ELSE NULL END AS LegalEntityId,
		   SUM(rd.Amount_Amount) AS TotalAmount,
		   SUM(CASE WHEN rd.AssetComponentType != 'Finance' 
					THEN rd.Amount_Amount
					ELSE 0.00
			   END) AS LeaseComponentTotalAmount,
		   SUM(CASE WHEN rd.AssetComponentType = 'Finance' 
					THEN rd.Amount_Amount
					ELSE 0.00
			   END) AS NonLeaseComponentTotalAmount,
		   SUM(CASE WHEN r.IsGLPosted = 1 AND rd.AssetComponentType != 'Finance' 
					THEN rd.Amount_Amount 
					ELSE 0.00 
				END) AS GLPostedLeaseComponent,
		   SUM(CASE WHEN r.IsGLPosted = 1 AND rd.AssetComponentType = 'Finance'
					THEN rd.Amount_Amount 
					ELSE 0.00 
				END) AS GLPostedFinanceComponent,
		   SUM(CASE WHEN r.IsGLPosted = 1 AND rd.AssetComponentType != 'Finance'
						 AND r.GLTransactionType IN ('InterimRentAR', 'LeaseInterimInterestAR', 'NonRentalAR')
					THEN rd.Balance_Amount
					WHEN r.IsGLPosted = 1 AND rd.AssetComponentType != 'Finance'
						AND co.Id IS NULL
						AND ((r.IsNonAccrual = 0 AND r.ContractType = 'Loan') OR (r.IsNonAccrual = 1 AND r.ContractType = 'Loan' AND r.ReceivableType NOT IN ('LoanPrincipal', 'LoanInterest')) OR r.ContractType != 'Loan')
					THEN rd.Balance_Amount
					WHEN r.IsGLPosted = 1 AND rd.AssetComponentType != 'Finance'
						AND co.Id IS NOT NULL
						AND ((r.IsNonAccrual = 0 AND r.ContractType = 'Loan') OR (r.IsNonAccrual = 1 AND r.ContractType = 'Loan' AND r.ReceivableType NOT IN ('LoanPrincipal', 'LoanInterest')) OR r.ContractType != 'Loan') AND r.ChargeoffBalance != 0.00
					THEN rd.Balance_Amount
					ELSE 0.00 
				END) AS GLPostedLeaseComponentOSAR,
		   SUM(CASE WHEN r.IsGLPosted = 1 AND rd.AssetComponentType = 'Finance'
						 AND r.GLTransactionType IN ('InterimRentAR', 'LeaseInterimInterestAR', 'NonRentalAR')
					THEN rd.Balance_Amount
					WHEN r.IsGLPosted = 1 AND rd.AssetComponentType = 'Finance'
						 AND ((r.IsNonAccrual = 0 AND r.ContractType = 'Loan') OR (r.IsNonAccrual = 1 AND r.ContractType = 'Loan' AND r.ReceivableType NOT IN ('LoanPrincipal', 'LoanInterest')) OR r.ContractType != 'Loan')
						 AND co.Id IS NULL
					THEN rd.Balance_Amount 
					WHEN r.IsGLPosted = 1 AND rd.AssetComponentType = 'Finance'
						AND co.Id IS NOT NULL
						AND ((r.IsNonAccrual = 0 AND r.ContractType = 'Loan') OR (r.IsNonAccrual = 1 AND r.ContractType = 'Loan' AND r.ReceivableType NOT IN ('LoanPrincipal', 'LoanInterest')) OR r.ContractType != 'Loan') AND r.ChargeoffBalance != 0.00
					THEN rd.Balance_Amount
					ELSE 0.00 
			   END) AS GLPostedFinanceComponentOSAR,
		   SUM(CASE WHEN r.IsGLPosted = 0 AND rd.AssetComponentType != 'Finance'
						 AND co.Id IS NOT NULL AND rd.Amount_Amount < 0
						 AND rd.Amount_Amount != rd.Balance_Amount 
						 AND r.ReceivableType NOT IN ('PropertyTax', 'PropertyTaxEscrow', 'AssetSale', 'CapitalLeaseRental', 'LeaseFloatRateAdj', 'OperatingLeaseRental', 'OverTermRental' , 'Supplemental', 'LoanInterest', 'LoanPrincipal')
					THEN 0.00
				    WHEN r.IsGLPosted = 0 AND rd.AssetComponentType != 'Finance'
						 AND r.GLTransactionType IN ('InterimRentAR', 'LeaseInterimInterestAR', 'NonRentalAR')
					THEN rd.Amount_Amount - rd.Balance_Amount
				    WHEN r.IsGLPosted = 0 AND rd.AssetComponentType != 'Finance' AND co.Id IS NULL 
						 AND ((r.IsNonAccrual = 0 AND r.ContractType = 'Loan') OR (r.IsNonAccrual = 1 AND r.ContractType = 'Loan' AND r.ReceivableType NOT IN ('LoanPrincipal', 'LoanInterest')) OR r.ContractType != 'Loan')
					THEN rd.Amount_Amount - rd.Balance_Amount 
					WHEN r.IsGLPosted = 0 AND rd.AssetComponentType != 'Finance'
						AND co.Id IS NOT NULL
						AND ((r.IsNonAccrual = 0 AND r.ContractType = 'Loan') OR (r.IsNonAccrual = 1 AND r.ContractType = 'Loan' AND r.ReceivableType NOT IN ('LoanPrincipal', 'LoanInterest')) OR r.ContractType != 'Loan') AND r.ChargeoffBalance != 0.00
					THEN rd.Amount_Amount - rd.Balance_Amount
					ELSE 0.00 
			   END) AS GLPostedLeaseComponentPrepaid,
		   SUM(CASE WHEN r.IsGLPosted = 0 AND rd.AssetComponentType = 'Finance'
						 AND co.Id IS NOT NULL AND rd.Amount_Amount < 0
						 AND rd.Amount_Amount != rd.Balance_Amount 
						 AND r.ReceivableType NOT IN ('PropertyTax', 'PropertyTaxEscrow', 'AssetSale', 'CapitalLeaseRental', 'LeaseFloatRateAdj', 'OperatingLeaseRental', 'OverTermRental' , 'Supplemental', 'LoanInterest', 'LoanPrincipal')
					THEN 0.00
					WHEN r.IsGLPosted = 0 AND rd.AssetComponentType = 'Finance'
						 AND r.GLTransactionType IN ('InterimRentAR', 'LeaseInterimInterestAR', 'NonRentalAR')
					THEN rd.Amount_Amount - rd.Balance_Amount
					WHEN r.IsGLPosted = 0 AND rd.AssetComponentType = 'Finance' AND co.Id IS NULL
						AND ((r.IsNonAccrual = 0 AND r.ContractType = 'Loan') OR (r.IsNonAccrual = 1 AND r.ContractType = 'Loan' AND r.ReceivableType NOT IN ('LoanPrincipal', 'LoanInterest')) OR r.ContractType != 'Loan') 
					THEN rd.Amount_Amount - rd.Balance_Amount
					WHEN r.IsGLPosted = 0 AND rd.AssetComponentType = 'Finance'
						AND co.Id IS NOT NULL
						AND ((r.IsNonAccrual = 0 AND r.ContractType = 'Loan') OR (r.IsNonAccrual = 1 AND r.ContractType = 'Loan' AND r.ReceivableType NOT IN ('LoanPrincipal', 'LoanInterest')) OR r.ContractType != 'Loan') AND r.ChargeoffBalance != 0.00
					THEN rd.Balance_Amount
					ELSE 0.00 
			   END) AS GLPostedFinanceComponentPrepaid,
		   SUM(CASE WHEN rd.AssetComponentType != 'Finance' 
					THEN rd.Balance_Amount 
					ELSE 0.00 
			   END) AS BalanceAmount_LC,
		   SUM(CASE WHEN rd.AssetComponentType = 'Finance' 
					THEN rd.Balance_Amount 
					ELSE 0.00 
			   END) AS BalanceAmount_NLC,
		   0.00 AS BookBalanceAmount
	FROM #ReceivableGLPostingInfo r
	INNER JOIN ReceivableDetails rd ON r.ReceivableId = rd.ReceivableId
	LEFT JOIN #ChargeOff co ON co.Id = r.EntityId AND r.EntityType ='CT'
	WHERE rd.IsActive = 1
	AND r.FunderId IS NULL
	GROUP BY r.EntityId,
			 r.GLContractType, 
			 r.GLTemplateId,
			 CASE WHEN r.EntityType ='CU' THEN r.LegalEntityId ELSE NULL END


		UPDATE ra SET 
					  BookBalanceAmount = t.BookBalance
		FROM #ReceivableAmount ra
			 INNER JOIN
		(
			SELECT r.EntityId
				 , r.GLContractType
				 , r.GLTemplateId
				 , SUM(R.BookBalance) AS BookBalance
			FROM #ReceivableGLPostingInfo r
				 LEFT JOIN #ChargeOff co ON co.Id = r.EntityId
											AND r.EntityType = 'CT'
			WHERE r.FunderId IS NULL
				  AND r.ReceivableType IN('LoanPrincipal', 'LoanInterest')
				 AND r.IsNonAccrual = 1
			GROUP BY r.EntityId
				   , r.GLContractType
				   , r.GLTemplateId
		) AS t ON t.EntityId = ra.EntityId
				  AND t.GLContractType = ra.EntityType
				  AND t.GLTemplateId = ra.GLTemplateId;

		INSERT INTO #NonAccrualLoanAmount
		SELECT EntityId
			 , GLContractType
			 , GLTemplateId
			 , CASE WHEN r.EntityType ='CU' THEN r.LegalEntityId ELSE NULL END AS LegalEntityId
			 , SUM(CASE
					   WHEN r.IsGLPosted = 1
					   THEN r.BookBalance
					   ELSE 0.00
				   END)
			 , 0.00
			 , SUM(CASE
					   WHEN r.IsGLPosted = 0
					   THEN r.TotalAmount_Amount - r.BookBalance
					   ELSE 0.00
				   END)
		FROM #ReceivableGLPostingInfo r
			 LEFT JOIN #ChargeOff co ON co.Id = r.EntityId
										AND r.EntityType = 'CT'
		WHERE r.IsNonAccrual = 1
			  AND co.Id IS NULL
			  AND r.ContractType = 'Loan'
			  AND r.ReceivableType IN('LoanPrincipal', 'LoanInterest')
		GROUP BY EntityId
			   , r.GLContractType
			   , r.GLTemplateId
			   , CASE WHEN r.EntityType ='CU' THEN r.LegalEntityId ELSE NULL END;

			  
	MERGE #ReceivableAmount AS receivable
	USING (SELECT * FROM #NonAccrualLoanAmount) AS receipt
	ON(receivable.GLTemplateId = receipt.GLTemplateId
		AND receivable.EntityId = receipt.EntityId
		AND receivable.EntityType = receipt.EntityType
		AND (receivable.LegalEntityId = receipt.LegalEntityId AND receivable.EntityType = 'Customer' OR receivable.EntityType != 'Customer'))
	WHEN MATCHED
		THEN UPDATE SET 
						GLPostedLeaseComponentOSAR = GLPostedLeaseComponentOSAR - receipt.OSARLease
						, GLPostedFinanceComponentOSAR = GLPostedFinanceComponentOSAR - receipt.OSARFinance
						, GLPostedLeaseComponentPrepaid = receipt.Prepaid - receivable.GLPostedLeaseComponentPrepaid
	WHEN NOT MATCHED
			THEN
			INSERT(EntityId, EntityType, GLTemplateId, LegalEntityId,  TotalAmount, LeaseComponentTotalAmount, NonLeaseComponentTotalAmount,  GLPostedLeaseComponent, GLPostedFinanceComponent ,GLPostedLeaseComponentOSAR , GLPostedFinanceComponentOSAR ,GLPostedLeaseComponentPrepaid, GLPostedFinanceComponentPrepaid, BalanceAmount_LC, BalanceAmount_NLC, BookBalanceAmount)
			VALUES(receipt.EntityId, receipt.EntityType, receipt.GLTemplateId, receipt.LegalEntityId,  0.00, 0.00, 0.00, 0.00, 0.00, receipt.OSARLease, receipt.OSARFinance, receipt.Prepaid, 0.00, 0.00, 0.00, 0.00);

	END
	
	IF @IsSku = 1
	BEGIN
	SET @Sql = 
	'SELECT r.EntityId,
			r.GLContractType,
			r.GLTemplateId,
			CASE WHEN r.EntityType =''CU'' THEN r.LegalEntityId ELSE NULL END AS LegalEntityId,
			SUM(rd.Amount_Amount) AS TotalAmount,
		    SUM(rd.LeaseComponentAmount_Amount) AS LeaseComponentTotalAmount,
		    SUM(rd.NonLeaseComponentAmount_Amount) AS NonLeaseComponentTotalAmount,
			SUM(CASE WHEN r.IsGLPosted = 1
					 THEN rd.LeaseComponentAmount_Amount 
					 ELSE 0.00 
				END) AS GLPostedLeaseComponent,
			SUM(CASE WHEN r.IsGLPosted = 1
					 THEN rd.NonLeaseComponentAmount_Amount 
					 ELSE 0.00 
				END) AS GLPostedFinanceComponent,
			SUM(CASE WHEN r.IsGLPosted = 1
						  AND r.GLTransactionType IN (''InterimRentAR'', ''LeaseInterimInterestAR'', ''NonRentalAR'')
					 THEN rd.LeaseComponentBalance_Amount
					 WHEN r.IsGLPosted = 1  AND co.Id IS NULL
						  AND ((r.IsNonAccrual = 0 AND r.ContractType = ''Loan'') OR (r.IsNonAccrual = 1 AND r.ContractType = ''Loan'' AND r.ReceivableType NOT IN (''LoanPrincipal'', ''LoanInterest'')) OR r.ContractType != ''Loan'')
					 THEN rd.LeaseComponentBalance_Amount
					 WHEN r.IsGLPosted = 1 AND co.Id IS NOT NULL
						AND ((r.IsNonAccrual = 0 AND r.ContractType = ''Loan'') OR (r.IsNonAccrual = 1 AND r.ContractType = ''Loan'' AND r.ReceivableType NOT IN (''LoanPrincipal'', ''LoanInterest'')) OR r.ContractType != ''Loan'') AND r.ChargeoffBalance != 0.00
					 THEN rd.LeaseComponentBalance_Amount	
					 ELSE 0.00  	
				END) AS GLPostedLeaseComponentOSAR,
			SUM(CASE WHEN r.IsGLPosted = 1
						  AND r.GLTransactionType IN (''InterimRentAR'', ''LeaseInterimInterestAR'', ''NonRentalAR'')
					 THEN rd.NonLeaseComponentBalance_Amount
			         WHEN r.IsGLPosted = 1 AND co.Id IS NULL
						  AND ((r.IsNonAccrual = 0 AND r.ContractType = ''Loan'') OR (r.IsNonAccrual = 1 AND r.ContractType = ''Loan'' AND r.ReceivableType NOT IN (''LoanPrincipal'', ''LoanInterest'')) OR r.ContractType != ''Loan'')
					 THEN rd.NonLeaseComponentBalance_Amount 
					 WHEN r.IsGLPosted = 1 AND co.Id IS NOT NULL
						  AND ((r.IsNonAccrual = 0 AND r.ContractType = ''Loan'') OR (r.IsNonAccrual = 1 AND r.ContractType = ''Loan'' AND r.ReceivableType NOT IN (''LoanPrincipal'', ''LoanInterest'')) OR r.ContractType != ''Loan'') AND r.ChargeoffBalance != 0.00
					 THEN rd.NonLeaseComponentBalance_Amount
					 ELSE 0.00  	
				END) AS GLPostedFinanceComponentOSAR,
			SUM(CASE WHEN r.IsGLPosted = 0
						 AND co.Id IS NOT NULL AND rd.LeaseComponentAmount_Amount < 0
						 AND rd.LeaseComponentAmount_Amount != rd.LeaseComponentBalance_Amount 
						 AND r.ReceivableType NOT IN (''PropertyTax'', ''PropertyTaxEscrow'', ''AssetSale'', ''CapitalLeaseRental'', ''LeaseFloatRateAdj'', ''OperatingLeaseRental'', ''OverTermRental'' , ''Supplemental'', ''LoanInterest'', ''LoanPrincipal'')
					 THEN 0.00
					 WHEN r.IsGLPosted = 0
						  AND r.GLTransactionType IN (''InterimRentAR'', ''LeaseInterimInterestAR'', ''NonRentalAR'')
					 THEN rd.LeaseComponentAmount_Amount - rd.LeaseComponentBalance_Amount	
					 WHEN r.IsGLPosted = 0 AND co.Id IS NULL
						  AND ((r.IsNonAccrual = 0 AND r.ContractType = ''Loan'') OR (r.IsNonAccrual = 1 AND r.ContractType = ''Loan'' AND r.ReceivableType NOT IN (''LoanPrincipal'', ''LoanInterest'')) OR r.ContractType != ''Loan'') 
					 THEN rd.LeaseComponentAmount_Amount - rd.LeaseComponentBalance_Amount
					 WHEN r.IsGLPosted = 0 AND co.Id IS NOT NULL
						  AND ((r.IsNonAccrual = 0 AND r.ContractType = ''Loan'') OR (r.IsNonAccrual = 1 AND r.ContractType = ''Loan'' AND r.ReceivableType NOT IN (''LoanPrincipal'', ''LoanInterest'')) OR r.ContractType != ''Loan'') AND r.ChargeoffBalance != 0.00
					 THEN rd.LeaseComponentAmount_Amount - rd.LeaseComponentBalance_Amount				  
					 ELSE 0.00 
				END) AS GLPostedLeaseComponentPrepaid,
			SUM(CASE WHEN r.IsGLPosted = 0
						 AND co.Id IS NOT NULL AND rd.NonLeaseComponentAmount_Amount < 0
						 AND rd.NonLeaseComponentAmount_Amount != rd.NonLeaseComponentBalance_Amount 
						 AND r.ReceivableType NOT IN (''PropertyTax'', ''PropertyTaxEscrow'', ''AssetSale'', ''CapitalLeaseRental'', ''LeaseFloatRateAdj'', ''OperatingLeaseRental'', ''OverTermRental'' , ''Supplemental'', ''LoanInterest'', ''LoanPrincipal'')
					 THEN 0.00
					 WHEN r.IsGLPosted = 0
						  AND r.GLTransactionType IN (''InterimRentAR'', ''LeaseInterimInterestAR'', ''NonRentalAR'')
					 THEN rd.NonLeaseComponentAmount_Amount - rd.NonLeaseComponentBalance_Amount
					 WHEN r.IsGLPosted = 0 AND co.Id IS NULL
						  AND ((r.IsNonAccrual = 0 AND r.ContractType = ''Loan'') OR (r.IsNonAccrual = 1 AND r.ContractType = ''Loan'' AND r.ReceivableType NOT IN (''LoanPrincipal'', ''LoanInterest'')) OR r.ContractType != ''Loan'')	
					 THEN rd.NonLeaseComponentAmount_Amount - rd.NonLeaseComponentBalance_Amount
					 WHEN r.IsGLPosted = 0 AND co.Id IS NOT NULL
						  AND ((r.IsNonAccrual = 0 AND r.ContractType = ''Loan'') OR (r.IsNonAccrual = 1 AND r.ContractType = ''Loan'' AND r.ReceivableType NOT IN (''LoanPrincipal'', ''LoanInterest'')) OR r.ContractType != ''Loan'') AND r.ChargeoffBalance != 0.00
					 THEN rd.NonLeaseComponentAmount_Amount - rd.NonLeaseComponentBalance_Amount					  	
					 ELSE 0.00 
				END) AS GLPostedFinanceComponentPrepaid,
		   SUM(rd.LeaseComponentBalance_Amount) AS BalanceAmount_LC,
		   SUM(rd.NonLeaseComponentBalance_Amount) AS BalanceAmount_NLC,
		   0.00 AS BookBalanceAmount
	FROM #ReceivableGLPostingInfo r
	INNER JOIN ReceivableDetails rd ON r.ReceivableId = rd.ReceivableId
	LEFT JOIN #ChargeOff co ON co.Id = r.EntityId AND r.EntityType =''CT''
	WHERE rd.IsActive = 1
	AND r.FunderId IS NULL
	GROUP BY r.EntityId,
			 r.GLContractType, 
			 r.GLTemplateId,
			 CASE WHEN r.EntityType =''CU'' THEN r.LegalEntityId ELSE NULL END'

	INSERT INTO #ReceivableAmount
	EXEC (@Sql)


	UPDATE ra SET 
					BookBalanceAmount = t.BookBalance
	FROM #ReceivableAmount ra
			INNER JOIN
	(
		SELECT r.EntityId
				, r.GLContractType
				, r.GLTemplateId
				, SUM(R.BookBalance) AS BookBalance
		FROM #ReceivableGLPostingInfo r
				LEFT JOIN #ChargeOff co ON co.Id = r.EntityId
										AND r.EntityType = 'CT'
		WHERE r.FunderId IS NULL
				AND r.ReceivableType IN('LoanPrincipal', 'LoanInterest')
				AND r.IsNonAccrual = 1
		GROUP BY r.EntityId
				, r.GLContractType
				, r.GLTemplateId
	) AS t ON t.EntityId = ra.EntityId
				AND t.GLContractType = ra.EntityType
				AND t.GLTemplateId = ra.GLTemplateId;

	SET @SQL = 
	'INSERT INTO #NonAccrualLoanAmount
	 SELECT EntityId
			 , GLContractType
			 , GLTemplateId
			 , CASE WHEN r.EntityType =''CU'' THEN r.LegalEntityId ELSE NULL END AS LegalEntityId
			 , SUM(CASE
					   WHEN r.IsGLPosted = 1
					   THEN r.BookBalance
					   ELSE 0.00
				   END)
			 , 0.00
			 , SUM(CASE
					   WHEN r.IsGLPosted = 0
					   THEN r.TotalAmount_Amount - r.BookBalance
					   ELSE 0.00
				   END)
		FROM #ReceivableGLPostingInfo r
			 LEFT JOIN #ChargeOff co ON co.Id = r.EntityId
										AND r.EntityType = ''CT''
		WHERE r.IsNonAccrual = 1
			  AND co.Id IS NULL
			  AND r.ContractType = ''Loan''
			  AND r.ReceivableType IN(''LoanPrincipal'', ''LoanInterest'')
		GROUP BY EntityId
			   , r.GLContractType
			   , r.GLTemplateId
			   , CASE WHEN r.EntityType =''CU'' THEN r.LegalEntityId ELSE NULL END;
		  
	MERGE #ReceivableAmount AS receivable
	USING (SELECT * FROM #NonAccrualLoanAmount) AS receipt
	ON(receivable.GLTemplateId = receipt.GLTemplateId
		AND receivable.EntityId = receipt.EntityId
		AND receivable.EntityType = receipt.EntityType
		AND (receivable.LegalEntityId = receipt.LegalEntityId AND receivable.EntityType = ''Customer'' OR receivable.EntityType != ''Customer''))
	WHEN MATCHED
		THEN UPDATE SET 
						GLPostedLeaseComponentOSAR = receipt.OSARLease - GLPostedLeaseComponentOSAR
						, GLPostedFinanceComponentOSAR = receipt.OSARFinance - GLPostedFinanceComponentOSAR
						, GLPostedLeaseComponentPrepaid = receipt.Prepaid - receivable.GLPostedLeaseComponentPrepaid
	WHEN NOT MATCHED
			THEN
			INSERT(EntityId, EntityType, GLTemplateId, LegalEntityId, TotalAmount, LeaseComponentTotalAmount, NonLeaseComponentTotalAmount, GLPostedLeaseComponent, GLPostedFinanceComponent ,GLPostedLeaseComponentOSAR , GLPostedFinanceComponentOSAR ,GLPostedLeaseComponentPrepaid, GLPostedFinanceComponentPrepaid, BalanceAmount_LC, BalanceAmount_NLC, BookBalanceAmount)
			VALUES(receipt.EntityId, receipt.EntityType, receipt.GLTemplateId, receipt.LegalEntityId, 0.00, 0.00, 0.00, 0.00, 0.00, receipt.OSARLease, receipt.OSARFinance, receipt.Prepaid, 0.00, 0.00, 0.00, 0.00);'
	EXEC (@Sql)

	END

	CREATE NONCLUSTERED INDEX IX_Id ON #ReceivableAmount(EntityId, EntityType,  GLTemplateId, LegalEntityId);
	
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

	CREATE NONCLUSTERED INDEX IX_Id ON #RecievableEntryItems(Id);

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
		 , SUM(CASE
				   WHEN eetd.AssetComponent != 'Finance'
				   THEN gld.DebitAmount
				   ELSE 0.00
			   END) -
			SUM(CASE
				   WHEN eetd.AssetComponent != 'Finance'
				   THEN gld.CreditAmount
				   ELSE 0.00
			   END) AS LeaseComponentGLPostedAmount
		 , SUM(CASE
				   WHEN eetd.AssetComponent = 'Finance' 
				   THEN gld.DebitAmount
				   ELSE 0.00
			   END) -
			SUM(CASE
				   WHEN eetd.AssetComponent = 'Finance'
				   THEN gld.CreditAmount
				   ELSE 0.00
			   END) AS NonLeaseComponentGLPostedAmount
		 , SUM(CASE
				   WHEN eetd.AssetComponent != 'Finance'
						AND eetd.IsPrepaidApplicable = 0
						AND gld.MatchingEntryName IS NULL
				   THEN gld.DebitAmount
				   ELSE 0.00
			   END) -
			SUM(CASE
				   WHEN eetd.AssetComponent != 'Finance'
						AND eetd.IsPrepaidApplicable = 0
						AND gld.MatchingEntryName IS NULL
				   THEN gld.CreditAmount 
				   ELSE 0.00
			   END) AS LeaseComponentOSARAmount
		 , SUM(CASE
				   WHEN eetd.AssetComponent = 'Finance'
						AND eetd.IsPrepaidApplicable = 0
				   THEN gld.DebitAmount
				   ELSE 0.00
			   END) -
			SUM(CASE
				   WHEN eetd.AssetComponent = 'Finance'
						AND eetd.IsPrepaidApplicable = 0 
				   THEN gld.CreditAmount
				   ELSE 0.00
			   END)  AS NonLeaseComponentOSARAmount
			, SUM(CASE
				   WHEN eetd.AssetComponent != 'Finance'
						AND eetd.IsPrepaidApplicable = 1 
				   THEN gld.DebitAmount
				   ELSE 0.00
			   END) -
			SUM(CASE
				   WHEN eetd.AssetComponent != 'Finance'
						AND eetd.IsPrepaidApplicable = 1 
				   THEN gld.CreditAmount
				   ELSE 0.00
			   END)  AS LeaseComponentPrepaid
			, SUM(CASE
				   WHEN eetd.AssetComponent = 'Finance'
						AND eetd.IsPrepaidApplicable = 1
				   THEN gld.DebitAmount
				   ELSE 0.00
			   END) -
			SUM(CASE
				   WHEN eetd.AssetComponent = 'Finance'
						AND eetd.IsPrepaidApplicable = 1
				   THEN gld.CreditAmount
				   ELSE 0.00
			   END)AS NonLeaseComponentPrepaid
	INTO #ReceivableGLPostedAmount
	FROM #GLTrialBalance gld
		 INNER JOIN GLEntryItems glei ON gld.EntryItemId = glei.Id
										 AND glei.IsActive = 1
		 INNER JOIN GLTransactionTypes gltt ON GLEI.GLTransactionTypeId = GLTT.Id
											   AND gltt.IsActive = 1
		 INNER JOIN #ExpectedEntryItemDetails eetd ON eetd.GLTransactionType = gltt.Name AND glei.Name = eetd.EntryItemName   
	WHERE eetd.IsDebit = 1
	AND eetd.IsBlendedItem = 0
	AND gltt.Name != 'SyndicatedAR'
	AND (MatchingEntryName != 'DueToThirdPartyAR' OR MatchingEntryName IS NULL)
	AND gltt.Name != 'SalesTax'
	AND eetd.IsVendorOwned = 0
	GROUP BY gld.EntityId
		   , gld.EntityType
		   , gld.GLTemplateId
		   , CASE WHEN gld.EntityType ='Customer' THEN gld.LegalEntityId ELSE NULL END;
		    
	CREATE NONCLUSTERED INDEX IX_Id ON #ReceivableGLPostedAmount(GLTemplateId, EntityId, EntityType, LegalEntityId);


	SELECT gld.EntityId
		 , gld.EntityType
		 , gld.MatchingGLTemplateId
		 , CASE WHEN gld.EntityType = 'Customer' THEN gld.LegalEntityId ELSE NULL END AS LegalEntityId
		 , SUM(CASE
				   WHEN eetd.AssetComponent != 'Finance'
						AND eetd.IsPrepaidApplicable = 0
				   THEN gld.CreditAmount
				   ELSE 0.00
			   END) - 
		   SUM(CASE
					WHEN eetd.AssetComponent != 'Finance'
						 AND eetd.IsPrepaidApplicable = 0
					THEN gld.DebitAmount
					ELSE 0.00
				END) LeaseComponentOSARAmount
		 , SUM(CASE
				   WHEN eetd.AssetComponent = 'Finance'
						AND eetd.IsPrepaidApplicable = 0
				   THEN gld.CreditAmount
				   ELSE 0.00
			   END) - 
		   SUM(CASE
					WHEN eetd.AssetComponent = 'Finance'
						 AND eetd.IsPrepaidApplicable = 0
					THEN gld.DebitAmount
					ELSE 0.00
				END) NonLeaseComponentOSARAmount
		 , SUM(CASE
				   WHEN eetd.AssetComponent != 'Finance'
						AND eetd.IsPrepaidApplicable = 1
				   THEN gld.CreditAmount
				   ELSE 0.00
			   END) - 
		   SUM(CASE
					WHEN eetd.AssetComponent != 'Finance'
						 AND eetd.IsPrepaidApplicable = 1
					THEN gld.DebitAmount
					ELSE 0.00
				END) LeaseComponentPrepaid
		 , SUM(CASE
				   WHEN eetd.AssetComponent = 'Finance'
						AND eetd.IsPrepaidApplicable = 1
				   THEN gld.CreditAmount
				   ELSE 0.00
			   END) - 
		   SUM(CASE
					WHEN eetd.AssetComponent = 'Finance'
						 AND eetd.IsPrepaidApplicable = 1
					THEN gld.DebitAmount
					ELSE 0.00
				END) NonLeaseComponentPrepaid
		 , SUM(CASE
				   WHEN eetd.AssetComponent != 'Finance'
						AND types.Name ='ReceiptCash'
						 AND eetd.IsDebit = 1
				   THEN gld.CreditAmount
				   ELSE 0.00
			   END) - 
		   SUM(CASE
					WHEN eetd.AssetComponent != 'Finance'
						 AND eetd.IsDebit = 1
						 AND types.Name ='ReceiptCash'
					THEN gld.DebitAmount
					ELSE 0.00
				END) LeaseComponentCashPosted
		 , SUM(CASE
				   WHEN eetd.AssetComponent != 'Finance'
						AND types.Name ='ReceiptNonCash'
						 AND eetd.IsDebit = 1
				   THEN gld.CreditAmount
				   ELSE 0.00
			   END) - 
		   SUM(CASE
					WHEN eetd.AssetComponent != 'Finance'
						 AND eetd.IsDebit = 1
						 AND types.Name ='ReceiptNonCash'
					THEN gld.DebitAmount
					ELSE 0.00
				END) LeaseComponentNonCashPosted
		 , SUM(CASE
				   WHEN eetd.AssetComponent = 'Finance'
						AND types.Name ='ReceiptCash'
						 AND eetd.IsDebit = 1
				   THEN gld.CreditAmount
				   ELSE 0.00
			   END) - 
		   SUM(CASE
					WHEN eetd.AssetComponent = 'Finance'
						 AND eetd.IsDebit = 1
						 AND types.Name ='ReceiptCash'
					THEN gld.DebitAmount
					ELSE 0.00
				END) FinanceComponentCashPosted
		 , SUM(CASE
				   WHEN eetd.AssetComponent = 'Finance'
						AND types.Name ='ReceiptNonCash'
						 AND eetd.IsDebit = 1
				   THEN gld.CreditAmount
				   ELSE 0.00
			   END) - 
		   SUM(CASE
					WHEN eetd.AssetComponent = 'Finance'
						 AND eetd.IsDebit = 1
						 AND types.Name ='ReceiptNonCash'
					THEN gld.DebitAmount
					ELSE 0.00
				END) FinanceComponentNonCashPosted
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
	WHERE gltt.Name != 'SyndicatedAR'
		  AND gl.Name IN ('OTPReceivable','Receivable')
		  AND MatchingEntryName != 'DueToThirdPartyAR'
		  AND gltt.Name != 'SalesTax'
		  AND eetd.IsBlendedItem = 0
		  AND eetd.IsVendorOwned = 0
	GROUP BY gld.EntityId
		   , gld.EntityType
		   , gld.MatchingGLTemplateId
		  , CASE WHEN gld.EntityType = 'Customer' THEN gld.LegalEntityId ELSE NULL END;

	CREATE NONCLUSTERED INDEX IX_Id ON #ReceiptGLPosting(EntityId, EntityType, MatchingGLTemplateId, LegalEntityId);

	IF @IsSku = 0
	BEGIN
	INSERT INTO #ReceiptApplicationReceivableDetails
		SELECT r.EntityId
			 , r.GLContractType
			 , r.GLTemplateId
			 , r.EntityType
			 , r.LegalEntityId
			 , ReceiptClassification
			 , rt.ReceiptTypeName
			 , rd.AssetComponentType
			 , r.IsNonAccrual
			 , r.ReceivableType
			 , r.StartDate
			 , rard.BookAmountApplied_Amount
		     , CASE WHEN rd.AssetComponentType != 'Finance' 
					 THEN rard.AmountApplied_Amount 
					 ELSE 0.00 
		      END LeaseComponentAmountApplied_Amount
			, CASE WHEN rd.AssetComponentType = 'Finance' 
				   THEN rard.AmountApplied_Amount 
				   ELSE 0.00 
			  END NonLeaseComponentAmountApplied_Amount
			 , rard.GainAmount_Amount
			 , rard.RecoveryAmount_Amount
			 , r.IsFAS91
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
		     , r.IsFas91ForExpense
			 , r.IsGLPosted
			 , r.AccountingTreatment
			 , rard.Id AS RardId
			 , r.GLTransactionType
			 , r.InvoiceComment
			 , r.DueDate
			 , NULL AS IsRecovery
		FROM #ReceivableGLPostingInfo r
			 JOIN ReceivableDetails rd ON rd.ReceivableId = r.ReceivableId
			 JOIN ReceiptApplicationReceivableDetails rard ON rard.ReceivableDetailId = rd.Id
			 JOIN ReceiptApplications ra ON ra.Id = rard.ReceiptApplicationId
			 JOIN Receipts Receipt ON ra.ReceiptId = Receipt.Id
			 JOIN ReceiptTypes rt ON rt.Id = receipt.TypeId
			 LEFT JOIN #ChargeOff co ON r.EntityId = co.Id
										AND r.EntityType = 'CT'
		WHERE rd.IsActive = 1
			 AND rard.IsActive = 1
			 AND rt.IsActive = 1
			 AND r.FunderId IS NULL;

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
				  AND co.ContractId IN (SELECT Distinct r.EntityId FROM #ReceivableGLPostingInfo r WHERE r.EntityType = 'CT') 
			GROUP BY co.ReceiptId
				   , c.Id ;


		CREATE NONCLUSTERED INDEX IX_Id ON #ChargeoffRecoveryReceiptIds(Id, ReceiptId);

		SELECT DISTINCT 
			   r.EntityId
			 , r.GLContractType
			 , r.GLTemplateId
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
			 , r.RardId
		INTO #NonSKUChargeoffRecoveryRecords
		FROM #ReceiptApplicationReceivableDetails r
			 JOIN Receipts receipt ON r.ReceiptId = Receipt.Id
			 JOIN ReceiptTypes rt ON rt.Id = receipt.TypeId
			 JOIN #ChargeoffRecoveryReceiptIds co ON r.EntityId = co.Id
													AND r.EntityType = 'CT'
													AND co.ReceiptId = receipt.Id
		WHERE (r.ReceivableType IN('CapitalLeaseRental', 'LeaseFloatRateAdj', 'OperatingLeaseRental', 'OverTermRental', 'Supplemental', 'LoanInterest', 'LoanPrincipal')
			   OR (r.IsGLPosted = 0 AND r.ReceivableType NOT IN('CapitalLeaseRental', 'LeaseFloatRateAdj', 'OperatingLeaseRent', 'OverTermRental', 'Supplemental', 'LoanInterest', 'LoanPrincipal', 'PropertyTax', 'PropertyTaxEscrow', 'AssetSale'))
			   OR (r.AccountingTreatment = 'CashBased' AND r.ReceivableType = 'AssetSale')
			   OR (r.IsFas91ForExpense = 1));

		CREATE NONCLUSTERED INDEX IX_Id ON #NonSKUChargeoffRecoveryRecords(RardId);


		UPDATE #NonSKUChargeoffRecoveryRecords SET 
												   RecoveryAmount_LC = LeaseComponentAmountApplied_Amount
												 , RecoveryAmount_NLC = NonLeaseComponentAmountApplied_Amount
		WHERE RecoveryAmount_Amount != 0.00
			  AND RecoveryAmount_Amount = AmountApplied;

		UPDATE #NonSKUChargeoffRecoveryRecords SET 
												   GainAmount_LC = LeaseComponentAmountApplied_Amount
												 , GainAmount_NLC = NonLeaseComponentAmountApplied_Amount
		WHERE GainAmount_Amount != 0.00
			  AND GainAmount_Amount = AmountApplied;

		UPDATE #NonSKUChargeoffRecoveryRecords SET 
												   RecoveryAmount_LC = CASE
																		   WHEN NonLeaseComponentAmountApplied_Amount = 0.00
																		   THEN RecoveryAmount_Amount
																		   ELSE RecoveryAmount_LC
																	   END
												 , RecoveryAmount_NLC = CASE
																			WHEN LeaseComponentAmountApplied_Amount = 0.00
																			THEN RecoveryAmount_Amount
																			ELSE RecoveryAmount_NLC
																		END
		WHERE RecoveryAmount_Amount != 0.00
			  AND (RecoveryAmount_LC IS NULL OR RecoveryAmount_NLC IS NULL)
			  AND (NonLeaseComponentAmountApplied_Amount = 0.00 OR LeaseComponentAmountApplied_Amount = 0.00);

		UPDATE #NonSKUChargeoffRecoveryRecords SET 
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

		UPDATE #NonSKUChargeoffRecoveryRecords SET 
												   RecoveryAmount_NLC = CASE
																			WHEN NonLeaseComponentAmountApplied_Amount = 0.00
																			THEN 0.00
																			ELSE RecoveryAmount_NLC
																		END
												 , RecoveryAmount_LC = CASE
																		   WHEN LeaseComponentAmountApplied_Amount = 0.00
																		   THEN 0.00
																		   ELSE RecoveryAmount_LC
																	   END
												 , GainAmount_NLC = CASE
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

		UPDATE rard SET 
						RecoveryAmount_LC = ISNULL(coe.RecoveryAmount_LC, 0.00)
					  , RecoveryAmount_NLC = ISNULL(coe.RecoveryAmount_NLC, 0.00)
					  , GainAmount_LC = ISNULL(coe.GainAmount_LC, 0.00)
					  , GainAmount_NLC = ISNULL(coe.GainAmount_NLC, 0.00)
					  , IsRecovery = CAST(1 AS BIT)
		FROM #ReceiptApplicationReceivableDetails rard
			 INNER JOIN #NonSKUChargeoffRecoveryRecords coe ON coe.RardId = rard.RardId;

	-- Chargeoff Expense logic
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
			  AND co.ContractId IN (SELECT Distinct r.EntityId FROM #ReceivableGLPostingInfo r WHERE r.EntityType = 'CT') 
		GROUP BY c.Id
			   , co.ReceiptId;

	CREATE NONCLUSTERED INDEX IX_Id ON #ChargeoffExpenseReceiptIds(Id, ReceiptId);

	SELECT DISTINCT
	  r.EntityId
	, r.GLContractType
	, r.GLTemplateId
	, r.ReceiptTypeName
	, r.ReceiptId
	, r.LeaseComponentAmountApplied_Amount
	, r.NonLeaseComponentAmountApplied_Amount
	, r.RecoveryAmount_Amount
	, r.GainAmount_Amount
	, r.StartDate
	, r.AmountApplied_Amount - (r.RecoveryAmount_Amount + r.GainAmount_Amount) AS ChargeoffExpenseAmount
	, IIF(r.LeaseComponentAmountApplied_Amount != 0.00, CAST(NULL AS DECIMAL(16, 2)),CAST(0 AS DECIMAL(16, 2)))  AS ChargeoffExpenseAmount_LC
	, IIF(r.NonLeaseComponentAmountApplied_Amount != 0.00, CAST(NULL AS DECIMAL(16, 2)),CAST(0 AS DECIMAL(16, 2))) AS ChargeoffExpenseAmount_NLC
	, r.AmountApplied_Amount AS AmountApplied
	, IIF(r.RecoveryAmount_Amount != 0.00, CAST(NULL AS DECIMAL(16, 2)), CAST(0 AS DECIMAL(16, 2))) AS RecoveryAmount_LC
	, IIF(r.RecoveryAmount_Amount != 0.00, CAST(NULL AS DECIMAL(16, 2)), CAST(0 AS DECIMAL(16, 2))) AS RecoveryAmount_NLC
	, IIF(r.GainAmount_Amount != 0.00, CAST(NULL AS DECIMAL(16, 2)), CAST(0 AS DECIMAL(16, 2))) AS GainAmount_LC
	, IIF(r.GainAmount_Amount != 0.00, CAST(NULL AS DECIMAL(16, 2)), CAST(0 AS DECIMAL(16, 2))) AS GainAmount_NLC
	, r.RardId
	INTO #NonSKUChargeoffExpenseRecords
	FROM #ReceiptApplicationReceivableDetails r
	JOIN #ChargeoffExpenseReceiptIds co ON r.EntityId = co.Id
										   AND r.EntityType = 'CT'
										   AND co.ReceiptId = r.ReceiptId
	WHERE (r.ReceivableType IN ('CapitalLeaseRental', 'LeaseFloatRateAdj', 'OperatingLeaseRental', 'OverTermRental', 'Supplemental', 'LoanInterest', 'LoanPrincipal')
		   OR (r.IsGLPosted = 0 AND r.ReceivableType NOT IN ('CapitalLeaseRental', 'LeaseFloatRateAdj', 'OperatingLeaseRental', 'OverTermRental', 'Supplemental', 'LoanInterest', 'LoanPrincipal', 'PropertyTax', 'PropertyTaxEscrow', 'AssetSale'))
		   OR (r.AccountingTreatment = 'CashBased' AND r.ReceivableType = 'AssetSale')
		   OR (r.IsFas91ForExpense = 1))
		    
	UPDATE #NonSKUChargeoffExpenseRecords SET 
											  ChargeoffExpenseAmount_LC = 0.00
											, ChargeoffExpenseAmount_NLC = 0.00
	WHERE ChargeoffExpenseAmount = 0.00;


	UPDATE #NonSKUChargeoffExpenseRecords SET 
											  ChargeoffExpenseAmount_LC = CASE
																			  WHEN NonLeaseComponentAmountApplied_Amount = 0.00
																			  THEN ChargeoffExpenseAmount
																			  ELSE ChargeoffExpenseAmount_LC
																		  END
											, ChargeoffExpenseAmount_NLC = CASE
																			   WHEN LeaseComponentAmountApplied_Amount = 0.00
																			   THEN ChargeoffExpenseAmount
																			   ELSE ChargeoffExpenseAmount_NLC
																		   END
	WHERE ChargeoffExpenseAmount != 0.00
		  AND (ChargeoffExpenseAmount_LC IS NULL OR ChargeoffExpenseAmount_NLC IS NULL)
		  AND (NonLeaseComponentAmountApplied_Amount = 0.00 OR LeaseComponentAmountApplied_Amount = 0.00);


 	UPDATE #NonSKUChargeoffExpenseRecords SET 
												RecoveryAmount_LC = CASE
																		WHEN NonLeaseComponentAmountApplied_Amount = 0.00 AND RecoveryAmount_Amount != 0.00
																		THEN RecoveryAmount_Amount
																		ELSE RecoveryAmount_LC
																	END
											, RecoveryAmount_NLC = CASE
																		WHEN LeaseComponentAmountApplied_Amount = 0.00 AND RecoveryAmount_Amount != 0.00
																		THEN RecoveryAmount_Amount
																		ELSE RecoveryAmount_NLC
																	END
											, GainAmount_LC = CASE
																	WHEN NonLeaseComponentAmountApplied_Amount = 0.00 AND GainAmount_Amount != 0.00
																	THEN GainAmount_Amount
																	ELSE GainAmount_LC
																END
											, GainAmount_NLC = CASE
																	WHEN LeaseComponentAmountApplied_Amount = 0.00 AND GainAmount_Amount != 0.00
																	THEN GainAmount_Amount
																	ELSE GainAmount_NLC
																END
	WHERE RecoveryAmount_Amount != 0.00 OR GainAmount_Amount != 0.00
			AND (RecoveryAmount_LC IS NULL OR RecoveryAmount_NLC IS NULL OR GainAmount_LC IS NULL OR GainAmount_NLC IS NULL)
			AND (NonLeaseComponentAmountApplied_Amount = 0.00 OR LeaseComponentAmountApplied_Amount = 0.00);
	

	UPDATE rard SET 
					RecoveryAmount_LC = ISNULL(coe.RecoveryAmount_LC, 0.00)
					, RecoveryAmount_NLC = ISNULL(coe.RecoveryAmount_NLC, 0.00)
					, GainAmount_LC = ISNULL(coe.GainAmount_LC, 0.00)
					, GainAmount_NLC = ISNULL(coe.GainAmount_NLC, 0.00)
					, ChargeoffExpenseAmount_LC = ISNULL(coe.ChargeoffExpenseAmount_LC, 0.00)
					, ChargeoffExpenseAmount_NLC = ISNULL(coe.ChargeoffExpenseAmount_NLC, 0.00)
					, IsRecovery = CAST(0 AS BIT)
	FROM #ReceiptApplicationReceivableDetails rard
			INNER JOIN #NonSKUChargeoffExpenseRecords coe ON coe.RardId = rard.RardId;


	INSERT INTO #ReceiptDetails
	SELECT  r.EntityId
		   , r.GLContractType
		   , r.GLTemplateId
		   , CASE WHEN r.EntityType ='CU' THEN r.LegalEntityId ELSE NULL END AS LegalEntityId
		   , SUM(CASE
					  WHEN ReceiptClassification IN('Cash', 'NonAccrualNonDSL', 'DSL') AND r.ReceiptTypeName NOT IN ('PayableOffset', 'SecurityDeposit', 'EscrowRefund')
				  		   AND r.AssetComponentType != 'Finance' AND r.IsNonAccrual = 1 AND r.ReceivableType IN ('LoanPrincipal', 'LoanInterest')
				  		   AND r.RecoveryAmount_Amount = 0.00 AND r.GainAmount_Amount = 0.00
						   AND (r.StartDate < co.ChargeOffDate  OR co.ChargeOffDate IS NULL OR r.StartDate IS NULL)
					  THEN r.BookAmountApplied_Amount
					  WHEN ReceiptClassification IN('Cash', 'NonAccrualNonDSL', 'DSL') AND r.ReceiptTypeName NOT IN ('PayableOffset', 'SecurityDeposit', 'EscrowRefund')
				  		   AND r.AssetComponentType != 'Finance'
						   AND r.GainAmount_Amount = 0.00 AND r.ChargeoffExpenseAmount_LC = 0.00 AND r.RecoveryAmount_Amount = 0.00 AND (((r.StartDate < co.ChargeOffDate  OR co.ChargeOffDate IS NULL OR r.StartDate IS NULL)) OR (co.Id IS NOT NULL AND (r.GLTransactionType IN ('AssetSaleAR', 'PropertyTaxAR' , 'PropertyTaxEscrow', 'SecurityDeposit') OR r.IsFAS91 = 0 OR r.InvoiceComment IN ('Syndication Actual Proceeds','Syndication Scrape Receivable')))) 
						   AND ((nc.DoubtfulCollectability IS NOT NULL AND (nc.DoubtfulCollectability = 0 OR r.GLTransactionType NOT IN ('OperatingLeaseAR', 'FloatRateAR'))) OR nc.DoubtfulCollectability IS NULL)
					  THEN r.AmountApplied_Amount
					  WHEN ReceiptClassification IN('Cash', 'NonAccrualNonDSL', 'DSL') AND r.ReceiptTypeName NOT IN ('PayableOffset', 'SecurityDeposit', 'EscrowRefund')
				  		   AND r.AssetComponentType != 'Finance'
						   AND r.GainAmount_Amount = 0.00 AND r.ChargeoffExpenseAmount_LC = 0.00 AND r.RecoveryAmount_Amount = 0.00
						   AND nc.DoubtfulCollectability IS NOT NULL AND nc.DoubtfulCollectability = 1
						   AND r.GLTransactionType IN ('OperatingLeaseAR', 'FloatRateAR')
					  THEN r.AmountApplied_Amount
					  ELSE 0.00 
				 END) AS LeaseComponentCashPosted
		   , SUM(CASE
					 WHEN ReceiptClassification IN('Cash', 'NonAccrualNonDSL', 'DSL') AND r.ReceiptTypeName NOT IN ('PayableOffset', 'SecurityDeposit', 'EscrowRefund')
				 		  AND r.AssetComponentType = 'Finance' AND r.IsNonAccrual = 1 AND r.ReceivableType IN ('LoanPrincipal', 'LoanInterest')
				 		  AND r.RecoveryAmount_Amount = 0.00 AND r.GainAmount_Amount = 0.00
						  AND (r.StartDate < co.ChargeOffDate  OR co.ChargeOffDate IS NULL OR r.StartDate IS NULL)
					 THEN r.BookAmountApplied_Amount
					 WHEN ReceiptClassification IN('Cash', 'NonAccrualNonDSL', 'DSL') AND r.ReceiptTypeName NOT IN ('PayableOffset', 'SecurityDeposit', 'EscrowRefund')
				 		  AND r.AssetComponentType = 'Finance'
						  AND r.GainAmount_Amount = 0.00 AND r.ChargeoffExpenseAmount_NLC = 0.00 AND r.RecoveryAmount_Amount = 0.00 AND (((r.StartDate < co.ChargeOffDate  OR co.ChargeOffDate IS NULL OR r.StartDate IS NULL)) OR (co.Id IS NOT NULL AND (r.GLTransactionType IN ('AssetSaleAR', 'PropertyTaxAR' , 'PropertyTaxEscrow', 'SecurityDeposit') OR r.IsFAS91 = 0 OR r.InvoiceComment IN ('Syndication Actual Proceeds','Syndication Scrape Receivable'))))
					 THEN r.AmountApplied_Amount
					 ELSE 0.00 
				 END) AS FinanceComponentCashPosted
		   , SUM(CASE
					  WHEN (ReceiptClassification NOT IN('Cash', 'NonAccrualNonDSL', 'DSL') OR r.ReceiptTypeName IN ('PayableOffset', 'SecurityDeposit', 'EscrowRefund'))
				 		  AND r.AssetComponentType != 'Finance' AND r.IsNonAccrual = 1 AND r.ReceivableType IN ('LoanPrincipal', 'LoanInterest')
				 		  AND r.RecoveryAmount_Amount = 0.00 AND r.GainAmount_Amount = 0.00
						  AND (r.StartDate < co.ChargeOffDate  OR co.ChargeOffDate IS NULL OR r.StartDate IS NULL)
					 THEN r.BookAmountApplied_Amount
					 WHEN (ReceiptClassification NOT IN('Cash', 'NonAccrualNonDSL', 'DSL') OR r.ReceiptTypeName IN ('PayableOffset', 'SecurityDeposit', 'EscrowRefund'))
				 		  AND r.AssetComponentType != 'Finance'
						  AND r.GainAmount_Amount = 0.00 AND r.ChargeoffExpenseAmount_LC = 0.00 AND r.RecoveryAmount_Amount = 0.00 AND (((r.StartDate < co.ChargeOffDate  OR co.ChargeOffDate IS NULL OR r.StartDate IS NULL)) OR (co.Id IS NOT NULL AND (r.GLTransactionType IN ('AssetSaleAR', 'PropertyTaxAR' , 'PropertyTaxEscrow', 'SecurityDeposit') OR r.IsFAS91 = 0 OR r.InvoiceComment IN ('Syndication Actual Proceeds','Syndication Scrape Receivable'))))
						  AND ((nc.DoubtfulCollectability IS NOT NULL AND (nc.DoubtfulCollectability = 0 OR r.GLTransactionType NOT IN ('OperatingLeaseAR', 'FloatRateAR'))) OR nc.DoubtfulCollectability IS NULL)
					 THEN r.AmountApplied_Amount
					  WHEN (ReceiptClassification NOT IN('Cash', 'NonAccrualNonDSL', 'DSL') OR r.ReceiptTypeName IN ('PayableOffset', 'SecurityDeposit', 'EscrowRefund'))
				 		  AND r.AssetComponentType != 'Finance'
						  AND r.GainAmount_Amount = 0.00 AND r.ChargeoffExpenseAmount_LC = 0.00 AND r.RecoveryAmount_Amount = 0.00
						  AND nc.DoubtfulCollectability IS NOT NULL AND nc.DoubtfulCollectability = 1 
						  AND r.GLTransactionType IN ('OperatingLeaseAR', 'FloatRateAR')
					 THEN r.AmountApplied_Amount
					 ELSE 0.00 
				 END) AS LeaseComponentNonCashPosted
		   , SUM(CASE
					 WHEN (ReceiptClassification NOT IN('Cash', 'NonAccrualNonDSL', 'DSL') OR r.ReceiptTypeName NOT IN ('PayableOffset', 'SecurityDeposit', 'EscrowRefund'))
				 		  AND r.AssetComponentType = 'Finance' AND r.IsNonAccrual = 1 AND r.ReceivableType IN ('LoanPrincipal', 'LoanInterest')
				 		  AND r.RecoveryAmount_Amount = 0.00 AND r.GainAmount_Amount = 0.00
						  AND (r.StartDate < co.ChargeOffDate  OR co.ChargeOffDate IS NULL OR r.StartDate IS NULL)
					 THEN r.BookAmountApplied_Amount
					 WHEN (ReceiptClassification NOT IN('Cash', 'NonAccrualNonDSL', 'DSL') OR r.ReceiptTypeName IN ('PayableOffset', 'SecurityDeposit', 'EscrowRefund'))
				 		  AND r.AssetComponentType = 'Finance'
						  AND r.GainAmount_Amount = 0.00 AND r.ChargeoffExpenseAmount_NLC = 0.00 AND r.RecoveryAmount_Amount = 0.00 AND (((r.StartDate < co.ChargeOffDate  OR co.ChargeOffDate IS NULL OR r.StartDate IS NULL)) OR (co.Id IS NOT NULL AND (r.GLTransactionType IN ('AssetSaleAR', 'PropertyTaxAR' , 'PropertyTaxEscrow', 'SecurityDeposit') OR r.IsFAS91 = 0 OR r.InvoiceComment IN ('Syndication Actual Proceeds','Syndication Scrape Receivable'))))
					 THEN r.AmountApplied_Amount
					 ELSE 0.00 
				 END) AS FinanceComponentNonCashPosted
			 , SUM(CASE
					   WHEN r.StartDate >= co.ChargeOffDate
							AND r.AssetComponentType != 'Finance'
							AND r.RecoveryAmount_Amount = 0.00 AND r.GainAmount_Amount = 0.00 AND r.ChargeoffExpenseAmount_LC = 0.00
							AND (ReceiptClassification IN('Cash', 'NonAccrualNonDSL', 'DSL') AND r.ReceiptTypeName NOT IN ('PayableOffset', 'SecurityDeposit', 'EscrowRefund'))
					   THEN r.AmountApplied_Amount
					   ELSE 0.00
				   END) AS LeaseCashApplicationRecovery
			 , SUM(CASE
					   WHEN r.StartDate >= co.ChargeOffDate
							AND r.AssetComponentType = 'Finance'
							AND r.RecoveryAmount_Amount = 0.00 AND r.GainAmount_Amount = 0.00 AND r.ChargeoffExpenseAmount_NLC = 0.00
							AND (ReceiptClassification IN('Cash', 'NonAccrualNonDSL', 'DSL') AND r.ReceiptTypeName NOT IN ('PayableOffset', 'SecurityDeposit', 'EscrowRefund'))
					   THEN r.AmountApplied_Amount
					   ELSE 0.00
				   END) AS FinanceCashApplicationRecovery
			, SUM(CASE
					  WHEN r.RecoveryAmount_Amount != 0.00
						   AND (r.GLTransactionType NOT IN ('AssetSaleAR', 'PropertyTaxAR' , 'PropertyTaxEscrow', 'SecurityDeposit') OR (r.IsFas91 IS NOT NULL AND r.IsFas91 = 0)
								OR (r.ReceivableType = 'Sundry' AND r.InvoiceComment NOT IN ('Syndication Actual Proceeds','Syndication Scrape Receivable')))
					  THEN r.RecoveryAmount_LC
					  ELSE 0.00
				END) AS RecoveryAmount_LC
		  , SUM(CASE
					WHEN r.RecoveryAmount_Amount != 0.00
						 AND (r.GLTransactionType NOT IN ('AssetSaleAR', 'PropertyTaxAR' , 'PropertyTaxEscrow', 'SecurityDeposit') OR (r.IsFas91 IS NOT NULL AND r.IsFas91 = 0)
							  OR (r.ReceivableType = 'Sundry' AND r.InvoiceComment NOT IN ('Syndication Actual Proceeds','Syndication Scrape Receivable')))
					THEN r.RecoveryAmount_NLC
					ELSE 0.00
				END) AS RecoveryAmount_NLC 
			, SUM(CASE
					  WHEN r.GainAmount_Amount != 0.00
						   AND (r.GLTransactionType NOT IN ('AssetSaleAR', 'PropertyTaxAR' , 'PropertyTaxEscrow', 'SecurityDeposit') OR (r.IsFas91 IS NOT NULL AND r.IsFas91 = 0)
							    OR (r.ReceivableType = 'Sundry' AND r.InvoiceComment NOT IN ('Syndication Actual Proceeds','Syndication Scrape Receivable')))
					  THEN r.GainAmount_LC
					  ELSE 0.00
				  END) AS GainAmount_LC
			, SUM(CASE
					  WHEN r.GainAmount_Amount != 0.00
						   AND (r.GLTransactionType NOT IN ('AssetSaleAR', 'PropertyTaxAR' , 'PropertyTaxEscrow', 'SecurityDeposit') OR (r.IsFas91 IS NOT NULL AND r.IsFas91 = 0)
								OR (r.ReceivableType = 'Sundry' AND r.InvoiceComment NOT IN ('Syndication Actual Proceeds','Syndication Scrape Receivable')))
					  THEN r.GainAmount_NLC
					  ELSE 0.00
				  END) AS GainAmount_LC
			, SUM(CASE
					  WHEN r.ReceivableType IN ('LoanPrincipal', 'LoanInterest')
						   AND r.AssetComponentType != 'Finance' AND r.IsNonAccrual = 1
				 		   AND r.RecoveryAmount_Amount = 0.00 AND r.GainAmount_Amount = 0.00 AND r.ChargeoffExpenseAmount_LC = 0.00
						   AND (r.StartDate < co.ChargeOffDate OR co.ChargeOffDate IS NULL OR r.StartDate IS NULL)
					  THEN r.BookAmountApplied_Amount
					  WHEN r.GLTransactionType NOT IN ('AssetSaleAR', 'PropertyTaxAR' , 'PropertyTaxEscrow', 'SecurityDeposit')
						   AND r.AssetComponentType != 'Finance' AND co.Id IS NOT NULL
						   AND r.RecoveryAmount_Amount = 0.00 AND r.GainAmount_Amount = 0.00  AND r.ChargeoffExpenseAmount_LC = 0.00
						   AND (r.StartDate < co.ChargeOffDate OR (r.StartDate IS NULL AND r.DueDate < co.ChargeOffDate)) 
						   AND ((nc.DoubtfulCollectability IS NOT NULL AND (nc.DoubtfulCollectability = 0 OR r.GLTransactionType NOT IN ('OperatingLeaseAR', 'FloatRateAR'))) OR nc.DoubtfulCollectability IS NULL)
					  THEN r.AmountApplied_Amount
					  WHEN r.GLTransactionType IN ('OperatingLeaseAR', 'FloatRateAR')
						   AND r.AssetComponentType != 'Finance' AND co.Id IS NOT NULL
						   AND r.RecoveryAmount_Amount = 0.00 AND r.GainAmount_Amount = 0.00  AND r.ChargeoffExpenseAmount_LC = 0.00
						   AND nc.DoubtfulCollectability IS NOT NULL AND nc.DoubtfulCollectability = 1
					  THEN r.AmountApplied_Amount
					  ELSE 0.00
				   END)	AS LeaseAmountApplied
			, SUM(CASE
					   WHEN r.ReceivableType IN ('LoanPrincipal', 'LoanInterest')
						   AND r.AssetComponentType = 'Finance' AND r.IsNonAccrual = 1
				 		   AND r.RecoveryAmount_Amount = 0.00 AND r.GainAmount_Amount = 0.00 AND r.ChargeoffExpenseAmount_NLC = 0.00
						   AND (r.StartDate < co.ChargeOffDate OR co.ChargeOffDate IS NULL OR r.StartDate IS NULL)
					  THEN r.BookAmountApplied_Amount
					  WHEN r.GLTransactionType NOT IN ('AssetSaleAR', 'PropertyTaxAR' , 'PropertyTaxEscrow', 'SecurityDeposit')
						   AND r.AssetComponentType = 'Finance' AND co.Id IS NOT NULL
						   AND r.RecoveryAmount_Amount = 0.00 AND r.GainAmount_Amount = 0.00 AND r.ChargeoffExpenseAmount_NLC = 0.00
						   AND (r.StartDate < co.ChargeOffDate OR (r.StartDate IS NULL AND r.DueDate < co.ChargeOffDate))
					  THEN r.AmountApplied_Amount
					  ELSE 0.00
				   END)	AS FinanceAmountApplied
			, SUM(CASE
					  WHEN r.ReceivableType = 'Sundry'
						   AND r.AssetComponentType != 'Finance' AND co.Id IS NOT NULL
						   AND r.RecoveryAmount_Amount = 0.00 AND r.GainAmount_Amount = 0.00 AND r.ChargeoffExpenseAmount_LC = 0.00
						   AND r.InvoiceComment IN ('Syndication Scrape Receivable', 'Syndication Actual Proceeds')
						   AND (r.StartDate < co.ChargeOffDate OR (r.StartDate IS NULL AND r.DueDate < co.ChargeOffDate))
					  THEN r.AmountApplied_Amount
					  ELSE 0.00
				   END) AS SundryAmount
			, SUM(CASE
					  WHEN r.AssetComponentType != 'Finance' AND co.Id IS NOT NULL
						   AND r.RecoveryAmount_Amount = 0.00 AND r.GainAmount_Amount = 0.00 AND r.ChargeoffExpenseAmount_LC = 0.00
						   AND r.IsFAS91 IS NOT NULL AND r.IsFAS91 = 0
						   AND (r.StartDate < co.ChargeOffDate OR (r.StartDate IS NULL AND r.DueDate < co.ChargeOffDate))
					  THEN r.AmountApplied_Amount
					  ELSE 0.00
				   END) AS BlendedItemAmount
			, SUM(CASE
					  WHEN co.Id IS NOT NULL
						   AND r.StartDate >= co.ChargeOffDate
						   AND r.ReceivableType IN ('LoanPrincipal', 'LoanInterest')
							AND r.RecoveryAmount_Amount = 0.00 AND r.GainAmount_Amount = 0.00
					  THEN r.BookAmountApplied_Amount
					  ELSE 0.00
				   END) AS LoanBookAmountApplied
			, SUM(CASE
					  WHEN r.accountingTreatment IN('CashBased', 'MemoBased')
						   AND r.AssetComponentType != 'Finance'
						   AND (ReceiptClassification NOT IN('Cash', 'NonAccrualNonDSL', 'DSL') AND r.ReceiptTypeName NOT IN ('PayableOffset', 'SecurityDeposit', 'EscrowRefund'))
						  AND r.GainAmount_Amount = 0.00 AND r.RecoveryAmount_Amount = 0.00 AND (((r.StartDate < co.ChargeOffDate  OR co.ChargeOffDate IS NULL OR r.StartDate IS NULL)) OR (co.Id IS NOT NULL AND (r.GLTransactionType IN ('AssetSaleAR', 'PropertyTaxAR' , 'PropertyTaxEscrow', 'SecurityDeposit') OR r.IsFAS91 = 0 OR r.InvoiceComment IN ('Syndication Actual Proceeds','Syndication Scrape Receivable'))))
					  THEN r.AmountApplied_Amount
				      ELSE 0.00
					END) AS LeaseComponentNonCashAmount
			, SUM(CASE
					  WHEN r.accountingTreatment IN('CashBased', 'MemoBased')
						   AND r.AssetComponentType = 'Finance'
						   AND (ReceiptClassification NOT IN('Cash', 'NonAccrualNonDSL', 'DSL') AND r.ReceiptTypeName NOT IN ('PayableOffset', 'SecurityDeposit', 'EscrowRefund'))
						  AND r.GainAmount_Amount = 0.00 AND r.RecoveryAmount_Amount = 0.00 AND (((r.StartDate < co.ChargeOffDate  OR co.ChargeOffDate IS NULL OR r.StartDate IS NULL)) OR (co.Id IS NOT NULL AND (r.GLTransactionType IN ('AssetSaleAR', 'PropertyTaxAR' , 'PropertyTaxEscrow', 'SecurityDeposit') OR r.IsFAS91 = 0 OR r.InvoiceComment IN ('Syndication Actual Proceeds','Syndication Scrape Receivable'))))
					  THEN r.AmountApplied_Amount
				      ELSE 0.00
					END) AS NonLeaseComponentNonCashAmount
			, SUM(r.ChargeoffExpenseAmount) AS ChargeoffExpenseAmount
			, SUM(ISNULL(r.ChargeoffExpenseAmount_LC, 0.00)) AS ChargeoffExpenseLCAmount
			, SUM(ISNULL(r.ChargeoffExpenseAmount_NLC, 0.00)) AS ChargeoffExpenseNLCAmount
	FROM #ReceiptApplicationReceivableDetails r
		 LEFT JOIN #ChargeOff co ON r.EntityId = co.Id AND r.EntityType = 'CT'
		 LEFT JOIN #NonAccrualDetails nc ON r.EntityId = nc.EntityId AND r.EntityType = 'CT'
	WHERE r.ReceiptStatus IN('Posted', 'Completed')
	GROUP BY r.EntityId
		   , r.GLContractType
		   , r.GLTemplateId
		   , CASE WHEN r.EntityType ='CU' THEN r.LegalEntityId ELSE NULL END;

	CREATE NONCLUSTERED INDEX IX_ReceiptId ON #ReceiptDetails(EntityId, GLContractType, GLTemplateId, LegalEntityId);
		  
	UPDATE rgl SET 
					LeaseComponentGLPostedAmount -= t.LeaseComponentGLPosted
                  , NonLeaseComponentGLPostedAmount -= t.FinanceComponentGLPosted
	FROM #ReceivableGLPostedAmount rgl
	INNER JOIN
	(
		SELECT r.EntityId
			 , r.GLContractType AS EntityType
			 , r.GLTemplateId
			 , ABS(SUM(CASE WHEN r.StartDate < co.ChargeoffDate OR r.StartDate IS NULL
						THEN ISNULL(r.ChargeoffExpenseAmount_LC, 0.00)
						ELSE 0.00 
				   END)) AS LeaseComponentGLPosted
			 , ABS(SUM(CASE WHEN r.StartDate < co.ChargeoffDate
						THEN ISNULL(r.ChargeoffExpenseAmount_NLC, 0.00)
						ELSE 0.00 
				   END)) AS FinanceComponentGLPosted
		FROM #ReceiptApplicationReceivableDetails r
			 INNER JOIN #ChargeOff co ON r.EntityId = co.Id
										 AND r.EntityType = 'CT'
		WHERE ReceiptStatus IN('Reversed')
			  AND r.IsRecovery IS NOT NULL AND r.IsRecovery = 0
			  AND ((r.ReceivableType IN ('CapitalLeaseRental', 'LeaseFloatRateAdj', 'OperatingLeaseRental', 'OverTermRental', 'Supplemental', 'LoanInterest', 'LoanPrincipal') AND r.IsGLPosted = 1)
				   OR (r.IsGLPosted = 0 AND r.ReceivableType NOT IN ('CapitalLeaseRental', 'LeaseFloatRateAdj', 'OperatingLeaseRental', 'OverTermRental', 'Supplemental', 'LoanInterest', 'LoanPrincipal', 'PropertyTax', 'PropertyTaxEscrow', 'AssetSale'))
				   OR (r.AccountingTreatment = 'CashBased' AND r.ReceivableType = 'AssetSale')
				   OR (r.IsFas91ForExpense = 1))
		GROUP BY r.EntityId
				, r.GLContractType
				, r.GLTemplateId
	) AS t ON t.EntityId = rgl.EntityId
				AND t.EntityType = rgl.EntityType
				AND t.GLTemplateId = rgl.GLTemplateId;

	UPDATE rgl SET 
				   LeaseComponentCashPosted -= t.LeaseComponentCashPosted
				 , FinanceComponentCashPosted -= t.FinanceComponentCashPosted
				 , LeaseComponentNonCashPosted -= t.LeaseComponentNonCashPosted
				 , FinanceComponentNonCashPosted -= t.FinanceComponentNonCashPosted
	FROM #ReceiptGLPosting rgl
	INNER JOIN
	(
		SELECT r.EntityId
			 , r.GLContractType AS EntityType
			 , r.GLTemplateId
			 , SUM(CASE WHEN ReceiptClassification IN('Cash', 'NonAccrualNonDSL', 'DSL') AND ReceiptTypeName NOT IN ('PayableOffset', 'SecurityDeposit',  'EscrowRefund')
						     AND (r.StartDate < co.ChargeoffDate OR r.StartDate IS NULL)
						THEN ISNULL(r.ChargeoffExpenseAmount_LC, 0.00)
						ELSE 0.00
				   END) AS LeaseComponentCashPosted
			 , SUM(CASE WHEN ReceiptClassification IN('Cash', 'NonAccrualNonDSL', 'DSL') AND ReceiptTypeName NOT IN ('PayableOffset', 'SecurityDeposit',  'EscrowRefund')
						     AND (r.StartDate < co.ChargeoffDate OR r.StartDate IS NULL)
						THEN ISNULL(r.ChargeoffExpenseAmount_NLC, 0.00)
						ELSE 0.00
				   END) AS FinanceComponentCashPosted
			 , SUM(CASE WHEN ReceiptClassification NOT IN('Cash', 'NonAccrualNonDSL', 'DSL') OR ReceiptTypeName IN ('PayableOffset', 'SecurityDeposit',  'EscrowRefund')
						     AND (r.StartDate < co.ChargeoffDate OR r.StartDate IS NULL)
						THEN ISNULL(r.ChargeoffExpenseAmount_LC, 0.00)
						ELSE 0.00
				   END) AS LeaseComponentNonCashPosted
			 , SUM(CASE WHEN ReceiptClassification NOT IN('Cash', 'NonAccrualNonDSL', 'DSL') OR ReceiptTypeName IN ('PayableOffset', 'SecurityDeposit',  'EscrowRefund')
						     AND (r.StartDate < co.ChargeoffDate OR r.StartDate IS NULL)
						THEN ISNULL(r.ChargeoffExpenseAmount_NLC, 0.00)
						ELSE 0.00
				   END) AS FinanceComponentNonCashPosted
		FROM #ReceiptApplicationReceivableDetails r
			 INNER JOIN #ChargeOff co ON r.EntityId = co.Id
										AND r.EntityType = 'CT'
		WHERE ReceiptStatus IN('Reversed')
			  AND r.IsRecovery IS NOT NULL AND r.IsRecovery = 0
			  AND ((r.ReceivableType IN ('CapitalLeaseRental', 'LeaseFloatRateAdj', 'OperatingLeaseRental', 'OverTermRental', 'Supplemental', 'LoanInterest', 'LoanPrincipal') AND r.IsGLPosted = 1)
				   OR (r.IsGLPosted = 0 AND r.ReceivableType NOT IN ('CapitalLeaseRental', 'LeaseFloatRateAdj', 'OperatingLeaseRental', 'OverTermRental', 'Supplemental', 'LoanInterest', 'LoanPrincipal', 'PropertyTax', 'PropertyTaxEscrow', 'AssetSale'))
				   OR (r.AccountingTreatment = 'CashBased' AND r.ReceivableType = 'AssetSale')
				   OR (r.IsFas91ForExpense = 1))
		GROUP BY r.EntityId
			   , r.GLContractType
			   , r.GLTemplateId
	) AS t ON t.EntityId = rgl.EntityId
			  AND t.EntityType = rgl.EntityType
			  AND t.GLTemplateId = rgl.MatchingGLTemplateId;
	END


	IF @IsSku = 1
	BEGIN

	SET @SQL = 
		'SELECT r.EntityId
			 , r.GLContractType
			 , r.GLTemplateId
			 , r.EntityType
			 , r.LegalEntityId
			 , ReceiptClassification
			 , rt.ReceiptTypeName
			 , rd.AssetComponentType
			 , r.IsNonAccrual
			 , r.ReceivableType
			 , r.StartDate
			 , rard.BookAmountApplied_Amount
			 , rard.LeaseComponentAmountApplied_Amount
			 , rard.NonLeaseComponentAmountApplied_Amount
			 , rard.GainAmount_Amount
			 , rard.RecoveryAmount_Amount
			 , r.IsFAS91
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
		     , r.IsFas91ForExpense
			 , r.IsGLPosted
			 , r.AccountingTreatment
			 , rard.Id AS RardId
			 , r.GLTransactionType
			 , r.InvoiceComment
			 , r.DueDate
			 , NULL AS IsRecovery
		FROM #ReceivableGLPostingInfo r
			 JOIN ReceivableDetails rd ON rd.ReceivableId = r.ReceivableId
			 JOIN ReceiptApplicationReceivableDetails rard ON rard.ReceivableDetailId = rd.Id
			 JOIN ReceiptApplications ra ON ra.Id = rard.ReceiptApplicationId
			 JOIN Receipts Receipt ON ra.ReceiptId = Receipt.Id
			 JOIN ReceiptTypes rt ON rt.Id = receipt.TypeId
			 LEFT JOIN #ChargeOff co ON r.EntityId = co.Id
										AND r.EntityType = ''CT''
		WHERE rd.IsActive = 1
			 AND rard.IsActive = 1
			 AND rt.IsActive = 1
			 AND r.FunderId IS NULL;'
		
		INSERT INTO #ReceiptApplicationReceivableDetails
		EXEC (@SQL)	 

	   -- Charge off recovery calculation logic
	IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'ChargeOffs' AND COLUMN_NAME = 'LeaseComponentGain_Amount')
	BEGIN    
	SET @SQL = 
		'SELECT c.Id
			 , co.ReceiptId
			 , SUM(co.LeaseComponentAmount_Amount) AS LeaseComponentAmount_Amount
			 , SUM(co.NonLeaseComponentAmount_Amount) AS NonLeaseComponentAmount_Amount
			 , SUM(co.LeaseComponentGain_Amount) AS LeaseComponentGain_Amount
			 , SUM(co.NonLeaseComponentGain_Amount) AS NonLeaseComponentGain_Amount
		FROM Contracts c
			 INNER JOIN ChargeOffs co ON co.ContractId = c.Id
		WHERE co.IsActive = 1
			  AND co.Status = ''Approved''
			  AND co.IsRecovery = 1
			  AND co.ReceiptId IS NOT NULL
			  AND co.ContractId IN (SELECT Distinct r.EntityId FROM #ReceivableGLPostingInfo r WHERE r.EntityType = ''CT'') 
		GROUP BY co.ReceiptId
			   , c.Id ;'

	    INSERT INTO #ChargeoffRecoveryReceiptIds
	    EXEC (@SQL)
	END

	IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'ChargeOffs' AND COLUMN_NAME = 'LeaseComponentGain_Amount')
	BEGIN
	SET @SQL = 
		'SELECT c.Id
			 , co.ReceiptId
			 , 0.00 AS LeaseComponentAmount_Amount
			 , 0.00 AS NonLeaseComponentAmount_Amount
			 , 0.00 AS LeaseComponentGain_Amount
			 , 0.00 AS NonLeaseComponentGain_Amount
		FROM Contracts c
			 INNER JOIN ChargeOffs co ON co.ContractId = c.Id
		WHERE co.IsActive = 1
			  AND co.Status = ''Approved''
			  AND co.IsRecovery = 1
			  AND co.ReceiptId IS NOT NULL
			  AND co.ContractId IN (SELECT Distinct r.EntityId FROM #ReceivableGLPostingInfo r WHERE r.EntityType = ''CT'') 
		GROUP BY co.ReceiptId
			   , c.Id ;'

	    INSERT INTO #ChargeoffRecoveryReceiptIds
	    EXEC (@SQL)
	END

	CREATE NONCLUSTERED INDEX IX_ReceiptId ON #ChargeoffRecoveryReceiptIds(Id, ReceiptId);


		SET @SQL =
	   'SELECT DISTINCT 
			   r.EntityId
			 , r.GLContractType
			 , r.GLTemplateId
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
			 , r.RardId
		FROM #ReceiptApplicationReceivableDetails r
			 JOIN Receipts receipt ON r.ReceiptId = Receipt.Id
			 JOIN ReceiptTypes rt ON rt.Id = receipt.TypeId
			 JOIN #ChargeoffRecoveryReceiptIds co ON r.EntityId = co.Id
													AND r.EntityType = ''CT''
													AND co.ReceiptId = receipt.Id
		WHERE Receipt.Status IN(''Posted'', ''Completed'')
			 AND (r.ReceivableType IN(''CapitalLeaseRental'', ''LeaseFloatRateAdj'', ''OperatingLeaseRental'', ''OverTermRental'', ''Supplemental'', ''LoanInterest'', ''LoanPrincipal'')
				  OR (r.IsGLPosted = 0 AND r.ReceivableType NOT IN(''CapitalLeaseRental'', ''LeaseFloatRateAdj'', ''OperatingLeaseRent'', ''OverTermRental'', ''Supplemental'', ''LoanInterest'', ''LoanPrincipal'', ''PropertyTax'', ''PropertyTaxEscrow'', ''AssetSale''))
				  OR (r.AccountingTreatment = ''CashBased'' AND r.ReceivableType = ''AssetSale'')
				  OR (r.IsFas91ForExpense = 1));'

		INSERT INTO #ChargeoffRecoveryRecords
		EXEC (@SQL)					

		CREATE NONCLUSTERED INDEX IX_Id ON #ChargeoffRecoveryRecords(EntityId);

		UPDATE #ChargeoffRecoveryRecords SET 
											RecoveryAmount_LC = LeaseComponentAmountApplied_Amount
										  , RecoveryAmount_NLC = NonLeaseComponentAmountApplied_Amount
		WHERE RecoveryAmount_Amount != 0.00
			  AND RecoveryAmount_Amount = AmountApplied;


		UPDATE #ChargeoffRecoveryRecords SET 
											GainAmount_LC = LeaseComponentAmountApplied_Amount
										  , GainAmount_NLC = NonLeaseComponentAmountApplied_Amount
		WHERE GainAmount_Amount != 0.00
			  AND GainAmount_Amount = AmountApplied;		

		UPDATE #ChargeoffRecoveryRecords SET 
											RecoveryAmount_LC = CASE
																	WHEN NonLeaseComponentAmountApplied_Amount = 0.00
																	THEN RecoveryAmount_Amount
																	ELSE RecoveryAmount_LC
																END
										  , RecoveryAmount_NLC = CASE
																	 WHEN LeaseComponentAmountApplied_Amount = 0.00
																	 THEN RecoveryAmount_Amount
																	 ELSE RecoveryAmount_NLC
																 END
		WHERE RecoveryAmount_Amount != 0.00
			  AND (RecoveryAmount_LC IS NULL OR RecoveryAmount_NLC IS NULL)
			  AND (NonLeaseComponentAmountApplied_Amount = 0.00 OR LeaseComponentAmountApplied_Amount = 0.00);

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
											RecoveryAmount_NLC = CASE
																	 WHEN NonLeaseComponentAmountApplied_Amount = 0.00
																	 THEN 0.00
																	 ELSE RecoveryAmount_NLC
																 END
										  , RecoveryAmount_LC = CASE
																	WHEN LeaseComponentAmountApplied_Amount = 0.00
																	THEN 0.00
																	ELSE RecoveryAmount_LC
																END
										  , GainAmount_NLC = CASE
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
												RecoveryAmount_LC = CASE
																	    WHEN coe.RecoveryAmount_LC IS NULL
																		THEN cte.ChargeoffRecoveryAmount_LC
																		ELSE coe.RecoveryAmount_LC
																	END
											, RecoveryAmount_NLC = CASE
																	    WHEN coe.RecoveryAmount_NLC IS NULL
																		THEN cte.ChargeoffRecoveryAmount_NLC
																		ELSE coe.RecoveryAmount_NLC
																	END
											, GainAmount_LC = CASE
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
				FROM #ReceiptApplicationReceivableDetails rard
					 INNER JOIN #ChargeoffRecoveryRecords coe ON coe.RardId = rard.RardId;

		-- Charge off expense calculation logic
	IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'ChargeOffs' AND COLUMN_NAME = 'LeaseComponentGain_Amount')
	BEGIN
		SET @SQL = 
	   'SELECT c.Id
			 , co.ReceiptId
			 , SUM(co.LeaseComponentAmount_Amount) AS LeaseComponentAmount_Amount
			 , SUM(co.NonLeaseComponentAmount_Amount) AS NonLeaseComponentAmount_Amount
			 , SUM(co.LeaseComponentGain_Amount) AS LeaseComponentGain_Amount
			 , SUM(co.NonLeaseComponentGain_Amount) AS NonLeaseComponentGain_Amount
		FROM Contracts c
			 INNER JOIN ChargeOffs co ON co.ContractId = c.Id
		WHERE co.IsActive = 1
			  AND co.Status = ''Approved''
			  AND co.IsRecovery = 0
			  AND co.ReceiptId IS NOT NULL
			  AND co.ContractId IN (SELECT Distinct r.EntityId FROM #ReceivableGLPostingInfo r WHERE r.EntityType = ''CT'') 
		GROUP BY c.Id
			   , co.ReceiptId;'
		INSERT INTO #ChargeoffExpenseReceiptIds
		EXEC (@SQL)

	END

	IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'ChargeOffs' AND COLUMN_NAME = 'LeaseComponentGain_Amount')
	BEGIN
		SET @SQL = 
	   'SELECT c.Id
			 , co.ReceiptId
			 , 0.00 AS LeaseComponentAmount_Amount
			 , 0.00 AS NonLeaseComponentAmount_Amount
			 , 0.00 AS LeaseComponentGain_Amount
			 , 0.00 AS NonLeaseComponentGain_Amount
		FROM Contracts c
			 INNER JOIN ChargeOffs co ON co.ContractId = c.Id
		WHERE co.IsActive = 1
			  AND co.Status = ''Approved''
			  AND co.IsRecovery = 0
			  AND co.ReceiptId IS NOT NULL
			  AND co.ContractId IN (SELECT Distinct r.EntityId FROM #ReceivableGLPostingInfo r WHERE r.EntityType = ''CT'') 
		GROUP BY c.Id
			   , co.ReceiptId;'
		INSERT INTO #ChargeoffExpenseReceiptIds
		EXEC (@SQL)

	END

		CREATE NONCLUSTERED INDEX IX_ReceiptId ON #ChargeoffExpenseReceiptIds(Id, ReceiptId);

		SET @SQL =
		'SELECT DISTINCT 
			   r.EntityId
			 , r.GLContractType
			 , r.GLTemplateId
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
		FROM #ReceiptApplicationReceivableDetails r
			 JOIN Receipts receipt ON r.ReceiptId = Receipt.Id
			 JOIN ReceiptTypes rt ON rt.Id = receipt.TypeId
			 JOIN #ChargeoffExpenseReceiptIds co ON r.EntityId = co.Id
													AND r.EntityType = ''CT''
													AND co.ReceiptId = receipt.Id
		WHERE (r.ReceivableType IN(''CapitalLeaseRental'', ''LeaseFloatRateAdj'', ''OperatingLeaseRental'', ''OverTermRental'', ''Supplemental'', ''LoanInterest'', ''LoanPrincipal'')
			   OR (r.IsGLPosted = 0 AND r.ReceivableType NOT IN(''CapitalLeaseRental'', ''LeaseFloatRateAdj'', ''OperatingLeaseRent'', ''OverTermRental'', ''Supplemental'', ''LoanInterest'', ''LoanPrincipal'', ''PropertyTax'', ''PropertyTaxEscrow'', ''AssetSale''))
			   OR (r.AccountingTreatment = ''CashBased'' AND r.ReceivableType = ''AssetSale'')
			   OR (r.IsFas91ForExpense = 1));'

		INSERT INTO #ChargeoffExpenseRecords
		EXEC (@SQL)
		
		 		
		CREATE NONCLUSTERED INDEX IX_Id ON #ChargeoffExpenseRecords(EntityId);

		UPDATE #ChargeoffExpenseRecords SET 
											ChargeoffExpenseAmount_LC = 0.00
										  , ChargeoffExpenseAmount_NLC = 0.00
		WHERE ChargeoffExpenseAmount = 0.00;

		UPDATE #ChargeoffExpenseRecords SET 
											RecoveryAmount_LC = LeaseComponentAmountApplied_Amount
										  , RecoveryAmount_NLC = NonLeaseComponentAmountApplied_Amount
		WHERE RecoveryAmount_Amount != 0.00
			  AND RecoveryAmount_Amount = AmountApplied;

		UPDATE #ChargeoffExpenseRecords SET 
											GainAmount_LC = LeaseComponentAmountApplied_Amount
										  , GainAmount_NLC = NonLeaseComponentAmountApplied_Amount
		WHERE GainAmount_Amount != 0.00
			  AND GainAmount_Amount = AmountApplied;

		UPDATE #ChargeoffExpenseRecords SET 
											RecoveryAmount_LC = CASE
																	WHEN NonLeaseComponentAmountApplied_Amount = 0.00
																	THEN RecoveryAmount_Amount
																	ELSE RecoveryAmount_LC
																END
										  , RecoveryAmount_NLC = CASE
																	 WHEN LeaseComponentAmountApplied_Amount = 0.00
																	 THEN RecoveryAmount_Amount
																	 ELSE RecoveryAmount_NLC
																 END
		WHERE RecoveryAmount_Amount != 0.00
			  AND (RecoveryAmount_LC IS NULL OR RecoveryAmount_NLC IS NULL)
			  AND (NonLeaseComponentAmountApplied_Amount = 0.00 OR LeaseComponentAmountApplied_Amount = 0.00);

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
											RecoveryAmount_NLC = CASE
																	 WHEN NonLeaseComponentAmountApplied_Amount = 0.00
																	 THEN 0.00
																	 ELSE RecoveryAmount_NLC
																 END
										  , RecoveryAmount_LC = CASE
																	WHEN LeaseComponentAmountApplied_Amount = 0.00
																	THEN 0.00
																	ELSE RecoveryAmount_LC
																END
										  , ChargeoffExpenseAmount_LC = CASE
																			WHEN LeaseComponentAmountApplied_Amount = 0.00
																			THEN 0.00
																			ELSE ChargeoffExpenseAmount_LC
																		END
										  , ChargeoffExpenseAmount_NLC = CASE
																			 WHEN NonLeaseComponentAmountApplied_Amount = 0.00
																			 THEN 0.00
																			 ELSE ChargeoffExpenseAmount_NLC
																		 END
										  , GainAmount_NLC = CASE
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

		UPDATE #ChargeoffExpenseRecords SET 
											ChargeoffExpenseAmount_LC = LeaseComponentAmountApplied_Amount
										  , ChargeoffExpenseAmount_NLC = NonLeaseComponentAmountApplied_Amount
		WHERE ChargeoffExpenseAmount != 0.00 AND ChargeoffExpenseAmount = AmountApplied;

		UPDATE #ChargeoffExpenseRecords SET 
											ChargeoffExpenseAmount_LC = CASE
																			WHEN NonLeaseComponentAmountApplied_Amount = 0.00
																			THEN ChargeoffExpenseAmount
																			ELSE ChargeoffExpenseAmount_LC
																		END
										  , ChargeoffExpenseAmount_NLC = CASE
																			 WHEN LeaseComponentAmountApplied_Amount = 0.00
																			 THEN ChargeoffExpenseAmount
																			 ELSE ChargeoffExpenseAmount_NLC
																		 END
		WHERE ChargeoffExpenseAmount != 0.00
			  AND (ChargeoffExpenseAmount_LC IS NULL OR ChargeoffExpenseAmount_NLC IS NULL)
			  AND (NonLeaseComponentAmountApplied_Amount = 0.00 OR LeaseComponentAmountApplied_Amount = 0.00);



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
												 ChargeoffExpenseAmount_LC = CASE
																				 WHEN coe.ChargeoffExpenseAmount_LC IS NULL
																				 THEN cte.ChargeoffExpenseAmount_LC
																				 ELSE coe.ChargeoffExpenseAmount_LC
																			 END
											   , ChargeoffExpenseAmount_NLC = CASE
																				  WHEN coe.ChargeoffExpenseAmount_NLC IS NULL
																				  THEN cte.ChargeoffExpenseAmount_NLC
																				  ELSE coe.ChargeoffExpenseAmount_NLC
																			  END
											   , GainAmount_LC = CASE
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

		UPDATE #ChargeoffExpenseRecords SET 
											RecoveryAmount_LC = CASE
																	WHEN RecoveryAmount_LC IS NULL
																	THEN LeaseComponentAmountApplied_Amount - (ChargeoffExpenseAmount_LC + ISNULL(GainAmount_LC, 0.00))
																	ELSE RecoveryAmount_LC
																END
										  , RecoveryAmount_NLC = CASE
																	 WHEN RecoveryAmount_NLC IS NULL
																	 THEN NonLeaseComponentAmountApplied_Amount - (ChargeoffExpenseAmount_NLC + ISNULL(GainAmount_NLC, 0.00))
																	 ELSE RecoveryAmount_NLC
																 END
		WHERE(RecoveryAmount_NLC IS NULL OR RecoveryAmount_LC IS NULL)
			 AND (ChargeoffExpenseAmount_LC IS NOT NULL AND ChargeoffExpenseAmount_NLC IS NOT NULL);


		UPDATE rard SET 
						RecoveryAmount_LC = coe.RecoveryAmount_LC
					  , RecoveryAmount_NLC = coe.RecoveryAmount_NLC
					  , GainAmount_LC = coe.GainAmount_LC
					  , GainAmount_NLC = coe.GainAmount_NLC
					  , ChargeoffExpenseAmount_LC = coe.ChargeoffExpenseAmount_LC
					  , ChargeoffExpenseAmount_NLC = coe.ChargeoffExpenseAmount_NLC
					  , ChargeoffExpenseAmount = coe.ChargeoffExpenseAmount
					  , IsRecovery = CAST(0 AS BIT)
		FROM #ReceiptApplicationReceivableDetails rard
			 INNER JOIN #ChargeoffExpenseRecords coe ON coe.RardId = rard.RardId

	INSERT INTO #ReceiptDetails
	SELECT  r.EntityId
		   , r.GLContractType
		   , r.GLTemplateId
		   , CASE WHEN r.EntityType = 'CU' THEN r.LegalEntityId ELSE NULL END AS LegalEntityId
		   , SUM(CASE
					   WHEN ReceiptClassification IN('Cash', 'NonAccrualNonDSL', 'DSL') AND ReceiptTypeName NOT IN ('PayableOffset', 'SecurityDeposit',  'EscrowRefund')
				  		   AND AssetComponentType != 'Finance' AND r.IsNonAccrual = 1 AND r.ReceivableType IN ('LoanPrincipal', 'LoanInterest')
				  		   AND RecoveryAmount_Amount = 0.00 AND GainAmount_Amount = 0.00 AND r.ChargeoffExpenseAmount_LC = 0.00
						   AND (r.StartDate < co.ChargeOffDate OR co.ChargeOffDate IS NULL OR r.StartDate IS NULL)
					  THEN BookAmountApplied_Amount
					  WHEN ReceiptClassification IN('Cash', 'NonAccrualNonDSL', 'DSL') AND ReceiptTypeName NOT IN ('PayableOffset', 'SecurityDeposit',  'EscrowRefund')
						   AND NOT (r.IsNonAccrual = 1 AND r.ReceivableType IN ('LoanPrincipal', 'LoanInterest'))
						   AND GainAmount_Amount = 0.00 AND r.ChargeoffExpenseAmount_LC = 0.00 AND RecoveryAmount_Amount = 0.00 AND (((r.StartDate < co.ChargeOffDate  OR co.ChargeOffDate IS NULL OR r.StartDate IS NULL)) OR (co.Id IS NOT NULL AND (r.GLTransactionType IN ('AssetSaleAR', 'PropertyTaxAR' , 'PropertyTaxEscrow', 'SecurityDeposit') OR r.IsFAS91 = 0 OR r.InvoiceComment IN ('Syndication Actual Proceeds','Syndication Scrape Receivable')))) 
					       AND ((nc.DoubtfulCollectability IS NOT NULL AND (nc.DoubtfulCollectability = 0 OR r.GLTransactionType NOT IN ('OperatingLeaseAR', 'FloatRateAR'))) OR nc.DoubtfulCollectability IS NULL)
					  THEN LeaseComponentAmountApplied_Amount
					  WHEN ReceiptClassification IN('Cash', 'NonAccrualNonDSL', 'DSL') AND ReceiptTypeName NOT IN ('PayableOffset', 'SecurityDeposit',  'EscrowRefund')
						   AND NOT (r.IsNonAccrual = 1 AND r.ReceivableType IN ('LoanPrincipal', 'LoanInterest'))
						   AND GainAmount_Amount = 0.00 AND r.ChargeoffExpenseAmount_LC = 0.00 AND RecoveryAmount_Amount = 0.00
					       AND nc.DoubtfulCollectability IS NOT NULL AND nc.DoubtfulCollectability = 1 
						   AND r.GLTransactionType IN ('OperatingLeaseAR', 'FloatRateAR')
					  THEN LeaseComponentAmountApplied_Amount
					  ELSE 0.00 
				 END) AS LeaseComponentCashPosted
		   , SUM(CASE
					  WHEN ReceiptClassification IN('Cash', 'NonAccrualNonDSL', 'DSL') AND ReceiptTypeName NOT IN ('PayableOffset', 'SecurityDeposit',  'EscrowRefund')
				 		  AND AssetComponentType = 'Finance' AND r.IsNonAccrual = 1 AND r.ReceivableType IN ('LoanPrincipal', 'LoanInterest')
				 		  AND RecoveryAmount_Amount = 0.00 AND GainAmount_Amount = 0.00 AND r.ChargeoffExpenseAmount_NLC = 0.00
						  AND (r.StartDate < co.ChargeOffDate OR co.ChargeOffDate IS NULL OR r.StartDate IS NULL)
					 THEN BookAmountApplied_Amount
					 WHEN ReceiptClassification IN('Cash', 'NonAccrualNonDSL', 'DSL') AND ReceiptTypeName NOT IN ('PayableOffset', 'SecurityDeposit',  'EscrowRefund')
						  AND GainAmount_Amount = 0.00 AND r.ChargeoffExpenseAmount_NLC = 0.00 AND RecoveryAmount_Amount = 0.00 AND (((r.StartDate < co.ChargeOffDate  OR co.ChargeOffDate IS NULL OR r.StartDate IS NULL)) OR (co.Id IS NOT NULL AND (r.GLTransactionType IN ('AssetSaleAR', 'PropertyTaxAR' , 'PropertyTaxEscrow', 'SecurityDeposit')OR r.IsFAS91 = 0 OR r.InvoiceComment IN ('Syndication Actual Proceeds','Syndication Scrape Receivable'))))
					 THEN NonLeaseComponentAmountApplied_Amount
					 ELSE 0.00 
				 END) AS FinanceComponentCashPosted
		   , SUM(CASE
					 WHEN (ReceiptClassification NOT IN('Cash', 'NonAccrualNonDSL', 'DSL') OR ReceiptTypeName IN ('PayableOffset', 'SecurityDeposit',  'EscrowRefund'))
				 		  AND AssetComponentType != 'Finance' AND r.IsNonAccrual = 1 AND r.ReceivableType IN ('LoanPrincipal', 'LoanInterest')
				 		  AND RecoveryAmount_Amount = 0.00 AND GainAmount_Amount = 0.00 AND r.ChargeoffExpenseAmount_LC = 0.00
						  AND (r.StartDate < co.ChargeOffDate OR co.ChargeOffDate IS NULL OR r.StartDate IS NULL)
					 THEN BookAmountApplied_Amount
					 WHEN (ReceiptClassification NOT IN('Cash', 'NonAccrualNonDSL', 'DSL') OR ReceiptTypeName IN ('PayableOffset', 'SecurityDeposit',  'EscrowRefund'))
						   AND GainAmount_Amount = 0.00 AND r.ChargeoffExpenseAmount_LC = 0.00 AND RecoveryAmount_Amount = 0.00 AND (((r.StartDate < co.ChargeOffDate  OR co.ChargeOffDate IS NULL OR r.StartDate IS NULL)) OR (co.Id IS NOT NULL AND (r.GLTransactionType IN ('AssetSaleAR', 'PropertyTaxAR' , 'PropertyTaxEscrow', 'SecurityDeposit') OR r.IsFAS91 = 0 OR r.InvoiceComment IN ('Syndication Actual Proceeds','Syndication Scrape Receivable'))))
						   AND ((nc.DoubtfulCollectability IS NOT NULL AND (nc.DoubtfulCollectability = 0 OR r.GLTransactionType NOT IN ('OperatingLeaseAR', 'FloatRateAR'))) OR nc.DoubtfulCollectability IS NULL)
					 THEN LeaseComponentAmountApplied_Amount
					 WHEN (ReceiptClassification NOT IN('Cash', 'NonAccrualNonDSL', 'DSL') OR ReceiptTypeName IN ('PayableOffset', 'SecurityDeposit',  'EscrowRefund'))
						   AND GainAmount_Amount = 0.00 AND r.ChargeoffExpenseAmount_LC = 0.00 AND RecoveryAmount_Amount = 0.00
						   AND nc.DoubtfulCollectability IS NOT NULL AND nc.DoubtfulCollectability = 1 
						   AND r.GLTransactionType IN ('OperatingLeaseAR', 'FloatRateAR')
					 THEN LeaseComponentAmountApplied_Amount
					 ELSE 0.00 
				 END) AS LeaseComponentNonCashPosted
		   , SUM(CASE
					 WHEN (ReceiptClassification NOT IN('Cash', 'NonAccrualNonDSL', 'DSL') OR ReceiptTypeName IN ('PayableOffset', 'SecurityDeposit',  'EscrowRefund'))
				 		  AND AssetComponentType = 'Finance' AND r.IsNonAccrual = 1 AND r.ReceivableType IN ('LoanPrincipal', 'LoanInterest')
				 		  AND RecoveryAmount_Amount = 0.00 AND GainAmount_Amount = 0.00 AND r.ChargeoffExpenseAmount_NLC = 0.00
						  AND (r.StartDate < co.ChargeOffDate OR co.ChargeOffDate IS NULL OR r.StartDate IS NULL)
					 THEN BookAmountApplied_Amount
					 WHEN (ReceiptClassification NOT IN('Cash', 'NonAccrualNonDSL', 'DSL') OR ReceiptTypeName IN ('PayableOffset', 'SecurityDeposit',  'EscrowRefund'))
						   AND GainAmount_Amount = 0.00 AND r.ChargeoffExpenseAmount_NLC = 0.00 AND RecoveryAmount_Amount = 0.00 AND (((r.StartDate < co.ChargeOffDate  OR co.ChargeOffDate IS NULL OR r.StartDate IS NULL)) OR (co.Id IS NOT NULL AND (r.GLTransactionType IN ('AssetSaleAR', 'PropertyTaxAR' , 'PropertyTaxEscrow', 'SecurityDeposit') OR r.IsFAS91 = 0 OR r.InvoiceComment IN ('Syndication Actual Proceeds','Syndication Scrape Receivable'))))
					 THEN NonLeaseComponentAmountApplied_Amount
					 ELSE 0.00 
				 END) AS FinanceComponentNonCashPosted
			 , SUM(CASE
					   WHEN nc.DoubtfulCollectability IS NOT NULL AND nc.DoubtfulCollectability = 1 AND r.GLTransactionType IN ('OperatingLeaseAR', 'FloatRateAR')
					   THEN 0.00
					   WHEN r.StartDate >= co.ChargeOffDate
							AND RecoveryAmount_Amount = 0.00 AND GainAmount_Amount = 0.00 AND r.ChargeoffExpenseAmount_LC = 0.00
							AND (ReceiptClassification IN('Cash', 'NonAccrualNonDSL', 'DSL') AND ReceiptTypeName NOT IN ('PayableOffset', 'SecurityDeposit',  'EscrowRefund'))
					   THEN LeaseComponentAmountApplied_Amount
					   ELSE 0.00
				   END) AS LeaseCashApplicationRecovery
			 , SUM(CASE
					   WHEN r.StartDate >= co.ChargeOffDate
							AND RecoveryAmount_Amount = 0.00 AND GainAmount_Amount = 0.00 AND r.ChargeoffExpenseAmount_NLC = 0.00
							AND (ReceiptClassification IN('Cash', 'NonAccrualNonDSL', 'DSL') AND ReceiptTypeName NOT IN ('PayableOffset', 'SecurityDeposit',  'EscrowRefund'))
					   THEN NonLeaseComponentAmountApplied_Amount
					   ELSE 0.00
				   END) AS FinanceCashApplicationRecovery
			, SUM(CASE
					  WHEN RecoveryAmount_LC != 0.00
						   AND (r.GLTransactionType NOT IN ('AssetSaleAR', 'PropertyTaxAR', 'PropertyTaxEscrow', 'SecurityDeposit') OR (r.IsFas91 IS NOT NULL AND r.IsFas91 = 1)
								OR (r.ReceivableType = 'Sundry' AND r.InvoiceComment NOT IN ('Syndication Actual Proceeds','Syndication Scrape Receivable')))
					  THEN RecoveryAmount_LC
					  ELSE 0.00
				  END) AS RecoveryAmount_LC
			, SUM(CASE
					  WHEN RecoveryAmount_NLC != 0.00
						   AND (r.GLTransactionType NOT IN ('AssetSaleAR', 'PropertyTaxAR', 'PropertyTaxEscrow', 'SecurityDeposit') OR (r.IsFas91 IS NOT NULL AND r.IsFas91 = 1)
								OR (r.ReceivableType = 'Sundry' AND r.InvoiceComment NOT IN ('Syndication Actual Proceeds','Syndication Scrape Receivable')))
					  THEN RecoveryAmount_NLC
					  ELSE 0.00
				  END) AS RecoveryAmount_NLC
			, SUM(CASE
					   WHEN GainAmount_LC != 0.00
							AND (r.GLTransactionType NOT IN ('AssetSaleAR', 'PropertyTaxAR' , 'PropertyTaxEscrow', 'SecurityDeposit') OR (r.IsFas91 IS NOT NULL AND r.IsFas91 = 1)
								  OR (r.ReceivableType = 'Sundry' AND r.InvoiceComment NOT IN ('Syndication Actual Proceeds','Syndication Scrape Receivable')))
					  THEN GainAmount_LC
				      ELSE 0.00
				  END) AS GainAmount_LC
			, SUM(CASE
					  WHEN GainAmount_NLC != 0.00
						   AND (r.GLTransactionType NOT IN ('AssetSaleAR', 'PropertyTaxAR' , 'PropertyTaxEscrow', 'SecurityDeposit') OR (r.IsFas91 IS NOT NULL AND r.IsFas91 = 1)
								 OR (r.ReceivableType = 'Sundry' AND r.InvoiceComment NOT IN ('Syndication Actual Proceeds','Syndication Scrape Receivable')))
					  THEN GainAmount_NLC
					  ELSE 0.00
				  END) AS GainAmount_NLC
			, SUM(CASE
					   WHEN r.ReceivableType IN ('LoanPrincipal', 'LoanInterest')
						   AND r.IsNonAccrual = 1 AND r.RecoveryAmount_Amount = 0.00 AND r.GainAmount_Amount = 0.00 AND r.ChargeoffExpenseAmount_LC = 0.00
						   AND (r.StartDate < co.ChargeOffDate OR co.ChargeOffDate IS NULL OR r.StartDate IS NULL)
					  THEN r.BookAmountApplied_Amount
					  WHEN r.GLTransactionType NOT IN ('AssetSaleAR', 'PropertyTaxAR' , 'PropertyTaxEscrow', 'SecurityDeposit')
						   AND co.Id IS NOT NULL
						   AND RecoveryAmount_Amount = 0.00 AND GainAmount_Amount = 0.00 AND r.ChargeoffExpenseAmount_LC = 0.00
						   AND (r.StartDate < co.ChargeOffDate OR (r.StartDate IS NULL AND r.DueDate < co.ChargeOffDate))
						   AND ((nc.DoubtfulCollectability IS NOT NULL AND (nc.DoubtfulCollectability = 0 OR r.GLTransactionType NOT IN ('OperatingLeaseAR', 'FloatRateAR'))) OR nc.DoubtfulCollectability IS NULL)
					  THEN LeaseComponentAmountApplied_Amount
					  WHEN r.GLTransactionType IN ('OperatingLeaseAR', 'FloatRateAR')
						   AND co.Id IS NOT NULL
						   AND r.RecoveryAmount_Amount = 0.00 AND r.GainAmount_Amount = 0.00  AND r.ChargeoffExpenseAmount_LC = 0.00
						   AND nc.DoubtfulCollectability IS NOT NULL AND nc.DoubtfulCollectability = 1
					  THEN r.LeaseComponentAmountApplied_Amount
					  ELSE 0.00
				   END)	AS LeaseAmountApplied
			, SUM(CASE
					   WHEN r.ReceivableType IN ('LoanPrincipal', 'LoanInterest')
						   AND r.IsNonAccrual = 1 AND r.RecoveryAmount_Amount = 0.00 AND r.GainAmount_Amount = 0.00 AND r.ChargeoffExpenseAmount_LC = 0.00
						   AND (r.StartDate < co.ChargeOffDate OR co.ChargeOffDate IS NULL OR r.StartDate IS NULL)
					  THEN 0.00
					  WHEN r.GLTransactionType NOT IN ('AssetSaleAR', 'PropertyTaxAR' , 'PropertyTaxEscrow', 'SecurityDeposit')
						   AND co.Id IS NOT NULL
						   AND RecoveryAmount_Amount = 0.00 AND GainAmount_Amount = 0.00 AND r.ChargeoffExpenseAmount_NLC = 0.00
						   AND (r.StartDate < co.ChargeOffDate OR (r.StartDate IS NULL AND r.DueDate < co.ChargeOffDate))
					  THEN NonLeaseComponentAmountApplied_Amount
					  ELSE 0.00
				   END)	AS FinanceAmountApplied
			, SUM(CASE
					  WHEN r.ReceivableType = 'Sundry'
						   AND co.Id IS NOT NULL
						   AND RecoveryAmount_Amount = 0.00 AND GainAmount_Amount = 0.00 AND r.ChargeoffExpenseAmount_LC = 0.00
						   AND r.InvoiceComment  IN ('Syndication Scrape Receivable', 'Syndication Actual Proceeds')
						   AND (r.StartDate < co.ChargeOffDate OR (r.StartDate IS NULL AND r.DueDate < co.ChargeOffDate))
					  THEN LeaseComponentAmountApplied_Amount
					  ELSE 0.00
				   END) AS SundryAmount
			, SUM(CASE
					  WHEN co.Id IS NOT NULL
						   AND RecoveryAmount_Amount = 0.00 AND GainAmount_Amount = 0.00 AND r.ChargeoffExpenseAmount_LC = 0.00
						   AND r.IsFAS91 IS NOT NULL AND r.IsFAS91 = 0
						   AND (r.StartDate < co.ChargeOffDate OR (r.StartDate IS NULL AND r.DueDate < co.ChargeOffDate))
					  THEN LeaseComponentAmountApplied_Amount
					  ELSE 0.00
				   END) AS BlendedItemAmount
			, SUM(CASE
					  WHEN co.Id IS NOT NULL
						   AND r.StartDate >= co.ChargeOffDate
						   AND r.ReceivableType IN ('LoanPrincipal', 'LoanInterest')
						   AND RecoveryAmount_Amount = 0.00 AND GainAmount_Amount = 0.00
					  THEN BookAmountApplied_Amount
					  ELSE 0.00
				   END) AS LoanBookAmountApplied
			, SUM(CASE
					  WHEN r.accountingTreatment IN('CashBased', 'MemoBased')
						   AND (ReceiptClassification NOT IN('Cash', 'NonAccrualNonDSL', 'DSL') AND ReceiptTypeName NOT IN ('PayableOffset', 'SecurityDeposit',  'EscrowRefund'))
						   AND GainAmount_Amount = 0.00 AND RecoveryAmount_Amount = 0.00 AND r.ChargeoffExpenseAmount_LC = 0.00 AND (((r.StartDate < co.ChargeOffDate  OR co.ChargeOffDate IS NULL OR r.StartDate IS NULL)) OR (co.Id IS NOT NULL AND (r.GLTransactionType IN ('AssetSaleAR', 'PropertyTaxAR' , 'PropertyTaxEscrow', 'SecurityDeposit') OR r.IsFAS91 = 0 OR r.InvoiceComment IN ('Syndication Actual Proceeds','Syndication Scrape Receivable'))))
					  THEN LeaseComponentAmountApplied_Amount
				      ELSE 0.00
					END) AS LeaseComponentNonCashAmount
			, SUM(CASE
					  WHEN r.accountingTreatment IN('CashBased', 'MemoBased')
						   AND (ReceiptClassification NOT IN('Cash', 'NonAccrualNonDSL', 'DSL') AND ReceiptTypeName NOT IN ('PayableOffset', 'SecurityDeposit',  'EscrowRefund'))
						   AND GainAmount_Amount = 0.00 AND RecoveryAmount_Amount = 0.00 AND r.ChargeoffExpenseAmount_NLC = 0.00 AND (((r.StartDate < co.ChargeOffDate  OR co.ChargeOffDate IS NULL OR r.StartDate IS NULL)) OR (co.Id IS NOT NULL AND (r.GLTransactionType IN ('AssetSaleAR', 'PropertyTaxAR' , 'PropertyTaxEscrow', 'SecurityDeposit') OR r.IsFAS91 = 0 OR r.InvoiceComment IN ('Syndication Actual Proceeds','Syndication Scrape Receivable'))))
					  THEN NonLeaseComponentAmountApplied_Amount
				      ELSE 0.00
					END) AS NonLeaseComponentNonCashAmount
			, SUM(r.ChargeoffExpenseAmount) AS ChargeoffExpenseAmount
			, SUM(ISNULL(r.ChargeoffExpenseAmount_LC, 0.00)) AS ChargeoffExpenseLCAmount
			, SUM(ISNULL(r.ChargeoffExpenseAmount_NLC, 0.00)) AS ChargeoffExpenseNLCAmount
	FROM #ReceiptApplicationReceivableDetails r
		 LEFT JOIN #ChargeOff co ON r.EntityId = co.Id AND r.EntityType = 'CT'
		 LEFT JOIN #NonAccrualDetails nc ON r.EntityId = nc.EntityId AND r.EntityType = 'CT'
	WHERE ReceiptStatus IN('Posted', 'Completed')
	GROUP BY r.EntityId
		   , r.GLContractType
		   , r.GLTemplateId
		   , CASE WHEN r.EntityType = 'CU' THEN r.LegalEntityId ELSE NULL END

	CREATE NONCLUSTERED INDEX IX_Id ON #ReceiptDetails(EntityId, GLContractType, GLTemplateId, LegalEntityId);

	UPDATE rgl SET 
					LeaseComponentGLPostedAmount -= t.LeaseComponentGLPosted
                  , NonLeaseComponentGLPostedAmount -= t.FinanceComponentGLPosted
	FROM #ReceivableGLPostedAmount rgl
			INNER JOIN
	(
		SELECT r.EntityId
			 , r.GLContractType AS EntityType
			 , r.GLTemplateId
			 , ABS(SUM(CASE WHEN r.StartDate < co.ChargeoffDate OR r.StartDate IS NULL
						THEN ISNULL(r.ChargeoffExpenseAmount_LC, 0.00)
						ELSE 0.00 
				   END)) AS LeaseComponentGLPosted
			 , ABS(SUM(CASE WHEN r.StartDate < co.ChargeoffDate OR r.StartDate IS NULL
						THEN ISNULL(r.ChargeoffExpenseAmount_NLC, 0.00)
						ELSE 0.00 
				   END)) AS FinanceComponentGLPosted
		FROM #ReceiptApplicationReceivableDetails r
			 INNER JOIN #ChargeOff co ON r.EntityId = co.Id
										 AND r.EntityType = 'CT'
		WHERE ReceiptStatus IN('Reversed')
			  AND r.IsRecovery IS NOT NULL AND r.IsRecovery = 0
			    AND ((r.ReceivableType IN ('CapitalLeaseRental', 'LeaseFloatRateAdj', 'OperatingLeaseRental', 'OverTermRental', 'Supplemental', 'LoanInterest', 'LoanPrincipal') AND r.IsGLPosted = 1)
					 OR (r.IsGLPosted = 0 AND r.ReceivableType NOT IN ('CapitalLeaseRental', 'LeaseFloatRateAdj', 'OperatingLeaseRental', 'OverTermRental', 'Supplemental', 'LoanInterest', 'LoanPrincipal', 'PropertyTax', 'PropertyTaxEscrow', 'AssetSale'))
					 OR (r.AccountingTreatment = 'CashBased' AND r.ReceivableType = 'AssetSale')
					 OR (r.IsFas91ForExpense = 1))
		GROUP BY r.EntityId
				, r.GLContractType
				, r.GLTemplateId
	) AS t ON t.EntityId = rgl.EntityId
				AND t.EntityType = rgl.EntityType
				AND t.GLTemplateId = rgl.GLTemplateId;
	

	UPDATE rgl SET 
				   LeaseComponentCashPosted -= t.LeaseComponentCashPosted
				 , FinanceComponentCashPosted -= t.FinanceComponentCashPosted
				 , LeaseComponentNonCashPosted -= t.LeaseComponentNonCashPosted
				 , FinanceComponentNonCashPosted -= t.FinanceComponentNonCashPosted
	FROM #ReceiptGLPosting rgl
		 INNER JOIN
	(
		SELECT r.EntityId
			 , r.GLContractType AS EntityType
			 , r.GLTemplateId
			 , SUM(CASE WHEN ReceiptClassification IN('Cash', 'NonAccrualNonDSL', 'DSL') AND ReceiptTypeName NOT IN ('PayableOffset', 'SecurityDeposit',  'EscrowRefund')
						     AND (r.StartDate < co.ChargeoffDate OR r.StartDate IS NULL)
						THEN ISNULL(r.ChargeoffExpenseAmount_LC, 0.00)
						ELSE 0.00
				   END) AS LeaseComponentCashPosted
			 , SUM(CASE WHEN ReceiptClassification IN('Cash', 'NonAccrualNonDSL', 'DSL') AND ReceiptTypeName NOT IN ('PayableOffset', 'SecurityDeposit',  'EscrowRefund')
						     AND (r.StartDate < co.ChargeoffDate OR r.StartDate IS NULL)
						THEN ISNULL(r.ChargeoffExpenseAmount_NLC, 0.00)
						ELSE 0.00
				   END) AS FinanceComponentCashPosted
			 , SUM(CASE WHEN (ReceiptClassification NOT IN('Cash', 'NonAccrualNonDSL', 'DSL') OR ReceiptTypeName IN ('PayableOffset', 'SecurityDeposit',  'EscrowRefund'))
						     AND (r.StartDate < co.ChargeoffDate OR r.StartDate IS NULL)
						THEN ISNULL(r.ChargeoffExpenseAmount_LC, 0.00)
						ELSE 0.00
				   END) AS LeaseComponentNonCashPosted
			 , SUM(CASE WHEN (ReceiptClassification NOT IN('Cash', 'NonAccrualNonDSL', 'DSL') OR ReceiptTypeName IN ('PayableOffset', 'SecurityDeposit',  'EscrowRefund'))
						     AND (r.StartDate < co.ChargeoffDate OR r.StartDate IS NULL)
						THEN ISNULL(r.ChargeoffExpenseAmount_NLC, 0.00)
						ELSE 0.00
				   END) AS FinanceComponentNonCashPosted
		FROM #ReceiptApplicationReceivableDetails r
			 INNER JOIN #ChargeOff co ON r.EntityId = co.Id
										AND r.EntityType = 'CT'
		WHERE ReceiptStatus IN('Reversed')
			  AND r.IsRecovery IS NOT NULL AND r.IsRecovery = 0
			  AND ((r.ReceivableType IN ('CapitalLeaseRental', 'LeaseFloatRateAdj', 'OperatingLeaseRental', 'OverTermRental', 'Supplemental', 'LoanInterest', 'LoanPrincipal') AND r.IsGLPosted = 1)
					 OR (r.IsGLPosted = 0 AND r.ReceivableType NOT IN ('CapitalLeaseRental', 'LeaseFloatRateAdj', 'OperatingLeaseRental', 'OverTermRental', 'Supplemental', 'LoanInterest', 'LoanPrincipal', 'PropertyTax', 'PropertyTaxEscrow', 'AssetSale'))
					 OR (r.AccountingTreatment = 'CashBased' AND r.ReceivableType = 'AssetSale')
					 OR (r.IsFas91ForExpense = 1))
		GROUP BY r.EntityId
			   , r.GLContractType
			   , r.GLTemplateId
	) AS t ON t.EntityId = rgl.EntityId
			  AND t.EntityType = rgl.EntityType
			  AND t.GLTemplateId = rgl.MatchingGLTemplateId;

	END 

	UPDATE #ReceiptDetails SET RecoveryAmount_LC += IIF(LoanBookAmountApplied != 0.00, LoanBookAmountApplied, LeaseCashApplicationRecovery)

	UPDATE #ReceiptDetails SET RecoveryAmount_NLC += FinanceCashApplicationRecovery
 
	MERGE #ReceivableGLPostedAmount AS receivable
	USING (SELECT * FROM #ReceiptGLPosting) AS receipt
	ON(receivable.GLTemplateId = receipt.MatchingGLTemplateId
	AND receivable.EntityId = receipt.EntityId
	AND receivable.EntityType = receipt.EntityType
	AND (receivable.LegalEntityId = receipt.LegalEntityId AND receivable.EntityType = 'Customer' OR receivable.EntityType != 'Customer'))
	WHEN MATCHED
	THEN UPDATE SET 
					  LeaseComponentOSARAmount -= receipt.LeaseComponentOSARAmount
					, NonLeaseComponentOSARAmount -= receipt.NonLeaseComponentOSARAmount
					, LeaseComponentPrepaid = ABS(receipt.LeaseComponentPrepaid - receivable.LeaseComponentPrepaid)
					, NonLeaseComponentPrepaid = ABS(receipt.NonLeaseComponentPrepaid - receivable.NonLeaseComponentPrepaid)
	WHEN NOT MATCHED
		THEN
		INSERT(EntityId, EntityType, LegalEntityId,  GLTemplateId, LeaseComponentGLPostedAmount, NonLeaseComponentGLPostedAmount, LeaseComponentOSARAmount, NonLeaseComponentOSARAmount, LeaseComponentPrepaid, NonLeaseComponentPrepaid)
		VALUES(receipt.EntityId, receipt.EntityType, receipt.LegalEntityId, receipt.MatchingGLTemplateId, 0.00, 0.00, receipt.LeaseComponentOSARAmount, receipt.NonLeaseComponentOSARAmount, receipt.LeaseComponentPrepaid, receipt.NonLeaseComponentPrepaid);
	 
	UPDATE ra SET 
				  GLPostedLeaseComponent+=GLPostedFinanceComponent
				, GLPostedFinanceComponent = 0.00
				, GLPostedLeaseComponentOSAR+=GLPostedFinanceComponentOSAR
				, GLPostedFinanceComponentOSAR = 0.00
				, GLPostedLeaseComponentPrepaid+=GLPostedFinanceComponentPrepaid
				, GLPostedFinanceComponentPrepaid = 0.00
				, LeaseComponentTotalAmount += NonLeaseComponentTotalAmount
				, NonLeaseComponentTotalAmount = 0.00
				, BalanceAmount_LC += BalanceAmount_NLC
				, BalanceAmount_NLC = 0.00
	FROM #ReceivableAmount ra
	INNER JOIN GLTemplates gt ON gt.Id = ra.GLTemplateId
	INNER JOIN GLTransactionTypes GTT ON gt.GLTransactionTypeId = GTT.Id
	WHERE GTT.Name IN ('FloatRateAR', 'OTPAR', 'PayoffBuyoutAR', 'Supplemental', 'LoanPrincipal', 'LoanInterest');


	UPDATE rd SET 
				  LeaseComponentCashPosted += FinanceComponentCashPosted
				, FinanceComponentCashPosted = 0.00
				, LeaseComponentNonCashPosted += FinanceComponentNonCashPosted
				, FinanceComponentNonCashPosted = 0.00
				, RecoveryAmount_LC += RecoveryAmount_NLC
				, RecoveryAmount_NLC = 0.00
				, GainAmount_LC += GainAmount_NLC
				, GainAmount_NLC = 0.00
				, ChargeoffExpenseLCAmount += ChargeoffExpenseNLCAmount
				, ChargeoffExpenseNLCAmount = 0.00
				, LeaseComponentNonCashAmount += NonLeaseComponentNonCashAmount
				, NonLeaseComponentNonCashAmount = 0.00
	FROM #ReceiptDetails rd
		 INNER JOIN GLTemplates gt ON gt.Id = rd.GLTemplateId
		 INNER JOIN GLTransactionTypes GTT ON gt.GLTransactionTypeId = GTT.Id
	WHERE GTT.Name IN('FloatRateAR', 'OTPAR', 'PayoffBuyoutAR', 'Supplemental', 'LoanPrincipal', 'LoanInterest');

	UPDATE #ReceivableAmount
	SET GLPostedLeaseComponent = CASE 
									 WHEN ra.GLPostedLeaseComponent - ISNULL(rd.LeaseComponentNonCashAmount , 0.00) != rgl.LeaseComponentGLPostedAmount AND gtt.Name NOT IN ('FloatRateAR', 'OTPAR', 'PayoffBuyoutAR', 'Supplemental', 'LoanPrincipal', 'LoanInterest')
									 THEN ISNULL(rd.LeaseAmountApplied, 0.00) + ISNULL(rd.SundryAmount, 0.00) + ISNULL(rd.BlendedItemAmount , 0.00)
									 WHEN ra.GLPostedLeaseComponent - ISNULL(rd.LeaseComponentNonCashAmount , 0.00) != rgl.LeaseComponentGLPostedAmount AND gtt.Name IN ('FloatRateAR', 'OTPAR', 'PayoffBuyoutAR', 'Supplemental', 'LoanPrincipal', 'LoanInterest')
									 THEN ISNULL(rd.LeaseAmountApplied, 0.00) + ISNULL(rd.FinanceAmountApplied, 0.00) + ISNULL(rd.SundryAmount, 0.00) + ISNULL(rd.BlendedItemAmount , 0.00)
									 ELSE GLPostedLeaseComponent
									 END, 
	GLPostedFinanceComponent =  CASE
									WHEN ABS(ABS(ra.GLPostedFinanceComponent) - ABS(ISNULL(rd.NonLeaseComponentNonCashAmount, 0.00))) != rgl.NonLeaseComponentGLPostedAmount AND gtt.Name NOT IN ('FloatRateAR', 'OTPAR', 'PayoffBuyoutAR', 'Supplemental', 'LoanPrincipal', 'LoanInterest')
									THEN ISNULL(rd.FinanceAmountApplied, 0.00) 
									ELSE GLPostedFinanceComponent
									END
	FROM #ReceivableAmount ra
	INNER JOIN #ChargeOff co ON ra.EntityId = co.Id
	INNER JOIN GLTemplates gt ON gt.Id = ra.GLTemplateId
	INNER JOIN GLTransactionTypes gtt ON gt.GLTransactionTypeId = gtt.Id
	LEFT JOIN #ReceiptDetails rd ON ra.EntityId = rd.EntityId
									 AND ra.EntityType = rd.GLContractType
									 AND ra.GLTemplateId = rd.GLTemplateId
	INNER JOIN #ReceivableGLPostedAmount rgl ON ra.EntityId = rgl.EntityId
												AND ra.EntityType = rgl.EntityType
												AND ra.GLTemplateId = rgl.GLTemplateId
   WHERE gtt.Name NOT IN ('InterimRentAR', 'LeaseInterimInterestAR', 'NonRentalAR')

   

SELECT *, CASE 
			  WHEN  
			  [LeaseComponentReceivableGLPostedAmount_Difference] != 0.00
              OR [NonLeaseComponentReceivableGLPostedAmount_Difference] != 0.00
              OR [LeaseComponentReceivableOSAR_Difference] != 0.00
              OR [NonLeaseComponentReceivableOSAR_Difference] != 0.00
              OR [LeaseComponentReceivablePrepaid_Difference] != 0.00
              OR [NonLeaseComponentReceivablePrepaid_Difference] != 0.00
              OR [LeaseComponentTotalCashPaid_Difference] != 0.00
              OR [LeaseComponentTotalNonCashPaid_Difference] != 0.00
              OR [NonLeaseComponentTotalCashPaid_Difference] != 0.00
              OR [NonLeaseComponentTotalNonCashPaid_Difference] != 0.00
			  OR [BalanceAmount_LC_Difference] != 0.00
			  OR [BalanceAmount_NLC_Difference] != 0.00
			  OR [TotalReceivableAmountVsLCAndNLC] != 0.00
           THEN 'Problem Record'
           ELSE 'Not Problem Record'
       END AS [Result]
INTO #ResultList
FROM
(
	SELECT ra.EntityType
		 , ra.EntityId
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
		 , ISNULL(ra.TotalAmount, 0.00) AS TotalReceivableAmount
		 , ISNULL(ra.LeaseComponentTotalAmount, 0.00) AS LeaseComponentReceivableAmount
		 , ISNULL(ra.NonLeaseComponentTotalAmount, 0.00) AS NonLeaseComponentReceivableAmount
		 , ISNULL(ra.TotalAmount, 0.00) - (ISNULL(ra.LeaseComponentTotalAmount, 0.00) + ISNULL(ra.NonLeaseComponentTotalAmount, 0.00)) AS [TotalReceivableAmountVsLCAndNLC]
		 , IIF(ISNULL(rd.LeaseComponentNonCashAmount , 0.00) > 0, ABS(ISNULL(ra.GLPostedLeaseComponent, 0.00)) - ISNULL(rd.LeaseComponentNonCashAmount , 0.00) ,ISNULL(ra.GLPostedLeaseComponent, 0.00))  [LeaseComponentReceivableGLPostedAmount_Table]
		 , ISNULL(rgl.LeaseComponentGLPostedAmount, 0.00) [LeaseComponentReceivableGLPostedAmount_GL]
		 , ABS(ABS(ISNULL(ra.GLPostedLeaseComponent, 0.00))  - ABS(ISNULL(rd.LeaseComponentNonCashAmount , 0.00))) - ABS(ISNULL(rgl.LeaseComponentGLPostedAmount, 0.00)) [LeaseComponentReceivableGLPostedAmount_Difference]
		 , ABS(ABS(ISNULL(ra.GLPostedFinanceComponent, 0.00)) - ABS(ISNULL(rd.NonLeaseComponentNonCashAmount, 0.00))) [NonLeaseComponentReceivableGLPostedAmount_Table]
		 , ISNULL(rgl.NonLeaseComponentGLPostedAmount, 0.00) [NonLeaseComponentReceivableGLPostedAmount_GL]
		 , ABS(ABS(ISNULL(ra.GLPostedFinanceComponent, 0.00)) - ABS(ISNULL(rd.NonLeaseComponentNonCashAmount, 0.00))) - ABS(ISNULL(rgl.NonLeaseComponentGLPostedAmount, 0.00)) [NonLeaseComponentReceivableGLPostedAmount_Difference]
		 , ISNULL(rd.LeaseComponentCashPosted, 0.00) AS [LeaseComponentTotalCashPaid_Table]
		 , ISNULL(receiptGL.LeaseComponentCashPosted, 0.00) AS [LeaseComponentTotalCashPaid_GL]
		 , ABS(ISNULL(rd.LeaseComponentCashPosted, 0.00)) - ABS(ISNULL(receiptGL.LeaseComponentCashPosted, 0.00)) AS [LeaseComponentTotalCashPaid_Difference]
		 , ABS(ABS(ISNULL(rd.LeaseComponentNonCashPosted, 0.00)) - ABS(ISNULL(rd.LeaseComponentNonCashAmount , 0.00))) AS [LeaseComponentTotalNonCashPaid_Table]
		 , ISNULL(receiptGL.LeaseComponentNonCashPosted, 0.00) AS [LeaseComponentTotalNonCashPaid_GL]
		 , ABS(ABS(ISNULL(rd.LeaseComponentNonCashPosted, 0.00)) - ABS(ISNULL(rd.LeaseComponentNonCashAmount , 0.00))) - ABS(ISNULL(receiptGL.LeaseComponentNonCashPosted, 0.00)) AS [LeaseComponentTotalNonCashPaid_Difference]
		 , ISNULL(rd.FinanceComponentCashPosted, 0.00) AS [NonLeaseComponentTotalCashPaid_Table]
		 , ISNULL(receiptGL.FinanceComponentCashPosted, 0.00) AS [NonLeaseComponentTotalCashPaid_GL]
		 , ABS(ISNULL(rd.FinanceComponentCashPosted, 0.00)) - ABS(ISNULL(receiptGL.FinanceComponentCashPosted, 0.00)) AS [NonLeaseComponentTotalCashPaid_Difference]
		 , ABS(ABS(ISNULL(rd.FinanceComponentNonCashPosted, 0.00)) - ABS(ISNULL(rd.NonLeaseComponentNonCashAmount , 0.00))) AS [NonLeaseComponentTotalNonCashPaid_Table]
		 , ISNULL(receiptGL.FinanceComponentNonCashPosted, 0.00) AS [NonLeaseComponentTotalNonCashPaid_GL]
		 , ABS(ISNULL(rd.FinanceComponentNonCashPosted, 0.00) - ABS(ISNULL(rd.NonLeaseComponentNonCashAmount , 0.00))) - ABS(ISNULL(receiptGL.FinanceComponentNonCashPosted, 0.00)) AS [NonLeaseComponentTotalNonCashPaid_Difference]
		 , ABS(ISNULL(ra.GLPostedLeaseComponentOSAR, 0.00))  [LeaseComponentReceivableOSAR_Table]
		 , ISNULL(rgl.LeaseComponentOSARAmount, 0.00) [LeaseComponentReceivableOSAR_GL]
		 , ABS(ISNULL(ra.GLPostedLeaseComponentOSAR, 0.00)) - ABS(ISNULL(rgl.LeaseComponentOSARAmount, 0.00)) [LeaseComponentReceivableOSAR_Difference]
		 , ISNULL(ra.GLPostedFinanceComponentOSAR, 0.00) [NonLeaseComponentReceivableOSAR_Table]
		 , ISNULL(rgl.NonLeaseComponentOSARAmount, 0.00) [NonLeaseComponentReceivableOSAR_GL]
		 , ABS(ISNULL(ra.GLPostedFinanceComponentOSAR, 0.00)) - ABS(ISNULL(rgl.NonLeaseComponentOSARAmount, 0.00)) [NonLeaseComponentReceivableOSAR_Difference]
		 , ABS(ISNULL(ra.GLPostedLeaseComponentPrepaid, 0.00)) [LeaseComponentReceivablePrepaid_Table]
		 , ABS(ISNULL(rgl.LeaseComponentPrepaid, 0.00)) [LeaseComponentReceivablePrepaid_GL]
		 , ABS(ISNULL(ra.GLPostedLeaseComponentPrepaid, 0.00)) - ABS(ISNULL(rgl.LeaseComponentPrepaid, 0.00)) [LeaseComponentReceivablePrepaid_Difference]
		 , ABS(ISNULL(ra.GLPostedFinanceComponentPrepaid, 0.00)) [NonLeaseComponentReceivablePrepaid_Table]
		 , ISNULL(rgl.NonLeaseComponentPrepaid, 0.00) [NonLeaseComponentReceivablePrepaid_GL]
		 , ABS(ISNULL(ra.GLPostedFinanceComponentPrepaid, 0.00)) - ABS(ISNULL(rgl.NonLeaseComponentPrepaid, 0.00)) [NonLeaseComponentReceivablePrepaid_Difference]
		 , ISNULL(rd.RecoveryAmount_LC, 0.00) + ISNULL(rd.ChargeoffExpenseLCAmount, 0.00) AS RecoveryAmount_LC
		 , ISNULL(rd.RecoveryAmount_NLC, 0.00) + ISNULL(rd.ChargeoffExpenseNLCAmount, 0.00) AS RecoveryAmount_NLC
		 , ISNULL(rd.GainAmount_LC, 0.00) AS GainAmount_LC
		 , ISNULL(rd.GainAmount_NLC, 0.00) AS GainAmount_NLC
		 , IIF(ISNULL(ra.BookBalanceAmount, 0.00) != 0.00, ISNULL(ra.BookBalanceAmount, 0.00), ISNULL(ra.BalanceAmount_LC, 0.00)) AS BalanceAmount_LC_Table
		 , ISNULL(ra.LeaseComponentTotalAmount, 0.00) - ISNULL(receiptGL.LeaseComponentCashPosted, 0.00) - ISNULL(receiptGL.LeaseComponentNonCashPosted, 0.00) - (ISNULL(rd.RecoveryAmount_LC, 0.00) + ISNULL(rd.ChargeoffExpenseLCAmount, 0.00)) - ISNULL(rd.GainAmount_LC, 0.00) - ISNULL(rd.LeaseComponentNonCashAmount, 0.00) AS [BalanceAmount_LC_Calculation]
		 , ABS(IIF(ISNULL(ra.BookBalanceAmount, 0.00) != 0.00, ISNULL(ra.BookBalanceAmount, 0.00), ISNULL(ra.BalanceAmount_LC, 0.00))) - ABS(ISNULL(ra.LeaseComponentTotalAmount, 0.00) - ISNULL(receiptGL.LeaseComponentCashPosted, 0.00) - ISNULL(receiptGL.LeaseComponentNonCashPosted, 0.00) - (ISNULL(rd.RecoveryAmount_LC, 0.00) + ISNULL(rd.ChargeoffExpenseLCAmount, 0.00)) - ISNULL(rd.GainAmount_LC, 0.00) - ISNULL(rd.LeaseComponentNonCashAmount, 0.00)) AS [BalanceAmount_LC_Difference]		 
		 , ISNULL(ra.BalanceAmount_NLC, 0.00) AS BalanceAmount_NLC_Table
		 , ISNULL(ra.NonLeaseComponentTotalAmount, 0.00) - ISNULL(receiptGL.FinanceComponentCashPosted, 0.00) - ISNULL(receiptGL.FinanceComponentNonCashPosted, 0.00) - (ISNULL(rd.RecoveryAmount_NLC, 0.00) + ISNULL(rd.ChargeoffExpenseNLCAmount, 0.00))  - ISNULL(rd.GainAmount_NLC, 0.00) - ISNULL(rd.NonLeaseComponentNonCashAmount, 0.00) AS [BalanceAmount_NLC_Calculation]
		 , ABS(ISNULL(ra.BalanceAmount_NLC, 0.00)) -   ABS(ISNULL(ra.NonLeaseComponentTotalAmount, 0.00) - ISNULL(receiptGL.FinanceComponentCashPosted, 0.00) - ISNULL(receiptGL.FinanceComponentNonCashPosted, 0.00) - (ISNULL(rd.RecoveryAmount_NLC, 0.00) + ISNULL(rd.ChargeoffExpenseNLCAmount, 0.00)) - ISNULL(rd.GainAmount_NLC, 0.00) - ISNULL(rd.NonLeaseComponentNonCashAmount, 0.00)) AS [BalanceAmount_NLC_Difference]
	FROM #ReceivableAmount ra
		 LEFT JOIN GLTemplates gtt ON gtt.Id = ra.GLTemplateId
		 LEFT JOIN #ReceivableGLPostedAmount rgl ON ra.EntityId = rgl.EntityId
													AND ra.EntityType = rgl.EntityType
													AND ra.GLTemplateId = rgl.GLTemplateId
													 AND (ra.EntityType = 'Customer' AND rgl.LegalEntityId = ra.LegalEntityId OR ra.EntityType != 'Customer')
		 LEFT JOIN #ReceiptDetails rd ON ra.EntityId = rd.EntityId
										 AND ra.EntityType = rd.GLContractType
										 AND ra.GLTemplateId = rd.GLTemplateId
										 AND (ra.EntityType = 'Customer' AND rd.LegalEntityId = ra.LegalEntityId OR ra.EntityType != 'Customer')
		 LEFT JOIN #ReceiptGLPosting receiptGL ON ra.EntityId = receiptGL.EntityId
										 AND ra.EntityType = receiptGL.EntityType
										 AND ra.GLTemplateId = receiptGL.MatchingGLTemplateId
										 AND (ra.EntityType = 'Customer' AND receiptGL.LegalEntityId = ra.LegalEntityId OR ra.EntityType != 'Customer')
		 LEFT JOIN #DistinctContracts dc ON ra.EntityId = dc.EntityId
										 AND ra.EntityType = dc.GLContractType
										 AND ra.GLTemplateId = dc.GLTemplateId
										 AND (ra.EntityType = 'Customer' AND dc.LegalEntityId = ra.LegalEntityId OR ra.EntityType != 'Customer')
		LEFT JOIN LegalEntities le ON le.Id = dc.LegalEntityId
		LEFT JOIN #Syndications sy ON sy.Id = ra.EntityId AND ra.EntityType = 'Contract') AS t;

		CREATE NONCLUSTERED INDEX IX_Id ON #ResultList(EntityId, EntityType);
	 
		SELECT name AS Name, 0 AS Count, CAST (0 AS BIT) AS IsProcessed, CAST('' AS NVARCHAR(max)) AS Label
		INTO #OwnedReceivableSummary
		FROM tempdb.sys.columns
		WHERE object_id = OBJECT_ID('tempdb..#ResultList')
		AND (Name LIKE '%Difference' OR Name LIKE '%Vs%');


		DECLARE @query NVARCHAR(MAX);
		DECLARE @TableName NVARCHAR(max);
		WHILE EXISTS (SELECT 1 FROM #OwnedReceivableSummary WHERE IsProcessed = 0)
		BEGIN
		SELECT TOP 1 @TableName = Name FROM #OwnedReceivableSummary WHERE IsProcessed = 0

		SET @query = 'UPDATE #OwnedReceivableSummary SET Count = (SELECT COUNT(*) FROM #ResultList WHERE ' + @TableName+ ' != 0.00), IsProcessed = 1
					  WHERE Name = '''+ @TableName+''' ;'
		EXEC (@query)
		END

		UPDATE #OwnedReceivableSummary SET Label = CASE 
													   WHEN Name = 'TotalReceivableAmountVsLCAndNLC'
													   THEN '1_Total Receivable Amount Vs LC & NLC Amount'
													   WHEN Name = 'LeaseComponentReceivableGLPostedAmount_Difference'
													   THEN '2_Lease Component : Receivable GL Posted Amount_Difference'
													   WHEN Name = 'NonLeaseComponentReceivableGLPostedAmount_Difference'
													   THEN '3_Non Lease Component : Receivable GL Posted Amount_Difference'
													   WHEN Name = 'LeaseComponentTotalCashPaid_Difference'
													   THEN '4_Lease Component - Total Paid_Difference'
													   WHEN Name = 'LeaseComponentTotalNonCashPaid_Difference'
													   THEN '5_Lease Component - Total Non-Cash_Difference'
													   WHEN Name = 'NonLeaseComponentTotalCashPaid_Difference'
													   THEN '6_Non Lease Component - Total Paid_Difference'
													   WHEN Name = 'NonLeaseComponentTotalNonCashPaid_Difference'
													   THEN '7_Non Lease Component - Total Non-Cash_Difference'
													   WHEN Name = 'LeaseComponentReceivableOSAR_Difference'
													   THEN '8_Lease Component Receivables - OSAR_Difference'
													   WHEN Name = 'NonLeaseComponentReceivableOSAR_Difference'
													   THEN '9_Non Lease Component Receivables - OSAR_Difference'
													   WHEN Name = 'LeaseComponentReceivablePrepaid_Difference'
													   THEN '10_Lease Component - Prepaid_Difference'
													   WHEN Name = 'NonLeaseComponentReceivablePrepaid_Difference'
													   THEN '11_Non LeaseComponent - Prepaid_Difference'
													   WHEN Name = 'BalanceAmount_LC_Difference'
													   THEN '12_Lease Component - Balance Receivable_Difference'
													    WHEN Name = 'BalanceAmount_NLC_Difference'
													   THEN '13_Non Lease Component - Balance Receivable_Difference'
												   END


	SELECT Label AS Name, Count
	FROM #OwnedReceivableSummary

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
	DROP TABLE #ReceivableAmount
	DROP TABLE #ReceivableGLPostedAmount
	DROP TABLE #ExpectedEntryItemDetails
	DROP TABLE #GLTrialBalance
	DROP TABLE #DistinctContracts
	DROP TABLE #ResultList
	DROP TABLE #ReceiptDetails
	DROP TABLE #NonAccrualLoanAmount
	DROP TABLE #OwnedReceivableSummary
	DROP TABLE #NonAccrualDetails
	DROP TABLE #RecievableEntryItems
	DROP TABLE #ReceiptGLPosting
	DROP TABLE #ChargeOff
	DROP TABLE #Syndications
	IF OBJECT_ID('tempdb..#ChargeoffExpenseReceiptIds') IS NOT NULL
	BEGIN
		DROP TABLE #ChargeoffExpenseReceiptIds;
	END
	IF OBJECT_ID('tempdb..#ChargeoffExpenseRecords') IS NOT NULL
	BEGIN
		DROP TABLE #ChargeoffExpenseRecords;
	END
	IF OBJECT_ID('tempdb..#ReceiptApplicationReceivableDetails') IS NOT NULL
	BEGIN
		DROP TABLE #ReceiptApplicationReceivableDetails;
	END
	IF OBJECT_ID('tempdb..#ChargeoffRecoveryReceiptIds') IS NOT NULL
	BEGIN
		DROP TABLE #ChargeoffRecoveryReceiptIds;
	END
	IF OBJECT_ID('tempdb..#ChargeoffRecoveryRecords') IS NOT NULL
	BEGIN
		DROP TABLE #ChargeoffRecoveryRecords;
	END
	IF OBJECT_ID('tempdb..#NonSKUChargeoffExpenseRecords') IS NOT NULL
	BEGIN
		DROP TABLE #NonSKUChargeoffExpenseRecords;
	END
	IF OBJECT_ID('tempdb..#NonSKUChargeoffRecoveryRecords') IS NOT NULL
	BEGIN
		DROP TABLE #NonSKUChargeoffRecoveryRecords;
	END

	SET NOCOUNT OFF
	SET ANSI_WARNINGS ON 
END

GO
