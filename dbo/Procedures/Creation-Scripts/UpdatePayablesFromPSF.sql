SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[UpdatePayablesFromPSF]
(
 @PayableStatusUpdateInfo PayableStatusUpdateInfo READONLY
)
AS
 BEGIN

	SELECT * INTO #PayablesToUpdate FROM @PayableStatusUpdateInfo

	 UPDATE P SET Status = pIds.Status
	 FROM Payables P
	 JOIN #PayablesToUpdate pIds ON P.Id = pIds.Id

	DROP TABLE #PayablesToUpdate
 END

GO
