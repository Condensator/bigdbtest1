SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[UpdateReceivableTaxGl]
(
@ReceivableTaxGlTemp ReceivableTaxGlTemp READONLY
,@IsGlReversal BIT
,@CreatedById BIGINT
,@CreatedTime DATETIMEOFFSET
)
AS
BEGIN
SET NOCOUNT ON;
UPDATE ReceivableTaxes
SET IsGLPosted =  CONVERT(BIT,  @IsGlReversal -1), UpdatedById = @CreatedById, UpdatedTime = @CreatedTime
FROM ReceivableTaxes
JOIN @ReceivableTaxGlTemp journal ON ReceivableTaxes.Id = journal.Id
AND ReceivableTaxes.IsActive = 1
UPDATE ReceivableTaxDetails
SET IsGLPosted = CONVERT(BIT,  @IsGlReversal -1), UpdatedById = @CreatedById, UpdatedTime = @CreatedTime
FROM ReceivableTaxDetails
JOIN ReceivableTaxes ON ReceivableTaxes.Id = ReceivableTaxDetails.ReceivableTaxId
JOIN @ReceivableTaxGlTemp journal ON ReceivableTaxes.Id = journal.Id
AND ReceivableTaxes.IsActive = 1 AND ReceivableTaxDetails.IsActive = 1
SET NOCOUNT OFF;
END

GO
