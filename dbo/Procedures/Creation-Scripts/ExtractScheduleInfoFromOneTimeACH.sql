SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[ExtractScheduleInfoFromOneTimeACH]
( @FromDate DATETIMEOFFSET
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
,@ToCustomerId BIGINT NULL
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
--insert into @LegalEntityBankInfo values(20028,148,NULL,NULL,'2018-01-08 00:00:00','2020-04-29 00:00:00','2020-04-22 00:00:00',5)
--insert into @LegalEntityBankInfo values(20039,131,NULL,NULL,'2018-01-08 00:00:00','2020-04-29 00:00:00','2020-04-22 00:00:00',1)
--insert into @LegalEntityBankInfo values(20039,173,NULL,NULL,'2018-01-08 00:00:00','2020-04-29 00:00:00','2020-04-22 00:00:00',2)
--insert into @LegalEntityBankInfo values(20031,115,NULL,NULL,'2018-01-01 00:00:00','2020-04-22 00:00:00','2020-04-22 00:00:00',1)
--insert into @LegalEntityBankInfo values(20028,102,NULL,NULL,'2018-01-08 00:00:00','2020-04-29 00:00:00','2020-04-22 00:00:00',1)
--insert into @LegalEntityBankInfo values(1,141490,NULL,NULL,'2018-01-01 00:00:00','2020-04-22 00:00:00','2020-04-22 00:00:00',1)
--insert into @LegalEntityBankInfo values(1,163,NULL,NULL,'2018-01-01 00:00:00','2020-04-22 00:00:00','2020-04-22 00:00:00',2)
--insert into @LegalEntityBankInfo values(1,26,NULL,NULL,'2018-01-01 00:00:00','2020-04-22 00:00:00','2020-04-22 00:00:00',0)
--insert into @LegalEntityBankInfo values(1,18,NULL,NULL,'2018-01-01 00:00:00','2020-04-22 00:00:00','2020-04-22 00:00:00',1)
--insert into @LegalEntityBankInfo values(1,17,NULL,NULL,'2018-01-08 00:00:00','2020-04-29 00:00:00','2020-04-22 00:00:00',0)
--insert into @LegalEntityBankInfo values(20103,127943,NULL,NULL,'2018-01-08 00:00:00','2020-04-29 00:00:00','2020-04-22 00:00:00',1)
--insert into @LegalEntityBankInfo values(20088,127925,NULL,NULL,'2018-01-08 00:00:00','2020-04-29 00:00:00','2020-04-22 00:00:00',1)
--insert into @LegalEntityBankInfo values(20102,127942,NULL,NULL,'2018-01-08 00:00:00','2020-04-29 00:00:00','2020-04-22 00:00:00',1)
--insert into @LegalEntityBankInfo values(20101,127941,NULL,NULL,'2018-01-08 00:00:00','2020-04-29 00:00:00','2020-04-22 00:00:00',1)
--insert into @LegalEntityBankInfo values(20100,127940,NULL,NULL,'2018-01-08 00:00:00','2020-04-29 00:00:00','2020-04-22 00:00:00',1)
--insert into @LegalEntityBankInfo values(20099,127938,NULL,NULL,'2018-01-08 00:00:00','2020-04-29 00:00:00','2020-04-22 00:00:00',1)
--insert into @LegalEntityBankInfo values(20098,127937,NULL,NULL,'2018-01-08 00:00:00','2020-04-29 00:00:00','2020-04-22 00:00:00',39)
--insert into @LegalEntityBankInfo values(20097,127936,NULL,NULL,'2018-01-08 00:00:00','2020-04-29 00:00:00','2020-04-22 00:00:00',1)
--insert into @LegalEntityBankInfo values(20096,127935,NULL,NULL,'2018-01-08 00:00:00','2020-04-29 00:00:00','2020-04-22 00:00:00',39)
--insert into @LegalEntityBankInfo values(20095,127934,NULL,NULL,'2018-01-08 00:00:00','2020-04-29 00:00:00','2020-04-22 00:00:00',3)
--insert into @LegalEntityBankInfo values(20094,127933,NULL,NULL,'2018-01-08 00:00:00','2020-04-29 00:00:00','2020-04-22 00:00:00',3)
--insert into @LegalEntityBankInfo values(20093,127932,NULL,NULL,'2018-01-08 00:00:00','2020-04-29 00:00:00','2020-04-22 00:00:00',3)
--insert into @LegalEntityBankInfo values(20092,127931,NULL,NULL,'2018-01-01 00:00:00','2020-04-22 00:00:00','2020-04-22 00:00:00',1)
--insert into @LegalEntityBankInfo values(20092,127930,NULL,NULL,'2018-01-01 00:00:00','2020-04-22 00:00:00','2020-04-22 00:00:00',1)
--insert into @LegalEntityBankInfo values(20091,127929,NULL,NULL,'2018-01-01 00:00:00','2020-04-22 00:00:00','2020-04-22 00:00:00',2)
--insert into @LegalEntityBankInfo values(20090,127928,NULL,NULL,'2018-01-01 00:00:00','2020-04-22 00:00:00','2020-04-22 00:00:00',1)
--insert into @LegalEntityBankInfo values(20090,127927,NULL,NULL,'2018-01-01 00:00:00','2020-04-22 00:00:00','2020-04-22 00:00:00',2)
--insert into @LegalEntityBankInfo values(20089,127926,NULL,NULL,'2018-01-01 00:00:00','2020-04-22 00:00:00','2020-04-23 00:00:00',1)


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




    SET @AnyrecordExists = 0;

    SELECT *
    INTO #LegalEntityBankInfo
    FROM @LegalEntityBankInfo;

    SET NOCOUNT ON;

    CREATE TABLE #OneTimeACHInfo
    (
	 Id BIGINT  IDENTITY(1,1),
	 OneTimeACHId                 BIGINT,
     ReceivableId                 BIGINT NULL,
     ReceivableInvoiceId          BIGINT NULL,
     ContractId                   BIGINT NULL,
     DiscountingId                BIGINT NULL,
     ReceivableTypeName           NVARCHAR(21) NULL,
     PaymentScheduleId            BIGINT NULL,
     SettlementDate               DATE,
     GLConfigurationId            BIGINT,
     ReceiptLegalEntityNumber     NVARCHAR(20) NOT NULL,
     ReceiptLegalEntityName       NVARCHAR(100) NOT NULL,
     ReceiptBankAccountId         BIGINT NOT NULL,
     ReceivableLegalEntityId      BIGINT NULL,
     ReceiptLegalEntityId         BIGINT NOT NULL,
     CashTypeId                   BIGINT NOT NULL,
     UnAllocatedAmount            DECIMAL(16, 2) NOT NULL,
     ReceivableDetailAmount       DECIMAL(16, 2) NOT NULL,
     ReceivableDetailTaxAmount    DECIMAL(16, 2) NOT NULL,
     CurrencyId                   BIGINT NOT NULL,
     CustomerId                   BIGINT NOT NULL,
     CustomerBankAccountId        BIGINT NOT NULL,
     OneTimeACHReceivableId       BIGINT NULL,
     OneTimeACHInvoiceId          BIGINT NULL,
     OneTimeACHScheduleId         BIGINT NULL,
     IsDSL                        BIT NOT NULL,
     IncomeType                   NVARCHAR(16),
     IsRental                     BIT NOT NULL,
     CheckNumber                  NVARCHAR(40),
     CustomerBankDebitCode        BIGINT NOT NULL,
     CustomerBankACHRoutingNumber NVARCHAR(20),
     ReceivableDueDate            DATE,
     CostCenterId                 BIGINT,
     ReceivableRemitToId          BIGINT,
     ReceivableRemitToName        NVARCHAR(40),
     ReceiptGLTemplateId          BIGINT,
     ReceiptGLTemplateName        NVARCHAR(50),
     IsTaxAssessed                BIT NOT NULL,
     ReceivableDetailId           BIGINT NULL,
     CustomerBankAccountNumber_CT VARBINARY(MAX) NOT NULL,
     IsUnAllocation               BIT,
	 OneTimeBankAccount			  BIT,
	 ReceivableDetailEffectiveBalance	 DECIMAL(16,2),
	 ReceivableDetailTaxEffectiveBalance DECIMAL(16,2),
	 IsPrivateLabel BIT,
	 BankAccountIsOnHold BIT
    );

    CREATE TABLE #OTACHDetails
    (OTACHId                    BIGINT,
     OTACHReceivableId          BIGINT,
     OTACHInvoiceId             BIGINT,
     OTACHReceivableDetailId    BIGINT,
     OTACHScheduleId            BIGINT,
     ReceivableInvoiceId        BIGINT,
     ReceivableId               BIGINT,
     ReceivableDetailId         BIGINT,
     AmountApplied_Amount       DECIMAL(16, 2),
     TaxApplied_Amount          DECIMAL(16, 2),
     EffectiveBalance_Amount    DECIMAL(16, 2),
     EffectiveTaxBalance_Amount DECIMAL(16, 2),
     IsTaxAssessed              BIT,
     IsRental                   BIT,
     ReceivableTypeName         NVARCHAR(21),
     SettlementDate             DATE
    );

	CREATE TABLE #AppliedAmount
	(
	ReceivableDetailAmount		DECIMAL(16,2),
	ReceivableDetailTaxAmount	Decimal(16,2),
	ReceivableDetailId			BIGINT
	);

	CREATE TABLE #ValidEntities
	(
	 EntityId		BIGINT,
	 EntityType		NVARCHAR(3)
	)

	 IF @EntityType = @LoanEntityType
      BEGIN
		INSERT INTO #ValidEntities
		SELECT Contracts.Id , @CTReceivableEntityType FROM Contracts
		INNER JOIN LoanFinances ON ContractId = Contracts.Id AND LoanFinances.IsCurrent = 1
		WHERE (Contracts.ContractType = @LoanContractType OR Contracts.ContractType = @ProgressLoanContractType)
		AND (@ContractId = 0 OR Contracts.Id = @ContractId)
		AND (Contracts.Status <> @UnCommencedContractStatus OR LoanFinances.CreateInvoiceForAdvanceRental = 0)
	  END

	  IF @EntityType = @LeaseEntityType
      BEGIN
		INSERT INTO #ValidEntities
		SELECT Contracts.Id , @CTReceivableEntityType FROM Contracts
		INNER JOIN LeaseFinances ON ContractId = Contracts.Id AND LeaseFinances.IsCurrent = 1
		INNER JOIN LeaseFinanceDetails ON LeaseFinances.Id = LeaseFinanceDetails.Id
		WHERE Contracts.ContractType = @LeaseContractType
		AND (Contracts.Status = @CommencedContractStatus OR LeaseFinanceDetails.CreateInvoiceForAdvanceRental = 0)
		AND (@ContractId = 0 OR Contracts.Id = @ContractId)
		AND (@ExcludeBackgroundProcessingPendingContracts = 0 OR Contracts.BackgroundProcessingPending = 0) 
	  END

	  IF @EntityType = @DiscountingEntityType
      BEGIN
		INSERT INTO #ValidEntities
		SELECT DISTINCT Discountings.Id , @DTReceivableEntityType FROM Discountings
		INNER JOIN dbo.DiscountingFinances AS DF ON DF.DiscountingId = Discountings.Id
		INNER JOIN DiscountingContracts  AS DC ON DC.DiscountingFinanceId = DF.Id AND DC.IsActive = 1
		INNER JOIN Contracts C ON C.Id = DC.ContractId
		LEFT JOIN LeaseFinances LF ON LF.ContractId = C.Id AND LF.IsCurrent = 1
		LEFT JOIN LoanFinances Lof ON Lof.ContractId = C.Id AND Lof.IsCurrent = 1
		WHERE DF.IsCurrent = 1
			  AND DF.BookingStatus = @ApprovedBookingStatus
			  AND (@ContractId = 0 OR Discountings.Id = @ContractId)
	  END

        INSERT INTO #OTACHDetails
        SELECT OTA.Id,
               OTR.Id,
               OTI.Id,
               OTARD.Id,
               OTAS.Id,
               RI.Id,
               R.Id,
			   RD.Id,
               OTARD.AmountApplied_Amount,
               OTARD.TaxApplied_Amount,
               RD.EffectiveBalance_Amount,
               0.00,
               RD.IsTaxAssessed,
               RT.IsRental,
               RT.Name,
               CASE
                 WHEN OTA.Settlementdate <= LEInfo.UpdatedSettlementDateForOTACH
                 THEN LEInfo.UpdatedSettlementDateForOTACH
                 ELSE OTA.Settlementdate
               END

        FROM dbo.OneTimeACHes AS OTA
        INNER JOIN dbo.OneTimeACHSchedules AS OTAS ON OTA.Id = OTAS.OneTimeACHId
                                                      AND OTAS.IsActive = 1
        INNER JOIN dbo.OneTimeACHReceivableDetails AS OTARD ON OTARD.OneTimeACHScheduleId = OTAS.Id
                                                               AND OTARD.IsActive = 1
        INNER JOIN dbo.ReceivableDetails AS RD ON OTARD.ReceivableDetailId = RD.Id
                                                  AND RD.IsActive = 1
        INNER JOIN dbo.Receivables AS R ON RD.ReceivableId = R.Id
                                           AND R.IsActive = 1
        INNER JOIN dbo.ReceivableCodes AS RC ON Rc.Id = R.ReceivableCodeId
        INNER JOIN dbo.ReceivableTypes AS RT ON RT.Id = RC.ReceivableTypeId
        INNER JOIN #LegalEntityBankInfo AS LEInfo ON LEInfo.LegalEntityId = OTA.LegalEntityId
                                                     AND LEInfo.BankAccountId = OTA.LegalEntityBankAccountId
        INNER JOIN #ValidEntities AS entity ON R.EntityId = entity.EntityId
                                             AND R.EntityType = entity.EntityType
        LEFT JOIN dbo.OneTimeACHReceivables AS OTR ON OTA.Id = OTR.OneTimeACHId
                                                      AND OTR.IsActive = 1
                                                      AND OTAS.ReceivableId = OTR.ReceivableId
                                                      AND OTR.STATUS = @PendingACHStatus
        LEFT JOIN dbo.ReceivableInvoices AS RI ON OTAS.ReceivableInvoiceId = RI.Id
                                                  AND RI.IsActive = 1
        LEFT JOIN dbo.OneTimeACHInvoices AS OTI ON OTA.Id = OTI.OneTimeACHId
                                                          AND OTI.IsActive = 1
                                                          AND RI.Id = OTI.ReceivableInvoiceId
                                                          AND OTI.STATUS = @PendingACHStatus
        WHERE OTA.IsActive = 1
              AND (OTR.Id IS NOT NULL OR OTI.Id IS NOT NULL)
              AND OTA.STATUS IN(@PendingACHStatus, @PartiallyCompletedACHStatus, @ProcessingACHStatus)
              AND OTA.SettlementDate >= @FromDate
              AND OTA.SettlementDate <= LEInfo.UpdatedProcessThroughDateForOTACH
			  AND (OTARD.AmountApplied_Amount <> 0 OR OTARD.TaxApplied_Amount <>0)
   
-- Insert OTACH Details for Customer level job

        INSERT INTO #OTACHDetails
        SELECT OTA.Id,
               OTR.Id,
               OTI.Id,
               OTARD.Id,
               OTAS.Id,
               RI.Id,
               R.Id,
			   RD.Id,
               OTARD.AmountApplied_Amount,
               OTARD.TaxApplied_Amount,
               RD.EffectiveBalance_Amount,
               0.00,
               RD.IsTaxAssessed,
               RT.IsRental,
               RT.Name,
               CASE
                 WHEN OTA.Settlementdate <= LEInfo.UpdatedSettlementDateForOTACH
                 THEN LEInfo.UpdatedSettlementDateForOTACH
                 ELSE OTA.Settlementdate
               END

        FROM dbo.OneTimeACHes AS OTA
        INNER JOIN dbo.OneTimeACHSchedules AS OTAS ON OTA.Id = OTAS.OneTimeACHId
                                                      AND OTAS.IsActive = 1
        INNER JOIN dbo.OneTimeACHReceivableDetails AS OTARD ON OTARD.OneTimeACHScheduleId = OTAS.Id
                                                               AND OTARD.IsActive = 1
        INNER JOIN dbo.ReceivableDetails AS RD ON OTARD.ReceivableDetailId = RD.Id
                                                  AND RD.IsActive = 1
        INNER JOIN dbo.Receivables AS R ON RD.ReceivableId = R.Id
                                           AND R.IsActive = 1
        INNER JOIN dbo.ReceivableCodes AS RC ON Rc.Id = R.ReceivableCodeId
        INNER JOIN dbo.ReceivableTypes AS RT ON RT.Id = RC.ReceivableTypeId
        INNER JOIN #LegalEntityBankInfo AS LEInfo ON LEInfo.LegalEntityId = OTA.LegalEntityId
                                                     AND LEInfo.BankAccountId = OTA.LegalEntityBankAccountId
        LEFT JOIN dbo.OneTimeACHReceivables AS OTR ON OTA.Id = OTR.OneTimeACHId
                                                      AND OTR.IsActive = 1
                                                      AND OTAS.ReceivableId = OTR.ReceivableId
                                                      AND OTR.STATUS = @PendingACHStatus
        LEFT JOIN dbo.ReceivableInvoices AS RI ON OTAS.ReceivableInvoiceId = RI.Id
                                                  AND RI.IsActive = 1
        LEFT JOIN dbo.OneTimeACHInvoices AS OTI ON OTA.Id = OTI.OneTimeACHId
                                                          AND OTI.IsActive = 1
                                                          AND RI.Id = OTI.ReceivableInvoiceId
                                                          AND OTI.STATUS = @PendingACHStatus
        WHERE OTA.IsActive = 1
			  AND @EntityType =@CustomerEntityType
              AND (OTR.Id IS NOT NULL OR OTI.Id IS NOT NULL)
              AND OTA.STATUS IN(@PendingACHStatus, @PartiallyCompletedACHStatus, @ProcessingACHStatus)
              AND OTA.SettlementDate >= @FromDate
              AND OTA.SettlementDate <= LEInfo.UpdatedProcessThroughDateForOTACH
			  AND (OTARD.AmountApplied_Amount <> 0 OR OTARD.TaxApplied_Amount <>0)
			  AND (@ToCustomerId = 0 OR OTA.CustomerId BETWEEN @FromCustomerId AND  @ToCustomerId  )
			  AND( @CustomerId = 0 OR OTA.CustomerId =  @CustomerId)
   

SELECT DISTINCT ReceivableDetailId INTO #ReceivableDetailIds FROM #OTACHDetails

    UPDATE #OTACHDetails
      SET
          EffectiveTaxBalance_Amount = T.EffectiveTaxBalance_Amount
    FROM
    (
        SELECT SUM(RTD.EffectiveBalance_Amount) AS EffectiveTaxBalance_Amount,
               OTAD.ReceivableDetailId
        FROM #ReceivableDetailIds AS OTAD
        INNER JOIN dbo.ReceivableTaxDetails AS RTD ON OTAD.ReceivableDetailId = RTD.ReceivableDetailId
                                                      AND RTD.IsActive = 1
        GROUP BY OTAD.ReceivableDetailId
    ) T
    WHERE #OTACHDetails.ReceivableDetailId = T.ReceivableDetailId;


    INSERT INTO #OneTimeACHInfo
    SELECT OneTimeACHId = OTA.Id,
           ReceivableId = R.Id,
           ReceivableInvoiceId = OTAD.ReceivableInvoiceId,
           ContractId = CASE
                          WHEN R.EntityType = @CTReceivableEntityType
                          THEN R.EntityId
                          ELSE NULL
                        END,
           DiscountingId = CASE
                             WHEN R.EntityType = @DTReceivableEntityType
                             THEN R.EntityId
                             ELSE NULL
                           END,
           ReceivableTypeName = OTAD.ReceivableTypeName,
           PaymentScheduleId = R.PaymentScheduleId,
           SettlementDate = OTAD.SettlementDate,
           GLConfigurationId = LE.GLConfigurationId,
           ReceiptLegalEntityNumber = LE.LegalEntityNumber,
           ReceiptLegalEntityName = LE.Name,
           ReceiptBankAccountId = OTA.LegalEntityBankAccountId,
           ReceivableLegalEntityId = R.LegalEntityId,
           ReceiptLegalEntityId = OTA.LegalEntityId,
           CashTypeId = ISNULL(OTA.CashTypeId, @DefaultCashTypeId),
           UnAllocatedAmount =	CASE WHEN OTARD.AmountApplied_Amount >= OTAD.EffectiveBalance_Amount AND  OTARD.AmountApplied_Amount > 0  THEN OTARD.AmountApplied_Amount - OTAD.EffectiveBalance_Amount
											ELSE 0.00 END
							  + CASE WHEN OTARD.TaxApplied_Amount >= ISNULL(OTAD.EffectiveTaxBalance_Amount, 0.00) AND OTARD.TaxApplied_Amount > 0 THEN OTARD.TaxApplied_Amount - ISNULL(OTAD.EffectiveTaxBalance_Amount, 0.00)
                                            ELSE 0.00  END
							+CASE WHEN OTARD.AmountApplied_Amount <= OTAD.EffectiveBalance_Amount AND  OTARD.AmountApplied_Amount < 0  THEN OTARD.AmountApplied_Amount - OTAD.EffectiveBalance_Amount
											ELSE 0.00 END
						  + CASE WHEN OTARD.TaxApplied_Amount <= ISNULL(OTAD.EffectiveTaxBalance_Amount, 0.00) AND  OTARD.TaxApplied_Amount < 0 THEN OTARD.TaxApplied_Amount - ISNULL(OTAD.EffectiveTaxBalance_Amount, 0.00)
                                            ELSE 0.00 END,
           ReceivableDetailAmount = CASE
                                      WHEN OTARD.AmountApplied_Amount <= OTAD.EffectiveBalance_Amount AND  OTARD.AmountApplied_Amount >= 0
                                      THEN OTARD.AmountApplied_Amount
									  WHEN OTARD.AmountApplied_Amount >= OTAD.EffectiveBalance_Amount AND  OTARD.AmountApplied_Amount <= 0
                                      THEN OTARD.AmountApplied_Amount
                                      ELSE OTAD.EffectiveBalance_Amount
                                    END,
           ReceivableDetailTaxAmount = CASE
                                         WHEN OTARD.TaxApplied_Amount <= ISNULL(OTAD.EffectiveTaxBalance_Amount, 0.00) AND OTARD.TaxApplied_Amount >= 0
                                         THEN OTARD.TaxApplied_Amount
										 WHEN OTARD.TaxApplied_Amount >= ISNULL(OTAD.EffectiveTaxBalance_Amount, 0.00) AND OTARD.TaxApplied_Amount <= 0
                                         THEN OTARD.TaxApplied_Amount
                                         ELSE ISNULL(OTAD.EffectiveTaxBalance_Amount, 0.00)
                                       END,
           CurrencyId = OTA.CurrencyId,
           CustomerId = OTA.CustomerId,
           CustomerBankAccountId = OTA.BankAccountId,
           OneTimeACHReceivableId = OTAD.OTACHReceivableId,
           OneTimeACHInvoiceId = OTAD.OTACHInvoiceId,
           OneTimeACHScheduleId = OTAD.OTACHScheduleId,
           IsDSL = R.IsDSL,
           IncomeType = R.IncomeType,
           IsRental = OTAD.IsRental,
           CheckNumber = OTA.CheckNumber,
           CustomerBankDebitCode = BAC.DebitCode,
           CustomerBankACHRoutingNumber = BB.ACHRoutingNumber,
           ReceivableDueDate = R.DueDate,
           CostCenterId = OTA.CostCenterId,
           ReceivableRemitToId = R.RemitToId,
           ReceivableRemitToName = RTes.Name,
           ReceiptGLTemplateId = GT.Id,
           ReceiptGLTemplateName = GT.Name,
           IsTaxAssessed = OTAD.IsTaxAssessed,
           ReceivableDetailId = OTAD.ReceivableDetailId,
           CustomerBankAccountNumber_CT = BA.AccountNumber_CT,
           IsUnAllocation = 0,
		   OneTimeBankAccount = BA.IsOneTimeACHOnly,
		   ReceivableDetailEffectiveBalance = OTAD.EffectiveBalance_Amount,
		   ReceivableDetailTaxEffectiveBalance = OTAD.EffectiveTaxBalance_Amount,
		   IsPrivateLabel = ISNULL(RTes.IsPrivateLabel,0),
		   BankAccountIsOnHold = BA.OnHold
    FROM #OTACHDetails AS OTAD
    INNER JOIN dbo.OneTimeACHes AS OTA ON OTA.Id = OTAD.OTACHId
    INNER JOIN dbo.Receivables AS R ON OTAD.ReceivableId = R.Id
    INNER JOIN dbo.OneTimeACHReceivableDetails AS OTARD ON OTARD.Id = OTAD.OTACHReceivableDetailId
    INNER JOIN dbo.LegalEntities AS LE ON LE.Id = OTA.LegalEntityId
    INNER JOIN dbo.BankAccounts AS BA ON BA.Id = OTA.BankAccountId
                                         AND BA.IsActive = 1
    INNER JOIN dbo.BankAccountCategories AS BAC ON BAC.Id = BA.BankAccountCategoryId
    INNER JOIN dbo.BankBranches AS BB ON BA.BankBranchId = BB.Id
                                         AND BA.AutomatedPaymentMethod = @ACHOrPAPAutomatedMethod
    INNER JOIN dbo.GLTemplates AS GT ON OTA.ReceiptGLTemplateId = GT.Id
    LEFT JOIN dbo.RemitToes AS RTes ON RTes.Id = R.RemitToId;

WITH CTE_DistinctReceivableDetails
         AS (SELECT #OneTimeACHInfo.ReceivableDetailId,
                    COUNT(*) AS count
             FROM #OneTimeACHInfo
             GROUP BY #OneTimeACHInfo.ReceivableDetailId
             HAVING COUNT(*) > 1)
SELECT			info.OneTimeACHId,
                    info.ReceivableDetailId,
                    info.OneTimeACHScheduleId,
					info.ReceivableDetailEffectiveBalance,
					info.ReceivableDetailTaxEffectiveBalance ,
                    RowNumber = ROW_NUMBER() OVER(PARTITION BY info.ReceivableDetailId
                    ORDER BY info.SettlementDate,
                             info.OneTimeACHId,
							 info.ReceivableDetailAmount,
							 info.ReceivableDetailTaxAmount
							 )
			INTO #ReceivableDetailInfoToAllocation
             FROM #OneTimeACHInfo AS info
             JOIN CTE_DistinctReceivableDetails ON CTE_DistinctReceivableDetails.ReceivableDetailId = info.ReceivableDetailId

IF EXISTS (SELECT * FROM #ReceivableDetailInfoToAllocation)
BEGIN
DECLARE db_cursor CURSOR FOR
SELECT  OneTimeACHScheduleId,ReceivableDetailId,OneTimeACHId
FROM #ReceivableDetailInfoToAllocation
ORDER BY ROWNumber

DECLARE @ReceivableDetailTaxEffectiveBalance DECIMAL(16,2),
@OneTimeACHScheduleId BIGINT,
@ReceivableDetailId BIGINT,
@OneTimeACHId BIGINT


OPEN db_cursor
FETCH NEXT FROM db_cursor INTO @OneTimeACHScheduleId,@ReceivableDetailId,@OneTimeACHId
WHILE @@FETCH_STATUS = 0
BEGIN

Update #OneTimeACHInfo SET ReceivableDetailAmount = CASE WHEN #ReceivableDetailInfoToAllocation.ReceivableDetailEffectiveBalance >= ReceivableDetailAmount AND  #ReceivableDetailInfoToAllocation.ReceivableDetailEffectiveBalance > 0 THEN ReceivableDetailAmount
														 WHEN #ReceivableDetailInfoToAllocation.ReceivableDetailEffectiveBalance <= ReceivableDetailAmount AND  #ReceivableDetailInfoToAllocation.ReceivableDetailEffectiveBalance < 0 THEN ReceivableDetailAmount
														 WHEN #ReceivableDetailInfoToAllocation.ReceivableDetailEffectiveBalance = 0.0 THEN 0.0
														 ELSE #ReceivableDetailInfoToAllocation.ReceivableDetailEffectiveBalance END,
						   ReceivableDetailTaxAmount = CASE WHEN #ReceivableDetailInfoToAllocation.ReceivableDetailTaxEffectiveBalance >= ReceivableDetailTaxAmount AND #ReceivableDetailInfoToAllocation.ReceivableDetailTaxEffectiveBalance > 0 THEN ReceivableDetailTaxAmount
															WHEN #ReceivableDetailInfoToAllocation.ReceivableDetailTaxEffectiveBalance <= ReceivableDetailTaxAmount AND #ReceivableDetailInfoToAllocation.ReceivableDetailTaxEffectiveBalance < 0 THEN ReceivableDetailTaxAmount
															WHEN #ReceivableDetailInfoToAllocation.ReceivableDetailTaxEffectiveBalance = 0.0 THEN 0.0
															ELSE #ReceivableDetailInfoToAllocation.ReceivableDetailTaxEffectiveBalance END,
						   UnAllocatedAmount = UnAllocatedAmount +
												CASE WHEN (#ReceivableDetailInfoToAllocation.ReceivableDetailEffectiveBalance >= ReceivableDetailAmount AND  #ReceivableDetailInfoToAllocation.ReceivableDetailEffectiveBalance > 0)
													OR (#ReceivableDetailInfoToAllocation.ReceivableDetailEffectiveBalance <= ReceivableDetailAmount AND  #ReceivableDetailInfoToAllocation.ReceivableDetailEffectiveBalance < 0 )
													THEN 0.0
													ELSE ReceivableDetailAmount - #ReceivableDetailInfoToAllocation.ReceivableDetailEffectiveBalance END
												+
						                       CASE WHEN (#ReceivableDetailInfoToAllocation.ReceivableDetailTaxEffectiveBalance >= ReceivableDetailTaxAmount AND #ReceivableDetailInfoToAllocation.ReceivableDetailTaxEffectiveBalance > 0 )
													OR (#ReceivableDetailInfoToAllocation.ReceivableDetailTaxEffectiveBalance <= ReceivableDetailTaxAmount AND #ReceivableDetailInfoToAllocation.ReceivableDetailTaxEffectiveBalance < 0 )
													THEN  0.0
													ELSE ReceivableDetailTaxAmount - #ReceivableDetailInfoToAllocation.ReceivableDetailTaxEffectiveBalance  END
OUTPUT Inserted.ReceivableDetailAmount , Inserted.ReceivableDetailTaxAmount , Inserted.ReceivableDetailId INTO #AppliedAmount
FROM #OneTimeACHInfo
JOIN #ReceivableDetailInfoToAllocation ON #OneTimeACHInfo.OneTimeACHId =  #ReceivableDetailInfoToAllocation. OneTimeACHId
AND #OneTimeACHInfo.ReceivableDetailId = #ReceivableDetailInfoToAllocation.ReceivableDetailId
AND #OneTimeACHInfo.OneTimeACHScheduleId = #ReceivableDetailInfoToAllocation.OneTimeACHScheduleId
WHERE #OneTimeACHInfo.ReceivableDetailId = @ReceivableDetailId
AND @OneTimeACHScheduleId = #OneTimeACHInfo.OneTimeACHScheduleId
AND @OneTimeACHId = #OneTimeACHInfo.OneTimeACHId

UPDATE #ReceivableDetailInfoToAllocation SET
ReceivableDetailTaxEffectiveBalance = CASE WHEN SIGN(ReceivableDetailTaxEffectiveBalance) = SIGN(ReceivableDetailTaxEffectiveBalance- #AppliedAmount.ReceivableDetailTaxAmount) THEN ReceivableDetailTaxEffectiveBalance- #AppliedAmount.ReceivableDetailTaxAmount ELSE 0.0 END,
ReceivableDetailEffectiveBalance = CASE WHEN SIGN(ReceivableDetailEffectiveBalance) = SIGN(ReceivableDetailEffectiveBalance- #AppliedAmount.ReceivableDetailAmount) THEN ReceivableDetailEffectiveBalance- #AppliedAmount.ReceivableDetailAmount ELSE 0.0 END
FROM #ReceivableDetailInfoToAllocation
JOIN #AppliedAmount ON #ReceivableDetailInfoToAllocation.ReceivableDetailId = #AppliedAmount.ReceivableDetailId
WHERE #ReceivableDetailInfoToAllocation.ReceivableDetailId = @ReceivableDetailId

DELETE FROM #AppliedAmount

FETCH NEXT FROM db_cursor INTO @OneTimeACHScheduleId,@ReceivableDetailId,@OneTimeACHId
END

CLOSE db_cursor
DEALLOCATE db_cursor

END
 INSERT INTO #OneTimeACHInfo
    SELECT DISTINCT
           OneTimeACHId = OneTimeACHId,
           ReceivableId = ReceivableId,
           ReceivableInvoiceId = ReceivableInvoiceId, --
           ContractId = ContractId,
           DiscountingId = DiscountingId,
           ReceivableTypeName = ReceivableTypeName, --
           PaymentScheduleId = PaymentScheduleId, --
           SettlementDate = SettlementDate,
           GLConfigurationId = GLConfigurationId,
           ReceiptLegalEntityNumber = ReceiptLegalEntityNumber,
           ReceiptLegalEntityName = ReceiptLegalEntityName,
           ReceiptBankAccountId = ReceiptBankAccountId,
           ReceivableLegalEntityId = ReceivableLegalEntityId,
           ReceiptLegalEntityId = ReceiptLegalEntityId,
           CashTypeId = CashTypeId,
           UnAllocatedAmount = ISNULL(UnAllocatedAmount, 0.00),
           ReceivableDetailAmount = 0.00,
           ReceivableDetailTaxAmount = 0.00,
           CurrencyId = CurrencyId,
           CustomerId = CustomerId,
           CustomerBankAccountId = CustomerBankAccountId,
           OneTimeACHReceivableId = OneTimeACHReceivableId, --
           OneTimeACHInvoiceId = OneTimeACHInvoiceId, --
           OneTimeACHScheduleId = OneTimeACHScheduleId, --
           IsDSL = IsDSL, --
           IncomeType = IncomeType, --
           IsRental = 0, --
           CheckNumber = CheckNumber,
           CustomerBankDebitCode = CustomerBankDebitCode,
           CustomerBankACHRoutingNumber = CustomerBankACHRoutingNumber,
           ReceivableDueDate = ReceivableDueDate,
           CostCenterId = CostCenterId,
           ReceivableRemitToId = ReceivableRemitToId,
           ReceivableRemitToName = ReceivableRemitToName,
           ReceiptGLTemplateId = ReceiptGLTemplateId,
           ReceiptGLTemplateName = ReceiptGLTemplateName,
           IsTaxAssessed = IsTaxAssessed, --
           ReceivableDetailId = ReceivableDetailId, --
           CustomerBankAccountNumber_CT = CustomerBankAccountNumber_CT,
           IsUnAllocation = 1,
		   OneTimeBankAccount = OneTimeBankAccount,
		   ReceivableDetailEffectiveBalance = ReceivableDetailEffectiveBalance,
		   ReceivableDetailTaxEffectiveBalance = ReceivableDetailTaxEffectiveBalance,
		   IsPrivateLabel = IsPrivateLabel,
		   BankAccountIsOnHold = BankAccountIsOnHold
    FROM #OneTimeACHInfo
    WHERE UnallocatedAmount <> 0.00
	ORDER BY OneTimeACHId,ReceivableDetailId;


----ReAllocate Amount for Adjustment Receivables ----
	Select OneTimeACHId,SUM(UnAllocatedAmount) AdjustmentAmount,MIN(Id) Id INTO #AdjustmentOTACHIds
	FROM #OneTimeACHInfo 
	where ((#OneTimeACHInfo.IsUnAllocation = 1 AND #OneTimeACHInfo.UnAllocatedAmount <> 0.00))
	GROUP BY OneTimeACHId
	HAVING SUM(UnAllocatedAmount) < 0

	SELECT Adjust.AdjustmentAmount,Adjust.OneTimeAChId,OTACH.ReceivableDetailId,OTACH.ReceivableDetailTaxAmount,OTACH.ReceivableDetailAmount INTO #AdjustmentOTACHInfo
FROM #AdjustmentOTACHIds Adjust
JOIN #OneTimeACHInfo OTACH ON Adjust.OneTimeACHId = OTACH.OneTimeACHId
WHERE (OTACH.ReceivableDetailTaxAmount + OTACH.ReceivableDetailAmount) > 0.0 AND OTACH.IsUnAllocation = 0
ORDER BY OneTimeACHId,ReceivableDetailId
	
IF EXISTS
(
    SELECT 1
    FROM #AdjustmentOTACHInfo
)
    BEGIN
        DECLARE db2_cursor CURSOR
        FOR SELECT OneTimeAChId, 
                   ReceivableDetailId, 
                   ReceivableDetailTaxAmount, 
                   ReceivableDetailAmount
            FROM #AdjustmentOTACHInfo
            ORDER BY OneTimeACHId, 
                     ReceivableDetailId;

        DECLARE @AdjustmentAmount DECIMAL(16, 2), @AdjustOneTimeACHId BIGINT, @AdjustReceivableDetailId BIGINT, @AvailableReceivableDetailTaxAmount DECIMAL(16, 2), @AvailableReceivableDetailAmount DECIMAL(16, 2);

        OPEN db2_cursor;
        FETCH NEXT FROM db2_cursor INTO @AdjustOneTimeACHId, @AdjustReceivableDetailId, @AvailableReceivableDetailTaxAmount, @AvailableReceivableDetailAmount;

		SET @AdjustmentAmount = (SELECT TOP 1 AdjustmentAmount FROM #AdjustmentOTACHInfo WHERE OneTimeACHId = @AdjustOneTimeACHId)

        WHILE @@FETCH_STATUS = 0 AND @AdjustmentAmount <> 0.00
            BEGIN
                DECLARE @AdjustedReceivableDetailTaxAmount DECIMAL(16, 2), @AdjustedReceivableDetailAmount DECIMAL(16, 2);

                SET @AdjustedReceivableDetailAmount = CASE
                                                         WHEN @AvailableReceivableDetailAmount + @AdjustmentAmount > 0
                                                         THEN @AvailableReceivableDetailAmount + @AdjustmentAmount
                                                         ELSE 0.0
                                                     END;
                SET @AdjustmentAmount = CASE
                                            WHEN @AvailableReceivableDetailAmount + @AdjustmentAmount > 0
                                            THEN 0.00
                                            ELSE @AdjustmentAmount + @AvailableReceivableDetailAmount
                                        END;
                SET @AdjustedReceivableDetailTaxAmount = CASE
                                                            WHEN @AvailableReceivableDetailTaxAmount + @AdjustmentAmount > 0
                                                            THEN @AvailableReceivableDetailTaxAmount + @AdjustmentAmount
                                                            ELSE 0.0
                                                        END;
                SET @AdjustmentAmount = CASE
                                            WHEN @AvailableReceivableDetailTaxAmount + @AdjustmentAmount > 0
                                            THEN 0.00
                                            ELSE @AdjustmentAmount + @AvailableReceivableDetailTaxAmount
                                        END;
                UPDATE #OneTimeACHInfo
                  SET 
                      ReceivableDetailAmount = @AdjustedReceivableDetailAmount, 
                      ReceivableDetailTaxAmount = @AdjustedReceivableDetailTaxAmount
                WHERE OneTimeACHId = @AdjustOneTimeACHId
                      AND ReceivableDetailId = @AdjustReceivableDetailId;

                UPDATE #AdjustmentOTACHInfo
                  SET 
                      AdjustmentAmount = @AdjustmentAmount
                WHERE OneTimeACHId = @AdjustOneTimeACHId;

				SET @AdjustmentAmount = (SELECT TOP 1 AdjustmentAmount FROM #AdjustmentOTACHInfo WHERE OneTimeACHId = @AdjustOneTimeACHId)

                FETCH NEXT FROM db2_cursor INTO @AdjustOneTimeACHId, @AdjustReceivableDetailId, @AvailableReceivableDetailTaxAmount, @AvailableReceivableDetailAmount;
END;
        CLOSE db2_cursor;
        DEALLOCATE db2_cursor;
END;

UPDATE OneTimeInfo  SET OneTimeInfo.UnAllocatedAmount = OneTimeInfo.UnAllocatedAmount - Adjustment.AdjustmentAmount
FROM #OneTimeACHInfo OneTimeInfo
JOIN #AdjustmentOTACHIds Adjustment ON OneTimeInfo.Id = Adjustment.Id
WHERE OneTimeInfo.IsUnAllocation = 1
----ReAllocate Amount for Adjustment Receivables ----

	SELECT DISTINCT OneTimeACHId INTO #OneTimeACHIds FROM #OneTimeACHInfo;

	INSERT INTO #OneTimeACHInfo
	SELECT DISTINCT
		   OneTimeACHId = OTA.Id,
		   ReceivableId = NULL,
		   ReceivableInvoiceId = NULL,
		   ContractId = NULL,
		   DiscountingId = NULL,
		   ReceivableTypeName = NULL,
		   PaymentScheduleId = NULL,
		   SettlementDate = CASE
							  WHEN OTA.Settlementdate <= LEInfo.UpdatedSettlementDateForOTACH
							  THEN LEInfo.UpdatedSettlementDateForOTACH
							  ELSE OTA.Settlementdate
							END,
		   GLConfigurationId = LE.GLConfigurationId,
		   ReceiptLegalEntityNumber = LE.LegalEntityNumber,
		   ReceiptLegalEntityName = LE.Name,
		   ReceiptBankAccountId = OTA.LegalEntityBankAccountId,
		   ReceivableLegalEntityId = NULL,
		   ReceiptLegalEntityId = OTA.LegalEntityId,
		   CashTypeId = ISNULL(OTA.CashTypeId, @DefaultCashTypeId),
		   UnAllocatedAmount = OTA.UnAllocatedAmount_Amount,
		   ReceivableDetailAmount = 0.00,
		   ReceivableDetailTaxAmount = 0.00,
		   CurrencyId = OTA.CurrencyId,
		   CustomerId = OTA.CustomerId,
		   CustomerBankAccountId = OTA.BankAccountId,
		   OneTimeACHReceivableId = NULL,
		   OneTimeACHInvoiceId = NULL,
		   OneTimeACHScheduleId = NULL,
		   IsDSL = 0,
		   IncomeType = NULL,
		   IsRental = 0,
		   CheckNumber = OTA.CheckNumber,
		   CustomerBankDebitCode = BAC.DebitCode,
		   CustomerBankACHRoutingNumber = BB.ACHRoutingNumber,
		   ReceivableDueDate = NULL,
		   CostCenterId = OTA.CostCenterId,
		   ReceivableRemitToId = NULL,
		   ReceivableRemitToName = NULL,
		   ReceiptGLTemplateId = GT.Id,
		   ReceiptGLTemplateName = GT.Name,
		   IsTaxAssessed = 0,
		   ReceivableDetailId = NULL,
		   CustomerBankAccountNumber_CT = BA.AccountNumber_CT,
		   IsUnAllocation = 1,
		   OneTimeBankAccount = BA.IsOneTimeACHOnly,
		   ReceivableDetailEffectiveBalance = 0.0,
		   ReceivableDetailTaxEffectiveBalance = 0.0,
		   IsPrivateLabel = 0,
		   BankAccountIsOnHold = BA.OnHold
	FROM dbo.OneTimeACHes AS OTA
	INNER JOIN #LegalEntityBankInfo AS LEInfo ON LEInfo.LegalEntityId = OTA.LegalEntityId
												 AND LEInfo.BankAccountId = OTA.LegalEntityBankAccountId
	INNER JOIN dbo.LegalEntities AS LE ON LE.Id = OTA.LegalEntityId
	INNER JOIN dbo.BankAccounts AS BA ON BA.Id = OTA.BankAccountId
										 AND BA.IsActive = 1
	INNER JOIN dbo.BankAccountCategories AS BAC ON BAC.Id = BA.BankAccountCategoryId
	INNER JOIN dbo.BankBranches AS BB ON BA.BankBranchId = BB.Id
										 AND BA.AutomatedPaymentMethod = @ACHOrPAPAutomatedMethod
	INNER JOIN dbo.GLTemplates AS GT ON OTA.ReceiptGLTemplateId = GT.Id
	LEFT JOIN #OneTimeACHIds AS OTACHId ON OTA.Id = OTACHId.OneTimeACHId
	WHERE OTA.IsActive = 1
		  AND OTA.UnAllocatedAmount_Amount > 0
		  AND(OTACHId.OneTimeACHId IS NOT NULL OR @EntityType = @CustomerEntityType)
		  AND(@CustomerId = 0 OR OTA.CustomerId = @CustomerId)
		  AND OTA.STATUS IN (@PendingACHStatus)
		 AND OTA.SettlementDate >= @FromDate
		 AND OTA.SettlementDate <= LEInfo.UpdatedProcessThroughDateForOTACH;

    ---Currency Details --
    SELECT DISTINCT
           C.Id AS CurrencyId,
           C.Name AS CurrencyName,
           CC.Symbol AS CurrencySymbol,
           CC.ISO AS CurrencyISO
    INTO #CurrencyInfos
    FROM dbo.Currencies AS C
    JOIN dbo.CurrencyCodes AS CC ON C.CurrencyCodeId = CC.Id
    JOIN #OneTimeACHInfo AS OTAInfo ON OTAInfo.CurrencyId = C.Id
    WHERE C.IsActive = 1
          AND CC.IsActive = 1;

    --Receipt Bank Account Details--
    SELECT DISTINCT
           BB.Name AS ReceiptBankBranchName,
           BB.GenerateBalancedACH AS ReceiptBankGenerateBalancedACH,
           BB.GenerateControlFile AS ReceiptBankGenerateControlFile,
           LEB.SourceofInput AS ReceiptBankSourceofInput,
           LEB.ACHOperatorConfigId AS ReceiptBankACHOperatorConfigId,
           LEB.ACISCustomerNumber AS ReceipeBankACISCustomerNumber,
           BA.Id AS ReceiptBankAccountId,
           BAC.CreditCode AS ReceiptBankAccountCreditCode,
           BB.ACHRoutingNumber AS ReceiptBankACHRoutingNumber,
           BA.AccountNumber_CT AS ReceiptBankAccountNumber_CT,
           BA.AccountType,
		   BB.NACHAFilePaddingOption
    INTO #ReceiptBankAccountDetails
    FROM #OneTimeACHInfo AS OTInfo
    INNER JOIN dbo.LegalEntityBankAccounts AS LEB ON LEB.LegalEntityId = OTInfo.ReceiptLegalEntityId
                                                     AND LEB.BankAccountId = OTInfo.ReceiptBankAccountId
    INNER JOIN dbo.BankAccounts AS BA ON BA.Id = LEB.BankAccountId
                                         AND BA.IsActive = 1
    INNER JOIN dbo.BankAccountCategories AS BAC ON BAC.Id = BA.BankAccountCategoryId
    INNER JOIN dbo.BankBranches AS BB ON BA.BankBranchId = BB.Id
    WHERE LEB.IsActive = 1
          AND BB.IsActive = 1
          AND BA.IsActive = 1;

    -- ACH ACHOperatorCOnfig ---
    SELECT DISTINCT
           AOC.FileFormat,
		   AOC.Id AS ReceiptBankACHOperatorConfigId
    INTO #ACHOperatorConfigInfos
    FROM dbo.ACHOperatorConfigs AS AOC
    INNER JOIN #ReceiptBankAccountDetails AS BD ON AOC.Id = BD.ReceiptBankACHOperatorConfigId
    WHERE AOC.IsActive = 1;

    -- Customer Details --
;WITH CTE_DistinctCustomerId AS
	(
		SELECT DISTINCT CustomerId FROM #OneTimeACHInfo
	)
    SELECT CTE.CustomerId AS CustomerId,
           p.PartyName AS PartyName,
           C.IsConsolidated AS IsConsolidated,
           p.PartyNumber
    INTO #CustomerInfos
    FROM CTE_DistinctCustomerId  CTE
    INNER JOIN dbo.Parties AS p ON p.Id = CTE.CustomerId
    INNER JOIN dbo.Customers AS C ON C.Id = P.Id;

    ---Contract Info

    CREATE TABLE #ContractInfos
    (ContractId                    BIGINT NULL,
     SequenceNumber                NVARCHAR(100),
     ContractType                  NVARCHAR(14),
     IsLease                       BIT,
     LineOfBusinessId              BIGINT,
     InstrumentTypeId              BIGINT,
     ContractOriginationId         BIGINT,
     NonAccrualDate                DATE,
     IsContractInNonAccrual        BIT,
     SyndicationType               NVARCHAR(16),
     SyndicationEffectiveDate      DATE NULL,
     LeaseContractType             NVARCHAR(30),
     CurrentDealId                 BIGINT,
     CreditApprovedStructureId     BIGINT NULL,
     CostCenterId                  BIGINT,
     BranchId                      BIGINT
    );

	SELECT DISTINCT ContractId INTO #DistinctContractIds FROM #OneTimeACHInfo

    INSERT INTO #ContractInfos
    SELECT
           ContractId = C.Id,
           SequenceNumber = C.SequenceNumber,
           ContractType = C.ContractType,
           IsLease = 1,
           LineofBusinessId = LF.LineofBusinessId,
           InstrumentTypeId = LF.InstrumentTypeId,
           ContractOriginationId = LF.ContractOriginationId,
           NonAccrualDate = C.NonAccrualDate,
           IsContractInNonAccrual = C.IsNonAccrual,
           SyndicationType = C.SyndicationType,
           SyndicationEffectiveDate = LP.StartDate,
           LeaseContractType = LFD.LeaseContractType,
           CurrentDealId = LF.Id,
           CreditApprovedStructureId = C.CreditApprovedStructureId,
           CostCenterId = LF.CostCenterId,
           BranchId = LF.BranchId
    FROM dbo.Contracts AS C
    INNER JOIN dbo.LeaseFinances AS LF ON LF.ContractId = C.Id
    INNER JOIN dbo.LeaseFinanceDetails AS LFD ON LFD.Id = LF.Id
    INNER JOIN #DistinctContractIds AS ContractIds ON C.Id = ContractIds.ContractId
    LEFT JOIN dbo.ReceivableForTransfers AS RFT ON C.Id = RFT.ContractId
                                                   AND RFT.ApprovalStatus = @ApprovedSyndicationStatus
                                                   AND C.SyndicationType NOT IN(@UnknownSyndicationType, @NoneSyndicationType)
    LEFT JOIN dbo.LeasePaymentSchedules AS LP ON RFT.LoanPaymentId = LP.Id AND Lp.IsACtive = 1
    WHERE LF.IsCurrent = 1
          AND C.ContractType = @LeaseContractType
		  AND (@ExcludeBackgroundProcessingPendingContracts = 0 OR C.BackgroundProcessingPending = 0);

    INSERT INTO #ContractInfos
    SELECT
           ContractId = C.Id,
           SequenceNumber = C.SequenceNumber,
           ContractType = C.ContractType,
           IsLease = 0,
           LineofBusinessId = LF.LineofBusinessId,
           InstrumentTypeId = LF.InstrumentTypeId,
           ContractOriginationId = LF.ContractOriginationId,
           NonAccrualDate = C.NonAccrualDate,
           IsContractInNonAccrual = C.IsNonAccrual,
           SyndicationType = C.SyndicationType,
           SyndicationEffectiveDate = LP.StartDate,
           LeaseContractType = '_',
           CurrentDealId = LF.Id,
           CreditApprovedStructureId = C.CreditApprovedStructureId,
           CostCenterId = LF.CostCenterId,
           BranchId = LF.BranchId
    FROM dbo.Contracts AS C
    INNER JOIN dbo.LoanFinances AS LF ON LF.ContractId = C.Id
    INNER JOIN #DistinctContractIds AS ContractIds ON C.Id = ContractIds.ContractId
    LEFT JOIN dbo.ReceivableForTransfers AS RFT ON C.Id = RFT.ContractId
                                                   AND RFT.ApprovalStatus = @ApprovedSyndicationStatus
                                                   AND C.SyndicationType NOT IN(@UnknownSyndicationType, @NoneSyndicationType)
    LEFT JOIN dbo.LoanPaymentSchedules AS LP ON RFT.LoanPaymentId = LP.Id AND Lp.IsACtive = 1
    WHERE LF.IsCurrent = 1
          AND C.ContractType <> @LeaseContractType;

	;WITH CTE_DistinctCustomerReceivableIds AS
	(
		SELECT DISTINCT ReceivableId
			FROM #OneTimeACHInfo
		WHERE  #OneTimeACHInfo.ContractId IS NULL
			AND #OneTimeACHInfo.DiscountingId IS NULL
			--AND ReceivableEntityType = @CUReceivableEntityType
	)
    SELECT DISTINCT
           ReceivableIds.ReceivableId,
           LineofBusinessId = CASE
                                WHEN S.Id IS NOT NULL
                                THEN S.LineofBusinessId
                                ELSE SundryRecurrings.LineofBusinessId
                              END,
           InstrumentTypeId = CASE
                                WHEN S.Id IS NOT NULL
                                THEN S.InstrumentTypeId
                                ELSE SundryRecurrings.InstrumentTypeId
                              END,
           CostCenterId = CASE
                            WHEN S.Id IS NOT NULL
                            THEN S.CostCenterId
                            ELSE SundryRecurrings.CostCenterId
                          END
    INTO #CustomerReceivableSundryInfos
    FROM CTE_DistinctCustomerReceivableIds ReceivableIds
    LEFT JOIN dbo.Sundries AS S ON S.ReceivableId = ReceivableIds.ReceivableId AND S.IsActive = 1
    LEFT JOIN dbo.SundryRecurringPaymentSchedules ON ReceivableIds.ReceivableId = SundryRecurringPaymentSchedules.ReceivableId
    LEFT JOIN dbo.SundryRecurrings ON SundryRecurringPaymentSchedules.SundryRecurringId = SundryRecurrings.Id AND SundryRecurrings.IsActive = 1

    -- DisCounting Details
    SELECT DISTINCT
           DiscountingId = D.Id,
           SequenceNumber = D.SequenceNumber,
           LineofBusinessId = DF.LineofBusinessId,
           InstrumentTypeId = DF.InstrumentTypeId,
           CurrentDealId = DF.Id,
           CostCenterId = DF.CostCenterId,
           BranchId = DF.BranchId
    INTO #DiscountingContractInfo
    FROM #OneTimeACHInfo
    INNER JOIN dbo.Discountings AS D ON D.Id = #OneTimeACHInfo.DiscountingId
    INNER JOIN dbo.DiscountingFinances AS DF ON DF.DiscountingId = D.Id
    WHERE DF.IsCurrent = 1
          AND DF.BookingStatus = @ApprovedBookingStatus;

    -- Get RemitTo Detais For Selected Le
    SELECT RemitToId,
           LegalEntityId,
           RemitToName
    INTO #RemitToForOneTime
    FROM
    (
        SELECT RemitToId = RemitToes.Id,
               RemitToName = RemitToes.Name,
               LegalEntityId = LegalEntityRemitToes.LegalEntityId,
               RANK = ROW_NUMBER() OVER(PARTITION BY LegalEntityRemitToes.LegalEntityId
               ORDER BY LegalEntityRemitToes.IsDefault DESC,
                        LegalEntityRemitToes.Id)
        FROM dbo.RemitToes
        INNER JOIN dbo.LegalEntityRemitToes ON RemitToes.Id = LegalEntityRemitToes.RemitToId
                                               AND RemitToes.IsActive = 1
        INNER JOIN
        (
            SELECT DISTINCT
                   #OneTimeACHInfo.ReceiptLegalEntityId
            FROM #OneTimeACHInfo
        ) AS OTAInfo ON OTAInfo.ReceiptLegalEntityId = LegalEntityRemitToes.LegalEntityId
    ) AS remitToLegalEntity
    WHERE remitToLegalEntity.Rank = 1;

    ---LoanPaymentScheduleInfo ----

    SELECT DISTINCT
           OTAInfo.ReceivableId,
           LP.PaymentType,
           LP.Id AS PaymentId
    INTO #LoanPaymentScheduleInfos
    FROM #OneTimeACHInfo AS OTAInfo
    JOIN dbo.LoanPaymentSchedules AS LP ON  OTAInfo.PaymentScheduleId = LP.Id
                                           AND LP.IsActive = 1;

    --final list
INSERT INTO ACHSchedule_Extract([IsOneTimeACH],[OneTimeACHId],[OneTimeACHInvoiceId],[OneTimeACHReceivableId],[OneTimeACHScheduleId],[ReceivableDetailId],[ACHScheduleId],[ACHAmount],[UnAllocatedAmount],[CheckNumber],[ACHPaymentNumber],[ACHSchedulePaymentType],[SettlementDate],[RemitToId],[RemitToName],[CashTypeId],[BranchId],[ReceiptTypeName],[ReceiptTypeId],[GLTemplateId],[GLConfigurationId],[ReceiptClassificationType],[ReceiptGLTemplateName],[CurrencyId] ,[CurrencyName] ,[CurrencyCode] ,[CurrencySymbol],[ContractId],[SequenceNumber],[CostCenterId],[InstrumentTypeId],[LineofBusinessId],[DiscountingId],[SyndicationDate],[IsPrivateLabel],[ContractType],[PrivateLabelName] ,[CustomerId] ,[CustomerNumber] ,[IsConsolidated],[CustomerName],[CustomerBankAccountId],[CustomerBankAccountNumber_CT] ,[CustomerBankAccountDebitCode],[CustomerBankAccountACHRoutingNumber] ,[ReceivableId] ,[ReceivableInvoiceId] ,[PaymentScheduleId],[ReceivableDetailAmount],[ReceivableDetailTaxAmount],[ReceivableLegalEntityId] ,[IsNonAccrual] ,[ReceiptLegalEntityId] ,[ReceiptLegalEntityNumber] ,[ReceiptLegalEntityName] ,[ReceiptBankAccountId] ,[ReceiptBankAccountNumber_CT] ,[ReceiptBankGenerateBalancedACH] ,[ReceiptBankGenerateControlFile] ,[ReceiptBankBranchName] ,[ReceiptBankSourceofInput] ,[ReceiptBankACISCustomerNumber],[ReceiptBankACHRoutingNumber],[ReceiptBankAccountCreditCode],[ReceiptBankAccountACHOperatorConfigId] ,[FileFormat] ,[PaymentThresholdEmailId] ,[PaymentThresholdAmount] ,[ACHPaymentThresholdDetailId] ,[PaymentThreshold] ,[JobStepInstanceId],[CreatedById],[CreatedTime],[ReceiptBankAccountType],[IsTaxAssessed],[HasMultipleContractReceivables] ,[HasPendingDSLOrNANSDLReceipt] ,[EmailTemplateName],[ErrorCode] ,[NACHAFilePaddingOption] ,[InvalidOpenPeriodFromDate],[InvalidOpenPerionToDate],[OneTimeBankAccount],[BankAccountIsOnHold])
    SELECT IsOneTimeACH = 1,
           OneTimeACHId = #OneTimeACHInfo.OneTimeACHId,
           OneTimeACHInvoiceId = #OneTimeACHInfo.OneTimeACHInvoiceId,
           OneTimeACHReceivableId = #OneTimeACHInfo.OneTimeACHReceivableId,
           OneTimeACHScheduleId = #OneTimeACHInfo.OneTimeACHScheduleId,
           ReceivableDetailId = #OneTimeACHInfo.ReceivableDetailId,
           ACHScheduleId = NULL,
           ACHAmount = CASE
                         WHEN #OneTimeACHInfo.IsUnAllocation = 1
                         THEN #OneTimeACHInfo.UnAllocatedAmount
                         ELSE ISNULL(#OneTimeACHInfo.ReceivableDetailAmount,0) + ISNULL(#OneTimeACHInfo.ReceivableDetailTaxAmount,0)
                       END,
           UnAllocatedAmount = CASE
                                 WHEN #OneTimeACHInfo.IsUnAllocation = 1
                                 THEN #OneTimeACHInfo.UnAllocatedAmount
                                 ELSE 0.00
                               END,
           CheckNumber = #OneTimeACHInfo.CheckNumber,
           ACHPaymentNumber = NULL,
           ACHSchedulePaymentType = '_',
           SettlementDate = #OneTimeACHInfo.SettlementDate,
           RemitToId = ISNULL(#OneTimeACHInfo.ReceivableRemitToId,#RemitToForOneTime.RemitToId),
           RemitToName = ISNULL(#OneTimeACHInfo.ReceivableRemitToName,#RemitToForOneTime.RemitToName),
           CashTypeId = ISNULL(#OneTimeACHInfo.CashTypeId,@DefaultCashTypeId),
           BranchId = CASE
                        WHEN #ContractInfos.BranchId IS NOT NULL
                        THEN #ContractInfos.BranchId
                        ELSE #DiscountingContractInfo.BranchId
                      END,
           ReceiptTypeName = CASE
                               WHEN #ACHOperatorConfigInfos.FileFormat = @ACHFileFormat AND OTRI.Id IS NOT NULL THEN @WebOneTimeACHReceiptTypeValue 
                               WHEN #ACHOperatorConfigInfos.FileFormat = @ACHFileFormat AND OTRI.Id IS  NULL THEN  @ACHReceiptTypeValue 
                               WHEN #ACHOperatorConfigInfos.FileFormat = @PAPFileFormat AND OTRI.Id IS NOT NULL THEN @WebOneTimePAPReceiptTypeValue 
                               WHEN #ACHOperatorConfigInfos.FileFormat = @PAPFileFormat AND OTRI.Id IS  NULL THEN @PAPReceiptTypeValue 
                               ELSE @UnknownReceiptTypeValue
                             END,
           ReceiptTypeId = CASE
                               WHEN #ACHOperatorConfigInfos.FileFormat = @ACHFileFormat AND OTRI.Id IS NOT NULL THEN @WebACHReceiptTypeId 
                               WHEN #ACHOperatorConfigInfos.FileFormat = @ACHFileFormat AND OTRI.Id IS  NULL THEN  @ACHReceiptTypeId 
                               WHEN #ACHOperatorConfigInfos.FileFormat = @PAPFileFormat AND OTRI.Id IS NOT NULL THEN @WebPAPReceiptTypeId 
                               WHEN #ACHOperatorConfigInfos.FileFormat = @PAPFileFormat AND OTRI.Id IS  NULL THEN @PAPReceiptTypeId
                               ELSE 0
                             END,
           GLTemplateId = #OneTimeACHInfo.ReceiptGLTemplateId,
           GLConfigurationId = #OneTimeACHInfo.GLConfigurationId,
           ReceiptClassificationType = CASE
                                         WHEN #ContractInfos.IsLease = 1
                                         THEN @CashReceiptClassficationType
                                         WHEN #ContractInfos.IsLease = 0
                                              AND #OneTimeACHInfo.PaymentScheduleId IS NOT NULL
                                              AND #OneTimeACHInfo.IsDSL = 1
                                              AND #LoanPaymentScheduleInfos.PaymentType NOT IN(@DownPaymentPaymentTypevalue,@InterimPaymentTypeValue)
                                              AND
                                                  ( #OneTimeACHInfo.IsRental = 1
                                                    OR #OneTimeACHInfo.ReceivableTypeName IN(@LoanPrincipalReceivableTypeName,@LoanInterestReceivableTypeName)
                                                  )
                                         THEN @DSLReceiptClassficationType
                                         WHEN #ContractInfos.IsLease = 0
                                              AND #OneTimeACHInfo.PaymentScheduleId IS NOT NULL
                                              AND #OneTimeACHInfo.IsDSL = 0
                                              AND #ContractInfos.IsContractInNonAccrual = 1
                                              AND
                                                  ( #OneTimeACHInfo.IsRental = 1
                                                    OR #OneTimeACHInfo.ReceivableTypeName IN(@LoanPrincipalReceivableTypeName,@LoanInterestReceivableTypeName)
                                                  )
                                              AND #OneTimeACHInfo.IncomeType NOT IN(@InterimInterestIncomeType,@TakeDownInterestIncomeType)
                                         THEN @NonAccrualNonDSLReceiptClassficationType
                                         ELSE @CashReceiptClassficationType
                                       END,
           ReceiptGLTemplateName = #OneTimeACHInfo.ReceiptGLTemplateName,
           CurrencyId = #OneTimeACHInfo.CurrencyId,
           CurrencyName = #CurrencyInfos.CurrencyName,
           CurrencyCode = #CurrencyInfos.CurrencyISO,
           CurrencySymbol = #CurrencyInfos.CurrencySymbol,
           ContractId = #ContractInfos.ContractId,
           SequenceNumber = #ContractInfos.SequenceNumber,
           CostCenterId = CASE
                                    WHEN OTA.CostCenterId IS NOT NULL
                                    THEN OTA.CostCenterId
                                    WHEN #ContractInfos.CostCenterId IS NOT NULL
                                    THEN #ContractInfos.CostCenterId
                                    WHEN #CustomerReceivableSundryInfos.CostCenterId IS NOT NULL
                                    THEN #CustomerReceivableSundryInfos.CostCenterId
                                    ELSE #DiscountingContractInfo.CostCenterId
                                  END,
           InstrumentTypeId = CASE
                                WHEN OTA.InstrumentTypeId IS NOT NULL
                                THEN OTA.InstrumentTypeId
                                WHEN #ContractInfos.InstrumentTypeId IS NOT NULL
                                THEN #ContractInfos.InstrumentTypeId
                                WHEN #CustomerReceivableSundryInfos.InstrumentTypeId IS NOT NULL
                                THEN #CustomerReceivableSundryInfos.InstrumentTypeId
                                ELSE #DiscountingContractInfo.InstrumentTypeId
                              END,
           LineofBusinessId = CASE
                                WHEN OTA.LineofBusinessId IS NOT NULL
                                THEN OTA.LineofBusinessId
                                WHEN #ContractInfos.LineofBusinessId IS NOT NULL
                                THEN #ContractInfos.LineofBusinessId
                                WHEN #CustomerReceivableSundryInfos.LineofBusinessId IS NOT NULL
                                THEN #CustomerReceivableSundryInfos.LineofBusinessId
                                ELSE #DiscountingContractInfo.LineofBusinessId
                              END,
           DiscountingId = #OneTimeACHInfo.DiscountingId,
           SyndicationDate = #ContractInfos.SyndicationEffectiveDate,
           IsPrivateLabel = ISNULL(#OneTimeAChInfo.IsPrivateLabel,0),
           ContractType = ISNULL(#ContractInfos.ContractType,'_'),
           PrivateLabelName = CASE
                                WHEN @UseProgramVendorAsCompanyName = 1
                                     AND #OneTimeACHInfo.IsPrivateLabel = 1
                                THEN #OneTimeAChInfo.ReceivableRemitToName
                                ELSE NULL
                              END,
           CustomerId = #CustomerInfos.CustomerId,
           CustomerNumber = #CustomerInfos.PartyNumber,
           IsConsolidated = #CustomerInfos.IsConsolidated,
           CustomerName = #CustomerInfos.PartyName,
           CustomerBankAccountId = #OneTimeACHInfo.CustomerBankAccountId,
           CustomerBankAccountNumber_CT = #OneTimeACHInfo.CustomerBankAccountNumber_CT,
           CustomerBankAccountDebitCode = #OneTimeACHInfo.CustomerBankDebitCode,
           CustomerBankAccountACHRoutingNumber = #OneTimeACHInfo.CustomerBankACHRoutingNumber,
           ReceivableId = #OneTimeACHInfo.ReceivableId,
           ReceivableInvoiceId = #OneTimeACHInfo.ReceivableInvoiceId,
           PaymentScheduleId = #OneTimeACHInfo.PaymentScheduleId,
           ReceivableDetailAmount = ISNULL(#OneTimeACHInfo.ReceivableDetailAmount,0),
           ReceivableDetailTaxAmount = ISNULL(#OneTimeACHInfo.ReceivableDetailTaxAmount,0),
           ReceivableLegalEntityId = #OneTimeACHInfo.ReceivableLegalEntityId,
           IsNonAccrual = CASE
                            WHEN #ContractInfos.ContractId IS NOT NULL
                                 AND #ContractInfos.IsContractInNonAccrual = 1
                            THEN 1
                            ELSE 0
                          END,
           ReceiptLegalEntityId = #OneTimeACHInfo.ReceiptLegalEntityId,
           ReceiptLegalEntityNumber = #OneTimeACHInfo.ReceiptLegalEntityNumber,
           ReceiptLegalEntityName = #OneTimeACHInfo.ReceiptLegalEntityName,
           ReceiptBankAccountId = #ReceiptBankAccountDetails.ReceiptBankAccountId,
           ReceiptBankAccountNumber = #ReceiptBankAccountDetails.ReceiptBankAccountNumber_CT,
           ReceiptBankGenerateBalancedACH = ISNULL(#ReceiptBankAccountDetails.ReceiptBankGenerateBalancedACH,0),
           ReceiptBankGenerateControlFile = ISNULL(#ReceiptBankAccountDetails.ReceiptBankGenerateControlFile,0),
           ReceiptBankBranchName = #ReceiptBankAccountDetails.ReceiptBankBranchName,
           ReceiptBankSourceofInput = #ReceiptBankAccountDetails.ReceiptBankSourceofInput,
           ReceiptBankACISCustomerNumber = #ReceiptBankAccountDetails.ReceipeBankACISCustomerNumber,
           ReceiptBankACHRoutingNumber = #ReceiptBankAccountDetails.ReceiptBankACHRoutingNumber,
           ReceiptBankAccountCreditCode = #ReceiptBankAccountDetails.ReceiptBankAccountCreditCode,
           ReceiptBankAccountACHOperatorConfigId = #ACHOperatorConfigInfos.ReceiptBankACHOperatorConfigId,
           FileFormat = #ACHOperatorConfigInfos.FileFormat,
           PaymentThresholdEmailId = NULL,
           PaymentThresholdAmount = 0.0,
           ACHPaymentThresholdDetailId = NULL,
           PaymentThreshold = 0,
           @JobStepInstanceId,
           @CreatedById,
           @CreatedTime,
           #ReceiptBankAccountDetails.AccountType AS ReceiptBankAccountType,
           ISNULL(#OneTimeACHInfo.IsTaxAssessed,0) AS IsTaxAssessed,
		   0,
		   0,
           NULL,
		   ErrorCode = '_',
		NACHAFilePaddingOption = #ReceiptBankAccountDetails.NACHAFilePaddingOption,
		InvalidOpenPeriodFromDate = NULL,
		InvalidOpenPerionToDate = NULL,
		OneTimeBankAccount = #OneTimeACHInfo.OneTimeBankAccount,
		BankAccountIsOnHold = #OneTimeACHInfo.BankAccountIsOnHold
    FROM #OneTimeACHInfo
    INNER JOIN dbo.OneTimeACHes AS OTA ON #OneTimeACHInfo.OneTimeACHId = OTA.Id
    INNER JOIN #CustomerInfos ON #OneTimeACHInfo.CustomerId = #CustomerInfos.CustomerId
    INNER JOIN #CurrencyInfos ON #CurrencyInfos.CurrencyId = #OneTimeACHInfo.CurrencyId
    INNER JOIN #ReceiptBankAccountDetails ON #ReceiptBankAccountDetails.ReceiptBankAccountId = #OneTimeACHInfo.ReceiptBankAccountId
    INNER JOIN #RemitToForOneTime ON #RemitToForOneTime.LegalEntityId = #OneTimeACHInfo.ReceiptLegalEntityId
    LEFT JOIN #ContractInfos ON #ContractInfos.ContractId = #OneTimeACHInfo.ContractId
    LEFT JOIN #CustomerReceivableSundryInfos ON #OneTimeACHInfo.ReceivableId = #CustomerReceivableSundryInfos.ReceivableId
    LEFT JOIN #DiscountingContractInfo ON #DiscountingContractInfo.DiscountingId = #OneTimeACHInfo.DiscountingId
    LEFT JOIN #ACHOperatorConfigInfos ON #ACHOperatorConfigInfos.ReceiptBankACHOperatorConfigId = #ReceiptBankAccountDetails.ReceiptBankACHOperatorConfigId
    LEFT JOIN #LoanPaymentScheduleInfos ON #OneTimeACHInfo.ReceivableId = #LoanPaymentScheduleInfos.ReceivableId
                                           AND #LoanPaymentScheduleInfos.PaymentId = #OneTimeACHInfo.PaymentScheduleId
	LEFT JOIN OneTimeAChRequestInvoices OTRI ON OTRI.ReceivableInvoiceId = #OneTimeACHInfo.ReceivableInvoiceId AND OTRI.OneTimeACHId= #OneTimeACHInfo.OneTimeACHId
	WHERE #OneTimeACHInfo.ReceivableDetailAmount + #OneTimeACHInfo.ReceivableDetailTaxAmount <> 0.00
	OR (#OneTimeACHInfo.IsUnAllocation = 1 AND #OneTimeACHInfo.UnAllocatedAmount <> 0.00)

    IF EXISTS (SELECT 1 FROM ACHSchedule_Extract WHERE JobStepInstanceId = @JobStepInstanceId AND ErrorCode = '_' AND IsOneTimeACH = 1)
      BEGIN
        SET @AnyrecordExists = CAST(1 AS BIT);
    END;

    DROP TABLE #ContractInfos;
    DROP TABLE #OneTimeACHInfo;
    DROP TABLE #ReceiptBankAccountDetails;
    DROP TABLE #ACHOperatorConfigInfos;
    DROP TABLE #CurrencyInfos;
    DROP TABLE #CustomerInfos;
    DROP TABLE #LoanPaymentScheduleInfos;
    DROP TABLE #RemitToForOneTime;
    DROP TABLE #CustomerReceivableSundryInfos;
    DROP TABLE #LegalEntityBankInfo;
    DROP TABLE #DiscountingContractInfo;
	DROP TABLE #OneTimeACHIds
	DROP TABLE #OTACHDetails
	DROP TABLE #ValidEntities
	DROP TABLE #AppliedAmount
	DROP TABLE #ReceivableDetailInfoToAllocation
  END;

GO
