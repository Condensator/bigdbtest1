SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROC [dbo].[UpdateACHSchedulesStatus]
(
 @ACHScheduleInfoForUpdate ACHSchedulesToUpdate READONLY
)
AS
 BEGIN

	SELECT * INTO #ACHSchedulesToUpdate FROM @ACHScheduleInfoForUpdate

	 UPDATE ACH SET Status = ACHInfo.Status
	 FROM ACHSchedules ACH
	 JOIN #ACHSchedulesToUpdate ACHInfo ON ACH.Id = ACHInfo.Id
	 WHERE ACH.IsActive = 1
	 AND ACHInfo.IsStatusOnly = 1

	 UPDATE ACH SET Status = ACHInfo.Status,
	 FileGenerationDate = ACHInfo.FileGenerationDate,
	 SettlementDate = ACHInfo.SettlementDate,
	 ACHAmount_Amount = ACHInfo.ACHAmount
	 FROM ACHSchedules ACH
	 JOIN #ACHSchedulesToUpdate ACHInfo ON ACH.Id = ACHInfo.Id
	 WHERE ACH.IsActive = 1
	 AND ACHInfo.IsStatusOnly = 0

	DROP TABLE #ACHSchedulesToUpdate
 END

GO
