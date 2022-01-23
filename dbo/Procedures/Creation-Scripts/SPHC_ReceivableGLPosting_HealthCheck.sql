SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SPHC_ReceivableGLPosting_HealthCheck]
(
	@StartDate DATE,
	@EndDate DATE,
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

	IF OBJECT_ID('tempdb..#PrepaidReceivablesInfo') IS NOT NULL DROP TABLE #PrepaidReceivablesInfo
	IF OBJECT_ID('tempdb..#ReceivableGLPostingInfo') IS NOT NULL DROP TABLE #ReceivableGLPostingInfo
	IF OBJECT_ID('tempdb..#ReceivableGLPostingResultOutput') IS NOT NULL DROP TABLE #ReceivableGLPostingResultOutput
	IF OBJECT_ID('tempdb..#ReceivableTaxGLPostingResultOutput') IS NOT NULL DROP TABLE #ReceivableTaxGLPostingResultOutput
	IF OBJECT_ID('tempdb..#ExpectedGLPostedReceivables') IS NOT NULL DROP TABLE #ExpectedGLPostedReceivables
	IF OBJECT_ID('tempdb..#ExpectedGLPostedReceivableTaxes') IS NOT NULL DROP TABLE #ExpectedGLPostedReceivableTaxes
	IF OBJECT_ID('tempdb..#ReceivableTaxSyndicationDetails') IS NOT NULL DROP TABLE #ReceivableTaxSyndicationDetails
	IF OBJECT_ID('tempdb..#ExpectedEntryItemDetails') IS NOT NULL DROP TABLE #ExpectedEntryItemDetails
	IF OBJECT_ID('tempdb..#ReceivableGLJournalDetails') IS NOT NULL DROP TABLE #ReceivableGLJournalDetails
	IF OBJECT_ID('tempdb..#ReceivableTaxGLJournalDetails') IS NOT NULL DROP TABLE #ReceivableTaxGLJournalDetails
	IF OBJECT_ID('tempdb..#TaxReceivableActualAmountDerivation') IS NOT NULL DROP TABLE #TaxReceivableActualAmountDerivation
	IF OBJECT_ID('tempdb..#ReApplicationReceivables') IS NOT NULL DROP TABLE #ReApplicationReceivables
	IF OBJECT_ID('tempdb..#CTE_ReceivableDetails') IS NOT NULL DROP TABLE #CTE_ReceivableDetails
	IF OBJECT_ID('tempdb..#ReceivableActualAmountDerivation') IS NOT NULL DROP TABLE #ReceivableActualAmountDerivation
	IF OBJECT_ID('tempdb..#TotalCountReceivables') IS NOT NULL DROP TABLE #TotalCountReceivables
	IF OBJECT_ID('tempdb..#TotalCountReceivableTaxes') IS NOT NULL DROP TABLE #TotalCountReceivableTaxes

	DECLARE @True BIT = 1
	DECLARE @False BIT = 0
	DECLARE @TrueChar NVARCHAR(10) = 'TRUE'
	DECLARE @DefaultValue DECIMAL(16,2) = 0.00
	DECLARE @CT NVARCHAR(5) = 'CT'
	DECLARE @CU NVARCHAR(5) = 'CU'
	DECLARE @DT NVARCHAR(5) = 'DT'
	DECLARE @Unknown NVARCHAR(5) = '_'
	DECLARE @Lease NVARCHAR(10) = 'Lease'
	DECLARE @Loan NVARCHAR(10) = 'Loan'
	DECLARE @Sundry NVARCHAR(10) = 'Sundry'
	DECLARE @ChargedOff NVARCHAR(20) = 'ChargedOff'
	DECLARE @Recovery NVARCHAR(20) = 'Recovery'
	DECLARE @AssetSaleAR NVARCHAR(30) = 'AssetSaleAR'
	DECLARE @PropertyTaxEscrow NVARCHAR(40) = 'PropertyTaxEscrow'
	DECLARE @PropertyTaxAR NVARCHAR(30) = 'PropertyTaxAR'
	DECLARE @NonRentalAR NVARCHAR(20) = 'NonRentalAR'
	DECLARE @ParticipatedSale NVARCHAR(40) = 'ParticipatedSale'
	DECLARE @SyndicatedAR NVARCHAR(30) = 'SyndicatedAR'
	DECLARE @SalesTax NVARCHAR(20) = 'SalesTax'
	DECLARE @AccrualBased NVARCHAR(20) = 'AccrualBased'
	DECLARE @CashBased NVARCHAR(20) = 'CashBased'
	DECLARE @Memo NVARCHAR(12) = 'Memo'
	DECLARE @Finance NVARCHAR(10) = 'Finance'
	DECLARE @RemitOnly NVARCHAR(10) = 'RemitOnly'
	DECLARE @OTP NVARCHAR(10) = 'OTP'
	DECLARE @Supplemental NVARCHAR(20) = 'Supplemental'
	DECLARE @PrePaid NVARCHAR(20) = '%PrePaid%'
	DECLARE @Financing NVARCHAR(20) = '%Financing%'
	DECLARE @Reversed NVARCHAR(20) = 'Reversed'
	DECLARE @All NVARCHAR(20) = 'All'
	DECLARE @Passed NVARCHAR(20) = 'Passed'
	DECLARE @Failed NVARCHAR(20) = 'Failed'
	DECLARE @IncorrectInputCount BIGINT
	DECLARE @SuccessMessage1 NVARCHAR(80) = 'Passed'
	DECLARE @SuccessMessage2 NVARCHAR(80) = 'Passed (Zero Valued Receivable)'
	DECLARE @SuccessMessage3 NVARCHAR(80) = 'Passed (Zero Valued ReceivableTax)'
	DECLARE @SuccessMessage4 NVARCHAR(80) ='Passed (Chargedoff contract, Receivables reclassified to expense bucket)' 
	DECLARE @FailureMessage1 NVARCHAR(80) = 'Not GL Posted.'
	DECLARE @FailureMessage2 NVARCHAR(80) = 'Correct entry found but IsGLPosted not updated.'
	DECLARE @FailureMessage3 NVARCHAR(80) = 'Incorrect entry found and IsGLPosted not updated.'
	DECLARE @FailureMessage4 NVARCHAR(80) = 'Incorrect entry found.'
	DECLARE @FailureMessage5 NVARCHAR(80) ='GL Posted and Reversed.'
	DECLARE @FailureMessage6 NVARCHAR(80) = 'Not GL Posted (Sales Tax is not GL Posted post charged off)'
	DECLARE @FailureMessage7 NVARCHAR(80) = 'Expected entry item detail not found'
	DECLARE @Conclusion NVARCHAR(100) = 'Please refer Results for Entry Item wise details.'
	DECLARE @Messages StoredProcMessage
	DECLARE @LegalEntitiesCount BIGINT = ISNULL((SELECT COUNT(*) FROM @LegalEntityIds), 0)
	DECLARE @ContractsCount BIGINT = ISNULL((SELECT COUNT(*) FROM @ContractIds), 0)
	DECLARE @CustomersCount BIGINT = ISNULL((SELECT COUNT(*) FROM @CustomerIds), 0)
	DECLARE @DiscountingsCount BIGINT = ISNULL((SELECT COUNT(*) FROM @DiscountingIds), 0)
	DECLARE @TotalReceivablesCount BIGINT
	DECLARE @PassedReceivablesCount BIGINT
	DECLARE @NotGLPostedReceivablesCount BIGINT
	DECLARE @IncorrectlyGLPostedReceivablesCount BIGINT
	DECLARE @ConfigMissingReceivablesCount BIGINT
	DECLARE @TotalReceivableTaxesCount BIGINT
	DECLARE @PassedReceivableTaxesCount BIGINT
	DECLARE @NotGLPostedReceivableTaxesCount BIGINT
	DECLARE @IncorrectlyGLPostedReceivableTaxesCount BIGINT
	DECLARE @ConfigMissingReceivableTaxesCount BIGINT

	SELECT 
		GLTransactionType, 
		EntryItemName,
		CASE WHEN IsDebit = @TrueChar THEN 1 ELSE 0 END AS IsDebit,
		CASE WHEN IsCashBased = @TrueChar THEN 1 ELSE 0 END AS IsCashBased,
		CASE WHEN IsAccrualBased = @TrueChar THEN 1 ELSE 0 END AS IsAccrualBased,
		CASE WHEN IsMemoBased = @TrueChar THEN 1 ELSE 0 END AS IsMemoBased,
		CASE WHEN IsPrepaidApplicable = @TrueChar THEN 1 ELSE 0 END AS IsPrepaidApplicable,
		AssetComponent,
		CASE WHEN IsInterCompany = @TrueChar THEN 1 ELSE 0 END AS IsInterCompany,
		CASE WHEN IsFunderOwnedTax = @TrueChar THEN 1 ELSE 0 END AS IsFunderOwnedTax,
		CASE WHEN IsOTP = @TrueChar THEN 1 ELSE 0 END AS IsOTP,
		CASE WHEN IsSupplemental = @TrueChar THEN 1 ELSE 0 END AS IsSupplemental,
		CASE WHEN IsBlendedItem = @TrueChar THEN 1 ELSE 0 END AS IsBlendedItem,
		CASE WHEN IsVendorOwned = @TrueChar THEN 1 ELSE 0 END AS IsVendorOwned
	INTO #ExpectedEntryItemDetails 
	FROM @ExpectedEntryItemDetail

		CREATE NONCLUSTERED INDEX IX_Id ON #ExpectedEntryItemDetails(GLTransactionType)
		CREATE TABLE #ReceivableGLPostingResultOutput
		(
			ReceivableId BIGINT,
			EntityId BIGINT,
			EntityType NVARCHAR(4),
			SyndicationType NVARCHAR(50) NULL,
			ChargeOffStatus NVARCHAR(50) NULL,
			ReceivableType NVARCHAR(50),
			Outage_Reason NVARCHAR(80) NULL,
			Expected_EntryItemName NVARCHAR(50) NULL,
			Actual_EntryItemName NVARCHAR(50) NULL,
			Expected_Amount DECIMAL(16,2) NULL,
			Actual_Amount DECIMAL(16,2) NULL,
			Expected_IsDebit BIT NULL,
			Actual_IsDebit BIT NULL
		)

		CREATE TABLE #ReceivableTaxGLPostingResultOutput
		(
			ReceivableTaxId BIGINT,
			EntityId BIGINT,
			EntityType NVARCHAR(4),
			SyndicationType NVARCHAR(50) NULL,
			ChargeOffStatus NVARCHAR(50) NULL,
			GLTransactionType NVARCHAR(50),
			Outage_Reason NVARCHAR(50) NULL,
			Expected_EntryItemName NVARCHAR(50) NULL,
			Actual_EntryItemName NVARCHAR(50) NULL,
			Expected_Amount DECIMAL(16,2) NULL,
			Actual_Amount DECIMAL(16,2) NULL,
			Expected_IsDebit BIT NULL,
			Actual_IsDebit BIT NULL
		)

		-- Fetches PrePaid Receivables Amounts for verifying PrePaidEntryItem GL entries.
		SELECT
		PR.ReceivableId,
		R.Status AS ReceiptStatus,
		PR.IsActive,
		SUM(PR.PrePaidAmount_Amount) AS PrePaidAmount_Amount,
		SUM(PR.PrePaidTaxAmount_Amount) AS PrePaidTaxAmount_Amount,
		SUM(PR.FinancingPrePaidAmount_Amount) AS FinancingPrePaidAmount_Amount
		INTO #PrepaidReceivablesInfo
		FROM PrepaidReceivables PR 
		LEFT JOIN Receipts R ON PR.ReceiptId = R.Id AND R.Status = @Reversed
		GROUP BY PR.ReceivableId, R.Status, PR.IsActive

	-- Fetches ReApplied Receivables GL Posted Receivables.
		SELECT 
		DIstinct RD.Receivableid,
    	CASE WHEN RARD.IsGLPosted = @True AND RARD.IsReApplication = @True THEN @True ELSE @False END AS ReappliedReceivables
		INTO #ReApplicationReceivables
		FROM PrepaidReceivables PR  
		JOIN ReceiptApplications RA ON PR.ReceiptId = RA.ReceiptId AND PR.IsActive = @True
		JOIN Receiptapplicationreceivabledetails RARD ON RA.Id = RARD.ReceiptApplicationId AND RARD.IsReApplication = @True
		JOIN Receivabledetails RD ON RARD.Receivabledetailid = RD.Id
		AND RARD.IsGLPosted = @True AND RARD.IsActive = @True

		CREATE INDEX idx_ReceivableId ON #PrepaidReceivablesInfo (ReceivableId);
		CREATE INDEX idx_ReceivableId ON #ReApplicationReceivables (ReceivableId);

		-- Filters Receivables
		SELECT 
		R.Id AS ReceivableId,
		R.EntityId,
		R.EntityType,
		R.IsCollected,
		R.IsGLPosted,
		R.DueDate,
		RT.Name AS ReceivableType,
		RC.AccountingTreatment,
		GTT.Name AS GLTransactionType,
		@SyndicatedAR AS SyndicationGLTransactionType,
		R.TotalAmount_Amount,
		R.TotalBalance_Amount,
		CASE WHEN PR.PrePaidAmount_Amount IS NULL THEN @DefaultValue ELSE PR.PrePaidAmount_Amount END AS PrePaidAmount_Amount,
		CASE WHEN PR.PrePaidTaxAmount_Amount IS NULL THEN @DefaultValue ELSE PR.PrePaidTaxAmount_Amount END AS PrePaidTaxAmount_Amount,
		CASE WHEN PR.FinancingPrePaidAmount_Amount IS NULL THEN @DefaultValue ELSE PR.FinancingPrePaidAmount_Amount END AS FinancingPrePaidAmount_Amount,
		R.FunderId,
		R.PaymentScheduleId,
		R.SourceId,
		R.SourceTable,
		P.IsInterCompany,
		CASE WHEN C.ChargeOffStatus IS NOT NULL THEN C.ChargeOffStatus ELSE '_' END AS ChargeOffStatus,
		CASE WHEN C.SyndicationType = 'None' THEN '_' 
		     WHEN C.SyndicationType != 'None' AND C.SyndicationType IS NOT NULL THEN C.SyndicationType ELSE '_' END AS SyndicationType, --- SyndicationType = None
		CASE WHEN C.ContractType = @Lease THEN LEPS.StartDate WHEN C.ContractType = @Loan THEN LOPS.StartDate ELSE NULL END AS PaymentStartDate,
		R.IncomeType,
		PR.ReceiptStatus
		INTO #ReceivableGLPostingInfo
		FROM Receivables R
		JOIN ReceivableCodes RC ON R.ReceivableCodeId = RC.Id
		JOIN ReceivableTypes RT ON RC.ReceivableTypeId = RT.Id
		JOIN GLTemplates GT ON RC.GLTemplateId = GT.Id
		JOIN GLTransactionTypes GTT ON GT.GLTransactionTypeId = GTT.Id
		JOIN Parties P ON R.CustomerId = P.Id
		LEFT JOIN #PrepaidReceivablesInfo PR ON R.Id = PR.ReceivableId  -- AND (PR.ReceiptStatus != @Reversed  OR PR.ReceiptStatus IS NULL) -- AND PR.IsActive = @True
		LEFT JOIN Contracts C ON R.EntityId = C.Id AND R.EntityType = @CT 
		LEFT JOIN LeasePaymentSchedules LEPS ON R.PaymentScheduleId = LEPS.Id AND C.ContractType = @Lease
		LEFT JOIN LoanPaymentSchedules LOPS ON R.PaymentScheduleId = LOPS.Id AND C.ContractType = @Loan
		LEFT JOIN #ReApplicationReceivables RRA ON R.Id = RRA.ReceivableId
		WHERE R.DueDate >= @StartDate
		AND R.DueDate <= @EndDate
		AND R.IsActive = @True
		AND R.IsDummy = @False
		AND (RRA.ReappliedReceivables !=@True OR RRA.ReappliedReceivables IS NULL) 	-- Do not consider Reapplication Receipts for Receivables which are GL Posted.
		AND R.IsCollected = @True  --- Collection Flag True Receivables
		AND ((R.IsGLPosted = @False AND (PR.ReceivableId IS NOT NULL  OR PR.ReceivableId IS NULL)) 
				OR (R.IsGLPosted = @True AND (PR.ReceiptStatus != @Reversed OR PR.ReceiptStatus IS NULL))) --- SKIP receivables having Receipt STATUS REVERSED
        AND @True = (CASE 
					 WHEN @LegalEntitiesCount > 0 AND EXISTS (SELECT Id FROM @LegalEntityIds WHERE Id = R.LegalEntityId) THEN @True
					 WHEN @LegalEntitiesCount = 0 THEN @True ELSE @False END)
		AND @True = (CASE 
					 WHEN @CustomersCount > 0 AND EXISTS (SELECT Id FROM @CustomerIds WHERE Id = R.CustomerId) THEN @True
					 WHEN @CustomersCount = 0 THEN @True ELSE @False END)
		AND (@True = (CASE 
					  WHEN @ContractsCount > 0 AND EXISTS (SELECT Id FROM @ContractIds WHERE Id = R.EntityId AND R.EntityType = @CT) THEN @True
					  WHEN @ContractsCount = 0 AND @DiscountingsCount = 0 THEN @True ELSE @False END)
					  OR @True = (CASE 
								  WHEN @DiscountingsCount > 0 AND EXISTS (SELECT Id FROM @DiscountingIds WHERE Id = R.EntityId AND R.EntityType = @DT) THEN @True
								  WHEN @DiscountingsCount = 0 AND @ContractsCount = 0 THEN @True ELSE @False END))


			CREATE NONCLUSTERED INDEX IX_Id ON #ReceivableGLPostingInfo(ReceivableId);

		-- Fetching #ExpectedGLPostedReceivables at ReceivableDetails level per AssetComponentType.

		SELECT ReceivableId
				, AssetComponentType
				, SUM(Amount_Amount) AS Amount_Amount
				, SUM(Balance_Amount) AS Balance_Amount
		INTO #CTE_ReceivableDetails
		FROM
		(
			SELECT R.ReceivableId
					, CASE
						  WHEN RD.AssetComponentType IS NULL THEN '_'
						  WHEN R.FunderId IS NOT NULL THEN '_'
						  ELSE RD.AssetComponentType
					  END AS AssetComponentType
					, RD.Amount_Amount AS Amount_Amount
					, RD.Balance_Amount AS Balance_Amount
			FROM ReceivableDetails RD
					INNER JOIN #ReceivableGLPostingInfo R ON R.ReceivableId = RD.ReceivableId
			WHERE RD.IsActive = 1
				  AND R.IsCollected = @True
		) AS t
		GROUP BY ReceivableId
				, AssetComponentType;

	  	CREATE NONCLUSTERED INDEX IX_Id ON #CTE_ReceivableDetails(ReceivableId);

		SELECT R.ReceivableId
			 , R.EntityId
			 , R.EntityType
			 , R.DueDate
			 , R.SyndicationType
			 , R.ChargeOffStatus
			 , R.ReceivableType
			 , R.AccountingTreatment
			 , RD.AssetComponentType
			 , R.IsGLPosted
			 , RD.Amount_Amount
			 , RD.Balance_Amount
			 , R.PrePaidAmount_Amount
			 , R.FinancingPrePaidAmount_Amount
			 , CASE
				   WHEN R.FunderId IS NOT NULL
				   THEN R.SyndicationGLTransactionType
				   ELSE R.GLTransactionType
			   END GLTransactionType
			 , R.IsIntercompany
			 , R.IncomeType
			 , CASE
				   WHEN BI.Id IS NOT NULL
				   THEN @True
				   ELSE @False
			   END AS IsBlendedItemReceivable
			 , CASE
				   WHEN RSD.Id IS NOT NULL
				   THEN @True
				   ELSE @False
			   END AS IsVendorOwned
			 , CASE
				   WHEN R.TotalAmount_Amount = @DefaultValue
				   THEN @True
				   ELSE @False
			   END AS IsZeroAmountReceivable
		INTO #ExpectedGLPostedReceivables
		FROM #ReceivableGLPostingInfo R
			 JOIN #CTE_ReceivableDetails RD ON R.ReceivableId = RD.ReceivableId
			 LEFT JOIN ChargeOffs CO ON R.EntityId = CO.ContractId
			 LEFT JOIN Sundries S ON R.SourceId = S.Id
									 AND R.SourceTable = @Sundry
			 LEFT JOIN BlendedItemDetails BID ON S.Id = BID.SundryId
												 AND S.Id IS NOT NULL
			 LEFT JOIN BlendedItems BI ON BID.BlendedItemId = BI.Id
										  AND BID.Id IS NOT NULL
			 LEFT JOIN RentSharingDetails RSD ON R.ReceivableId = RSD.ReceivableId
		WHERE R.IsCollected = @True
			  AND NOT EXISTS (SELECT SundryId FROM DisbursementRequests DR WHERE DR.SundryId = S.Id)
			  AND NOT EXISTS (SELECT SundryId FROM PaymentVoucherInfoes PV WHERE PV.SundryId = S.Id)
			  AND ((((R.ChargeOffStatus != '_' 
					AND (((R.GLTransactionType != @PropertyTaxEscrow 
							AND R.GLTransactionType != @NonRentalAR) 
							AND (R.PaymentStartDate IS NOT NULL AND R.PaymentStartDate < CO.ChargeOffDate AND CO.IsRecovery = 0))) 
					OR R.GLTransactionType = @AssetSaleAR 
					OR R.GLTransactionType = @PropertyTaxEscrow 
					OR R.GLTransactionType = @PropertyTaxAR 
					OR (R.GLTransactionType = @NonRentalAR AND BI.IsFAS91 = @False) 
					OR (R.GLTransactionType = @NonRentalAR AND R.DueDate < CO.ChargeOffDate AND CO.IsRecovery = 0))))
			OR R.ChargeOffStatus = '_')

    	CREATE NONCLUSTERED INDEX idx_ReceivableId ON #ExpectedGLPostedReceivables (ReceivableId)  

		-- Fetches Last Syndication Servicing details less than DueDate.
		SELECT 
		-- TOP 1
		R.ReceivableId,
		CASE WHEN RFTS.Id IS NOT NULL THEN RFTS.IsCollected ELSE @False END AS IsCollected
		INTO #ReceivableTaxSyndicationDetails
		FROM #ReceivableGLPostingInfo R
		LEFT JOIN ReceivableForTransfers RFT ON R.EntityId = RFT.ContractId
		LEFT JOIN ReceivableForTransferServicings RFTS ON RFT.Id = RFTS.ReceivableForTransferId AND RFT.Id IS NOT NULL 
		AND R.PaymentStartDate >= RFTS.EffectiveDate AND RFTS.IsActive = 1
		WHERE R.SyndicationType = @ParticipatedSale 
		ORDER BY RFTS.EffectiveDate DESC

	    ;WITH CTE_ReceivableForTransferFundingSources AS -------joining with ReceivableForTransferFundingSources to derive SalesTaxResponsibility
		(
		 Select ID,EffectiveDate,ContractId,'RemitOnly' AS SalesTaxResponsibility 
         from ReceivableForTransfers where ApprovalStatus = 'Approved' AND  Id in (
         Select ReceivableForTransferId from ReceivableForTransferFundingSources where SalesTaxResponsibility = 'RemitOnly' AND IsActive = 1)
		)
		
		-- Fetching #ExpectedGLPostedReceivableTaxes
		SELECT 
		RT.Id AS ReceivableTaxId, 
		R.EntityId, 
		R.EntityType,
		R.DueDate,
		R.SyndicationType,
		R.Chargeoffstatus,
		RT.IsGLPosted,
		RT.Amount_Amount,
		RT.Balance_Amount,
		R.PrePaidTaxAmount_Amount,
		RT.IsCashBased,
		CASE 
			WHEN RTFS.Id IS NOT NULL THEN 
				CASE 
					WHEN R.FunderId IS NOT NULL THEN @SyndicatedAR 
					ELSE @SalesTax END 
			ELSE @SalesTax 
		END AS GLTransactionType,
		R.FunderId
		INTO #ExpectedGLPostedReceivableTaxes
		FROM #ReceivableGLPostingInfo R
		JOIN ReceivableTaxes RT ON R.ReceivableId = RT.ReceivableId
		LEFT JOIN #ReceivableTaxSyndicationDetails RTSD ON R.ReceivableId = RTSD.ReceivableId AND R.SyndicationType = @ParticipatedSale
		LEFT JOIN ReceivableForTransfers RFT ON R.EntityId = RFT.ContractId 
		LEFT JOIN CTE_ReceivableForTransferFundingSources RTFS ON R.EntityId = RTFS.ContractId AND R.FunderId IS NOT NULL 
		AND RTFS.SalesTaxResponsibility = @RemitOnly 
		AND ((R.SyndicationType != 'SaleOfPayment' OR (R.SyndicationType ='SaleOfPayment' AND ((R.IncomeType !=@OTP OR R.IncomeType !=@Supplemental))))
			AND ((R.PaymentScheduleId IS NOT NULL AND R.PaymentStartDate >=RTFS.EffectiveDate) OR (R.DueDate >=RTFS.EffectiveDate))) 
		WHERE RT.IsActive = @True
		AND RT.IsDummy = @False
		AND (((R.EntityType = @CU OR R.EntityType = @DT) 
				AND R.IsCollected = @True)
			OR (R.EntityType = @CT 
				AND (R.SyndicationType = '_' 
				    OR (R.SyndicationType IS NOT NULL AND R.FunderId IS NOT NULL)
					OR (R.SyndicationType != @ParticipatedSale AND R.FunderId IS NULL)) ----- Derivation of Collection flag for Non Syndicated or other than Participated Syndication
				AND R.IsCollected = @True)
			OR (R.EntityType = @CT
				AND R.SyndicationType = @ParticipatedSale
				AND R.FunderId IS NULL 
				AND R.GLTransactionType != @PropertyTaxEscrow
				AND R.GLTransactionType != @NonRentalAR
				AND R.PaymentScheduleId IS NOT NULL
				AND RTSD.ReceivableId IS NOT NULL
				AND RTSD.IsCollected = @True)
		)

		CREATE INDEX idx_ReceivableTaxId ON #ExpectedGLPostedReceivableTaxes (ReceivableTaxId) 

		-- Inserts into Output TempTable: Receivables info for which GL Posting has not been processed.
		--INSERT INTO #ReceivableGLPostingResultOutput

		;WITH CTE_NonGLPostedReceivables AS
		(
			SELECT
			ER.ReceivableId,
			ER.EntityId,
			ER.EntityType,
			ER.SyndicationType,
			ER.ChargeOffStatus,
			ER.ReceivableType,
			CASE 
				WHEN ER.IsGLPosted = @False THEN @FailureMessage1 ELSE 
					CASE 
						WHEN ER.IsZeroAmountReceivable = @True AND ER.IsGLPosted = @True THEN @SuccessMessage2 
					END 
			END AS Outage_Reason,
			CASE WHEN ER.IsZeroAmountReceivable = @False THEN EEID.EntryItemName ELSE NULL END AS Expected_EntryItemName,
			NULL AS Actual_EntryItemName,
			CASE
				WHEN EEID.IsDebit = @True THEN 
					CASE 
						WHEN EEID.IsPrepaidApplicable = @True THEN 
							CASE 
								WHEN ER.GLTransactionType = 'SyndicatedAR' AND ER.AssetComponentType = '_' THEN ABS (ER.FinancingPrePaidAmount_Amount + ER.PrePaidAmount_Amount)
								WHEN ER.GLTransactionType != 'SyndicatedAR' AND ER.AssetComponentType = '_' THEN ABS (ER.FinancingPrePaidAmount_Amount + ER.PrePaidAmount_Amount)
								WHEN ER.AssetComponentType = @Finance THEN ABS(ER.FinancingPrePaidAmount_Amount) 
								WHEN ER.AssetComponentType = @Lease THEN ABS(ER.PrePaidAmount_Amount) END 
						ELSE CASE 
                                WHEN ER.GLTransactionType = 'SyndicatedAR' AND ER.AssetComponentType = '_' THEN ABS(ER.Amount_Amount) - ABS (ER.FinancingPrePaidAmount_Amount + ER.PrePaidAmount_Amount)   
								WHEN ER.GLTransactionType != 'SyndicatedAR' AND ER.AssetComponentType = '_' THEN ABS(ER.Amount_Amount) - ABS (ER.FinancingPrePaidAmount_Amount + ER.PrePaidAmount_Amount)   
								WHEN ER.AssetComponentType = @Finance THEN ABS(ER.Amount_Amount) - ABS(ER.FinancingPrePaidAmount_Amount) 
								WHEN ER.AssetComponentType = @Lease THEN ABS(ER.Amount_Amount) - ABS(ER.PrePaidAmount_Amount) END
					END
				ELSE
					ABS(ER.Amount_Amount)
			END AS Expected_Amount,
			@DefaultValue AS Actual_Amount,
			CASE WHEN ER.IsZeroAmountReceivable = @False THEN (CASE WHEN ER.Amount_Amount < 0 THEN CASE WHEN EEID.IsDebit = 0 THEN 1 ELSE 0 END ELSE EEID.IsDebit END) ELSE NULL END AS Expected_IsDebit,
			NULL AS Actual_IsDebit,
			ER.IsZeroAmountReceivable
			FROM #ExpectedGLPostedReceivables ER
			LEFT JOIN ReceivableGLJournals RG ON ER.ReceivableId = RG.ReceivableId
			LEFT JOIN GLJournals GJ ON RG.GLJournalId = GJ.Id AND RG.Id IS NOT NULL
			LEFT JOIN #ExpectedEntryItemDetails EEID ON ER.GLTransactionType = EEID.GLTransactionType
			WHERE EEID.GLTransactionType IS NULL OR (EEID.GLTransactionType IS NOT NULL AND (ER.AssetComponentType = EEID.AssetComponent OR ER.AssetComponentType = '_') AND
				((((ER.PrePaidAmount_Amount = @DefaultValue OR ER.FinancingPrePaidAmount_Amount = @DefaultValue) AND EEID.IsPrepaidApplicable = @False) 
					OR (ER.PrePaidAmount_Amount > @DefaultValue OR ER.FinancingPrePaidAmount_Amount > @DefaultValue)) -- Filter for PrePaidReceivable GLEntries
				AND ((ER.AccountingTreatment = @AccrualBased AND EEID.IsAccrualBased = @True) 
					OR (ER.AccountingTreatment = @CashBased AND EEID.IsCashBased = @True) 
					OR (ER.AccountingTreatment = @Memo AND EEID.IsMemoBased = @True)) -- Filter for Accounting Treatment 
				AND ((ER.AssetComponentType != @Finance AND EEID.AssetComponent != @Finance) 
					OR (ER.AssetComponentType = @Finance AND EEID.AssetComponent = @Finance)) -- Filter for Asset Component Type
				AND (ER.IncomeType != @OTP AND ER.IncomeType != @Supplemental AND ER.IncomeType != 'InterimRent'
					OR (ER.IncomeType = 'InterimRent' AND ER.GLTransactionType = 'InterimRentAR'
					   AND ((ER.IsVendorOwned = @True AND EEID.IsVendorOwned = @True) 
							OR (ER.IsVendorOwned = @False AND EEID.IsVendorOwned = @False))) --- Filter on Interm Rent and IsVendorOwned
					OR (ER.IncomeType = @OTP AND EEID.IsOTP = @True 
						AND ((ER.IsVendorOwned = @True AND EEID.IsVendorOwned = @True)
							OR (ER.IsVendorOwned = @False AND EEID.IsVendorOwned = @False)))
					OR (ER.IncomeType = @Supplemental AND EEID.IsSupplemental = @True
						AND ((ER.IsVendorOwned = @False AND EEID.IsVendorOwned = @False)
							OR (ER.IsVendorOwned = @True AND EEID.IsVendorOwned = @True)))) -- Filter for OTP/Supplemental and IsVendorOwned
			AND (EEID.GLTransactionType != @NonRentalAR
				OR (ER.IsIntercompany = @True AND EEID.IsInterCompany = @True AND ER.IsBlendedItemReceivable = @True AND EEID.IsBlendedItem = @True) -- Filter for InterCompany and BlendedItem
				OR (ER.IsIntercompany = @False AND EEID.IsInterCompany = @False AND ER.IsBlendedItemReceivable = @True AND EEID.IsBlendedItem = @True)-- Filter for NonRental BlendedItem
				OR (ER.IsIntercompany = @True AND EEID.IsInterCompany = @True AND ER.IsBlendedItemReceivable = @False AND EEID.IsBlendedItem = @False) -- Filter for InterCompany and NonRental
				OR (ER.IsBlendedItemReceivable = @False AND ER.IsIntercompany = @False AND EEID.IsIntercompany = @False AND EEID.IsBlendedItem = @False))
			AND ((ER.IsGLPosted = @False) OR ( ER.IsGLPosted = @True AND ER.IsZeroAmountReceivable = @True)) --- Zero Valued Receivable OR Not GL Posted
			AND GJ.Id IS NULL))
		)

		INSERT INTO #ReceivableGLPostingResultOutput
		SELECT 
		ReceivableId,
		EntityId,
		EntityType,
		SyndicationType,
		ChargeOffStatus,
		ReceivableType,
		Outage_Reason,
		Expected_EntryItemName,
		Actual_EntryItemName,
		Expected_Amount,
		Actual_Amount,
		Expected_IsDebit,
		Actual_IsDebit
		FROM CTE_NonGLPostedReceivables
		WHERE ((IsZeroAmountReceivable = @False AND Expected_Amount != @DefaultValue) OR IsZeroAmountReceivable = @True)
		AND Outage_Reason IS NOT NULL

		-- Inserts into Output TempTable: ReceivableTaxes info for which GL Posting has not been processed.
		INSERT INTO #ReceivableTaxGLPostingResultOutput
		SELECT * FROM
		(
			SELECT
			ERT.ReceivableTaxId,
			ERT.EntityId,
			ERT.EntityType,
			ERT.SyndicationType,
			ERT.ChargeOffStatus,
			ERT.GLTransactionType,
			CASE 
				WHEN ERT.IsGLPosted = @False THEN @FailureMessage1 ELSE 
					CASE 
						WHEN ERT.Amount_Amount = @DefaultValue AND ERT.IsGLPosted = @True THEN @SuccessMessage3 
					END 
			END AS Outage_Reason,
			CASE WHEN ERT.Amount_Amount != @DefaultValue THEN EEID.EntryItemName ELSE NULL END AS Expected_EntryItemName,
			NULL AS Actual_EntryItemName,
			CASE WHEN EEID.IsDebit = @True THEN
					CASE 
						WHEN EEID.IsPrepaidApplicable = @True THEN ABS(ERT.PrePaidTaxAmount_Amount) 
						ELSE ABS(ERT.Amount_Amount) - ABS(ERT.PrePaidTaxAmount_Amount) END
				ELSE ABS(ERT.Amount_Amount)
			END AS Expected_Amount,
			@DefaultValue AS Actual_Amount,
			CASE WHEN ERT.Amount_Amount != @DefaultValue THEN (CASE WHEN ERT.Amount_Amount < 0 THEN CASE WHEN EEID.IsDebit = 0 THEN 1 ELSE 0 END ELSE EEID.IsDebit END) ELSE NULL END AS Expected_IsDebit,
			NULL AS Actual_IsDebit
			FROM #ExpectedGLPostedReceivableTaxes ERT
			LEFT JOIN ReceivableTaxGLs RTG ON ERT.ReceivableTaxId = RTG.ReceivableTaxId
			LEFT JOIN GLJournals GJ ON RTG.GLJournalId = GJ.Id AND RTG.Id IS NOT NULL
			LEFT JOIN #ExpectedEntryItemDetails EEID ON ERT.GLTransactionType = EEID.GLTransactionType
			WHERE EEID.GLTransactionType IS NULL OR
			(((ERT.PrePaidTaxAmount_Amount = @DefaultValue AND EEID.IsPrepaidApplicable = @False) 
				OR (ERT.PrePaidTaxAmount_Amount > @DefaultValue))
			  AND ((ERT.IsCashBased = @True AND EEID.IsCashBased = @True)
				 OR (ERT.IsCashBased = @False AND EEID.IsAccrualBased = @True))
			  AND (ERT.GLTransactionType != @SalesTax 
				 OR (ERT.FunderId IS NOT NULL AND EEID.IsFunderOwnedTax = @True AND ERT.GLTransactionType = @SalesTax) 
				 OR (ERT.FunderId IS NULL AND EEID.IsFunderOwnedTax = @False AND ERT.GLTransactionType = @SalesTax))
			AND ((ERT.IsGLPosted = @False) OR (ERT.IsGLPosted = @True AND ERT.Amount_Amount = @DefaultValue)) --- Zero Valued Receivable OR Not GL Posted
			AND GJ.Id IS NULL)
		) as t
		WHERE Outage_Reason IS NOT NULL

		SELECT *
		INTO #ReceivableGLJournalDetails
		FROM
		(
			SELECT DISTINCT 
					ER.ReceivableId
					, GJD.GLJournalId
					, GJD.Amount_Amount
					, GJD.IsDebit
					, GJD.GLTemplateDetailId
			FROM #ExpectedGLPostedReceivables ER
					JOIN ReceivableGLJournals rgl ON ER.ReceivableId = rgl.ReceivableId
					JOIN GLJournalDetails GJD ON GJD.GLJournalId = rgl.GLJournalId
			WHERE GJD.IsActive = 1
			UNION
			SELECT DISTINCT 
					ER.ReceivableId
					, GJD.GLJournalId
					, GJD.Amount_Amount
					, GJD.IsDebit
					, GJD.GLTemplateDetailId
			FROM #ExpectedGLPostedReceivables ER
					JOIN ReceivableGLJournals rgl ON ER.ReceivableId = rgl.ReceivableId
					JOIN GLJournalDetails GJD ON ER.ReceivableId = GJD.Sourceid
												AND GJD.EntityType IN('Customer', 'Contract', 'Discounting')
												AND ER.ENtityId = GJD.EntityId
			WHERE GJD.IsActive = 1
					AND rgl.GLJournalId != GJD.GLJournalId
		) AS t;

		CREATE NONCLUSTERED INDEX IX_Id ON #ReceivableGLJournalDetails(ReceivableId);

		SELECT t.ReceivableId, SUM(CreditAmount - DebitAmount) AS Amount_Amount, t.EntryItemId
		INTO #ReceivableActualAmountDerivation
		FROM
		(
		SELECT gl.ReceivableId
			 , CASE
				   WHEN gl.IsDebit = 1
				   THEN gl.Amount_Amount
				   ELSE 0.0
			   END AS DebitAmount
			 , CASE
				   WHEN gl.IsDebit = 0
				   THEN gl.Amount_Amount
				   ELSE 0.0
			   END AS CreditAmount
			, GLEI.Id AS EntryItemId
		FROM #ReceivableGLJournalDetails gl
			 JOIN GLTemplateDetails GTD ON gl.GLTemplateDetailId = GTD.Id
			 JOIN GLEntryItems GLEI ON GTD.EntryItemId = GLEI.Id
			 JOIN GLTransactionTypes GLTT ON GLEI.GLTransactionTypeId = GLTT.Id
											 AND GLTT.Name IN('NonRentalAR', 'InterimRentAR', 'LeaseInterimInterestAR', 'CapitalLeaseAR', 'OperatingLeaseAR', 'OTPAR', 'SyndicatedAR','LoanPrincipalAR', 'LoanInterestAR', 'PropertyTaxAR', 'FloatRateAR', 'LeveragedLeaseAR', 'PayoffBuyoutAR', 'AssetSaleAR','PropertyTaxEscrow', 'SecurityDeposit', 'AssetSaleAR')
		) as t
		GROUP BY t.ReceivableId, t.EntryItemId;

		CREATE NONCLUSTERED INDEX IX_Id ON #ReceivableActualAmountDerivation(ReceivableId);

		;WITH CTE_ReceivableGLPostingResult AS
		(
			SELECT
			ER.ReceivableId,
			ER.EntityId,
			ER.EntityType,
			ER.ChargeOffStatus,
			ER.SyndicationType,
			ER.ReceivableType,
			ER.IsGLPosted,
			EEID.IsPrepaidApplicable,
			ER.AssetComponentType,
			ER.FinancingPrePaidAmount_Amount,
			ER.PrePaidAmount_Amount,
			EEID.EntryItemName AS Expected_EntryItemName,
			GEI.Name AS Actual_EntryItemName,
			CASE
				WHEN EEID.IsDebit = @True THEN 
					CASE 
						WHEN EEID.IsPrepaidApplicable = @True THEN 
							CASE 
								WHEN ER.GLTransactionType = 'SyndicatedAR' AND ER.AssetComponentType = '_' THEN ABS (ER.FinancingPrePaidAmount_Amount + ER.PrePaidAmount_Amount)
								WHEN ER.GLTransactionType != 'SyndicatedAR' AND ER.AssetComponentType = '_' THEN ABS (ER.FinancingPrePaidAmount_Amount + ER.PrePaidAmount_Amount)
								WHEN ER.AssetComponentType = @Finance THEN ABS(ER.FinancingPrePaidAmount_Amount) 
								WHEN ER.AssetComponentType = @Lease THEN ABS(ER.PrePaidAmount_Amount) END 
						ELSE CASE 
                                WHEN ER.GLTransactionType = 'SyndicatedAR' AND ER.AssetComponentType = '_' THEN ABS(ER.Amount_Amount) - ABS (ER.FinancingPrePaidAmount_Amount + ER.PrePaidAmount_Amount)   
								WHEN ER.GLTransactionType != 'SyndicatedAR' AND ER.AssetComponentType = '_' THEN ABS(ER.Amount_Amount) - ABS (ER.FinancingPrePaidAmount_Amount + ER.PrePaidAmount_Amount)   
								WHEN ER.AssetComponentType = @Finance THEN ABS(ER.Amount_Amount) - ABS(ER.FinancingPrePaidAmount_Amount) 
								WHEN ER.AssetComponentType = @Lease THEN ABS(ER.Amount_Amount) - ABS(ER.PrePaidAmount_Amount) END
					END
				ELSE
					ABS(ER.Amount_Amount)
			END AS Expected_Amount,
			ABS(RAAD.Amount_Amount) AS Actual_Amount,
			CASE WHEN ER.Amount_Amount < 0 THEN CASE WHEN EEID.IsDebit = 0 THEN 1 ELSE 0 END ELSE EEID.IsDebit END AS Expected_IsDebit,
			CASE WHEN RAAD.Amount_Amount < 0 THEN @TRUE ELSE @FALSE END AS Actual_IsDebit
			FROM 
			#ExpectedGLPostedReceivables ER
			JOIN #ReceivableActualAmountDerivation RAAD ON ER.ReceivableId = RAAD.ReceivableId
			JOIN GLEntryItems GEI ON RAAD.EntryItemId = GEI.Id
			LEFT JOIN #ExpectedEntryItemDetails EEID ON ER.GLTransactionType = EEID.GLTransactionType AND EEID.EntryItemName = GEI.Name
			WHERE EEID.GLTransactionType IS NULL OR (EEID.GLTransactionType IS NOT NULL AND (ER.AssetComponentType = EEID.AssetComponent OR ER.AssetComponentType = '_') AND GEI.IsDebit = EEID.IsDebit
			AND ((GEI.Name NOT LIKE @PrePaid AND EEID.IsPrepaidApplicable = @False) 
				OR (GEI.Name LIKE @PrePaid AND EEID.IsPrepaidApplicable = @True)) -- Filter for PrePaidReceivable GLEntries
			AND ((ER.AccountingTreatment = @AccrualBased AND EEID.IsAccrualBased = @True) 
				OR (ER.AccountingTreatment = @CashBased AND EEID.IsCashBased = @True) 
				OR (ER.AccountingTreatment = @Memo AND EEID.IsMemoBased = @True)) -- Filter for Accounting Treatment 
			AND ((GEI.Name NOT LIKE @Financing AND EEID.AssetComponent != @Finance) 
				OR (GEI.Name LIKE @Financing AND EEID.AssetComponent = @Finance)) -- Filter for Asset Component Type
			AND (ER.IncomeType != @OTP AND ER.IncomeType != @Supplemental AND ER.IncomeType != 'InterimRent'
				OR (ER.IncomeType = 'InterimRent' AND ER.GLTransactionType = 'InterimRentAR'
				   AND ((ER.IsVendorOwned = @True AND EEID.IsVendorOwned = @True) 
						OR (ER.IsVendorOwned = @False AND EEID.IsVendorOwned = @False))) --- Filter on Interm Rent and IsVendorOwned
				OR (ER.IncomeType = @OTP AND EEID.IsOTP = @True 
					AND ((ER.IsVendorOwned = @True AND EEID.IsVendorOwned = @True)
					    OR (ER.IsVendorOwned = @False AND EEID.IsVendorOwned = @False)))
				OR (ER.IncomeType = @Supplemental AND EEID.IsSupplemental = @True
					AND ((ER.IsVendorOwned = @False AND EEID.IsVendorOwned = @False)
					    OR (ER.IsVendorOwned = @True AND EEID.IsVendorOwned = @True)))) -- Filter for OTP/Supplemental and IsVendorOwned
			AND (EEID.GLTransactionType != @NonRentalAR
				OR (ER.IsIntercompany = @True AND EEID.IsInterCompany = @True AND ER.IsBlendedItemReceivable = @True AND EEID.IsBlendedItem = @True) -- Filter for InterCompany and BlendedItem
				OR (ER.IsIntercompany = @False AND EEID.IsInterCompany = @False AND ER.IsBlendedItemReceivable = @True AND EEID.IsBlendedItem = @True)-- Filter for NonRental BlendedItem
				OR (ER.IsIntercompany = @True AND EEID.IsInterCompany = @True AND ER.IsBlendedItemReceivable = @False AND EEID.IsBlendedItem = @False) -- Filter for InterCompany and NonRental
				OR (ER.IsBlendedItemReceivable = @False AND ER.IsIntercompany = @False AND EEID.IsIntercompany = @False AND EEID.IsBlendedItem = @False))
               ))
 
		-- Inserts into Output TempTable: Receivables info for which GL Entries exist.

		INSERT INTO #ReceivableGLPostingResultOutput
		SELECT * 
		FROM
		(
			SELECT 
			ReceivableId,
			EntityId,
			EntityType,
			SyndicationType,
			ChargeOffStatus,
			ReceivableType,
			CASE 
				WHEN Expected_EntryItemName = Actual_EntryItemName AND Expected_Amount = Actual_Amount AND Expected_IsDebit = Actual_IsDebit THEN 
					CASE 
						WHEN IsGLPosted = @True THEN @SuccessMessage1
						ELSE @FailureMessage2 END 
				WHEN Expected_EntryItemName IS NULL THEN @FailureMessage7
				ELSE 
					CASE
						WHEN Expected_Amount != @DefaultValue AND (Actual_Amount = @DefaultValue OR Actual_Amount != @DefaultValue) AND ChargeOffStatus in (@ChargedOff,@Recovery) AND IsGLPosted = @True THEN @SuccessMessage4 
						WHEN IsGLPosted = @True AND Actual_Amount != @DefaultValue AND ChargeOffStatus NOT IN (@ChargedOff,@Recovery) THEN @FailureMessage4
						WHEN Expected_Amount != @DefaultValue AND Actual_Amount = @DefaultValue AND (IsGLPosted = @False) THEN @FailureMessage1
						ELSE @FailureMessage3 END 
			END AS Outage_Reason,
			Expected_EntryItemName,
			Actual_EntryItemName,
			Expected_Amount,
			Actual_Amount,
			Expected_IsDebit,
			Actual_IsDebit
			FROM CTE_ReceivableGLPostingResult
			WHERE Expected_EntryItemName IS NULL OR (((IsPrepaidApplicable = @True AND 
				((FinancingPrePaidAmount_Amount > @DefaultValue AND AssetComponentType = @Finance) 
					OR (PrePaidAmount_Amount > @DefaultValue))) 
			OR IsPrepaidApplicable = @False)
			AND Expected_Amount != @DefaultValue)
		)AS t
		WHERE Outage_Reason IS NOT NULL

		CREATE NONCLUSTERED INDEX IX_Id ON #ReceivableGLPostingResultOutput(ReceivableId);

		SELECT *
		INTO #ReceivableTaxGLJournalDetails
		FROM
		(
			SELECT DISTINCT 
					ER.ReceivableTaxId
					, GJD.GLJournalId
					, GJD.Amount_Amount
					, GJD.IsDebit
					, GJD.GLTemplateDetailId
			FROM #ExpectedGLPostedReceivableTaxes ER
					JOIN ReceivableTaxGLs rgl ON ER.ReceivableTaxId = rgl.ReceivableTaxId
					JOIN GLJournalDetails GJD ON GJD.GLJournalId = rgl.GLJournalId
			WHERE GJD.IsActive = 1
			UNION
			SELECT DISTINCT 
					ER.ReceivableTaxId
					, GJD.GLJournalId
					, GJD.Amount_Amount
					, GJD.IsDebit
					, GJD.GLTemplateDetailId
			FROM #ExpectedGLPostedReceivableTaxes ER
					JOIN ReceivableTaxGLs rgl ON ER.ReceivableTaxId = rgl.ReceivableTaxId
					JOIN GLJournalDetails GJD ON ER.ReceivableTaxId = GJD.Sourceid
												AND GJD.EntityType IN('Customer', 'Contract', 'Discounting')
												AND ER.ENtityId = GJD.EntityId
			WHERE GJD.IsActive = 1
					AND rgl.GLJournalId != GJD.GLJournalId
		) AS t;

		CREATE NONCLUSTERED INDEX IX_Id ON #ReceivableTaxGLJournalDetails(ReceivableTaxId);

		SELECT t.ReceivableTaxId, SUM(CreditAmount - DebitAmount) AS Amount_Amount, t.EntryItemId
		INTO #TaxReceivableActualAmountDerivation
		FROM
		(
		SELECT gl.ReceivableTaxId
			 , CASE
				   WHEN gl.IsDebit = 1
				   THEN gl.Amount_Amount
				   ELSE 0.0
			   END AS DebitAmount
			 , CASE
				   WHEN gl.IsDebit = 0
				   THEN gl.Amount_Amount
				   ELSE 0.0
			   END AS CreditAmount
			, GLEI.Id AS EntryItemId
		FROM #ReceivableTaxGLJournalDetails gl
			 JOIN GLTemplateDetails GTD ON gl.GLTemplateDetailId = GTD.Id
			 JOIN GLEntryItems GLEI ON GTD.EntryItemId = GLEI.Id
			 JOIN GLTransactionTypes GLTT ON GLEI.GLTransactionTypeId = GLTT.Id
											 AND GLTT.Name IN ('SalesTax','SyndicatedAR')
		) as t
		GROUP BY t.ReceivableTaxId, t.EntryItemId;

		CREATE NONCLUSTERED INDEX IX_Id ON #TaxReceivableActualAmountDerivation(ReceivableTaxId);


		;WITH CTE_ReceivableTaxGLPostingResult AS
		(
			SELECT
			ERT.ReceivableTaxId,
			ERT.EntityId,
			ERT.EntityType,
			ERT.ChargeOffStatus,
			ERT.SyndicationType,
			ERT.GLTransactionType,
			ERT.IsGLPosted,
			EEID.IsPrepaidApplicable,
			ERT.PrePaidTaxAmount_Amount,
			EEID.EntryItemName AS Expected_EntryItemName,
			GEI.Name AS Actual_EntryItemName,
			CASE WHEN EEID.IsDebit = @True THEN
					CASE 
						WHEN EEID.IsPrepaidApplicable = @True THEN ABS(ERT.PrePaidTaxAmount_Amount) 
						ELSE ABS(ERT.Amount_Amount) - ABS(ERT.PrePaidTaxAmount_Amount) END
				ELSE ABS(ERT.Amount_Amount)
			END AS Expected_Amount,
			ABS(RTG.Amount_Amount) AS Actual_Amount,
			CASE WHEN ERT.Amount_Amount < 0 THEN CASE WHEN EEID.IsDebit = 0 THEN 1 ELSE 0 END ELSE EEID.IsDebit END AS Expected_IsDebit,
			CASE WHEN RTG.Amount_Amount < 0 THEN @TRUE ELSE @FALSE END AS Actual_IsDebit
			FROM 
			#ExpectedGLPostedReceivableTaxes ERT
			JOIN #TaxReceivableActualAmountDerivation RTG ON ERT.ReceivableTaxId = RTG.ReceivableTaxId
			JOIN GLEntryItems GEI ON RTG.EntryItemId = GEI.Id
			LEFT JOIN #ExpectedEntryItemDetails EEID ON ERT.GLTransactionType = EEID.GLTransactionType AND EEID.EntryItemName = GEI.Name
			WHERE EEID.GLTransactionType IS NULL OR (GEI.IsDebit = EEID.IsDebit 
			AND ((GEI.Name NOT LIKE @PrePaid AND EEID.IsPrepaidApplicable = @False) 
				OR (GEI.Name LIKE @PrePaid AND EEID.IsPrepaidApplicable = @True))
			AND ((ERT.IsCashBased = @True AND EEID.IsCashBased = @True)
				OR (ERT.IsCashBased = @False AND EEID.IsAccrualBased = @True)) ---- Cashbased or Accrualbased remittance method
			AND (ERT.GLTransactionType != @SalesTax 
				OR (ERT.GLTransactionType = @SalesTax AND ERT.FunderId IS NOT NULL AND EEID.IsFunderOwnedTax = @True) 
				OR (ERT.GLTransactionType = @SalesTax AND ERT.FunderId IS NULL AND EEID.IsFunderOwnedTax = @False)))
		)
		-- Inserts into Output TempTable: Receivable Taxes info for which GL Entries exist.
		INSERT INTO #ReceivableTaxGLPostingResultOutput
		SELECT * FROM
		(
			SELECT 
			ReceivableTaxId,
			EntityId,
			EntityType,
			SyndicationType,
			ChargeOffStatus,
			GLTransactionType,
			CASE 
				WHEN Expected_EntryItemName = Actual_EntryItemName AND Expected_Amount = Actual_Amount AND Expected_IsDebit = Actual_IsDebit THEN 
					CASE 
						WHEN IsGLPosted = @True THEN @SuccessMessage1 
						ELSE @FailureMessage2 END
				WHEN Expected_EntryItemName IS NULL THEN @FailureMessage7					 
				ELSE 
					CASE 
						WHEN IsGLPosted = @True AND Actual_Amount != @DefaultValue THEN @FailureMessage4
						WHEN IsGLPosted = @False AND Actual_Amount = @DefaultValue THEN @FailureMessage1
						ELSE @FailureMessage3 END
			END AS Outage_Reason,
			Expected_EntryItemName,
			Actual_EntryItemName,
			Expected_Amount,
			Actual_Amount,
			Expected_IsDebit,
			Actual_IsDebit
			FROM CTE_ReceivableTaxGLPostingResult
			WHERE Expected_EntryItemName IS NULL OR (((IsPrepaidApplicable = @True AND PrePaidTaxAmount_Amount > @DefaultValue) 
			OR IsPrepaidApplicable = @False)
			AND Expected_Amount != @DefaultValue)
		) AS T
		WHERE T.Outage_Reason IS NOT NULL

		-- Selecting Results on the basis of @ResultOption input parameter.

		IF (@ResultOption = @All)
		BEGIN

		SELECT distinct ReceivableId ,
			EntityId ,
			EntityType ,
			SyndicationType,
			ChargeOffStatus ,
			ReceivableType ,
			Outage_Reason ,
			Expected_EntryItemName ,
			Actual_EntryItemName,
			Expected_Amount,
			Actual_Amount ,
			Expected_IsDebit,
			Actual_IsDebit  FROM #ReceivableGLPostingResultOutput

		SELECT distinct ReceivableTaxId ,
			EntityId ,
			EntityType ,
			SyndicationType,
			ChargeOffStatus,
			GLTransactionType,
			Outage_Reason,
			Expected_EntryItemName ,
			Actual_EntryItemName ,
			Expected_Amount ,
			Actual_Amount ,
			Expected_IsDebit,
			Actual_IsDebit
		 FROM #ReceivableTaxGLPostingResultOutput

		END
	
		IF (@ResultOption = @Passed)
		BEGIN

		SELECT distinct ReceivableId ,
			EntityId ,
			EntityType ,
			SyndicationType,
			ChargeOffStatus ,
			ReceivableType ,
			Outage_Reason ,
			Expected_EntryItemName ,
			Actual_EntryItemName,
			Expected_Amount,
			Actual_Amount ,
			Expected_IsDebit,
			Actual_IsDebit FROM #ReceivableGLPostingResultOutput WHERE Outage_Reason = @SuccessMessage1 OR Outage_Reason = @SuccessMessage2 OR Outage_Reason = @SuccessMessage4

		SELECT distinct ReceivableTaxId ,
			EntityId ,
			EntityType ,
			SyndicationType,
			ChargeOffStatus,
			GLTransactionType,
			Outage_Reason,
			Expected_EntryItemName ,
			Actual_EntryItemName ,
			Expected_Amount ,
			Actual_Amount ,
			Expected_IsDebit,
			Actual_IsDebit FROM #ReceivableTaxGLPostingResultOutput WHERE Outage_Reason = @SuccessMessage1 OR Outage_Reason = @SuccessMessage3 OR Outage_Reason = @SuccessMessage4

		END

		IF (@ResultOption = @Failed)
		BEGIN

		SELECT distinct ReceivableId ,
			EntityId ,
			EntityType ,
			SyndicationType,
			ChargeOffStatus ,
			ReceivableType ,
			Outage_Reason ,
			Expected_EntryItemName ,
			Actual_EntryItemName,
			Expected_Amount,
			Actual_Amount ,
			Expected_IsDebit,
			Actual_IsDebit FROM #ReceivableGLPostingResultOutput WHERE Outage_Reason != @SuccessMessage1 AND Outage_Reason != @SuccessMessage2

		SELECT distinct ReceivableTaxId ,
			EntityId ,
			EntityType ,
			SyndicationType,
			ChargeOffStatus,
			GLTransactionType,
			Outage_Reason,
			Expected_EntryItemName ,
			Actual_EntryItemName ,
			Expected_Amount ,
			Actual_Amount ,
			Expected_IsDebit,
			Actual_IsDebit FROM #ReceivableTaxGLPostingResultOutput WHERE Outage_Reason != @SuccessMessage1 AND Outage_Reason != @SuccessMessage3 AND Outage_Reason != @SuccessMessage4

		END

		SET @TotalReceivablesCount = (SELECT COUNT(distinct ReceivableId) FROM #ReceivableGLPostingResultOutput)

		SELECT ReceivableId, COUNT(*) AS TOTAL_COUNT
		INTO #TotalCountReceivables
		FROM #ReceivableGLPostingResultOutput
		GROUP BY ReceivableId

		CREATE NONCLUSTERED INDEX IX_Id ON #TotalCountReceivables(ReceivableId)

		SET @PassedReceivablesCount = (SELECT COUNT(a.ReceivableId) FROM
		(SELECT ReceivableId, COUNT(*) AS COUNT_PASS
		FROM #ReceivableGLPostingResultOutput
		WHERE Outage_Reason IN (@SuccessMessage1, @SuccessMessage2, @SuccessMessage3, @SuccessMessage4)
		GROUP BY ReceivableId) as a
		JOIN #TotalCountReceivables b ON a.ReceivableId=b.ReceivableId
		Where a.COUNT_PASS = b.TOTAL_COUNT) ----- To derive Receivables which are GL Posted

		SET @NotGLPostedReceivablesCount = (SELECT COUNT(a.ReceivableId) FROM
		(SELECT ReceivableId, COUNT(*) AS COUNT_PASS
		FROM #ReceivableGLPostingResultOutput
		WHERE Outage_Reason IN (@FailureMessage1)
		GROUP BY ReceivableId) as a
		JOIN #TotalCountReceivables b ON a.ReceivableId=b.ReceivableId
		Where a.COUNT_PASS = b.TOTAL_COUNT)
		
		SET @ConfigMissingReceivablesCount = (SELECT ISNULL(COUNT(distinct ReceivableId), 0) FROM #ReceivableGLPostingResultOutput WHERE Outage_Reason in (@FailureMessage7))

		SET @IncorrectlyGLPostedReceivablesCount = @TotalReceivablesCount - (@PassedReceivablesCount + @NotGLPostedReceivablesCount + @ConfigMissingReceivablesCount)

		SET @TotalReceivableTaxesCount = (SELECT COUNT(distinct ReceivableTaxId) FROM #ReceivableTaxGLPostingResultOutput)

		SELECT ReceivableTaxId, COUNT(*) AS TOTAL_COUNT
		INTO #TotalCountReceivableTaxes
		FROM #ReceivableTaxGLPostingResultOutput
		GROUP BY ReceivableTaxId

		CREATE NONCLUSTERED INDEX IX_Id ON #TotalCountReceivableTaxes(ReceivableTaxId)

		SET @PassedReceivableTaxesCount = (SELECT COUNT(a.ReceivableTaxId) FROM
		(SELECT ReceivableTaxId, COUNT(*) AS COUNT_PASS
		FROM #ReceivableTaxGLPostingResultOutput
		WHERE Outage_Reason IN (@SuccessMessage1, @SuccessMessage2, @SuccessMessage3, @SuccessMessage4)
		GROUP BY ReceivableTaxId) AS a
		JOIN #TotalCountReceivableTaxes AS b ON a.ReceivableTaxId=b.ReceivableTaxId
		WHERE a.COUNT_PASS = b.TOTAL_COUNT) ----- To derive TAX Receivables which are GL Posted

		SET @NotGLPostedReceivableTaxesCount = (SELECT COUNT(a.ReceivableTaxId) FROM
		(SELECT ReceivableTaxId, COUNT(*) AS COUNT_PASS
		FROM #ReceivableTaxGLPostingResultOutput
		WHERE Outage_Reason IN (@FailureMessage1,@FailureMessage6)
		GROUP BY ReceivableTaxId) AS a
		JOIN #TotalCountReceivableTaxes AS b ON a.ReceivableTaxId=b.ReceivableTaxId
		WHERE a.COUNT_PASS = b.TOTAL_COUNT)

		SET @ConfigMissingReceivableTaxesCount = (SELECT ISNULL(COUNT(DISTINCT ReceivableTaxId),0) FROM #ReceivableTaxGLPostingResultOutput WHERE Outage_Reason in (@FailureMessage7))

		SET @IncorrectlyGLPostedReceivableTaxesCount = @TotalReceivableTaxesCount - (@PassedReceivableTaxesCount + @NotGLPostedReceivableTaxesCount + @ConfigMissingReceivableTaxesCount)

		INSERT INTO @Messages(Name, ParameterValuesCsv) VALUES('TotalReceivables', (Select 'Receivables=' + CONVERT(nvarchar(40), @TotalReceivablesCount)))
		INSERT INTO @Messages(Name, ParameterValuesCsv) VALUES('ReceivableSuccessful', (Select 'ReceivableSuccessful=' + CONVERT(nvarchar(40), @PassedReceivablesCount)))
		INSERT INTO @Messages(Name, ParameterValuesCsv) VALUES('ReceivableIncorrect', (Select 'ReceivableIncorrect=' + CONVERT(nvarchar(40), @IncorrectlyGLPostedReceivablesCount)))
		INSERT INTO @Messages(Name, ParameterValuesCsv) VALUES('ReceivableNotPosted', (Select 'ReceivableNotPosted=' + CONVERT(nvarchar(40), @NotGLPostedReceivablesCount)))
		INSERT INTO @Messages(Name, ParameterValuesCsv) VALUES('ReceivableConfigMissing', (Select 'ReceivableConfig=' + CONVERT(nvarchar(40), @ConfigMissingReceivablesCount)))

		INSERT INTO @Messages(Name, ParameterValuesCsv) VALUES('TotalReceivableTaxes', (Select 'Receivables=' + CONVERT(nvarchar(40), @TotalReceivableTaxesCount)))
		INSERT INTO @Messages(Name, ParameterValuesCsv) VALUES('ReceivableTaxSuccessful', (Select 'ReceivableTaxSuccessful=' + CONVERT(nvarchar(40), @PassedReceivableTaxesCount)))
		INSERT INTO @Messages(Name, ParameterValuesCsv) VALUES('ReceivableTaxIncorrect', (Select 'ReceivableTaxIncorrect=' + CONVERT(nvarchar(40), @IncorrectlyGLPostedReceivableTaxesCount)))
		INSERT INTO @Messages(Name, ParameterValuesCsv) VALUES('ReceivableTaxNotPosted', (Select 'ReceivableTaxNotPosted=' + CONVERT(nvarchar(40), @NotGLPostedReceivableTaxesCount)))
		INSERT INTO @Messages(Name, ParameterValuesCsv) VALUES('ReceivableTaxConfigMissing', (Select 'ReceivableTaxConfig=' + CONVERT(nvarchar(40), @ConfigMissingReceivableTaxesCount)))

		INSERT INTO @Messages(Name, ParameterValuesCsv) VALUES('ReceivableResultOption', (Select 'ResultOption=' + CONVERT(nvarchar(40), @ResultOption)))

		SELECT * FROM @Messages

	IF OBJECT_ID('tempdb..#PrepaidReceivablesInfo') IS NOT NULL DROP TABLE #PrepaidReceivablesInfo
	IF OBJECT_ID('tempdb..#ReceivableGLPostingInfo') IS NOT NULL DROP TABLE #ReceivableGLPostingInfo
	IF OBJECT_ID('tempdb..#ReceivableGLPostingResultOutput') IS NOT NULL DROP TABLE #ReceivableGLPostingResultOutput
	IF OBJECT_ID('tempdb..#ReceivableTaxGLPostingResultOutput') IS NOT NULL DROP TABLE #ReceivableTaxGLPostingResultOutput
	IF OBJECT_ID('tempdb..#ExpectedGLPostedReceivables') IS NOT NULL DROP TABLE #ExpectedGLPostedReceivables
	IF OBJECT_ID('tempdb..#ExpectedGLPostedReceivableTaxes') IS NOT NULL DROP TABLE #ExpectedGLPostedReceivableTaxes
	IF OBJECT_ID('tempdb..#ReceivableTaxSyndicationDetails') IS NOT NULL DROP TABLE #ReceivableTaxSyndicationDetails
	IF OBJECT_ID('tempdb..#ExpectedEntryItemDetails') IS NOT NULL DROP TABLE #ExpectedEntryItemDetails
	IF OBJECT_ID('tempdb..#CTE_ReceivableDetails') IS NOT NULL DROP TABLE #CTE_ReceivableDetails
	IF OBJECT_ID('tempdb..#ReceivableActualAmountDerivation') IS NOT NULL DROP TABLE #ReceivableActualAmountDerivation
	IF OBJECT_ID('tempdb..#ReApplicationReceivables') IS NOT NULL DROP TABLE #ReApplicationReceivables
	IF OBJECT_ID('tempdb..#ReceivableGLJournalDetails') IS NOT NULL DROP TABLE #ReceivableGLJournalDetails
	IF OBJECT_ID('tempdb..#ReceivableTaxGLJournalDetails') IS NOT NULL DROP TABLE #ReceivableTaxGLJournalDetails
	IF OBJECT_ID('tempdb..#TaxReceivableActualAmountDerivation') IS NOT NULL DROP TABLE #TaxReceivableActualAmountDerivation
	IF OBJECT_ID('tempdb..#TotalCountReceivables') IS NOT NULL DROP TABLE #TotalCountReceivables
	IF OBJECT_ID('tempdb..#TotalCountReceivableTaxes') IS NOT NULL DROP TABLE #TotalCountReceivableTaxes
	SET NOCOUNT OFF
	SET ANSI_WARNINGS ON 
    END

GO
