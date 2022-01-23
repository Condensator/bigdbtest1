SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[UpdatePayableSundry]
(
@SundryPayableParam SundryPayableParam READONLY
,@UpdatedById BIGINT
,@UpdatedTime DATETIMEOFFSET
)
AS
BEGIN
SET NOCOUNT ON;
CREATE TABLE #SundryInfo
(
[SundryId] BIGINT,
[PayableId] BIGINT
)
INSERT INTO  #SundryInfo
SELECT
Sundries.Id SundryId,
Payable.Id PayableId
FROM
Sundries
JOIN @SundryPayableParam SundryPayableParam ON Sundries.Id = SundryPayableParam.Id
JOIN Payables payable ON payable.SourceId = SundryPayableParam.Id
LEFT JOIN Payables adjustmentPayables on payable.Id = adjustmentPayables.AdjustmentBasisPayableId
where payable.SourceTable = 'SundryPayable'
AND payable.Status != 'InActive'
AND payable.AdjustmentBasisPayableId is null
AND adjustmentPayables.Id is null
AND Sundries.IsActive = 1
UPDATE Sundries SET
PayableId = (CASE WHEN SI.SundryId is null
THEN NULL
ELSE SI.PayableId
END),
UpdatedById = @UpdatedById,
UpdatedTime = @UpdatedTime
FROM Sundries
JOIN @SundryPayableParam SundryPayableParam ON Sundries.Id = SundryPayableParam.Id
LEFT JOIN #SundryInfo SI ON  Sundries.Id =  SI.SundryId
DROP TABLE #SundryInfo
SET NOCOUNT OFF;
END

GO
