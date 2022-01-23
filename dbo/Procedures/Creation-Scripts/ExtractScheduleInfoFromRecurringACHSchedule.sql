SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[ExtractScheduleInfoFromRecurringACHSchedule]
(
 @FromDate DATETIMEOFFSET
,@ToDate DATETIMEOFFSET
,@ExcludeBackgroundProcessingPendingContracts BIT
,@LegalEntityBankInfo LegalEntityBankInfoForACHUpdate READONLY
,@ContractId BIGINT
,@CustomerId BIGINT
,@EntityType NVARCHAR(30)
,@FilterOption NVARCHAR(MAX)
,@UseProgramVendorAsCompanyName BIT
,@AllowInterCompanyTransfer BIT
,@JobStepInstanceId BIGINT
,@ReceiptGLTemplateId BIGINT
,@ReceiptGLTemplateName NVARCHAR(40)
,@CreatedById BIGINT
,@CreatedTime DATETIMEOFFSET
,@AnyrecordExists BIT OUT
,@WebOneTimePAPReceiptTypeValue NVARCHAR(50)
,@WebOneTimeACHReceiptTypeValue NVARCHAR(50)
,@ACHReceiptTypeValue NVARCHAR(50)
,@PAPReceiptTypeValue NVARCHAR(50)
,@UnknownReceiptTypeValue NVARCHAR(50)
,@LeaseEntityType NVARCHAR(10)
,@LoanEntityType NVARCHAR(10)
,@CustomerEntityType NVARCHAR(10)
,@DiscountingEntityType NVARCHAR(20)
,@OneFilterOption NVARCHAR(3)
,@AllFilterOption NVARCHAR(3)
,@PendingACHStatus NVARCHAR(20)
,@ThresholdExceededACHStatus NVARCHAR(20)
,@LeaseContractType NVARCHAR(20)
,@LoanContractType NVARCHAR(20)
,@ProgressLoanContractType NVARCHAR(20)
,@UnCommencedContractStatus NVARCHAR(50)
,@CommencedContractStatus NVARCHAR(50)
,@FullPaymentType NVARCHAR(15)
,@ReceivableOnlyPaymentType NVARCHAR(15)
,@TaxOnlyPaymentType NVARCHAR(15)
,@ACHOrPAPAutomatedMethod NVARCHAR(10)
,@ApprovedSyndicationStatus NVARCHAR(50)
,@UnknownSyndicationType NVARCHAR(15)
,@NoneSyndicationType NVARCHAR(15)
,@ACHFileFormat NVARCHAR(10)
,@PAPFileFormat NVARCHAR(10)
,@DSLReceiptClassficationType NVARCHAR(18)
,@CashReceiptClassficationType NVARCHAR(18)
,@NonAccrualNonDSLReceiptClassficationType NVARCHAR(18)
,@DownPaymentPaymentTypevalue NVARCHAR(34)
,@InterimPaymentTypeValue NVARCHAR(34)
,@LoanPrincipalReceivableTypeName  NVARCHAR(32)
,@LoanInterestReceivableTypeName  NVARCHAR(32)
,@InterimInterestIncomeType  NVARCHAR(28)
,@TakeDownInterestIncomeType  NVARCHAR(28)
,@CTReceivableEntityType NVARCHAR(10)
,@DTReceivableEntityType NVARCHAR(10)
,@CUReceivableEntityType NVARCHAR(10)
,@ApprovedBookingStatus NVARCHAR(50)
,@PartiallyCompletedACHStatus NVARCHAR(50)
,@ProcessingACHStatus NVARCHAR(50)
,@FromCustomerId BIGINT
,@ToCustomerId BIGINT
,@ACHPaymentThresholdNotification NVARCHAR(50)
,@ACHReceiptTypeId BIGINT
,@PAPReceiptTypeId BIGINT
,@WebACHReceiptTypeId BIGINT
,@WebPAPReceiptTypeId BIGINT
,@DefaultCashTypeId BIGINT
)
AS
BEGIN

--declare @LegalEntityBankInfo dbo.LegalEntityBankInfoForACHUpdate
--insert into @LegalEntityBankInfo values(20039,131,'2018-01-08 00:00:00','2020-04-29 00:00:00',NULL,NULL,'2020-04-22 00:00:00',1)
--insert into @LegalEntityBankInfo values(20039,173,'2018-01-08 00:00:00','2020-04-29 00:00:00',NULL,NULL,'2020-04-22 00:00:00',2)
--insert into @LegalEntityBankInfo values(20031,115,'2018-01-01 00:00:00','2020-04-22 00:00:00',NULL,NULL,'2020-04-22 00:00:00',1)
--insert into @LegalEntityBankInfo values(20028,102,'2018-01-08 00:00:00','2020-04-29 00:00:00',NULL,NULL,'2020-04-22 00:00:00',1)
--insert into @LegalEntityBankInfo values(1,18,'2018-01-01 00:00:00','2020-04-22 00:00:00',NULL,NULL,'2020-04-22 00:00:00',1)
--insert into @LegalEntityBankInfo values(1,163,'2018-01-01 00:00:00','2020-04-22 00:00:00',NULL,NULL,'2020-04-22 00:00:00',2)
--insert into @LegalEntityBankInfo values(1,26,'2018-01-01 00:00:00','2020-04-22 00:00:00',NULL,NULL,'2020-04-22 00:00:00',0)
--insert into @LegalEntityBankInfo values(20103,127943,'2018-01-08 00:00:00','2020-04-29 00:00:00',NULL,NULL,'2020-04-22 00:00:00',1)
--insert into @LegalEntityBankInfo values(20088,127925,'2018-01-08 00:00:00','2020-04-29 00:00:00',NULL,NULL,'2020-04-22 00:00:00',1)
--insert into @LegalEntityBankInfo values(20102,127942,'2018-01-08 00:00:00','2020-04-29 00:00:00',NULL,NULL,'2020-04-22 00:00:00',1)
--insert into @LegalEntityBankInfo values(20101,127941,'2018-01-08 00:00:00','2020-04-29 00:00:00',NULL,NULL,'2020-04-22 00:00:00',1)
--insert into @LegalEntityBankInfo values(20100,127940,'2018-01-08 00:00:00','2020-04-29 00:00:00',NULL,NULL,'2020-04-22 00:00:00',1)
--insert into @LegalEntityBankInfo values(20099,127938,'2018-01-08 00:00:00','2020-04-29 00:00:00',NULL,NULL,'2020-04-22 00:00:00',1)
--insert into @LegalEntityBankInfo values(20098,127937,'2018-01-08 00:00:00','2020-04-29 00:00:00',NULL,NULL,'2020-04-22 00:00:00',39)
--insert into @LegalEntityBankInfo values(20097,127936,'2018-01-08 00:00:00','2020-04-29 00:00:00',NULL,NULL,'2020-04-22 00:00:00',1)
--insert into @LegalEntityBankInfo values(20096,127935,'2018-01-08 00:00:00','2020-04-29 00:00:00',NULL,NULL,'2020-04-22 00:00:00',39)
--insert into @LegalEntityBankInfo values(20095,127934,'2018-01-08 00:00:00','2020-04-29 00:00:00',NULL,NULL,'2020-04-22 00:00:00',3)
--insert into @LegalEntityBankInfo values(20094,127933,'2018-01-08 00:00:00','2020-04-29 00:00:00',NULL,NULL,'2020-04-22 00:00:00',3)
--insert into @LegalEntityBankInfo values(20093,127932,'2018-01-08 00:00:00','2020-04-29 00:00:00',NULL,NULL,'2020-04-22 00:00:00',3)
--insert into @LegalEntityBankInfo values(20092,127931,'2018-01-01 00:00:00','2020-04-22 00:00:00',NULL,NULL,'2020-04-22 00:00:00',1)
--insert into @LegalEntityBankInfo values(20091,127929,'2018-01-01 00:00:00','2020-04-22 00:00:00',NULL,NULL,'2020-04-22 00:00:00',2)
--insert into @LegalEntityBankInfo values(20090,127928,'2018-01-01 00:00:00','2020-04-22 00:00:00',NULL,NULL,'2020-04-22 00:00:00',1)
--insert into @LegalEntityBankInfo values(20090,127927,'2018-01-01 00:00:00','2020-04-22 00:00:00',NULL,NULL,'2020-04-22 00:00:00',2)
--insert into @LegalEntityBankInfo values(20089,127926,'2018-01-01 00:00:00','2020-04-22 00:00:00',NULL,NULL,'2020-04-23 00:00:00',1)


