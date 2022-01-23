SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [dbo].[ACHScheduleUpdate_ProcessedACH_Recon]

AS
BEGIN

SELECT *, CASE WHEN [Incomplete ACH Amount prior to ACH Run date]=0 AND [Completed ACH Amount post ACH Run date]=0
THEN 'Success'
ELSE 'Failed' END AS Result 
FROM 
(
	SELECT C.SequenceNumber [Sequence Number],
	SUM
	 (
		 CASE WHEN ACHS.SettlementDate<= ACHU.ACHRuntilldate AND ACHS.Status!='COMPLETED'
		 THEN
		 ACHS.ACHAmount_Amount
		 ELSE 0
		 END 
	 ) AS [Incomplete ACH Amount prior to ACH Run date], 
	SUM
	 (
		 CASE WHEN ACHS.SettlementDate> ACHU.ACHRuntilldate AND ACHS.Status='COMPLETED'
		 THEN
		 ACHS.ACHAmount_Amount
		 ELSE 0
		 END 
	 ) AS   [Completed ACH Amount post ACH Run date],
	COUNT
	 (
		CASE 
		WHEN ACHS.Status='Completed'
		THEN 1
		END 
	 ) AS [Count of ACH Schedules Processed]
	FROM stgACHScheduleUpdate ACHU
	LEFT JOIN Contracts C ON ACHU.SequenceNumber = C.SequenceNumber
	LEFT JOIN ACHSchedules ACHS ON ACHS.ContractBillingId = C.ID  
	WHERE ACHU.IsMigrated=1
	GROUP BY C.SequenceNumber
) AS Summary

END;

GO
