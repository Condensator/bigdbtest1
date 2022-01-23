SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[GetLoanContractsForReAccrual]
    (
    @LegalEntities ReAccrual_LoanLegalEntities READONLY,
    @EntityType NVARCHAR(20),
    @FilterOption NVARCHAR(20),
    @ContractId BIGINT = NULL,
    @CustomerId BIGINT = NULL,
    @DefaultCultureCurrency NVARCHAR(3),
    @CurrentBusinessDate DATE,
    @ReceivableContractType NVARCHAR(20),
    @ReceiptStatusPosted NVARCHAR(20),
    @ReceiptStatusReadyForPosting NVARCHAR(20),
    @InvoicePreferenceDoNotGenerate NVARCHAR(30),
    @AmendmentAppprovedStatus NVARCHAR(30),
    @RestructureAmendmentType NVARCHAR(30),
    @RebookAmendmentType NVARCHAR(30),
    @SyndicationAmendmentType NVARCHAR(30),
    @AssumptionAmendmentType NVARCHAR(30),
    @NonAccrualAmendmentType NVARCHAR(30),
    @ReAccrualAmendmentType NVARCHAR(30),
    @PayoffAmendmentType NVARCHAR(30),
    @PayDownAmendmentType NVARCHAR(30),
    @ReceiptAmendmentType NVARCHAR(20),
    @GLTransferAmendmentType NVARCHAR(20),
    @RenewalAmendmentType NVARCHAR(20),
    @NBVImpairmentAmendmentType NVARCHAR(20),
    @ResidualImpairmentAmendmentType NVARCHAR(20),
	@EffectiveDateForThresholdDate DATE
)
AS
BEGIN
SET
NOCOUNT ON;

DECLARE @LoanContractType NVARCHAR(20) = 'Loan';

-------------------------------------Temp Table creation----------------------------------------------------------------------------------------------
CREATE TABLE #ContractBasicInfo
(
     ContractId BIGINT,
     SequenceNumber NVARCHAR(100),
     LegalEntityId BIGINT,
     LegalEntityName NVARCHAR(100),
     LegalEntityNumber NVARCHAR(100),
     CustomerId BIGINT,
     CustomerName NVARCHAR(100),
     CustomerNumber NVARCHAR(100),
     LoanFinanceId BIGINT NULL,
     CommencementDate DATE,
     MaturityDate DATE,
     CurrencyId BIGINT,
     ContractCurrencyCode NVARCHAR(5),
     IsLease BIT,
     LeaseContractType NVARCHAR(100),
     NetInvestment DECIMAL(16, 2),
     IsDSL BIT,
     HoldingStatus NVARCHAR(30),
     ReAccrualTemplateId BIGINT NULL,
     Basis NVARCHAR(40) NULL,
     MinimumPercentageOfBasis DECIMAL (6, 2) NULL,
     MinimumQualifyingAmount DECIMAL(16, 2),
     ThresholdDate DATE NULL,
     DaysPastDueLimit INT NULL,
	 NonAccrualDate DATE,
	 ReAccrualDate DATE,
 )

CREATE TABLE #ContractLastIncomeGLPostedInfo
(
    ContractId BIGINT,
    IncomeDate DATE
)

CREATE TABLE #ContractLastIncomeGLPostedInfoPostNonAccrual
(
ContractId BIGINT,
IncomeDate DATE,
)

CREATE TABLE #ContractLastModificationDateInfoPostNonAccrual
(
ContractId BIGINT,
LastModificationDate DATE
)

CREATE TABLE #ReAccrualDateInfo
(
ContractId BigInt,
ReAccrualDate Date
)

CREATE TABLE #ContractLastModificationDateInfo
(
    ContractId BIGINT,
    LastModificationDate DATE
)

CREATE TABLE #ContractNBVInfo
(
    ContractId BIGINT,
    NBV DECIMAL (16, 2)
);

CREATE TABLE #ContractNBVWithBlendedInfo
(
    ContractId BIGINT,
    NBVWithBlended DECIMAL (16, 2)
)

CREATE TABLE #ContractOutstandingARInfo
(
    ContractId BIGINT,
    OutstandingAR DECIMAL(16, 2)
)

CREATE TABLE #ContractLastReceiptDateInfo
(
    ContractId BIGINT,
    LastReceiptDate DATE
)

CREATE TABLE #ExchangeRateInfo
(
    CurrencyId BIGINT,
    ExchangeRate DECIMAL(20, 10)
);

CREATE TABLE #BillingSuppressedInfo
(
    ContractId BIGINT,
    BillingSuppressed BIT
);

CREATE TABLE #SuspendedIncomeInfo
(
	ContractId BIGINT,
	SuspendedIncome DECIMAL(16,2)
);

CREATE TABLE #LastPaymentStartDate
(
	ContractId BIGINT,
	StartDate DATE
);

--------------------------------------END Table Creation------------------------------------------------------------------------------------------

------------*** FETCH CONTRACT BASIC INFO ***-------------------

INSERT INTO #ContractBasicInfo
SELECT
    ContractId = C.Id,
    SequenceNumber = C.SequenceNumber,
    LegalEntityId = LE.Id,
    LegalEntityName = LE.Name,
    LegalEntityNumber = LE.LegalEntityNumber,
    CustomerId = CU.Id,
    CustomerName = P.PartyName,
    CustomerNumber = P.PartyNumber,
    LoanFinanceId = LF.Id,
    CommencementDate = LF.CommencementDate,
    MaturityDate = LF.MaturityDate,
    CurrencyId = C.CurrencyId,
    ContractCurrencyCode = CC.ISO,
    IsLease = 0,
    LeaseContractType = NULL,
    NetInvestment = LF.LoanAmount_Amount,
    IsDSL = LF.IsDailySensitive,
    HoldingStatus = LF.HoldingStatus,
    ReAccrualTemplateId = LE.ReAccrualRuleTemplateId,
    Basis = RT.Basis,
    MinimumPercentageOfBasis = RT.MinimumPercentageofBasis,
    MinimumQualifyingAmount = RT.MinimumQualifyingAmount_Amount,
    ThresholdDate = DATEADD(DAY, ISNULL(0 - RT.DaysPastDue, 0), @EffectiveDateForThresholdDate),
    DaysPastDueLimit = RT.DaysPastDue,
	NonAccrualDate = C.NonAccrualDate,
	ReAccrualDate = NULL
