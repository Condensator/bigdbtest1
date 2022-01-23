SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[GetReceivableUpfrontOnCostDetail]
(
@ReceivableAssetTable ReceivableAssetTableType READONLY
)
AS
BEGIN
SET NOCOUNT ON;
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
SELECT * INTO #ReceivableAssetTable FROM @ReceivableAssetTable
CREATE INDEX IX_AssetId ON #ReceivableAssetTable(AssetId)
CREATE TABLE #ContractDetails
(
ContractId					 BIGINT,
SyndicationType				NVARCHAR(100),
PaymentScheduleId			BIGINT,
IncomeDate					DATE,
BeginNBVAmount				DECIMAL(16,2),
AssetId						BIGINT,
AssetNBVAmount				DECIMAL(16,2),
TotalNBVAmount				DECIMAL(16,2),
AssetBeginNBVAmount			DECIMAL(16,2),
LeaseFinanceId				BIGINT,
ReceivableId				BIGINT,
DueDate						DATE,
ClassificationContractType	NVARCHAR(100)
)
;
--_ucReceivableInfo
SELECT
R.DueDate,
RD.AssetId,
RD.ReceivableId,
R.EntityId ContractId,
R.CustomerId CustomerId,
RD.Id ReceivableDetailId,
RD.AdjustmentBasisReceivableDetailId
FROM Receivables R
JOIN ReceivableDetails RD ON R.Id = RD.ReceivableId
JOIN ReceivableCodes RC ON R.ReceivableCodeId = RC.Id
JOIN ReceivableTypes RT ON RC.ReceivableTypeId = RT.Id
JOIN @ReceivableAssetTable CBRD ON RD.AssetId = CBRD.AssetId
WHERE RT.IsRental = 1 AND CBRD.AssetId IS NOT NULL AND R.IsActive = 1 AND R.PaymentScheduleId IS NOT NULL AND RT.Name != 'LeaseInterimInterest'
--_ucReceivableValue
INSERT INTO #ContractDetails
(ContractId, SyndicationType, PaymentScheduleId, IncomeDate, BeginNBVAmount, AssetId, AssetNBVAmount,
ReceivableId, DueDate, ClassificationContractType,TotalNBVAmount, AssetBeginNBVAmount, LeaseFinanceId)
SELECT DISTINCT
R.EntityId, CT.SyndicationType, R.PaymentScheduleId LeasePaymentId, LIS.IncomeDate,
CASE WHEN LFD.ClassificationContractType = 'Operating' THEN
LIS.OperatingBeginNetBookValue_Amount
ELSE LIS.BeginNetBookValue_Amount END,
LA.AssetId, LA.NBV_Amount, RAT.ReceivableId,
R.DueDate, ClassificationContractType,
0.00, 0.00, LF.Id
FROM #ReceivableAssetTable RAT
JOIN Receivables R ON RAT.ReceivableId = R.Id
JOIN Contracts CT ON R.EntityId = CT.Id AND CT.SyndicationType = 'FullSale' AND CT.ContractType = 'Lease'
JOIN LeaseFinances LF ON CT.Id = LF.ContractId
JOIN LeaseFinanceDetails LFD ON LF.Id = LFD.Id
JOIN LeasePaymentSchedules LPS ON R.PaymentScheduleId = LPS.Id
JOIN LeaseAssets LA ON LF.Id = LA.LeaseFinanceId AND RAT.AssetId = LA.AssetId
JOIN LeaseIncomeSchedules LIS ON LF.Id = LIS.LeaseFinanceId
AND LIS.IncomeDate = (CASE WHEN LFD.NumberOfInceptionPayments > 0 THEN LPS.DueDate ELSE  LPS.EndDate END)
IF EXISTS (SELECT * FROM #ContractDetails)
BEGIN
SELECT LA.LeaseFinanceId, SUM(LA.NBV_Amount) TotalNBVAmount INTO #LeaseAssetNBV FROM
(
SELECT DISTINCT LA.LeaseFinanceId, LA.AssetId, (LA.NBV_Amount) NBV_Amount FROM LeaseAssets LA
JOIN #ContractDetails CD ON LA.LeaseFinanceId = CD.LeaseFinanceId
) AS LA
GROUP BY LA.LeaseFinanceId
UPDATE #ContractDetails
SET TotalNBVAmount = LA.TotalNBVAmount,
AssetBeginNBVAmount = (CD.AssetNBVAmount/LA.TotalNBVAmount) * CD.BeginNBVAmount
FROM #ContractDetails CD JOIN #LeaseAssetNBV LA ON CD.LeaseFinanceId = LA.LeaseFinanceId
END
SELECT
R.DueDate,
AIS.AssetId,
R.Id ReceivableId,
AIS.BeginNetBookValue_Amount BeginNetBookValueAmount,
AIS.OperatingBeginNetBookValue_Amount OperatingBeginNetBookValueAmount,
LFD.ClassificationContractType
FROM AssetIncomeSchedules AIS
JOIN LeaseIncomeSchedules LIS ON AIS.LeaseIncomeScheduleId = LIS.Id
JOIN LeaseFinances ON LIS.LeaseFinanceId = LeaseFinances.Id
JOIN LeaseFinanceDetails ON LeaseFinances.Id = LeaseFinanceDetails.Id
JOIN LeasePaymentSchedules LPS ON LIS.IncomeDate = (CASE WHEN LeaseFinanceDetails.NumberOfInceptionPayments > 0 THEN LPS.DueDate ELSE  LPS.EndDate END)
JOIN Receivables R ON LPS.Id = R.PaymentScheduleId
JOIN ReceivableDetails RD ON RD.ReceivableId = R.Id
JOIN #ReceivableAssetTable RAT ON RAT.AssetId = RD.AssetId AND RD.ReceivableId = RAT.ReceivableId
JOIN LeaseFinanceDetails LFD ON LIS.LeaseFinanceId = LFD.Id
WHERE AIS.IsActive = 1 AND LPS.IsActive = 1 AND AIS.AssetId = RAT.AssetId
UNION
SELECT
DueDate,
AssetId,
ReceivableId,
CASE WHEN ClassificationContractType = 'Operating' THEN CAST(0.00 AS DECIMAL(16,2)) ELSE AssetBeginNBVAmount END AS BeginNetBookValueAmount,
CASE WHEN ClassificationContractType = 'Operating' THEN AssetBeginNBVAmount ELSE CAST(0.00 AS DECIMAL(16,2)) END AS OperatingBeginNetBookValueAmount,
ClassificationContractType
FROM #ContractDetails
;
END

GO
