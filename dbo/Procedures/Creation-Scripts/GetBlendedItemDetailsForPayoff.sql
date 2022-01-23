SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROC [dbo].[GetBlendedItemDetailsForPayoff]
(
@LeaseFinanceId BIGINT,
@ForLeaseLevel BIT,
@LeaseAssetIds BlendedItemLeaseAssetInfo READONLY,
@BlendedItemIds BlendedItemTypeInfo READONLY,
@ForBlendedItemsOnly BIT,
@PayoffEffectiveDate DATE = NULL,
@ReceivableOnlySundryType NVARCHAR(15),
@AccreteRecognitionMode NVARCHAR(10),
@AmortizeRecognitionMode NVARCHAR(10),
@CapitalizeRecognitionMode NVARCHAR(10),
@RecognizeImmediately NVARCHAR(20),
@IsChargedOffLease BIT,
@IsFullPayoff BIT,
@ReceivableForTransferApprovedStatus NVARCHAR(20),
@IsSyndicationServiced BIT,
@IsPayoffAtInception BIT,
@ApprovedReAccrualStatus NVARCHAR(15)
)
AS
BEGIN
SET NOCOUNT ON
SELECT * INTO #LeaseAssetIds FROM @LeaseAssetIds
SELECT * INTO #BlendedItemIds FROM @BlendedItemIds
CREATE TABLE #BlendedIncomesInfo
(
BlendedItemId BIGINT,
EarnedIncome DECIMAL(16,2)
)
CREATE TABLE #BlendedItemsInfo
(
Id BIGINT,
Name NVARCHAR(50),
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
)


CREATE CLUSTERED INDEX IX_BlendedItemsInfo ON #BlendedItemsInfo (Id)

CREATE TABLE #ReAccrualCatchupInfo
(
BlendedItemId BIGINT,
CatchupAmount DECIMAL(16,2)
);

CREATE TABLE #ReAccrualDateInfo
(
ContractId BIGINT,
NonAccrualDate DATETIME,
ReAccrualDate DATETIME
);

If @ForBlendedItemsOnly=1
BEGIN
	INSERT INTO #BlendedItemsInfo
	SELECT BI.Id, BI.Name, BI.Type, BI.StartDate, BI.EndDate, BI.DueDate, Amount= BI.Amount_Amount, BI.Occurrence,
	BI.BookRecognitionMode, BI.RecognitionMethod, BI.GeneratePayableOrReceivable, BI.LeaseAssetId,BI.IsFAS91, BI.AccumulateExpense, BI.SystemConfigType,BI.RelatedBlendedItemId
	FROM BlendedItems BI
	JOIN #BlendedItemIds BII ON BI.Id = BII.ID
