SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[GetLeaseContractsForReAccrual]
(
	@LegalEntities ReAccrual_LeaseLegalEntities READONLY,
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

DECLARE @LeaseContractType NVARCHAR(20) = 'Lease';

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
	LeaseFinanceId BIGINT NULL,
	LeaseFinanceDetailId BIGINT NULL,
	CommencementDate DATE,
	MaturityDate DATE,
	CurrencyId BIGINT,
	ContractCurrencyCode NVARCHAR(5),
	IsLease BIT,
	IsDSL BIT,
	LeaseContractType NVARCHAR(100),
	NetInvestment DECIMAL(16, 2),
	HoldingStatus NVARCHAR(30),
	ReAccrualTemplateId BIGINT NULL,
	Basis NVARCHAR(40) NULL,
	MinimumPercentageOfBasis DECIMAL (6, 2) NULL,
	MinimumQualifyingAmount DECIMAL(16, 2),
	ThresholdDate DATE NULL,
	DaysPastDueLimit INT NULL,
	NonAccrualDate DATE,
	ReAccrualDate DATE,
	DoubtFulCollectability BIT
)

CREATE TABLE #ContractLastIncomeGLPostedInfo
(
    ContractId BIGINT,
    IncomeDate DATE
)

CREATE TABLE #ContractLastIncomeGLPostedInfoPostNonAccrual
(
ContractId BIGINT,
IncomeDate DATE
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

CREATE TABLE #BillingSuppressedInfo
(
    ContractId BIGINT,
    BillingSuppressed BIT
);

CREATE TABLE #OperatingLease
(
    ContractId BIGINT,
	DoubtFulCollectability BIT,
	NonAccrualDate DATE,
	ReAccrualDate DATE

);

CREATE TABLE #CapitalLease
(
    ContractId BIGINT,
	ReAccrualDate DATE
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

CREATE TABLE #OTPIncome
(
	ContractId BIGINT,
	OTPIncome DECIMAL(16,2)
);

CREATE TABLE #AssetIncomeInfoForSuspendedIncomeCalculation
(
	ContractId BIGINT,
	IncomeType NVARCHAR(15),
	Income DECIMAL(16,2),
	RentalIncome DECIMAL(16,2),
	DSPIncome DECIMAL(16,2),
	IsLeaseAsset BIT,
	LeaseRentalIncome DECIMAL(16,2),
	FinanceIncome DECIMAL(16,2),
	IsTerminated BIT
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
    LeaseFinanceId = LF.Id,
    LeaseFinanceDetailId = LFD.Id,
    CommencementDate = LFD.CommencementDate,
    MaturityDate = LFD.MaturityDate,
    CurrencyId = C.CurrencyId,
    ContractCurrencyCode = CC.ISO,
    IsLease = 1,
	IsDSL = 0,
    LeaseContractType = LFD.LeaseContractType,
    NetInvestment = LFD.NetInvestment_Amount,
    HoldingStatus = LF.HoldingStatus,
    ReAccrualTemplateId = LE.ReAccrualRuleTemplateId,
    Basis = RT.Basis,
    MinimumPercentageOfBasis = RT.MinimumPercentageofBasis,
    MinimumQualifyingAmount = RT.MinimumQualifyingAmount_Amount,
    ThresholdDate = DATEADD(DAY, ISNULL(0 - RT.DaysPastDue, 0), @EffectiveDateForThresholdDate),
    DaysPastDueLimit = RT.DaysPastDue,
	NonAccrualDate = C.NonAccrualDate,
	ReAccrualDate = NULL,
	DoubtfulCollectability = C.DoubtfulCollectability
FROM
    Contracts C
    JOIN LeaseFinances LF ON C.Id = LF.ContractId AND LF.IsCurrent = 1
    JOIN LeaseFinanceDetails LFD ON LF.Id = LFD.Id
    JOIN @LegalEntities LES ON LF.LegalEntityId = LES.Id
    JOIN LegalEntities LE ON LES.Id = LE.Id
    JOIN Customers CU ON LF.CustomerId = CU.Id
    JOIN Currencies CUR ON C.CurrencyId = CUR.Id
    JOIN CurrencyCodes CC ON CUR.CurrencyCodeId = CC.Id
    JOIN Parties P ON CU.Id = P.Id
    LEFT JOIN ReAccrualRuleTemplates RT ON LE.ReAccrualRuleTemplateId = RT.Id
  
WHERE
	C.ContractType = @LeaseContractType
    AND C.IsNonAccrualExempt = 0
    AND CU.IsNonAccrualExempt = 0
    AND C.SyndicationType NOT IN ('FullSale', 'ParticipatedSales')
    AND C.IsNonAccrual = 1
    AND LF.BookingStatus != 'FullyPaidOff'
    AND LF.BookingStatus != 'Terminated'
    AND C.ChargeOffStatus = '_'
    AND (@EntityType = '_' OR @FilterOption = 'All'
		OR (@EntityType = 'Customer' AND CU.Id = @CustomerId)
		OR (@EntityType = 'Lease' AND C.Id = @ContractId)
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

--->Get Latest Exchange Rate
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
FROM
    #ForeignCurrencies FC
    LEFT JOIN #ExchangeRateInfo ER ON FC.CurrencyId = ER.CurrencyId
WHERE ER.CurrencyId IS NULL;

--->Inserting Exchange Rate Info for Domestic Currency as 1 for Calculation Purposes
INSERT INTO #ExchangeRateInfo
VALUES (@DomesticCurrencyId, 1.0);

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
	CB.ReAccrualTemplateId IS NOT NULL ;

CREATE CLUSTERED INDEX IX_ValidContractsContractId ON #ValidContractsToProcess (ContractId);

-------------------------------------------*** REACCRUAL ELIGIBILTY CHECK BASED ON TEMPLATE ***-------------------------------------------------------

---> 1) Fetch All Contract Receivables of Receivable Types imported in Template
SELECT 
	VC.ContractId, 
	ReceivableId = R.Id,
	PaymentScheduleId = R.PaymentScheduleId, 
	R.DueDate, 
	Amount = R.TotalAmount_Amount, 
	Balance = R.TotalBalance_Amount
INTO #ContractAllReceivables
FROM #ValidContractsToProcess VC
    JOIN ReAccrualRuleReceivableTypes RAR ON VC.ReAccrualTemplateId = RAR.ReAccrualRuleTemplateId AND RAR.IsActive = 1
    JOIN ReceivableCodes RC ON RAR.ReceivableTypeId = RC.ReceivableTypeId
    JOIN Receivables R ON R.EntityType = @ReceivableContractType AND VC.ContractId = R.EntityId AND R.ReceivableCodeId = RC.Id AND R.IsActive = 1
WHERE 
	R.FunderId IS NULL 
	AND (R.IsDummy = 0 OR VC.IsDSL = 1);

CREATE CLUSTERED INDEX IX_ContractAllReceivablesContractId ON #ContractAllReceivables (ContractId);

----> 2) Calculate Base Amount

--> 2.1) Basis = ReceivableAmount
SELECT 
VC.ContractId, 
BaseAmount = CASE WHEN (SUM(R.Amount) * (VC.MinimumPercentageOfBasis/100) * VC.ExchangeRate) > VC.MinimumQualifyingAmount
				THEN (SUM(R.Amount) * (VC.MinimumPercentageOfBasis/100) * VC.ExchangeRate)
				ELSE VC.MinimumQualifyingAmount END
INTO #ContractBaseAmountDetails
FROM #ValidContractsToProcess VC
    JOIN #ContractAllReceivables R ON VC.ContractId = R.ContractId AND VC.Basis = 'ReceivableAmount'
GROUP BY VC.ContractId, VC.ExchangeRate, VC.MinimumPercentageOfBasis, VC.MinimumQualifyingAmount;

--> 2.2) Basis = NetInvestment
INSERT INTO #ContractBaseAmountDetails
SELECT 
	ContractId, 
	BaseAmount = CASE WHEN (NetInvestment * (MinimumPercentageOfBasis/100) * ExchangeRate) > MinimumQualifyingAmount
						THEN (NetInvestment * (MinimumPercentageOfBasis/100) * ExchangeRate)
						ELSE MinimumQualifyingAmount END
