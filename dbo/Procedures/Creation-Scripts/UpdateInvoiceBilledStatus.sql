SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[UpdateInvoiceBilledStatus]
(
	@ReceivableIds IDs READONLY,
	@UpdatedById BIGINT,
	@UpdatedTime DATETIMEOFFSET
)
AS
BEGIN
SET NOCOUNT ON;
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

	UPDATE ReceivableDetails 
	SET 
		BilledStatus = 'Invoiced',
		UpdatedById = @UpdatedById,
		UpdatedTime = @UpdatedTime
	FROM Receivables R
		JOIN @ReceivableIds RIds ON R.Id = RIds.Id
		JOIN ReceivableDetails RD ON RD.ReceivableId = R.Id
	WHERE RD.IsTaxAssessed = 1;
END

GO