--DECLARE
-- @FromDate DATETIMEOFFSET ='0001-01-01 00:00:00 +00:00'
--,@ToDate DATETIMEOFFSET = '2018-01-01 00:00:00 +05:30'
--,@ContractId BIGINT =0
--,@CustomerId BIGINT =0
--,@EntityType NVARCHAR(30) ='CUSTOMER'
--,@FilterOption NVARCHAR(MAX) ='ALL'
--,@UseProgramVendorAsCompanyName BIT =0
--,@AllowInterCompanyTransfer BIT=0
--,@JobStepInstanceId BIGINT =3662
--,@ReceiptGLTemplateId BIGINT =10231
--,@ReceiptGLTemplateName NVARCHAR(40) =N'DF_Receipt GL Template'
--,@CreatedById BIGINT =40425
--,@CreatedTime DATETIMEOFFSET  =GETDATE()
--,@NewCashType    NVARCHAR(20) =N'New'
--,@WebOneTimePAPReceiptTypeValue NVARCHAR(50) =N'WebOneTimePAP'
--,@WebOneTimeACHReceiptTypeValue NVARCHAR(50) =N'WebOneTimeACH'
--,@ACHReceiptTypeValue NVARCHAR(50) =N'ACH'
--,@PAPReceiptTypeValue NVARCHAR(50) = N'PAP'
--,@UnknownReceiptTypeValue NVARCHAR(50) =N'_'
--,@LeaseEntityType NVARCHAR(10)=N'Lease'
--,@LoanEntityType NVARCHAR(10)=N'Loan'
--,@CustomerEntityType NVARCHAR(10)=N'Customer'
--,@DiscountingEntityType NVARCHAR(10)=N'Discounting'
--,@OneFilterOption  NVARCHAR(50)=N'One'
--,@AllFilterOption  NVARCHAR(50)=N'All'
--,@PendingACHStatus  NVARCHAR(50)=N'Pending'
--,@ThresholdExceededACHStatus  NVARCHAR(50)=N'ThresholdExceeded'
--,@LeaseContractType  NVARCHAR(50)=N'Lease'
--,@LoanContractType  NVARCHAR(50)=N'Loan'
--,@ProgressLoanContractType  NVARCHAR(50)=N'ProgressLoan'
--,@UnCommencedContractStatus  NVARCHAR(50)=N'Uncommenced'
--,@CommencedContractStatus  NVARCHAR(50)=N'Commenced'
--,@FullPaymentType  NVARCHAR(50)=N'Full'
--,@ReceivableOnlyPaymentType  NVARCHAR(50)=N'ReceivableOnly'
--,@TaxOnlyPaymentType  NVARCHAR(50)=N'TaxOnly'
--,@ACHOrPAPAutomatedMethod  NVARCHAR(50)=N'ACHOrPAP'
--,@ApprovedSyndicationStatus  NVARCHAR(50)=N'Approved'
--,@UnknownSyndicationType  NVARCHAR(50)=N'_'
--,@NoneSyndicationType  NVARCHAR(50)=N'None'
--,@ACHFileFormat  NVARCHAR(50)=N'ACH'
--,@PAPFileFormat  NVARCHAR(50)=N'PAP'
--,@DSLReceiptClassficationType  NVARCHAR(50)=N'DSL'
--,@CashReceiptClassficationType   NVARCHAR(50)=N'Cash'
--,@NonAccrualNonDSLReceiptClassficationType  NVARCHAR(50)=N'NonAccrualNonDSL'
--,@DownPaymentPaymentTypevalue  NVARCHAR(50)=N'Downpayment'
--,@InterimPaymentTypeValue  NVARCHAR(50)=N'Interim'
--,@LoanPrincipalReceivableTypeName  NVARCHAR(50)=N'LoanPrincipal'
--,@LoanInterestReceivableTypeName  NVARCHAR(50)=N'LoanInterest'
--,@InterimInterestIncomeType  NVARCHAR(50)=N'InterimInterest'
--,@TakeDownInterestIncomeType  NVARCHAR(50)=N'TakeDownInterest'
--,@CTReceivableEntityType  NVARCHAR(50)=N'CT'
--,@DTReceivableEntityType  NVARCHAR(50)=N'DT'
--,@CUReceivableEntityType  NVARCHAR(50)=N'CU'
--,@ApprovedBookingStatus  NVARCHAR(50)=N'Approved'
--,@PartiallyCompletedACHStatus  NVARCHAR(50)=N'Partiallycompleted'
--,@ProcessingACHStatus  NVARCHAR(50)=N'Processing'
--,@FromCustomerId BIGINT=181327
--,@ToCustomerId BIGINT=181327

SET NOCOUNT ON;


SET @AnyrecordExists = CAST(0 AS BIT)

SELECT * INTO #LegalEntityBankInfo FROM @LegalEntityBankInfo

CREATE TABLE #OneTimeACHExtractedDetails
(
	ReceivableDetailId BIGINT
	,ReceivableDetailAmount DECIMAL(16,2)
	,ReceivableDetailTaxApplied DECIMAL(16,2)
)

CREATE NONCLUSTERED INDEX IX_ReceivableDetailId ON #OneTimeACHExtractedDetails(ReceivableDetailId);

