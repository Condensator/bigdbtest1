SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[UpdateLateFeeReceivablesToReverse]
(
	@ReceivableIds IdCollection READONLY,
	@Date DATETIME,
	@ReversedCount INT OUTPUT
)
AS
BEGIN

	SELECT Id INTO #ReceivableIds FROM @ReceivableIds
	CREATE TABLE #UpdatedValues ( IsActive BIT )

	UPDATE LateFeeReceivables SET IsActive = Receivables.IsActive, LateFeeReceivables.ReversedDate = @Date
	OUTPUT INSERTED.IsActive INTO #UpdatedValues
	FROM Receivables
	JOIN #ReceivableIds ON Receivables.Id = #ReceivableIds.Id
	JOIN LateFeeReceivables ON Receivables.SourceId = LateFeeReceivables.Id AND Receivables.SourceTable = 'LateFee'

	SELECT @ReversedCount = COUNT(1) FROM #UpdatedValues WHERE IsActive = 0;
	
	DROP TABLE IF EXISTS #ReceivableIds
	DROP TABLE IF EXISTS #UpdatedValues

END

GO
