SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[CanProceedWithExternalReceiptPosting]
(
@ReceiptBatchStatusValues_ReadyForPosting	NVARCHAR(30),
@ReceiptBatchStatusValues_IsPosted			NVARCHAR(30),
@IsRunBatchJob								BIT,
@JobStepInstanceId							BIGINT,
@ReceiptBatchId								BIGINT,
@CreatedById								BIGINT,
@CreatedTime								DATETIMEOFFSET,
@IsTotalEqualToDepositAmount				BIGINT OUTPUT,
@IsReceiptNotInReadyForPosting				BIGINT OUTPUT
)
AS
BEGIN
SELECT
R.ReceiptBatchId,
R.Status,
R.ReceiptAmount_Amount ReceiptAmount
INTO #ReceiptBatchDetails
FROM Receipts R
JOIN ReceiptBatchDetails RBD
ON R.ReceiptBatchId = RBD.ReceiptBatchId AND R.Id = RBD.ReceiptId
WHERE RBD.IsActive = 1 AND R.ReceiptBatchId = @ReceiptBatchId
;
IF(@IsRunBatchJob = 1)
BEGIN
WITH CTE_Receipts AS
(
SELECT
R.ReceiptBatchId
FROM #ReceiptBatchDetails R
WHERE R.Status <> @ReceiptBatchStatusValues_IsPosted AND
R.Status <> @ReceiptBatchStatusValues_ReadyForPosting
)
SELECT @IsReceiptNotInReadyForPosting = CASE WHEN COUNT(*) >= 1 THEN 1 ELSE 0 END FROM CTE_Receipts
;
WITH CTE_Receipts AS
(
SELECT
R.ReceiptBatchId,
SUM(R.ReceiptAmount) ReceiptAmount
FROM #ReceiptBatchDetails R
WHERE (R.Status = @ReceiptBatchStatusValues_IsPosted OR
R.Status = @ReceiptBatchStatusValues_ReadyForPosting)
GROUP BY
R.ReceiptBatchId
)
SELECT
@IsTotalEqualToDepositAmount = CASE WHEN COUNT(*) >= 1 THEN 1 ELSE 0 END
FROM ReceiptBatches RB
INNER JOIN CTE_Receipts CR ON RB.Id = CR.ReceiptBatchId
AND RB.DepositAmount_Amount = CR.ReceiptAmount
;
END
ELSE
BEGIN
WITH CTE_Receipts AS
(
SELECT
R.ReceiptBatchId
FROM #ReceiptBatchDetails R
WHERE R.Status <> @ReceiptBatchStatusValues_ReadyForPosting
)
SELECT @IsReceiptNotInReadyForPosting = CASE WHEN COUNT(*) >= 1 THEN 1 ELSE 0 END FROM CTE_Receipts
;
WITH CTE_Receipts AS
(
SELECT
R.ReceiptBatchId,
SUM(R.ReceiptAmount) ReceiptAmount
FROM #ReceiptBatchDetails R
WHERE R.Status = @ReceiptBatchStatusValues_ReadyForPosting
GROUP BY
R.ReceiptBatchId
)
SELECT
@IsTotalEqualToDepositAmount = CASE WHEN COUNT(*) >= 1 THEN 1 ELSE 0 END
FROM ReceiptBatches RB
INNER JOIN CTE_Receipts CR ON RB.Id = CR.ReceiptBatchId
AND RB.DepositAmount_Amount = CR.ReceiptAmount
;
END
SELECT @IsTotalEqualToDepositAmount;
SELECT @IsReceiptNotInReadyForPosting ;
END

GO