FROM
    Contracts C
    JOIN LoanFinances LF ON C.Id = LF.ContractId AND LF.IsCurrent = 1
    JOIN @LegalEntities LES ON LF.LegalEntityId = LES.Id
    JOIN LegalEntities LE ON LES.Id = LE.Id
    JOIN Customers CU ON LF.CustomerId = CU.Id
    JOIN Currencies CUR ON C.CurrencyId = CUR.Id
    JOIN CurrencyCodes CC ON CUR.CurrencyCodeId = CC.Id
    JOIN Parties P ON CU.Id = P.Id
    LEFT JOIN ReAccrualRuleTemplates RT ON LE.ReAccrualRuleTemplateId = RT.Id
   
WHERE
 C.ContractType = @LoanContractType
        AND C.IsNonAccrualExempt = 0
        AND CU.IsNonAccrualExempt = 0
        AND C.SyndicationType NOT IN ('FullSale', 'ParticipatedSales')
        AND C.IsNonAccrual = 1
        AND LF.[Status] != 'FullyPaidOff'
        AND LF.[Status] != 'Terminated'
        AND C.ChargeOffStatus = '_'
        AND (@EntityType = '_' OR @FilterOption = 'All'
		OR  (@EntityType = 'Customer' AND CU.Id = @CustomerId)
		OR  (@EntityType = 'Loan' AND C.Id = @ContractId)
		);

CREATE CLUSTERED INDEX IX_ContractBasicInfoContractId ON #ContractBasicInfo (ContractId);

---*** LEGAL ENTITIES WITHOUT REACCRUAL RULE TEMPLATE***-------------------------------
SELECT DISTINCT(LegalEntityNumber)
FROM #ContractBasicInfo
WHERE ReAccrualTemplateId IS NULL;

---*** LEGAL ENTITIES WITHOUT GL FINANCIAL PERIOD***-----------------------------------
SELECT DISTINCT(LegalEntityNumber) INTO #LegalEntitiesWithGLFinancialOpenPeriods
FROM #ContractBasicInfo CB
INNER JOIN GLFinancialOpenPeriods GLFOP ON GLFOP.LegalEntityId = CB.LegalEntityId AND GLFOP.IsCurrent = 1;

SELECT CB.LegalEntityNumber from #ContractBasicInfo CB 
LEFT JOIN  #LegalEntitiesWithGLFinancialOpenPeriods LEWGL ON CB.LegalEntityNumber = LEWGL.LegalEntityNumber
WHERE LEWGL.LegalEntityNumber IS NULL;
---***EXCHANGE RATES***---------------------------------------------------------------

--->Get Domestic Currency
DECLARE @DomesticCurrencyId BIGINT = (SELECT TOP 1 C.Id
									    FROM Currencies C
									    JOIN CurrencyCodes CC ON C.CurrencyCodeId = CC.Id
									    WHERE C.IsActive = 1
									    AND CC.ISO = @DefaultCultureCurrency
									  );
									  
--->Fetch Foreign Currencies
SELECT DISTINCT(CurrencyId), ContractCurrencyCode
INTO #ForeignCurrencies
FROM #ContractBasicInfo FC
WHERE CurrencyId != @DomesticCurrencyId
  AND ReAccrualTemplateId IS NOT NULL;

--->Load Exchange Rates
WITH CTE_ExchangeRateInfo_Batch(CurrencyId, ExchangeRate, RowNumber) AS(
SELECT
	CER.CurrencyId,
	CER.ExchangeRate,
	RowNumber = ROW_NUMBER() OVER (PARTITION BY CER.CurrencyId
									ORDER BY Id DESC)
FROM CurrencyExchangeRates CER
    JOIN #ForeignCurrencies FC ON CER.CurrencyId = FC.CurrencyId
WHERE
	CER.ForeignCurrencyId = @DomesticCurrencyId
    AND CER.IsActive = 1
    AND CER.EffectiveDate <= GETDATE()
	)
INSERT INTO #ExchangeRateInfo
SELECT
    CurrencyId,
    ExchangeRate
FROM CTE_ExchangeRateInfo_Batch
WHERE RowNumber = 1;


---*** FOREIGN CURRENCIES WITHOUT EXHANGE RATES ***---------------------------------
SELECT ContractCurrencyCode AS ISO
FROM #ForeignCurrencies FC
LEFT JOIN #ExchangeRateInfo ER ON FC.CurrencyId = ER.CurrencyId
WHERE ER.CurrencyId IS NULL;


--->Inserting Exchange Rate Info for Domestic Currency as 1 for Calculation Purposes
INSERT INTO #ExchangeRateInfo
VALUES(@DomesticCurrencyId, 1.0);

---***FETCH VALID CONTRACTS TO PROCESS FOR REACCRUAL***--------------------------------------
SELECT
    CB.*,
    ExchangeRate = ER.ExchangeRate
INTO #ValidContractsToProcess
FROM
    #ContractBasicInfo CB
    JOIN #ExchangeRateInfo ER ON CB.CurrencyId = ER.CurrencyId
    JOIN #LegalEntitiesWithGLFinancialOpenPeriods LEWGLFOP ON LEWGLFOP.LegalEntityNumber = CB.LegalEntityNumber
WHERE
	CB.ReAccrualTemplateId IS NOT NULL;

CREATE CLUSTERED INDEX IX_ValidContractsContractId ON #ValidContractsToProcess (ContractId);

-------------------------------------------*** REACCRUAL ELIGIBILTY CHECK BASED ON TEMPLATE ***-------------------------------------------------------

