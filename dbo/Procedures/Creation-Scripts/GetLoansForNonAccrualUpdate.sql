SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [dbo].[GetLoansForNonAccrualUpdate]
(
@LegalEntities NonAccrual_LegalEntities READONLY,
@EntityType NVARCHAR(20),
@FilterOption NVARCHAR(20),
@ContractId BIGINT = NULL,
@CustomerId BIGINT = NULL,
@DefaultCultureCurrency NVARCHAR(3),
@LoanContractType NVARCHAR(20),
@ReceivableContractType NVARCHAR(20),
@ReceiptStatusPosted NVARCHAR(20),
@ReceiptStatusReadyForPosting NVARCHAR(20),
@AmendmentAppprovedStatus NVARCHAR(30),
@RestructureAmendmentType NVARCHAR(30),
@RebookAmendmentType NVARCHAR(30),
@SyndicationAmendmentType NVARCHAR(30),
@AssumptionAmendmentType NVARCHAR(30),
@NonAccrualAmendmentType NVARCHAR(30),
@ReAccrualAmendmentType NVARCHAR(30),
@PayDownAmendmentType NVARCHAR(30),
@ReceiptAmendmentType NVARCHAR(20),
@GLTransferAmendmentType NVARCHAR(20),
@EffectiveDateForThresholdDate DATE
)
AS
BEGIN
SET NOCOUNT ON;

CREATE TABLE #ContractBasicInfo
(
ContractId BIGINT,
SequenceNumber NVARCHAR(100),
LegalEntityId BIGINT,
LegalEntityName NVARCHAR(100),
LegalEntityNumber NVARCHAR(100),
CustomerId BIGINT,
CustomerName NVARCHAR(500),
CustomerNumber NVARCHAR(100),
LoanFinanceId BIGINT NOT NULL,
CommencementDate DATE,
MaturityDate DATE,
CurrencyId BIGINT,
ContractCurrencyCode NVARCHAR(5),
NetInvestment DECIMAL(16,2),
IsDSL BIT,
HoldingStatus NVARCHAR(30),
NonAccrualTemplateId BIGINT NULL,
Basis NVARCHAR(40) NULL,
MinimumPercentageOfBasis DECIMAL (6,2) NULL,
MinimumQualifyingAmount DECIMAL(16,2),
ThresholdDate DATE NULL,
DaysPastDueLimit INT NULL,
NonAccrualDateOption NVARCHAR(26),
TemplateBillingSuppressed BIT NOT NULL,
ContractReceivableAmendmentType NVARCHAR(40) NULL
);

CREATE TABLE #ContractLastIncomeGLPostedInfo
(
ContractId BIGINT,
IncomeDate DATE
);

CREATE TABLE #ContractOutstandingReceivableInfo
(
ContractId BIGINT NOT NULL,
OutstandingReceivableDueDate DATE,
LoanFinanceId BIGINT
);

CREATE TABLE #ContractOutstandingPaymentInfo
(
ContractId BIGINT,
OutstandingPaymentDate DATE
);

CREATE TABLE #ContractLastModificationDateInfo
(
ContractId BIGINT,
LastModificationDate DATE
);

CREATE TABLE #ContractEstimatedNonAccrualDateInfo
(
ContractId BIGINT,
NonAccrualDate DATE,
LastModificationDate DATE
);

CREATE TABLE #ContractNBVInfo
(
ContractId BIGINT,
NBV DECIMAL (16,2)
);

CREATE TABLE #ContractNBVWithBlendedInfo
(
ContractId BIGINT,
NBVWithBlended DECIMAL (16,2)
);

CREATE TABLE #ContractOutstandingARInfo
(
ContractId BIGINT,
OutstandingAR DECIMAL(16,2)
);

CREATE TABLE #ContractIncomeRecognizedAfterNonAccrualInfo
(
ContractId BIGINT,
IncomeRecognized DECIMAL(16,2)
);

CREATE TABLE #ContractDeferredRentalReclassInfo
(
ContractId BIGINT,
DeferredRentalIncome DECIMAL(16,2)
);

CREATE TABLE #ContractLastReceiptDateInfo
(
ContractId BIGINT,
LastReceiptDate DATE
);

