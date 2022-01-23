SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [dbo].[ACHScheduleUpdate_CompletedVsOutstanding_Recon]

AS
BEGIN

SELECT

	C.SequenceNumber [Sequence Number],
	SUM
	 (
		 CASE WHEN ACHS.SettlementDate<= (CAST(GetDate() AS DATE)) AND ACHS.Status='COMPLETED'
		 THEN
		 ACHS.ACHAmount_Amount
		 ELSE 0
		 END 
	 ) AS [Completed ACH Amount prior to Today], 
	SUM
	 (
		 CASE WHEN ACHS.SettlementDate <= (CAST(GetDate() AS DATE)) AND ACHS.Status!='COMPLETED'
		 THEN
		 ACHS.ACHAmount_Amount
		 ELSE 0
		 END 
	 ) AS [InComplete ACH Amount prior to Today],
SUM
	 (
		 CASE WHEN ACHS.SettlementDate> (CAST(GetDate() AS DATE)) AND ACHS.Status='COMPLETED'
		 THEN
		 ACHS.ACHAmount_Amount
		 ELSE 0
		 END 
	 ) AS [Completed ACH Amount past Today], 
	SUM
	 (
		 CASE WHEN ACHS.SettlementDate > (CAST(GetDate() AS DATE)) AND ACHS.Status!='COMPLETED'
		 THEN
		 ACHS.ACHAmount_Amount
		 ELSE 0
		 END 
	 ) AS [InComplete ACH Amount past Today]
	FROM stgACHScheduleUpdate ACHU
	LEFT JOIN Contracts C ON ACHU.SequenceNumber = C.SequenceNumber
	LEFT JOIN ACHSchedules ACHS ON ACHS.ContractBillingId = C.ID 
	WHERE ACHU.IsMigrated=1
	GROUP BY C.SequenceNumber
END;

GO