---> 1) Fetch All Contract Receivables of Receivable Types imported in Template

SELECT VC.ContractId, ReceivableId = R.Id, PaymentScheduleId = R.PaymentScheduleId, R.DueDate, Amount = R.TotalAmount_Amount, Balance = R.TotalBalance_Amount
INTO #ContractAllReceivables
FROM #ValidContractsToProcess VC
    JOIN ReAccrualRuleReceivableTypes RAR ON VC.ReAccrualTemplateId = RAR.ReAccrualRuleTemplateId AND RAR.IsActive = 1
    JOIN ReceivableCodes RC ON RAR.ReceivableTypeId = RC.ReceivableTypeId
    JOIN Receivables R ON R.EntityType = @ReceivableContractType AND VC.ContractId = R.EntityId AND R.ReceivableCodeId = RC.Id AND R.IsActive = 1
WHERE R.FunderId IS NULL AND (R.IsDummy = 0 OR VC.IsDSL = 1);

CREATE CLUSTERED INDEX IX_ContractAllReceivablesContractId ON #ContractAllReceivables (ContractId);

----> 2) Calculate Base Amount

--> 2.1) Basis = ReceivableAmount
SELECT VC.ContractId, BaseAmount = CASE WHEN (SUM(R.Amount) * (VC.MinimumPercentageOfBasis/100) * VC.ExchangeRate) > VC.MinimumQualifyingAmount
THEN (SUM(R.Amount) * (VC.MinimumPercentageOfBasis/100) * VC.ExchangeRate)
ELSE VC.MinimumQualifyingAmount END
    INTO #ContractBaseAmountDetails
    FROM #ValidContractsToProcess VC
        JOIN #ContractAllReceivables R ON VC.ContractId = R.ContractId AND VC.Basis = 'ReceivableAmount'
    GROUP BY VC.ContractId, VC.ExchangeRate, VC.MinimumPercentageOfBasis, VC.MinimumQualifyingAmount;


--> 2.2) Basis = NetInvestment
INSERT INTO #ContractBaseAmountDetails
SELECT ContractId, BaseAmount = CASE WHEN (NetInvestment * (MinimumPercentageOfBasis/100) * ExchangeRate) > MinimumQualifyingAmount
	THEN (NetInvestment * (MinimumPercentageOfBasis/100) * ExchangeRate)
	ELSE MinimumQualifyingAmount END
FROM #ValidContractsToProcess
WHERE Basis != 'ReceivableAmount';

----> 3) Calculate Outstanding Balance of Receivables having Due Date <= Threshold Date
SELECT VC.ContractId, OutstandingBalance = SUM(R.Balance) * VC.ExchangeRate
INTO #ContractAllOutstandingBalanceInfo
FROM #ValidContractsToProcess VC
    JOIN #ContractAllReceivables R ON VC.ContractId = R.ContractId AND R.DueDate <= VC.ThresholdDate 
GROUP BY VC.ContractId, VC.ExchangeRate;

----> 4) Fetch Contracts eligible for ReAccrual (Outstanding Balance < Base Amount AND ThresholdDate < CommencementDate)
SELECT VC.ContractId
INTO #SelectedContracts
FROM #ValidContractsToProcess VC
    JOIN #ContractBaseAmountDetails CB ON VC.ContractId = CB.ContractId
    JOIN #ContractAllOutstandingBalanceInfo RO ON VC.ContractId = RO.ContractId
WHERE RO.OutstandingBalance = 0 OR RO.OutstandingBalance < CB.BaseAmount 
UNION
SELECT VC.ContractId
FROM #ValidContractsToProcess VC WHERE VC.ThresholdDate < VC.CommencementDate;

---------------------------**********CALCULATIONS**************--------------------------------------------------------------------------------------

---------***REACCRUAL DATE***--------------

--FETCH LAST INCOME GL POSTED POST NON ACCRUAL

WITH CTE_LoanLastIncomeGLPostedInfoPostNonAccrual(ContractId,LastIncomeUpdateDate)
AS
(
SELECT
	C.Id,
	LIS.IncomeDate
FROM Contracts C
JOIN #SelectedContracts CT ON C.Id = CT.ContractId
JOIN LoanFinances LF ON LF.ContractId = C.Id
JOIN LoanIncomeSchedules LIS ON LIS.LoanFinanceId = LF.Id
WHERE LIS.IsAccounting=1 
		AND LIS.IsGLPosted =1 
		AND LIS.IsLessorOwned=1 
		AND LIS.AdjustmentEntry = 0
		AND LIS.IncomeDate > C.NonAccrualDate
)
INSERT INTO #ContractLastIncomeGLPostedInfoPostNonAccrual
SELECT
	C.Id,
	MAX(CLM.LastIncomeUpdateDate)
FROM Contracts C
JOIN #SelectedContracts CT ON C.Id = CT.ContractId
LEFT JOIN CTE_LoanLastIncomeGLPostedInfoPostNonAccrual CLM ON CLM.ContractId = C.Id
WHERE C.ContractType = @LoanContractType
GROUP BY C.Id;

--FETCH LATEST AMENDMENT DATE POST NON-ACCRUAL

WITH CTE_LoanLastModifiedDatePostNonAccrual(ContractId,LastModifiedDate)
AS
(
SELECT
	C.Id,
	CASE WHEN LA.AmendmentDate <= CBI.CommencementDate THEN CBI.CommencementDate
		 ELSE LA.AmendmentDate
	END
FROM LoanAmendments LA
JOIN LoanFinances LF ON LA.LoanFinanceId = LF.Id
JOIN Contracts C ON LF.ContractId = C.Id
JOIN #SelectedContracts CT ON C.Id = CT.ContractId
JOIN #ContractBasicInfo CBI ON C.Id = CBI.ContractId
WHERE LA.QuoteStatus = @AmendmentAppprovedStatus
		AND LA.AmendmentDate > CBI.NonAccrualDate
		AND LA.AmendmentType NOT IN (@ReceiptAmendmentType,@GLTransferAmendmentType)
)