CREATE TABLE #ExchangeRateInfo
(
CurrencyId BIGINT,
ExchangeRate DECIMAL(20,10)
);

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
NetInvestment = LF.LoanAmount_Amount,
IsDailySensitive = LF.IsDailySensitive,
HoldingStatus = LF.HoldingStatus,
NonAccrualTemplateId = LE.NonAccrualRuleTemplateId,
Basis = NT.Basis,
MinimumPercentageOfBasis = NT.MinimumPercentageofBasis,
MinimumQualifyingAmount = NT.MinimumQualifyingAmount_Amount,
ThresholdDate = DATEADD(DAY, ISNULL(0 - NT.DaysPastDue, 0), @EffectiveDateForThresholdDate),
DaysPastDueLimit = NT.DaysPastDue,
NonAccrualDateOption = NT.NonAccrualDateOption,
TemplateBillingSuppressed = NT.BillingSuppressed,
ContractReceivableAmendmentType = C.ReceivableAmendmentType
FROM Contracts C
JOIN LoanFinances LF ON C.Id = LF.ContractId AND LF.IsCurrent = 1
JOIN @LegalEntities LES ON LF.LegalEntityId = LES.Id
JOIN LegalEntities LE ON LES.Id = LE.Id
JOIN Customers CU ON LF.CustomerId = CU.Id
JOIN Currencies CUR ON C.CurrencyId = CUR.Id
JOIN CurrencyCodes CC ON CUR.CurrencyCodeId = CC.Id
JOIN Parties P ON CU.Id = P.Id
LEFT JOIN NonAccrualRuleTemplates NT ON LE.NonAccrualRuleTemplateId = NT.Id
WHERE C.ContractType = @LoanContractType
AND C.IsNonAccrualExempt = 0
AND C.BackgroundProcessingPending = 0
AND CU.IsNonAccrualExempt = 0
AND C.SyndicationType NOT IN ('FullSale','ParticipatedSales')
AND C.IsNonAccrual = 0
AND LF.[Status] = 'Commenced'
AND
(
@EntityType = '_'
OR (@EntityType = 'Customer' AND (@FilterOption = 'All' OR CU.Id = @CustomerId))
OR (@EntityType = 'Loan' AND (@FilterOption = 'All' OR C.Id = @ContractId))
);


-- Legal Entities Without Non-Accrual Template - Error Result[0]
SELECT DISTINCT(LegalEntityNumber) AS [Value]
FROM #ContractBasicInfo
WHERE NonAccrualTemplateId IS NULL;

--
DECLARE @DomesticCurrencyId BIGINT = (SELECT TOP 1 C.Id FROM Currencies C
JOIN CurrencyCodes CC ON C.CurrencyCodeId = CC.Id
WHERE C.IsActive = 1 AND CC.ISO = @DefaultCultureCurrency);

SELECT DISTINCT(CurrencyId)
INTO #ForeignCurrencies
FROM #ContractBasicInfo FC
WHERE CurrencyId != @DomesticCurrencyId
AND NonAccrualTemplateId IS NOT NULL;

;WITH CTE_ExchangeRateInfo AS (
SELECT CER.CurrencyId, CER.ExchangeRate, RowNumber = ROW_NUMBER() OVER (PARTITION BY CER.CurrencyId ORDER BY CER.EffectiveDate DESC, Id DESC)
FROM CurrencyExchangeRates CER
JOIN #ForeignCurrencies FC ON CER.CurrencyId = FC.CurrencyId
WHERE CER.ForeignCurrencyId = @DomesticCurrencyId
AND CER.IsActive = 1
AND CER.EffectiveDate <= @EffectiveDateForThresholdDate
)
INSERT INTO #ExchangeRateInfo
SELECT CurrencyId, ExchangeRate FROM CTE_ExchangeRateInfo
WHERE RowNumber = 1;


-- Sending Back Invalid Foreign Currencies 
-- Foreign Currencies With No Exchange Rates Result[1]
SELECT DISTINCT(CC.ISO) AS [Value]
FROM #ForeignCurrencies FC
JOIN Currencies CR ON FC.CurrencyId = CR.Id
JOIN CurrencyCodes CC ON CR.CurrencyCodeId = CC.Id
LEFT JOIN #ExchangeRateInfo ER ON FC.CurrencyId = ER.CurrencyId
WHERE ER.CurrencyId IS NULL;


-----------------------------------------------
INSERT INTO #ExchangeRateInfo VALUES (@DomesticCurrencyId, 1.0);

SELECT CB.*, ExchangeRate = ER.ExchangeRate
INTO #ValidContractsToProcess 
FROM #ContractBasicInfo CB
JOIN #ExchangeRateInfo ER ON CB.CurrencyId = ER.CurrencyId
WHERE CB.NonAccrualTemplateId IS NOT NULL;


