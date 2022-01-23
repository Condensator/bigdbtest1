SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROC [dbo].[DeactivateReceivableDetailsForAdjustment]
(
@ReceivableIds ReceivableAdjustmentReceivableIds READONLY,
@UpdatedById BIGINT,
@UpdatedTime DATETIMEOFFSET,
@CanUpdatePaymentScheduleId BIT
)
AS
BEGIN
SET NOCOUNT ON;

SELECT ReceivableId, PaymentScheduleId INTO #ReceivableIds FROM @ReceivableIds
WHERE ReverseTaxAssessedFlag = 0

SELECT ReceivableId INTO #MigratedReceivableIds FROM @ReceivableIds
WHERE ReverseTaxAssessedFlag = 1

SELECT ReceivableDetailId = rd.Id
INTO #ReceivableDetailIds 
FROM #ReceivableIds r
JOIN ReceivableDetails rd ON r.ReceivableId = rd.ReceivableId

SELECT ReceivableDetailId = rd.Id
INTO #MigratedReceivableDetailIds 
FROM #MigratedReceivableIds r
JOIN ReceivableDetails rd ON r.ReceivableId = rd.ReceivableId

UPDATE ReceivableDetails
SET IsActive=0, UpdatedById = @UpdatedById, UpdatedTime = @UpdatedTime
FROM ReceivableDetails
JOIN #ReceivableDetailIds RID ON ReceivableDetails.Id = RID.ReceivableDetailId

UPDATE ReceivableDetails
SET IsActive=0, IsTaxAssessed = 0, UpdatedById = @UpdatedById, UpdatedTime = @UpdatedTime
FROM ReceivableDetails
JOIN #MigratedReceivableDetailIds RID ON ReceivableDetails.Id = RID.ReceivableDetailId

UPDATE Receivables
SET IsActive =0, UpdatedById = @UpdatedById, UpdatedTime = @UpdatedTime
FROM Receivables
JOIN #MigratedReceivableIds RID ON Receivables.Id = RID.ReceivableId

IF(@CanUpdatePaymentScheduleId  = 1)
BEGIN
	UPDATE Receivables
	SET IsActive =0, UpdatedById = @UpdatedById, UpdatedTime = @UpdatedTime, PaymentScheduleId = RID.PaymentScheduleId
	FROM Receivables
	JOIN #ReceivableIds RID ON Receivables.Id = RID.ReceivableId
END 
ELSE
BEGIN
	UPDATE Receivables
	SET IsActive =0, UpdatedById = @UpdatedById, UpdatedTime = @UpdatedTime
	FROM Receivables
	JOIN #ReceivableIds RID ON Receivables.Id = RID.ReceivableId
END

DROP TABLE #ReceivableIds
DROP TABLE #ReceivableDetailIds
DROP TABLE #MigratedReceivableDetailIds
DROP TABLE #MigratedReceivableIds
SET NOCOUNT OFF;
END

GO
