SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROC [dbo].[GetTxnInstanceStages]
(
	@transactionInstanceIds NVARCHAR(max),
	@UnAssigned NVARCHAR(20),
	@Assigned NVARCHAR(20)
)
AS
BEGIN

   SELECT Id 
   INTO #TxnInstanceIds
   FROM ConvertCSVToBigIntTable(@transactionInstanceIds,',');

	SELECT WI.TransactionInstanceId [TxnInstanceId]
	     , TSC.Label [Stage]
	FROM [WorkItems] WI 
	JOIN [WorkItemConfigs] WIC ON WI.WorkItemConfigId = WIC.Id
	JOIN [TransactionStageConfigs] TSC ON WIC.TransactionStageConfigId = TSC.Id
	JOIN #TxnInstanceIds TId ON TId.Id = WI.TransactionInstanceId
	WHERE WI.[Status] = @UnAssigned OR WI.[Status]=@Assigned
END


GO