INSERT INTO #ContractLastModificationDateInfoPostNonAccrual
SELECT
	C.Id,
	MAX(CLM.LastModifiedDate)
FROM Contracts C
JOIN #SelectedContracts CT ON C.Id = CT.ContractId
LEFT JOIN CTE_LoanLastModifiedDatePostNonAccrual CLM ON CLM.ContractId = C.Id
GROUP BY C.Id;

----------*** LAST PAYMENT START DATE ***-----------------

INSERT INTO #LastPaymentStartDate
SELECT 
	LF.ContractId,
	MAX(LPS.StartDate)
FROM #SelectedContracts SC
JOIN LoanFinances LF ON SC.ContractId = LF.ContractId
JOIN LoanPaymentSchedules LPS ON LF.Id = LPS.LoanFinanceId
WHERE LPS.IsActive = 1
GROUP BY LF.ContractId

--SET REACCRUAL DATE AS NON-ACCRUAL DATE 

INSERT INTO #ReAccrualDateInfo
SELECT 
	CB.ContractId,
	CB.NonAccrualDate
FROM #ContractBasicInfo CB
JOIN #ContractLastIncomeGLPostedInfoPostNonAccrual GLI ON CB.ContractId = GLI.ContractId
JOIN #ContractLastModificationDateInfoPostNonAccrual CLM ON CB.ContractId = CLM.ContractId
JOIN #LastPaymentStartDate LPSD ON LPSD.ContractId = CB.ContractId
WHERE (GLI.IncomeDate >= LPSD.StartDate OR GLI.IncomeDate IS NULL)
		AND CLM.LastModificationDate IS NULL;

--SET REACCRUAL DATE AS IMMEDIATE PAYMENT PERIOD STARTDATE OF MAX(GLPOSTEDDATE,AMENDMENTDATE)

WITH CTE_MaxModifiedDate(ContractId,LastModifiedDate)
AS
(
SELECT 
	CB.ContractId,
	CASE WHEN (GLI.IncomeDate IS NULL AND CLM.LastModificationDate IS NOT NULL) THEN CLM.LastModificationDate
		 WHEN (GLI.IncomeDate IS NOT NULL AND CLM.LastModificationDate IS NULL) THEN GLI.IncomeDate
		 WHEN (GLI.IncomeDate IS NOT NULL AND CLM.LastModificationDate IS NOT NULL)
			THEN (CASE WHEN (GLI.IncomeDate > CLM.LastModificationDate)
							THEN GLI.IncomeDate
						    ELSE CLM.LastModificationDate
				  END)
		 END
FROM #ContractBasicInfo CB
JOIN #LastPaymentStartDate LPSD ON LPSD.ContractId = CB.ContractId
LEFT JOIN #ContractLastIncomeGLPostedInfoPostNonAccrual GLI ON CB.ContractId = GLI.ContractId
LEFT JOIN #ContractLastModificationDateInfoPostNonAccrual CLM ON CB.ContractId = CLM.ContractId
WHERE (1 = (CASE 
				WHEN GLI.IncomeDate IS NOT NULL THEN ( CASE WHEN GLI.IncomeDate >= LPSD.StartDate THEN 0 ELSE 1  END) 
				ELSE 1 
			END))
		 AND (GLI.IncomeDate IS NOT NULL OR CLM.LastModificationDate IS NOT NULL)
)

INSERT INTO #ReAccrualDateInfo
SELECT
	CMD.ContractId,
	MIN(LPS.StartDate)
FROM CTE_MaxModifiedDate CMD
JOIN LoanFinances LF ON CMD.ContractId = LF.ContractId AND LF.IsCurrent=1
JOIN LoanPaymentSchedules LPS ON  LPS.LoanFinanceId = LF.Id AND LPS.IsActive=1 
WHERE LPS.StartDate >= CMD.LastModifiedDate
GROUP BY CMD.ContractId;

--SET REACCRUAL DATE AS IMMEDIATE PAYMENT PERIOD STARTDATE AMENDMENT DATE  

WITH CTE_GLPostedTillMaturityAndAmendment(ContractId,LastModifiedDate)
AS
(
SELECT 
	CB.ContractId,
	CLM.LastModificationDate
FROM #ContractBasicInfo CB
LEFT JOIN #ContractLastIncomeGLPostedInfoPostNonAccrual GLI ON CB.ContractId = GLI.ContractId
LEFT JOIN #ContractLastModificationDateInfoPostNonAccrual CLM ON CB.ContractId = CLM.ContractId
WHERE (1 = (CASE 
				WHEN GLI.IncomeDate IS NOT NULL THEN ( CASE WHEN  GLI.IncomeDate = CB.MaturityDate  THEN 1 ELSE 0 END) 
				ELSE 1 
			END))  
		 AND CLM.LastModificationDate IS NOT NULL
)

INSERT INTO #ReAccrualDateInfo
SELECT
	CMD.ContractId,
	MIN(LPS.StartDate)
FROM CTE_GLPostedTillMaturityAndAmendment CMD
JOIN LoanFinances LF ON CMD.ContractId = LF.ContractId AND LF.IsCurrent=1
JOIN LoanPaymentSchedules LPS ON  LPS.LoanFinanceId = LF.Id AND LPS.IsActive=1 
WHERE LPS.StartDate >= CMD.LastModifiedDate
GROUP BY CMD.ContractId;

UPDATE #ContractBasicInfo SET ReAccrualDate = RD.ReAccrualDate
FROM #ReAccrualDateInfo RD
JOIN #ContractBasicInfo CB ON RD.ContractId = CB.ContractId


--------***LAST INCOME UPDATE DATE***-----------------