FROM #ValidContractsToProcess
WHERE Basis != 'ReceivableAmount';

----> 3) Calculate Outstanding Balance of Receivables having Due Date <= Threshold Date
SELECT 
	VC.ContractId, 
	OutstandingBalance = SUM(R.Balance) * VC.ExchangeRate
INTO #ContractAllOutstandingBalanceInfo
FROM #ValidContractsToProcess VC
    JOIN #ContractAllReceivables R ON VC.ContractId = R.ContractId AND R.DueDate <= VC.ThresholdDate
GROUP BY VC.ContractId, VC.ExchangeRate;

----> 4) Fetch Contracts eligible for ReAccrual (Outstanding Balance < Base Amount AND  ThresholdDate < CommencementDate )
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

WITH CTE_LeaseLastIncomeGLPostedInfoPostNonAccrual(ContractId,LastIncomeUpdateDate)
AS
(
	SELECT
		C.Id,
		LIS.IncomeDate
	FROM Contracts C
	JOIN #SelectedContracts CT ON C.Id = CT.ContractId
	JOIN LeaseFinances LF ON LF.ContractId = C.Id
	JOIN LeaseIncomeSchedules LIS ON LIS.LeaseFinanceId = LF.Id
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
LEFT JOIN CTE_LeaseLastIncomeGLPostedInfoPostNonAccrual CLM ON CLM.ContractId = C.Id
WHERE C.ContractType = @LeaseContractType
GROUP BY C.Id;

--FETCH LATEST AMENDMENT DATE POST NON-ACCRUAL

WITH CTE_LeaseLastModifiedDatePostNonAccrual(ContractId,LastModifiedDate)
AS
(
SELECT
	C.Id,
	CASE WHEN LA.AmendmentDate <= CB.CommencementDate THEN CB.CommencementDate
		 ELSE LA.AmendmentDate
	END
FROM LeaseAmendments LA
JOIN LeaseFinances LF ON LA.CurrentLeaseFinanceId = LF.Id
JOIN Contracts C ON LF.ContractId = C.Id
JOIN #SelectedContracts CT ON C.Id = CT.ContractId
JOIN #ContractBasicInfo CB ON C.Id = CB.ContractId
WHERE LA.LeaseAmendmentStatus = @AmendmentAppprovedStatus
		AND LA.AmendmentDate > CB.NonAccrualDate
		AND LA.AmendmentType NOT IN (@ReceiptAmendmentType,@GLTransferAmendmentType)
)
INSERT INTO #ContractLastModificationDateInfoPostNonAccrual
SELECT
	C.Id,
	MAX(CLM.LastModifiedDate)
FROM Contracts C
JOIN #SelectedContracts CT ON C.Id = CT.ContractId
LEFT JOIN CTE_LeaseLastModifiedDatePostNonAccrual CLM ON CLM.ContractId = C.Id
WHERE C.ContractType = @LeaseContractType
GROUP BY C.Id;

--select * from #ContractLastModificationDateInfoPostNonAccrual
----------*** LAST PAYMENT START DATE ***-----------------

INSERT INTO #LastPaymentStartDate
SELECT 
	LF.ContractId,
	MAX(LPS.StartDate)
FROM #SelectedContracts SC
JOIN LeaseFinances LF ON SC.ContractId = LF.ContractId
JOIN LeaseFinanceDetails LFD ON LF.Id = LFD.Id
JOIN LeasePaymentSchedules LPS ON LFD.Id = LPS.LeaseFinanceDetailId
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
				WHEN GLI.IncomeDate IS NOT NULL THEN ( CASE WHEN GLI.IncomeDate >= LPSD.StartDate THEN 0 ELSE 1 END) 
				ELSE 1 
			END))
		 AND (GLI.IncomeDate IS NOT NULL OR CLM.LastModificationDate IS NOT NULL)
)


INSERT INTO #ReAccrualDateInfo
SELECT
	CMD.ContractId,
	MIN(LPS.StartDate)
