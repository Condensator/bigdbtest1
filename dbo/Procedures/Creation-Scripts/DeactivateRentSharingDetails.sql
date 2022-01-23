SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[DeactivateRentSharingDetails]
(
@SharedReceivableIds SharedReceivableIds READONLY,
@UpdatedById BIGINT,
@UpdatedTime DATETIMEOFFSET
)
AS
BEGIN
SET NOCOUNT ON;
UPDATE RentSharingDetails
SET IsActive =0, UpdatedById = @UpdatedById, UpdatedTime = @UpdatedTime
FROM RentSharingDetails R
JOIN @SharedReceivableIds RID ON R.ReceivableId = RID.ReceivableId
SET NOCOUNT OFF;
END

GO