SELECT VC.ContractId, ReceivableId = R.Id, PaymentScheduleId = R.PaymentScheduleId, R.DueDate, Amount = R.TotalAmount_Amount, Balance = R.TotalBalance_Amount
INTO #ContractAllReceivables 
FROM #ValidContractsToProcess VC
JOIN NonAccrualRuleReceivableTypes NAR ON VC.NonAccrualTemplateId = NAR.NonAccrualRuleTemplateId AND NAR.IsActive = 1
JOIN ReceivableCodes RC ON NAR.ReceivableTypeId = RC.ReceivableTypeId
JOIN Receivables R ON R.EntityType = @ReceivableContractType AND VC.ContractId = R.EntityId AND R.ReceivableCodeId = RC.Id AND R.IsActive = 1
WHERE R.FunderId IS NULL AND (R.IsDummy = 0 OR VC.IsDSL = 1);

--Base Amount Details
SELECT 
	VC.ContractId, 
	BaseAmount = CASE 
		WHEN (SUM(R.Amount) * (VC.MinimumPercentageOfBasis/100) * VC.ExchangeRate) > VC.MinimumQualifyingAmount 
			THEN (SUM(R.Amount) * (VC.MinimumPercentageOfBasis/100) * VC.ExchangeRate)
		ELSE VC.MinimumQualifyingAmount 
	END
INTO #ContractBaseAmountDetails
FROM #ValidContractsToProcess VC
JOIN #ContractAllReceivables R ON VC.ContractId = R.ContractId AND VC.Basis = 'ReceivableAmount'
GROUP BY VC.ContractId, VC.ExchangeRate, VC.MinimumPercentageOfBasis, VC.MinimumQualifyingAmount;

INSERT INTO #ContractBaseAmountDetails
SELECT 
	ContractId, 
	BaseAmount = CASE 
		WHEN (NetInvestment * (MinimumPercentageOfBasis/100) * ExchangeRate) > MinimumQualifyingAmount
			THEN (NetInvestment * (MinimumPercentageOfBasis/100) * ExchangeRate)
	ELSE MinimumQualifyingAmount END
FROM #ValidContractsToProcess WHERE Basis != 'ReceivableAmount';
--



SELECT VC.ContractId, OutstandingBalance = SUM(R.Balance) * VC.ExchangeRate
INTO #ContractAllOutstandingBalanceInfo
FROM #ValidContractsToProcess VC
JOIN #ContractAllReceivables R ON VC.ContractId = R.ContractId AND R.DueDate <= VC.ThresholdDate
GROUP BY VC.ContractId, VC.ExchangeRate;


SELECT VC.ContractId
INTO #SelectedContracts
FROM #ValidContractsToProcess VC
JOIN #ContractBaseAmountDetails CB ON VC.ContractId = CB.ContractId
JOIN #ContractAllOutstandingBalanceInfo RO ON VC.ContractId = RO.ContractId
WHERE RO.OutstandingBalance != 0 AND RO.OutstandingBalance >= CB.BaseAmount;


INSERT INTO #ContractLastIncomeGLPostedInfo
SELECT
CT.ContractId, MAX(LIS.IncomeDate)
FROM #SelectedContracts CT
JOIN #ValidContractsToProcess VC ON CT.ContractId = VC.ContractId
JOIN LoanFinances LF ON LF.ContractId = CT.ContractId
JOIN LoanIncomeSchedules LIS ON LIS.LoanFinanceId = LF.Id
WHERE LIS.IsAccounting = 1 and LIS.IsGLPosted = 1 and LIS.IsLessorOwned = 1 AND LIS.AdjustmentEntry = 0
GROUP BY CT.ContractId;

;WITH CTE_LoanLastModifiedDate(ContractId,LastModifiedDate)
AS
(
SELECT CT.ContractId,
CASE WHEN LA.AmendmentDate <= CCI.CommencementDate THEN CCI.CommencementDate
WHEN LA.AmendmentType in (@RebookAmendmentType,@SyndicationAmendmentType,@NonAccrualAmendmentType,@ReAccrualAmendmentType,@AssumptionAmendmentType)THEN LA.AmendmentDate
WHEN LA.AmendmentType in (@RestructureAmendmentType,@PayDownAmendmentType) THEN DATEADD(DAY,1,LA.AmendmentDate)
ELSE LA.AmendmentDate END
FROM LoanAmendments LA
JOIN LoanFinances LF ON LA.LoanFinanceId = LF.Id
JOIN #SelectedContracts CT ON LF.ContractId = CT.ContractId
JOIN #ValidContractsToProcess CCI ON CT.ContractId = CCI.ContractId
WHERE LA.QuoteStatus = @AmendmentAppprovedStatus
AND LA.AmendmentType NOT IN (@ReceiptAmendmentType,@GLTransferAmendmentType)
)
INSERT INTO #ContractLastModificationDateInfo
SELECT
CT.ContractId,
MAX(CLM.LastModifiedDate)
FROM #SelectedContracts CT
JOIN #ValidContractsToProcess VC ON CT.ContractId = VC.ContractId
JOIN CTE_LoanLastModifiedDate CLM ON CLM.ContractId = CT.ContractId
GROUP BY CT.ContractId;