CREATE TABLE #ValidACHSchedules
(
	ContractId BIGINT
	,ACHScheduleId BIGINT
	,ReceivableId BIGINT
	,SettlementDate DATE
	,ReceiptLegalEntityId BIGINT
	,ReceiptBankAccountId BIGINT
)

CREATE NONCLUSTERED INDEX IX_ACHScheduleId ON #ValidACHSchedules(ACHScheduleId);
CREATE NONCLUSTERED INDEX IX_ReceivableId ON #ValidACHSchedules(ReceivableId);

IF @EntityType = @LoanEntityType OR @EntityType = @CustomerEntityType
BEGIN
	INSERT INTO #validACHSchedules
	SELECT
		Contracts.Id ,
		ACHScheduleId = ACHS.Id
		,ReceivableId = ACHS.ReceivableId
		,SettlementDate = CASE WHEN ACHS.Settlementdate <= LegalEntityBankInfo.UpdatedSettlementDateForACH
							THEN LegalEntityBankInfo.UpdatedSettlementDateForACH
							ELSE ACHS.Settlementdate
						END
		,ReceiptLegalEntityId = CB.ReceiptLegalEntityId
		,LegalEntityBankInfo.BankAccountId AS ReceiptBankAccountId
	FROM Contracts
	INNER JOIN LoanFinances ON ContractId = Contracts.Id AND LoanFinances.IsCurrent = 1
	INNER JOIN ACHSchedules ACHS ON ACHS.ContractBillingId = Contracts.Id
	INNER JOIN ContractBillings CB ON CB.Id = ACHS.ContractBillingId
	INNER JOIN #LegalEntityBankInfo LegalEntityBankInfo ON LegalEntityBankInfo.LegalEntityId = CB.ReceiptLegalEntityId
													AND Contracts.CurrencyId = LegalEntityBankInfo.CurrencyId
													AND CB.ReceiptLegalEntityId IS NOT NULL
	WHERE ACHS.IsActive = 1 AND ACHS.StopPayment = 0
		AND (ACHS.Status = @PendingACHStatus OR ACHS.Status = @ThresholdExceededACHStatus )
		AND (Contracts.ContractType = @LoanContractType OR Contracts.ContractType = @ProgressLoanContractType)
		AND (@ContractId = 0 OR Contracts.Id = @ContractId)
		AND (@ToCustomerId =0 OR LoanFinances.CustomerId BETWEEN @FromCustomerId AND  @ToCustomerId)
		AND ( @CustomerId = 0 OR  LoanFinances.CustomerId = @CustomerId)
		AND (Contracts.Status <> @UnCommencedContractStatus OR LoanFinances.CreateInvoiceForAdvanceRental = 0)
		AND (ACHS.SettlementDate BETWEEN @FromDate AND LegalEntityBankInfo.UpdatedProcessThroughDateForACH)
	UNION ALL
	SELECT
		Contracts.Id ,
		ACHScheduleId = ACHS.Id
		,ReceivableId = ACHS.ReceivableId
		,SettlementDate = CASE WHEN ACHS.Settlementdate <= LegalEntityBankInfo.UpdatedSettlementDateForACH
							THEN LegalEntityBankInfo.UpdatedSettlementDateForACH
							ELSE ACHS.Settlementdate
						END
		,ReceiptLegalEntityId = LoanFinances.LegalEntityId
		,LegalEntityBankInfo.BankAccountId AS ReceiptBankAccountId
	FROM Contracts
	INNER JOIN LoanFinances ON ContractId = Contracts.Id AND LoanFinances.IsCurrent = 1
	INNER JOIN ACHSchedules ACHS ON ACHS.ContractBillingId = Contracts.Id
	INNER JOIN ContractBillings CB ON CB.Id = ACHS.ContractBillingId
	INNER JOIN #LegalEntityBankInfo LegalEntityBankInfo ON LegalEntityBankInfo.LegalEntityId = LoanFinances.LegalEntityId
														AND Contracts.CurrencyId = LegalEntityBankInfo.CurrencyId
														AND CB.ReceiptLegalEntityId IS NULL
	WHERE ACHS.IsActive = 1 AND ACHS.StopPayment = 0
		AND (ACHS.Status = @PendingACHStatus OR ACHS.Status = @ThresholdExceededACHStatus )
		AND (Contracts.ContractType = @LoanContractType OR Contracts.ContractType = @ProgressLoanContractType)
		AND (@ContractId = 0 OR Contracts.Id = @ContractId)
		AND (@ToCustomerId =0 OR LoanFinances.CustomerId BETWEEN @FromCustomerId AND  @ToCustomerId)
		AND ( @CustomerId = 0 OR  LoanFinances.CustomerId = @CustomerId)
		AND (Contracts.Status <> @UnCommencedContractStatus OR LoanFinances.CreateInvoiceForAdvanceRental = 0)
		AND (ACHS.SettlementDate BETWEEN @FromDate AND LegalEntityBankInfo.UpdatedProcessThroughDateForACH)
