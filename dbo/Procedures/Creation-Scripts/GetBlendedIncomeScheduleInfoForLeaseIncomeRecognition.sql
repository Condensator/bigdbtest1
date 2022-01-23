SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[GetBlendedIncomeScheduleInfoForLeaseIncomeRecognition]
(
	 @IncomeRecognitionContractIds IncomeRecognitionContractIds READONLY
	,@ProcessThroughDate DATETIME 
)
AS
BEGIN
SET NOCOUNT ON;

SELECT 
	ContractId=C.Id,
	C.ChargeOffStatus,
	LeaseFinanceId=LF.Id	
INTO #ContractMapping
FROM @IncomeRecognitionContractIds ContractIds
INNER JOIN Contracts C ON ContractIds.ContractId = C.Id
JOIN LeaseFinances LF ON LF.ContractId = C.Id

SELECT DISTINCT 
	ContractId = #ContractMapping.ContractId,
	#ContractMapping.ChargeOffStatus,
    BlendedItemId = BIS.BlendedItemId
INTO #BlendedItemMapping
FROM #ContractMapping
JOIN BlendedIncomeSchedules BIS ON BIS.LeaseFinanceId = #ContractMapping.LeaseFinanceId

Select 
	ContractId = #BlendedItemMapping.ContractId,
    BlendedIncomeScheduleId = BIS.Id,
    BlendedItemId = BI.Id,
    BlendedItemName = BI.Name,
    AccumulateExpense = BI.AccumulateExpense,
    BlendedItemType = BI.Type,
    BookRecognitionMode = BI.BookRecognitionMode,
    SystemConfigType = BI.SystemConfigType,
    BookingGLTemplateId = BI.BookingGLTemplateId,
    RecognitionGLTemplateId = BI.RecognitionGLTemplateId,
    IsNonAccrual = BIS.IsNonAccrual,
    Income = BIS.Income_Amount,
    IncomeDate = BIS.IncomeDate
FROM #BlendedItemMapping
JOIN BlendedItems BI ON #BlendedItemMapping.BlendedItemId = BI.Id
JOIN BlendedIncomeSchedules BIS ON BIS.BlendedItemId = BI.Id
WHERE BI.IsActive = 1
	AND (#BlendedItemMapping.ChargeOffStatus != 'ChargedOff' OR BI.IsFAS91 = 1)
	AND  BIS.IsAccounting = 1
	AND BIS.AdjustmentEntry = 0
	AND BIS.PostDate IS NULL
	AND BIS.IncomeDate <= @ProcessThroughDate

END

GO
