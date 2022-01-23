SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[InactivateReceivablesOfNotGlPosted]
(
@ReceivableIds ReceivableIdCollection READONLY,
@UserId BIGINT,
@Time DATETIMEOFFSET
)
AS
BEGIN
SET NOCOUNT ON
Update Receivables
Set IsActive = 0,
UpdatedById = @UserId,
UpdatedTime = @Time
where Receivables.Id in (select * from @ReceivableIds)
Update ReceivableDetails
Set IsActive = 0,
UpdatedById = @UserId,
UpdatedTime = @Time
where ReceivableDetails.ReceivableId in (select * from @ReceivableIds)
End

GO