END
ELSE
BEGIN
	IF @IsFullPayoff=1
	BEGIN
		INSERT INTO #BlendedItemsInfo
		SELECT BI.Id, BI.Name, BI.Type, BI.StartDate, BI.EndDate, BI.DueDate, Amount= BI.Amount_Amount, BI.Occurrence,
		BI.BookRecognitionMode, BI.RecognitionMethod, BI.GeneratePayableOrReceivable, BI.LeaseAssetId,BI.IsFAS91, BI.AccumulateExpense, BI.SystemConfigType,BI.RelatedBlendedItemId
		FROM LeaseFinances LF
		JOIN LeaseBlendedItems LBI ON LF.Id = LBI.LeaseFinanceId
		JOIN BlendedItems BI ON LBI.BlendedItemId = BI.Id 
		WHERE LF.Id = @LeaseFinanceId
		AND	BI.IsActive = 1

		IF @IsSyndicationServiced=1
		BEGIN
			INSERT INTO #BlendedItemsInfo
			SELECT BI.Id, BI.Name, BI.Type, BI.StartDate, BI.EndDate, BI.DueDate, Amount= BI.Amount_Amount, BI.Occurrence,
			BI.BookRecognitionMode, BI.RecognitionMethod, BI.GeneratePayableOrReceivable, BI.LeaseAssetId,BI.IsFAS91, BI.AccumulateExpense, BI.SystemConfigType,BI.RelatedBlendedItemId
			FROM LeaseFinances LF
			JOIN ReceivableForTransfers RF ON LF.ContractId = RF.ContractId
			JOIN ReceivableForTransferBlendedItems RBI ON RF.Id = RBI.ReceivableForTransferId
			JOIN BlendedItems BI ON RBI.BlendedItemId = BI.Id
			WHERE LF.Id = @LeaseFinanceId
			AND RF.ApprovalStatus = @ReceivableForTransferApprovedStatus
			AND	BI.IsActive = 1
		END
	END
	ELSE
	BEGIN
		IF @ForLeaseLevel =1
		BEGIN
			INSERT INTO #BlendedItemsInfo
			SELECT BI.Id, BI.Name, BI.Type, BI.StartDate, BI.EndDate, BI.DueDate, Amount= BI.Amount_Amount, BI.Occurrence,
			BI.BookRecognitionMode, BI.RecognitionMethod, BI.GeneratePayableOrReceivable, BI.LeaseAssetId,BI.IsFAS91, BI.AccumulateExpense, BI.SystemConfigType,BI.RelatedBlendedItemId
			FROM LeaseFinances LF
			JOIN LeaseBlendedItems LBI ON LF.Id = LBI.LeaseFinanceId
			JOIN BlendedItems BI ON LBI.BlendedItemId = BI.Id 
			WHERE LF.Id = @LeaseFinanceId
			AND	BI.IsActive = 1
			AND BI.LeaseAssetId IS NULL

			IF @IsSyndicationServiced=1
			BEGIN
				INSERT INTO #BlendedItemsInfo
				SELECT BI.Id, BI.Name, BI.Type, BI.StartDate, BI.EndDate, BI.DueDate, Amount= BI.Amount_Amount, BI.Occurrence,
				BI.BookRecognitionMode, BI.RecognitionMethod, BI.GeneratePayableOrReceivable, BI.LeaseAssetId,BI.IsFAS91, BI.AccumulateExpense, BI.SystemConfigType,BI.RelatedBlendedItemId
				FROM LeaseFinances LF
				JOIN ReceivableForTransfers RF ON LF.ContractId = RF.ContractId
				JOIN ReceivableForTransferBlendedItems RBI ON RF.Id = RBI.ReceivableForTransferId
				JOIN BlendedItems BI ON RBI.BlendedItemId = BI.Id
				WHERE LF.Id = @LeaseFinanceId
				AND RF.ApprovalStatus = @ReceivableForTransferApprovedStatus
				AND	BI.IsActive = 1
			END
		END

		INSERT INTO #BlendedItemsInfo
		SELECT BI.Id, BI.Name, BI.Type, BI.StartDate, BI.EndDate, BI.DueDate, Amount= BI.Amount_Amount, BI.Occurrence,
		BI.BookRecognitionMode, BI.RecognitionMethod, BI.GeneratePayableOrReceivable, BI.LeaseAssetId,BI.IsFAS91, BI.AccumulateExpense, BI.SystemConfigType,BI.RelatedBlendedItemId
		FROM LeaseFinances LF
		JOIN LeaseBlendedItems LBI ON LF.Id = LBI.LeaseFinanceId
		JOIN BlendedItems BI ON LBI.BlendedItemId = BI.Id 
		JOIN #LeaseAssetIds LAI ON BI.LeaseAssetId = LAI.ID
		WHERE LF.Id = @LeaseFinanceId
		AND	BI.IsActive = 1
	END
END

CREATE TABLE #BlendedIncomeScheduleInfo
(
BlendedItemId BIGINT,
LeaseFinanceId BIGINT,
Income_Amount DECIMAL(16,2),
IncomeBalance_Amount DECIMAL(16,2),
IncomeDate Date,
AdjustmentEntry BIT,
IsNonAccrual BIT,
IsFAS91 BIT
)
CREATE CLUSTERED INDEX IX_BlendedIncomeScheduleInfo ON #BlendedIncomeScheduleInfo (BlendedItemId)