INSERT INTO #ContractLastIncomeGLPostedInfo
SELECT
C.Id,
MAX(LIS.IncomeDate)
FROM Contracts C
JOIN #SelectedContracts CT ON C.Id = CT.ContractId
JOIN LoanFinances LF ON LF.ContractId = C.Id
JOIN LoanIncomeSchedules LIS ON LIS.LoanFinanceId = LF.Id
WHERE LIS.IsAccounting=1 
		AND LIS.IsGLPosted =1 
		AND LIS.IsLessorOwned=1 
		AND LIS.AdjustmentEntry = 0
GROUP BY C.Id;

----------------*** LAST MODIFICATION DATE***-----------------

WITH CTE_LoanLastModifiedDate(ContractId,LastModifiedDate)
AS
(
SELECT C.Id,
CASE WHEN LA.AmendmentDate <= CB.CommencementDate THEN CB.CommencementDate
WHEN LA.AmendmentType in (@RebookAmendmentType,@SyndicationAmendmentType,@NonAccrualAmendmentType,@ReAccrualAmendmentType,@AssumptionAmendmentType)THEN LA.AmendmentDate
WHEN LA.AmendmentType in (@RestructureAmendmentType,@PayDownAmendmentType) THEN DATEADD(DAY,1,LA.AmendmentDate)
ELSE LA.AmendmentDate END
FROM LoanAmendments LA
JOIN LoanFinances LF ON LA.LoanFinanceId = LF.Id
JOIN Contracts C ON LF.ContractId = C.Id
JOIN #SelectedContracts CT ON C.Id = CT.ContractId
JOIN #ContractBasicInfo CB ON C.Id = CB.ContractId
WHERE LA.QuoteStatus = @AmendmentAppprovedStatus
AND LA.AmendmentType NOT IN (@ReceiptAmendmentType,@GLTransferAmendmentType)
)
INSERT INTO #ContractLastModificationDateInfo
SELECT
C.Id,
MAX(CLM.LastModifiedDate)
FROM Contracts C
JOIN #SelectedContracts CT ON C.Id = CT.ContractId
LEFT JOIN CTE_LoanLastModifiedDate CLM ON CLM.ContractId = C.Id
WHERE C.ContractType = @LoanContractType
GROUP BY C.Id

-----------*** OUTSTANDING RECEIVABLE BALANCE***--------------

INSERT INTO #ContractOutstandingARInfo
SELECT 
	R.EntityId,
	SUM(R.TotalBalance_Amount)
FROM #ContractBasicInfo CB
JOIN Receivables R ON CB.ContractId = R.EntityId AND R.EntityType = @ReceivableContractType AND R.IsActive = 1
JOIN ReceivableCodes RC ON R.ReceivableCodeId = RC.Id
JOIN ReceivableTypes RT ON RC.ReceivableTypeId = RT.Id
JOIN LoanPaymentSchedules LPS ON R.PaymentScheduleId = LPS.Id AND LPS.StartDate < CB.ReAccrualDate
WHERE RT.Name IN ('LoanPrincipal','LoanInterest')
		AND R.IsDummy = 0
		AND R.FunderId IS NULL
GROUP BY R.EntityId;

---------***LAST RECEIPT DATE***--------------

INSERT INTO #ContractLastReceiptDateInfo
SELECT
	CT.ContractId,
	MAX(RC.ReceivedDate)
FROM #SelectedContracts CT
JOIN Receivables R ON CT.ContractId = R.EntityId
JOIN ReceivableDetails RD ON R.Id = RD.ReceivableId
JOIN ReceiptApplicationReceivableDetails RAD ON RD.Id = RAD.ReceivableDetailId
JOIN ReceiptApplications RA ON RAD.ReceiptApplicationId = RA.Id
JOIN Receipts RC ON RA.ReceiptId = RC.Id
WHERE RD.IsActive = 1
	AND RAD.IsActive = 1
	AND (RC.[Status] = @ReceiptStatusPosted OR RC.[Status] = @ReceiptStatusReadyForPosting)
GROUP BY CT.ContractId;

----------------***BILLING SUPPRESSED***-------------------

--- FETCH INVOICE PREFERENCE DETAILS BASED ON VALID RECEIVABLE TYPES 

WITH CTE_InvoicePreference(ContractId,InvoicePreference)
AS
(
SELECT 
	CT.ContractId,
	CBP.InvoicePreference
FROM #SelectedContracts CT
JOIN #ContractBasicInfo CBI ON CT.ContractId = CBI.ContractId
JOIN ContractBillings CB ON CT.ContractId = CB.Id AND CB.IsActive = 1
JOIN ContractBillingPreferences CBP ON CB.Id = CBP.ContractBillingId AND CBP.IsActive = 1
JOIN ReceivableTypes RT ON CBP.ReceivableTypeId = RT.Id AND RT.IsActive = 1
WHERE RT.Name IN ('LoanPrincipal','LoanInterest')
GROUP BY CT.ContractId, CBP.InvoicePreference
)

-----SET BILLING SUPPRESSED TO TRUE ONLY IF THE CONTRACT HAS ONLY SuppressGeneration AS InvoicePreference

-- FETCH COUNT OF INVOICE PREFERENCE FOR EACH CONTRACT
SELECT 
	CTE_IP.ContractId,
	COUNT(CTE_IP.InvoicePreference) AS Count_InvoicePreference
INTO #InvoicePreferenceCount
FROM CTE_InvoicePreference CTE_IP 
GROUP BY CTE_IP.ContractId


---CHECK IF INVOICE PREFERENCE IS SUPPRESS GENERATION IF COUNT OF INVOICE PREFERENCE IS 1

INSERT INTO #BillingSuppressedInfo
SELECT
	DISTINCT CBI.ContractId,
	CASE WHEN CBP.InvoicePreference = 'SuppressGeneration' THEN 1 ELSE 0 END
FROM #ContractBasicInfo CBI
JOIN #InvoicePreferenceCount IPC ON CBI.ContractId = IPC.ContractId
JOIN ContractBillingPreferences CBP ON IPC.ContractId = CBP.ContractBillingId
JOIN ReceivableTypes RT ON CBP.ReceivableTypeId = RT.Id AND RT.IsActive = 1
WHERE IPC.Count_InvoicePreference = 1
		AND RT.Name IN ('LoanPrincipal','LoanInterest')

