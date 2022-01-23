SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[UpdateReAccrualContracts]
(
@ContractId ContractIdsInfoRA READONLY,
@LeaseContractType NVARCHAR(20),
@AmendmentAppprovedStatus NVARCHAR(30),
@RestructureAmendmentType NVARCHAR(30),
@RebookAmendmentType NVARCHAR(30),
@SyndicationAmendmentType NVARCHAR(30),
@AssumptionAmendmentType NVARCHAR(30),
@NonAccrualAmendmentType NVARCHAR(30),
@ReAccrualAmendmentType NVARCHAR(30),
@PayoffAmendmentType NVARCHAR(30),
@PayDownAmendmentType NVARCHAR(30),
@ReceiptAmendmentType NVARCHAR(30),
@GLTransferAmendmentType NVARCHAR(20),
@RenewalAmendmentType NVARCHAR(20),
@NBVImpairmentAmendmentType NVARCHAR(20),
@ResidualImpairmentAmendmentType NVARCHAR(20),
@ReceivableContractType NVARCHAR(20),
@ReceiptStatusPosted NVARCHAR(20),
@ReceiptStatusReadyForPosting NVARCHAR(20),
@ValidReceivableTypes NVARCHAR(MAX),
@NonAccrualApprovedStatus NVARCHAR(20)
)
AS
BEGIN
SET NOCOUNT ON
CREATE TABLE #LastIncomeGLPostedInfo
(
IncomeDate DATE,
ContractId BIGINT
)
CREATE TABLE #ReAccrualContractInfo
(
ContractId BIGINT,
LegalEntityId BIGINT,
LegalEntityName NVARCHAR(MAX),
LeaseFinanceId BIGINT,
LoanFinanceId BIGINT,
CustomerId BIGINT,
CustomerName NVARCHAR(MAX),
CustomerNumber NVARCHAR(MAX),
CommencementDate DATE,
MaturityDate DATE,
NonAccrualDate DATE,
LastIncomeUpdateDate DATE,
ContractCurrencyCode NVARCHAR(MAX),
IsLease BIT,
LeaseContractType NVARCHAR(MAX),
NetInvestment DECIMAL(16,2),
LeaseFinanceDetailId BIGINT,
IsDSL BIT,
BillingSuppressed BIT,
HoldingStatus NVARCHAR(30),
LastExtensionARUpdateRunDate DATE NULL,
LastSupplementalARUpdateRunDate DATE NULL
)
CREATE TABLE #ValidReceivableTypes
(
ContractId BIGINT,
ReceivableTypeId BIGINT
)
CREATE TABLE #ContractLastReceiptDateInfo
(
ContractId BIGINT,
LastReceiptDate DATE
)
CREATE TABLE #ContractLastModificationDateInfo
(
ContractId BIGINT,
LastModificationDate DATE
)
CREATE TABLE #ReAccrualDateInfo
(
ContractId BigInt,
ReAccrualDate Date
)
SELECT ContractId = Id INTO #SelectedContracts FROM @ContractId
INSERT INTO #LastIncomeGLPostedInfo
SELECT
MAX(LIS.IncomeDate),
C.Id
FROM Contracts C
JOIN #SelectedContracts CT ON C.Id = CT.ContractId
JOIN LeaseFinances LF ON LF.ContractId = C.Id
JOIN LeaseIncomeSchedules LIS ON LIS.LeaseFinanceId = LF.Id
WHERE LIS.IsAccounting=1 and LIS.IsGLPosted =1 and LIS.IsLessorOwned=1 AND LIS.AdjustmentEntry = 0
GROUP BY
C.Id
INSERT INTO #LastIncomeGLPostedInfo
SELECT
MAX(LIS.IncomeDate),
C.Id
FROM Contracts C
JOIN #SelectedContracts CT ON C.Id = CT.ContractId
JOIN LoanFinances LF ON LF.ContractId = C.Id
JOIN LoanIncomeSchedules LIS ON LIS.LoanFinanceId = LF.Id
WHERE LIS.IsAccounting=1 and LIS.IsGLPosted =1 and LIS.IsLessorOwned=1 AND LIS.AdjustmentEntry = 0
GROUP BY
C.Id
SELECT CT.ContractId, LatestNonAccrualId = MAX(NAC.NonAccrualId) INTO #LatestNonAccrualInfo
FROM #SelectedContracts CT
JOIN NonAccrualContracts NAC ON CT.ContractId = NAC.ContractId AND NAC.IsActive = 1 AND NAC.IsNonAccrualApproved = 1
GROUP BY CT.ContractId
SELECT CT.ContractId, NAC.BillingSuppressed
INTO #NonAccrualBillingSuppressedInfo
FROM #SelectedContracts CT
JOIN #LatestNonAccrualInfo LNA ON CT.ContractId = LNA.ContractId
JOIN NonAccrualContracts NAC ON CT.ContractId = NAC.ContractId AND NAC.NonAccrualId = LNA.LatestNonAccrualId
WHERE NAC.IsActive = 1 AND NAC.IsNonAccrualApproved = 1
INSERT INTO #ReAccrualContractInfo
SELECT
C.Id,
CASE WHEN C.ContractType = @LeaseContractType THEN
LeaseLE.Id ELSE LoanLE.Id END,
CASE WHEN C.ContractType = @LeaseContractType THEN
LeaseLE.Name ELSE LoanLE.Name END,
Lease.Id,
Loan.Id,
CASE WHEN C.ContractType = @LeaseContractType THEN
LeaseCustomer.Id ELSE LoanCustomer.Id END,
CASE WHEN C.ContractType = @LeaseContractType THEN
LeaseParty.PartyName ELSE LoanParty.PartyName END,
CASE WHEN C.ContractType = @LeaseContractType THEN
LeaseParty.PartyNumber ELSE LoanParty.PartyNumber END,
CASE WHEN C.ContractType = @LeaseContractType THEN
LFD.CommencementDate ELSE Loan.CommencementDate END,
CASE WHEN C.ContractType = @LeaseContractType THEN
LFD.MaturityDate ELSE Loan.MaturityDate END,
C.NonAccrualDate,
LIS.IncomeDate,
CC.ISO,
CASE WHEN C.ContractType = @LeaseContractType THEN
1 ELSE 0 END,
CASE WHEN  C.ContractType = @LeaseContractType THEN
LFD.LeaseContractType ELSE null END,
CASE WHEN C.ContractType = @LeaseContractType THEN
LFD.NetInvestment_Amount ELSE Loan.LoanAmount_Amount END,
CASE WHEN C.ContractType = @LeaseContractType THEN
LFD.Id ELSE 0 END,
CASE WHEN C.ContractType = @LeaseContractType THEN
0 ELSE Loan.IsDailySensitive END,
NBS.BillingSuppressed,
CASE WHEN C.ContractType = @LeaseContractType THEN Lease.HoldingStatus ELSE Loan.HoldingStatus END,
LFD.LastExtensionARUpdateRunDate, LFD.LastSupplementalARUpdateRunDate

