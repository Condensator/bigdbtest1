SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[UpdateBilledRentalReceivables]
(
@UpdatedById BigInt,
@UpdatedTime DateTimeOffset,
@BilledRentalReceivableIds BilledRentalReceivableIds READONLY
)
AS
BEGIN
SET NOCOUNT ON;
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
UPDATE brr SET brr.IsActive = 0
,brr.UpdatedById = @UpdatedById
,brr.UpdatedTime = @UpdatedTime
FROM @BilledRentalReceivableIds b
JOIN dbo.ReceivableDetails rd ON b.ReceivableId = rd.ReceivableId
JOIN dbo.VertexBilledRentalReceivables brr ON rd.Id = brr.ReceivableDetailId
END

GO