END
IF @EntityType = @LeaseEntityType OR @EntityType = @CustomerEntityType
BEGIN
	INSERT INTO #validACHSchedules
	SELECT
		Contracts.Id ,
		ACHScheduleId = ACHS.Id
		,ReceivableId = ACHS.ReceivableId
		,SettlementDate = CASE WHEN ACHS.Settlementdate <= LegalEntityBankInfo.UpdatedSettlementDateForACH
							THEN LegalEntityBankInfo.UpdatedSettlementDateForACH
							ELSE ACHS.Settlementdate
						END
		,ReceiptLegalEntityId = CB.ReceiptLegalEntityId
		,LegalEntityBankInfo.BankAccountId AS ReceiptBankAccountId
	FROM Contracts
	INNER JOIN LeaseFinances ON ContractId = Contracts.Id AND LeaseFinances.IsCurrent = 1
	INNER JOIN LeaseFinanceDetails ON LeaseFinances.Id = LeaseFinanceDetails.Id
	INNER JOIN ACHSchedules ACHS ON ACHS.ContractBillingId = Contracts.Id
	INNER JOIN ContractBillings CB ON CB.Id = ACHS.ContractBillingId
	INNER JOIN #LegalEntityBankInfo LegalEntityBankInfo ON LegalEntityBankInfo.LegalEntityId = CB.ReceiptLegalEntityId
														AND Contracts.CurrencyId = LegalEntityBankInfo.CurrencyId
														AND CB.ReceiptLegalEntityId IS NOT NULL
	WHERE ACHS.IsActive = 1 AND ACHS.StopPayment = 0
	AND (ACHS.Status = @PendingACHStatus OR ACHS.Status = @ThresholdExceededACHStatus )
	AND Contracts.ContractType = @LeaseContractType
	AND (Contracts.Status = @CommencedContractStatus OR LeaseFinanceDetails.CreateInvoiceForAdvanceRental = 0)
	AND (@ContractId = 0 OR Contracts.Id = @ContractId)
	AND (@ToCustomerId =0  OR LeaseFinances.CustomerId BETWEEN @FromCustomerId AND  @ToCustomerId  )
	AND( @CustomerId = 0 OR  LeaseFinances.CustomerId = @CustomerId)
	AND (ACHS.SettlementDate BETWEEN @FromDate AND LegalEntityBankInfo.UpdatedProcessThroughDateForACH)
	AND (@ExcludeBackgroundProcessingPendingContracts = 0 OR Contracts.BackgroundProcessingPending = 0) 
	UNION ALL
	SELECT
		Contracts.Id ,
		ACHScheduleId = ACHS.Id
		,ReceivableId = ACHS.ReceivableId
		,SettlementDate = CASE WHEN ACHS.Settlementdate <= LegalEntityBankInfo.UpdatedSettlementDateForACH
							THEN LegalEntityBankInfo.UpdatedSettlementDateForACH
							ELSE ACHS.Settlementdate
						END
		,ReceiptLegalEntityId = LeaseFinances.LegalEntityId
		,LegalEntityBankInfo.BankAccountId AS ReceiptBankAccountId
	FROM Contracts
	INNER JOIN LeaseFinances ON ContractId = Contracts.Id AND LeaseFinances.IsCurrent = 1
	INNER JOIN LeaseFinanceDetails ON LeaseFinances.Id = LeaseFinanceDetails.Id
	INNER JOIN ACHSchedules ACHS ON ACHS.ContractBillingId = Contracts.Id
	INNER JOIN ContractBillings CB ON CB.Id = ACHS.ContractBillingId
	INNER JOIN #LegalEntityBankInfo LegalEntityBankInfo ON LegalEntityBankInfo.LegalEntityId = LeaseFinances.LegalEntityId
														AND Contracts.CurrencyId = LegalEntityBankInfo.CurrencyId
														AND CB.ReceiptLegalEntityId IS NULL
	WHERE ACHS.IsActive = 1 AND ACHS.StopPayment = 0
	AND (ACHS.Status = @PendingACHStatus OR ACHS.Status = @ThresholdExceededACHStatus )
	AND Contracts.ContractType = @LeaseContractType
	AND (Contracts.Status = @CommencedContractStatus OR LeaseFinanceDetails.CreateInvoiceForAdvanceRental = 0)
	AND (@ContractId = 0 OR Contracts.Id = @ContractId)
	AND (@ToCustomerId =0  OR LeaseFinances.CustomerId BETWEEN @FromCustomerId AND  @ToCustomerId  )
	AND( @CustomerId = 0 OR  LeaseFinances.CustomerId = @CustomerId)
	AND (ACHS.SettlementDate BETWEEN @FromDate AND LegalEntityBankInfo.UpdatedProcessThroughDateForACH)
	AND (@ExcludeBackgroundProcessingPendingContracts = 0 OR Contracts.BackgroundProcessingPending = 0) 
END

IF EXISTS(SELECT TOP 1 ID FROM ACHSchedule_Extract WHERE JobStepInstanceId = @JobStepInstanceId AND IsOneTimeACH = 1)
BEGIN
	
	;WITH CTE_SelectReceivableDetailIds
	AS
	(	SELECT OTACHDetail.ReceivableDetailId FROM ACHSchedule_Extract OTACHDetail
		INNER JOIN #validACHSchedules ON #validACHSchedules.ReceivableId = OTACHDetail.ReceivableId
		WHERE OTACHDetail.JobStepInstanceId = @JobStepInstanceId
			AND OTACHDetail.ErrorCode ='_'
			AND IsOneTimeACH = 1
		GROUP BY OTACHDetail.ReceivableDetailId
	)
	INSERT INTO #OneTimeACHExtractedDetails
	SELECT OTACHDetail.ReceivableDetailId,
	SUM(OTACHDetail.ReceivableDetailAmount) AS ReceivableDetailAmount,
	SUM(OTACHDetail.ReceivableDetailTaxAmount) AS ReceivableDetailTaxApplied
	FROM ACHSchedule_Extract OTACHDetail
	INNER JOIN CTE_SelectReceivableDetailIds ON CTE_SelectReceivableDetailIds.ReceivableDetailId = OTACHDetail.ReceivableDetailId
	WHERE OTACHDetail.JobStepInstanceId = @JobStepInstanceId
		AND OTACHDetail.ErrorCode ='_'
		AND IsOneTimeACH = 1
	GROUP BY OTACHDetail.ReceivableDetailId;
END

SELECT RTD.ReceivableDetailId,
RTD.EffectiveBalance_Amount
INTO #TaxInfo
FROM #validACHSchedules
JOIN ReceivableTaxes RT ON #validACHSchedules.ReceivableId = RT.ReceivableId
JOIN ReceivableTaxDetails RTD ON RT.Id = RTD.ReceivableTaxId AND RT.IsActive = 1 AND RTD.IsActive = 1
WHERE RTD.EffectiveBalance_Amount <> 0;


SELECT ReceivableDetailId,
	   SUM(EffectiveBalance_Amount) EffectiveTaxBalanceAmount
INTO #ReceivableTaxDetails
FROM #TaxInfo T
GROUP BY ReceivableDetailId;

SELECT
ACHScheduleId = ACHS.Id
,ReceivableId  = ACHS.ReceivableId
,ACHPaymentType  = ACHS.PaymentType
,ACHPaymentNumber = ACHS.ACHPaymentNumber
,SettlementDate = ACHDetails.SettlementDate
,ReceivableDueDate = R.DueDate
,ReceivableTypeName = RT.Name
,IsDSL = R.IsDSL
,PaymentScheduleId  = R.PaymentScheduleId
,ReceivableRemitToId = R.RemitToId
,ReceivableRemitToName = RToes.Name
,ContractId = ACHS.ContractBillingId
,ReceiptLegalEntityId = ACHDetails.ReceiptLegalEntityId
,ReceivableLegalEntityId = R.LegalEntityId
,CustomerBankDebitCode = BAC.DebitCode
,CustomerBankACHRoutingNumber = BB.ACHRoutingNumber
,CustomerBankAccountId = ACHS.ACHAccountId
,IsRental = RT.IsRental
,IncomeType = R.IncomeType
,CustomerBankAccountNumber_CT = BA.AccountNumber_CT
,ReceivableDetailID = RD.Id
,IsTaxAssessed = RD.IsTaxAssessed
,ReceivableDetailAmount = CASE WHEN (RD.EffectiveBalance_Amount - ISNULL(OTACHInfo.ReceivableDetailAmount,0.00) <> 0.0) AND (ACHS.PaymentType = @FullPaymentType OR ACHS.PaymentType = @ReceivableOnlyPaymentType)
									THEN
									  	RD.EffectiveBalance_Amount - ISNULL(OTACHInfo.ReceivableDetailAmount,0.00)
									ELSE
										0.00
									END