FROM CTE_MaxModifiedDate CMD
JOIN LeaseFinances LF ON CMD.ContractId = LF.ContractId AND LF.IsCurrent=1
JOIN LeasePaymentSchedules LPS ON  LPS.LeaseFinanceDetailId = LF.Id AND LPS.IsActive=1 
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
WHERE  (1 = (CASE 
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
JOIN LeaseFinances LF ON CMD.ContractId = LF.ContractId AND LF.IsCurrent=1
JOIN LeasePaymentSchedules LPS ON  LPS.LeaseFinanceDetailId = LF.Id AND LPS.IsActive=1 
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
JOIN LeaseFinances LF ON LF.ContractId = C.Id
JOIN LeaseIncomeSchedules LIS ON LIS.LeaseFinanceId = LF.Id
WHERE LIS.IsAccounting=1 and LIS.IsGLPosted =1 and LIS.IsLessorOwned=1 AND LIS.AdjustmentEntry = 0
GROUP BY C.Id;



----------------*** LAST MODIFICATION DATE***-----------------


WITH CTE_LeaseLastModifiedDate(ContractId,LastModifiedDate)
AS
(
SELECT
	C.Id,
	CASE WHEN LA.AmendmentDate <= CB.CommencementDate THEN CB.CommencementDate
		 WHEN LA.AmendmentType in (@RebookAmendmentType,@SyndicationAmendmentType,@NonAccrualAmendmentType,@ReAccrualAmendmentType,@AssumptionAmendmentType)THEN LA.AmendmentDate
		 WHEN LA.AmendmentType in (@RestructureAmendmentType,@PayoffAmendmentType,@RenewalAmendmentType,@NBVImpairmentAmendmentType,@ResidualImpairmentAmendmentType) THEN DATEADD(DAY,1,LA.AmendmentDate)
		 ELSE LA.AmendmentDate
	END
FROM LeaseAmendments LA
JOIN LeaseFinances LF ON LA.CurrentLeaseFinanceId = LF.Id
JOIN Contracts C ON LF.ContractId = C.Id
JOIN #SelectedContracts CT ON C.Id = CT.ContractId
JOIN #ContractBasicInfo CB ON C.Id = CB.ContractId
WHERE LA.LeaseAmendmentStatus = @AmendmentAppprovedStatus
		AND LA.AmendmentType NOT IN (@ReceiptAmendmentType,@GLTransferAmendmentType)
)

INSERT INTO #ContractLastModificationDateInfo
SELECT
	C.Id,
	MAX(CLM.LastModifiedDate)
FROM Contracts C
JOIN #SelectedContracts CT ON C.Id = CT.ContractId
LEFT JOIN CTE_LeaseLastModifiedDate CLM ON CLM.ContractId = C.Id
WHERE C.ContractType = @LeaseContractType
GROUP BY C.Id;

--SELECT * FROM #ContractLastModificationDateInfo


-----------*** OUTSTANDING RECEIVABLE BALANCE***--------------

INSERT INTO #ContractOutstandingARInfo
SELECT 
	R.EntityId,
	SUM(R.TotalBalance_Amount)
FROM #ContractBasicInfo CB
JOIN Receivables R ON CB.IsLease = 1 AND CB.ContractId = R.EntityId AND R.EntityType = 'CT' AND R.IsActive = 1
JOIN ReceivableCodes RC ON R.ReceivableCodeId = RC.Id
JOIN ReceivableTypes RT ON RC.ReceivableTypeId = RT.Id
JOIN LeasePaymentSchedules LPS ON R.PaymentScheduleId = LPS.Id AND CB.IsLease = 1 AND LPS.StartDate < CB.ReAccrualDate
WHERE RT.Name IN ('CapitalLeaseRental','OperatingLeaseRental','LeaseFloatRateAdj','OverTermRental','Supplemental')
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
JOIN #ContractBasicInfo  CBI ON CT.ContractId = CBI.ContractId
JOIN ContractBillings CB ON CT.ContractId = CB.Id AND CB.IsActive = 1
JOIN ContractBillingPreferences CBP ON CB.Id = CBP.ContractBillingId AND CBP.IsActive = 1
JOIN ReceivableTypes RT ON CBP.ReceivableTypeId = RT.Id AND RT.IsActive = 1
WHERE RT.Name IN ((CASE WHEN CBI.ReAccrualDate <= CBI.MaturityDate 
						THEN (CASE WHEN CBI.LeaseContractType = 'Operating' 
								   THEN 'OperatingLeaseRental' ELSE 'CapitalLeaseRental'
							  END)
						ELSE 'OverTermRental,Supplemental'
				   END))
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

--DROP TABLE #InvoicePreferenceCount

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
		AND  RT.Name IN ((CASE WHEN CBI.ReAccrualDate <= CBI.MaturityDate 
						THEN (CASE WHEN CBI.LeaseContractType = 'Operating' 
								   THEN 'OperatingLeaseRental' ELSE 'CapitalLeaseRental'
							  END)
						ELSE 'OverTermRental,Supplemental'
				   END))

---- SET BILLING SUPPRESSED AS 0 FOR THE CONTRACTS HAVING COUNT OF INVOICE PREFERNCE MORE THAN 1

INSERT INTO #BillingSuppressedInfo
SELECT
	SC.ContractId,
	0
FROM #SelectedContracts SC
JOIN #InvoicePreferenceCount IPC ON SC.ContractId = IPC.ContractId
WHERE IPC.Count_InvoicePreference > 1;

---****Suspended Income ****----

---- FETCH ASSET INCOME SCHEDULE----

WITH CTE_CurrentLeaseAssetIds(ContractId,LeaseAssetId,IsTerminated)
AS
(
SELECT 
	SC.ContractId,
	LeaseAssetId = LA.Id,
	IsTerminated = CASE WHEN (LA.TerminationDate Is NOT NULL AND LA.IsActive = 0) THEN 1 ELSE 0 END
FROM #SelectedContracts SC
JOIN LeaseFinances LF ON SC.ContractId = LF.ContractId AND LF.Iscurrent = 1
JOIN LeaseAssets LA on LF.Id = LA.LeaseFinanceId
WHERE (LA.IsActive = 1 OR LA.TerminationDate Is NOT NULL)
)
INSERT INTO #AssetIncomeInfoForSuspendedIncomeCalculation
SELECT 
	CB.ContractId,
	LIS.IncomeType,
	AIS.Income_Amount,
	AIS.RentalIncome_Amount,
	AIS.DeferredSellingProfitIncome_Amount,
	LA.IsLeaseAsset,
	AIS.LeaseRentalIncome_Amount,
	AIS.FinanceIncome_Amount,
    CLA.IsTerminated
FROM AssetIncomeSchedules AIS 
JOIN LeaseIncomeSchedules LIS ON AIS.LeaseIncomeScheduleId = LIS.Id
JOIN LeaseAssets LA ON AIS.AssetId = LA.AssetId
JOIN CTE_CurrentLeaseAssetIds CLA ON LA.Id = CLA.LeaseAssetId
JOIN #ContractBasicInfo CB ON CLA.ContractId = CB.ContractId
WHERE LIS.IncomeDate >= CB.NonAccrualDate
		AND LIS.IncomeDate < CB.ReAccrualDate
		AND LIS.IsSchedule = 1
		AND LIS.IsLessorOwned = 1
		AND AIS.IsActive = 1

--select * from #AssetIncomeInfoForSuspendedIncomeCalculation

-----FETCH OPERATING LEASE -----

INSERT INTO #OperatingLease
SELECT 
	CB.ContractId,
	CB.DoubtFulCollectability,
	CB.NonAccrualDate,
	CB.ReAccrualDate
FROM #ContractBasicInfo CB
WHERE CB.LeaseContractType = 'Operating'

--SELECT * FROM #OperatingLease

---- CALCULATE SUSPENDED INCOME FOR OPERATING LEASE HAVING DOUBTFUL COLLECTABILITY FALSE-------------

INSERT INTO #SuspendedIncomeInfo
SELECT 
	OL.ContractId,
	SUM(AIS.LeaseRentalIncome) + SUM(AIS.FinanceIncome) + SUM(AIS.DSPIncome)
FROM #OperatingLease OL
JOIN #AssetIncomeInfoForSuspendedIncomeCalculation AIS ON OL.ContractId = AIS.ContractId
WHERE OL.DoubtFulCollectability = 0
		AND AIS.IncomeType = 'FixedTerm'
		AND AIS.IsTerminated = 0
GROUP BY OL.ContractId

--SELECT * FROM #SuspendedIncomeInfo

----- FETCH CAPITAL LEASE -------------------------

INSERT INTO #CapitalLease
SELECT 
	CB.ContractId,
	CB.ReAccrualDate
FROM #ContractBasicInfo CB
WHERE CB.LeaseContractType <> 'Operating'

------CALCULATE SUSPENDED INCOME FOR CAPITAL LEASE-------------------

INSERT INTO #SuspendedIncomeInfo
SELECT 
	CL.ContractId,
	SUM(AIS.Income) + SUM(AIS.DSPIncome)
FROM #CapitalLease CL
JOIN #AssetIncomeInfoForSuspendedIncomeCalculation AIS ON CL.ContractId = AIS.ContractId
WHERE  AIS.IncomeType = 'FixedTerm'
		AND AIS.IsTerminated = 0
GROUP BY CL.ContractId

-----CALCULATE SUSPENDED INCOME FOR DOUBTFUL COLLECTABILITY TRUE ------------------

-----CALCULATE SUSPENDED INCOME FOR LEASE ASSETS------

INSERT INTO #SuspendedIncomeInfo 
SELECT
	AIS.ContractId,
	SUM(AIS.RentalIncome) + SUM(AIS.FinanceIncome) + SUM(AIS.DSPIncome)
FROM #OperatingLease OL
JOIN #AssetIncomeInfoForSuspendedIncomeCalculation AIS ON OL.ContractId = AIS.ContractId
WHERE OL.DoubtFulCollectability = 1
		AND AIS.IsLeaseAsset = 1
GROUP BY AIS.ContractId

-----CALCULATE SUSPENDED INCOME FOR FINANCE ASSETS------

SELECT
	AIS.ContractId,
    FinanceIncomeInfo = SUM(AIS.FinanceIncome) + SUM(AIS.DSPIncome)
INTO #SuspendedFinanceIncomeInfo
FROM #OperatingLease OL
JOIN #AssetIncomeInfoForSuspendedIncomeCalculation AIS ON OL.ContractId = AIS.ContractId
WHERE OL.DoubtFulCollectability = 1
		AND AIS.IsLeaseAsset = 0
GROUP BY AIS.ContractId

UPDATE #SuspendedIncomeInfo SET SuspendedIncome = SI.SuspendedIncome + SFI.FinanceIncomeInfo
FROM #OperatingLease OL
JOIN #SuspendedIncomeInfo SI ON OL.ContractId = SI.ContractId
JOIN #SuspendedFinanceIncomeInfo SFI ON SI.ContractId = SFI.ContractId

----- INCLUDE DEFERRED RENTAL INCOME IF CONTRACT IS FULLY SYNDICATED--------

;WITH CTE_FullySyndicatedDeferredRentalInfo AS
(
SELECT 
	OL.ContractId,
	LIS.DeferredRentalIncome_Amount
FROM #OperatingLease OL
JOIN ReceivableForTransfers RFT ON OL.ContractId = RFT.ContractId
JOIN LeaseFinances LF ON RFT.ContractId = LF.ContractId
JOIN LeaseIncomeSchedules LIS ON LF.Id = LIS.LeaseFinanceId
WHERE OL.DoubtFulCollectability = 1
		AND RFT.ReceivableForTransferType = 'FullSale'
		AND RFT.ApprovalStatus = 'Approved'
		AND LIS.IncomeDate = DATEADD(DAY,-1,RFT.EffectiveDate)
		AND LIS.IsSchedule=1 
		AND LIS.IsLessorOwned=1
GROUP BY OL.ContractId,LIS.DeferredRentalIncome_Amount
)

UPDATE #SuspendedIncomeInfo SET SuspendedIncome = SI.SuspendedIncome + FullySyndicatedDeferredRentalInfo.DeferredRentalIncome_Amount
FROM #OperatingLease OL
JOIN #SuspendedIncomeInfo SI ON OL.ContractId = SI.ContractId
JOIN CTE_FullySyndicatedDeferredRentalInfo FullySyndicatedDeferredRentalInfo ON SI.ContractId = FullySyndicatedDeferredRentalInfo.ContractId

-------INCLUDE DEFERRED RENTAL OF TERMINATED ASSETS IN PARTIAL PAYOFF-----------

-----FETCH TERMINATED ASSET IDS --------------

SELECT 
	OL.ContractId,
	LA.AssetId	
INTO #TerminatedAssetIdsInfo	 
FROM #OperatingLease OL 
JOIN LeaseFinances LF ON OL.ContractId = LF.ContractId
JOIN LeaseAssets LA on LF.Id = LA.LeaseFinanceId
JOIN LeaseAmendments LAM on LF.Id = LAM.CurrentLeaseFinanceId AND LAM.AmendmentType = 'Payoff' AND LAM.LeaseAmendmentStatus='Approved'
WHERE OL.DoubtFulCollectability = 1
		AND LA.IsActive=0
		AND LA.TerminationDate IS NOT NULL
		AND LA.IsLeaseAsset=1

-----FETCH DEFERRED RENTAL INCOME HAVING RANK BASED ON INCOME DATE FOR EACH ASSET------------

SELECT 
	TAI.ContractId,
	TAI.AssetId,
	Rank() OVER (PARTITION BY TAI.AssetId ORDER BY LIS.IncomeDate DESC) AS rankOverAssetIncomeSchedule,
	AIS.DeferredRentalIncome_Amount  
INTO #LatestAssetDeferredRentalIncomeInfo
FROM #TerminatedAssetIdsInfo TAI 
JOIN LeaseFinances LF on TAI.ContractId = LF.ContractId
JOIN Payoffs P ON LF.Id = P.LeaseFinanceId
JOIN LeaseIncomeSchedules LIS ON LF.Id = LIS.LeaseFinanceId
JOIN AssetIncomeSchedules AIS ON LIS.Id = AIS.LeaseIncomeScheduleId
WHERE LIS.IsSchedule=1				 
		AND AIS.IsActive=1
		AND LIS.IsLessorOwned = 1
		AND AIS.AssetId = TAI.AssetId
		AND P.Status='Activated'
		AND P.FullPayoff=0

-----FETCHING SUM OF DEFEREED RENTAL INCOME HAVING LATEST INCOME DATE IN EACH ASSET LEVEL-----------

SELECT 
	LADRI.ContractId,
	SUM(LADRI.DeferredRentalIncome_Amount) as TerminatedAssetsDeferredRental
INTO #TerminatedAssetsdDeferredRentalInfo
FROM #LatestAssetDeferredRentalIncomeInfo LADRI
WHERE LADRI.rankOverAssetIncomeSchedule=1
GROUP BY LADRI.ContractId

UPDATE #SuspendedIncomeInfo SET SuspendedIncome = SI.SuspendedIncome + TerminatedAssetsdDeferredRentalInfo.TerminatedAssetsDeferredRental
FROM #OperatingLease OL
JOIN #SuspendedIncomeInfo SI ON OL.ContractId = SI.ContractId
JOIN #TerminatedAssetsdDeferredRentalInfo TerminatedAssetsdDeferredRentalInfo ON SI.ContractId = TerminatedAssetsdDeferredRentalInfo.ContractId

----------EXCLUDE CASH POSTED AMOUNT POST NON-ACCRUAL DATE-------------

;WITH CTE_CashPostedReceivablesInfo AS 
(
	SELECT OL.ContractId, 
		   SUM(RARD.AmountApplied_Amount) AS AmountApplied
	FROM #OperatingLease OL
	JOIN LeaseFinances LF ON OL.ContractId = LF.ContractId AND LF.IsCurrent=1
	JOIN LeaseFinanceDetails LFD ON LF.Id = LFD.Id
	JOIN LeasePaymentSchedules LPS ON LFD.Id = LPS.LeaseFinanceDetailId AND LPS.IsActive=1
	JOIN Receivables REC ON LPS.Id = REC.PaymentScheduleId AND REC.IsActive=1
	JOIN ReceivableDetails RD ON REC.Id = RD.ReceivableId AND RD.IsActive=1
	JOIN LeaseAssets LA ON RD.AssetId = LA.AssetId and LA.IsActive = 1
	JOIN ReceiptApplicationReceivableDetails RARD ON RD.Id = RARD.ReceivableDetailId AND RARD.IsActive=1
	JOIN ReceiptApplications RA ON RARD.ReceiptApplicationId = RA.Id
	JOIN Receipts R ON RA.ReceiptId = R.Id
	WHERE OL.DoubtFulCollectability = 1
			AND REC.EntityType = 'CT'
			AND LA.IsLeaseAsset=1
			AND R.Status='Posted'
			AND LPS.PaymentType = 'FixedTerm'
			AND RARD.AmountApplied_Amount <> 0
			AND LPS.StartDate >= OL.NonAccrualDate
	GROUP BY OL.ContractId
)

UPDATE #SuspendedIncomeInfo SET SuspendedIncome = SI.SuspendedIncome - CashPostedReceivablesInfo.AmountApplied
FROM #OperatingLease OL
JOIN #SuspendedIncomeInfo SI ON OL.ContractId = SI.ContractId
JOIN CTE_CashPostedReceivablesInfo CashPostedReceivablesInfo ON SI.ContractId = CashPostedReceivablesInfo.ContractId


------FETCH OVERTERM AND SUPPLEMENTAL INCOME-------------

INSERT INTO #OTPIncome
SELECT
	AIS.ContractId,
	SUM(AIS.RentalIncome)
FROM #SuspendedIncomeInfo SI
JOIN #AssetIncomeInfoForSuspendedIncomeCalculation AIS ON SI.ContractId = AIS.ContractId
WHERE AIS.IncomeType = 'Supplemental' 
		 OR AIS.IncomeType = 'OverTerm'
GROUP BY AIS.ContractId

-------UPDATE OVERTERM AND SUPPLEMENTAL INCOME TO SUSPENDED INCOME----------------

UPDATE #SuspendedIncomeInfo SET SuspendedIncome = SuspendedIncome + OI.OTPIncome
FROM #SuspendedIncomeInfo SI
JOIN #OTPIncome OI ON SI.ContractId = OI.ContractId

--SELECT * FROM #SuspendedIncomeInfo

-------***NBV CALCULATION***----------------------------------------------------------------------------

-------------- NBV COMPUTATION FOR CAPITAL LEASES -----------------------------------

----FETCH LEASE INCOMES POST RE-ACCRUAL WITH RAKNING-----------

SELECT 
	ContractId = CL.ContractId, 
	IncomeScheduleId = LI.Id, 
	RowNumber = ROW_NUMBER() OVER (PARTITION BY CL.ContractId ORDER BY LI.IncomeDate, LI.Id)
INTO #CapitalLeaseFirstIncomeInfo
FROM #CapitalLease CL
JOIN LeaseFinances LF ON CL.ContractId = LF.ContractId
JOIN LeaseIncomeSchedules LI ON LF.Id = LI.LeaseFinanceId AND LI.IncomeDate >= CL.ReAccrualDate
WHERE LI.IsSchedule = 1
		AND LI.IsLessorOwned = 1;

-----CALCULATE NBV FOR EACH CONTRACT-----------------

INSERT INTO #ContractNBVInfo
SELECT 
	 CLFI.ContractId, 
	(LIS.BeginNetBookValue_Amount - (LIS.DeferredSellingProfitIncomeBalance_Amount + LIS.DeferredSellingProfitIncome_Amount))
FROM #CapitalLeaseFirstIncomeInfo CLFI
JOIN LeaseIncomeSchedules LIS ON CLFI.IncomeScheduleId = LIS.Id
WHERE CLFI.RowNumber = 1;

------------------------------- NBV COMPUTATION FOR OPERATING LEASES---------------------------------------------------------

---------***CALCULATE NBV FOR HFS CONTRACTS***-------

--------FETCH SYNDICATION EFFECTIVE DATE HAPPENED ON RE-ACCRUAL DATE--------
SELECT 
	RFT.ContractId,
	RFT.EffectiveDate 
INTO #SyndicationInfoForParticipatedSale 
FROM #OperatingLease OL
JOIN #ContractBasicInfo CB ON OL.ContractId = CB.ContractId
JOIN ReceivableForTransfers RFT ON OL.ContractId = RFT.ContractId
WHERE CB.HoldingStatus = 'HFS'
		AND RFT.ReceivableForTransferType = 'ParticipatedSale'
		AND RFT.ApprovalStatus ='Approved'
		AND RFT.EffectiveDate = OL.ReAccrualDate

-----FETCH ASSETVALUEHISTORY IDS PRIOR TO RE-ACCRUAL DATE FOR NON-PARTICIPATED SYNDICATED CONTRACTS-------------------

SELECT 
	ContractId = OL.ContractId, 
	AssetValueHistoryId = AVL.Id,
	RowNumber = ROW_NUMBER() OVER (PARTITION BY OL.ContractId, AVL.AssetId ORDER BY AVL.IncomeDate DESC, AVL.Id DESC)
INTO #OperatingLeaseMaxAssetValueHistoryInfoForHFS
FROM #OperatingLease OL
JOIN #ContractBasicInfo CB ON OL.ContractId = CB.ContractId
JOIN LeaseFinances LF ON CB.LeaseFinanceId = LF.Id
JOIN LeaseAssets LA ON LF.Id = LA.LeaseFinanceId
JOIN AssetValueHistories AVL ON LA.AssetId = AVL.AssetId AND AVL.IncomeDate < OL.ReAccrualDate
LEFT JOIN #SyndicationInfoForParticipatedSale SI ON OL.ContractId = SI.ContractId
WHERE CB.HoldingStatus = 'HFS'
		AND LA.IsActive = 1
		AND AVL.IsSchedule = 1
		AND AVL.IsLessorOwned = 1
		AND AVL.SourceModule IN ('FixedTermDepreciation','ResidualRecapture','OTPDepreciation')
		AND SI.ContractId IS NULL;

-----FETCH ASSETVALUEHISTORY IDS AS OF RE-ACCRUAL DATE FOR PARTICIPATED SYNDICATED CONTRACTS-------------------

INSERT INTO #OperatingLeaseMaxAssetValueHistoryInfoForHFS
SELECT 
	ContractId = OL.ContractId, 
	AssetValueHistoryId = AVL.Id, 
	RowNumber = ROW_NUMBER() OVER (PARTITION BY OL.ContractId, AVL.AssetId ORDER BY AVL.IncomeDate DESC, AVL.Id DESC)
FROM #OperatingLease OL
JOIN #ContractBasicInfo CB ON OL.ContractId = CB.ContractId
JOIN #SyndicationInfoForParticipatedSale SI ON OL.ContractId = SI.ContractId
JOIN LeaseFinances LF ON CB.LeaseFinanceId = LF.Id
JOIN LeaseAssets LA ON LF.Id = LA.LeaseFinanceId
JOIN AssetValueHistories AVL ON LA.AssetId = AVL.AssetId AND AVL.IncomeDate = SI.EffectiveDate
WHERE CB.HoldingStatus = 'HFS'
		AND LA.IsActive = 1
		AND AVL.IsSchedule = 1
		AND AVL.IsLessorOwned = 1
		AND AVL.SourceModule IN ('FixedTermDepreciation','ResidualRecapture','OTPDepreciation');

----UPDATE NBV FOR HFS CONTRACTS----------

INSERT INTO #ContractNBVInfo
SELECT 
	OLMA.ContractId,
	SUM(AVL.EndBookValue_Amount)
FROM #OperatingLeaseMaxAssetValueHistoryInfoForHFS OLMA
JOIN AssetValueHistories AVL ON OLMA.AssetValueHistoryId = AVL.Id
WHERE OLMA.RowNumber = 1
GROUP BY OLMA.ContractId;

----------------------***CALCULATE NBV FOR HFI CONTRACTS***-------------------

-----FETCH ASSETVALUEHISTORY IDS POST RE-ACCRUAL DATE-------------------

SELECT 
	ContractId = OL.ContractId,
	AssetValueHistoryId = AVL.Id,
	RowNumber = ROW_NUMBER() OVER (PARTITION BY OL.ContractId, AVL.AssetId ORDER BY AVL.IncomeDate, AVL.Id)
INTO #OperatingLeaseMaxAssetValueHistoryInfoForHFI
FROM #OperatingLease OL
JOIN #ContractBasicInfo CB ON OL.ContractId = CB.ContractId
JOIN LeaseFinances LF ON CB.LeaseFinanceId = LF.Id
JOIN LeaseAssets LA ON LF.Id = LA.LeaseFinanceId
JOIN AssetValueHistories AVL ON LA.AssetId = AVL.AssetId AND AVL.IncomeDate >= OL.ReAccrualDate
WHERE CB.HoldingStatus != 'HFS'
		AND LA.IsActive = 1
		AND AVL.IsSchedule = 1
		AND AVL.IsLessorOwned = 1
		AND AVL.SourceModule IN ('FixedTermDepreciation','ResidualRecapture','OTPDepreciation');

----UPDATE NBV FOR HFI CONTRACTS----------

INSERT INTO #ContractNBVInfo
SELECT 
	OLMA.ContractId, 
	SUM(AVL.BeginBookValue_Amount)
FROM #OperatingLeaseMaxAssetValueHistoryInfoForHFI OLMA
JOIN AssetValueHistories AVL ON OLMA.AssetValueHistoryId = AVL.Id AND AVL.IsLessorOwned = 1
WHERE OLMA.RowNumber = 1
GROUP BY OLMA.ContractId;

--SELECT * FROM #ContractNBVInfo

----------CALCULATE FINANCE ASSETS NBV FOR OPERATING LEASE----------------------

------FETCH FINANCE ASSET IDS---------------

SELECT 
	LA.AssetId,
	LA.LeaseFinanceId
INTO #FinanceAssetsInfo
FROM LeaseAssets LA
JOIN LeaseFinances LF ON LA.LeaseFinanceId = LF.Id
JOIN #ContractBasicInfo CB ON LF.Id = CB.LeaseFinanceId
JOIN #OperatingLease OL ON CB.ContractId = OL.ContractId
WHERE LA.IsActive =1
		AND LA.IsLeaseAsset = 0


IF EXISTS (SELECT * FROM #FinanceAssetsInfo)
BEGIN

--------FETCH INCOME SCHEDULES POST RE-ACCRUAL DATE---------

SELECT 
	ContractId = OL.ContractId, 
	IncomeScheduleId = LIS.Id,
	RowNumber = ROW_NUMBER() OVER (PARTITION BY OL.ContractId ORDER BY LIS.IncomeDate, LIS.Id)
INTO #OperatingLeaseFirstIncomeInfo
FROM #OperatingLease OL
JOIN LeaseFinances LF ON OL.ContractId = LF.ContractId
JOIN LeaseIncomeSchedules LIS ON LF.Id = LIS.LeaseFinanceId AND LIS.IncomeDate >= OL.ReAccrualDate
WHERE LIS.IsSchedule = 1
AND LIS.IsLessorOwned = 1

------CALCULATE NBV FOR FINANCE ASSETS----------------

SELECT 
	OLFI.ContractId, 
	SUM(AIS.BeginNetBookValue_Amount - (AIS.DeferredSellingProfitIncomeBalance_Amount + AIS.DeferredSellingProfitIncome_Amount)) AS NBV
INTO #FinanceAssetNBVInfo
FROM AssetIncomeSchedules AIS
JOIN LeaseIncomeSchedules LIS ON AIS.LeaseIncomeScheduleId = LIS.Id
JOIN #FinanceAssetsInfo FA ON AIS.AssetId = FA.AssetId
JOIN #OperatingLeaseFirstIncomeInfo OLFI ON LIS.Id = OLFI.IncomeScheduleId
WHERE OLFI.RowNumber = 1
GROUP BY OLFI.ContractId

-----UPDATE FINANCE ASSETS NBV TO RESPECTIVE CONTRACTS----------

UPDATE #ContractNBVInfo
SET NBV = CI.NBV + FI.NBV
FROM #FinanceAssetNBVInfo FI
JOIN #ContractNBVInfo CI ON FI.ContractId = CI.ContractId
END

---------------------------********************** NBV WITH BLENDED COMPUTATION***************************---------------------------

--------------------**** (A)BLENDED INCOME BALANCE COMPUTATION ****-----------------------

------FETCH BLENDED ITEM INFO FOR ONE TIME OCCURUNCE BLENDED ITEM-------------

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
JOIN LeaseBlendedItems LBI ON CB.IsLease = 1 AND CB.LeaseFinanceId IS NOT NULL AND CB.LeaseFinanceId  = LBI.LeaseFinanceId
JOIN BlendedItems BI ON LBI.BlendedItemId = BI.Id AND BI.IsActive = 1 AND BI.IsFAS91 = 1 AND BI.BookRecognitionMode IN ('Amortize')
JOIN Contracts C on CB.ContractId = C.Id
WHERE CB.ReAccrualDate < CB.MaturityDate
		AND BI.Occurrence='OneTime'
		AND (C.AccountingStandard = 'ASC840_IAS17' OR (BI.Type !='IDC' OR (BI.Type ='IDC' AND BI.RelatedBlendedItemId IS NOT NULL)));

--select * FROM #BlendedItems

------FETCH BLENDED ITEM INFO FOR RECURRING OCCURUNCE BLENDED ITEM-------------

INSERT INTO #BlendedItems
SELECT 
	CB.ContractId, 
	CB.CommencementDate, 
	CB.MaturityDate, 
	CB.ReAccrualDate, 
	BI.Id, 
	BI.[Type], 
	BI.BookRecognitionMode, 
	Amount = SUM(BID.Amount_Amount)
FROM #ContractBasicInfo CB
JOIN LeaseBlendedItems LBI ON CB.IsLease = 1 AND CB.LeaseFinanceId IS NOT NULL AND CB.LeaseFinanceId  = LBI.LeaseFinanceId
JOIN BlendedItems BI ON LBI.BlendedItemId = BI.Id AND BI.IsActive = 1 AND BI.IsFAS91 = 1 AND BI.BookRecognitionMode IN ('Amortize','Accrete')
JOIN BlendedItemDetails BID ON BI.Id = BID.BlendedItemId
JOIN Contracts C on CB.ContractId = C.Id
WHERE CB.ReAccrualDate < CB.MaturityDate
		AND BID.DueDate < CB.ReAccrualDate
		AND (BI.BookRecognitionMode = 'Accrete' OR (BI.BookRecognitionMode = 'Amortize' AND BI.Occurrence='Recurring'))
		AND (C.AccountingStandard = 'ASC840_IAS17' OR (BI.Type !='IDC' OR (BI.Type ='IDC' AND BI.RelatedBlendedItemId IS NOT NULL)))
GROUP BY CB.ContractId, CB.CommencementDate, CB.MaturityDate, CB.ReAccrualDate, BI.Id, BI.[Type], BI.BookRecognitionMode;



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
JOIN LeaseFinances LF ON CT.ContractId = LF.ContractId 
JOIN BlendedIncomeSchedules BIS ON LF.Id = BIS.LeaseFinanceId AND BIS.IsSchedule = 1 AND BIS.IncomeDate <= DATEADD(DAY, -1, CB.ReAccrualDate)
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

--SELECT * FROM #ContractBlendedItemBalanceInfo

--------------***(B) OUTSTANDING RECEIVABLE BALANCE COMPUTATION***-------------

-----FETCH RECEIVABLES INFO BASED ON VALID RECEIVABLE TYPES-----------

SELECT 
	CB.ContractId, 
	CB.ReAccrualDate, 
	ReceivableId = R.Id, 
	R.PaymentScheduleId, 
	EffectiveBalance = RD.Balance_Amount,
	ReceivableDetailId = RD.Id
INTO #ContractReceivablesInfo
FROM ReceivableDetails RD 
JOIN LeaseAssets LA ON RD.AssetId = LA.AssetId and LA.IsActive = 1
JOIN LeaseFinances LF ON LA.LeaseFinanceId = LF.Id AND LF.IsCurrent = 1
JOIN Receivables R ON RD.ReceivableId = R.Id AND R.EntityType = 'CT' AND R.IsActive = 1
JOIN #ContractBasicInfo CB ON R.EntityId = CB.ContractId
JOIN ReceivableCodes RC ON R.ReceivableCodeId = RC.Id AND RC.IsActive = 1
JOIN ReceivableTypes RT ON RC.ReceivableTypeId = RT.Id AND RT.IsActive = 1
WHERE R.IsDummy = 0
		AND RD.IsActive = 1
		AND R.FunderId IS NULL
		AND CB.IsLease = 1
	    AND RT.Name IN ('CapitalLeaseRental','OperatingLeaseRental','LeaseFloatRateAdj','OverTermRental','Supplemental')


----- CALCULATE RECEIVABLE BALANCE PRIOR TO REACCRUAL DATE BASED ON CONTRACT---------

SELECT 
	CR.ContractId, 
	Amount = SUM(CR.EffectiveBalance)
INTO #OutstandingReceivablesInfo
FROM #ContractReceivablesInfo CR
JOIN LeasePaymentSchedules LP ON CR.PaymentScheduleId = LP.Id
WHERE (LP.StartDate < CR.ReAccrualDate OR LP.StartDate IS NULL)
		AND LP.PaymentType IN ('FixedTerm','Downpayment','MaturityPayment','CustomerGuaranteedResidual','ThirdPartyGuaranteedResidual','OTP','Supplemental')
GROUP BY CR.ContractId;

--SELECT * FROM #OutstandingReceivablesInfo



----------------***(C) FUTURE CASH POSTING AMOUNT COMPUTATION***-------------
SELECT 
	CR.ContractId, 
	Amount = SUM(RARD.AmountApplied_Amount)
INTO #FutureCashPostingInfo
FROM #ContractReceivablesInfo CR
JOIN LeasePaymentSchedules LP ON CR.PaymentScheduleId = LP.Id
JOIN ReceiptApplicationReceivableDetails RARD ON CR.ReceivableDetailId = RARD.ReceivableDetailId AND RARD.IsActive = 1
JOIN ReceiptApplications RA ON RARD.ReceiptApplicationId = RA.Id
JOIN Receipts R ON RA.ReceiptId = R.Id
WHERE  LP.StartDate >= CR.ReAccrualDate
		  AND R.[Status] NOT IN ('Inactive','Reversed')
		  AND R.ReceiptClassification NOT IN ('NonCash','NonAccrualNonDSLNonCash')
GROUP BY CR.ContractId;

------------*** (D)RECOGNIZED DEPRECIATION FOR OPERATING LEASE ***--------------

SELECT  
	OL.ContractId, 
	SUM(Value_Amount) AS Amount
INTO #NBVWithBlended_ContractRecognizedDepreciationInfo
FROM AssetValueHistories AVH
JOIN LeaseAssets LA on AVH.AssetId = LA.AssetId
JOIN LeaseFinances LF on LA.LeaseFinanceId = LF.id
JOIN #ContractBasicInfo CB ON LF.Id = CB.LeaseFinanceId
JOIN #OperatingLease OL ON CB.ContractId = OL.ContractId
WHERE AVH.IsCleared = 0
		AND LA.IsActive = 1
		AND AVH.IncomeDate > OL.ReAccrualDate
		AND AVH.IsSchedule = 1
		AND AVH.IsLessorOwned = 1
		AND AVH.IsAccounted = 1
		AND AVH.GLJournalId IS NOT NULL
		AND (AVH.SourceModule = 'FixedTermDepreciation' OR AVH.SourceModule = 'OTPDepreciation')
GROUP BY OL.ContractId

-----*** NBV WITH BLENDED = NBV + A + B - C + D ****--------------

INSERT INTO #ContractNBVWithBlendedInfo
SELECT 
	CB.ContractId, 
	NBVWithBlended = ISNULL(CN.NBV, 0.00) + ISNULL(CBIB.Amount, 0.00) + ISNULL(ORI.Amount, 0.00) - ISNULL(FCP.Amount, 0.00) + ISNULL(CD.Amount, 0.00)
FROM #ContractBasicInfo CB
LEFT JOIN #ContractNBVInfo CN ON CB.ContractId = CN.ContractId
LEFT JOIN #ContractBlendedItemBalanceInfo CBIB ON CB.ContractId = CBIB.ContractId
LEFT JOIN #OutstandingReceivablesInfo ORI ON CB.ContractId = ORI.ContractId
LEFT JOIN #FutureCashPostingInfo FCP ON CB.ContractId = FCP.ContractId
LEFT JOIN #NBVWithBlended_ContractRecognizedDepreciationInfo CD ON CB.ContractId = CD.ContractId

---------------------------****************OUTPUT*******************---------------------------------------------------------------------------------
SELECT
    ContractId = CB.ContractId,
	SequenceNumber = CB.SequenceNumber,
	CustomerId = CB.CustomerId,
	CustomerNumber = CB.CustomerNumber,
	CustomerName = CB.CustomerName,
	LegalEntityId = CB.LegalEntityId,
	LegalEntityName = CB.LegalEntityName,
	LeaseFinanceId = CB.LeaseFinanceId,
	CommencementDate = CB.CommencementDate,
	MaturityDate = CB.MaturityDate,
	ContractCurrencyCode = CB.ContractCurrencyCode,
	IsLease = CB.IsLease,
	LeaseContractType = CB.LeaseContractType,
	LeaseFinanceDetailId = CB.LeaseFinanceDetailId,
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
	JOIN #LastPaymentStartDate LPS ON CB.ContractId = LPS.ContractId
	LEFT JOIN #ContractLastIncomeGLPostedInfo CLI ON CB.ContractId = CLI.ContractId
	LEFT JOIN #ContractLastModificationDateInfo CLM ON CB.ContractId = CLM.ContractId
	LEFT JOIN #ContractLastReceiptDateInfo CLR ON CB.ContractId = CLR.ContractId
	LEFT JOIN #ContractOutstandingARInfo COAR ON CB.ContractId = COAR.ContractId
	LEFT JOIN #BillingSuppressedInfo BS ON CB.ContractId = BS.ContractId
	LEFT JOIN #SuspendedIncomeInfo SI ON CB.ContractId = SI.ContractId
	LEFT JOIN #ContractNBVInfo CN ON CB.ContractId = CN.ContractId
	LEFT JOIN #ContractNBVWithBlendedInfo CNB ON CB.ContractId = CNB.ContractId;

--------------------***DROP TABLE***-------------------------

IF OBJECT_ID('#ContractBasicInfo') IS NOT NULL	DROP TABLE #ContractBasicInfo 
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
IF OBJECT_ID('#ContractLastIncomeGLPostedInfoPostNonAccrual') IS NOT NULL DROP TABLE #ContractLastIncomeGLPostedInfoPostNonAccrual
IF OBJECT_ID('#ContractLastModificationDateInfoPostNonAccrual') IS NOT NULL DROP TABLE #ContractLastModificationDateInfoPostNonAccrual
IF OBJECT_ID('#ReAccrualDateInfo') IS NOT NULL DROP TABLE #ReAccrualDateInfo
IF OBJECT_ID('#BillingSuppressedInfo') IS NOT NULL DROP TABLE #BillingSuppressedInfo
IF OBJECT_ID('#AssetIncomeInfoForSuspendedIncomeCalculation') IS NOT NULL DROP TABLE #AssetIncomeInfoForSuspendedIncomeCalculation
IF OBJECT_ID('#CapitalLease') IS NOT NULL DROP TABLE #CapitalLease
IF OBJECT_ID('#LatestAssetDeferredRentalIncomeInfo') IS NOT NULL DROP TABLE #LatestAssetDeferredRentalIncomeInfo
IF OBJECT_ID('#OperatingLease') IS NOT NULL DROP TABLE #OperatingLease
IF OBJECT_ID('#OTPIncome') IS NOT NULL DROP TABLE #OTPIncome
IF OBJECT_ID('#SuspendedIncomeInfo') IS NOT NULL DROP TABLE #SuspendedIncomeInfo
IF OBJECT_ID('#TerminatedAssetIdsInfo') IS NOT NULL DROP TABLE #TerminatedAssetIdsInfo
IF OBJECT_ID('#TerminatedAssetsdDeferredRentalInfo') IS NOT NULL DROP TABLE #TerminatedAssetsdDeferredRentalInfo
IF OBJECT_ID('#LastPaymentStartDate') IS NOT NULL DROP TABLE #LastPaymentStartDate
IF OBJECT_ID('#CapitalLeaseFirstIncomeInfo') IS NOT NULL DROP TABLE #CapitalLeaseFirstIncomeInfo
IF OBJECT_ID('#FinanceAssetNBVInfo') IS NOT NULL DROP TABLE #FinanceAssetNBVInfo
IF OBJECT_ID('#FinanceAssetsInfo') IS NOT NULL DROP TABLE #FinanceAssetsInfo
IF OBJECT_ID('#OperatingLeaseFirstIncomeInfo') IS NOT NULL DROP TABLE #OperatingLeaseFirstIncomeInfo
IF OBJECT_ID('#OperatingLeaseMaxAssetValueHistoryInfoForHFI') IS NOT NULL DROP TABLE #OperatingLeaseMaxAssetValueHistoryInfoForHFI
IF OBJECT_ID('#OperatingLeaseMaxAssetValueHistoryInfoForHFS') IS NOT NULL DROP TABLE #OperatingLeaseMaxAssetValueHistoryInfoForHFS
IF OBJECT_ID('#SyndicationInfoForParticipatedSale') IS NOT NULL DROP TABLE #SyndicationInfoForParticipatedSale
IF OBJECT_ID('#BlendedIncomeBalances') IS NOT NULL DROP TABLE #BlendedIncomeBalances
IF OBJECT_ID('#BlendedItemBalanceInfo') IS NOT NULL DROP TABLE #BlendedItemBalanceInfo
IF OBJECT_ID('#BlendedItems') IS NOT NULL DROP TABLE #BlendedItems
IF OBJECT_ID('#ContractBlendedItemBalanceInfo') IS NOT NULL DROP TABLE #ContractBlendedItemBalanceInfo
IF OBJECT_ID('#ContractReceivablesInfo') IS NOT NULL DROP TABLE #ContractReceivablesInfo
IF OBJECT_ID('#FutureCashPostingInfo') IS NOT NULL DROP TABLE #FutureCashPostingInfo
IF OBJECT_ID('#NBVWithBlended_ContractRecognizedDepreciationInfo') IS NOT NULL DROP TABLE #NBVWithBlended_ContractRecognizedDepreciationInfo
IF OBJECT_ID('#OutstandingReceivablesInfo') IS NOT NULL DROP TABLE #OutstandingReceivablesInfo
IF OBJECT_ID('#InvoicePreferenceCount') IS NOT NULL DROP TABLE #InvoicePreferenceCount
IF OBJECT_ID('#SuspendedFinanceIncomeInfo') IS NOT NULL DROP TABLE #SuspendedFinanceIncomeInfo

SET
NOCOUNT OFF;
END

GO