SELECT C.ContractId, CR.DueDate, CR.PaymentScheduleId, RowNumber = ROW_NUMBER() OVER (PARTITION BY C.ContractId ORDER BY CR.DueDate, CR.ReceivableId)
INTO #ContractsOrderedWithReceivableDueDate
FROM #SelectedContracts C
JOIN #ContractAllReceivables CR ON C.ContractId = CR.ContractId
WHERE CR.Balance > 0;

INSERT #ContractOutstandingPaymentInfo
SELECT CB.ContractId, LP.StartDate
FROM #ValidContractsToProcess CB
JOIN #ContractsOrderedWithReceivableDueDate CR ON CB.ContractId = CR.ContractId
JOIN LoanPaymentSchedules LP ON CR.PaymentScheduleId = LP.Id AND LP.IsActive = 1
WHERE CR.RowNumber = 1 AND CR.PaymentScheduleId IS NOT NULL AND LP.StartDate IS NOT NULL
AND (NonAccrualDateOption = 'EarliestPaymentDefaultDate' OR NonAccrualDateOption IS NULL);

INSERT #ContractOutstandingPaymentInfo
SELECT ContractLoanOutstandingPaymentInfo.ContractId, ContractLoanOutstandingPaymentInfo.StartDate FROM
(SELECT CB.ContractId, LP.StartDate,RowNumber = ROW_NUMBER() OVER (PARTITION BY CB.ContractId ORDER BY LP.StartDate)
FROM #ValidContractsToProcess CB
JOIN #ContractsOrderedWithReceivableDueDate CR ON CB.ContractId = CR.ContractId
JOIN LoanPaymentSchedules LP ON 
CB.LoanFinanceId = LP.LoanFinanceId AND LP.IsActive = 1
WHERE CR.PaymentScheduleId IS NOT NULL AND LP.StartDate IS NOT NULL
AND NonAccrualDateOption = 'NonAccrualAssessmentDate'
AND DATEADD(DAY, ISNULL(DaysPastDueLimit, 0),CR.DueDate) Between LP.StartDate AND LP.EndDate
) ContractLoanOutstandingPaymentInfo
WHERE ContractLoanOutstandingPaymentInfo.RowNumber = 1;

;WITH LoanOutstandingReceivablesWithoutPaymentScheduleId
AS
(
SELECT CB.ContractId, CR.DueDate, CB.LoanFinanceId,CB.NonAccrualDateOption,CB.DaysPastDueLimit
FROM #ValidContractsToProcess CB
JOIN #ContractsOrderedWithReceivableDueDate CR ON CB.ContractId = CR.ContractId
LEFT JOIN LoanPaymentSchedules LP ON CR.PaymentScheduleId = LP.Id
WHERE CR.RowNumber = 1 AND (CR.PaymentScheduleId IS NULL OR LP.StartDate IS NULL) 
)
SELECT ContractId, LP.StartDate, RO.DueDate, RowNumber = ROW_NUMBER() OVER (PARTITION BY RO.ContractId ORDER BY LP.StartDate)
INTO #LoanOutstandingPaymentStartDateInfo
FROM LoanOutstandingReceivablesWithoutPaymentScheduleId RO
JOIN LoanPaymentSchedules LP ON RO.LoanFinanceId = LP.LoanFinanceId
AND
(
((LP.StartDate <= RO.DueDate) AND (NonAccrualDateOption = 'EarliestPaymentDefaultDate' OR NonAccrualDateOption IS NULL))
OR
((DATEADD(DAY, ISNULL(RO.DaysPastDueLimit, 0),RO.DueDate) BETWEEN LP.StartDate AND LP.EndDate)) AND (NonAccrualDateOption = 'NonAccrualAssessmentDate')
)
WHERE LP.PaymentType = 'FixedTerm' AND LP.IsActive = 1;