---- SET BILLING SUPPRESSED AS 0 FOR THE CONTRACTS HAVING COUNT OF INVOICE PREFERNCE MORE THAN 1

INSERT INTO #BillingSuppressedInfo
SELECT
	SC.ContractId,
	0
FROM #SelectedContracts SC
JOIN #InvoicePreferenceCount IPC ON SC.ContractId = IPC.ContractId
WHERE IPC.Count_InvoicePreference > 1


---****Suspended Income ****----

INSERT INTO #SuspendedIncomeInfo
SELECT 
	CB.ContractId,
	SUM(LIS.InterestAccrued_Amount)
FROM LoanIncomeSchedules LIS 
JOIN LoanFinances LF ON LIS.LoanFinanceId = LF.Id
JOIN #ContractBasicInfo CB ON LF.ContractId = CB.ContractId
WHERE LIS.IncomeDate >= CB.NonAccrualDate
		AND LIS.IncomeDate < CB.ReAccrualDate
		AND LIS.IsSchedule = 1
		AND LIS.IsLessorOwned = 1 
GROUP BY CB.ContractId

----****NBV****------------

-----FETCH INCOME SCHEDULES POST RE-ACCRUAL DATE HAVING RANK OVER INCOMEDATE
SELECT 
	CB.ContractId, 
	IncomeScheduleId = LIS.Id, 
	RowNumber = ROW_NUMBER() OVER (PARTITION BY CB.ContractId ORDER BY LIS.IncomeDate, LIS.Id)
INTO #LoanMinIncomeScheduleInfo
FROM #ContractBasicInfo CB
JOIN LoanFinances LF ON CB.ContractId = LF.ContractId
JOIN LoanIncomeSchedules LIS ON LF.Id = LIS.LoanFinanceId AND LIS.IncomeDate >= CB.ReAccrualDate
WHERE CB.IsLease = 0 
		AND CB.LoanFinanceId IS NOT NULL
		AND LIS.IsSchedule = 1
		AND LIS.IsLessorOwned = 1;

-----UPDATE NBV ------------------

INSERT INTO #ContractNBVInfo
SELECT
	 LIMI.ContractId, 
	 LI.BeginNetBookValue_Amount + LI.PrincipalAdded_Amount
FROM #LoanMinIncomeScheduleInfo LIMI
JOIN LoanIncomeSchedules LI ON LIMI.IncomeScheduleId = LI.Id
WHERE LIMI.RowNumber = 1;

---------------------------********************** NBV WITH BLENDED COMPUTATION***************************---------------------------

--------------------**** (A)BLENDED INCOME BALANCE COMPUTATIO ****-----------------------

------FETCH BLENDED ITEM INFO-------------

SELECT 
	CB.ContractId, 
	CB.CommencementDate, 
	CB.MaturityDate, 
	CB.ReAccrualDate, 
	BI.Id, 
	BI.[Type], 
	BI.BookRecognitionMode, 
	Amount = BI.Amount_Amount
INTO #BlendedItems
FROM #ContractBasicInfo CB
JOIN LoanBlendedItems LBI ON CB.IsLease = 0 AND CB.LoanFinanceId IS NOT NULL AND CB.LoanFinanceId  = LBI.LoanFinanceId
JOIN BlendedItems BI ON LBI.BlendedItemId = BI.Id AND BI.IsActive = 1AND BI.IsFAS91 = 1
WHERE CB.ReAccrualDate < CB.MaturityDate;

----FETCH BLENDED EXPENSE BALANCE WHEN REACCRUAL AS OF COMMENCEMENT-----------

SELECT 
	ContractId, 
	Amount
INTO #BlendedItemBalanceInfo
FROM #BlendedItems
WHERE ReAccrualDate = CommencementDate 
		AND [Type] != 'Income';

----FETCH BLENDED INCOME BALANCE WHEN REACCRUAL AS OF COMMENCEMENT-----------

INSERT INTO #BlendedItemBalanceInfo
SELECT 
	ContractId, 
	0.00 - Amount 
FROM #BlendedItems
WHERE ReAccrualDate = CommencementDate 
		AND [Type] = 'Income';

----FETCH BLENDED INCOMES PRIOR TO RE-ACCRUAL DATE WHEN REACCRUAL IS NOT AS OF COMMENCEMENT-------

SELECT 
	BI.Id, 
	CB.ContractId,
	BI.BookRecognitionMode,
	BI.Type, 
	Amount = BI.Amount_Amount, 
	IncomeBalance = SUM(BIS.Income_Amount)
INTO #BlendedIncomeBalances
FROM #SelectedContracts CT
JOIN #ContractBasicInfo CB ON CT.ContractId = CB.ContractId
JOIN LoanFinances LF ON CT.ContractId = LF.ContractId 
JOIN BlendedIncomeSchedules BIS ON LF.Id = BIS.LoanFinanceId AND BIS.IsSchedule = 1 AND BIS.IncomeDate <= DATEADD(DAY, -1, CB.ReAccrualDate)
JOIN BlendedItems BI ON BIS.BlendedItemId = BI.Id AND BI.IsActive = 1 AND BI.IsFAS91 = 1
WHERE CB.ReAccrualDate != CB.CommencementDate
		AND BI.BookRecognitionMode NOT IN ('RecognizeImmediately','Capitalize')
GROUP BY BI.Id, CB.ContractId, BI.BookRecognitionMode, BI.Type, BI.Amount_Amount;

-----CALCULATE BLENDED EXPENSE BALANCE FOR AMORTIZE BLENDED ITEM----------

INSERT INTO #BlendedItemBalanceInfo
SELECT 
	ContractId, 
	(Amount - IncomeBalance)
FROM #BlendedIncomeBalances BIS
WHERE [Type] != 'Income' 
		AND BookRecognitionMode = 'Amortize'

