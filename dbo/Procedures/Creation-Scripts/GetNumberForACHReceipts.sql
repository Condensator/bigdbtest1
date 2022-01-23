SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[GetNumberForACHReceipts]
(
@ReceiptCount BIGINT,
@UpdatedById BIGINT,
@UpdatedTime DateTimeOffset
)
AS
BEGIN
SET NOCOUNT ON;
DECLARE @NextReceiptNumber BIGINT;
SELECT @NextReceiptNumber = Next
FROM
SequenceGenerators WITH (nolock) WHERE Module = 'Receipt';
UPDATE SequenceGenerators
SET Next = Next + @ReceiptCount,
UpdatedById =  @UpdatedById,
UpdatedTime = @UpdatedTime
WHERE Module = 'Receipt'
SELECT @NextReceiptNumber AS Number
END

GO
