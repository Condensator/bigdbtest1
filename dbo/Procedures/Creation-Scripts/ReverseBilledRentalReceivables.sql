SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[ReverseBilledRentalReceivables]
(
@UpdatedById BigInt,
@UpdatedTime DateTimeOffset,
@BilledRentalReceivableIds ReverseBilledRentalReceivableIds READONLY
)
AS
BEGIN
SET NOCOUNT ON;
UPDATE BRR
SET BRR.IsActive = 0
,BRR.UpdatedById = @UpdatedById
,BRR.UpdatedTime = @UpdatedTime
FROM @BilledRentalReceivableIds B
JOIN ReceivableDetails RD ON B.ReceivableId = RD.ReceivableId
JOIN VertexBilledRentalReceivables BRR ON RD.Id = BRR.ReceivableDetailId
END

GO