-----CALCULATE BLENDED EXPENSE BALANCE FOR ACCRETE BLENDED ITEM----------

INSERT INTO #BlendedItemBalanceInfo
SELECT 
	ContractId, 
	(IncomeBalance - Amount)
FROM #BlendedIncomeBalances
WHERE [Type] != 'Income' 
		AND BookRecognitionMode != 'Amortize'

-----CALCULATE BLENDED INCOME BALANCE FOR AMORTIZE BLENDED ITEM----------

INSERT INTO #BlendedItemBalanceInfo
SELECT 
	ContractId, 
	0.00 - (Amount - IncomeBalance)
FROM #BlendedIncomeBalances
WHERE [Type] = 'Income' 
		AND BookRecognitionMode = 'Amortize'

-----CALCULATE BLENDED INCOME BALANCE FOR ACCRETE BLENDED ITEM----------

INSERT INTO #BlendedItemBalanceInfo
SELECT 
	ContractId, 
	0.00 - (IncomeBalance - Amount)
FROM #BlendedIncomeBalances
WHERE [Type] = 'Income' 
		AND BookRecognitionMode != 'Amortize'

-----CONSOLIDATE BLENDED BALANCE BASED ON CONTRACT----------

SELECT 
	ContractId, 
	Amount = SUM(Amount)
INTO #ContractBlendedItemBalanceInfo
FROM #BlendedItemBalanceInfo
GROUP BY ContractId;

--------------***(B) OUTSTANDING RECEIVABLE BALANCE COMPUTATION***-------------

-----FETCH RECEIVABLES INFO BASED ON VALID RECEIVABLE TYPES-----------

SELECT 
	CB.ContractId, 
	CB.ReAccrualDate, 
	ReceivableId = R.Id, 
	R.PaymentScheduleId, 
	EffectiveBalance = R.TotalEffectiveBalance_Amount
INTO #ContractReceivablesInfo
FROM #ContractBasicInfo CB
JOIN Receivables R ON R.EntityType = 'CT' AND CB.ContractId = R.EntityId AND R.IsActive = 1
JOIN ReceivableCodes RC ON R.ReceivableCodeId = RC.Id
JOIN ReceivableTypes RT ON RC.ReceivableTypeId = RT.Id
WHERE R.IsDummy = 0
		AND R.FunderId IS NULL
		AND CB.IsLease = 0
		AND CB.ReAccrualDate < CB.MaturityDate
	    AND RT.Name IN ('LoanPrincipal','LoanInterest')

----- CALCULATE RECEIVABLE BALANCE PRIOR TO REACCRUAL DATE BASED ON CONTRACT---------

SELECT 
	CR.ContractId, 
	Amount = SUM(CR.EffectiveBalance)
INTO #OutstandingReceivablesInfo
FROM #ContractReceivablesInfo CR
JOIN LoanPaymentSchedules LP ON CR.PaymentScheduleId = LP.Id
WHERE (LP.StartDate < CR.ReAccrualDate OR LP.StartDate IS NULL)
		AND LP.PaymentType IN ('FixedTerm','Downpayment')
GROUP BY CR.ContractId;

----------------***(C) FUTURE CASH POSTING AMOUNT COMPUTATION***-------------

SELECT 
	CR.ContractId, 
	Amount = SUM(RARD.AmountApplied_Amount)
INTO #FutureCashPostingInfo 
FROM #ContractReceivablesInfo CR
JOIN LoanPaymentSchedules LP ON CR.PaymentScheduleId = LP.Id
JOIN ReceivableDetails RD ON CR.ReceivableId = RD.ReceivableId AND RD.IsActive = 1
JOIN ReceiptApplicationReceivableDetails RARD ON RD.Id = RARD.ReceivableDetailId AND RARD.IsActive = 1
JOIN ReceiptApplications RA ON RARD.ReceiptApplicationId = RA.Id
JOIN Receipts R ON RA.ReceiptId = R.Id
WHERE LP.StartDate >= CR.ReAccrualDate
		AND R.[Status] NOT IN ('Inactive','Reversed')
		AND R.ReceiptClassification NOT IN ('NonCash','NonAccrualNonDSLNonCash')
GROUP BY CR.ContractId

-----*** NBV WITH BLENDED = NBV + A + B - C****--------------

INSERT INTO #ContractNBVWithBlendedInfo
SELECT 
	CB.ContractId, 
	NBVWithBlended = ISNULL(CN.NBV, 0.00) + ISNULL(CBIB.Amount, 0.00) + ISNULL(ORI.Amount, 0.00) - ISNULL(FCP.Amount, 0.00)
FROM #ContractBasicInfo CB
LEFT JOIN #ContractNBVInfo CN ON CB.ContractId = CN.ContractId
LEFT JOIN #ContractBlendedItemBalanceInfo CBIB ON CB.ContractId = CB.ContractId
LEFT JOIN #OutstandingReceivablesInfo ORI ON CB.ContractId = ORI.ContractId
LEFT JOIN #FutureCashPostingInfo FCP ON CB.ContractId = FCP.ContractId;

---------------------------****************OUTPUT*******************---------------------------------------------------------------------------------

SELECT
    ContractId = CB.ContractId,
	SequenceNumber = CB.SequenceNumber,
	CustomerId = CB.CustomerId,
	CustomerNumber = CB.CustomerNumber,
	CustomerName = CB.CustomerName,
	LegalEntityId = CB.LegalEntityId,
	LegalEntityName = CB.LegalEntityName,
	LoanFinanceId = CB.LoanFinanceId,
	CommencementDate = CB.CommencementDate,
	MaturityDate = CB.MaturityDate,
	ContractCurrencyCode = CB.ContractCurrencyCode,
	IsLease = CB.IsLease,
	LeaseContractType= CB.LeaseContractType,
	HoldingStatus = CB.HoldingStatus,
	NonAccrualDate = CB.NonAccrualDate,
	ReAccrualDate = CB.ReAccrualDate,
	LastPaymentStartDate = LPS.StartDate,
	LastIncomeUpdateDate = CLI.IncomeDate,
	LastModificationDate = CLM.LastModificationDate,
	LastReceiptDate = CLR.LastReceiptDate,
	OutstandingAR = COAR.OutstandingAR,
	BillingSuppressed = BS.BillingSuppressed,
	ResumeBilling = BS.BillingSuppressed,
	SuspendedIncome = SI.SuspendedIncome,
	NBV = CN.NBV,
	NBVWithBlended = CNB.NBVWithBlended