,ReceivableDetailTaxAmount = CASE WHEN (ACHS.PaymentType = @FullPaymentType OR ACHS.PaymentType = @TaxOnlyPaymentType) AND ISNULL(RTD.EffectiveTaxBalanceAmount,0.0) - ISNULL(OTACHInfo.ReceivableDetailTaxApplied,0.00) <> 0.0
									THEN
										ISNULL(RTD.EffectiveTaxBalanceAmount,0.0) - ISNULL(OTACHInfo.ReceivableDetailTaxApplied,0.00)
									ELSE
										0.0
									END
,ReceiptBankAccountId = ACHDetails.ReceiptBankAccountId
,PaymentThresholdEmailId = ContractBankAccountPaymentThresholds.EmailId
,PaymentThresholdAmount = ISNULL(ContractBankAccountPaymentThresholds.PaymentThresholdAmount_Amount,0.0)
,ACHPaymentThresholdDetailId = ACHS.BankAccountPaymentThresholdId
,PaymentThreshold = ISNULL(ContractBankAccountPaymentThresholds.PaymentThreshold,0)
,IsPrivateLabel = ISNULL(RToes.IsPrivateLabel,0)
,EmailTemplate = ET.Name
,BankAccountIsOnHold = BA.OnHold
INTO #AchSchedulesForUpdateJob
FROM #ValidACHSchedules ACHDetails
INNER JOIN ACHSchedules ACHS ON ACHS.Id = ACHDetails.ACHScheduleId
INNER JOIN Receivables R on ACHS.ReceivableId = R.Id AND R.IsActive=1
INNER JOIN ReceivableDetails RD ON RD.ReceivableId = R.Id AND RD.IsActive = 1
INNER JOIN ReceivableCodes RC ON R.ReceivableCodeId = RC.Id
INNER JOIN ReceivableTypes RT ON RT.Id = RC.ReceivableTypeId
INNER JOIN BankAccounts BA ON BA.Id = ACHS.ACHAccountId AND BA.IsActive = 1
INNER JOIN BankAccountCategories BAC ON BAC.Id = BA.BankAccountCategoryId
INNER JOIN BankBranches BB ON BA.BankBranchId = BB.Id AND BA.AutomatedPaymentMethod = @ACHOrPAPAutomatedMethod
LEFT JOIN #OneTimeACHExtractedDetails OTACHInfo ON OTACHInfo.ReceivableDetailId = RD.Id
LEFT JOIN RemitToes RToes ON RToes.Id = R.RemitToId
LEFT JOIN #ReceivableTaxDetails RTD ON RTD.ReceivableDetailId = RD.Id
LEFT JOIN ContractBankAccountPaymentThresholds ON ACHS.BankAccountPaymentThresholdId = ContractBankAccountPaymentThresholds.Id AND ContractBankAccountPaymentThresholds.IsActive = 1
LEFT JOIN EmailTemplates ET ON ET.Id = ContractBankAccountPaymentThresholds.ThresholdExceededEmailTemplateId
WHERE ((ACHS.PaymentType = @ReceivableOnlyPaymentType OR ACHS.PaymentType = @FullPaymentType)
		AND (RD.EffectiveBalance_Amount - ISNULL(OTACHInfo.ReceivableDetailAmount,0.00)) <> 0.0)
   OR ((ACHS.PaymentType = @TaxOnlyPaymentType  OR ACHS.PaymentType = @FullPaymentType)
		AND (ISNULL(RTD.EffectiveTaxBalanceAmount,0.0) - ISNULL(OTACHInfo.ReceivableDetailTaxApplied,0.00)) <> 0.0 )

CREATE NONCLUSTERED INDEX IX_#AchSchedulesForUpdateJob ON #AchSchedulesForUpdateJob(ContractId,ReceivableId);

CREATE TABLE #ContractInfos
(
ContractId BIGINT NULL,
SequenceNumber NVARCHAR(100),
ContractType NVARCHAR(14),
IsLease BIT,
LineOfBusinessId BIGINT,
InstrumentTypeId BIGINT,
ContractOriginationId BIGINT,
NonAccrualDate DATE,
IsNonAccrual BIT,
SyndicationType NVARCHAR(16),
SyndicationEffectiveDate DATE NULL,
LeaseContractType NVARCHAR(30),
FinanceId BIGINT,
CreditApprovedStructureId BIGINT NULL,
ContractStatus NVARCHAR(16),
CreateInvoiceForAdvanceRental Bit,
CostCenterId BIGINT,
BranchId BIGINT,
BillToId BIGINT,
CustomerId BIGINT,
CurrencyId BIGINT
);

CREATE CLUSTERED INDEX IX_ContractId ON #ContractInfos(ContractId);

INSERT INTO #ContractInfos
SELECT DISTINCT
ContractId = C.Id,
SequenceNumber = C.SequenceNumber,
ContractType = C.ContractType,
IsLease = 1,
LineofBusinessId = LF.LineofBusinessId,
InstrumentTypeId = LF.InstrumentTypeId,
ContractOriginationId = LF.ContractOriginationId ,
NonAccrualDate = C.NonAccrualDate ,
IsNonAccrual=C.IsNonAccrual,
SyndicationType = C.SyndicationType,
SyndicationEffectiveDate = NULL,
LeaseContractType = LFD.LeaseContractType,
FinanceId = LF.Id,
CreditApprovedStructureId = C.CreditApprovedStructureId,
ContractStatus = c.Status,
CreateInvoiceForAdvanceRental = LFD.CreateInvoiceForAdvanceRental,
CostCenterId = LF.CostCenterId,
BranchId = LF.BranchId,
BilltoId = C.BillToId,
CustomerId= LF.CustomerId,
CurrencyId = C.CurrencyId
FROM Contracts C
INNER JOIN LeaseFinances LF ON LF.ContractId = C.Id
INNER JOIN LeaseFinanceDetails LFD ON LFD.Id = LF.Id
INNER JOIN #AchSchedulesForUpdateJob AS ContractIds ON C.Id = ContractIds.ContractId
WHERE LF.IsCurrent = 1
AND C.ContractType =@LeaseContractType
AND (@ExcludeBackgroundProcessingPendingContracts = 0 OR C.BackgroundProcessingPending = 0);

INSERT INTO #ContractInfos
SELECT DISTINCT
ContractId = C.Id,
SequenceNumber = C.SequenceNumber,
ContractType = C.ContractType,
IsLease = 0,
LineofBusinessId = LF.LineofBusinessId,
InstrumentTypeId = LF.InstrumentTypeId,
ContractOriginationId = LF.ContractOriginationId ,
NonAccrualDate = C.NonAccrualDate ,
IsNonAccrual=C.IsNonAccrual,
SyndicationType = C.SyndicationType,
SyndicationEffectiveDate = NULL,
LeaseContractType = '_',
FinanceId = LF.Id,
CreditApprovedStructureId = C.CreditApprovedStructureId,
ContractStatus = c.Status,
CreateInvoiceForAdvanceRental = LF.CreateInvoiceForAdvanceRental,
CostCenterId = LF.CostCenterId,
BranchId = LF.BranchId,
BilltoId = C.BillToId,
CustomerId= LF.CustomerId,
CurrencyId = C.CurrencyId
FROM Contracts C
INNER JOIN LoanFinances LF ON LF.ContractId = C.Id
INNER JOIN #AchSchedulesForUpdateJob AS ContractIds ON C.Id = ContractIds.ContractId
WHERE LF.IsCurrent = 1
AND C.ContractType <>@LeaseContractType;