MERGE #ContractOutstandingPaymentInfo AS ContractLoanOutstandingPayment
USING (SELECT * FROM #LoanOutstandingPaymentStartDateInfo) AS LoanOutstandingPaymentStartDate
ON (ContractLoanOutstandingPayment.ContractId = LoanOutstandingPaymentStartDate.ContractId 
AND LoanOutstandingPaymentStartDate.RowNumber = 1 AND LoanOutstandingPaymentStartDate.StartDate IS NOT NULL)
WHEN MATCHED THEN
UPDATE SET ContractLoanOutstandingPayment.OutstandingPaymentDate = 
CASE WHEN LoanOutstandingPaymentStartDate.StartDate < ContractLoanOutstandingPayment.OutstandingPaymentDate 
THEN LoanOutstandingPaymentStartDate.StartDate ELSE ContractLoanOutstandingPayment.OutstandingPaymentDate END
WHEN NOT MATCHED THEN
INSERT (ContractId, OutstandingPaymentDate)
Values (LoanOutstandingPaymentStartDate.ContractId, LoanOutstandingPaymentStartDate.StartDate);

INSERT INTO #ContractOutstandingPaymentInfo
SELECT VC.ContractId, VC.CommencementDate
FROM #ValidContractsToProcess VC 
LEFT JOIN #LoanOutstandingPaymentStartDateInfo LOP  ON LOP.ContractId = VC.ContractId
LEFT JOIN #ContractOutstandingPaymentInfo COP ON COP.ContractId = VC.ContractId 
WHERE ((LOP.RowNumber = 1 AND LOP.StartDate IS NULL AND LOP.DueDate < VC.CommencementDate) 
		OR (LOP.ContractId IS NULL))
		AND COP.ContractId is NULL;

INSERT INTO #ContractEstimatedNonAccrualDateInfo (ContractId, NonAccrualDate, LastModificationDate)
SELECT 
	CT.ContractId,
	CASE 
		WHEN (COP.OutstandingPaymentDate IS NULL) AND (CLM.LastModificationDate IS NULL) THEN NULL
		WHEN (COP.OutstandingPaymentDate IS NOT NULL) AND (CLM.LastModificationDate IS NULL) THEN
				CASE 
					WHEN CCI.CommencementDate > COP.OutstandingPaymentDate THEN CCI.CommencementDate 
					ELSE COP.OutstandingPaymentDate 
				END
		WHEN (COP.OutstandingPaymentDate IS NULL) AND (CLM.LastModificationDate IS NOT NULL) THEN CLM.LastModificationDate
		WHEN  (COP.OutstandingPaymentDate IS NOT NULL) AND (CLM.LastModificationDate IS NOT NULL) THEN
				CASE 
					WHEN CLM.LastModificationDate >= COP.OutstandingPaymentDate AND CLM.LastModificationDate >= CCI.CommencementDate THEN CLM.LastModificationDate
					WHEN COP.OutstandingPaymentDate >= CCI.CommencementDate THEN COP.OutstandingPaymentDate
					ELSE CCI.CommencementDate 
				END
		ELSE NULL
	END,
	CLM.LastModificationDate
FROM #SelectedContracts CT
JOIN #ValidContractsToProcess CCI ON CT.ContractId = CCI.ContractId
LEFT JOIN #ContractOutstandingPaymentInfo COP ON CT.ContractId = COP.ContractId
LEFT JOIN #ContractLastModificationDateInfo CLM ON CT.ContractId = CLM.ContractId;

SELECT CN.ContractId, CN.NonAccrualDate, CN.LastModificationDate
INTO #ContractNonAccrualDateInfo
FROM #ContractEstimatedNonAccrualDateInfo CN
JOIN #SelectedContracts C ON CN.ContractId = C.ContractId
JOIN #ValidContractsToProcess VC ON C.ContractId = VC.ContractId 
JOIN LoanPaymentSchedules LP ON VC.LoanFinanceId = LP.LoanFinanceId AND CN.NonAccrualDate = LP.StartDate AND LP.IsActive = 1
WHERE LP.PaymentType IN('FixedTerm');

SELECT
CT.ContractId AS ContractId,
NC.SequenceNumber AS SequenceNumber,
NA.NonAccrualDate AS NonAccrualDate,
NA.LastModificationDate AS LastModificationDate,
NC.CustomerId AS CustomerId,
NC.CustomerNumber AS CustomerNumber,
NC.CustomerName AS CustomerName,
NC.LegalEntityId AS LegalEntityId,
NC.LegalEntityName AS LegalEntityName,
NC.LoanFinanceId AS LoanFinanceId,
NC.CommencementDate AS CommencementDate,
NC.MaturityDate AS MaturityDate,
NC.ContractCurrencyCode AS ContractCurrencyCode,
NC.NetInvestment AS NetInvestment,
NC.IsDSL AS IsDSL,
NC.HoldingStatus AS HoldingStatus,
NC.TemplateBillingSuppressed,
NC.ContractReceivableAmendmentType
INTO #NonAccrualContractInfo
FROM #SelectedContracts CT
JOIN #ValidContractsToProcess NC ON CT.ContractId = NC.ContractId
JOIN #ContractNonAccrualDateInfo NA ON CT.ContractId = NA.ContractId
WHERE NA.NonAccrualDate IS NOT NULL;

-- Last Receipt Date Computation
INSERT INTO #ContractLastReceiptDateInfo
SELECT
CT.ContractId,
MAX(RC.ReceivedDate)
FROM #SelectedContracts CT
JOIN #ContractAllReceivables R ON CT.ContractId = R.ContractId
JOIN ReceivableDetails RD ON R.ReceivableId = RD.ReceivableId
JOIN ReceiptApplicationReceivableDetails RAD ON RD.Id = RAD.ReceivableDetailId
JOIN ReceiptApplications RA ON RAD.ReceiptApplicationId = RA.Id
JOIN Receipts RC ON RA.ReceiptId = RC.Id
WHERE RD.IsActive = 1
AND RAD.IsActive = 1
AND (RC.[Status] = @ReceiptStatusPosted OR RC.[Status] = @ReceiptStatusReadyForPosting)
GROUP BY CT.ContractId;

-- NBV Computation For Loans
SELECT RS.ContractId, IncomeScheduleId = LI.Id, RowNumber = ROW_NUMBER() OVER (PARTITION BY RS.ContractId ORDER BY LI.IncomeDate, LI.Id)
INTO #LoanMinIncomeScheduleInfo
FROM #NonAccrualContractInfo RS
JOIN LoanFinances LF ON RS.ContractId = LF.ContractId
JOIN LoanIncomeSchedules LI ON LF.Id = LI.LoanFinanceId AND RS.NonAccrualDate >= LI.IncomeDate
WHERE LI.IsSchedule = 1 AND LI.IsLessorOwned = 1;

INSERT INTO #ContractNBVInfo
SELECT LIMI.ContractId, LI.BeginNetBookValue_Amount + LI.PrincipalAdded_Amount
FROM #LoanMinIncomeScheduleInfo LIMI
JOIN LoanIncomeSchedules LI ON LIMI.IncomeScheduleId = LI.Id
WHERE LIMI.RowNumber = 1;

-- Outstanding AR Computation
INSERT INTO #ContractOutstandingARInfo
SELECT R.EntityId, SUM(R.TotalBalance_Amount) FROM #NonAccrualContractInfo RS
JOIN Receivables R ON RS.ContractId = R.EntityId AND R.EntityType = @ReceivableContractType AND R.IsActive = 1
JOIN ReceivableCodes RC ON R.ReceivableCodeId = RC.Id
JOIN ReceivableTypes RT ON RC.ReceivableTypeId = RT.Id
JOIN LoanPaymentSchedules LoP ON R.PaymentScheduleId = LoP.Id AND LoP.StartDate < RS.NonAccrualDate
WHERE RT.Name IN ('LoanInterest','LoanPrincipal')
AND (R.IsDummy = 0 OR RS.IsDSL = 1)
GROUP BY R.EntityId;


-- Income Recongized After Non Accrual Date Computation For Loans
INSERT INTO #ContractIncomeRecognizedAfterNonAccrualInfo
SELECT RS.ContractId, SUM(LI.InterestAccrued_Amount)
FROM #NonAccrualContractInfo RS
JOIN LoanFinances LF ON RS.ContractId = LF.ContractId
JOIN LoanIncomeSchedules LI ON LF.Id = LI.LoanFinanceId AND LI.IncomeDate >= RS.NonAccrualDate
WHERE LI.IsAccounting = 1
AND LI.IsGLPosted = 1
AND LI.AdjustmentEntry = 0
AND LI.IsLessorOwned = 1
GROUP BY RS.ContractId;

-- Deferred Rental Reclass Computation For Leases

-- NBV With Blended Computation
SELECT RS.ContractId, RS.CommencementDate, RS.MaturityDate, RS.NonAccrualDate, BI.Id, BI.[Type], BI.BookRecognitionMode, Amount = BI.Amount_Amount
INTO #BlendedItems
FROM #NonAccrualContractInfo RS
JOIN LoanBlendedItems LBI ON RS.LoanFinanceId  = LBI.LoanFinanceId
JOIN BlendedItems BI ON LBI.BlendedItemId = BI.Id AND BI.IsActive = 1AND BI.IsFAS91 = 1
WHERE RS.NonAccrualDate < RS.MaturityDate;

SELECT ContractId, Amount
INTO #BlendedItemBalanceInfo
FROM #BlendedItems
WHERE NonAccrualDate = CommencementDate AND [Type] != 'Income';

INSERT INTO #BlendedItemBalanceInfo
SELECT ContractId, 0.00 - Amount FROM #BlendedItems
WHERE NonAccrualDate = CommencementDate AND [Type] = 'Income';

SELECT BI.Id, BI.ContractId,BI.BookRecognitionMode,BI.Type, BI.Amount, IncomeBalance = SUM(BIS.Income_Amount)
INTO #BlendedIncomeBalances
FROM #BlendedItems BI
JOIN BlendedIncomeSchedules BIS ON BI.Id = BIS.BlendedItemId AND BIS.IsSchedule = 1 AND BIS.IncomeDate <= DATEADD(DAY, -1, BI.NonAccrualDate)
WHERE BI.NonAccrualDate != BI.CommencementDate
GROUP BY BI.Id, BI.ContractId,BI.BookRecognitionMode,BI.Type, BI.Amount;

INSERT INTO #BlendedItemBalanceInfo
SELECT ContractId, (Amount - IncomeBalance)
FROM #BlendedIncomeBalances BIS
WHERE [Type] != 'Income' AND BookRecognitionMode = 'Amortize'

INSERT INTO #BlendedItemBalanceInfo
SELECT ContractId, (Amount - IncomeBalance)
FROM #BlendedIncomeBalances
WHERE [Type] != 'Income' AND BookRecognitionMode != 'Amortize'

INSERT INTO #BlendedItemBalanceInfo
SELECT ContractId, 0.00 - (Amount - IncomeBalance)
FROM #BlendedIncomeBalances
WHERE [Type] = 'Income' AND BookRecognitionMode = 'Amortize'

INSERT INTO #BlendedItemBalanceInfo
SELECT ContractId, 0.00 - (Amount - IncomeBalance)
FROM #BlendedIncomeBalances
WHERE [Type] = 'Income' AND BookRecognitionMode != 'Amortize'

SELECT ContractId, Amount = SUM(Amount)
INTO #ContractBlendedItemBalanceInfo
FROM #BlendedItemBalanceInfo
GROUP BY ContractId;

-- B) Outstanding AR Computation
SELECT RS.ContractId, RS.NonAccrualDate, ReceivableId = R.Id, R.PaymentScheduleId, EffectiveBalance = R.TotalEffectiveBalance_Amount
INTO #ContractReceivablesInfo
FROM #NonAccrualContractInfo RS
JOIN Receivables R ON R.EntityType = 'CT' AND RS.ContractId = R.EntityId AND R.IsActive = 1
JOIN ReceivableCodes RC ON R.ReceivableCodeId = RC.Id
JOIN ReceivableTypes RT ON RC.ReceivableTypeId = RT.Id
WHERE
(R.IsDummy = 0 OR RS.IsDSL = 1) AND RT.Name IN ('LoanInterest','LoanPrincipal');

