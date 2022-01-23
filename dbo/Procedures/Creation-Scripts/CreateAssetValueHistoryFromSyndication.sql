SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [dbo].[CreateAssetValueHistoryFromSyndication]
(@AssetValueHistories AssetValueForSyndication READONLY,
@UpdatedById BIGINT,
@UpdatedTime DATETIMEOFFSET)
AS
BEGIN
SET NOCOUNT ON;
INSERT INTO [dbo].[AssetValueHistories]
         ([SourceModule],
          [SourceModuleId],
		  [FromDate],
		  [ToDate],
          [IncomeDate],
		  [PostDate],
          [Value_Amount],
          [Value_Currency],
          [Cost_Amount],
          [Cost_Currency],
          [NetValue_Amount],
          [NetValue_Currency],
          [BeginBookValue_Amount],
          [BeginBookValue_Currency],
          [EndBookValue_Amount],
          [EndBookValue_Currency],
          [IsAccounted],
          [IsSchedule],
          [IsCleared],
          [AssetId],
		  [GLJournalId],
          [CreatedById],
          [CreatedTime],
		[AdjustmentEntry],
		[IsLessorOwned],
		[IsLeaseComponent]
		)

SELECT  [SourceModule],
		[SourceModuleId],
		[IncomeDate],
		[IncomeDate],
		[IncomeDate],
		[PostDate],
		[Value],
		[Currency],
		[Cost],
		[Currency],
		[NetValue],
		[Currency],
		[BeginBookValue],
		[Currency],
		[EndBookValue],
		[Currency],
		[IsAccounted],
		[IsSchedule],
		[IsCleared],
		[AssetId],
		[GLJournalId],  
		@UpdatedById,
		@UpdatedTime,
	    1,
		1,
		IsLeaseComponent
FROM @AssetValueHistories;
END;

GO
