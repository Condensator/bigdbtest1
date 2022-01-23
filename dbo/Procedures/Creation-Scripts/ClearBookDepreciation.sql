SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[ClearBookDepreciation]
(
	 @AssetsToClear AssetDetailsForBookDepClearing READONLY
	,@UpdatedById BIGINT
	,@UpdatedTime DATETIMEOFFSET
	,@ResidualRecaptureType NVARCHAR(30) = NULL 
)
AS
BEGIN
	SET NOCOUNT ON;
	SELECT * INTO #AssetsToClear FROM @AssetsToClear
	Select Id, A.Assetid, IsLeaseComponent,IncomeDate,IsAccounted,IsSchedule,IsLessorOwned,SourceModule,EndBookValue_Amount 
	INTO #AVH
	FROM dbo.AssetValueHistories   
	JOIN #AssetsToClear A ON AssetValueHistories.AssetId = A.AssetId  
	AND AssetValueHistories.IncomeDate <= A.ClearTillDate

	SELECT avh.Id, avh.EndBookValue_Amount, ROW_NUMBER() OVER( PARTITION BY avh.Assetid,avh.IsLeaseComponent ORDER BY IncomeDate DESC, avh.Id DESC) AS ranking  
	into #AVHsToUpdate
	FROM #AVH avh   
	JOIN #AssetsToClear A ON avh.AssetId = A.AssetId  
	WHERE avh.IsAccounted = 1   
	AND avh.IsSchedule = 1   
	AND avh.IsLessorOwned = 1  
	AND (@ResidualRecaptureType IS NULL OR avh.SourceModule <> @ResidualRecaptureType)  
	   
	UPDATE AssetValueHistories  
	SET IsCleared = 1, NetValue_Amount = lastestRecord.EndBookValue_Amount, UpdatedById = @UpdatedById, UpdatedTime = @UpdatedTime
	FROM AssetValueHistories avh
	Join #AVHsToUpdate lastestRecord on avh.Id = lastestRecord.Id
	Where ranking = 1 

	DROP TABLE #AVHsToUpdate DROP TABLE #AVH
END

GO