SELECT CR.ContractId, Amount = CR.EffectiveBalance
INTO #OutstandingReceivablesInfo
FROM #ContractReceivablesInfo CR
JOIN LoanPaymentSchedules LP ON CR.PaymentScheduleId = LP.Id
WHERE LP.StartDate < CR.NonAccrualDate;

INSERT INTO #OutstandingReceivablesInfo
SELECT CR.ContractId, Amount = 0.00 - RARD.AmountApplied_Amount FROM #ContractReceivablesInfo CR
JOIN LoanPaymentSchedules LP ON CR.PaymentScheduleId = LP.Id
JOIN ReceivableDetails RD ON CR.ReceivableId = RD.ReceivableId AND RD.IsActive = 1
JOIN ReceiptApplicationReceivableDetails RARD ON RD.Id = RARD.ReceivableDetailId AND RARD.IsActive = 1
JOIN ReceiptApplications RA ON RARD.ReceiptApplicationId = RA.Id
JOIN Receipts R ON RA.ReceiptId = R.Id
WHERE LP.StartDate >= CR.NonAccrualDate
AND R.[Status] NOT IN ('Inactive','Reversed')
AND R.ReceiptClassification NOT IN ('NonCash','NonAccrualNonDSLNonCash');

SELECT ContractId, Amount = SUM(Amount)
INTO #NBVWithBlended_ContractOutstandingReceivablesInfo
FROM #OutstandingReceivablesInfo
GROUP BY ContractId;

