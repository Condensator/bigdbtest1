SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[GetGLTransferContractInfo]
@EffectiveDate DATE,
@ContractIds ContractIdCollection READONLY
AS
BEGIN
SET NOCOUNT ON;
DECLARE @SQL NVARCHAR(MAX) ='';
CREATE TABLE #ContractSummary
(
ContractId BIGINT,
SequenceNumber NVARCHAR(40),
ContractType NVARCHAR(14),
ChargeOffStatus NVARCHAR(10),
HoldingStatus NVARCHAR(15),
CurrencyId BIGINT,
CurrencyCode NVARCHAR(3),
LeaseApprovalStatus NVARCHAR(25),
LoanApprovalStatus NVARCHAR(25),
LeaseContractType NVARCHAR(16),
IsRecoveryContract BIT,
LeaseFinanceId BIGINT,
LoanFinanceId BIGINT,
LeveragedLeaseFinanceId BIGINT,
LegalEntityId BIGINT,
RemitToId BIGINT,
LegalEntityNumber NVARCHAR(20),
LineOfBusinessId BIGINT,
LineOfBusiness NVARCHAR(40),
CostCenterId BIGINT,
CostCenter NVARCHAR(80),
TransactionType NVARCHAR(32),
ProductType NVARCHAR(40),
InstrumentTypeId BIGINT,
InstrumentTypeName NVARCHAR(40),
AcquisitionId NVARCHAR(48),
GLSegmentValue NVARCHAR(24),
TransactionTypeGLSegmentValue NVARCHAR(12),
BQNBQ NVARCHAR(16),
IsSOPStatus BIT,
OriginatingLineOfBusiness NVARCHAR(40),
OriginatingLineOfBusinessId BIGINT,
CommencementDate DATE,
MaturityDate DATE,
BranchCostCenter NVARCHAR(40),
BranchId BIGINT,
BranchName NVARCHAR(40),
AccountingStandard NVARCHAR(12),
IsTaxLease BIT,
RemitToName NVARCHAR(80)
);
SELECT ContractId INTO #ContractIds FROM @ContractIds
SELECT
Contracts.Id AS ContractId,
Contracts.SequenceNumber,
Contracts.ContractType,
Contracts.CurrencyId,
CurrencyCodes.ISO AS CurrencyCode,
Contracts.RemitToId AS RemitToId,
LineofBusinesses.Id AS LineOfBusinessId,
LineofBusinesses.Name AS LineOfBusiness,
Contracts.CostCenterId,
CostCenterConfigs.CostCenter,
DealProductTypes.Name AS TransactionType,
DealTypes.ProductType AS ProductType,
Contracts.ChargeOffStatus AS ChargeOffStatus,
DealProductTypes.GLSegmentValue AS TransactionTypeGLSegmentValue,
Contracts.AccountingStandard
INTO #ContractInfo
FROM Contracts
JOIN #ContractIds ON Contracts.Id = #ContractIds.ContractId
JOIN LineofBusinesses ON Contracts.LineofBusinessId = LineofBusinesses.Id
JOIN CostCenterConfigs ON Contracts.CostCenterId = CostCenterConfigs.Id
JOIN DealTypes ON Contracts.DealTypeId = DealTypes.Id
JOIN DealProductTypes ON Contracts.DealProductTypeId = DealProductTypes.Id
JOIN Currencies ON Contracts.CurrencyId = Currencies.Id
JOIN CurrencyCodes ON Currencies.CurrencyCodeId = CurrencyCodes.Id
IF EXISTS(SELECT 1 FROM #ContractInfo WHERE ContractType = 'LeveragedLease')
SET @SQL = @SQL + '
INSERT INTO #ContractSummary
SELECT
#ContractInfo.ContractId,
#ContractInfo.SequenceNumber,
#ContractInfo.ContractType,
#ContractInfo.ChargeOffStatus,
LeveragedLeases.HoldingStatus,
#ContractInfo.CurrencyId,
#ContractInfo.CurrencyCode,
NULL,
NULL,
NULL,
0,
NULL,
NULL,
LeveragedLeases.Id AS LeveragedLeaseFinanceId,
LegalEntities.Id AS LegalEntityId,
#ContractInfo.RemitToId,
LegalEntities.LegalEntityNumber AS LegalEntityNumber,
#ContractInfo.LineOfBusinessId,
#ContractInfo.LineOfBusiness,
#ContractInfo.CostCenterId,
#ContractInfo.CostCenter,
#ContractInfo.TransactionType,
#ContractInfo.ProductType,
InstrumentTypes.Id AS InstrumentTypeId,
InstrumentTypes.Code AS InstrumentTypeName,
LeveragedLeases.AcquisitionId,
LegalEntities.GLSegmentValue,
#ContractInfo.TransactionTypeGLSegmentValue,
NULL,
0,
OriginatingLineOfBusiness.Name AS OriginatingLineOfBusiness,
OriginatingLineOfBusiness.Id AS OriginatingLineOfBusinessId,
LeveragedLeases.CommencementDate,
LeveragedLeases.MaturityDate,
NULL,
Null,
Null,
#ContractInfo.AccountingStandard,
0,
RemitToes.Name AS RemitToName
FROM #ContractInfo
JOIN LeveragedLeases ON #ContractInfo.ContractId = LeveragedLeases.ContractId
JOIN LegalEntities ON LeveragedLeases.LegalEntityId = LegalEntities.Id
LEFT JOIN InstrumentTypes ON LeveragedLeases.InstrumentTypeId = InstrumentTypes.Id
JOIN ContractOriginations ON LeveragedLeases.ContractOriginationId = ContractOriginations.Id
LEFT JOIN LineofBusinesses OriginatingLineOfBusiness ON ContractOriginations.OriginatingLineOfBusinessId = OriginatingLineOfBusiness.Id
LEFT JOIN RemitToes ON #ContractInfo.RemitToId = RemitToes.Id
WHERE #ContractInfo.ContractType = ''LeveragedLease'' AND LeveragedLeases.IsCurrent=1;'
IF EXISTS(SELECT 1 FROM #ContractInfo WHERE ContractType = 'Lease')
SET @SQL = @SQL + '
INSERT INTO #ContractSummary
SELECT
#ContractInfo.ContractId,
#ContractInfo.SequenceNumber,
#ContractInfo.ContractType,
#ContractInfo.ChargeOffStatus,
LeaseFinances.HoldingStatus,
#ContractInfo.CurrencyId,
#ContractInfo.CurrencyCode,
LeaseFinances.ApprovalStatus AS LeaseApprovalStatus,
NULL,
LeaseFinanceDetails.LeaseContractType,
LeaseFinances.IsRecoveryContract,
LeaseFinances.Id AS LeaseFinanceId,
NULL,
NULL,
LegalEntities.Id AS LegalEntityId,
#ContractInfo.RemitToId,
LegalEntities.LegalEntityNumber AS LegalEntityNumber,
#ContractInfo.LineOfBusinessId,
#ContractInfo.LineOfBusiness,
#ContractInfo.CostCenterId,
#ContractInfo.CostCenter,
#ContractInfo.TransactionType,
#ContractInfo.ProductType,
InstrumentTypes.Id AS InstrumentTypeId,
InstrumentTypes.Code AS InstrumentTypeName,
LeaseFinances.AcquisitionId,
LegalEntities.GLSegmentValue,
#ContractInfo.TransactionTypeGLSegmentValue,
LeaseFinances.BankQualified as BQNBQ,
0,
OriginatingLineOfBusiness.Name AS OriginatingLineOfBusiness,
OriginatingLineOfBusiness.Id AS OriginatingLineOfBusinessId,
LeaseFinanceDetails.CommencementDate,
LeaseFinanceDetails.MaturityDate,
Branches.CostCenter,
LeaseFinances.BranchId,
Branches.BranchName,
#ContractInfo.AccountingStandard,
LeaseFinanceDetails.IsTaxLease,
RemitToes.Name AS RemitToName
FROM #ContractInfo
JOIN LeaseFinances ON #ContractInfo.ContractId = LeaseFinances.ContractId
JOIN LeaseFinanceDetails ON LeaseFinances.Id = LeaseFinanceDetails.Id
JOIN LegalEntities ON LeaseFinances.LegalEntityId = LegalEntities.Id
LEFT JOIN InstrumentTypes ON LeaseFinances.InstrumentTypeId = InstrumentTypes.Id
JOIN ContractOriginations ON LeaseFinances.ContractOriginationId = ContractOriginations.Id
JOIN LineofBusinesses AS OriginatingLineOfBusiness ON ContractOriginations.OriginatingLineOfBusinessId = OriginatingLineOfBusiness.Id
LEFT JOIN Branches ON LeaseFinances.BranchId = Branches.Id
LEFT JOIN RemitToes ON #ContractInfo.RemitToId = RemitToes.Id
WHERE #ContractInfo.ContractType = ''Lease'' AND LeaseFinances.IsCurrent=1;'
IF EXISTS(SELECT 1 FROM #ContractInfo WHERE ContractType IN ('Loan','ProgressLoan'))
SET @SQL = @SQL + '
INSERT INTO #ContractSummary
SELECT
#ContractInfo.ContractId,
#ContractInfo.SequenceNumber,
#ContractInfo.ContractType,
#ContractInfo.ChargeOffStatus,
LoanFinances.HoldingStatus,
#ContractInfo.CurrencyId,
#ContractInfo.CurrencyCode,
NULL,
LoanFinances.ApprovalStatus AS LoanApprovalStatus,
NULL,
LoanFinances.IsRecoveryContract,
NULL,
LoanFinances.Id AS LoanFinanceId,
NULL,
LegalEntities.Id AS LegalEntityId,
#ContractInfo.RemitToId,
LegalEntities.LegalEntityNumber AS LegalEntityNumber,
#ContractInfo.LineOfBusinessId,
#ContractInfo.LineOfBusiness,
#ContractInfo.CostCenterId,
#ContractInfo.CostCenter,
#ContractInfo.TransactionType,
#ContractInfo.ProductType,
InstrumentTypes.Id AS InstrumentTypeId,
InstrumentTypes.Code AS InstrumentTypeName,
LoanFinances.AcquisitionId,
LegalEntities.GLSegmentValue,
#ContractInfo.TransactionTypeGLSegmentValue,
LoanFinances.BankQualified as BQNBQ,
LoanFinances.IsSOPStatus,
OriginatingLineOfBusiness.Name AS OriginatingLineOfBusiness,
OriginatingLineOfBusiness.Id AS OriginatingLineOfBusinessId,
LoanFinances.CommencementDate,
LoanFinances.MaturityDate,
Branches.CostCenter,
LoanFinances.BranchId,
Branches.BranchName,
#ContractInfo.AccountingStandard,
0,
RemitToes.Name AS RemitToName
FROM #ContractInfo
JOIN LoanFinances ON #ContractInfo.ContractId = LoanFinances.ContractId
JOIN LegalEntities ON LoanFinances.LegalEntityId = LegalEntities.Id
LEFT JOIN InstrumentTypes ON LoanFinances.InstrumentTypeId = InstrumentTypes.Id
JOIN ContractOriginations ON LoanFinances.ContractOriginationId = ContractOriginations.Id
JOIN LineofBusinesses AS OriginatingLineOfBusiness ON ContractOriginations.OriginatingLineOfBusinessId = OriginatingLineOfBusiness.Id
LEFT JOIN Branches ON LoanFinances.BranchId = Branches.Id
LEFT JOIN RemitToes ON #ContractInfo.RemitToId = RemitToes.Id
WHERE #ContractInfo.ContractType IN (''Loan'',''ProgressLoan'') AND LoanFinances.IsCurrent=1;'
EXEC SP_EXECUTESQL @SQL;
SELECT * FROM #ContractSummary
DROP TABLE #ContractInfo
,#ContractIds
,#ContractSummary
SET NOCOUNT OFF;
END

GO