FROM Contracts C
JOIN #SelectedContracts CT ON C.Id = CT.ContractId
JOIN Currencies CU ON C.CurrencyId = CU.Id
JOIN CurrencyCodes CC ON CU.CurrencyCodeId = CC.Id
JOIN #NonAccrualBillingSuppressedInfo NBS ON C.Id = NBS.ContractId
LEFT JOIN LeaseFinances Lease ON Lease.ContractId = C.Id AND Lease.IsCurrent = 1
LEFT JOIN LeaseFinanceDetails LFD ON Lease.Id = LFD.Id
LEFT JOIN LoanFinances Loan ON Loan.ContractId = C.Id AND Loan.IsCurrent = 1
LEFT JOIN #LastIncomeGLPostedInfo LIS ON LIS.ContractId = C.Id
LEFT JOIN LegalEntities LeaseLE ON  Lease.LegalEntityId = LeaseLE.Id
LEFT JOIN LegalEntities LoanLE ON Loan.LegalEntityId = LoanLE.Id
LEFT JOIN Customers LeaseCustomer ON Lease.CustomerId = LeaseCustomer.Id
LEFT JOIN Customers LoanCustomer ON Loan.CustomerId = LoanCustomer.Id
LEFT JOIN Parties LeaseParty ON LeaseCustomer.Id = LeaseParty.Id
LEFT JOIN Parties LoanParty ON LoanCustomer.Id = LoanParty.Id;
WITH CTE_LeaseLastModifiedDate(ContractId,LastModifiedDate)
AS
(
SELECT C.Id,
CASE WHEN LA.AmendmentDate <= CCI.CommencementDate THEN CCI.CommencementDate
WHEN LA.AmendmentType in (@RebookAmendmentType,@SyndicationAmendmentType,@NonAccrualAmendmentType,@ReAccrualAmendmentType,@AssumptionAmendmentType)THEN LA.AmendmentDate
WHEN LA.AmendmentType in (@RestructureAmendmentType,@PayoffAmendmentType,@RenewalAmendmentType,@NBVImpairmentAmendmentType,@ResidualImpairmentAmendmentType) THEN DATEADD(DAY,1,LA.AmendmentDate)
ELSE LA.AmendmentDate END
FROM LeaseAmendments LA
JOIN LeaseFinances LF ON LA.CurrentLeaseFinanceId = LF.Id
JOIN Contracts C ON LF.ContractId = C.Id
JOIN #SelectedContracts CT ON C.Id = CT.ContractId
JOIN #ReAccrualContractInfo CCI ON C.Id = CCI.ContractId
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
JOIN #ReAccrualContractInfo CCI ON C.Id = CCI.ContractId
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
INSERT INTO #ReAccrualDateInfo
SELECT CLM.ContractId,
CLM.LastModificationDate
FROM #ContractLastModificationDateInfo CLM
LEFT JOIN #LastIncomeGLPostedInfo GLI  ON CLM.ContractId = GLI.ContractId
WHERE (GLI.IncomeDate IS NULL OR GLI.IncomeDate<=CLM.LastModificationDate)
INSERT INTO #ReAccrualDateInfo
SELECT GLI.ContractId,
MIN(LPS.StartDate)
FROM  #ContractLastModificationDateInfo CLM
JOIN #LastIncomeGLPostedInfo GLI ON CLM.ContractId = GLI.ContractId
JOIN LeaseFinances LF ON GLI.ContractId = LF.ContractId AND LF.IsCurrent=1
JOIN LeasePaymentSchedules LP ON GLI.IncomeDate = LP.EndDate AND LP.LeaseFinanceDetailId = LF.Id
LEFT JOIN LeasePaymentSchedules LPS ON LF.Id = LPS.LeaseFinanceDetailId
WHERE GLI.IncomeDate IS NOT NULL
AND GLI.IncomeDate > CLM.LastModificationDate
AND LP.IsActive = 1
AND (LPS.Id IS NULL OR (LPS.IsActive = 1 AND LPS.StartDate > GLI.IncomeDate))
GROUP BY GLI.ContractId
INSERT INTO #ReAccrualDateInfo
SELECT GLI.ContractId,
MAX(LPS.StartDate)
FROM  #ContractLastModificationDateInfo CLM
JOIN #LastIncomeGLPostedInfo GLI ON CLM.ContractId = GLI.ContractId
JOIN LeaseFinances LF ON GLI.ContractId = LF.ContractId AND LF.IsCurrent=1
LEFT JOIN LeasePaymentSchedules LP ON GLI.IncomeDate = LP.EndDate AND LP.LeaseFinanceDetailId = LF.Id AND LP.IsActive = 1
LEFT JOIN LeasePaymentSchedules LPS ON LF.Id = LPS.LeaseFinanceDetailId
WHERE GLI.IncomeDate IS NOT NULL
AND GLI.IncomeDate > CLM.LastModificationDate
AND LP.Id IS NULL
AND (LPS.Id IS NULL OR (LPS.IsActive = 1 AND LPS.StartDate <= GLI.IncomeDate))
GROUP BY GLI.ContractId
INSERT INTO #ReAccrualDateInfo
SELECT GLI.ContractId,
MIN(LPS.StartDate)
FROM  #ContractLastModificationDateInfo CLM
JOIN #LastIncomeGLPostedInfo GLI ON CLM.ContractId = GLI.ContractId
JOIN LoanFinances LF ON GLI.ContractId = LF.ContractId AND LF.IsCurrent=1
JOIN LoanPaymentSchedules LP ON GLI.IncomeDate = LP.EndDate AND LP.LoanFinanceId = LF.Id
LEFT JOIN LoanPaymentSchedules LPS ON LF.Id = LPS.LoanFinanceId
WHERE GLI.IncomeDate IS NOT NULL
AND GLI.IncomeDate > CLM.LastModificationDate
AND LP.IsActive = 1
AND (LPS.Id IS NULL OR (LPS.IsActive = 1 AND LPS.StartDate > GLI.IncomeDate))
GROUP BY GLI.ContractId
INSERT INTO #ReAccrualDateInfo
SELECT GLI.ContractId,
MAX(LPS.StartDate)
FROM  #ContractLastModificationDateInfo CLM
JOIN #LastIncomeGLPostedInfo GLI ON CLM.ContractId = GLI.ContractId
JOIN LoanFinances LF ON GLI.ContractId = LF.ContractId AND LF.IsCurrent=1
LEFT JOIN LoanPaymentSchedules LP ON GLI.IncomeDate = LP.EndDate AND LP.LoanFinanceId = LF.Id AND LP.IsActive = 1
LEFT JOIN LoanPaymentSchedules LPS ON LF.Id = LPS.LoanFinanceId
WHERE GLI.IncomeDate IS NOT NULL
AND GLI.IncomeDate > CLM.LastModificationDate
AND LP.Id IS NULL
AND (LPS.Id IS NULL OR (LPS.IsActive = 1 AND LPS.StartDate <= GLI.IncomeDate))
GROUP BY GLI.ContractId
INSERT INTO #ValidReceivableTypes
SELECT C.Id, RT.Id FROM Contracts C
JOIN #SelectedContracts CT ON C.Id = CT.ContractId
JOIN ReceivableTypes RT ON IsActive = 1
JOIN ConvertCSVToStringTable(@ValidReceivableTypes, ',') VRT ON RT.Name = VRT.Item;
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
SELECT
C.Id AS ContractId,
RAD.ReAccrualDate AS ReAccrualDate,
CLM.LastModificationDate AS LastModificationDate,
RI.LastReceiptDate AS LastReceiptDate,
RC.CustomerId AS CustomerId,
RC.CustomerNumber AS CustomerNumber,
RC.CustomerName AS CustomerName,
RC.LegalEntityId AS LegalEntityId,
RC.LegalEntityName AS LegalEntityName,
RC.LeaseFinanceId AS LeaseFinanceId,
RC.LoanFinanceId AS LoanFinanceId,
RC.NonAccrualDate AS NonAccrualDate,
RC.CommencementDate AS CommencementDate,
RC.MaturityDate AS MaturityDate,
RC.LastIncomeUpdateDate AS LastIncomeUpdateDate,
RC.ContractCurrencyCode AS ContractCurrencyCode,
RC.IsLease AS IsLease,
RC.LeaseContractType AS LeaseContractType,
RC.NetInvestment AS NetInvestment,
RC.LeaseFinanceDetailId AS LeaseFinanceDetailId,
RC.IsDSL AS IsDSL,
RC.BillingSuppressed AS BillingSuppressed,
RC.HoldingStatus AS HoldingStatus,
RC.LastExtensionARUpdateRunDate AS LastExtensionARUpdateRunDate,
RC.LastSupplementalARUpdateRunDate AS LastSupplementalARUpdateRunDate
FROM Contracts C
JOIN #SelectedContracts CT ON C.Id = CT.ContractId
LEFT JOIN #ContractLastModificationDateInfo CLM ON C.Id = CLM.ContractId
LEFT JOIN #ContractLastReceiptDateInfo RI ON C.Id = RI.ContractId
LEFT JOIN #ReAccrualDateInfo RAD ON C.Id = RAD.ContractId
LEFT JOIN #ReAccrualContractInfo RC ON C.Id  = RC.ContractId
DROP TABLE
#SelectedContracts,
#LastIncomeGLPostedInfo,
#ReAccrualContractInfo,
#ValidReceivableTypes,
#ContractLastReceiptDateInfo,
#ContractLastModificationDateInfo,
#ReAccrualDateInfo,
#NonAccrualBillingSuppressedInfo,
#LatestNonAccrualInfo
END

GO