-- NBV With Blended = NBV + A + B + C
INSERT INTO #ContractNBVWithBlendedInfo
SELECT RS.ContractId, NBVWithBlended = ISNULL(CN.NBV, 0.00) + ISNULL(CB.Amount, 0.00) + ISNULL(CR.Amount, 0.00)
FROM #NonAccrualContractInfo RS
LEFT JOIN #ContractNBVInfo CN ON RS.ContractId = CN.ContractId
LEFT JOIN #ContractBlendedItemBalanceInfo CB ON RS.ContractId = CB.ContractId
LEFT JOIN #NBVWithBlended_ContractOutstandingReceivablesInfo CR ON RS.ContractId = CR.ContractId

---
SELECT
ContractId = C.ContractId,
SequenceNumber = C.SequenceNumber,
NonAccrualDate = C.NonAccrualDate,
LastModificationDate = C.LastModificationDate,
CustomerId = C.CustomerId,
CustomerNumber = C.CustomerNumber,
CustomerName = C.CustomerName,
LegalEntityId = C.LegalEntityId,
LegalEntityName = C.LegalEntityName,
LoanFinanceId = C.LoanFinanceId,
CommencementDate = C.CommencementDate,
MaturityDate = C.MaturityDate,
ContractCurrencyCode = C.ContractCurrencyCode,
NetInvestment = C.NetInvestment,
IsDSL = C.IsDSL,
HoldingStatus = C.HoldingStatus,
NBV = ISNULL(CN.NBV, 0.00),
NBVWithBlended = ISNULL(CNB.NBVWithBlended, 0.00),
OutstandingAR = ISNULL(COR.OutstandingAR, 0.00),
IncomeRecognizedAfterNonAccrualDate = ISNULL(CI.IncomeRecognized, 0.00),
DeferredRentalIncomeToReclass = ISNULL(CD.DeferredRentalIncome, 0.00),
LastIncomeUpdateDate = LI.IncomeDate,
LastReceiptDate = LR.LastReceiptDate,
TemplateBillingSuppressed = C.TemplateBillingSuppressed,
ContractReceivableAmendmentType = C.ContractReceivableAmendmentType
FROM #NonAccrualContractInfo C
LEFT JOIN #ContractNBVInfo CN ON C.ContractId = CN.ContractId
LEFT JOIN #ContractNBVWithBlendedInfo CNB ON C.ContractId = CNB.ContractId
LEFT JOIN #ContractOutstandingARInfo COR ON C.ContractId = COR.ContractId
LEFT JOIN #ContractIncomeRecognizedAfterNonAccrualInfo CI ON C.ContractId = CI.ContractId
LEFT JOIN #ContractDeferredRentalReclassInfo CD ON C.ContractId = CD.ContractId
LEFT JOIN #ContractLastIncomeGLPostedInfo LI ON C.ContractId = LI.ContractId
LEFT JOIN #ContractLastReceiptDateInfo LR ON C.ContractId = LR.ContractId;


