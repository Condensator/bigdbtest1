SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[UpdateRardExtract]
(  
    @RardExtractDetailsToUpdate RardExtractDetailsToUpdate READONLY
)
AS

BEGIN
	SET NOCOUNT ON

	SELECT * INTO #RardExtractDetailsToUpdate FROM @RardExtractDetailsToUpdate

	CREATE CLUSTERED INDEX IX_RARDExtractId ON #RardExtractDetailsToUpdate (RardExtractId);

	UPDATE RRD SET
		ReceiptId = RD.ReceiptId
		,ReceiptApplicationId = RD.ReceiptApplicationId
		,ReceiptApplicationReceivableDetailId = RD.ReceiptApplicationReceivableDetailId 
	FROM ReceiptReceivableDetails_Extract RRD
	INNER JOIN #RardExtractDetailsToUpdate RD ON RRD.Id = RD.RardExtractId
END

GO