FROM
    #ContractBasicInfo CB
	JOIN #SelectedContracts SC ON SC.ContractId = CB.ContractId
	JOIN #LastPaymentStartDate LPS ON SC.ContractId = LPS.ContractId
	LEFT JOIN #ContractLastIncomeGLPostedInfo CLI ON CB.ContractId = CLI.ContractId
	LEFT JOIN #ContractLastModificationDateInfo CLM ON CB.ContractId = CLM.ContractId
	LEFT JOIN #ContractLastReceiptDateInfo CLR ON CB.ContractId = CLR.ContractId
	LEFT JOIN #ContractOutstandingARInfo COAR ON CB.ContractId = COAR.ContractId
	LEFT JOIN #BillingSuppressedInfo BS ON CB.ContractId = BS.ContractId
	LEFT JOIN #SuspendedIncomeInfo SI ON CB.ContractId = SI.ContractId
	LEFT JOIN #ContractNBVInfo CN ON SC.ContractId = CN.ContractId
	LEFT JOIN #ContractNBVWithBlendedInfo CNB ON SC.ContractId = CNB.ContractId;

--------------------***DROP TABLE***-------------------------
IF OBJECT_ID('#ContractBasicInfo') IS NOT NULL DROP TABLE #ContractBasicInfo
IF OBJECT_ID('#ExchangeRateInfo') IS NOT NULL DROP TABLE #ExchangeRateInfo
IF OBJECT_ID('#ForeignCurrencies') IS NOT NULL DROP TABLE #ForeignCurrencies
IF OBJECT_ID('#ContractLastIncomeGLPostedInfo') IS NOT NULL DROP TABLE #ContractLastIncomeGLPostedInfo
IF OBJECT_ID('#ContractLastModificationDateInfo') IS NOT NULL DROP TABLE #ContractLastModificationDateInfo
IF OBJECT_ID('#ContractNBVInfo') IS NOT NULL DROP TABLE #ContractNBVInfo
IF OBJECT_ID('#ContractNBVWithBlendedInfo') IS NOT NULL DROP TABLE #ContractNBVWithBlendedInfo
IF OBJECT_ID('#ContractOutstandingARInfo') IS NOT NULL DROP TABLE #ContractOutstandingARInfo
IF OBJECT_ID('#ContractLastReceiptDateInfo') IS NOT NULL DROP TABLE #ContractLastReceiptDateInfo
IF OBJECT_ID('#LegalEntitiesWithGLFinancialOpenPeriods') IS NOT NULL DROP TABLE #LegalEntitiesWithGLFinancialOpenPeriods
IF OBJECT_ID('#ValidContractsToProcess') IS NOT NULL DROP TABLE #ValidContractsToProcess
IF OBJECT_ID('#ContractAllReceivables') IS NOT NULL DROP TABLE #ContractAllReceivables
IF OBJECT_ID('#ContractBaseAmountDetails') IS NOT NULL DROP TABLE #ContractBaseAmountDetails
IF OBJECT_ID('#ContractAllOutstandingBalanceInfo') IS NOT NULL DROP TABLE #ContractAllOutstandingBalanceInfo
IF OBJECT_ID('#SelectedContracts') IS NOT NULL DROP TABLE #SelectedContracts
IF OBJECT_ID('#BillingSuppressedInfo') IS NOT NULL DROP TABLE #BillingSuppressedInfo
IF OBJECT_ID('#ContractLastIncomeGLPostedInfoPostNonAccrual') IS NOT NULL DROP TABLE #ContractLastIncomeGLPostedInfoPostNonAccrual
IF OBJECT_ID('#ContractLastModificationDateInfoPostNonAccrual') IS NOT NULL DROP TABLE #ContractLastModificationDateInfoPostNonAccrual
IF OBJECT_ID('#ReAccrualDateInfo') IS NOT NULL DROP TABLE #ReAccrualDateInfo
IF OBJECT_ID('#SuspendedIncomeInfo') IS NOT NULL DROP TABLE #SuspendedIncomeInfo
IF OBJECT_ID('#LastPaymentStartDate') IS NOT NULL DROP TABLE #LastPaymentStartDate
IF OBJECT_ID('#BlendedIncomeBalances') IS NOT NULL DROP TABLE #BlendedIncomeBalances
IF OBJECT_ID('#BlendedItemBalanceInfo') IS NOT NULL DROP TABLE #BlendedItemBalanceInfo
IF OBJECT_ID('#BlendedItems') IS NOT NULL DROP TABLE #BlendedItems
IF OBJECT_ID('#ContractBlendedItemBalanceInfo') IS NOT NULL DROP TABLE #ContractBlendedItemBalanceInfo
IF OBJECT_ID('#ContractReceivablesInfo') IS NOT NULL DROP TABLE #ContractReceivablesInfo
IF OBJECT_ID('#FutureCashPostingInfo') IS NOT NULL DROP TABLE #FutureCashPostingInfo
IF OBJECT_ID('#OutstandingReceivablesInfo') IS NOT NULL DROP TABLE #OutstandingReceivablesInfo
IF OBJECT_ID('#LoanMinIncomeScheduleInfo') IS NOT NULL DROP TABLE #LoanMinIncomeScheduleInfo
IF OBJECT_ID('#InvoicePreferenceCount') IS NOT NULL DROP TABLE #InvoicePreferenceCount

SET
NOCOUNT OFF;
END

GO
