SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[GetCPUAssetMultiFinanceInfo]
(
@PayoffTransactionType NVARCHAR(11),
@CPUContractId BIGINT,
@ScheduleNumbers NVARCHAR(max)
)
AS
BEGIN
SET NOCOUNT ON;

SELECT
	Id
INTO
	#ScheduleNumbers
FROM
	ConvertCSVToBigIntTable(@ScheduleNumbers, ',')

--CPU Asset Parameters across multiple finance objects
SELECT
	CPUSchedules.ScheduleNumber,
	CPUAssets.AssetId,
	CASE
		WHEN ([CPUSchedules].[CommencementDate] >= [CPUTransactions].[Date])
	THEN
		[CPUTransactions].[Date]
	ELSE
		DATEADD(Day,1,CPUTransactions.Date)
	END AS TxnEffectiveFrom,
	CPUAssets.BaseDistributionBasisAmount_Amount AS BaseDistributionBasisAmount
FROM
	CPUTransactions
	JOIN CPUFinances			ON CPUTransactions.CPUFinanceId = CPUFinances.Id
	JOIN CPUSchedules			ON CPUFinances.Id = CPUSchedules.CPUFinanceId
	JOIN #ScheduleNumbers		ON CPUSchedules.ScheduleNumber = #ScheduleNumbers.Id
	JOIN CPUAssets				ON CPUSchedules.Id = CPUAssets.CPUScheduleId AND CPUAssets.IsActive = 1
WHERE
	CPUTransactions.CPUContractId = @CPUContractId
	AND CPUSchedules.IsActive = 1
	AND CPUTransactions.IsActive = 1
	AND CPUTransactions.TransactionType != @PayoffTransactionType
ORDER BY
	TxnEffectiveFrom

SET NOCOUNT OFF;
END

GO