INSERT INTO #BlendedIncomeScheduleInfo
SELECT
BIS.BlendedItemId,
BIS.LeaseFinanceId,
BIS.Income_Amount,
BIS.IncomeBalance_Amount,
BIS.IncomeDate,
BIS.AdjustmentEntry,
BIS.IsNonAccrual,
BIInfo.IsFAS91
FROM #BlendedItemsInfo BIInfo
JOIN BlendedIncomeSchedules BIS on BIInfo.Id = BIS.BlendedItemId
WHERE BIS.IsSchedule = 1


IF(@IsPayoffAtInception = 0)
BEGIN
INSERT INTO #ReAccrualDateInfo
SELECT LF.ContractId ContractId,
MAX(RAC.NonAccrualDate) NonAccrualDate,
MAX(RAC.ReAccrualDate) ReAccrualDate
FROM LeaseFinances LF
JOIN ReAccrualContracts RAC ON LF.ContractId = RAC.ContractId
JOIN ReAccruals RA ON RAC.ReAccrualId = RA.Id
WHERE LF.Id = @LeaseFinanceId
AND RA.Status = @ApprovedReAccrualStatus
AND RAC.IsActive = 1
GROUP BY LF.ContractId;

INSERT INTO #ReAccrualCatchupInfo
SELECT
BIS.BlendedItemId BlendedItemId,
SUM(BIS.Income_Amount) CatchUpIncome 
FROM #BlendedIncomeScheduleInfo BIS 	
JOIN LeaseFinances LF ON BIS.LeaseFinanceId = LF.Id
JOIN #ReAccrualDateInfo RDI ON LF.ContractId = RDI.ContractId 		
WHERE RDI.NonAccrualDate <= BIS.IncomeDate AND BIS.IncomeDate <= @PayoffEffectiveDate
	AND RDI.ReAccrualDate = DATEADD(DD, 1, @PayoffEffectiveDate)
	AND BIS.AdjustmentEntry = 0
	AND BIS.IsNonAccrual = 1
GROUP BY BIS.BlendedItemId
END


--And BIS.LeaseFinanceId = @LeaseFinanceId -- this condition can be added in the below query if we need BI adj only for the  lease finance id that is passed to this SP.
-- This may have functional impact

--this above query can be added if we need BI Adj across lease finances for this contract. we can get all lease finances associated with this contract and join it with the below query.

SELECT lf2.Id LeaseFinanceId Into #LeaseFinances FROM 
LeaseFinances lf1
JOIN LeaseFinances lf2 ON lf1.ContractId = lf2.ContractId
WHERE lf1.Id = @LeaseFinanceId

SELECT BlendedItemId = BIS.BlendedItemId, PaidOffIncome = SUM(BIS.Income_Amount) INTO #BlendedAdjustedIncomeInfo
FROM #BlendedIncomeScheduleInfo BIS 
JOIN #LeaseFinances
	ON BIS.LeaseFinanceId = #LeaseFinances.LeaseFinanceId
	AND BIS.AdjustmentEntry = 1 AND BIS.IncomeDate >= @PayoffEffectiveDate 
WHERE (@IsChargedOffLease = 0 OR BIS.IsFAS91 = 0)
GROUP BY BIS.BlendedItemId;

INSERT INTO #BlendedIncomesInfo
SELECT BI.Id, EarnedIncome = CASE   WHEN @IsPayoffAtInception = 1 THEN 0.0
WHEN BIS.BlendedItemId IS NOT NULL AND BI.BookRecognitionMode = @AccreteRecognitionMode THEN BIS.IncomeBalance_Amount
WHEN BIS.BlendedItemId IS NOT NULL AND BI.BookRecognitionMode = @AmortizeRecognitionMode THEN BI.Amount - BIS.IncomeBalance_Amount
WHEN BIS.BlendedItemId IS NOT NULL AND BI.BookRecognitionMode = @CapitalizeRecognitionMode THEN BI.Amount - BIS.IncomeBalance_Amount
WHEN BI.BookRecognitionMode = @RecognizeImmediately THEN (CASE WHEN BI.DueDate > @PayoffEffectiveDate THEN 0.0 ELSE BI.Amount END)
WHEN BIS.BlendedItemId IS NULL  THEN (CASE WHEN BI.StartDate > @PayoffEffectiveDate THEN 0.0 ELSE BI.Amount END)
ELSE 0.0
END
FROM #BlendedItemsInfo BI
LEFT JOIN #BlendedIncomeScheduleInfo BIS ON BI.Id = BIS.BlendedItemId AND BIS.IncomeDate = @PayoffEffectiveDate AND BIS.AdjustmentEntry = 0
WHERE (@IsChargedOffLease = 0 OR BI.IsFAS91 = 0);

