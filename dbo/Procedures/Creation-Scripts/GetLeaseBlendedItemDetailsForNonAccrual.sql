SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[GetLeaseBlendedItemDetailsForNonAccrual]
(
	@ContractIds												ContractIds READONLY,
	@BlendedItemBookRecognitionModeValues_Capitalize			NVARCHAR(24),	
	@BlendedItemBookRecognitionModeValues_RecognizeImmediately	NVARCHAR(24)
)
AS 
BEGIN
	SET NOCOUNT ON;

	SELECT * INTO #ContractIds FROM @ContractIds

	SELECT 
		LF.ContractId,
		BI.Id AS BlendedItemId,
		BI.Name,
		BI.Amount_Amount Amount,
		BI.Type,
		BI.AccumulateExpense,
		BI.RelatedBlendedItemId,
		BI.BookingGLTemplateId,
		BI.RecognitionGLTemplateId,
		BI.BookRecognitionMode,
		BI.SystemConfigType,
		BI.Occurrence
	INTO #FAS91BlendedItems
	FROM #ContractIds 
	JOIN LeaseFinances LF ON #ContractIds.Id = LF.ContractId AND LF.IsCurrent=1
	JOIN LeaseBlendedItems LBI ON LF.Id = LBI.LeaseFinanceId
	JOIN BlendedItems BI ON LBI.BlendedItemId = BI.Id 
	WHERE BI.IsActive=1 AND BI.IsFAS91 = 1 
	AND BI.BookRecognitionMode NOT IN(@BlendedItemBookRecognitionModeValues_Capitalize,@BlendedItemBookRecognitionModeValues_RecognizeImmediately)

	SELECT 
		BI.ContractId,
		BIS.Id,
		BIS.BlendedItemId,
		BIS.IncomeDate,
		BIS.Income_Amount AS Income,
		BIS.IncomeBalance_Amount AS IncomeBalance,
		BIS.EffectiveYield,
		BIS.EffectiveInterest_Amount AS EffectiveInterest,
		BIS.IsAccounting,
		BIS.IsSchedule,
		BIS.PostDate,
		BIS.ReversalPostDate,
		BIS.AdjustmentEntry,
		BIS.LeaseFinanceId,
		BIS.IsRecomputed,
		BIS.IsNonAccrual
	FROM #FAS91BlendedItems BI
	JOIN BlendedIncomeSchedules BIS ON BI.BlendedItemId = BIS.BlendedItemId
	WHERE BIS.IsAccounting=1 OR BIS.IsSchedule=1

	SELECT 
		BI.BlendedItemId,
		BID.DueDate,
		BID.Amount_Amount AS Amount,
		BID.IsGLPosted
	FROM #FAS91BlendedItems BI
	JOIN BlendedItemDetails BID ON BI.BlendedItemId = BID.BlendedItemId
	WHERE BID.IsActive=1	

	SELECT * FROM #FAS91BlendedItems

	DROP TABLE #FAS91BlendedItems
	DROP TABLE #ContractIds
END

GO
