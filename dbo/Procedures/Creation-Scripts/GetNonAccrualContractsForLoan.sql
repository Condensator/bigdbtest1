SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[GetNonAccrualContractsForLoan]
(
@ContractIds IdCollection READONLY,
@LeaseContractType NVARCHAR(20),
@ReceivableContractType NVARCHAR(20),
@ReceiptStatusPosted NVARCHAR(20),
@ReceiptStatusReadyForPosting NVARCHAR(20),
@InvoicePreferenceDoNotGenerate NVARCHAR(30),
@ValidReceivableTypes NVARCHAR(MAX),
@FromJob BIT,
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
@IsEdit BIT
)
AS
BEGIN
SET NOCOUNT ON
DECLARE @ReceivableEntityId BIGINT
DECLARE @OutstandingReceivableDueDate DATE
DECLARE	@LoanFinanceId BIGINT
DECLARE @PaymentScheduleStartDate DATE = NULL
CREATE TABLE #LastIncomeGLPostedInfo
(
ContractId BIGINT,
IncomeDate DATE
)
CREATE TABLE #NonAccrualContractInfo
(
ContractId BIGINT,
LegalEntityId BIGINT,
LegalEntityName NVARCHAR(MAX),
LoanFinanceId BIGINT,
CustomerId BIGINT,
CustomerName NVARCHAR(MAX),
CustomerNumber NVARCHAR(MAX),
CommencementDate DATE,
MaturityDate DATE,
NonAccrualDate DATE,
LastIncomeUpdateDate DATE,
ContractCurrencyCode NVARCHAR(MAX),
NetInvestment DECIMAL(16,2),
IsDSL BIT,
HoldingStatus NVARCHAR(30),
IsContractNonAccrualExempt BIT,
IsCustomerNonAccrualExempt BIT
)
CREATE TABLE #ValidReceivableTypes
(
ContractId BIGINT,
ReceivableTypeId BIGINT
)
CREATE TABLE #ContractOutstandingReceivableInfo
(
ContractId BIGINT NOT NULL,
OutstandingReceivableDueDate DATE,
LoanFinanceId BIGINT
)
CREATE TABLE #ContractOutstandingPaymentInfo
(
ContractId BIGINT,
OutstandingPaymentDate DATE
)
CREATE TABLE #ContractLastModificationDateInfo
(
ContractId BIGINT,
LastModificationDate DATE
)
CREATE TABLE #ContractCommencementDateInfo
(
ContractId BIGINT,
CommencementDate DATE
)
CREATE TABLE #ContractNonAccrualDateInfo
(
ContractId BIGINT,
NonAccrualDate DATE,
LastModificationDate DATE
)
CREATE TABLE #ContractLastReceiptDateInfo
(
ContractId BIGINT,
LastReceiptDate DATE
)
SELECT ContractId = Id INTO #SelectedContracts FROM @ContractIds
If @IsEdit = 0
BEGIN
INSERT INTO #LastIncomeGLPostedInfo
SELECT
C.Id, MAX(LIS.IncomeDate)
FROM Contracts C
JOIN #SelectedContracts CT ON C.Id = CT.ContractId
JOIN LoanFinances LF ON LF.ContractId = C.Id
JOIN LoanIncomeSchedules LIS ON LIS.LoanFinanceId = LF.Id
WHERE C.ContractType != @LeaseContractType AND LIS.IsAccounting = 1 and LIS.IsGLPosted = 1 and LIS.IsLessorOwned = 1 AND LIS.AdjustmentEntry = 0
GROUP BY C.Id
IF @FromJob = 1
BEGIN
INSERT INTO #ValidReceivableTypes
SELECT C.Id, RT.Id FROM Contracts C
JOIN #SelectedContracts CT ON C.Id = CT.ContractId
JOIN LoanFinances Loan ON Loan.ContractId = C.Id AND Loan.IsCurrent = 1
JOIN LegalEntities L ON Loan.LegalEntityId = L.Id
JOIN NonAccrualRuleTemplates NT ON L.NonAccrualRuleTemplateId = NT.Id
JOIN NonAccrualRuleReceivableTypes NTR ON NT.Id = NTR.NonAccrualRuleTemplateId
JOIN ReceivableTypes RT ON NTR.ReceivableTypeId = RT.Id
WHERE NT.IsActive = 1
AND NTR.IsActive = 1
AND RT.IsActive = 1
END
ELSE
BEGIN
INSERT INTO #ValidReceivableTypes
SELECT C.Id, RT.Id FROM Contracts C
JOIN #SelectedContracts CT ON C.Id = CT.ContractId
JOIN ReceivableTypes RT ON IsActive = 1
JOIN ConvertCSVToStringTable(@ValidReceivableTypes, ',') VRT ON RT.Name = VRT.Item
END;
INSERT INTO #ContractCommencementDateInfo
SELECT C.Id,
Loan.CommencementDate
FROM Contracts C
JOIN #SelectedContracts CT ON C.Id = CT.ContractId
JOIN LoanFinances Loan ON Loan.ContractId = C.Id AND Loan.IsCurrent = 1;
WITH CTE_LoanLastModifiedDate(ContractId,LastModifiedDate)
AS
(
SELECT C.Id,
CASE WHEN LA.AmendmentDate <= CCI.CommencementDate THEN CCI.CommencementDate
WHEN LA.AmendmentType in (@RebookAmendmentType,@SyndicationAmendmentType,@NonAccrualAmendmentType,@ReAccrualAmendmentType,@AssumptionAmendmentType)THEN LA.AmendmentDate
WHEN LA.AmendmentType in (@RestructureAmendmentType,@PayDownAmendmentType) THEN DATEADD(DAY,1,LA.AmendmentDate)
ELSE LA.AmendmentDate END
FROM LoanAmendments LA
JOIN LoanFinances LF ON LA.LoanFinanceId = LF.Id
JOIN Contracts C ON LF.ContractId = C.Id
JOIN #SelectedContracts CT ON C.Id = CT.ContractId
JOIN #ContractCommencementDateInfo CCI ON C.Id = CCI.ContractId
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
WHERE C.ContractType != @LeaseContractType
GROUP BY C.Id
INSERT INTO #ContractLastReceiptDateInfo
SELECT
C.Id,
MAX(RC.ReceivedDate)
FROM Contracts C
JOIN #SelectedContracts CT ON C.Id = CT.ContractId
JOIN Receivables R ON C.Id = R.EntityId
JOIN ReceivableCodes RecCode ON R.ReceivableCodeId = RecCode.Id
JOIN ReceivableTypes RT ON RecCode.ReceivableTypeId = RT.Id
JOIN #ValidReceivableTypes VRT ON RT.Id = VRT.ReceivableTypeId
JOIN ReceivableDetails RD ON R.Id = RD.ReceivableId
JOIN ReceiptApplicationReceivableDetails RAD ON RD.Id = RAD.ReceivableDetailId
JOIN ReceiptApplications RA ON RAD.ReceiptApplicationId = RA.Id
JOIN Receipts RC ON RA.ReceiptId = RC.Id
WHERE  R.IsActive = 1
AND R.EntityType=@ReceivableContractType
AND R.FunderId IS NULL
AND RD.IsActive = 1
AND RAD.IsActive = 1
AND (RC.Status = @ReceiptStatusPosted OR RC.Status = @ReceiptStatusReadyForPosting)
GROUP BY
C.Id
INSERT INTO #ContractOutstandingReceivableInfo
SELECT
C.Id,
MIN(R.DueDate),
Loan.Id
FROM Contracts C
JOIN #SelectedContracts CT ON C.Id = CT.ContractId
JOIN Receivables R ON C.Id = R.EntityId
JOIN ReceivableCodes RC ON R.ReceivableCodeId = RC.Id
JOIN ReceivableTypes RT ON RC.ReceivableTypeId = RT.Id
JOIN #ValidReceivableTypes VRT ON RT.Id = VRT.ReceivableTypeId
JOIN ReceivableDetails RD ON R.Id = RD.ReceivableId
JOIN LoanFinances Loan ON Loan.ContractId = C.Id AND Loan.IsCurrent = 1
WHERE R.EntityType = @ReceivableContractType
AND R.IsActive = 1
AND R.FunderId IS NULL
AND RD.IsActive = 1
AND RD.Balance_Amount > 0
AND (Loan.Id IS NULL OR Loan.IsDailySensitive = 0 OR R.IsDummy = 1)
GROUP BY C.Id,
Loan.Id,
C.ContractType
DECLARE NonAccrualDateFiller CURSOR LOCAL FOR SELECT * FROM #ContractOutstandingReceivableInfo
OPEN NonAccrualDateFiller
FETCH NEXT FROM NonAccrualDateFiller INTO @ReceivableEntityId, @OutstandingReceivableDueDate, @LoanFinanceId
WHILE @@FETCH_STATUS = 0
BEGIN
SET @PaymentScheduleStartDate = NULL
IF @OutstandingReceivableDueDate IS NOT NULL
BEGIN
SET @PaymentScheduleStartDate = (SELECT MIN(LP.StartDate) FROM Receivables R
JOIN LoanPaymentSchedules LP ON R.PaymentScheduleId = LP.Id
WHERE R.IsActive = 1
AND R.EntityId = @ReceivableEntityId
AND R.EntityType = @ReceivableContractType
AND R.FunderId IS NULL
AND R.DueDate = @OutstandingReceivableDueDate
AND LP.IsActive = 1
AND LP.LoanFinanceId = @LoanFinanceId)
IF @PaymentScheduleStartDate IS NULL
BEGIN
SET @PaymentScheduleStartDate = (SELECT MAX(LP.StartDate) FROM LoanPaymentSchedules LP
WHERE LP.IsActive = 1
AND LP.LoanFinanceId = @LoanFinanceId
AND LP.StartDate <= @OutstandingReceivableDueDate)
END
END
INSERT INTO #ContractOutstandingPaymentInfo VALUES (@ReceivableEntityId, @PaymentScheduleStartDate)
FETCH NEXT FROM NonAccrualDateFiller INTO @ReceivableEntityId, @OutstandingReceivableDueDate, @LoanFinanceId
END
CLOSE NonAccrualDateFiller
DEALLOCATE NonAccrualDateFiller
INSERT INTO #ContractNonAccrualDateInfo
SELECT C.Id,
CASE WHEN (COP.OutstandingPaymentDate IS NULL) AND (CLM.LastModificationDate IS NULL) THEN NULL
WHEN (COP.OutstandingPaymentDate IS NOT NULL) AND (CLM.LastModificationDate IS NULL) THEN
CASE WHEN CCI.CommencementDate > COP.OutstandingPaymentDate THEN CCI.CommencementDate ELSE COP.OutstandingPaymentDate END
WHEN (COP.OutstandingPaymentDate IS NULL) AND (CLM.LastModificationDate IS NOT NULL) THEN CLM.LastModificationDate
WHEN  (COP.OutstandingPaymentDate IS NOT NULL) AND (CLM.LastModificationDate IS NOT NULL) THEN
CASE WHEN CLM.LastModificationDate >= COP.OutstandingPaymentDate AND CLM.LastModificationDate >= CCI.CommencementDate THEN CLM.LastModificationDate
WHEN COP.OutstandingPaymentDate >= CCI.CommencementDate THEN COP.OutstandingPaymentDate
ELSE CCI.CommencementDate END
ELSE NULL
END,
CLM.LastModificationDate
FROM Contracts C
JOIN #SelectedContracts CT ON C.Id = CT.ContractId
JOIN #ContractCommencementDateInfo CCI ON C.Id = CCI.ContractId
LEFT JOIN #ContractOutstandingPaymentInfo COP ON C.Id = COP.ContractId
LEFT JOIN #ContractLastModificationDateInfo CLM ON C.Id = CLM.ContractId
END
INSERT INTO #NonAccrualContractInfo
SELECT
C.Id,
LoanLE.Id,
LoanLE.Name,
Loan.Id,
LoanCustomer.Id,
LoanParty.PartyName,
LoanParty.PartyNumber,
Loan.CommencementDate,
Loan.MaturityDate,
C.NonAccrualDate,
LIG.IncomeDate,
CC.ISO,
Loan.LoanAmount_Amount,
Loan.IsDailySensitive,
Loan.HoldingStatus,
C.IsNonAccrualExempt,
LoanCustomer.IsNonAccrualExempt
FROM Contracts C
JOIN #SelectedContracts CT ON C.Id = CT.ContractId
JOIN LoanFinances Loan ON Loan.ContractId = C.Id AND Loan.IsCurrent = 1
LEFT JOIN #LastIncomeGLPostedInfo LIG ON LIG.ContractId = C.Id
JOIN LegalEntities LoanLE ON Loan.LegalEntityId = LoanLE.Id
JOIN Customers LoanCustomer ON Loan.CustomerId = LoanCustomer.Id 
JOIN Parties LoanParty ON LoanCustomer.Id = LoanParty.Id
JOIN Currencies CU ON C.CurrencyId = CU.Id
JOIN CurrencyCodes CC ON CU.CurrencyCodeId = CC.Id
/* For DSL Loans NonAccrualDate Should be LastReceiptDate OR CommencementDate if LastReceiptDate does not exist */
UPDATE CNADI
SET CNADI.NonAccrualDate = (CASE  WHEN CRI.LastReceiptDate is NULL THEN NACI.CommencementDate ELSE CRI.LastReceiptDate END )
FROM #ContractNonAccrualDateInfo CNADI
LEFT JOIN #NonAccrualContractInfo NACI ON CNADI.ContractId = NACI.ContractId
LEFT JOIN #ContractLastReceiptDateInfo CRI ON CNADI.ContractId = CRI.ContractId
Where NACI.IsDSL = 1
SELECT
C.Id AS ContractId,
NA.LastModificationDate AS LastModificationDate,
RI.LastReceiptDate AS LastReceiptDate,
NC.CustomerId AS CustomerId,
NC.CustomerNumber AS CustomerNumber,
NC.CustomerName AS CustomerName,
NC.LegalEntityId AS LegalEntityId,
NC.LegalEntityName AS LegalEntityName,
NC.LoanFinanceId AS LoanFinanceId,
NC.CommencementDate AS CommencementDate,
NC.MaturityDate AS MaturityDate,
NC.LastIncomeUpdateDate AS LastIncomeUpdateDate,
NC.ContractCurrencyCode AS ContractCurrencyCode,
NC.NetInvestment AS NetInvestment,
NC.IsDSL AS IsDSL,
NC.HoldingStatus AS HoldingStatus,
C.AccountingStandard AS AccountingStandard,
NC.IsContractNonAccrualExempt AS IsContractNonAccrualExempt,
NC.IsCustomerNonAccrualExempt AS IsCustomerNonAccrualExempt,
C.Alias AS ContractAlias,
C.SequenceNumber,
NA.NonAccrualDate AS DefaultLoanNonAccrualDate
FROM Contracts C
JOIN #SelectedContracts CT ON C.Id = CT.ContractId
LEFT JOIN #ContractNonAccrualDateInfo NA ON C.Id = NA.ContractId
LEFT JOIN #ContractLastReceiptDateInfo RI ON C.Id = RI.ContractId
LEFT JOIN #NonAccrualContractInfo NC ON C.Id = NC.ContractId

DROP TABLE
#SelectedContracts,
#LastIncomeGLPostedInfo,
#NonAccrualContractInfo,
#ContractLastModificationDateInfo,
#ValidReceivableTypes,
#ContractCommencementDateInfo,
#ContractOutstandingReceivableInfo,
#ContractOutstandingPaymentInfo,
#ContractNonAccrualDateInfo,
#ContractLastReceiptDateInfo
END

GO