DROP TABLE #ExchangeRateInfo
DROP TABLE #ContractLastReceiptDateInfo
DROP TABLE #ContractDeferredRentalReclassInfo
DROP TABLE #ContractIncomeRecognizedAfterNonAccrualInfo
DROP TABLE #ContractOutstandingARInfo
DROP TABLE #ContractNBVWithBlendedInfo
DROP TABLE #ContractNBVInfo
DROP TABLE #ContractEstimatedNonAccrualDateInfo
DROP TABLE #ContractLastModificationDateInfo
DROP TABLE #ContractOutstandingPaymentInfo
DROP TABLE #ContractOutstandingReceivableInfo
DROP TABLE #ContractLastIncomeGLPostedInfo
DROP TABLE #ContractBasicInfo
DROP TABLE #ForeignCurrencies
DROP TABLE #ValidContractsToProcess
DROP TABLE #ContractAllReceivables
DROP TABLE #ContractBaseAmountDetails
DROP TABLE #ContractAllOutstandingBalanceInfo
DROP TABLE #SelectedContracts
DROP TABLE #ContractsOrderedWithReceivableDueDate
DROP TABLE #LoanOutstandingPaymentStartDateInfo
DROP TABLE #ContractNonAccrualDateInfo
DROP TABLE #NonAccrualContractInfo
DROP TABLE #LoanMinIncomeScheduleInfo
DROP TABLE #BlendedItems
DROP TABLE #BlendedItemBalanceInfo
DROP TABLE #BlendedIncomeBalances
DROP TABLE #ContractBlendedItemBalanceInfo
DROP TABLE #ContractReceivablesInfo
DROP TABLE #OutstandingReceivablesInfo
DROP TABLE #NBVWithBlended_ContractOutstandingReceivablesInfo

SET NOCOUNT OFF;
END

GO
