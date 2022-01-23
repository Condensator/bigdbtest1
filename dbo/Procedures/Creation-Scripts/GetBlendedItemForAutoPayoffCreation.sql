SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[GetBlendedItemForAutoPayoffCreation]
(
@PayoffInputsForBlendedItemExtract PayoffInputForBlendedItemExtract READONLY,
@ReceivableOnlySundryType NVARCHAR(15),
@ReceivableForTransferApprovedStatus NVARCHAR(20)
)
AS
BEGIN
SET NOCOUNT ON;
CREATE TABLE #BlendedItemsInfo
(
LeaseFinanceId BIGINT,
Id BIGINT,
Name NVARCHAR(40),
Type NVARCHAR(20),
StartDate DATE,
EndDate DATE,
DueDate DATE,
Amount DECIMAL(16,2),
Occurrence NVARCHAR(20),
BookRecognitionMode NVARCHAR(20),
RecognitionMethod NVARCHAR(17),
GeneratePayableOrReceivable BIT,
LeaseAssetId  BIGINT,
IsFAS91 BIT,
AccumulateExpense BIT,
SystemConfigType NVARCHAR(36),
RelatedBlendedItemId BIGINT
);
CREATE TABLE #BlendedBilledReceivablesInfo
(
LeaseFinanceId BIGINT,
BlendedItemId BIGINT,
BilledAmount DECIMAL
);
INSERT INTO #BlendedItemsInfo
SELECT LeaseFinanceId = PIB.LeaseFinanceId,
Id = BI.Id,
Name = BI.Name,
Type = BI.Type,
StartDate = BI.StartDate,
EndDate = BI.EndDate,
DueDate = BI.DueDate,
Amount = BI.Amount_Amount,
Occurrence = BI.Occurrence,
BookRecognitionMode = BI.BookRecognitionMode,
RecognitionMethod = BI.RecognitionMethod,
GeneratePayableOrReceivable = BI.GeneratePayableOrReceivable,
LeaseAssetId = BI.LeaseAssetId,
IsFAS91 = BI.IsFAS91,
AccumulateExpense = BI.AccumulateExpense,
SystemConfigType = BI.SystemConfigType,
RelatedBlendedItemId = BI.RelatedBlendedItemId
FROM @PayoffInputsForBlendedItemExtract PIB
JOIN LeaseFinances LF ON PIB.LeaseFinanceId = LF.Id
JOIN LeaseBlendedItems LB ON LF.Id = LB.LeaseFinanceId
JOIN BlendedItems BI ON LB.BlendedItemId = BI.Id
WHERE BI.IsActive = 1;
INSERT INTO #BlendedItemsInfo
SELECT  LeaseFinanceId = PIB.LeaseFinanceId,
Id = BI.Id,
Name = BI.Name,
Type = BI.Type,
StartDate = BI.StartDate,
EndDate = BI.EndDate,
DueDate = BI.DueDate,
Amount = BI.Amount_Amount,
Occurrence = BI.Occurrence,
BookRecognitionMode = BI.BookRecognitionMode,
RecognitionMethod = BI.RecognitionMethod,
GeneratePayableOrReceivable = BI.GeneratePayableOrReceivable,
LeaseAssetId = BI.LeaseAssetId,
IsFAS91 = BI.IsFAS91,
AccumulateExpense = BI.AccumulateExpense,
SystemConfigType = BI.SystemConfigType,
RelatedBlendedItemId = BI.RelatedBlendedItemId
FROM BlendedItems BI
JOIN ReceivableForTransferBlendedItems RBI ON BI.Id = RBI.BlendedItemId
JOIN ReceivableForTransfers RF ON RBI.ReceivableForTransferId = RF.Id
JOIN LeaseFinances LF ON RF.ContractId = LF.ContractId
JOIN @PayoffInputsForBlendedItemExtract PIB ON LF.Id = PIB.LeaseFinanceId
WHERE RF.ApprovalStatus = @ReceivableForTransferApprovedStatus
AND BI.IsActive = 1
AND PIB.IsSyndicatedServiced = 1;
INSERT INTO #BlendedBilledReceivablesInfo
SELECT LeaseFinanceId = BI.LeaseFinanceId,
BlendedItemId = BI.Id,
BilledAmount = ISNULL(SUM(R.TotalAmount_Amount),0.0)
FROM @PayoffInputsForBlendedItemExtract PIB
JOIN #BlendedItemsInfo BI ON PIB.LeaseFinanceId = BI.LeaseFinanceId
LEFT JOIN BlendedItemDetails BID ON BI.Id = BID.BlendedItemId
LEFT JOIN Sundries S ON BID.SundryId = S.Id
LEFT JOIN Receivables R ON S.ReceivableId = R.Id
WHERE S.Id IS NULL OR (S.SundryType = @ReceivableOnlySundryType
AND S.IsActive = 1
AND S.ReceivableDueDate <= DATEADD(DAY,1,PIB.PayoffEffectiveDate))
AND (R.Id IS NULL OR R.IsActive = 1)
GROUP BY BI.Id,BI.LeaseFinanceId;
SELECT LeaseFinanceId = BI.LeaseFinanceId,
BlendedItemId = BI.Id,
Name = BI.Name,
Type = BI.Type,
Amount = BI.Amount,
StartDate = BI.StartDate,
EndDate = BI.EndDate,
DueDate = BI.DueDate,
Occurence = BI.Occurrence,
BookRecognitionMode = BI.BookRecognitionMode,
RecognitionMethod = BI.RecognitionMethod,
LeaseAssetId = BI.LeaseAssetId,
EarnedIncome = (CASE WHEN (PIB.IsChargedOffLease = 1 AND BI.IsFAS91 = 1) THEN 0.0 ELSE ISNULL(BI.Amount, 0.0) END),
BilledAmount = ISNULL(BRI.BilledAmount,0.0),
IsFAS91 = BI.IsFAS91,
AccumulateExpense = BI.AccumulateExpense,
SystemConfigType = BI.SystemConfigType,
RelatedBlendedItemId = BI.RelatedBlendedItemId
FROM @PayoffInputsForBlendedItemExtract PIB
JOIN #BlendedItemsInfo BI ON PIB.LeaseFinanceId = BI.LeaseFinanceId
LEFT JOIN #BlendedBilledReceivablesInfo BRI ON BI.Id = BRI.BlendedItemId;
DROP TABLE
#BlendedItemsInfo,
#BlendedBilledReceivablesInfo;
END

GO