UPDATE #ContractInfos SET SyndicationEffectiveDate =RFT.EffectiveDate
FROM ReceivableForTransfers RFT
WHERE #ContractInfos.ContractId = RFT.ContractId
	AND RFT.ApprovalStatus = @ApprovedSyndicationStatus
	AND #ContractInfos.SyndicationType NOT IN (@UnknownSyndicationType,@NoneSyndicationType)

---LoanPaymentScheduleInfo ----
SELECT DISTINCT #AchSchedulesForUpdateJob.ReceivableId,
LP.PaymentType,
LP.Id AS PaymentId
INTO #LoanPaymentScheduleInfos
FROM #AchSchedulesForUpdateJob
JOIN LoanPaymentSchedules LP ON  #AchSchedulesForUpdateJob.PaymentScheduleId = LP.Id AND LP.IsActive = 1

---Customer Infos---
SELECT DISTINCT
C.Id AS CustomerId,
p.PartyName AS PartyName ,
C.IsConsolidated AS IsConsolidated,
PartyNumber
INTO #CustomerInfos
FROM  #ContractInfos
INNER JOIN Customers C ON C.Id = #ContractInfos.CustomerId
INNER JOIN Parties P ON P.Id = C.Id

CREATE CLUSTERED INDEX IX_CustomerId ON #CustomerInfos(CustomerId);

---Currency Infos --
SELECT DISTINCT
C.Id AS CurrencyId,
C.Name AS CurrencyName,
CC.Symbol AS CurrencySymbol,
CC.ISO AS CurrencyISO
INTO #CurrencyInfos
FROM Currencies C
JOIN CurrencyCodes CC ON C.CurrencyCodeId = CC.Id
JOIN #ContractInfos  ON #ContractInfos .CurrencyId = C.Id
WHERE C.IsActive = 1 AND CC.IsActive = 1

CREATE CLUSTERED INDEX IX_CurrencyId ON #CurrencyInfos(CurrencyId);

---ReceiptLegalEntityBankInfo--
SELECT DISTINCT
LE.Id AS ReceiptLegalEntityId,
LE.LegalEntityNumber AS ReceiptLegalEntityNumber,
LE.Name AS ReceiptLegalEntityName,
LE.GLConfigurationId AS GLConfigurationId
INTO #ACHScheduleLealEntityInfo
FROM #AchSchedulesForUpdateJob
JOIN LegalEntities LE ON #AchSchedulesForUpdateJob.ReceiptLegalEntityId = LE.Id

--Receipt Bank Account Details--
SELECT  DISTINCT
BB.Name AS ReceiptBankBranchName,
BA.AccountNumber_CT AS ReceiptBankAccountNumber_CT,
BB.GenerateBalancedACH AS ReceiptBankGenerateBalancedACH,
BB.GenerateControlFile AS ReceiptBankGenerateControlFile,
LEB.SourceofInput AS ReceiptBankSourceofInput,
LEB.ACHOperatorConfigId AS ReceiptBankACHOperatorConfigId,
LEB.ACISCustomerNumber AS ReceipeBankACISCustomerNumber,
BA.Id AS ReceiptBankAccountId,
BAC.CreditCode AS ReceiptBankAccountCreditCode,
BB.ACHRoutingNumber AS ReceiptBankACHRoutingNumber,
BA.AccountType AS AccountType,
BB.NACHAFilePaddingOption
INTO #ReceiptBankAccountInfos
FROM  #AchSchedulesForUpdateJob ACHInfo
INNER JOIN LegalEntityBankAccounts LEB ON LEB.BankAccountId = ACHInfo.ReceiptBankAccountId AND LEB.IsActive = 1
INNER JOIN BankAccounts BA ON BA.Id = LEB.BankAccountId AND BA.IsActive = 1
INNER JOIN BankAccountCategories BAC ON BAC.Id = BA.BankAccountCategoryId
INNER JOIN BankBranches BB ON BA.BankBranchId = BB.Id
WHERE LEB.IsActive = 1
AND BB.IsActive = 1
AND BA.IsActive = 1;

CREATE CLUSTERED INDEX IX_LegalEntitybankAccounts ON #ReceiptBankAccountInfos(ReceiptBankAccountId,ReceiptBankBranchName);

-- ACH ACHOperatorCOnfig ---
SELECT DISTINCT
AOC.FileFormat,
AOC.Id AS ReceiptBankACHOperatorConfigId
INTO #ACHOperatorConfigInfos
FROM  ACHOperatorConfigs AOC
INNER JOIN #ReceiptBankAccountInfos BD ON AOC.Id = BD.ReceiptBankACHOperatorConfigId
WHERE AOC.IsActive = 1

-- Get RemitTo Detais For Selected Le
SELECT
RemitToId=RemitToes.Id,
RemitToName=RemitToes.Name,
LegalEntityId=LegalEntityRemitToes.LegalEntityId,
LegalEntityRemitToes.IsDefault
INTO #RemitToDetails
FROM RemitToes
INNER JOIN LegalEntityRemitToes ON RemitToes.Id =LegalEntityRemitToes.RemitToId AND RemitToes.IsActive=1
INNER JOIN #AchSchedulesForUpdateJob AS ACHInfo ON ACHInfo.ReceiptLegalEntityId = LegalEntityRemitToes.LegalEntityId

SELECT Remito.LegalEntityId,
	   Remito.RemitToName,
	   Remito.RemitToId
