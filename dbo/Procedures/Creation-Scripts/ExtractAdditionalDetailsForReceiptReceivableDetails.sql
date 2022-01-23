SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROC [dbo].[ExtractAdditionalDetailsForReceiptReceivableDetails]
(
@CreatedById										BIGINT,
@CreatedTime										DATETIMEOFFSET,
@JobStepInstanceId									BIGINT,
@SyndicationTypeValues_None							NVARCHAR(40),
@ChargeOffStatus_None								NVARCHAR(20),
@ReceivableSourceTableValues_Sundry					NVARCHAR(20),
@ReceivableSourceTableValues_SundryRecurring		NVARCHAR(20),
@ReceivableSourceTableValues_CPIReceivable			NVARCHAR(20),
@ReceivableSourceTableValues_LateFee				NVARCHAR(20),
@ReceivableSourceTableValues_AssetSaleReceivable	NVARCHAR(20),
@ReceivableSourceTableValues_CPUSchedule			NVARCHAR(20),
@WriteDownStatus_Approved							NVARCHAR(40),
@IsPrepaidDetailRequired							BIT,
@LeaseContractType									NVARCHAR(20),
@AccountingStandard									NVARCHAR(20),
@ReceivableType_FloatRate							NVARCHAR(20),
@ReceivableType_LoanInterest						NVARCHAR(20),
@ReceivableType_LoanPrincipal						NVARCHAR(20),
@IncomeType_InterimInterest							NVARCHAR(20),
@IncomeType_TakeDownInterest						NVARCHAR(20)
)
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;
	--Contract Level Details Begin
	CREATE TABLE #ContractDetails
	(
	ContractId									BIGINT,
	IsChargedOff								BIT,
	SequenceNumber								NVARCHAR(80),
	IsWrittenDown								BIT,
	IsSyndicatedContract						BIT,
	InstrumentTypeId							BIGINT,
	LineofBusinessId							BIGINT,
	CostCenterId								BIGINT,
	BranchId									BIGINT,
	AcquisitionId								NVARCHAR(24),
	DealProductTypeId							BIGINT,
	ContractType								NVARCHAR(28),
	NonAccrualDate								DATE,
	IsNonAccrual								BIT,
	IncomeGLTemplateId							BIGINT NULL,
	FloatIncomeGLTemplateId						BIGINT NULL,
	LeaseContractType							NVARCHAR(32) NULL,
	AccountingStandard							NVARCHAR(24) NULL,
	CurrentFinanceId							BIGINT NULL,
	LeaseBookingGLTemplateId					BIGINT,
	LeaseInterimInterestIncomeGLTemplateId		BIGINT,
	LeaseInterimRentIncomeGLTemplateId			BIGINT,
	LeveragedLeaseBookingGLTemplateId			BIGINT,
	LoanInterimIncomeRecognitionGLTemplateId	BIGINT,
	LoanBookingGLTemplateId						BIGINT,
	LoanIncomeRecognitionGLTemplateId			BIGINT,
	CommencementDate							DATE,
	DoubtfulCollectability						BIT,
	IsLease										BIT
	)

	SELECT ContractId
	INTO #ContractIds
	FROM ReceiptApplicationReceivableDetails_Extract RARD
	WHERE JobStepInstanceId = @JobStepInstanceId
	AND ContractId IS NOT NULL
	GROUP BY ContractId

	INSERT INTO #ContractDetails
	(ContractId, IsChargedOff, SequenceNumber, IsWrittenDown, IsSyndicatedContract, InstrumentTypeId, LineofBusinessId,
	CostCenterId, BranchId,	AcquisitionId, DealProductTypeId, ContractType, NonAccrualDate,	IsNonAccrual, IncomeGLTemplateId,
	FloatIncomeGLTemplateId, LeaseContractType, AccountingStandard,	CurrentFinanceId, LeaseBookingGLTemplateId,
	LeaseInterimInterestIncomeGLTemplateId,	LeaseInterimRentIncomeGLTemplateId, DoubtfulCollectability,IsLease)
	SELECT
	Contracts.Id ContractId,
	CASE WHEN Contracts.ChargeOffStatus != @ChargeOffStatus_None THEN CAST(1 AS BIT) ELSE CAST(0 AS BIT) END AS IsChargedOff,
	Contracts.SequenceNumber,
	CAST(0 AS BIT) IsWrittenDown,
	CASE WHEN Contracts.SyndicationType <> @SyndicationTypeValues_None THEN CAST(1 AS BIT) ELSE CAST(0 AS BIT) END AS IsSyndicatedContract,
	LeaseFinances.InstrumentTypeId,
	LeaseFinances.LineofBusinessId,
	LeaseFinances.CostCenterId,
	LeaseFinances.BranchId,
	LeaseFinances.AcquisitionId,
	Contracts.DealProductTypeId,
	Contracts.ContractType,
	Contracts.NonAccrualDate,
	Contracts.IsNonAccrual,
	LeaseFinanceDetails.LeaseIncomeGLTemplateId IncomeGLTemplateId,
	LeaseFinanceDetails.FloatIncomeGLTemplateId,
	LeaseFinanceDetails.LeaseContractType,
	Contracts.AccountingStandard,
	LeaseFinances.Id CurrentFinanceId,
	LeaseFinanceDetails.LeaseBookingGLTemplateId,
	LeaseFinanceDetails.InterimInterestIncomeGLTemplateId,
	LeaseFinanceDetails.InterimRentIncomeGLTemplateId,
	Contracts.DoubtfulCollectability,
	CAST(1 AS BIT) IsLease
	FROM #ContractIds AS ContractIds
	JOIN Contracts ON ContractIds.ContractId = Contracts.Id
	JOIN LeaseFinances ON Contracts.Id = LeaseFinances.ContractId AND LeaseFinances.IsCurrent = 1
	JOIN LeaseFinanceDetails ON LeaseFinances.Id=LeaseFinanceDetails.Id

	INSERT INTO #ContractDetails
	(ContractId, IsChargedOff, SequenceNumber, IsWrittenDown, IsSyndicatedContract, InstrumentTypeId, LineofBusinessId,
	CostCenterId, BranchId,	AcquisitionId, DealProductTypeId, ContractType, NonAccrualDate,	IsNonAccrual, LoanInterimIncomeRecognitionGLTemplateId,
	LoanBookingGLTemplateId, LoanIncomeRecognitionGLTemplateId, CommencementDate,IsLease)
	SELECT
	Contracts.Id ContractId,
	CASE WHEN Contracts.ChargeOffStatus != @ChargeOffStatus_None THEN CAST(1 AS BIT) ELSE CAST(0 AS BIT) END AS IsChargedOff,
	Contracts.SequenceNumber,
	CAST(0 AS BIT) IsWrittenDown,
	CASE WHEN Contracts.SyndicationType <> @SyndicationTypeValues_None THEN CAST(1 AS BIT) ELSE CAST(0 AS BIT) END AS IsSyndicatedContract,
	LoanFinances.InstrumentTypeId,
	LoanFinances.LineofBusinessId,
	LoanFinances.CostCenterId,
	LoanFinances.BranchId,
	LoanFinances.AcquisitionId,
	Contracts.DealProductTypeId,
	Contracts.ContractType,
	Contracts.NonAccrualDate,
	Contracts.IsNonAccrual,
	LoanFinances.LoanIncomeRecognitionGLTemplateId,
	LoanFinances.LoanBookingGLTemplateId,
	LoanFinances.LoanIncomeRecognitionGLTemplateId,
	LoanFinances.CommencementDate,
	CAST(0 AS BIT) IsLease
	FROM #ContractIds AS ContractIds
	JOIN Contracts ON ContractIds.ContractId = Contracts.Id
	JOIN LoanFinances ON Contracts.Id = LoanFinances.ContractId AND LoanFinances.IsCurrent = 1

	INSERT INTO #ContractDetails
	(ContractId, IsChargedOff, SequenceNumber, IsWrittenDown, IsSyndicatedContract, InstrumentTypeId, LineofBusinessId,
	CostCenterId, BranchId,	AcquisitionId, DealProductTypeId, ContractType, NonAccrualDate,	IsNonAccrual, LeveragedLeaseBookingGLTemplateId,IsLease)
	SELECT
	Contracts.Id ContractId,
	CASE WHEN Contracts.ChargeOffStatus != @ChargeOffStatus_None THEN CAST(1 AS BIT) ELSE CAST(0 AS BIT) END AS IsChargedOff,
	Contracts.SequenceNumber,
	CAST(0 AS BIT) IsWrittenDown,
	CASE WHEN Contracts.SyndicationType <> @SyndicationTypeValues_None THEN CAST(1 AS BIT) ELSE CAST(0 AS BIT) END AS IsSyndicatedContract,
	LeveragedLeases.InstrumentTypeId,
	LeveragedLeases.LineofBusinessId,
	LeveragedLeases.CostCenterId,
	NULL AS BranchId,
	LeveragedLeases.AcquisitionId,
	Contracts.DealProductTypeId,
	Contracts.ContractType,
	Contracts.NonAccrualDate,
	Contracts.IsNonAccrual,
	LeveragedLeases.BookingGLTemplateId,
	CAST(0 AS BIT) IsLease
	FROM #ContractIds AS ContractIds
	JOIN Contracts ON ContractIds.ContractId = Contracts.Id
	JOIN LeveragedLeases ON Contracts.Id = LeveragedLeases.ContractId AND LeveragedLeases.IsCurrent = 1

	UPDATE #ContractDetails
	SET IsWrittenDown = 1
	WHERE EXISTS(SELECT 1 FROM WriteDowns WD WHERE WD.ContractId = #ContractDetails.ContractId AND WD.IsActive=1 AND WD.Status = @WriteDownStatus_Approved);
	--Contract Level Details End

	;WITH CTE_RARD AS
	(
	SELECT ReceivableId, ContractId, DiscountingId
	FROM ReceiptApplicationReceivableDetails_Extract RARD
	WHERE RARD.JobStepInstanceId = @JobStepInstanceId
	GROUP BY ReceivableId, ContractId, DiscountingId
	)
	SELECT
	RARD.ReceivableId,
	RARD.ContractId,
	RARD.DiscountingId,
	R.[SourceTable],
	R.[SourceId],
	R.[EntityType],
	R.[EntityId],
	R.[IncomeType],
	RT.Id [ReceivableTypeId],
	RT.Name [ReceivableType],
	R.[PaymentScheduleId],
	R.[DueDate],
	R.[LegalEntityId],
	R.[CustomerId],
	R.[FunderId],
	R.[IsGLPosted],
	GLT.Name [GLTransactionType],
	R.TotalBalance_Amount [ReceivableBalance],
	R.TotalAmount_Amount [ReceivableTotalAmount],
	RC.GLTemplateId [ReceivableGLTemplateId],
	RC.SyndicationGLTemplateId [SyndicationGLTemplateId],
	RC.[AccountingTreatment],
	P.IsIntercompany [IsIntercompany],
	R.AlternateBillingCurrencyId,
	R.ExchangeRate,
	CASE WHEN R.[FunderId] IS NULL THEN CAST(0 AS BIT) ELSE CAST(1 AS BIT) END AS [IsSyndicated]
	INTO #Receivables
	FROM CTE_RARD RARD
	INNER JOIN Receivables R ON RARD.ReceivableId = R.Id
	INNER JOIN ReceivableCodes RC ON R.ReceivableCodeId = RC.Id 
	INNER JOIN ReceivableTypes RT ON RC.ReceivableTypeId = RT.Id AND RT.IsActive = 1
	INNER JOIN GLTemplates GT ON RC.GLTemplateId = GT.Id
	INNER JOIN GLTransactionTypes GLT ON GT.GLTransactionTypeId = GLT.Id
	INNER JOIN Parties P ON R.CustomerId = P.Id

	-- NonAccrualAssetDetails
	CREATE TABLE #AssetDetailsForNonAccrualReceivables
	(
	AssetId				BIGINT,
	IsLeaseAsset		BIT,
	ContractId		    BIGINT
	)

	-- BEGIN ReceivableGLInfo
	CREATE TABLE #ReceivableGLInfo
	(
	ReceivableId				BIGINT,
	InstrumentTypeId			BIGINT,
	LineofBusinessId			BIGINT,
	CostCenterId				BIGINT,
	BranchId					BIGINT,
	AcquisitionID				NVARCHAR(24),
	DealProductTypeId			BIGINT,
	ClearingAPGLTemplateId		BIGINT,
	PaymentStartDate			DATE
	)

	INSERT INTO #ReceivableGLInfo
	(ReceivableId, InstrumentTypeId, LineofBusinessId, CostCenterId, BranchId, ClearingAPGLTemplateId)
	SELECT Receivables.ReceivableId ReceivableId,
	Sundries.InstrumentTypeId,
	Sundries.LineofBusinessId,
	Sundries.CostCenterId,
	Sundries.BranchId,
	CASE WHEN DisbursementRequests.APGLTemplateId IS NOT NULL THEN DisbursementRequests.APGLTemplateId
	ELSE PaymentVoucherInfoes.APGLTemplateId END AS ClearingAPGLTemplateId
	FROM #Receivables AS Receivables
	JOIN Sundries ON Receivables.SourceId = Sundries.Id AND Receivables.SourceTable = @ReceivableSourceTableValues_Sundry
	LEFT JOIN DisbursementRequests ON DisbursementRequests.SundryId = Sundries.Id
	LEFT JOIN PaymentVoucherInfoes ON PaymentVoucherInfoes.SundryId = Sundries.Id
	WHERE Receivables.ContractId IS NULL AND Receivables.DiscountingId IS NULL

	INSERT INTO #ReceivableGLInfo
	(ReceivableId, InstrumentTypeId, LineofBusinessId, CostCenterId, BranchId)
	SELECT Receivables.ReceivableId ReceivableId,
	InstrumentTypeId,
	LineofBusinessId,
	CostCenterId,
	BranchId
	FROM #Receivables AS Receivables
	JOIN SundryRecurringPaymentSchedules ON Receivables.SourceId = SundryRecurringPaymentSchedules.Id
	AND Receivables.SourceTable = @ReceivableSourceTableValues_SundryRecurring
	AND Receivables.ContractId IS NULL AND Receivables.DiscountingId IS NULL
	JOIN SundryRecurrings ON SundryRecurringPaymentSchedules.SundryRecurringId = SundryRecurrings.Id
	WHERE Receivables.ContractId IS NULL AND Receivables.DiscountingId IS NULL

	INSERT INTO #ReceivableGLInfo
	(ReceivableId, InstrumentTypeId, LineofBusinessId, CostCenterId)
	SELECT Receivables.ReceivableId ReceivableId,
	InstrumentTypeId,
	LineofBusinessId,
	CostCenterId
	FROM #Receivables AS Receivables
	JOIN CPIReceivables ON Receivables.SourceId = CPIReceivables.Id
	AND Receivables.SourceTable = @ReceivableSourceTableValues_CPIReceivable
	AND Receivables.ContractId IS NULL AND Receivables.DiscountingId IS NULL
	JOIN CPISchedules ON CPIReceivables.CPIScheduleId = CPISchedules.Id
	JOIN CPIContracts ON CPISchedules.CPIContractId = CPIContracts.Id
	WHERE Receivables.ContractId IS NULL AND Receivables.DiscountingId IS NULL

	INSERT INTO #ReceivableGLInfo
	(ReceivableId, InstrumentTypeId, LineofBusinessId, CostCenterId)
	SELECT Receivables.ReceivableId ReceivableId,
	InstrumentTypeId,
	LineofBusinessId,
	CostCenterId
	FROM #Receivables AS Receivables
	JOIN SecurityDeposits ON Receivables.ReceivableId = SecurityDeposits.ReceivableId
	WHERE Receivables.ContractId IS NULL AND Receivables.DiscountingId IS NULL

	INSERT INTO #ReceivableGLInfo
	(ReceivableId, InstrumentTypeId, LineofBusinessId, CostCenterId)
	SELECT Receivables.ReceivableId ReceivableId,
	InstrumentTypeId,
	LineofBusinessId,
	CostCenterId
	FROM #Receivables AS Receivables
	JOIN LateFeeReceivables ON Receivables.SourceId = LateFeeReceivables.Id
	AND Receivables.SourceTable = @ReceivableSourceTableValues_LateFee
	WHERE Receivables.ContractId IS NULL AND Receivables.DiscountingId IS NULL

	INSERT INTO #ReceivableGLInfo
	(ReceivableId, InstrumentTypeId, LineofBusinessId, CostCenterId, BranchId)
	SELECT Receivables.ReceivableId ReceivableId,
	InstrumentTypeId,
	LineofBusinessId,
	CostCenterId ,
	BranchId
	FROM #Receivables AS Receivables
	JOIN AssetSaleReceivables ON Receivables.SourceId = AssetSaleReceivables.Id
	AND Receivables.SourceTable = @ReceivableSourceTableValues_AssetSaleReceivable
	AND Receivables.ContractId IS NULL AND Receivables.DiscountingId IS NULL
	JOIN AssetSales ON AssetSaleReceivables.AssetSaleId = AssetSales.Id
	WHERE Receivables.ContractId IS NULL AND Receivables.DiscountingId IS NULL

	INSERT INTO #ReceivableGLInfo
	(ReceivableId, InstrumentTypeId, LineofBusinessId, CostCenterId, BranchId)
	SELECT Receivables.ReceivableId ReceivableId,
	InstrumentTypeId,
	LineofBusinessId,
	CostCenterId,
	BranchId
	FROM #Receivables AS Receivables
	JOIN CPUSchedules ON Receivables.SourceId = CPUSchedules.Id
	AND Receivables.SourceTable = @ReceivableSourceTableValues_CPUSchedule
	AND Receivables.ContractId IS NULL AND Receivables.DiscountingId IS NULL
	JOIN CPUAccountings ON CPUSchedules.CPUFinanceId = CPUAccountings.Id
	WHERE Receivables.ContractId IS NULL AND Receivables.DiscountingId IS NULL

	INSERT INTO #ReceivableGLInfo
	(ReceivableId, InstrumentTypeId, LineofBusinessId, CostCenterId, BranchId)
	SELECT Receivables.ReceivableId ReceivableId,
	InstrumentTypeId,
	LineofBusinessId,
	CostCenterId ,
	BranchId
	FROM #Receivables AS Receivables
	JOIN DiscountingFinances ON Receivables.DiscountingId = DiscountingFinances.DiscountingId AND DiscountingFinances.IsCurrent = 1

	INSERT INTO #ReceivableGLInfo
	(ReceivableId, InstrumentTypeId, LineofBusinessId, CostCenterId, BranchId, AcquisitionID, DealProductTypeId,PaymentStartDate)
	SELECT Receivables.ReceivableId ReceivableId,
	InstrumentTypeId,
	LineofBusinessId,
	CostCenterId,
	BranchId,
	AcquisitionID,
	DealProductTypeId,
	LPS.StartDate PaymentStartDate
	FROM #Receivables AS Receivables
	JOIN #ContractDetails C ON Receivables.ContractId = C.ContractId
	LEFT JOIN LeasePaymentSchedules LPS on Receivables.PaymentScheduleId=LPS.Id AND C.IsLease = 1
	-- END ReceivableGLInfo

	--PrepaidReceivableIdInfo
	CREATE TABLE #PrepaidReceivableExtract
	(
	ReceiptApplicationReceivableDetailId	BIGINT,
	PrepaidReceivableId						BIGINT,
	CurrentPrepaidAmount					DECIMAL(16,2),
	CurrentPrepaidTaxAmount					DECIMAL(16,2),
	CurrentPrepaidFinanceAmount				DECIMAL(16,2)
	)

	IF @IsPrepaidDetailRequired = 1
	BEGIN
	INSERT INTO #PrepaidReceivableExtract
	SELECT
	RARD.Id ReceiptApplicationReceivableDetailId,
	PR.Id PrepaidReceivableId,
	PR.PrePaidAmount_Amount AS CurrentPrepaidAmount,
	PR.PrePaidTaxAmount_Amount AS CurrentPrepaidTaxAmount,
	FinancingPrePaidAmount_Amount AS CurrentPrepaidFinanceAmount
	FROM ReceiptApplicationReceivableDetails_Extract RARD
	JOIN PrepaidReceivables PR ON RARD.ReceivableId = PR.ReceivableId
	AND RARD.ReceiptId = PR.ReceiptId AND RARD.JobStepInstanceId = @JobStepInstanceId
	END
	--
	INSERT INTO #AssetDetailsForNonAccrualReceivables
		SELECT Distinct LA.AssetId,LA.IsLeaseAsset,C.ContractId
		FROM ReceiptApplicationReceivableDetails_Extract RARD 
		JOIN #ContractDetails C ON RARD.ContractId=C.ContractId AND RARD.JobStepInstanceId = @JobStepInstanceId
		JOIN LeaseFinances LF on LF.ContractId=C.ContractId
		JOIN LeaseAssets LA on  LF.Id=LA.LeaseFinanceId 
		WHERE (LA.IsActive=1 OR LA.TerminationDate IS NOT NULL) 
		AND C.IsNonAccrual=1 AND C.DoubtfulCollectability=1
		AND C.LeaseContractType=@LeaseContractType AND C.AccountingStandard=@AccountingStandard
		AND C.IsChargedOff=0

	SELECT R.*, RD.[AssetComponentType], RD.Amount_Amount, RD.Balance_Amount, RD.AssetId, RD.AdjustmentBasisReceivableDetailId,
	RD.LeaseComponentAmount_Amount,
	RD.NonLeaseComponentAmount_Amount 
	INTO #ReceivableDetail
	FROM ReceiptApplicationReceivableDetails_Extract R
	INNER JOIN ReceivableDetails RD
		ON R.ReceivableDetailId = RD.Id
	WHERE JobStepInstanceId = @JobStepInstanceId

	SELECT 
		ARD.Id AS RARD_ExtractId
	INTO #AdjustedReceivableDetail
	FROM #ReceivableDetail ARD
	INNER JOIN ReceivableDetails RD 
		ON ARD.ReceivableDetailId = RD.AdjustmentBasisReceivableDetailId
		AND RD.IsActive = 1
		AND RD.AdjustmentBasisReceivableDetailId IS NOT NULL

	;WITH CTE_RT AS
	(
	SELECT
	ReceivableTaxDetails.ReceivableDetailId,
	ReceivableTaxDetails.IsGLPosted,
	ReceivableTaxDetails.IsActive,
	ReceivableTaxes.IsCashBased,
	ReceivableTaxes.GLTemplateId
	FROM ReceiptApplicationReceivableDetails_Extract AS RARD
	JOIN ReceivableTaxDetails ON RARD.JobStepInstanceId = @JobStepInstanceId
	AND RARD.ReceivableDetailId = ReceivableTaxDetails.ReceivableDetailId
	AND ReceivableTaxDetails.IsActive=1
	JOIN ReceivableTaxes ON ReceivableTaxDetails.ReceivableTaxId = ReceivableTaxes.Id AND ReceivableTaxes.IsActive=1
	GROUP BY ReceivableTaxDetails.ReceivableDetailId,ReceivableTaxDetails.IsGLPosted,ReceivableTaxDetails.IsActive,ReceivableTaxes.IsCashBased,ReceivableTaxes.GLTemplateId
	)

INSERT INTO [dbo].[ReceiptReceivableDetails_Extract]
([ReceiptId],[ReceivableDetailId],[ReceivableId],[ReceiptApplicationReceivableDetailId],[AmountApplied],[BookAmountApplied],[TaxApplied]
,[PrevAmountAppliedForReApplication], [PrevBookAmountAppliedForReApplication], [PrevTaxAppliedForReApplication], [PrevAdjustedWithHoldingTaxForReApplication], [ReceiptApplicationId]
,[CreatedById],[CreatedTime],[ContractId],[DiscountingId],[InvoiceId],[DumpId],[ReceivableDetailIsActive], [ReceivableTaxDetailIsActive]
,[IsChargeoffContract],[IsWritedownContract],[IsChargeoffReceivable],[IsWritedownReceivable],[IsSyndicatedContract],[IsSyndicated]
,[AlternateBillingCurrencyId],[ExchangeRate],[ReceivableTypeId],[ReceivableType],[PaymentScheduleId],[SequenceNumber],[DueDate]
,[LegalEntityId],[CustomerId],[FunderId],[AssetComponentType],[IsNegativeReceivable],[IsGLPosted],[IsTaxGLPosted],[IsTaxCashBased]
,[SourceTable],[SourceId],[EntityType],[EntityId],[IncomeType],[GLTransactionType],[ReceivableBalance],[ReceivableDetailBalance]
,[ReceivableTotalAmount],[ReceivableGLTemplateId],[SyndicationGLTemplateId],[AccountingTreatment],[IsIntercompany]
,[ReceivableTaxGLTemplateId],[ClearingAPGLTemplateId],[InstrumentTypeId],[CostCenterId] ,[LineofBusinessID],[BranchId],[DealProductTypeId]
,[AcquisitionId],[ContractType],[IsTiedToDiscounting],[AssetId],IsNonAccrual,[IsAdjustmentReceivableDetail],[NonAccrualDate],[JobStepInstanceId],[IsReApplication]
,[PrevPrePaidForReApplication],[PrevPrePaidTaxForReApplication],[IncomeGLTemplateId],[PaymentScheduleStartDate],[LeaseContractType],[AccountingStandard]
,[CurrentFinanceId],[IsLeaseAsset],[LeaseBookingGLTemplateId],[LeaseInterimInterestIncomeGLTemplateId]
,[LeaseInterimRentIncomeGLTemplateId],[LeveragedLeaseBookingGLTemplateId],[LoanInterimIncomeRecognitionGLTemplateId],[LoanBookingGLTemplateId]
,[LoanIncomeRecognitionGLTemplateId],[CommencementDate],[PrepaidReceivableId],[DoubtfulCollectability]
,[CurrentPrepaidAmount],[CurrentPrepaidTaxAmount],[CurrentPrepaidFinanceAmount],[AdjustedWithHoldingTax]
,[LeaseComponentAmountApplied],[NonLeaseComponentAmountApplied],[PrevLeaseComponentAmountAppliedForReApplication],[PrevNonLeaseComponentAmountAppliedForReApplication]
,[PrevPrePaidLeaseComponentForReApplication],[PrevPrePaidNonLeaseComponentForReApplication],[ReceivedTowardsInterest], [WithHoldingTaxBookAmountApplied])
SELECT
RARD.[ReceiptId],
RARD.ReceivableDetailId [ReceivableDetailId],
RARD.ReceivableId [ReceivableId],
RARD.[ReceiptApplicationReceivableDetailId],
RARD.[AmountApplied],
RARD.[BookAmountApplied],
RARD.[TaxApplied],
ISNULL(RARD.[PrevAmountAppliedForReApplication], 0.0) [PrevAmountAppliedForReApplication],
ISNULL(RARD.[PrevBookAmountAppliedForReApplication],0.0) [PrevBookAmountAppliedForReApplication],
ISNULL(RARD.[PrevTaxAppliedForReApplication], 0) [PrevTaxAppliedForReApplication],
ISNULL(RARD.[PrevAdjustedWithHoldingTaxForReApplication], 0) [PrevAdjustedWithHoldingTaxForReApplication],
RARD.[ReceiptApplicationId],
@CreatedById,
@CreatedTime,
R.[ContractId],
R.[DiscountingId],
RARD.[InvoiceId],
RARD.[DumpId],
RARD.[ReceivableDetailIsActive],
ISNULL(RT.IsActive,CAST(0 AS BIT)) [ReceivableTaxDetailIsActive],
ISNULL(C.IsChargedOff,0) [IsChargeoffContract],
ISNULL(C.IsWrittenDown,0) [IsWritedownContract],
0 [IsChargeoffReceivable],
0 [IsWritedownReceivable],
ISNULL(C.IsSyndicatedContract,0) [IsSyndicatedContract],
R.[IsSyndicated],
R.[AlternateBillingCurrencyId],
R.[ExchangeRate],
R.[ReceivableTypeId],
R.[ReceivableType],
R.[PaymentScheduleId],
C.[SequenceNumber],
R.[DueDate],
R.[LegalEntityId],
R.[CustomerId],
R.[FunderId],
RARD.[AssetComponentType],
CASE WHEN RARD.Amount_Amount >= 0 THEN CAST(0 AS BIT) ELSE CAST(1 AS BIT) END [IsNegativeReceivable],
R.[IsGLPosted],
ISNULL(RT.IsGLPosted,CAST(0 AS BIT)) [IsTaxGLPosted],
ISNULL(RT.IsCashBased,CAST(0 AS BIT)) [IsTaxCashBased],
R.[SourceTable],
R.[SourceId],
R.[EntityType],
R.[EntityId],
R.[IncomeType],
R.[GLTransactionType],
R.[ReceivableBalance],
RARD.Balance_Amount [ReceivableDetailBalance],
R.[ReceivableTotalAmount],
R.[ReceivableGLTemplateId],
R.[SyndicationGLTemplateId],
R.[AccountingTreatment],
R.IsIntercompany [IsIntercompany],
RT.GLTemplateId [ReceivableTaxGLTemplateId],
RGL.[ClearingAPGLTemplateId],
RGL.[InstrumentTypeId],
RGL.[CostCenterId],
RGL.[LineofBusinessID],
RGL.[BranchId],
RGL.[DealProductTypeId],
RGL.[AcquisitionId],
C.[ContractType],
CAST(0 AS BIT) [IsTiedToDiscounting],
RARD.AssetId,
ISNULL(C.IsNonAccrual,0) [IsNonAccrual],
CASE WHEN RARD.AdjustmentBasisReceivableDetailId IS NOT NULL OR AdjustmentReceivableDetail.RARD_Extractid IS NOT NULL
THEN CAST(1 AS BIT)
ELSE CAST(0 AS BIT)
END [IsAdjustmentReceivableDetail],
C.[NonAccrualDate],
@JobStepInstanceId,
RARD.IsReApplication,
ISNULL(RARD.PrevPrePaidForReApplication, 0.00),
ISNULL(RARD.PrevPrePaidTaxForReApplication, 0.00),
CASE WHEN  R.ReceivableType =@ReceivableType_FloatRate THEN C.FloatIncomeGLTemplateId
ELSE   C.IncomeGLTemplateId END [IncomeGLTemplateId],
RGL.[PaymentStartDate] PaymentScheduleStartDate,
C.[LeaseContractType],
C.[AccountingStandard],
C.[CurrentFinanceId],
ISNULL(AssetDetails.IsLeaseAsset,CAST(0 AS BIT)) AS IsLeaseAsset,
C.LeaseBookingGLTemplateId,
C.LeaseInterimInterestIncomeGLTemplateId,
C.LeaseInterimRentIncomeGLTemplateId,
C.LeveragedLeaseBookingGLTemplateId,
C.LoanInterimIncomeRecognitionGLTemplateId,
C.LoanBookingGLTemplateId,
C.LoanIncomeRecognitionGLTemplateId,
C.CommencementDate,
PR.PrepaidReceivableId,
ISNULL(C.DoubtfulCollectability,0) DoubtfulCollectability,
ISNULL(PR.CurrentPrepaidAmount, 0),
ISNULL(PR.CurrentPrepaidTaxAmount, 0),
ISNULL(PR.CurrentPrepaidFinanceAmount, 0),
ISNULL(RARD.AdjustedWithHoldingTax, 0),
ISNULL(RARD.LeaseComponentAmountApplied, 0.00) [LeaseComponentAmountApplied],
ISNULL(RARD.NonLeaseComponentAmountApplied, 0.00) [NonLeaseComponentAmountApplied],
ISNULL(RARD.PrevLeaseComponentAmountAppliedForReApplication, 0.00) [PrevLeaseComponentAmountAppliedForReApplication],
ISNULL(RARD.PrevNonLeaseComponentAmountAppliedForReApplication, 0.00) [PrevNonLeaseComponentAmountAppliedForReApplication],
ISNULL(RARD.PrevPrePaidLeaseComponentForReApplication, 0.00) [PrevPrePaidLeaseComponentForReApplication],
ISNULL(RARD.PrevPrePaidNonLeaseComponentForReApplication, 0.00) [PrevPrePaidNonLeaseComponentForReApplication],
ISNULL(RARD.ReceivedTowardsInterest, 0),
CASE 
	WHEN 
		ISNULL(C.IsNonAccrual,0) = 0 AND ISNULL(RARD.WithHoldingTaxBookAmountApplied, 0) = 0
		AND ((R.[ReceivableType] = @ReceivableType_LoanInterest OR R.[ReceivableType] = @ReceivableType_LoanPrincipal) 
		AND (R.[IncomeType] != @IncomeType_InterimInterest AND R.[IncomeType] != @IncomeType_TakeDownInterest)) 
	THEN ISNULL(RARD.AdjustedWithHoldingTax, 0)
	ELSE 
		ISNULL(RARD.WithHoldingTaxBookAmountApplied, 0)
END
FROM #ReceivableDetail AS RARD
INNER JOIN #Receivables [R] ON RARD.ReceivableId = R.ReceivableId
INNER JOIN #ReceivableGLInfo [RGL] ON R.ReceivableId = RGL.ReceivableId
LEFT JOIN #ContractDetails [C] ON R.ContractId = C.ContractId
LEFT JOIN CTE_RT AS RT ON RARD.ReceivableDetailId = RT.ReceivableDetailId
LEFT JOIN #AdjustedReceivableDetail AdjustmentReceivableDetail ON RARD.Id = AdjustmentReceivableDetail.RARD_ExtractId
LEFT JOIN #AssetDetailsForNonAccrualReceivables AssetDetails on C.ContractId=AssetDetails.ContractId AND RARD.AssetId=AssetDetails.AssetId
LEFT JOIN #PrepaidReceivableExtract PR ON RARD.Id = PR.ReceiptApplicationReceivableDetailId
DROP TABLE #ContractIds
DROP TABLE #ContractDetails
DROP TABLE #Receivables
DROP TABLE #ReceivableGLInfo
DROP TABLE #PrepaidReceivableExtract
END

GO