DECLARE @EffectiveDate DATE = CASE WHEN @IsPayoffAtInception = 1 THEN DATEADD(DAY, -1, @PayoffEffectiveDate) ELSE @PayoffEffectiveDate END;


SELECT BI.Id BlendedItemId, S.ReceivableDueDate, R.TotalAmount_Amount
INTO #BlendedItemSundryReceivables
FROM #BlendedItemsInfo BI
INNER JOIN BlendedItemDetails BID ON BI.Id = BID.BlendedItemId
INNER JOIN Sundries S ON BID.SundryId = S.Id AND S.IsActive = 1
INNER JOIN Receivables R ON S.ReceivableId = R.Id AND R.IsActive = 1
WHERE S.SundryType = @ReceivableOnlySundryType

SELECT BI.Id,
BilledAmount = ISNULL(SUM(SR.TotalAmount_Amount),0.0)
INTO #BlendedBilledReceivablesInfo
FROM #BlendedItemsInfo BI
LEFT JOIN #BlendedItemSundryReceivables SR ON BI.Id = SR.BlendedItemId
WHERE SR.BlendedItemId IS NULL OR SR.ReceivableDueDate <= @EffectiveDate
GROUP BY BI.Id

SELECT BI.Id,
UnbilledAmount = ISNULL(SUM(SR.TotalAmount_Amount),0.0)
INTO #BlendedUnBilledReceivablesInfo
FROM #BlendedItemsInfo BI
LEFT JOIN #BlendedItemSundryReceivables SR ON BI.Id = SR.BlendedItemId
WHERE SR.BlendedItemId IS NULL OR SR.ReceivableDueDate > @EffectiveDate
GROUP BY BI.Id

SELECT
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
EarnedIncome = ISNULL(BIS.EarnedIncome,0.0) + ISNULL(BAI.PaidOffIncome, 0.0) - ISNULL(RCI.CatchupAmount, 0.00),
UnearnedIncome = (CASE WHEN (@IsChargedOffLease=0 OR BI.IsFAS91 = 0) THEN ISNULL(BI.Amount,0.0) - ISNULL(BIS.EarnedIncome,0.0) - ISNULL(BAI.PaidOffIncome, 0.0) + ISNULL(RCI.CatchupAmount, 0.00)
 ELSE 0.0 END),
BilledAmount = ISNULL(BRI.BilledAmount,0.0),
UnbilledAmount = ISNULL(BUI.UnbilledAmount,0.0),
IsFAS91 = BI.IsFAS91,
AccumulateExpense = BI.AccumulateExpense,
SystemConfigType = BI.SystemConfigType,
RelatedBlendedItemId = BI.RelatedBlendedItemId
FROM #BlendedItemsInfo BI
LEFT JOIN #BlendedIncomesInfo BIS ON BI.Id = BIS.BlendedItemId
LEFT JOIN #BlendedAdjustedIncomeInfo BAI ON BI.Id = BAI.BlendedItemId
LEFT JOIN #ReAccrualCatchupInfo RCI ON BI.Id = RCI.BlendedItemId
LEFT JOIN #BlendedBilledReceivablesInfo BRI ON BI.Id = BRI.Id
LEFT JOIN #BlendedUnBilledReceivablesInfo BUI ON BI.Id = BUI.Id

DROP TABLE
#LeaseAssetIds,
#BlendedItemIds,
#BlendedItemsInfo,
#BlendedIncomesInfo,
#BlendedAdjustedIncomeInfo,
#BlendedBilledReceivablesInfo,
#BlendedUnBilledReceivablesInfo,
#ReAccrualCatchupInfo,
#ReAccrualDateInfo,
#BlendedItemSundryReceivables

END

GO