INTO #RemitToForOneTime
FROM (SELECT DISTINCT LEgalEntityId FROM #RemitToDetails) LegalEntity
CROSS APPLY (SELECT TOP 1 * FROM #RemitToDetails temp WHERE LegalEntity.LegalEntityId = temp.LegalEntityId ORDER BY IsDefault DESC) Remito

--final list
INSERT INTO ACHSchedule_Extract([IsOneTimeACH],[OneTimeACHId],[OneTimeACHInvoiceId],[OneTimeACHReceivableId],[OneTimeACHScheduleId],[ReceivableDetailId],[ACHScheduleId],[ACHAmount],[UnAllocatedAmount],[CheckNumber],[ACHPaymentNumber],[ACHSchedulePaymentType],[SettlementDate],[RemitToId],[RemitToName],[CashTypeId],[BranchId],[ReceiptTypeName],[ReceiptTypeId],[GLTemplateId],[GLConfigurationId],[ReceiptClassificationType],[ReceiptGLTemplateName],[CurrencyId] ,[CurrencyName] ,[CurrencyCode] ,[CurrencySymbol],[ContractId],[SequenceNumber],[CostCenterId],[InstrumentTypeId],[LineofBusinessId],[DiscountingId],[SyndicationDate],[IsPrivateLabel],[ContractType],[PrivateLabelName] ,[CustomerId] ,[CustomerNumber] ,[IsConsolidated],[CustomerName],[CustomerBankAccountId],[CustomerBankAccountNumber_CT] ,[CustomerBankAccountDebitCode],[CustomerBankAccountACHRoutingNumber] ,[ReceivableId] ,[ReceivableInvoiceId] ,[PaymentScheduleId],[ReceivableDetailAmount],[ReceivableDetailTaxAmount],[ReceivableLegalEntityId] ,[IsNonAccrual] ,[ReceiptLegalEntityId] ,[ReceiptLegalEntityNumber] ,[ReceiptLegalEntityName] ,[ReceiptBankAccountId] ,[ReceiptBankAccountNumber_CT] ,[ReceiptBankGenerateBalancedACH] ,[ReceiptBankGenerateControlFile] ,[ReceiptBankBranchName] ,[ReceiptBankSourceofInput] ,[ReceiptBankACISCustomerNumber],[ReceiptBankACHRoutingNumber],[ReceiptBankAccountCreditCode],[ReceiptBankAccountACHOperatorConfigId] ,[FileFormat] ,[PaymentThresholdEmailId] ,[PaymentThresholdAmount] ,[ACHPaymentThresholdDetailId] ,[PaymentThreshold] ,[JobStepInstanceId],[CreatedById],[CreatedTime],[ReceiptBankAccountType],[IsTaxAssessed],[HasMultipleContractReceivables] ,[HasPendingDSLOrNANSDLReceipt] ,[EmailTemplateName],[ErrorCode] ,[NACHAFilePaddingOption] ,[InvalidOpenPeriodFromDate],[InvalidOpenPerionToDate],[OneTimeBankAccount],[BankAccountIsOnHold])
Select
		IsOneTimeACH = 0
        ,OneTimeACHId = NULL
        ,OneTimeACHInvoiceId = NULL
        ,OneTimeACHReceivableId  = NULL
		,OneTimeACHScheduleId = NULL
		,ReceivableDetailId = #AchSchedulesForUpdateJob.ReceivableDetailID
        ,ACHScheduleId = #AchSchedulesForUpdateJob.ACHScheduleId
        ,ACHAmount = #AchSchedulesForUpdateJob.ReceivableDetailAmount + #AchSchedulesForUpdateJob.ReceivableDetailTaxAmount
        ,UnAllocatedAmount  = 0.00
        ,CheckNumber = #ContractInfos.SequenceNumber
        ,ACHPaymentNumber = #AchSchedulesForUpdateJob.ACHPaymentNumber
        ,ACHSchedulePaymentType = ISNULL(#AchSchedulesForUpdateJob.ACHPaymentType,'_')
        ,SettlementDate = #AchSchedulesForUpdateJob.SettlementDate
        ,RemitToId = ISNULL(#AchSchedulesForUpdateJob.ReceivableRemitToId,#RemitToForOneTime.RemitToId)
        ,RemitToName = ISNULL(#AchSchedulesForUpdateJob.ReceivableRemitToName,#RemitToForOneTime.RemitToName)
        ,CashTypeId = @DefaultCashTypeId
        ,BranchId = #ContractInfos.BranchId
        ,ReceiptTypeName = CASE WHEN #ACHOperatorConfigInfos.FileFormat = @ACHFileFormat THEN @ACHReceiptTypeValue
		                        WHEN #ACHOperatorConfigInfos.FileFormat = @PAPFileFormat THEN  @PAPReceiptTypeValue
								ELSE @UnknownReceiptTypeValue
								END
        ,ReceiptTypeId = CASE WHEN #ACHOperatorConfigInfos.FileFormat = @ACHFileFormat THEN @ACHReceiptTypeId
		                        WHEN #ACHOperatorConfigInfos.FileFormat = @PAPFileFormat THEN  @PAPReceiptTypeId
								ELSE 0
								END
        ,GLTemplateId = @ReceiptGLTemplateId
        ,GLConfigurationId = #ACHScheduleLealEntityInfo.GLConfigurationId
        ,ReceiptClassficationType = CASE
			WHEN #ContractInfos.IsLease = 1
			THEN @CashReceiptClassficationType
			WHEN  #ContractInfos.IsLease = 0 AND #AchSchedulesForUpdateJob.PaymentScheduleId IS NOT NULL AND #AchSchedulesForUpdateJob.IsDSL = 1 AND #LoanPaymentScheduleInfos.PaymentType NOT IN (@DownPaymentPaymentTypevalue,@InterimPaymentTypeValue)
			AND (#AchSchedulesForUpdateJob.IsRental = 1 OR #AchSchedulesForUpdateJob.ReceivableTypeName IN (@LoanInterestReceivableTypeName,@LoanPrincipalReceivableTypeName))
			THEN @DSLReceiptClassficationType
			WHEN #ContractInfos.IsLease = 0  AND #AchSchedulesForUpdateJob.PaymentScheduleId IS NOT NULL AND #AchSchedulesForUpdateJob.IsDSL = 0 AND #ContractInfos.IsNonAccrual = 1 AND (#AchSchedulesForUpdateJob.IsRental = 1 OR #AchSchedulesForUpdateJob.ReceivableTypeName IN  (@LoanInterestReceivableTypeName,@LoanPrincipalReceivableTypeName)) AND (#AchSchedulesForUpdateJob.IncomeType NOT IN (@InterimInterestIncomeType,@TakeDownInterestIncomeType))
			THEN @NonAccrualNonDSLReceiptClassficationType
			ELSE @CashReceiptClassficationType
			END
        ,ReceiptGLTemplateName  = @ReceiptGLTemplateName
        ,CurrencyId = #ContractInfos.CurrencyId
        ,CurrencyName = #CurrencyInfos.CurrencyName
        ,CurrencyCode = #CurrencyInfos.CurrencyISO
        ,CurrencySymbol = #CurrencyInfos.CurrencySymbol
        ,ContractId = ISNULL(#AchSchedulesForUpdateJob.ContractId,0)
        ,SequenceNumber= #ContractInfos.SequenceNumber
        ,CostCenterId  = #ContractInfos.CostCenterId
        ,InstrumentTypeId = #ContractInfos.InstrumentTypeId
        ,LineofBusinessId = #ContractInfos.LineOfBusinessId
        ,DiscountingId      = NULL
        ,SyndicationDate = #ContractInfos.SyndicationEffectiveDate
        ,IsPrivateLabel = ISNULL(#AchSchedulesForUpdateJob.IsPrivateLabel,0)
        ,ContractType  = ISNULL(#ContractInfos.ContractType,'_')
        ,PrivateLabelName = CASE WHEN @UseProgramVendorAsCompanyName= 1 AND #AchSchedulesForUpdateJob.IsPrivateLabel=1 THEN #AchSchedulesForUpdateJob.ReceivableRemitToName
							ELSE NULL END
        ,CustomerId = #CustomerInfos.CustomerId
        ,CustomerNumber = #CustomerInfos.PartyNumber
        ,IsConsolidated  = #CustomerInfos.IsConsolidated
        ,CustomerName  = #CustomerInfos.PartyName
        ,CustomerBankAccountId = #AchSchedulesForUpdateJob.CustomerBankAccountId
		,CustomerBankAccountNumber_CT = #AchSchedulesForUpdateJob.CustomerBankAccountNumber_CT
        ,CustomerBankAccountDebitCode  = #AchSchedulesForUpdateJob.CustomerBankDebitCode
        ,CustomerBankAccountACHRoutingNumber   = #AchSchedulesForUpdateJob.CustomerBankACHRoutingNumber
        ,ReceivableId = #AchSchedulesForUpdateJob.ReceivableId
        ,ReceivableInvoiceId = NULL
        ,PaymentScheduleId = #AchSchedulesForUpdateJob.PaymentScheduleId
        ,ReceivableDetailAmount = ISNULL(#AchSchedulesForUpdateJob.ReceivableDetailAmount,0)
        ,ReceivableDetailTaxAmount = ISNULL(#AchSchedulesForUpdateJob.ReceivableDetailTaxAmount,0)
        ,ReceivableLegalEntityId = #AchSchedulesForUpdateJob.ReceivableLegalEntityId
        ,IsNonAccrual = CASE WHEN #AchSchedulesForUpdateJob.ContractId IS NOT NULL
									AND #ContractInfos.IsNonAccrual = 1
							THEN 1
							ELSE 0
						END
        ,ReceiptLegalEntityId = #ACHScheduleLealEntityInfo.ReceiptLegalEntityId
        ,ReceiptLegalEntityNumber = #ACHScheduleLealEntityInfo.ReceiptLegalEntityNumber
        ,ReceiptLegalEntityName = #ACHScheduleLealEntityInfo.ReceiptLegalEntityName
        ,ReceiptBankAccountId = #ReceiptBankAccountInfos.ReceiptBankAccountId
		,ReceiptBankAccountNumber = #ReceiptBankAccountInfos.ReceiptBankAccountNumber_CT
        ,ReceiptBankGenerateBalancedACH = ISNULL(#ReceiptBankAccountInfos.ReceiptBankGenerateBalancedACH,0)
        ,ReceiptBankGenerateControlFile = ISNULL(#ReceiptBankAccountInfos.ReceiptBankGenerateControlFile,0)
        ,ReceiptBankBranchName = #ReceiptBankAccountInfos.ReceiptBankBranchName
        ,ReceiptBankSourceofInput = #ReceiptBankAccountInfos.ReceiptBankSourceofInput
        ,ReceiptBankACISCustomerNumber = #ReceiptBankAccountInfos.ReceipeBankACISCustomerNumber
        ,ReceiptBankACHRoutingNumber = #ReceiptBankAccountInfos.ReceiptBankACHRoutingNumber
        ,ReceiptBankAccountCreditCode = #ReceiptBankAccountInfos.ReceiptBankAccountCreditCode
        ,ReceiptBankAccountACHOperatorConfigId = #ACHOperatorConfigInfos.ReceiptBankACHOperatorConfigId
        ,FileFormat = #ACHOperatorConfigInfos.FileFormat
        ,PaymentThresholdEmailId = #AchSchedulesForUpdateJob.PaymentThresholdEmailId
        ,PaymentThresholdAmount = #AchSchedulesForUpdateJob.PaymentThresholdAmount
        ,ACHPaymentThresholdDetailId = #AchSchedulesForUpdateJob.ACHPaymentThresholdDetailId
        ,PaymentThreshold = #AchSchedulesForUpdateJob.PaymentThreshold
		,@JobStepInstanceId
		,@CreatedById
		,@CreatedTime
		,ReceiptBankAccountType = #ReceiptBankAccountInfos.AccountType
		,IsTaxAssessed=ISNUll(#AchSchedulesForUpdateJob.IsTaxAssessed,0)
		,0 AS HasMultipleContractReceivables
        ,0 As HasPendingDSLOrNANSDLReceipt
		,#AchSchedulesForUpdateJob.EmailTemplate
		,ErrorCode = '_'
		,NACHAFilePaddingOption = #ReceiptBankAccountInfos.NACHAFilePaddingOption
		,InvalidOpenPeriodFromDate = NULL
		,InvalidOpenPerionToDate = NULL
		,0
		,BankAccountIsOnHold
FROM #AchSchedulesForUpdateJob
INNER JOIN #ContractInfos ON #ContractInfos.ContractId = #AchSchedulesForUpdateJob.ContractId
INNER JOIN #CustomerInfos ON #ContractInfos.CustomerId = #CustomerInfos.CustomerId
INNER JOIN #CurrencyInfos ON #CurrencyInfos.CurrencyId = #ContractInfos.CurrencyId
INNER JOIN #ReceiptBankAccountInfos ON #ReceiptBankAccountInfos.ReceiptBankAccountId = #AchSchedulesForUpdateJob.ReceiptBankAccountId
INNER JOIN #ACHScheduleLealEntityInfo ON #AchSchedulesForUpdateJob.ReceiptLegalEntityId = #ACHScheduleLealEntityInfo.ReceiptLegalEntityId
INNER JOIN #RemitToForOneTime ON #RemitToForOneTime.LegalEntityId = #AchSchedulesForUpdateJob.ReceiptLegalEntityId
LEFT JOIN #ACHOperatorConfigInfos ON #ACHOperatorConfigInfos.ReceiptBankACHOperatorConfigId = #ReceiptBankAccountInfos.ReceiptBankACHOperatorConfigId
LEFT JOIN #LoanPaymentScheduleInfos ON #AchSchedulesForUpdateJob.PaymentScheduleId = #LoanPaymentScheduleInfos.PaymentId AND #AchSchedulesForUpdateJob.ReceivableId = #LoanPaymentScheduleInfos.ReceivableId

IF EXISTS (SELECT 1 FROM ACHSchedule_Extract WHERE JobStepInstanceId = @JobStepInstanceId AND ErrorCode ='_' AND IsOneTimeACH = 0)
SET @AnyrecordExists = CAST(1 AS BIT)

DROP TABLE #ContractInfos
DROP TABLE #AchSchedulesForUpdateJob
DROP TABLE #ReceiptBankAccountInfos
DROP TABLE #ACHOperatorConfigInfos
DROP TABLE #CurrencyInfos
DROP TABLE #CustomerInfos
DROP TABLE #LoanPaymentScheduleInfos
DROP TABLE #ACHScheduleLealEntityInfo
DROP TABLE #RemitToForOneTime
DROP TABLE #LegalEntityBankInfo
DROP TABLE #ReceivableTaxDetails
DROP TABLE #ValidACHSchedules
DROP TABLE #OneTimeACHExtractedDetails

END

GO
